# Definition of the geometry types

abstract type AbstractBoundaryShape end

import BoundaryIntegralPDE: starfish

# needs to be callable on a list of parameter values...

# NOTE: Takeaway: here, this should be parametric so that a concrete, fixed floating point
# representation can be used. This way, the same schema defined for the control
# model can produce a valid snapshot with the observable current values at the
# moment of the screenshot
struct Starfish{T} <: AbstractBoundaryShape
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
    return starfish(
        t;
        # TODO: find a better abstraction that produces a snapshot of the control
        # model state. probably validation from the model itself is enough to trust
        # throwing data into simulation, but who knows.
        # Also field names of struct have to coincide with starfish callable which is weird.
        tonamedtuple(b)...

        # t0=b.t0, R=b.R, a=b.a, w=b.w

    )
end

struct Circumference{T} <: AbstractBoundaryShape
    R::RealInRange{T}
end
function Circumference()
    return Circumference(RealInRange(0.5, 1.5))
end
function (b::Circumference)(t::Number)
    return (b.R[] * cos(t), b.R[] * sin(t))
end




# TODO: how to automate testing of added shapes?

BoundaryShape = Union{Starfish,Circumference}


observables(x::BoundaryShape) = (observable(f) for f in fielditerator(x))
