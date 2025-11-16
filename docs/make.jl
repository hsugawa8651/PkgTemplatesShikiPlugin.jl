using Documenter
using PkgTemplatesShikiPlugin

makedocs(;
    modules=[PkgTemplatesShikiPlugin],
    sitename="PkgTemplatesShikiPlugin.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://hsugawa8651.github.io/PkgTemplatesShikiPlugin.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "User Guide" => "guide.md",
        "API Reference" => "api.md",
    ],
    remotes=nothing,  # Disable remote links for local builds without Git remote
    checkdocs=:none,  # Don't check for missing docstrings (minimal docs strategy)
)

deploydocs(;
    repo="github.com/hsugawa8651/PkgTemplatesShikiPlugin.jl.git",
    devbranch="main",
)
