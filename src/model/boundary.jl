# Definition of the geometry types

abstract type BoundaryShape end

# needs to be callable on a list of parameter values...

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

function (b::Starfish)(t::Number)
    return BoundaryIntegralPDE.starfish(
        t;
        # TODO: find a better abstraction that produces a snapshot of the control
        # model state. probably validation from the model itself is enough to trust
        # throwing data into simulation, but who knows.
        # Also field names of struct have to coincide with starfish callable which is weird.
        value(b)...

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
