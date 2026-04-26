#!/usr/bin/env ruby
# frozen_string_literal: true

require "date"
require "fileutils"
require "optparse"
require "yaml"

ROOT = File.expand_path("..", __dir__)

options = {
  target: "",
  tips: "",
  language: "auto",
  output_dir: File.join(ROOT, "generated-cvs"),
  basename: nil,
  compile: true
}

OptionParser.new do |parser|
  parser.banner = "Usage: ruby cv/generate_tailored_cv.rb --target job.txt [--tips notes.txt]"

  parser.on("--target TEXT_OR_FILE", "Job/application context or path to a text file") { |v| options[:target] = v }
  parser.on("--tips TEXT_OR_FILE", "Additional positioning tips or path to a text file") { |v| options[:tips] = v }
  parser.on("--language LANG", "auto, en, or el") { |v| options[:language] = v }
  parser.on("--output-dir DIR", "Output directory, default generated-cvs") { |v| options[:output_dir] = File.expand_path(v, ROOT) }
  parser.on("--basename NAME", "Output filename without extension") { |v| options[:basename] = v }
  parser.on("--no-compile", "Write .typ only, do not run typst") { options[:compile] = false }
end.parse!

def read_text(value)
  return "" if value.nil? || value.strip.empty?

  path = File.expand_path(value, ROOT)
  File.file?(path) ? File.read(path) : value
end

def load_yaml(path)
  YAML.load_file(File.join(ROOT, path))
end

def array(value)
  value.is_a?(Array) ? value : []
end

def text_of(value)
  case value
  when Hash
    title = value["text"].to_s
    details = [value["metric"], value["detail"]].compact.join(" ")
    details.empty? ? title : "#{title}: #{details}"
  else
    value.to_s
  end
end

def typst_escape(text)
  text.to_s
      .gsub("\\", "\\\\")
      .gsub('"', '\"')
      .gsub("\u00A0", " ")
      .strip
end

def ascii_text(text)
  text.to_s.encode("ASCII", invalid: :replace, undef: :replace, replace: "")
end

def english_text(text)
  original = text.to_s.strip.gsub(/\s+/, " ")
  return original unless original.match?(/[α-ωΑ-Ω]/)

  translations = {
    "Configuration και optimization Docker containers" => "Configured and optimized Docker containers.",
    "Ticket management και bug resolution" => "Handled IT tickets and software troubleshooting.",
    "Backend services integration για mobile game development." => "Integrated backend services for mobile game development.",
    "SvelteKit frontend με responsive design" => "Built a responsive SvelteKit frontend.",
    "Pocketbase backend για data management" => "Used PocketBase for backend data management.",
    "Website για τη Κτηνιατρική με ενσωματωμένο linear solver για βελτιστοποίηση διατροφής ζώων." => "Veterinary web platform with an embedded linear solver for animal diet optimization."
  }

  translations.fetch(original, ascii_text(original).squeeze(" ").strip)
end

