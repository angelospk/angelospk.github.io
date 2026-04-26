---
description: Generate a one-page ATS-friendly tailored CV from portfolio data using Typst
---

# Generate Tailored ATS CV

Use this workflow when the user wants a CV for a specific job, company, grant, freelance proposal, or application.

1. Collect the target context:
   - job posting or role description
   - company/application destination
   - user tips about what to emphasize or avoid

2. Run:

   ```bash
   ruby cv/generate_tailored_cv.rb --target "<job or file>" --tips "<user tips>" --basename "<company-role>"
   ```

3. Review the generated `.typ` in `generated-cvs/`.

4. If needed, edit the `.typ` manually for final polish, but do not add unsupported claims.

5. Compile or recompile:

   ```bash
   typst compile generated-cvs/<name>.typ generated-cvs/<name>.pdf
   ```

6. Deliver the PDF path and mention any assumptions.

Rules:

- One page.
- ATS-friendly, single-column text.
- Truthful tailoring only.
- Use keywords naturally.
- Avoid inflated AI-sounding language.
- Keep language consistent with the target posting.
