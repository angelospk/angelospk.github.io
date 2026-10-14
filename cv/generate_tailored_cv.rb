#!/usr/bin/env ruby
# frozen_string_literal: true

require "date"
require "fileutils"
require "optparse"
require "yaml"
require_relative "ranking"

ROOT = File.expand_path("..", __dir__)

options = {
  target: "",
  tips: "",
  language: "auto",
  output_dir: File.join(ROOT, "generated-cvs"),
  basename: nil,
  compile: true,
  pin_projects: nil,
  max_projects: nil,
  projects_first: false,
  explain: false
}

OptionParser.new do |parser|
  parser.banner = "Usage: ruby cv/generate_tailored_cv.rb --target job.txt [--tips notes.txt]"

  parser.on("--target TEXT_OR_FILE", "Job/application context or path to a text file") { |v| options[:target] = v }
  parser.on("--tips TEXT_OR_FILE", "Additional positioning tips or path to a text file") { |v| options[:tips] = v }
  parser.on("--language LANG", "auto, en, or el") { |v| options[:language] = v }
  parser.on("--output-dir DIR", "Output directory, default generated-cvs") { |v| options[:output_dir] = File.expand_path(v, ROOT) }
  parser.on("--basename NAME", "Output filename without extension") { |v| options[:basename] = v }
  parser.on("--no-compile", "Write .typ only, do not run typst") { options[:compile] = false }
  parser.on("--pin-projects IDS", "Comma-separated project ids to force into Selected Projects, in order") { |v| options[:pin_projects] = v }
  parser.on("--pin-experience IDS", "Comma-separated experience ids to force into Experience, in order") { |v| options[:pin_experience] = v }
  parser.on("--location LOC", "Override the contact-line location (e.g. the target city)") { |v| options[:location] = v }
  parser.on("--phone PHONE", "Override the contact-line phone number") { |v| options[:phone] = v }
  parser.on("--eligibility TEXT", "Work-authorisation/mobility line under the contact details") { |v| options[:eligibility] = v }
  parser.on("--overlay PATH", "Private overlay YAML merged over the portfolio data") { |v| options[:overlay] = v }
  parser.on("--max-projects N", Integer,
            "Cap Selected Projects below the default #{Ranking::PROJECT_LIMIT}. The template sits within\n"\
            "                                     a line of one page, so a profile with long project highlights spills onto a\n"\
            "                                     second page carrying nothing but Certifications. Dropping one project is the\n"\
            "                                     cheapest way back.") { |v| options[:max_projects] = v }
  parser.on("--projects-first", "Put Selected Projects above Experience") { options[:projects_first] = true }
  parser.on("--explain-ranking", "Print project scores and matched terms to stderr") { options[:explain] = true }
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

# --- Private overlay -----------------------------------------------------------
# The portfolio YAML is published: it drives this repo's public website. The CV is
# not published, and a CV is allowed to say the same true things in the language of
# the business problem they solved, which is not the language a portfolio page wants.
# So the sharper wording lives in a file outside this repo and is merged in here.
#
# Merge is per top-level key, overlay wins: an overlay entry giving `highlights:`
# replaces the whole list rather than appending to it, because appending would
# silently produce an entry that argues with itself. Patching an id that does not
# exist is an error; an addition has to say so with `op: add`, so a typo cannot
# quietly put a half-empty block on the CV.
#
# There is deliberately no auto-discovered default. A file that applies itself would
# turn every future CV — web, Go, backend — into whichever profile was written last,
# and regenerating an application months later would produce a different document
# than the one that was sent.
def overlay_path(option)
  return nil if option == false || option.nil? || option.to_s.strip.empty?

  path = File.expand_path(option.to_s)
  abort("Overlay not found: #{path}") unless File.file?(path)
  path
end

