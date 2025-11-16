# User Guide

## Usage Examples

### Basic Usage (No Deployment)

For local documentation only:

```julia
t = Template(;
    user="YourUsername",
    plugins=[DocumenterShiki()]  # Defaults to NoDeploy
)
```

### With GitHub Actions Deployment

```julia
t = Template(;
    user="YourUsername",
    plugins=[
        GitHubActions(),
        DocumenterShiki{GitHubActions}(
            theme="catppuccin-mocha",
            dark_theme="catppuccin-latte"
        ),
    ]
)
```

### Custom Theme and Languages

```julia
t = Template(;
    user="YourUsername",
    plugins=[
        GitHubActions(),
        DocumenterShiki{GitHubActions}(
            theme="nord",
            dark_theme="dracula",
            languages=["julia", "python", "rust", "toml"],
            cdn_url="https://esm.sh"
        ),
    ]
)
```

### With Travis CI

```julia
t = Template(;
    user="YourUsername",
    plugins=[
        TravisCI(),
        DocumenterShiki{TravisCI}(),
    ]
)
```

### With GitLab CI

```julia
t = Template(;
    user="YourUsername",
    plugins=[
        GitLabCI(),
        DocumenterShiki{GitLabCI}(),
    ]
)
```

## Configuration Options

The `DocumenterShiki` constructor accepts the following options:

- `theme::String`: Light theme (default: `"github-light"`)
- `dark_theme::String`: Dark theme (default: `"github-dark"`)
- `languages::Vector{String}`: Programming languages to support (default: `["julia", "javascript", "python", "bash", "json", "yaml", "toml"]`)
- `cdn_url::String`: CDN URL for Shiki (default: `"https://esm.sh"`)
- `assets::Vector{String}`: Additional asset files to copy
- `logo::Logo`: Documentation logo (light and dark variants)
- `makedocs_kwargs::Dict{Symbol,Any}`: Additional arguments for `makedocs()`
- `devbranch::String`: Development branch name
- `edit_link::Union{String,Symbol}`: Edit link type

See [available Shiki themes](https://shiki.matsu.io/themes) for theme options.

## Deployment Types

DocumenterShiki supports the same deployment types as the standard Documenter plugin:

- `DocumenterShiki()` or `DocumenterShiki{NoDeploy}()`: Local documentation only
- `DocumenterShiki{GitHubActions}()`: Deploy to GitHub Pages via GitHub Actions
- `DocumenterShiki{TravisCI}()`: Deploy to GitHub Pages via Travis CI
- `DocumenterShiki{GitLabCI}()`: Deploy to GitLab Pages via GitLab CI

**Note**: When using deployment types other than `NoDeploy`, you must include the corresponding CI plugin in your template.

## Comparison with Standard Documenter

| Feature | Documenter | DocumenterShiki |
|---------|-----------|-----------------|
| Syntax Highlighting | highlight.js | Shiki (VS Code engine) |
| Theme Quality | Basic | Professional, consistent |
| Theme Customization | Limited | 100+ themes available |
| Language Support | Good | Excellent (240+ languages) |
| Dark Mode | Manual | Automatic switching |
| Setup Complexity | Low | Low (automatic) |
| Build Speed | Fast | Fast (CDN-based) |

## Requirements

- Julia 1.6 or later
- PkgTemplates 0.7 or later
- Node.js 18+ (for building documentation)
- pnpm or npm (for Shiki dependencies)

## Generated Package Structure

When you generate a package with DocumenterShiki, it creates:

```
MyPackage/
├── docs/
│   ├── make.jl              # Documentation build script
│   ├── ShikiHighlighter.jl  # Shiki integration module
│   └── src/
│       └── index.md         # Documentation homepage
├── package.json             # Node.js dependencies
├── build-shiki.js          # Shiki build script
└── ...
```

## Building Documentation

In the generated package:

```bash
# Install Node.js dependencies
pnpm install

# Build documentation
julia --project=docs docs/make.jl
```
