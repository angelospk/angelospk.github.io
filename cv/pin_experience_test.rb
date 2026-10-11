# frozen_string_literal: true

# ruby cv/pin_experience_test.rb
# Companion to pin_projects_test.rb. --pin-experience exists because the ranker scores
# an entry on the posting's own vocabulary: open-source ML work sinks below weaker
# entries whenever the ad is a generic web-dev one, and the top-4 cut then drops it.
require "minitest/autorun"
require "tmpdir"
require "open3"

GENERATOR = File.expand_path("generate_tailored_cv.rb", __dir__)

# A posting that names none of the GSoC entry's terms (no ML, ASR, Whisper, PyTorch),
# which is exactly the case where the ranker drops it.
PLAIN_WEB_AD = "Junior developer. JavaScript, HTML, CSS, REST APIs, Git, SQL databases."

def generate_exp(pins: nil, target: PLAIN_WEB_AD, language: "en")
  Dir.mktmpdir do |dir|
    job = File.join(dir, "job.txt")
    File.write(job, target)
    cmd = ["ruby", GENERATOR, "--target", job, "--language", language,
           "--output-dir", dir, "--basename", "cv", "--no-compile"]
    cmd += ["--pin-experience", pins] if pins
    # The generator reads UTF-8 portfolio data; a US-ASCII default external encoding
    # makes it die on the first non-ASCII byte.
    stdout, stderr, status = Open3.capture3({ "LANG" => "en_US.UTF-8" }, *cmd)
    path = File.join(dir, "cv.typ")
    # Read explicitly as UTF-8: the portfolio data is Greek and this test file
    # asserts against Greek labels, but Ruby's default external encoding is
    # US-ASCII whenever LANG is unset in the parent shell.
    typ = File.exist?(path) ? File.read(path, encoding: "UTF-8") : ""
    [status, typ, stdout + stderr]
  end
end