def load_overlay(path)
  return {} if path.nil?

  data = YAML.load_file(path)
  abort("#{path}: overlay must be a YAML mapping") unless data.is_a?(Hash)

  unknown = data.keys - OVERLAY_KEYS
  abort("#{path}: unknown overlay key(s) #{unknown.join(', ')}; expected #{OVERLAY_KEYS.join(', ')}") unless unknown.empty?

  # `summary: Applied AI engineer.` instead of `summary: {en: ...}` is the easy
  # mistake, and it does not fail on its own: String#[] takes a string argument, so
  # the lookup below would quietly put the word "en" at the top of the CV.
  # Keys are checked too: YAML turns a bare `no:` into the boolean false, so a
  # Norwegian summary would parse fine and then never be found by a string lookup.
  summary = data["summary"]
  unless summary.nil? || (summary.is_a?(Hash) && summary.all? { |lang, text|
    lang.is_a?(String) && !lang.strip.empty? && (text.nil? || text.is_a?(String))
  })
    abort("#{path}: 'summary' must be a mapping of language to text, e.g. summary: {en: ...}")
  end

  data
end

OVERLAY_KEYS = %w[summary experiences projects].freeze

def merge_overlay(items, patches, kind, prepend_new: false)
  abort("overlay: '#{kind}s' must be a list") unless patches.nil? || patches.is_a?(Array)

  by_id = {}
  items.each { |item| by_id[item["id"].to_s.downcase] = item }

  added = []
  seen = []
  array(patches).each do |patch|
    abort("overlay: every #{kind} entry needs an id") unless patch.is_a?(Hash) && !patch["id"].to_s.empty?

    id = patch["id"].to_s.downcase
    abort("overlay: #{kind} '#{id}' patched twice") if seen.include?(id)

    seen << id
    op = (patch["op"] || "patch").to_s
    patch = patch.reject { |key, _| key == "op" }
    case op
    when "patch"
      abort("overlay: no #{kind} with id '#{id}' to patch (typo?)") unless by_id.key?(id)

      by_id[id] = by_id[id].merge(patch)
    when "add"
      abort("overlay: #{kind} '#{id}' already exists; drop `op: add` to patch it") if by_id.key?(id)
      abort("overlay: added #{kind} '#{id}' needs a title") if patch["title"].to_s.empty?

      by_id[id] = patch
      added << patch
    else
      abort("overlay: #{kind} '#{id}' has unknown op '#{op}' (expected patch or add)")
    end
  end

  kept = items.map { |item| by_id[item["id"].to_s.downcase] }
  prepend_new ? added + kept : kept + added
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

# Escapes for Typst *content* mode (inside [...]), where markup chars are live.
def typst_escape_content(text)
  text.to_s
      .gsub("\u00A0", " ")
      .gsub(/[\\#\[\]*_@$`<>~]/) { |c| "\\#{c}" }
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
    "Website για τη Κτηνιατρική με ενσωματωμένο linear solver για βελτιστοποίηση διατροφής ζώων." => "Veterinary web platform with an embedded linear solver for animal diet optimization.",
    "Εφαρμογή προτάσεων ταινιών/σειρών με AI, που λαμβάνει υπόψη το ιστορικό του χρήστη για personalized recommendations." => "A movie and series recommendation app that uses AI and a user's history for personalized suggestions."
  }

  # Fallback for un-translated Greek: strip non-ASCII, then drop any leading
  # punctuation/whitespace the stripping leaves behind (e.g. "ταινιών/σειρών" ->
  # a dangling "/") so the result never starts with markup that breaks Typst.
  translations.fetch(original,
    ascii_text(original).squeeze(" ").strip.sub(/\A[[:punct:][:space:]]+/, ""))
end

def normalize(text)
  Ranking.normalize(text)
end

# The original list, kept deliberately: `keywords` feeds experience ranking, highlight
# ordering and the developer-target check, none of which were the problem. Ranking has
# its own, much longer list, which only makes sense alongside its rarity weighting.
STOPWORDS = %w[
  and the for with from this that your you are will have has into using use role
  developer engineer software full stack backend frontend senior junior mid experience
  σε και για την τον των που με από στο στη στην είναι θα έχει ως ένα μια
]

def keywords(text)
  normalize(text).split.uniq.reject { |w| w.length < 3 || STOPWORDS.include?(w) }
end

# "JavaScript/TypeScript" has to match a posting that only says TypeScript, and
# "Swift (macOS)" one that only says Swift — so a skill matches on any of its
# slash/ampersand-separated parts as well as on the whole phrase.
def skill_needles(name)
  base = name.to_s.gsub(/\([^)]*\)/, " ")
  (base.split(%r{[/&]}) << base)
    .map(&:strip)
    .reject { |part| normalize(part).strip.length < 2 }
    .uniq
