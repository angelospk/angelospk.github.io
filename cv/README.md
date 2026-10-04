# CV Generation

Generate a one-page ATS-friendly tailored CV from the portfolio YAML files:

```bash
ruby cv/generate_tailored_cv.rb --target job-posting.txt --tips "emphasize SvelteKit, Go, payments" --basename company-role
```

The script writes `.typ` and `.pdf` files to `generated-cvs/`. Generated files are ignored by Git.

Set `LANG` (e.g. `LANG=en_US.UTF-8`) if your shell leaves it unset — Ruby otherwise
reads the portfolio as US-ASCII and dies on the first Greek character.

## Which projects get picked

Four of the featured projects are selected per posting, ranked by `cv/ranking.rb`.
A term is worth what it tells you about *which* project to pick: rarity is measured
against the portfolio itself, so a word in every project ("data", "platform") counts
for almost nothing while "sql" or "whisper" counts for a lot. Each term counts once,
at its best field (technologies/skills/subtitle > title > highlights > description),
so a long description cannot win on volume. Prose can at most double a project's
structured score and can never create one on its own.

Inspect any decision instead of guessing at it:

```bash
ruby cv/generate_tailored_cv.rb --target job.txt --no-compile --explain-ranking
```

It prints every project's score and the terms that earned it, `*` marking the picks.

## Overriding the picks

When the ranking is wrong for a specific posting, pin the projects by `id` rather than
editing the generated `.typ` — the next run overwrites that file.

```bash
ruby cv/generate_tailored_cv.rb --target job.txt --pin-projects diesi-analytics,unitrip
```

Pins come first, in order; ranking fills the rest. A pin overrides `featured: false`.
Unknown ids and more than four pins are errors, so a typo fails loudly instead of
quietly producing a CV that ignores you.

From the job-hunt side, record them per application so they survive regeneration —
`applications/<job-id>/cv-overrides.toml`:

```toml
projects = ["diesi-analytics", "unitrip"]
```

`jobhunt-cli assets <job-id>` reads that file and passes it through.

## Profiles (`--overlay`)

The portfolio YAML is published: it drives the website. A CV is not published, and the
same true work reads differently to someone hiring an applied-AI engineer than it does
to a visitor on a personal site. `--overlay` merges a private YAML over the portfolio
data for one run:

```bash
ruby cv/generate_tailored_cv.rb --target job.txt --overlay ~/job-hunt/private/cv-profiles/applied-ai.yaml
```

The overlay takes `summary` (a mapping of language to text, replacing the generated
one), `experiences` and `projects`. Entries are addressed by `id`. By default an entry
patches the matching portfolio entry, per top-level key, overlay winning; a list such
as `highlights` is replaced whole rather than appended to. Patching an id that does not
exist is an error, so a typo fails instead of putting a half-empty block on the CV. A
genuinely new entry has to say `op: add`.

There is deliberately no auto-discovered default overlay. A file that applied itself
would turn every later CV into whichever profile was written last, and regenerating a
sent application months later would produce a different document.

From the job-hunt side, name the profile per application in
`applications/<job-id>/cv-overrides.toml`:

```toml
profile = "applied-ai"
```

which resolves to `~/job-hunt/private/cv-profiles/applied-ai.yaml`. An unknown name is
an error rather than a silent fallback to the default CV.

## Tests

```bash
ruby cv/ranking_test.rb        # scoring, stemming, aliases
ruby cv/pin_projects_test.rb   # --pin-projects, end-to-end through the CLI
ruby cv/pin_experience_test.rb # --pin-experience
ruby cv/overlay_test.rb        # --overlay: patching, additions, validation
```
