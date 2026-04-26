# CV Generation

Generate a one-page ATS-friendly tailored CV from the portfolio YAML files:

```bash
ruby cv/generate_tailored_cv.rb --target job-posting.txt --tips "emphasize SvelteKit, Go, payments" --basename company-role
```

The script writes `.typ` and `.pdf` files to `generated-cvs/`. Generated files are ignored by Git.
