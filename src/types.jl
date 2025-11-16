# Basic types and utilities for DocumenterShiki plugin
# Adapted from PkgTemplates.jl/src/plugins/documenter.jl
# Copyright (c) PkgTemplates.jl contributors
# Used under MIT License

using PkgTemplates: @with_kw_noshow, GitHubActions, TravisCI, GitLabCI

# Define NoDeploy type for local-only documentation
struct NoDeploy end

"""
    Logo(; light=nothing, dark=nothing)

Logo configuration for documentation.

# Keyword Arguments
- `light::Union{String, Nothing}`: Path to a logo file for the light (default) theme.
- `dark::Union{String, Nothing}`: Path to a logo file for the dark theme.
"""
@with_kw_noshow struct Logo
    light::Union{String, Nothing} = nothing
    dark::Union{String, Nothing} = nothing
end

# Helper function for canonical URL (similar to Documenter plugin)
"""
    make_canonical(T::Type)

Generate canonical URL function based on deployment type.
"""
function make_canonical(::Type{GitHubActions})
    return (t, pkg) -> "https://$(t.user).github.io/$pkg.jl/"
end

function make_canonical(::Type{TravisCI})
    return (t, pkg) -> "https://$(t.user).github.io/$pkg.jl/"
end

function make_canonical(::Type{GitLabCI})
    return (t, pkg) -> "https://$(t.user).gitlab.io/$pkg.jl/"
end

make_canonical(::Type{NoDeploy}) = nothing
