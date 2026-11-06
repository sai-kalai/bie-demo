
# Definition of the tree data structure used for controls

# internal api, should not be used

struct Node{T<:Union{AbstractControl,Nothing},C<:NamedTuple} # consider dict instead
    id::Symbol
    control::T
    children::C
end
Node(id) = Node(Symbol(id), nothing, NamedTuple())
Node(id, control) = Node(Symbol(id), control, NamedTuple())
function Node(id, control, children::NamedTuple)
    Node(Symbol(id), control, children)
end
function Node(id, control, children::AbstractVector{<:Node})
    children_nt = (; (n.id => n for n in children)...)
    Node(Symbol(id), control, children_nt)
end

_getnode(node::Node) = node
function _getnode(node::Node, path::Symbol...)
    # @show node.control, path
    isempty(path) && return node
    child = getproperty(node.children, first(path))
    return _getnode(child, Base.tail(path)...)
end

Base.get(node::Node, path::Symbol...) = _getnode(node, path...).control

Base.getindex(node::Node, path::Symbol...) = _getnode(node, path...)

function Base.show(io::IO, node::Node)
    print_tree(io, node)
end

function print_tree(io::IO, node::Node, prefix="", islast=true, isroot=true)
    if !isroot
        print(io, prefix, islast ? "└── " : "├── ")
    end

    print(io, node.id)

    if !isnothing(node.control)
        print(io, " => ")
        show(io, node.control)
    end

    println(io)

    children = collect(values(node.children))

    child_prefix = isroot ? "" : prefix * (islast ? "    " : "│   ")

    for (i, child) in enumerate(children)
        print_tree(io, child, child_prefix, i == length(children), false)
    end
end

print_tree(node::Node) = print_tree(stdout, node)
