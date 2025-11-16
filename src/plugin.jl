# Define NoDeploy type for local-only documentation
struct NoDeploy end

"""
    DocumenterShiki{T<:Union{PkgTemplates.GitHubActions, PkgTemplates.TravisCI, PkgTemplates.GitLabCI, NoDeploy}}

PkgTemplates plugin for generating package templates with DocumenterShiki.

# Type Parameters
- `T`: Deployment type (NoDeploy, GitHubActions, TravisCI, or GitLabCI)

# Fields (Shiki-specific)
- `theme::String`: Light mode theme (default: "github-light")
- `dark_theme::String`: Dark mode theme (default: "github-dark")
- `languages::Vector{String}`: Supported languages (default: julia, javascript, python, bash)
- `cdn_url::String`: CDN URL for Shiki (default: "https://esm.sh")

# Fields (Documenter-inherited)
- `assets::Vector{String}`: Additional asset files
- `logo::Logo`: Logo configuration
- `makedocs_kwargs::Dict{Symbol, Any}`: Additional makedocs() arguments
- `canonical_url::Union{Function, Nothing}`: Canonical URL function or string
- `devbranch::Union{String, Nothing}`: Development branch name
- `edit_link::Union{String, Symbol, Nothing}`: Edit link configuration

# Template Files
- `make_jl::String`: Path to make.jl template
- `index_md::String`: Path to index.md template
- `shiki_highlighter_jl::String`: Path to ShikiHighlighter.jl template

# Examples
```julia
# Local documentation only
DocumenterShiki()

# With GitHub Actions deployment
DocumenterShiki{GitHubActions}(
    theme="github-light",
    dark_theme="github-dark"
)
```
"""
@plugin struct DocumenterShiki{T} <: Plugin
    # Shiki-specific options
    theme::String = "github-light"
    dark_theme::String = "github-dark"
    languages::Vector{String} = ["julia", "javascript", "python", "bash", "json", "yaml", "toml"]
    cdn_url::String = "https://esm.sh"

    # Documenter options (inherited concepts)
    assets::Vector{String} = String[]
    logo::Logo = Logo()
    makedocs_kwargs::Dict{Symbol, Any} = Dict{Symbol, Any}()
    canonical_url::Union{Function, Nothing} = nothing

    # Template files
    make_jl::String = default_file("documenter_shiki", "make.jlt")
    index_md::String = default_file("documenter_shiki", "index.md")
    shiki_highlighter_jl::String = default_file("documenter_shiki", "ShikiHighlighter.jlt")

    # Deployment settings
    devbranch::Union{String, Nothing} = nothing
    edit_link::Union{String, Symbol, Nothing} = :commit
end

"""
    DocumenterShiki()

Create a DocumenterShiki plugin with no deployment (local documentation only).
Equivalent to `DocumenterShiki{NoDeploy}()`.
"""
DocumenterShiki() = DocumenterShiki{NoDeploy}()
