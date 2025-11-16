module PkgTemplatesShikiPlugin

using PkgTemplates
using PkgTemplates: Plugin, Template, @plugin, @with_kw_noshow, default_file
using Mustache
using Pkg

# Include submodules
include("helpers.jl")
include("plugin.jl")
include("methods.jl")

# Export main plugin type
export DocumenterShiki

end # module
