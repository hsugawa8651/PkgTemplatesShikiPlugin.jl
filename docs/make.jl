using Documenter
using PkgTemplatesShikiPlugin

makedocs(;
    modules=[PkgTemplatesShikiPlugin],
    sitename="PkgTemplatesShikiPlugin.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://[USERNAME].github.io/PkgTemplatesShikiPlugin.jl",
        assets=String[],
    ),
    pages=[
        "API Reference" => "index.md",
    ],
    remotes=nothing,  # Disable remote links for local builds without Git remote
    checkdocs=:none,  # Don't check for missing docstrings (minimal docs strategy)
)

deploydocs(;
    repo="github.com/[USERNAME]/PkgTemplatesShikiPlugin.jl.git",
    devbranch="main",
)
