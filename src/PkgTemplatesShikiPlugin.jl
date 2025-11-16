module PkgTemplatesShikiPlugin

using PkgTemplates
using PkgTemplates: Plugin, Template, @plugin, @with_kw_noshow, default_file
using PkgTemplates: GitHubActions, TravisCI, GitLabCI, defaultkw
using Mustache
using Pkg

# Include submodules in correct order:
# 1. types.jl - Basic types (NoDeploy, Logo, make_canonical)
# 2. plugin.jl - DocumenterShiki struct (uses Logo, make_canonical)
# 3. helpers.jl - Helper functions (uses DocumenterShiki)
# 4. methods.jl - Plugin interface methods (uses DocumenterShiki, helpers)
include("types.jl")
include("plugin.jl")
include("helpers.jl")
include("methods.jl")

# Export main plugin type and utility types
export DocumenterShiki, Logo, NoDeploy

end # module
