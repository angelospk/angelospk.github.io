---
name: ats-typst-cv
description: Generate a truthful, ATS-friendly one-page tailored CV/resume in Typst for a specific job application, using this repo's data/portfolio YAML files and optional user tips. Use when asked to create, tailor, regenerate, or improve a CV/resume for a role, company, application, or job posting.
---

# ATS Typst CV

Use this skill to generate a one-page, ATS-friendly CV tailored to a specific application.

## Inputs To Ask For

If not already provided, ask for:

- The job posting, company, role, or application context.
- Optional positioning tips from the user, such as "emphasize SvelteKit and payments" or "avoid teaching experience".
- Preferred language only if unclear. Default to English unless the target is Greek.

## Source Of Truth

Use only facts from:

- `data/portfolio/*.yaml`
- `data/portfolio_backup.yaml` if the split YAML files are missing information
- existing `content/projects/*/index.md` only for wording support

Do not invent employment, seniority, metrics, clients, certifications, degrees, or technologies.

## Tailoring Rules

- Extract real keywords from the job/application context: languages, frameworks, domain terms, responsibilities, deployment/runtime, databases, testing, analytics, payments, automation, teaching, and operations.
- Prefer matching truthful items from portfolio data.
- Rephrase for relevance, but keep claims grounded in existing projects and experience.
- Use plain human language. Avoid generic AI phrases like "leveraged cutting-edge", "spearheaded", "dynamic professional", "passionate innovator", or inflated claims.
- Match the application language: English for international/tech roles, Greek only for clearly Greek postings or when the user asks.
- Include job keywords naturally in summary, skills, project choices, and bullets. Do not keyword-stuff or add a separate fake keyword block.
- Keep it ATS-friendly: one column, real text, standard section names, no icons, no charts, no skill bars, no tables required for meaning.
- Keep it one page. If it overflows, reduce bullets before shrinking below readable text size.

## Generation Command

Create a tailored Typst source and PDF:

```bash
ruby cv/generate_tailored_cv.rb --target path/to/job.txt --tips "emphasize Go, SvelteKit, product ownership" --basename company-role
```

If Typst is unavailable:

```bash
ruby cv/generate_tailored_cv.rb --target path/to/job.txt --no-compile
```

Outputs go to `generated-cvs/`, which is intentionally gitignored.

## Review Checklist

Before delivering:

1. Verify the generated `.typ` exists.
2. Compile with Typst if available.
3. Check the CV is one page.
4. Check the top projects and experience match the application.
5. Check language consistency. A mostly English CV should not contain avoidable Greek bullets.
6. Remove anything that sounds exaggerated, generic, AI-written, or unsupported by the data files.

## When Updating This Skill

Keep the generator deterministic and dependency-light. It should work with system Ruby and Typst, without npm or Python packages.
