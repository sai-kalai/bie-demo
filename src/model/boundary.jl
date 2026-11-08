# Definition of the geometry types

abstract type BoundaryShape end

# needs to be callable on a list of parameter values...

# NOTE: Takeaway: here, this should be parametric so that a concrete, fixed floating point
# representation can be used. This way, the same schema defined for the control
# model can produce a valid snapshot with the observable current values at the
# moment of the screenshot
struct Starfish{T} <: BoundaryShape
    t0::RealInRange{T}
    R::RealInRange{T}
    a::RealInRange{T}
    w::RealInRange{Int}
end
function Starfish()
    return Starfish(
        RealInRange(0., 0., 2pi),
        RealInRange(0.5, 1.5),
        RealInRange(0.3, 2.0),
        RealInRange(1, 10),
    )
end

# NOTE: Takeaway: api for setting bounds of realinrange clamps the value
# is there a way to listen for changes in any of the members? should RealInRange
# itself be in an observable
# convert struct to named tuple for kwarg splatting
# effectively "snapshot"
# This is i think the main friction with the new, heterogeneous, static schema
function tonamedtuple(x::Union{BCShape,BoundaryShape})
    names = fieldnames(typeof(x))
    values = (value(getfield(x, name)) for name in names)
    return NamedTuple{names}(values)
end
function toobservables(x::Union{BCShape,BoundaryShape})
    names = fieldnames(typeof(x))
    values = (observable(getfield(x, name)) for name in names)
    return NamedTuple{names}(values)
end
function (b::Starfish)(t::Number)
    return BoundaryIntegralPDE.starfish(
        t;
        # TODO: find a better abstraction that produces a snapshot of the control
        # model state. probably validation from the model itself is enough to trust
        # throwing data into simulation, but who knows.
        # Also field names of struct have to coincide with starfish callable which is weird.
        tonamedtuple(b)...

        # t0=b.t0, R=b.R, a=b.a, w=b.w

    )
end

struct Circle{T} <: BoundaryShape
    R::RealInRange{T}
end
function Circle()
    return Circle(RealInRange(0.5, 1.5))
end
function (b::Circle)(t::Number)
    return (b.R * cos(t), b.R * sin(t))
end


const BOUNDARY_SHAPES = (Starfish, Circle)

function subtypes(::Type{BoundaryShape})
    return BOUNDARY_SHAPES # unionalls
end
