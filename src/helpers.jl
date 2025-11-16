# Adapted from PkgTemplates.jl/src/plugins/documenter.jl
# Copyright (c) PkgTemplates.jl contributors
# Used under MIT License

using PkgTemplates: @with_kw_noshow

"""
    Logo

Logo configuration for documentation.
"""
@with_kw_noshow struct Logo
    light::Union{String, Nothing} = nothing
    dark::Union{String, Nothing} = nothing
end

"""
    canonical_url_string(p::DocumenterShiki, t::Template, pkg::AbstractString)

Generate canonical URL string for makedocs().
"""
function canonical_url_string(p::DocumenterShiki, t::Template, pkg::AbstractString)
    p.canonical_url === nothing && return ""
    url = p.canonical_url isa Function ? p.canonical_url(t, pkg) : p.canonical_url
    return "canonical=\"$url\","
end

"""
    edit_link_string(p::DocumenterShiki)

Generate edit_link parameter string for makedocs().
"""
function edit_link_string(p::DocumenterShiki)
    p.edit_link === nothing && return "edit_link=nothing,"
    p.edit_link isa Symbol && return "edit_link=:$(p.edit_link),"
    return "edit_link=\"$(p.edit_link)\","
end

"""
    render_makedocs_kwargs(p::DocumenterShiki)

Render additional makedocs() keyword arguments.
"""
function render_makedocs_kwargs(p::DocumenterShiki)
    isempty(p.makedocs_kwargs) && return ""
    pairs = ["$k=$v" for (k, v) in p.makedocs_kwargs]
    return join(pairs, ", ") * ","
end
