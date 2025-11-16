# Plugin struct definition following PkgTemplates Documenter{T} pattern
# Reference: https://github.com/JuliaCI/PkgTemplates.jl/blob/v0.7.56/src/plugins/documenter.jl#L74-L113
# Note: Cannot use @plugin macro because it doesn't support parametric types

# Import functions we need to extend
import PkgTemplates: defaultkw

"""
    DocumenterShiki{T}(;
        theme="github-light",
        dark_theme="github-dark",
        languages=["julia", "javascript", "python", "bash", "json", "yaml", "toml"],
        cdn_url="https://esm.sh",
        assets=String[],
        logo=Logo(),
        makedocs_kwargs=Dict{Symbol,Any}(),
        canonical_url=make_canonical(T),
        devbranch=nothing,
        edit_link=:commit,
        make_jl=default_file("documenter_shiki", "make.jlt"),
        index_md=default_file("documenter_shiki", "index.md"),
        shiki_highlighter_jl=default_file("documenter_shiki", "ShikiHighlighter.jlt"),
    )

PkgTemplates plugin for generating package templates with DocumenterShiki.

Documentation deployment depends on `T`, where `T` is some supported CI plugin,
or `NoDeploy` to only support local documentation builds.

# Supported Type Parameters
- `GitHubActions`: Deploys documentation to GitHub Pages with GitHubActions
- `TravisCI`: Deploys documentation to GitHub Pages with TravisCI
- `GitLabCI`: Deploys documentation to GitLab Pages with GitLabCI
- `NoDeploy` (default): Does not set up documentation deployment

# Keyword Arguments (Shiki-specific)
- `theme::String`: Light mode theme (default: "github-light")
- `dark_theme::String`: Dark mode theme (default: "github-dark")
- `languages::Vector{String}`: Supported languages (default: julia, javascript, python, bash, json, yaml, toml)
- `cdn_url::String`: CDN URL for Shiki (default: "https://esm.sh")

# Keyword Arguments (Documenter-inherited)
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
struct DocumenterShiki{T} <: Plugin
    # Shiki-specific options
    theme::String
    dark_theme::String
    languages::Vector{String}
    cdn_url::String

    # Documenter options (inherited concepts)
    assets::Vector{String}
    logo::Logo
    makedocs_kwargs::Dict{Symbol, Any}
    canonical_url::Union{Function, Nothing}

    # Template files
    make_jl::String
    index_md::String
    shiki_highlighter_jl::String

    # Deployment settings
    devbranch::Union{String, Nothing}
    edit_link::Union{String, Symbol, Nothing}
end

# Can't use @plugin because we're implementing our own parametric constructor.
function DocumenterShiki{T}(;
    theme::AbstractString="github-light",
    dark_theme::AbstractString="github-dark",
    languages::Vector{<:AbstractString}=["julia", "javascript", "python", "bash", "json", "yaml", "toml"],
    cdn_url::AbstractString="https://esm.sh",
    assets::Vector{<:AbstractString}=String[],
    logo::Logo=Logo(),
    makedocs_kwargs::Dict{Symbol}=Dict{Symbol, Any}(),
    canonical_url::Union{Function, Nothing}=make_canonical(T),
    devbranch::Union{AbstractString, Nothing}=nothing,
    edit_link::Union{AbstractString, Symbol, Nothing}=:commit,
    make_jl::AbstractString=default_file("documenter_shiki", "make.jlt"),
    index_md::AbstractString=default_file("documenter_shiki", "index.md"),
    shiki_highlighter_jl::AbstractString=default_file("documenter_shiki", "ShikiHighlighter.jlt"),
) where {T}
    return DocumenterShiki{T}(
        theme,
        dark_theme,
        languages,
        cdn_url,
        assets,
        logo,
        makedocs_kwargs,
        canonical_url,
        make_jl,
        index_md,
        shiki_highlighter_jl,
        devbranch,
        edit_link,
    )
end

"""
    DocumenterShiki(; kwargs...)

Create a DocumenterShiki plugin with no deployment (local documentation only).
Equivalent to `DocumenterShiki{NoDeploy}(; kwargs...)`.
"""
DocumenterShiki(; kwargs...) = DocumenterShiki{NoDeploy}(; kwargs...)

# We have to define these manually because we didn't use @plugin.
defaultkw(::Type{<:DocumenterShiki}, ::Val{:theme}) = "github-light"
defaultkw(::Type{<:DocumenterShiki}, ::Val{:dark_theme}) = "github-dark"
defaultkw(::Type{<:DocumenterShiki}, ::Val{:languages}) = ["julia", "javascript", "python", "bash", "json", "yaml", "toml"]
defaultkw(::Type{<:DocumenterShiki}, ::Val{:cdn_url}) = "https://esm.sh"
defaultkw(::Type{<:DocumenterShiki}, ::Val{:assets}) = String[]
defaultkw(::Type{<:DocumenterShiki}, ::Val{:logo}) = Logo()
defaultkw(::Type{<:DocumenterShiki}, ::Val{:makedocs_kwargs}) = Dict{Symbol, Any}()
defaultkw(::Type{<:DocumenterShiki}, ::Val{:devbranch}) = nothing
defaultkw(::Type{<:DocumenterShiki}, ::Val{:edit_link}) = :commit
