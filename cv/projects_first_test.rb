# frozen_string_literal: true

# ruby cv/projects_first_test.rb
# --projects-first puts Selected Projects above Experience, for CVs whose strongest
# evidence is live work a reader can open rather than job titles.
require "minitest/autorun"
require "tmpdir"
require "open3"

GENERATOR = File.expand_path("generate_tailored_cv.rb", __dir__)

def section_order(*extra)
  Dir.mktmpdir do |dir|
    job = File.join(dir, "job.txt")
    File.write(job, "Full stack web development with TypeScript and Go.")
    cmd = ["ruby", GENERATOR, "--target", job, "--language", "en",
           "--output-dir", dir, "--basename", "cv", "--no-compile", *extra]
    _, err, status = Open3.capture3({ "LANG" => "en_US.UTF-8" }, *cmd)
    raise err unless status.success?

    File.read(File.join(dir, "cv.typ")).scan(/^#section\("([^"]+)"\)/).flatten
  end
end

class ProjectsFirstTest < Minitest::Test
  def test_default_keeps_experience_first
    order = section_order
    assert_operator order.index("Experience"), :<, order.index("Selected Projects")
  end

  def test_flag_moves_projects_above_experience
    order = section_order("--projects-first")
    assert_equal ["Selected Projects", "Experience"], order.first(2)
  end
end