def normalize(text)
  text.to_s.downcase.gsub(/[^[:alnum:]α-ωάέήίόύώϊϋΐΰ\+\#\.]+/i, " ")
end

STOPWORDS = %w[
  and the for with from this that your you are will have has into using use role
  developer engineer software full stack backend frontend senior junior mid experience
  σε και για την τον των που με από στο στη στην είναι θα έχει ως ένα μια
]

def keywords(text)
  normalize(text).split.uniq.reject { |w| w.length < 3 || STOPWORDS.include?(w) }
end

def score_item(item, wanted)
  haystack = normalize([
    item["title"],
    item["subtitle"],
    item["organization"],
    item["organization_en"],
    item["description"],
    array(item["technologies"]).join(" "),
    array(item["skills"]).join(" "),
    array(item["highlights"]).map { |h| text_of(h) }.join(" ")
  ].compact.join(" "))

  wanted.count { |word| haystack.include?(word) }
end

def tech_like?(item)
  terms = normalize([
    item["title"],
    item["title_en"],
    item["description"],
    array(item["technologies"]).join(" "),
    array(item["skills"]).join(" ")
  ].compact.join(" "))

  %w[
    developer software backend frontend full stack automation svelte go python
    javascript typescript database cloudflare docker api payment product
  ].any? { |term| terms.include?(term) }
end

def period_text(period)
  return "" unless period.is_a?(Hash)

  start = period["start"].to_s
  finish = period["end"].nil? ? "Present" : period["end"].to_s
  [start, finish].reject(&:empty?).join(" - ")
end

def start_year_month(item)
  value = item.dig("period", "start").to_s
  parts = value.split("-").map(&:to_i)
  (parts[0] || 0) * 100 + (parts[1] || 1)
end

def pick_highlights(item, wanted, limit)
  lines = array(item["highlights"]).map { |h| text_of(h) }.reject(&:empty?)
  lines = lines.sort_by { |line| -keywords(line).count { |kw| wanted.include?(kw) } }
  lines.first(limit)
end

def bullets_for(item, wanted, limit, language)
  bullets = pick_highlights(item, wanted, limit)
  bullets = [item["description"].to_s.strip.gsub(/\s+/, " ")] if bullets.empty? && item["description"]
  bullets = bullets.map { |line| language == "en" ? english_text(line) : line }
  bullets.reject(&:empty?).first(limit)
end

target = read_text(options[:target])
tips = read_text(options[:tips])
context = [target, tips].join("\n")
wanted = keywords(context)

language = options[:language]
language = context.match?(/[α-ωΑ-Ω]/) ? "el" : "en" if language == "auto"

personal = load_yaml("data/portfolio/personal.yaml")
experience = load_yaml("data/portfolio/experience.yaml")
education = load_yaml("data/portfolio/education.yaml")
projects = load_yaml("data/portfolio/projects.yaml")
skills = load_yaml("data/portfolio/skills.yaml")

profile = personal["profile"]
experiences = array(experience["experiences"])
project_items = array(projects)

experience_scores = experiences.map { |item| [item, score_item(item, wanted)] }
developer_target = wanted.any? do |word|
  %w[
    developer software backend frontend fullstack full-stack svelte go python
    javascript typescript database api cloudflare payment devops
  ].include?(word)
end

ranked_experiences = experience_scores
                     .sort_by do |item, score|
                       tech_penalty = developer_target && !tech_like?(item) ? 1 : 0
                       [-score, tech_penalty, item.dig("period", "end").nil? ? 0 : 1, -start_year_month(item)]
                     end
                     .map(&:first)

ranked_projects = project_items
                  .select { |item| item["featured"] != false }
                  .map { |item| [item, score_item(item, wanted)] }
                  .sort_by { |item, score| [-score, -(item["weight"] || 0), item["title"].to_s] }
                  .map(&:first)

selected_experiences = ranked_experiences.first(4)
selected_projects = ranked_projects.first(4)

skill_groups = skills["skills"] || {}
flat_skills = skill_groups.values.flatten.map { |s| s["name"] }.compact
ordered_skills = flat_skills.sort_by { |skill| wanted.any? { |kw| normalize(skill).include?(kw) } ? 0 : 1 }.first(16)

summary = if language == "el"
            "Full-stack developer με εμπειρία σε SvelteKit, Go, Python, data-driven εφαρμογές και end-to-end product delivery. Χτίζω πρακτικά web προϊόντα από τη βάση δεδομένων και το backend μέχρι το frontend, deployment και operations."
          else
            "Full-stack developer with experience in SvelteKit, Go, Python, data-driven applications, and end-to-end product delivery. I build practical web products from database and backend design through frontend, deployment, and operations."
          end

if context.strip.length.positive?
  top_terms = wanted.first(5).join(", ")
  summary += " Focus: #{top_terms}."
end

labels = if language == "el"
           {
             experience: "Experience",
             projects: "Selected Projects",
             skills: "Skills",
             education: "Education",
             certifications: "Certifications"
           }
         else
           {
             experience: "Experience",
             projects: "Selected Projects",
             skills: "Skills",
             education: "Education",
             certifications: "Certifications"
           }
         end

lines = []
lines << '#set page(paper: "a4", margin: (x: 1.25cm, y: 1.15cm))'
lines << '#set text(font: "Helvetica", size: 8.8pt, lang: "en")'
lines << '#set par(justify: false, leading: 0.5em)'
lines << '#show link: underline'
lines << '#let section(title) = block(above: 1.25em, below: 0.5em)[#text(size: 10pt, weight: "bold", upper(title)) #v(0.16em) #line(length: 100%, stroke: 0.45pt)]'
lines << '#let entry(title, meta, body) = block(above: 0.34em, below: 0.24em)[#grid(columns: (1fr, auto), gutter: 0.6em, text(weight: "bold", title), text(size: 7.9pt, fill: rgb("#444"), meta)) #v(0.08em) #body]'
lines << ""
lines << "#align(center)[#text(size: 16pt, weight: \"bold\", \"#{typst_escape(profile["name"])}\")]"
lines << "#align(center)[#text(\"#{typst_escape(profile["email"])}\") | #text(\"#{typst_escape(profile["location"])}\") | #link(\"#{profile.dig("social", "github")}\")[GitHub] | #link(\"#{profile.dig("social", "linkedin")}\")[LinkedIn]]"
lines << ""
lines << typst_escape(summary)
lines << ""

lines << "#section(\"#{labels[:experience]}\")"
selected_experiences.each do |item|
  title = item["title_en"] || item["title"]
  org = item["organization_en"] || item["organization"]
  meta = [org, period_text(item["period"])].reject(&:empty?).join(" | ")
  bullets = bullets_for(item, wanted, 3, language)
  body = bullets.map { |b| "- #{typst_escape(b)}" }.join("\n")
  lines << "#entry(\"#{typst_escape(title)}\", \"#{typst_escape(meta)}\")["
  lines << body
  lines << "]"
end
lines << ""

lines << "#section(\"#{labels[:projects]}\")"
selected_projects.each do |item|
  title = item["title"]
  meta = array(item["technologies"]).first(6).join(", ")
  desc = language == "en" ? english_text(item["description"].to_s.strip.gsub(/\s+/, " ")) : item["description"].to_s.strip.gsub(/\s+/, " ")
  highlights = bullets_for(item, wanted, 1, language)
  project_lines = [desc]
  project_lines.concat(highlights)
  body = project_lines.reject(&:empty?).first(2).map { |b| "- #{typst_escape(b)}" }.join("\n")
  link = array(item["links"]).first
  title_text = link ? "#{title} (#{link["label"]})" : title
  lines << "#entry(\"#{typst_escape(title_text)}\", \"#{typst_escape(meta)}\")["
  lines << body
  lines << "]"
end
lines << ""

lines << "#section(\"#{labels[:skills]}\")"
lines << typst_escape(ordered_skills.join(" | "))
lines << ""

lines << "#section(\"#{labels[:education]}\")"
array(education["education"]).first(2).each do |item|
  degree = item["degree_en"] || item["degree"]
  institution = item["institution_en"] || item["institution"]
  meta = [institution, period_text(item["period"])].reject(&:empty?).join(" | ")
  extra = item["gpa"] ? "GPA: #{item["gpa"]}" : ""
  lines << "#entry(\"#{typst_escape(degree)}\", \"#{typst_escape(meta)}\")[#{typst_escape(extra)}]"
end

certifications = array(education["certifications"]).first(4)
unless certifications.empty?
  lines << ""
  lines << "#section(\"#{labels[:certifications]}\")"
  cert_line = certifications.map { |cert| "#{cert["name"]} (#{cert["issuer"]})" }.join(" | ")
  lines << typst_escape(cert_line)
end

FileUtils.mkdir_p(options[:output_dir])
stamp = Date.today.strftime("%Y-%m-%d")
basename = options[:basename] || "angelos-papamichail-cv-#{stamp}"
typ_path = File.join(options[:output_dir], "#{basename}.typ")
pdf_path = File.join(options[:output_dir], "#{basename}.pdf")
File.write(typ_path, lines.join("\n"))

if options[:compile]
  if system("typst", "compile", typ_path, pdf_path)
    puts pdf_path
  else
    warn "Wrote #{typ_path}, but Typst compile failed or typst is not installed."
    exit 2
  end
else
  puts typ_path
end