# Titles under the "Experience" heading, in order.
def selected_experience(typ)
  typ.split('#section("Experience")').last.to_s
     .split('#section("Selected Projects")').first.to_s
     .scan(/^#entry\("(.*?)"/).flatten.map { |t| t.gsub("\\", "") }
end

class PinExperienceTest < Minitest::Test
  def test_without_the_flag_ranking_is_untouched
    status, typ, = generate_exp
    assert_predicate status, :success?
    assert_equal 4, selected_experience(typ).length
  end

  def test_a_pin_takes_the_first_slot
    _, typ, = generate_exp(pins: "gsoc-opencouncil")
    titles = selected_experience(typ)
    assert_match(/GSoC|AI Engineer/, titles.first)
    assert_equal 4, titles.length
  end

  def test_a_pinned_entry_is_not_duplicated_by_the_ranking
    _, typ, = generate_exp(pins: "unitrip-fullstack")
    titles = selected_experience(typ)
    assert_equal titles.uniq.length, titles.length
  end

  def test_pins_keep_their_given_order
    _, typ, = generate_exp(pins: "haf-military,gsoc-opencouncil")
    titles = selected_experience(typ)
    assert_match(/Military/, titles[0])
    assert_match(/GSoC|AI Engineer/, titles[1])
  end

  def test_an_unknown_id_is_an_error_not_a_silent_drop
    status, _, output = generate_exp(pins: "no-such-role")
    refute_predicate status, :success?
    assert_match(/Unknown --pin-experience/, output)
  end

  def test_too_many_pins_is_an_error
    status, _, output = generate_exp(pins: "skipq-founder,gsoc-opencouncil,unitrip-fullstack,enosi-2025,tui-magic-life")
    refute_predicate status, :success?
    assert_match(/at most/, output)
  end
end

class MilitaryLineTest < Minitest::Test
  # Greek postings routinely list "εκπληρωμένες στρατιωτικές υποχρεώσεις" as a hard
  # requirement, and the service entry loses the top-4 experience cut every time.
  def certifications_line(typ)
    typ.split('#section("Certifications")').last.to_s.strip
  end

  def test_the_note_is_present_without_spending_an_experience_slot
    _, typ, = generate_exp
    assert_match(/Military service: Completed/, certifications_line(typ))
    refute_match(/Military Service, Fire Rescue/, selected_experience(typ).join(" "))
  end

  def test_the_status_is_greek_in_a_greek_cv
    _, typ, = generate_exp(language: "el")
    assert_match(/Στρατιωτικά: Εκπληρωμένες/, certifications_line(typ))
  end

  def test_the_note_reports_the_years_from_the_portfolio_data
    _, typ, = generate_exp
    assert_match(/2021-2022/, certifications_line(typ))
  end

  def test_it_uses_the_org_abbreviation_and_does_not_nest_brackets
    _, typ, = generate_exp
    assert_match(/\(HAF, /, certifications_line(typ))
    refute_match(/Hellenic Air Force \(HAF\)/, certifications_line(typ))
  end

  def test_it_adds_no_block_of_its_own
    # A #section costs a heading, a rule and 1.25em; even an #entry was enough to
    # spill this one-page CV onto a second page. Measured, both times.
    _, typ, = generate_exp
    refute_match(/#section\("Military Service"\)/, typ)
    refute_match(/#entry\("Military Service"/, typ)
  end
end

class PageBudgetTest < Minitest::Test
  # The CV is a one-page document. Anything added to the template has to fit.
  def test_the_generated_cv_is_a_single_page
    skip "typst not installed" if `which typst`.strip.empty?

    Dir.mktmpdir do |dir|
      job = File.join(dir, "job.txt")
      File.write(job, PLAIN_WEB_AD)
      _, err, status = Open3.capture3({ "LANG" => "en_US.UTF-8" },
                                      "ruby", GENERATOR, "--target", job, "--language", "en",
                                      "--output-dir", dir, "--basename", "cv")
      assert_predicate status, :success?, err
      pdf = File.binread(File.join(dir, "cv.pdf"))
      pages = pdf.scan(%r{/Type\s*/Page[^s]}).length
      assert_equal 1, pages, "CV grew to #{pages} pages"
    end
  end
end

class DuplicatePinTest < Minitest::Test
  # Mirrors pin_projects_test.rb: a repeated id collapses, it is not an error.
  # CodeRabbit flagged the `.uniq` as a silent swallow; that existing test says the
  # dedupe is the intended contract, so the shared parser keeps it.
  def test_a_repeated_experience_id_is_deduplicated
    _, typ, = generate_exp(pins: "gsoc-opencouncil,gsoc-opencouncil")
    titles = selected_experience(typ)
    assert_match(/GSoC|AI Engineer/, titles.first)
    assert_equal titles.uniq, titles
  end
end

class DescriptionTrimTest < Minitest::Test
  # Portfolio descriptions run to four lines; the CV has room for about one per
  # project. Untrimmed, they pushed real CVs onto a second page.
  def project_bullets(typ)
    typ.split('#section("Selected Projects")').last.to_s
       .split('#section("Skills")').first.to_s
       .lines.select { |l| l.start_with?("- ") }.map(&:strip)
  end

  def test_no_project_bullet_runs_past_a_couple_of_lines
    _, typ, = generate_exp
    long = project_bullets(typ).select { |b| b.length > 240 }
    assert_empty long, "over-long bullets: #{long.map { |b| b[0, 60] }}"
  end

  def test_a_trimmed_description_still_ends_on_a_whole_word
    _, typ, = generate_exp
    project_bullets(typ).each { |b| refute_match(/\s\z/, b) }
  end

  def test_a_dotted_domain_does_not_end_the_sentence
    # "finddoctors.gov.gr" must not be read as three sentence breaks.
    _, typ, = generate_exp(target: "Go backend, REST APIs, concurrent workers, aggregation.")
    bullet = project_bullets(typ).find { |b| b.include?("finddoctors") }
    refute_nil bullet, "expected the FindDoctors project to be selected"
    assert_match(/finddoctors\.gov\.gr/, bullet)
  end
end