end

# Names this short double as ordinary English words ("Go", "R", "C"), so they only
# count when the posting spells them with the skill's own capitalisation — otherwise
# "go above and beyond" puts Go on the CV of someone the team never asked it of.
AMBIGUOUS_MAX_LEN = 3

# Boundary-anchored so "Go" doesn't match "Google", "SQL" doesn't match
# "PostgreSQL", and "Git" doesn't match "GitHub".
def skill_hits(needles, ctx_norm, ctx_raw)
  needles.sum do |needle|
    normalized = normalize(needle).strip
    if normalized.length <= AMBIGUOUS_MAX_LEN
      ctx_raw.scan(/(?<![[:alnum:]])#{Regexp.escape(needle)}(?![[:alnum:]])/).size
    else
      ctx_norm.scan(/(?<![[:alnum:]])#{Regexp.escape(normalized)}(?![[:alnum:]])/).size
    end
  end
end

# Experiences keep the original keyword count on purpose. The rarity-weighted scorer
# is tuned for the 25 projects, which have deep technology/skill lists; the 11
# experiences are thin by comparison, so their scores collapse to near-ties and the
# order falls to tie-breaks — which put "Military Service, Fire Rescue" on a
# full-stack CV. Ranking the work history was never the problem being solved here.
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

# Shared by both pin flags. Duplicates collapse rather than abort: a repeated id is
# unambiguous about what was wanted, unlike an unknown id or an over-long list, and
# pin_projects_test.rb pins that behaviour down deliberately.
def parse_pin_ids(raw)
  raw.to_s.split(",").map { |id| id.strip.downcase }.reject(&:empty?).uniq
end

# Project descriptions are portfolio prose written for the website, where four lines
# are fine; on the CV each one gets about one. The first sentence is where every entry
# states what the thing is, so it survives and the rest goes. Abbreviations keep their
# dot because the split needs whitespace after it ("gov.gr" stays intact).
def first_sentence(text, limit = 200)
  s = text.to_s.strip.gsub(/\s+/, " ")
  s = s[/\A.*?[.!?](?=\s|\z)/] || s
  return s if s.length <= limit

  # A cut inside a clause leaves "...that week," on the page; an ATS and a reader both
  # take that for a typo.
  s[0, limit].sub(/\s+\S*\z/, "").sub(/[\s,;:]+\z/, "")
end

# "https://www.linkedin.com/in/x/" -> "linkedin.com/in/x": the URL as printed text, which
# is what an ATS can read even when it ignores the PDF's link annotations.
def url_label(url)
  url.to_s.sub(%r{\Ahttps?://(www\.)?}, "").chomp("/")
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

overlay = load_overlay(overlay_path(options[:overlay]))

profile = personal["profile"]
# Per-application contact overrides (e.g. present the target city / a local number).
# dup so we never mutate the loaded YAML across a batch run.
profile = profile.dup
profile["location"] = options[:location] if options[:location] && !options[:location].strip.empty?
profile["phone"] = options[:phone] if options[:phone] && !options[:phone].strip.empty?
# The phone number stays out of the public repo: cv/private.yaml is gitignored.
private_path = File.join(__dir__, "private.yaml")
profile["phone"] ||= YAML.load_file(private_path)["phone"] if File.exist?(private_path)
experiences = merge_overlay(array(experience["experiences"]), overlay["experiences"],
                            "experience", prepend_new: true)
project_items = merge_overlay(array(projects), overlay["projects"], "project")

# Ranked terms are stemmed/aliased; `wanted` stays raw for the keyword checks below
# and for highlight ordering, which compare against literal word lists.
ranked_terms = Ranking.wanted_weights(context)

eligible_projects = project_items.select { |item| item["featured"] != false }

# Rarity only means something relative to the items competing for the slot, so the
# corpus is exactly the pool a pick comes from — no experiences, no unfeatured
# projects diluting a term's rarity.
project_scorer = Ranking::Scorer.new(eligible_projects)

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

ranked_projects = eligible_projects
                  .map { |item| [item, project_scorer.score(item, ranked_terms)] }
                  .sort_by do |item, score|
                    # Prose breaks ties before the curated weight does. Items with no
                    # structured match all score 0, and the last slot often falls to
                    # them; ordering those by static weight ignores the posting
                    # entirely, so the prose it did match decides instead.
                    _, prose = project_scorer.split_score(item, ranked_terms)
                    [-score, -prose, -(item["weight"] || 0), item["title"].to_s]
                  end
                  .map(&:first)

# A pinned selection is a deliberate override of the ranking, so it wins over the
# `featured` filter too, and an id that does not exist is an error rather than a
# silently dropped pin — the whole point is that the pick survives regeneration.
pinned_ids = parse_pin_ids(options[:pin_projects])
projects_by_id = {}
project_items.each do |item|
  id = item["id"].to_s.downcase
  # Two projects under one id would make a pin resolve to whichever came last.
  abort("Duplicate project id in projects.yaml: #{id}") if projects_by_id.key?(id)
  projects_by_id[id] = item
end

unknown = pinned_ids.reject { |id| projects_by_id.key?(id) }
abort("Unknown --pin-projects id(s): #{unknown.join(", ")}") unless unknown.empty?
project_limit = options[:max_projects] || Ranking::PROJECT_LIMIT
if project_limit < 1 || project_limit > Ranking::PROJECT_LIMIT
  abort("--max-projects must be between 1 and #{Ranking::PROJECT_LIMIT}, got #{project_limit}")
end
if pinned_ids.length > project_limit
  abort("--pin-projects takes at most #{project_limit} ids, got #{pinned_ids.length}")
end

pinned_projects = pinned_ids.map { |id| projects_by_id[id] }

# Same override for experience. The ranker scores an entry on the posting's own
# vocabulary, so a role whose terms the posting never uses (open source ML work
# against a generic web-dev ad) sinks below weaker but better-matching entries.
pinned_exp_ids = parse_pin_ids(options[:pin_experience])
experiences_by_id = {}
experiences.each do |item|
  id = item["id"].to_s.downcase
  abort("Duplicate experience id in experience.yaml: #{id}") if experiences_by_id.key?(id)
  experiences_by_id[id] = item
end

unknown_exp = pinned_exp_ids.reject { |id| experiences_by_id.key?(id) }
abort("Unknown --pin-experience id(s): #{unknown_exp.join(", ")}") unless unknown_exp.empty?
if pinned_exp_ids.length > Ranking::EXPERIENCE_LIMIT
  abort("--pin-experience takes at most #{Ranking::EXPERIENCE_LIMIT} ids, got #{pinned_exp_ids.length}")
end

pinned_experiences = pinned_exp_ids.map { |id| experiences_by_id[id] }
selected_experiences = (pinned_experiences + (ranked_experiences - pinned_experiences)).first(Ranking::EXPERIENCE_LIMIT)
selected_projects = (pinned_projects + (ranked_projects - pinned_projects)).first(project_limit)

if options[:explain]
  warn "\n# project ranking (#{eligible_projects.length} eligible, top #{project_limit} selected)"
  warn "# pinned: #{pinned_ids.empty? ? "(none)" : pinned_ids.join(", ")}"
  ranked_projects.each_with_index do |item, index|
    score = project_scorer.score(item, ranked_terms)
    top = project_scorer.matches(item, ranked_terms).first(6)
                        .map { |term, weight, points| "#{term}(x#{weight}=#{points.round(2)})" }
    marker = selected_projects.include?(item) ? "*" : " "
    warn format("%s %2d. %-34s %6.2f  %s", marker, index + 1, item["title"], score, top.join(" "))
  end
end

skill_groups = skills["skills"] || {}
flat_skills = skill_groups.values.flatten.map { |s| s["name"] }.compact
# One ranking feeds both the Skills list and the "Focus:" line. They used to differ: Skills
# matched the short keyword list by substring and sorted unstably, so a skill the summary
# called out (Go) could be missing from the list while Hugo and Astro were in it. Ties go
# to the shorter name, then to the order in skills.yaml, and with no target at all the
# yaml order stands.
ctx_norm = normalize(context)
skill_hits_by_name = flat_skills.to_h { |skill| [skill, skill_hits(skill_needles(skill), ctx_norm, context)] }
skill_rank = flat_skills.each_with_index.sort_by do |skill, index|
  hits = skill_hits_by_name[skill]
  [-hits, hits.positive? ? skill.length : 0, index]
end.map(&:first).uniq
ordered_skills = skill_rank.first(16)

# The default summary sells a full-stack web developer. When the overlay supplies one
# (`summary: {en:, el:}`) it wins: the same person is a different headline depending on
# whether the target is a web role or an applied-AI one, and only the CV needs to know.
overlay_summary = (overlay["summary"] || {})[language]
summary = if overlay_summary && !overlay_summary.to_s.strip.empty?
            overlay_summary.to_s.strip.gsub(/\s+/, " ")
          elsif language == "el"
            "Full-stack developer με εμπειρία σε SvelteKit, Go, Python, data-driven εφαρμογές και end-to-end product delivery. Χτίζω πρακτικά web προϊόντα από τη βάση δεδομένων και το backend μέχρι το frontend, deployment και operations."
          else
            "Full-stack developer with experience in SvelteKit, Go, Python, data-driven applications, and end-to-end product delivery. I build practical web products from database and backend design through frontend, deployment, and operations."
          end

if context.strip.length.positive?
  # Focus terms are the candidate's own skills that the posting actually asks for,
  # ranked by how often the posting mentions them. Ranking raw posting words instead
  # surfaces whatever the ad happens to open with ("Focus: exness, not, just").
  top_terms = skill_rank.select { |skill| skill_hits_by_name[skill].positive? }.first(5).join(", ")
  summary += " Focus: #{top_terms}." if top_terms.length.positive?
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
lines << "#set document(title: \"#{typst_escape(profile["name"])} CV\", author: \"#{typst_escape(profile["name"])}\")"
lines << '#set page(paper: "a4", margin: (x: 1.25cm, y: 1.15cm))'
lines << '#set text(font: "Helvetica", size: 8.8pt, lang: "en")'
lines << '#set par(justify: false, leading: 0.5em)'
lines << '#show link: underline'
lines << '#let section(title) = block(above: 1.25em, below: 0.5em)[#text(size: 10pt, weight: "bold", upper(title)) #v(0.16em) #line(length: 100%, stroke: 0.45pt)]'
lines << '#let entry(title, meta, body) = block(above: 0.34em, below: 0.24em)[#text(weight: "bold", title) #h(1fr) #text(size: 7.9pt, fill: rgb("#444"), meta) #v(0.08em) #body]'
lines << ""
lines << "#align(center)[#text(size: 16pt, weight: \"bold\", \"#{typst_escape(profile["name"])}\")]"
contact_bits = [
  "#link(\"mailto:#{typst_escape(profile["email"])}\")[#{typst_escape_content(profile["email"])}]",
  profile["phone"] ? "#link(\"tel:#{typst_escape(profile["phone"].to_s.gsub(/[^+\d]/, ""))}\")[#{typst_escape_content(profile["phone"])}]" : nil,
  "#text(\"#{typst_escape(profile["location"])}\")",
  "#link(\"#{profile.dig("social", "github")}\")[#{typst_escape_content(url_label(profile.dig("social", "github")))}]",
  "#link(\"#{profile.dig("social", "linkedin")}\")[#{typst_escape_content(url_label(profile.dig("social", "linkedin")))}]",
].compact
lines << "#align(center)[#text(size: 7.8pt)[#{contact_bits.join(" | ")}]]"
# Work authorisation and mobility get their own line rather than being appended to
# the location. They answer a different question ("can I hire this person, and when"),
# and jamming them into the address is how a contact line ends up implying a residence
# nobody claimed.
if options[:eligibility] && !options[:eligibility].strip.empty?
  lines << "#align(center)[#text(size: 8.2pt, fill: rgb(\"#444\"), \"#{typst_escape(options[:eligibility])}\")]"
end
lines << ""
lines << typst_escape(summary)
lines << ""

# Built apart so --projects-first can swap the two sections without duplicating them.
experience_lines = ["#section(\"#{labels[:experience]}\")"]
selected_experiences.each do |item|
  title = item["title_en"] || item["title"]
  org = item["organization_en"] || item["organization"]
  meta = [org, period_text(item["period"])].reject(&:empty?).join(" | ")
  bullets = bullets_for(item, wanted, 3, language)
  body = bullets.map { |b| "- #{typst_escape(b)}" }.join("\n")
  experience_lines << "#entry(\"#{typst_escape(title)}\", \"#{typst_escape(meta)}\")["
  experience_lines << body
  experience_lines << "]"
end
experience_lines << ""

project_lines_out = ["#section(\"#{labels[:projects]}\")"]
selected_projects.each do |item|
  title = item["title"]
  meta = array(item["technologies"]).first(6).join(", ")
  desc = language == "en" ? english_text(item["description"].to_s.strip.gsub(/\s+/, " ")) : item["description"].to_s.strip.gsub(/\s+/, " ")
  desc = first_sentence(desc)
  highlights = bullets_for(item, wanted, 1, language)
  project_lines = [desc]
  project_lines.concat(highlights)
  body = project_lines.reject(&:empty?).first(2).map { |b| "- #{typst_escape(b)}" }.join("\n")
  link = array(item["links"]).first
  title_arg = if link && !link["url"].to_s.strip.empty?
                label = typst_escape_content(link["label"] || "Link")
                "[#link(\"#{typst_escape(link["url"])}\")[#{typst_escape_content(title)} (#{label})]]"
              else
                "\"#{typst_escape(title)}\""
              end
  project_lines_out << "#entry(#{title_arg}, \"#{typst_escape(meta)}\")["
  project_lines_out << body
  project_lines_out << "]"
end
project_lines_out << ""
lines.concat(options[:projects_first] ? project_lines_out + experience_lines : experience_lines + project_lines_out)

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

# Greek postings routinely list completed service as a hard requirement, and the
# service entry loses the top-4 experience cut on any developer CV. It is folded into
# the certifications line rather than given a #section or even an #entry of its own:
# measured, both spill this one-page CV onto a second page, because the template runs
# within a line of the page limit. A clause on an existing paragraph costs no block.
military = experiences.find { |item| item["military"] }
military_note = if military
                  years = [military.dig("period", "start"), military.dig("period", "end")]
                          .compact.map { |v| v.to_s[0, 4] }.uniq.join(" - ")
                  status = language == "el" ? "Εκπληρωμένες" : "Completed"
                  # Prefer the org's own abbreviation ("Hellenic Air Force (HAF)" -> HAF):
                  # the full name inside a parenthetical nests brackets and costs the
                  # characters that decide whether this line wraps.
                  org = (military["organization_en"] || military["organization"]).to_s
                  org = org[/\(([^)]+)\)/, 1] || org
                  label = language == "el" ? "Στρατιωτικά" : "Military service"
                  "#{label}: #{status} (#{[org, years.delete(" ")].reject(&:empty?).join(", ")})"
                end

certifications = array(education["certifications"]).first(4)
unless certifications.empty? && military_note.nil?
  lines << ""
  lines << "#section(\"#{labels[:certifications]}\")"
  cert_line = certifications.map { |cert| "#{cert["name"]} (#{cert["issuer"]})" }
                            .push(military_note).compact.join(" | ")
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
