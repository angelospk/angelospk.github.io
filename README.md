# Angelos Papamichail - Personal Website

This is my personal website and blog built with [Hugo](https://gohugo.io/) using the [Hugo Coder](https://themes.gohugo.io/themes/hugo-coder/) theme.

## Local Development

### Prerequisites

- [Hugo Extended](https://gohugo.io/installation/) (v0.80.0 or newer)
- [Git](https://git-scm.com/)

### Setup

1. Clone this repository:
   ```bash
   git clone https://github.com/angelospk/angelospk.github.io.git
   cd angelospk.github.io
   ```

2. Initialize and update the theme submodule:
   ```bash
   git submodule update --init --recursive
   ```

3. Start the Hugo development server:
   ```bash
   hugo server -D
   ```

4. Open your browser and navigate to http://localhost:1313/

## Deployment to GitHub Pages

This site is configured to be deployed to GitHub Pages. Here's how to deploy it:

### Manual Deployment

1. Build the site:
   ```bash
   hugo --minify
   ```

2. The generated files will be in the `public` directory. You can then push these files to the `gh-pages` branch of your repository.

### Automated Deployment with GitHub Actions

This repository is set up to automatically deploy to GitHub Pages using GitHub Actions whenever changes are pushed to the main branch.

The workflow file is located at `.github/workflows/hugo.yml`.

## Customization

- Configuration: Edit the `hugo.toml` file to customize site settings.
- Content: Add or modify content in the `content` directory.
- Theme: The Hugo Coder theme is included as a Git submodule in `themes/hugo-coder`.

## License

This project is licensed under the MIT License - see the LICENSE file for details. 