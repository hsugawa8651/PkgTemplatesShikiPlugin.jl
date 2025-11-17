# Plugin interface methods for DocumenterShiki

using PkgTemplates: Template, Plugin, hasplugin, Badge, DEFAULT_PRIORITY
import PkgTemplates: validate, hook, view, badges, priority, gitignore

# Import additional PkgTemplates types for validation
using PkgTemplates: GitHubActions, TravisCI, GitLabCI, Documenter

# Import PkgTemplates utilities for hook() implementation
using PkgTemplates: pkg_name, combined_view, render_file, gen_file, tags
using Pkg: PackageSpec

#=
NOTE: We use `import` for the plugin interface functions (validate, hook, view, badges)
because we need to extend them with new methods for DocumenterShiki.
=#

## Plugin Interface Methods

"""
    validate(p::DocumenterShiki, t::Template)

Base validation for all DocumenterShiki configurations.

Checks:
1. No conflict with standard Documenter plugin
2. Asset files exist
3. Logo files exist

Adapted from PkgTemplates Documenter plugin.
Source: https://github.com/JuliaCI/PkgTemplates.jl/blob/v0.7.56/src/plugins/documenter.jl#L167-L177
"""
function validate(p::DocumenterShiki, t::Template)
    # Check for conflicting Documenter plugin
    if hasplugin(t, Documenter)
        throw(ArgumentError("""
            Template contains both Documenter and DocumenterShiki plugins.
            These plugins are mutually exclusive as they generate the same files.
            Please use only one documentation plugin:
            - Use Documenter{T}() for standard Documenter.jl with highlight.js
            - Use DocumenterShiki{T}() for Documenter.jl with Shiki highlighting
            """))
    end

    # Validate assets exist
    for asset in p.assets
        isfile(asset) || throw(ArgumentError("Asset file not found: $asset"))
    end

    # Validate logos exist
    if p.logo.light !== nothing && !isfile(p.logo.light)
        throw(ArgumentError("Logo file not found: $(p.logo.light)"))
    end
    if p.logo.dark !== nothing && !isfile(p.logo.dark)
        throw(ArgumentError("Logo file not found: $(p.logo.dark)"))
    end
end

# Type union for deployment CI providers (mirroring PkgTemplates pattern)
const YesDeploy = Union{GitHubActions, TravisCI, GitLabCI}

"""
    validate(p::DocumenterShiki{T}, t::Template) where T <: YesDeploy

Additional validation for DocumenterShiki with deployment.

Checks that the required CI plugin is present in the template.

Adapted from PkgTemplates Documenter plugin.
Source: https://github.com/JuliaCI/PkgTemplates.jl/blob/v0.7.56/src/plugins/documenter.jl#L179-L186
"""
function validate(p::DocumenterShiki{T}, t::Template) where T <: YesDeploy
    # Call base validation first
    invoke(validate, Tuple{DocumenterShiki, Template}, p, t)

    # Check for required CI plugin
    if !hasplugin(t, T)
        name = nameof(T)
        throw(ArgumentError("DocumenterShiki: The $name plugin must be included for docs deployment to be set up"))
    end
end

"""
    view(p::DocumenterShiki{T}, t::Template, pkg::AbstractString) where T

Generate template variables for rendering.
"""
function view(p::DocumenterShiki{T}, t::Template, pkg::AbstractString) where T
    devbranch = p.devbranch === nothing ? PkgTemplates.default_branch(t) : p.devbranch
    Dict{String, Any}(
        # Standard variables
        "PKG" => pkg,
        "USER" => t.user,  # Add USER for badge URLs
        "AUTHORS" => join(t.authors, ", "),
        "REPO" => string(t.host, "/", t.user, "/", pkg, ".jl"),
        "DEVBRANCH" => devbranch,

        # Shiki-specific
        "SHIKI_THEME" => p.theme,
        "SHIKI_DARK_THEME" => p.dark_theme,
        "SHIKI_LANGUAGES" => repr(p.languages),
        "SHIKI_CDN_URL" => p.cdn_url,

        # Asset handling
        "HAS_ASSETS" => !isempty(p.assets),
        "ASSETS" => p.assets,
        "HAS_LOGO" => p.logo.light !== nothing || p.logo.dark !== nothing,

        # Deployment
        "HAS_DEPLOY" => T !== NoDeploy,
        "CANONICAL_URL" => canonical_url_string(p, t, pkg),
        "EDIT_LINK" => edit_link_string(p),
        "MAKEDOCS_KWARGS" => render_makedocs_kwargs(p),
    )
end

"""
    badges(p::DocumenterShiki)

Generate documentation badges for README.

Adapted from PkgTemplates Documenter plugin.
Source: https://github.com/JuliaCI/PkgTemplates.jl/blob/v0.7.56/src/plugins/documenter.jl#L122-L140
"""
badges(::DocumenterShiki) = Badge[]

"""
    badges(p::DocumenterShiki{<:Union{GitHubActions, TravisCI}})

Generate documentation badges for GitHub Pages deployment.

Adapted from PkgTemplates Documenter plugin.
Source: https://github.com/JuliaCI/PkgTemplates.jl/blob/v0.7.56/src/plugins/documenter.jl#L123-L134
"""
function badges(::DocumenterShiki{T}) where T <: Union{GitHubActions, TravisCI}
    return [
        Badge(
            "Stable",
            "https://img.shields.io/badge/docs-stable-blue.svg",
            "https://{{{USER}}}.github.io/{{{PKG}}}.jl/stable/",
        ),
        Badge(
            "Dev",
            "https://img.shields.io/badge/docs-dev-blue.svg",
            "https://{{{USER}}}.github.io/{{{PKG}}}.jl/dev/",
        ),
    ]
