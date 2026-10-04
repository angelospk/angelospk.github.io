# frozen_string_literal: true

# ruby cv/overlay_test.rb
# The overlay exists so the CV can say the same true things in sharper, business-facing
# language without that language landing on the public website, which is driven by the
# same portfolio YAML. What matters here is that it never changes the CV unless it is
# asked to, and that a mistake in it is loud rather than quietly on the PDF.
require "minitest/autorun"
require "tmpdir"
require "open3"
require "yaml"

GENERATOR = File.expand_path("generate_tailored_cv.rb", __dir__)
AI_AD = "AI engineer. Python, RAG, embeddings, retrieval, evaluation, LLM agents."

def generate_with(overlay, target: AI_AD, env: {}, pin_experience: nil)
  Dir.mktmpdir do |dir|
    job = File.join(dir, "job.txt")
    File.write(job, target)
    cmd = ["ruby", GENERATOR, "--target", job, "--language", "en",
           "--output-dir", dir, "--basename", "cv", "--no-compile"]
    cmd += ["--pin-experience", pin_experience] if pin_experience
    unless overlay.nil?
      path = File.join(dir, "overlay.yaml")
      File.write(path, overlay.to_yaml)
      cmd += ["--overlay", path]
    end
    stdout, stderr, status = Open3.capture3({ "LANG" => "en_US.UTF-8" }.merge(env), *cmd)
    path = File.join(dir, "cv.typ")
    [status, File.exist?(path) ? File.read(path, encoding: "UTF-8") : "", stdout + stderr]
  end
end

def entries_under(typ, heading, following)
  typ.split(%(#section("#{heading}"))).last.to_s
     .split(%(#section("#{following}"))).first.to_s
     .scan(/^#entry\("(.*?)"/).flatten.map { |t| t.gsub("\\", "") }
end

class OverlayTest < Minitest::Test
  def test_no_overlay_leaves_the_cv_alone
    status, typ, = generate_with(nil)
    assert_predicate status, :success?
    assert_includes typ, "Full-stack developer with experience"
  end

  def test_a_patch_rewrites_an_existing_entry_without_adding_one
    _, base, = generate_with(nil, pin_experience: "unitrip-fullstack")
    baseline = entries_under(base, "Experience", "Selected Projects")

    _, typ, = generate_with(
      { "experiences" => [{ "id" => "unitrip-fullstack",
                            "title" => "Freelance Full-Stack Engineer" }] },
      pin_experience: "unitrip-fullstack"
    )
    titles = entries_under(typ, "Experience", "Selected Projects")
    assert_equal baseline.length, titles.length
    assert_includes titles, "Freelance Full-Stack Engineer"
    refute_includes titles, "Full-Stack Developer"
  end

  def test_a_patched_list_replaces_rather_than_appends
    _, typ, = generate_with(
      { "projects" => [{ "id" => "gemini-rag-demo",
                         "highlights" => [{ "text" => "Page-level citations" }] }] }
    )
    assert_includes typ, "Page-level citations"
    refute_includes typ, "FAISS Vector Store"
  end

  def test_a_new_entry_is_added_and_can_be_pinned
    _, typ, = generate_with(
      { "experiences" => [{ "id" => "freelance", "op" => "add",
                            "title" => "Independent Software Engineer",
                            "organization" => "Freelance",
                            "period" => { "start" => "2024-01", "end" => nil },
                            "description" => "Delivery work for small organisations.",
                            "technologies" => %w[Python RAG] }] }
    )
    assert_includes entries_under(typ, "Experience", "Selected Projects"),
                    "Independent Software Engineer"
  end

  def test_a_typo_in_a_patched_id_is_an_error_not_a_new_entry
    status, _, log = generate_with(
      { "projects" => [{ "id" => "gemini-rag-demoo", "title" => "Gemini RAG" }] }
    )
    refute_predicate status, :success?
    assert_match(/typo/, log)
  end

  def test_adding_an_id_that_already_exists_is_an_error
    status, _, log = generate_with(
      { "projects" => [{ "id" => "gemini-rag-demo", "op" => "add", "title" => "X" }] }
    )
    refute_predicate status, :success?
    assert_match(/already exists/, log)
  end

  def test_a_bare_string_summary_is_an_error_not_the_word_en
    status, typ, log = generate_with({ "summary" => "Applied AI engineer." })
    refute_predicate status, :success?
    refute_includes typ, "\nen\n"
    assert_match(/must be a mapping of language/, log)
  end

  def test_an_unknown_top_level_key_is_an_error
    status, _, log = generate_with({ "skills" => [{ "name" => "AWS" }] })
    refute_predicate status, :success?
    assert_match(/unknown overlay key/, log)
  end

  def test_an_entry_without_an_id_is_an_error
    status, _, log = generate_with({ "projects" => [{ "title" => "Nameless" }] })
    refute_predicate status, :success?
    assert_match(/needs an id/, log)
  end

  def test_the_summary_can_be_replaced
    _, typ, = generate_with({ "summary" => { "en" => "Applied AI engineer." } })
    assert_includes typ, "Applied AI engineer."
    refute_includes typ, "Full-stack developer with experience"
  end

  def test_a_missing_explicit_overlay_is_an_error_not_a_silent_skip
    Dir.mktmpdir do |dir|
      job = File.join(dir, "job.txt")
      File.write(job, AI_AD)
      _, stderr, status = Open3.capture3(
        { "LANG" => "en_US.UTF-8" }, "ruby", GENERATOR, "--target", job,
        "--overlay", File.join(dir, "nope.yaml"), "--no-compile",
        "--output-dir", dir, "--basename", "cv"
      )
      refute_predicate status, :success?
      assert_match(/Overlay not found/, stderr)
    end
  end
end
