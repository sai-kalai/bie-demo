# representation fo the contol structure

# The data model for controls specifies the validity of values and can be
# configured at app startup. The view implementations produce valid HTML from
# the control configuration.

abstract type AbstractControlNode end

struct NullNode <: AbstractControlNode end

_alltrue(args...) = true

# grouping of other controls
# "product ADT"
struct ControlGroup <: AbstractControlNode
    id::String
    controls::Vector{AbstractControlNode} # possible child nodes
    filter::Function # determines what nodes are active w.r.t current state

    function ControlGroup(id)
        return ControlGroup(id, AbstractControlNode[], _alltrue)
    end

end

function push!(g::ControlGroup, vals...)
    push!(g.controls, vals...)
end


# materialized as e.g. sliders, number inputs
struct RealValued{T,R<:AbstractRange{T}} <: AbstractControlNode
    id::String
    controls::Vector{AbstractControlNode}
    filter::Function

    cur::Observable{T} # current value
    range::R

end
function RealValued(id, range; value=first(range),
    controls=AbstractControlNode[], filter=_alltrue)
    return RealValued(id, controls, filter, value, range)
end

# e.g. dropdown menu
# "sum ADT"
struct CategoricalEnumeration{T} <: AbstractControlNode
    id::String
    controls::Vector{AbstractControlNode}
    filter::Function

    cur::Observable{T}
    variants::Vector{T}
end

# e.g. checkbox
struct Boolean <: AbstractControlNode
    id::String
    filter::Function
    controls::Vector{AbstractControlNode}

    cur::Observable{Bool}
end
controls(n::AbstractControlNode) = n.controls
controls(n::NullNode) = []

function Base.show(io::IO, node::AbstractControlNode)
    print_tree(io, node)
end

function print_tree(io::IO, node::AbstractControlNode, prefix="", is_last=true)
    connector = is_last ? "└── " : "├── "
    print(io, prefix, connector)

    if node isa ControlGroup
        println(io, "ControlGroup ($(node.id))")
    elseif node isa RealValued
        println(io, "RealValued ($(node.id)): $(node.cur) ∈ [$(node.min), $(node.max)], step=$(node.step)")
    elseif node isa CategoricalEnumeration
        println(io, "CategoricalEnumeration ($(node.id)): $(node.variants)")
    elseif node isa Boolean
        println(io, "Boolean: $(node.val)")
    elseif node isa NullNode
        println(io, "NullNode")
    end

    children = controls(node)
    child_prefix = prefix * (is_last ? "    " : "│   ")

    for (i, child) in enumerate(children)
        print_tree(io, child, child_prefix, i == length(children))
    end
end

# Root node: no connector
function Base.show(io::IO, ::MIME"text/plain", node::AbstractControlNode)
    if node isa ControlGroup
        println(io, "ControlGroup ($(node.id))")
    else
        print_tree(io, node, "", true)
    end

    if node isa ControlGroup
        for (i, child) in enumerate(node.controls)
            print_tree(io, child, "", i == length(node.controls))
        end
    end
end
