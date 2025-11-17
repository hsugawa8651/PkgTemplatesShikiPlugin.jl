# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2025-11-17

### Added
- Initial release
- DocumenterShiki plugin for PkgTemplates
- Support for GitHubActions, TravisCI, GitLabCI deployment types
- NoDeploy option for local documentation only
- Shiki syntax highlighting with configurable themes
  - Default themes: github-light / github-dark
  - Support for 100+ Shiki themes
- Configurable programming language support
  - Default languages: julia, javascript, python, bash, json, yaml, toml
  - Support for 240+ languages via Shiki
- First standalone third-party PkgTemplates plugin
- Comprehensive test suite (45 tests)
- Validation for:
  - Documenter/DocumenterShiki mutual exclusivity
  - Required CI plugin presence for deployment types
  - Asset and logo file existence
- Template file generation:
  - docs/make.jl with DocumenterShiki configuration
  - docs/src/index.md
  - docs/ShikiHighlighter.jl module
  - package.json with Shiki dependencies
  - build-shiki.js script
  - .github/workflows/Documentation.yml for GitHubActions deployment
- Plugin interface methods:
  - `validate()` - Configuration validation
  - `view()` - Template variable generation with USER variable for badge URLs
  - `hook()` - File generation
  - `badges()` - README badge generation with correct GitHub Pages URLs
  - `priority()` - Hook execution ordering
- Documentation:
  - Comprehensive README with usage examples
  - CHANGELOG following Keep a Changelog format
  - API documentation from docstrings
  - Shiki syntax highlighting in documentation site
- SSH Deploy Key support via DOCUMENTER_KEY for secure documentation deployment

### Fixed
- Missing `add_shiki_assets()` call in generated docs/make.jl template
- Incorrect placement of `canonical` and `edit_link` arguments (moved to shiki_html())
- Missing USER variable in view() causing broken badge URLs in generated README
- Incorrect gitignore pattern for pnpm-lock.yaml (should not be ignored)
- GitHub Actions syntax escaping in Documentation.yml template
