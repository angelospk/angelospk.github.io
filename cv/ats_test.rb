# frozen_string_literal: true

# ruby cv/ats_test.rb
# What an applicant tracking system sees, rather than what a reader sees: the order of
# text in the PDF, which skills it finds, which links it can read, and a sentence that
# stops in the middle. Each test here exists because pdftotext showed the defect on a
# real role CV (2026-10-12).
require "minitest/autorun"
require "tmpdir"
require "open3"
require "yaml"

GENERATOR = File.expand_path("generate_tailored_cv.rb", __dir__)

# The applied-ai role CV's own target text (job-hunt scripts/jobhunt/roles.py). Its
# summary says "Focus: Go, ..." and the Skills list used to leave Go out.
APPLIED_AI_TARGET = "Applied AI and forward deployed engineering: LLMs, retrieval augmented " \
                    "generation, embeddings, vector databases, agents, prompt engineering, " \
                    "evaluation harnesses, MCP and tool use, customer facing delivery, " \
                    "integrations, workflow automation, SQL and data analysis, Python, " \
                    "TypeScript, Go, cloud deployment."

def generate_ats(target, overlay: nil, extra: [])
  Dir.mktmpdir do |dir|
    job = File.join(dir, "job.txt")
    File.write(job, target)
    cmd = ["ruby", GENERATOR, "--target", job, "--language", "en",
           "--output-dir", dir, "--basename", "cv", "--no-compile"] + extra
    unless overlay.nil?
      path = File.join(dir, "overlay.yaml")
      File.write(path, overlay.to_yaml)
      cmd += ["--overlay", path]
    end
    stdout, stderr, status = Open3.capture3({ "LANG" => "en_US.UTF-8" }, *cmd)
    path = File.join(dir, "cv.typ")
    [status, File.exist?(path) ? File.read(path, encoding: "UTF-8") : "", stdout + stderr]
  end
end

def skills_line(typ)
  typ.split(%(#section("Skills"))).last.to_s.strip.lines.first.to_s.strip
end

def focus_terms(typ)
  typ[/Focus: (.*?)\.$/, 1].to_s.split(", ")
end

class AtsTest < Minitest::Test
  def test_every_focus_term_is_also_in_the_skills_list
    status, typ, = generate_ats(APPLIED_AI_TARGET)
    assert_predicate status, :success?
    terms = focus_terms(typ)
    refute_empty terms
    skills = skills_line(typ).gsub("\\", "").split(" | ")
    terms.each { |term| assert_includes skills, term, "Focus names #{term} but Skills does not list it" }
  end

  def test_the_most_requested_skill_comes_first
    _, typ, = generate_ats("Go services. Go and Go again. Python scripts.")
    skills = skills_line(typ).gsub("\\", "").split(" | ")
    assert_equal "Go", skills.first
    assert_equal "Python", skills[1]
  end

  def test_the_skills_list_is_stable_between_runs
    _, first, = generate_ats(APPLIED_AI_TARGET)
    _, second, = generate_ats(APPLIED_AI_TARGET)
    assert_equal skills_line(first), skills_line(second)
  end

  def test_a_truncated_description_does_not_end_on_a_comma
    description = "abcdefghi, " * 30
    overlay = { "projects" => [{ "op" => "add", "id" => "long-one", "title" => "Long One",
                                 "description" => description, "technologies" => ["Go"],
                                 "highlights" => [{ "text" => "A real highlight." }],
                                 "featured" => true }] }
    status, typ, = generate_ats("Go developer.", overlay: overlay, extra: ["--pin-projects", "long-one"])
    assert_predicate status, :success?
    bullets = typ.lines.select { |l| l.start_with?("- ") && l.include?("abcdefghi") }
    refute_empty bullets
    bullets.each { |b| refute_match(/[,;:]\s*\z/, b, "bullet ends on dangling punctuation") }
  end

  def test_entry_headers_are_one_run_of_text_not_two_grid_cells
    _, typ, = generate_ats(APPLIED_AI_TARGET)
    refute_match(/#grid\(columns/, typ)
    assert_includes typ, "#h(1fr)"
  end

  def test_the_contact_line_shows_the_profile_urls_as_text
    _, typ, = generate_ats(APPLIED_AI_TARGET)
    contact = typ.lines.find { |l| l.include?("mailto:") }.to_s
    # The URL is already inside link(...); what ATS reads is the visible label.
    assert_includes contact, ")[github.com/angelospk]"
    assert_includes contact, ")[linkedin.com/in/angelos-papamichail]"
  end

  def test_the_pdf_carries_a_title_and_author
    _, typ, = generate_ats(APPLIED_AI_TARGET)
    assert_match(/#set document\(title: "[^"]*Angelos Papamichail[^"]*", author: "Angelos Papamichail"\)/, typ)
  end
end

# The tests above read the Typst source. These compile it and read the PDF the way an
# applicant tracking system does, because a source check cannot see reading order.
class AtsCompiledPdfTest < Minitest::Test
  def setup
    skip "typst not installed" unless system("command -v typst >/dev/null 2>&1")
    skip "pdftotext/pdfinfo not installed" unless system("command -v pdftotext >/dev/null 2>&1 && command -v pdfinfo >/dev/null 2>&1")
  end

  def compile_pdf
    Dir.mktmpdir do |dir|
      job = File.join(dir, "job.txt")
      File.write(job, APPLIED_AI_TARGET)
      _, err, status = Open3.capture3({ "LANG" => "en_US.UTF-8" }, "ruby", GENERATOR, "--target", job,
                                      "--language", "en", "--output-dir", dir, "--basename", "cv",
                                      "--pin-experience", "unitrip-fullstack")
      assert_predicate status, :success?, err
      pdf = File.join(dir, "cv.pdf")
      assert File.exist?(pdf), "no PDF produced"
      yield pdf
    end
  end

  def test_the_pdf_has_a_title_and_author
    compile_pdf do |pdf|
      info, = Open3.capture2("pdfinfo", pdf)
      assert_match(/^Title:\s+Angelos Papamichail CV/, info)
      assert_match(/^Author:\s+Angelos Papamichail/, info)
    end
  end

  def test_an_entry_title_and_its_details_read_as_one_line
    compile_pdf do |pdf|
      text, = Open3.capture2("pdftotext", "-raw", pdf, "-")
      line = text.lines.find { |l| l.include?("Freelance Software Engineer") }
      refute_nil line, "experience title missing from extracted text"
      assert_includes line, "UniTrip.gr", "title and employer were split across lines"
    end
  end

  def test_the_profile_urls_are_in_the_extracted_text
    compile_pdf do |pdf|
      text, = Open3.capture2("pdftotext", "-raw", pdf, "-")
      assert_includes text, "github.com/angelospk"
      assert_includes text, "linkedin.com/in/angelos-papamichail"
    end
  end

  def test_the_cv_stays_on_one_page
    compile_pdf do |pdf|
      info, = Open3.capture2("pdfinfo", pdf)
      assert_match(/^Pages:\s+1$/, info)
    end
  end
end