end

"""
    badges(p::DocumenterShiki{GitLabCI})

Generate documentation badge for GitLab Pages deployment.

Adapted from PkgTemplates Documenter plugin.
Source: https://github.com/JuliaCI/PkgTemplates.jl/blob/v0.7.56/src/plugins/documenter.jl#L135-L140
"""
function badges(::DocumenterShiki{GitLabCI})
    return Badge(
        "Dev",
        "https://img.shields.io/badge/docs-dev-blue.svg",
        "https://{{{USER}}}.gitlab.io/{{{PKG}}}.jl/dev",
    )
end

"""
    gitignore(::DocumenterShiki)

Return patterns that should be added to `.gitignore` for DocumenterShiki projects.

Includes:
- Documenter build outputs and manifests
- Node.js dependencies for Shiki
- OS-specific files (macOS, Windows, Linux)

Adapted from PkgTemplates Documenter plugin.
Source: https://github.com/JuliaCI/PkgTemplates.jl/blob/v0.7.56/src/plugins/documenter.jl#L119
"""
gitignore(::DocumenterShiki) = [
    "/docs/build/",
    "/docs/Manifest*.toml",
    "node_modules/",
    "package-lock.json",
    ".DS_Store",
    "Thumbs.db",
]

"""
    priority(::DocumenterShiki, ::Function)

Set hook priority to run after SrcDir plugin creates source files.

Reference: https://github.com/JuliaCI/PkgTemplates.jl/blob/v0.7.56/src/plugins/documenter.jl#L120
"""
priority(::DocumenterShiki, ::Function) = DEFAULT_PRIORITY - 1  # We need SrcDir to go first.

"""
    hook(p::DocumenterShiki{T}, t::Template, pkg_dir) where T

Main file generation hook. Creates documentation directory structure and generates
all necessary files for DocumenterShiki.
"""
function hook(p::DocumenterShiki{T}, t::Template, pkg_dir::AbstractString) where T
    pkg = pkg_name(pkg_dir)

    # Directory structure
    docs_dir = joinpath(pkg_dir, "docs")
    src_dir = joinpath(docs_dir, "src")
    assets_dir = joinpath(src_dir, "assets")
    mkpath(src_dir)
    mkpath(assets_dir)

    # Template variables
    vars = combined_view(p, t, pkg)

    # Generate ShikiHighlighter.jl
    shiki_text = render_file(p.shiki_highlighter_jl, vars, tags(p))
    gen_file(joinpath(docs_dir, "ShikiHighlighter.jl"), shiki_text)

    # Generate make.jl
    make_text = render_file(p.make_jl, vars, tags(p))
    gen_file(joinpath(docs_dir, "make.jl"), make_text)

    # Generate index.md
    index_text = render_file(p.index_md, vars, tags(p))
    gen_file(joinpath(src_dir, "index.md"), index_text)

    # Generate Documentation.yml if deploying with GitHubActions
    if p.documentation_yml !== nothing
        workflows_dir = joinpath(pkg_dir, ".github", "workflows")
        mkpath(workflows_dir)
        doc_yml_text = render_file(p.documentation_yml, vars, tags(p))
        gen_file(joinpath(workflows_dir, "Documentation.yml"), doc_yml_text)
    end

    # Generate package.json
    pkg_json = generate_package_json(p)
    gen_file(joinpath(pkg_dir, "package.json"), pkg_json)

    # Generate build-shiki.js
    build_script = generate_build_script(p)
    gen_file(joinpath(pkg_dir, "build-shiki.js"), build_script)

    # Copy assets
    for asset in p.assets
        cp(asset, joinpath(assets_dir, basename(asset)))
    end

    # Copy logos
    foreach((:light => "logo", :dark => "logo-dark")) do (k, f)
        logo = getfield(p.logo, k)
        if logo !== nothing
            _, ext = splitext(logo)
            cp(logo, joinpath(assets_dir, "$f$ext"))
        end
    end

    # Setup docs environment
    # Reference: https://github.com/JuliaCI/PkgTemplates.jl/blob/v0.7.56/src/plugins/documenter.jl#L212-L216
    PkgTemplates.with_project(docs_dir) do
        Pkg.add("Documenter")
        cd(() -> Pkg.develop(PackageSpec(; path="..")), docs_dir)
    end
end

## Helper Functions for File Generation

"""
    generate_package_json(p::DocumenterShiki)

Generate package.json content for Node.js dependencies.
"""
function generate_package_json(p::DocumenterShiki)
    return """
    {
      "name": "documenter-shiki",
      "version": "1.0.0",
      "type": "module",
      "private": true,
      "dependencies": {
        "shiki": "^1.22.2"
      },
      "scripts": {
        "build-shiki": "node build-shiki.js",
        "build-docs": "julia --project=docs docs/make.jl"
      }
    }
    """
end

"""
    generate_build_script(p::DocumenterShiki)

Generate build-shiki.js script content.
"""
function generate_build_script(p::DocumenterShiki)
    return """
    // Placeholder for Shiki build script
    // This would contain logic to process code blocks with Shiki
    console.log('Shiki build script - to be implemented');
    """
end

