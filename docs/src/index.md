# PkgTemplatesShikiPlugin.jl

*A PkgTemplates plugin for DocumenterShiki - bringing modern Shiki syntax highlighting to Julia package documentation*

## Overview

PkgTemplatesShikiPlugin is the **first standalone third-party plugin** for [PkgTemplates.jl](https://github.com/JuliaCI/PkgTemplates.jl). It extends PkgTemplates with support for DocumenterShiki, enabling VS Code-quality syntax highlighting powered by [Shiki](https://shiki.matsu.io/) in your package documentation.

When you generate a new Julia package with this plugin, it automatically sets up DocumenterShiki with:
- Modern Shiki syntax highlighting
- Light/dark theme support
- Configurable color themes and languages
- CI/CD integration (GitHub Actions, Travis CI, GitLab CI)
- All necessary template files and Node.js dependencies

## Installation

```julia
using Pkg
Pkg.add("PkgTemplatesShikiPlugin")
```

## Quick Start

```julia
using PkgTemplates
using PkgTemplatesShikiPlugin

# Create a template with DocumenterShiki
t = Template(;
    user="YourGitHubUsername",
    plugins=[
        Git(),
        GitHubActions(),
        DocumenterShiki{GitHubActions}(
            theme="github-light",
            dark_theme="github-dark"
        ),
    ]
)

# Generate a new package
t("MyAwesomePackage")
```

This creates a new Julia package with DocumenterShiki documentation pre-configured and ready to build.

## Features

- 🎨 **Modern Syntax Highlighting**: VS Code-quality highlighting powered by Shiki
- 🌓 **Theme Support**: Built-in light/dark theme switching
- 📦 **Automatic Setup**: All documentation files and dependencies configured automatically
- 🔧 **Highly Configurable**: Customize themes, languages, and Documenter options
- ⚡ **CDN-based**: No bundling required, loads Shiki from CDN
- 🚀 **CI/CD Ready**: Works with GitHub Actions, Travis CI, and GitLab CI
- ✅ **Well Tested**: Comprehensive test suite (45 tests)

## API Reference

```@docs
DocumenterShiki
Logo
```

## Index

```@index
```
