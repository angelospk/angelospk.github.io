# frozen_string_literal: true

# ruby cv/pin_projects_test.rb
# Drives the real generator CLI, because --pin-projects exists to make a hand-picked
# selection survive `jobhunt-cli assets` regenerating the file.
require "minitest/autorun"
require "tmpdir"
require "open3"

GENERATOR = File.expand_path("generate_tailored_cv.rb", __dir__)

def generate(pins: nil, target: "SQL reporting and dashboards.")
  Dir.mktmpdir do |dir|
    job = File.join(dir, "job.txt")
    File.write(job, target)
    cmd = ["ruby", GENERATOR, "--target", job, "--language", "en",
           "--output-dir", dir, "--basename", "cv", "--no-compile"]
    cmd += ["--pin-projects", pins] if pins
    # The generator reads UTF-8 portfolio data; a US-ASCII default external encoding
    # makes it die on the first non-ASCII byte.
    stdout, stderr, status = Open3.capture3({ "LANG" => "en_US.UTF-8" }, *cmd)
    typ = File.exist?(File.join(dir, "cv.typ")) ? File.read(File.join(dir, "cv.typ")) : ""
    [status, typ, stdout + stderr]
  end
end

# Titles under the "Selected Projects" heading, in order.
def selected_projects(typ)
  section = typ.split('#section("Selected Projects")').last.to_s
              .split('#section("Skills")').first.to_s
  section.scan(/^#entry\((?:"(.*?)"|\[#link\("[^"]*"\)\[(.*?) \()/).map { |a, b| (a || b).gsub("\\", "") }
end

class PinProjectsTest < Minitest::Test
  def test_without_the_flag_ranking_is_untouched
    status, typ, = generate
    assert_predicate status, :success?
    assert_equal 4, selected_projects(typ).length
  end

  def test_pins_come_first_in_the_order_given
    _, typ, = generate(pins: "rationvet,diesi-analytics")
    assert_equal ["RationVet", "Diesi Analytics"], selected_projects(typ).first(2)
  end

  def test_remaining_slots_are_filled_from_the_ranking_without_duplicates
    _, unpinned_typ, = generate
    unpinned = selected_projects(unpinned_typ)

    _, typ, = generate(pins: "rationvet")
    picked = selected_projects(typ)

    assert_equal 4, picked.length
    assert_equal picked.uniq, picked
    refute_includes unpinned, "RationVet", "fixture must pin something ranking would not pick"
    # Pinning takes the top slot and pushes the ranking down, without reordering it.
    assert_equal ["RationVet"] + unpinned.first(3), picked
  end

  def test_a_full_slate_of_pins_is_exactly_what_is_rendered
    _, typ, = generate(pins: "rationvet,diesi-analytics,skroutz-vanced,aimovie")
    assert_equal ["RationVet", "Diesi Analytics", "Skroutz Vanced", "AiMovie"], selected_projects(typ)
  end

  def test_duplicate_pins_are_deduplicated
    _, typ, = generate(pins: "rationvet,rationvet")
    picked = selected_projects(typ)
    assert_equal "RationVet", picked.first
    assert_equal picked.uniq, picked
  end

  def test_pins_are_case_and_space_insensitive
    _, typ, = generate(pins: " RationVet , diesi-analytics ")
    assert_equal ["RationVet", "Diesi Analytics"], selected_projects(typ).first(2)
  end

  def test_an_unknown_id_fails_loudly
    # A silently dropped pin would hand back a CV that looks fine and is wrong.
    status, _, output = generate(pins: "diesi-analytics,no-such-project")
    refute_predicate status, :success?
    assert_match(/no-such-project/, output)
  end

  def test_more_pins_than_slots_fails_rather_than_truncating
    status, _, output = generate(pins: "rationvet,diesi-analytics,aimovie,skroutz-vanced,unitrip")
    refute_predicate status, :success?
    assert_match(/at most 4/, output)
  end

  def test_a_pin_can_override_the_featured_filter
    # "church-showcase" is featured: false, so ranking can never surface it. An
    # explicit pin is a deliberate override and outranks that policy.
    _, typ, = generate(pins: "church-showcase")
    assert_equal "AthosCy", selected_projects(typ).first
  end
end
