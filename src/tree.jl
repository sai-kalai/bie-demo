
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

# function Base.append!(r::Node, c)
#     children_nt = (; (n.id => n for n in r), (n.id => n for n in c)...)
#     Node(r.id, r.control, children_nt)
# end



_getnode(node::Node) = node
function _getnode(node::Node, path::Symbol...)
    # @show node.control, path
    isempty(path) && return node
    child = getproperty(node.children, first(path))
    return _getnode(child, Base.tail(path)...)
end

Base.get(node::Node, path::Symbol...) = _getnode(node, path...).control
function getchildren(node::Node, path::Symbol...)
    node = _getnode(node, path...)
    return (n.control for n in node.children)

end

Base.getindex(node::Node, path::Symbol...) = _getnode(node, path...)

function Base.show(io::IO, node::Node)
    print_tree(io, node)
end

# TODO: how to make this data compiletime, but allow each session to evolve it?
# also make more flexible constructor from Symbol, Control => []
#
# (:a, RealValued(...)) => [
#       (:b, Boolean(...)) => [],
#
# ]
#
function default_control_tree()
    root = Node(:root, nothing, [])

    Node(:boundary, nothing, [
        Node(:numpoints, RealValued(40:10:100;
            value=40,
            info=ControlInfo("Number of Boundary Points", ""))
        ), Node(:shape, CategoricalEnumeration(:starfish, [:starfish, :circle], ControlInfo())), Node(:rotation, RealValued(
            0.0:0.1:2π;
            value=0.0,
            info=ControlInfo("Rotation", "")
        ),
        ),
        Node(:size, RealValued(0.8:0.1:3.0;
            info=ControlInfo("Size", "")),
        ),
        Node(:freq, RealValued(1:1:10;
            value=5,
            info=ControlInfo("Number of Tips", "")
        ),
        ),
        Node(:ampl, RealValued(0.3:0.1:2.0;
            info=ControlInfo("Size of Tips", "")
        ),
        ),
    ])
    Node(:bc, nothing, [
        Node(:ampl, RealValued(-1:0.1:1
            ;
            info=ControlInfo("Amplitude", "")
        )),
        Node(:alpha,
            RealValued(0.1:0.1:5.0;
                value=1.0,
                info=ControlInfo("Spread", "")
            )
        ),
        Node(:omega, RealValued(-10.0:0.1:10.0;
            info=ControlInfo("Frequency", ""),
        )),
        Node(:phase, RealValued(0.0:0.1:2π;
            info=ControlInfo("Phase", "")
        )
        ),
        Node(:center, RealValued(0.0:0.1:2π;
            value=0.,
            info=ControlInfo("Location", "")
        ),
        ),
    ],)

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
