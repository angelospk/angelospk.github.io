# frozen_string_literal: true

# ruby cv/ranking_test.rb
require "minitest/autorun"
require_relative "ranking"

def project(id, title: "T", subtitle: nil, description: nil, technologies: [], skills: [], highlights: [])
  {
    "id" => id, "title" => title, "subtitle" => subtitle, "description" => description,
    "technologies" => technologies, "skills" => skills, "highlights" => highlights
  }
end

class StemTest < Minitest::Test
  def test_short_tokens_are_left_alone
    # "sql" -> "sq" would make it match nothing; "aws" -> "aw" likewise.
    %w[sql api aws git go ai ml c#].each { |t| assert_equal t, Ranking.stem(t) }
  end

  def test_plurals_converge
    { "reports" => "report", "queries" => "query",
      "classes" => "class", "dashboards" => "dashboard" }.each do |input, want|
      assert_equal want, Ranking.stem(input)
    end
  end

  def test_words_ending_in_ss_us_is_keep_their_s
    # "redis" -> "redi" and "axis" -> "axi" would quietly break real technology names.
    %w[redis axis less status].each { |t| assert_equal t, Ranking.stem(t) }
  end

  def test_verb_suffixes_converge_with_their_base
    assert_equal Ranking.stem("scaling"), Ranking.stem("scale")
    assert_equal Ranking.stem("managed"), Ranking.stem("manage")
    assert_equal Ranking.stem("caching"), Ranking.stem("cache")
  end

  def test_ing_stripping_leaves_real_words_intact
    assert_equal "string", Ranking.stem("string")
  end

  def test_stemming_is_deterministic_under_repetition
    assert_equal Ranking.stem("settings"), Ranking.stem(Ranking.stem("settings"))
  end
end

class AliasTest < Minitest::Test
  def test_analyst_family_converges
    canon = %w[analyst analytics analysis analyze analyzes analysed analytical]
            .map { |w| Ranking.canonical(w) }.uniq
    assert_equal 1, canon.size, "analyst-family words must land on one term, got #{canon.inspect}"
  end

  def test_punctuated_and_short_technology_names
    assert_equal Ranking.canonical("apis"), Ranking.canonical("api")
    assert_equal Ranking.canonical("vue.js"), Ranking.canonical("vue")
    assert_equal Ranking.canonical("nodejs"), Ranking.canonical("node.js")
    assert_equal Ranking.canonical("postgres"), Ranking.canonical("postgresql")
    assert_equal Ranking.canonical("golang"), Ranking.canonical("go")
  end

  def test_go_the_language_is_a_term_even_though_it_is_two_letters
    # Postings ask for "Go" and never write "Golang", and much of the portfolio is Go,
    # so dropping the term below the length floor loses exactly the right projects.
    assert_includes Ranking.wanted_terms("Backend engineer. Go and Python."), "go"
    assert_includes Ranking.wanted_terms("We use GO and gRPC"), "go"
    assert_includes Ranking.wanted_terms("Golang microservices"), "go"
  end

  def test_go_the_verb_is_not_a_term
    refute_includes Ranking.wanted_terms("we go above and beyond for customers"), "go"
    refute_includes Ranking.wanted_terms("things that go wrong"), "go"
  end

  def test_inflected_stopwords_do_not_leak_through
    # Filtering happens on the raw word but matching on the canonical one, so the
    # stopword list has to be canonicalised or "developers" walks straight past
    # "developer".
    terms = Ranking.wanted_terms("developers and engineers building applications")
    assert_empty terms
  end

  def test_short_words_that_are_not_technologies_stay_out
    refute_includes Ranking.wanted_terms("An Ideal Candidate Is Someone"), "is"
  end

  def test_sql_and_sqlite_stay_distinct
    # The old substring scorer counted "sql" as a hit against "sqlite".
    refute_equal Ranking.canonical("sql"), Ranking.canonical("sqlite")
    refute_equal Ranking.canonical("sql"), Ranking.canonical("postgresql")
  end
end

class ScorerTest < Minitest::Test
  def setup
    @sql = project("sql", title: "Diesi Analytics", subtitle: "Radio Analytics",
                   technologies: %w[SQL Python],
                   description: "Reporting queries over play data records.")
    @web = project("web", title: "Booking Site", subtitle: "Travel",
                   technologies: %w[SvelteKit], description: "Data and reports and performance.")
    @app = project("app", title: "Ordering", subtitle: "Hospitality",
                   technologies: %w[Go], description: "Data reports performance search data reports.")
    @corpus = [@sql, @web, @app]
    @scorer = Ranking::Scorer.new(@corpus)
  end

  def test_rare_term_outranks_a_pile_of_ubiquitous_ones
    wanted = Ranking.wanted_weights("sql data reports performance")
    assert_operator @scorer.score(@sql, wanted), :>, @scorer.score(@app, wanted)
  end

  def test_term_in_every_item_carries_almost_no_weight
    # "data" is in all three descriptions, "sql" in one. Asserted as a ratio because
    # the floor of a 3-item corpus is coarse; over the real 25 it collapses further.
    ubiquitous = @scorer.idf(Ranking.canonical("data"))
    rare = @scorer.idf(Ranking.canonical("sql"))
    assert_operator ubiquitous, :<, rare * 0.2
  end

  def test_posting_emphasis_is_bounded
    # Repetition in the posting counts, but only up to 1.5x — otherwise a verbose ad
    # that repeats itself would win on volume, which is the bug in a new costume.
    once = @scorer.score(@sql, Ranking.wanted_weights("sql"))
    thrice = @scorer.score(@sql, Ranking.wanted_weights("sql sql sql"))
    flooded = @scorer.score(@sql, Ranking.wanted_weights("sql " * 50))

    assert_operator thrice, :>, once
    assert_equal thrice, flooded
    assert_in_delta once * 1.5, flooded, 0.001
  end

  def test_repeating_a_term_within_an_item_does_not_inflate
    plain = project("a", title: "Reports", technologies: ["SQL"], description: "sql")
    padded = project("b", title: "Reports", technologies: ["SQL"],
                     description: "sql sql sql sql sql sql sql sql")
    scorer = Ranking::Scorer.new([plain, padded])
    wanted = Ranking.wanted_weights("sql")
    assert_equal scorer.score(plain, wanted), scorer.score(padded, wanted)
  end

  def test_appending_unrelated_prose_does_not_change_the_score
    lean = project("a", title: "X", technologies: ["SQL"], description: "Short.")
    verbose = project("b", title: "X", technologies: ["SQL"],
                      description: "Short. " + ("We collaborate with stakeholders. " * 40))
    scorer = Ranking::Scorer.new([lean, verbose])
    wanted = Ranking.wanted_weights("sql")
    assert_equal scorer.score(lean, wanted), scorer.score(verbose, wanted)
  end

  def test_a_term_in_two_fields_counts_once_at_the_better_tier
    both = project("a", title: "Redis", technologies: ["Redis"], description: "redis redis")
    weights = Ranking.term_weights(both)
    assert_equal Ranking::TIER_SIGNAL, weights[Ranking.canonical("redis")]
  end

  def test_technology_match_beats_the_same_word_buried_in_prose
    tech = project("a", title: "X", technologies: ["Redis"])
    prose = project("b", title: "Y", description: "We once considered redis.")
    scorer = Ranking::Scorer.new([tech, prose])
    wanted = Ranking.wanted_weights("redis")
    assert_operator scorer.score(tech, wanted), :>, scorer.score(prose, wanted)
  end

  def test_document_frequency_counts_an_item_once
    repeated = project("a", title: "Go Go Go", technologies: %w[Go Go], description: "go go go")
    other = project("b", title: "X")
    scorer = Ranking::Scorer.new([repeated, other])
    # df(go) must be 1 of 2 docs, not 6 — which would push idf negative.
    assert_operator scorer.idf(Ranking.canonical("go")), :>, 0
  end

  def test_organization_is_not_scored
    item = project("a", title: "X").merge("organization" => "Revolut")
    assert_nil Ranking.term_weights(item)[Ranking.canonical("revolut")]
  end

  def test_no_match_scores_zero
    assert_equal 0.0, @scorer.score(@sql, Ranking.wanted_weights("kubernetes helm"))
  end

  def test_prose_alone_cannot_manufacture_a_match
    # The failure this whole scorer exists to prevent: a project whose highlights
    # happen to share ordinary words with the posting, but which names none of what
    # the posting actually asks for, must not score at all.
    prose_only = project("a", title: "X", subtitle: "Y", technologies: ["Svelte"],
                         description: "We improved throughput and latency for users.")
    scorer = Ranking::Scorer.new([prose_only, project("b", title: "Z")])
    assert_equal 0.0, scorer.score(prose_only, Ranking.wanted_weights("throughput latency"))
  end

  def test_prose_cannot_outweigh_a_genuine_structured_match
    # Modelled on the real regression: Nightshift named the posting's stack while a
    # rival won on six unrelated prose words.
    real = project("a", title: "Nightshift", subtitle: "Agent Orchestration",
                   technologies: %w[Python], description: "Runs overnight.")
    padded = project("b", title: "Trainer", subtitle: "Literacy Platform",
                     technologies: %w[Svelte],
                     highlights: ["previous background saving scam touch behind third"])
    scorer = Ranking::Scorer.new([real, padded])
    wanted = Ranking.wanted_weights(
      "python orchestration previous background saving scam touch behind third"
    )
    assert_operator scorer.score(real, wanted), :>, scorer.score(padded, wanted)
  end

  def test_explained_contributions_sum_to_the_score
    # The explain output is how weights get tuned, so it has to add up to the number
    # it claims to explain, cap included.
    item = project("a", title: "X", technologies: ["Redis"],
                   highlights: ["latency", "throughput", "caching", "eviction"])
    scorer = Ranking::Scorer.new([item, project("b", title: "Z")])
    wanted = Ranking.wanted_weights("redis latency throughput caching eviction")
    total = scorer.matches(item, wanted).sum { |_, _, points| points }
    assert_in_delta scorer.score(item, wanted), total, 0.001
  end

  def test_prose_is_capped_at_the_structured_score
    item = project("a", title: "X", technologies: ["Redis"],
                   highlights: ["latency", "throughput", "caching", "eviction", "cluster"])
    scorer = Ranking::Scorer.new([item, project("b", title: "Z")])
    wanted = Ranking.wanted_weights("redis latency throughput caching eviction cluster")
    structured, prose = scorer.split_score(item, wanted)

    assert_operator prose, :>, structured, "fixture should have prose outweighing structure"
    assert_in_delta structured * 2, scorer.score(item, wanted), 0.001
  end
end
