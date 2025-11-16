# Adapted from PkgTemplates.jl v0.7.56
# Source: https://github.com/JuliaCI/PkgTemplates.jl/blob/v0.7.56/src/plugins/documenter.jl
# Copyright (c) PkgTemplates.jl contributors
# Used under MIT License

"""
    canonical_url_string(p::DocumenterShiki, t::Template, pkg::AbstractString)

Generate canonical URL string for makedocs().

Adapted from PkgTemplates Documenter plugin.
Source: https://github.com/JuliaCI/PkgTemplates.jl/blob/v0.7.56/src/plugins/documenter.jl#L148-L152
"""
function canonical_url_string(p::DocumenterShiki, t::Template, pkg::AbstractString)
    p.canonical_url === nothing && return ""
    url = p.canonical_url isa Function ? p.canonical_url(t, pkg) : p.canonical_url
    return "canonical=\"$url\","
end

"""
    edit_link_string(p::DocumenterShiki)

Generate edit_link parameter string for makedocs().

Adapted from PkgTemplates Documenter plugin.
Source: https://github.com/JuliaCI/PkgTemplates.jl/blob/v0.7.56/src/plugins/documenter.jl#L154-L158
"""
function edit_link_string(p::DocumenterShiki)
    p.edit_link === nothing && return "edit_link=nothing,"
    p.edit_link isa Symbol && return "edit_link=:$(p.edit_link),"
    return "edit_link=\"$(p.edit_link)\","
end

"""
    render_makedocs_kwargs(p::DocumenterShiki)

Render additional makedocs() keyword arguments.

Adapted from PkgTemplates Documenter plugin.
Source: https://github.com/JuliaCI/PkgTemplates.jl/blob/v0.7.56/src/plugins/documenter.jl#L160-L163
"""
function render_makedocs_kwargs(p::DocumenterShiki)
    isempty(p.makedocs_kwargs) && return ""
    pairs = ["$k=$v" for (k, v) in p.makedocs_kwargs]
    return join(pairs, ", ") * ","
end
