using Documenter
using PkgTemplatesShikiPlugin
include("./ShikiHighlighter.jl")
using .ShikiHighlighter

makedocs(;
    modules=[PkgTemplatesShikiPlugin],
    sitename="PkgTemplatesShikiPlugin.jl",
    format=shiki_html(
        theme="github-light",
        dark_theme="github-dark",
        languages=["julia", "javascript", "python", "bash", "json", "yaml", "toml"],
        cdn_url="https://esm.sh",
        canonical="https://hsugawa8651.github.io/PkgTemplatesShikiPlugin.jl",
        prettyurls=get(ENV, "CI", "false") == "true"
    ),
    pages=[
        "Home" => "index.md",
        "User Guide" => "guide.md",
        "API Reference" => "api.md",
    ],
    remotes=nothing,  # Disable remote links for local builds without Git remote
    checkdocs=:none,  # Don't check for missing docstrings (minimal docs strategy)
)

# Add Shiki assets to build directory
add_shiki_assets(joinpath(@__DIR__, "build"))

deploydocs(;
    repo="github.com/hsugawa8651/PkgTemplatesShikiPlugin.jl.git",
    devbranch="main",
)
