# frozen_string_literal: true

require "set"

# Ranks portfolio items (projects, experiences) against a job posting.
#
# The scoring answers one question: which of these items does the posting single
# out? So the weighting is relative to the portfolio itself — a term that shows up
# in every project ("data", "performance") says nothing about which project to
# pick, while a term in one or two ("sql", "whisper") says almost everything. A
# plain keyword count gets this backwards and just rewards whichever project has
# the longest prose.
module Ranking
  PROJECT_LIMIT = 4
  EXPERIENCE_LIMIT = 4

  # Field weights. Structured fields are the candidate's own claim about what an
  # item *is*; description prose is where a project drifts into generic language,
  # so it is worth least. Organization is excluded outright — a company name is
  # not evidence of relevance, it just collides with posting boilerplate.
  TIER_SIGNAL = 3.0    # technologies, skills, subtitle
  TIER_TITLE = 2.5
  TIER_HIGHLIGHT = 1.0
  TIER_DESCRIPTION = 0.5

  # Structured fields are labels the portfolio chose deliberately; prose is where
  # anything can be said. Only the former is treated as evidence in its own right.
  STRUCTURED_TIERS = [TIER_SIGNAL, TIER_TITLE].freeze

  # Folded before stemming, because these pairs differ by more than a suffix.
  # Deliberately small and portfolio-specific: every entry here is a term that
  # actually appears in the postings or in data/portfolio.
  ALIASES = {
    "vuejs" => "vue", "vue.js" => "vue",
    "nodejs" => "node", "node.js" => "node",
    "nextjs" => "next", "next.js" => "next",
    "golang" => "go",
    "postgres" => "postgresql", "psql" => "postgresql",
    "k8s" => "kubernetes",
    # A real plural that the "-is" guard below would otherwise protect, as if it
    # were "axis" or "redis".
    "apis" => "api",
    # The analyst/analytics/analysis family: a posting says "Analyst" where the
    # portfolio says "Analytics", and no suffix rule bridges those two.
    "analytics" => "analysis", "analytic" => "analysis", "analytical" => "analysis",
    "analyst" => "analysis", "analysts" => "analysis",
    "analyze" => "analysis", "analyzes" => "analysis", "analyzed" => "analysis",
    "analyzing" => "analysis", "analyse" => "analysis", "analyses" => "analysis",
    "analysing" => "analysis", "analysed" => "analysis",
    "reporting" => "report", "reports" => "report",
    "queries" => "query", "querying" => "query", "queried" => "query",
    "aggregation" => "aggregate", "aggregations" => "aggregate",
    "aggregating" => "aggregate", "aggregated" => "aggregate"
  }.freeze

  # Terms shorter than this are dropped: two-letter words are almost all noise.
  MIN_TERM_LENGTH = 3

  # ...except these, which are real technologies whose names are too short to survive
  # that floor. "Go" is the one that matters here — several postings ask for it and
  # never write "Golang", and half the portfolio is written in it, so dropping the
  # term silently costs exactly the projects the posting wants. They only count when
  # the posting spells them as a name ("Go", "GO"), never as the English verb in
  # "go above and beyond".
  SHORT_TECHNOLOGIES = %w[go ai ml bi].freeze

  # Rarity is measured against the portfolio, which answers "which of my projects does
  # this word single out" but not "is this word worth anything at all". A word like
  # "because" or "think" is rare across the portfolio and so scores high, purely for
  # appearing in one project's prose. Only a real stopword list keeps that noise out,
  # so this covers function words and generic posting filler — not domain vocabulary
  # ("data", "report", "search" stay in, and portfolio rarity judges those).
  STOPWORDS = %w[
    a about above across after again against all almost along already also although
    always am among an and another any anyone anything are around as at back be became
    because become been before being below best better between both bring build built
    but by came can cannot come coming could create created creating currently day days
    deliver delivered delivering did different do does doing done down drive driven
    during each early edge either else enable enabled enabling end ensure ensured
    ensuring enough etc even ever every everything except existing expect far few find
    first focus follow following for from further get give given giving going good
    goes gone got great had handle handling has have having help helping her here high
    him his how
    however identify identifying if implement implementing improve improving in include
    included includes including into is it its itself join just keep key kind know known
    large last later lead leading learn least less let level like likely little long
    look looking made main make makes making manage many may maybe me mean means might
    more most much must my need needed needs never new next no non none nor not now of
    off often on once one only open or other others our out over own part people per
    perform place plus possible provide provided providing put rather real really
    require required requirements right run running said same say see seem set several
    shall she should show side since so some someone something soon start started still
    such support supporting sure take taken taking team than that the their them then
    there these they thing things think this those though three through thus time times
    to together too took top toward turn two under understand understanding until up
    upon us usually various very via want was way we well went were what when where
    whether which while who whole why will with within without work working works would
    write writing written yet you your yours
    developer engineer software full stack backend frontend senior junior mid experience
    role position job company candidate applicant apply hiring years year strong ability
    able excellent knowledge skills skill plus preferred nice must responsibilities
    qualifications benefits salary remote office fulltime
    platform platforms system systems solution solutions application applications
    service services product products tool tools feature features project projects
    technology technologies user users customer customers business team teams
    development environment environments practice practices process processes
    σε και για την τον των που με από στο στη στην είναι θα έχει ως ένα μια
    ή αν όχι όταν όπως μας σας τους τις στους στις κάθε πολύ πιο
  ].freeze

  module_function

  # Stopwords are written in their natural form, but matching happens on canonical
  # terms — so they have to be canonicalised too, or "developers" walks straight past
  # a list containing "developer".
  def stopword_terms
    @stopword_terms ||= STOPWORDS.map { |w| canonical(w) }.to_set
  end

  def normalize(text)
    text.to_s.downcase.gsub(/[^[:alnum:]α-ωάέήίόύώϊϋΐΰ\+\#\.]+/i, " ")
  end

  # Crude on purpose, and applied to BOTH sides of every comparison — the posting's
  # words and the portfolio's. It does not need to produce real English stems, only
  # to land related words on the same string. Rules apply in sequence.
  def stem(token)
    t = token.to_s
    return t if t.length <= 3 # "sql", "api", "aws", "go" are words in their own right

    # 1. plurals
    if t.end_with?("ies")
      t = t[0..-4] + "y"
    elsif t.end_with?("sses")
      t = t[0..-3]
    elsif t.end_with?("s") && !(t.end_with?("ss") || t.end_with?("us") || t.end_with?("is"))
      t = t[0..-2]
    end

    # 2. verb suffixes, only when a real stem is left behind ("string" survives)
    if t.end_with?("ing") && t.length >= 7
      t = t[0..-4]
    elsif t.end_with?("ed") && t.length >= 6
      t = t[0..-3]
    end

    # 3. trailing vowel, so "scale"/"scaling" and "manage"/"managed" converge
    t = t[0..-2] if t.end_with?("e") && t.length >= 5
    t
  end

  # `normalize` keeps "." so "vue.js" and "node.js" survive, which leaves sentence
  # punctuation stuck to prose words — "data." would otherwise be a different term
  # from "data". Interior dots stay.
  def trim(token)
    token.gsub(/\A\.+|\.+\z/, "")
  end

  def canonical(token)
    t = trim(token)
    stem(ALIASES.fetch(t, t))
  end

  def tokens(text)
    normalize(text).split.map { |w| canonical(w) }.reject(&:empty?)
  end

  # Splits on the same rule as `normalize` but keeps capitalisation, which is the only
  # thing telling "Go" the language from "go" the verb.
  def raw_words(text)
    text.to_s.gsub(/[^[:alnum:]α-ωΑ-Ωάέήίόύώϊϋΐΰ\+\#\.]+/i, " ").split
  end

  # A short technology name counts only where the posting capitalises it. Lowercase
  # "go" in running prose is the verb; "Go" or "GO" standing alone is the language.
  def names_short_technology?(word)
    word == word.upcase || word == word.capitalize
  end

  # The posting's terms in order of appearance, repeats included, so wanted_weights
  # can count them. Length/stopword filtering happens on the raw word, which is what
  # keeps the stopword list readable.
  def wanted_terms(context)
    raw_words(context).each_with_object([]) do |raw, out|
      word = trim(raw.downcase)
      next if word.empty? || STOPWORDS.include?(word)

      if word.length < MIN_TERM_LENGTH
        next unless SHORT_TECHNOLOGIES.include?(word) && names_short_technology?(trim(raw))
      end

      term = canonical(word)
      out << term unless term.empty? || stopword_terms.include?(term)
    end
  end

  # term => emphasis, bounded hard at 1.5. A posting that says "Python" six times and
  # "employee" once means the first more than the second. The bound is what keeps this
  # from becoming the same bug in a new place: unbounded frequency would just trade
  # portfolio-length bias for posting-length bias, letting repetitive boilerplate win.
  def wanted_weights(context)
    counts = Hash.new(0)
    wanted_terms(context).each { |term| counts[term] += 1 }
    counts.each_with_object({}) do |(term, count), out|
      out[term] = case count
                  when 1 then 1.0
                  when 2 then 1.25
                  else 1.5
                  end
    end
  end

  def array(value)
    value.is_a?(Array) ? value : []
  end

  def highlight_text(value)
    case value
    when Hash
      [value["text"], value["metric"], value["detail"]].compact.join(" ")
    else
      value.to_s
    end
  end

  # term => the best field weight it appears at, for one item. A term counts once
  # per item no matter how often it repeats or how many fields carry it, so padding
  # an item with prose can never raise its score.
  def term_weights(item)
    fields = [
      [TIER_SIGNAL, [array(item["technologies"]).join(" "),
                     array(item["skills"]).join(" "),
                     item["subtitle"]]],
      [TIER_TITLE, [item["title"], item["title_en"]]],
      [TIER_HIGHLIGHT, [array(item["highlights"]).map { |h| highlight_text(h) }.join(" ")]],
      [TIER_DESCRIPTION, [item["description"]]]
    ]

    weights = {}
    fields.each do |tier, parts|
      tokens(parts.compact.join(" ")).each do |term|
        weights[term] = tier if tier > (weights[term] || 0.0)
      end
    end
    weights
  end

  # Scores items against one posting, weighting each match by how rare the term is
  # across the items being ranked. The corpus must be exactly the pool a pick comes
  # from: mixing experiences into the project corpus would let documents that can
  # never be selected as a project drag a term's rarity down.
  class Scorer
    def initialize(corpus)
      # Keyed by identity, not by value: two portfolio items with equal contents are
      # still separate documents. Holding the items as keys also keeps them alive, so
      # unlike an object_id key this cannot be invalidated by GC reusing an id.
      @weights = {}.compare_by_identity
      corpus.each { |item| @weights[item] = Ranking.term_weights(item) }

      @n = corpus.size
      @df = Hash.new(0)
      @weights.each_value { |w| w.each_key { |term| @df[term] += 1 } }
    end

    # BM25-style. A term in every item lands near 0 rather than at some floor, so no
    # pile of generic matches can out-vote a single rare one.
    def idf(term)
      df = @df[term]
      Math.log(1 + ((@n - df + 0.5) / (df + 0.5)))
    end

    # Prose can at most double an item's structured score, and an item with no
    # structured match scores zero no matter how much matching prose it carries.
    #
    # This is the load-bearing rule. Rarity is measured against the portfolio, so a
    # word that is merely rare *here* — "background", "previous", "scam" — looks as
    # precious as "orchestration". Left unchecked, a project with six such words in
    # its highlights outranks one that genuinely names the posting's stack, which is
    # how the old keyword count failed too. Prose is corroboration, not evidence.
    def score(item, wanted)
      structured, prose = split_score(item, wanted)
      structured + [prose, structured].min
    end

    # `wanted` is term => posting emphasis, from Ranking.wanted_weights.
    def split_score(item, wanted)
      weights = @weights[item] || Ranking.term_weights(item)
      structured = 0.0
      prose = 0.0
      wanted.each do |term, emphasis|
        weight = weights[term]
        next unless weight

        points = idf(term) * weight * emphasis
        if Ranking::STRUCTURED_TIERS.include?(weight)
          structured += points
        else
          prose += points
        end
      end
      [structured, prose]
    end

    # [term, field weight, contribution] for whatever actually matched, so ranking
    # decisions can be inspected instead of guessed at.
    # Reports what each term actually contributed *after* the prose cap, not its
    # uncapped value — an explain line that does not add up to the score it explains
    # is worse than none, since tuning is done by reading it.
    def matches(item, wanted)
      weights = @weights[item] || Ranking.term_weights(item)
      found = wanted.map { |term, emphasis|
        weight = weights[term]
        weight ? [term, weight, idf(term) * weight * emphasis] : nil
      }.compact

      structured, prose = split_score(item, wanted)
      # The cap scales every prose term by the same factor, so the parts still sum
      # to the total.
      scale = prose.zero? ? 0.0 : [prose, structured].min / prose

      found.map { |term, weight, points|
        points *= scale unless Ranking::STRUCTURED_TIERS.include?(weight)
        [term, weight, points]
      }.reject { |_, _, points| points.zero? }.sort_by { |m| -m[2] }
    end
  end
end
