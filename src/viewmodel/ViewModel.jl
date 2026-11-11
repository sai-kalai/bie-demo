
# Abstract definition of client interaction

module ViewModel

using Observables

using ..Model

export ControlState, value, setvalue!, chosen, setchosen!, choices
export Choice, RealInRange, Switch
export observable, observable_max, observable_min, observables

export Circumference, Starfish
export Bump, Sinusoidal, WavePacket

# export make_prob, make_alg

# NOTE: Takeaway: api for setting bounds of realinrange clamps the value
# is there a way to listen for changes in any of the members? should RealInRange
# itself be in an observable

# convert struct fields to named tuple for kwarg splatting
function tonamedtuple(x)
    names = fieldnames(typeof(x))
    values = (value(getfield(x, name)) for name in names)
    return NamedTuple{names}(values)
end
function fielditerator(x)
    names = fieldnames(typeof(x))
    return (getfield(x, name) for name in names)
end

include("util.jl")
include("bc.jl")
include("boundary.jl")

# strongly typed, tracks state of controls
struct ControlState
    hotreaload::Switch
    numpoints::RealInRange{Int}
    boundaryshape::Choice{BoundaryShape}
    bcshape::Choice{BCShape}
end



function ControlState()
    return ControlState(
        Switch(),
        RealInRange(40, 100),
        Choice(BoundaryShape),
        Choice(BCShape)
    )
end

# "snapshot" functions to take current state of observables from ViewModel state
# application layer can use these to construct and run sumulation

observables(x::ControlState) = (observables(f) for f in fielditerator(x)) |> Iterators.flatten

function Model.make_prob(controls::ControlState)
    return Model.make_prob(
        controls.numpoints[],
        :Laplace,
        (t) -> controls.boundaryshape[](t), # pass callables
        :Dirichlet,
        (t) -> controls.bcshape[](t),
        :Interior,
    )

end

# NOTE: WIP
function Model.make_alg(controls::ControlState)
    return Model.make_alg(:Indirect, 0.05)
end


end

