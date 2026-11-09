
# Abstract definition of client interaction

module ViewModel

export ControlState, value, setvalue!, chosen, setchosen!, choices
export Choice, RealInRange, Switch
export observable, observable_max, observable_min, observables
export tonamedtuple

export make_prob, make_alg, make_target

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

function fielditerator(x)
    names = fieldnames(typeof(x))
    return (getfield(x, name) for name in names)
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

function make_prob(controls::ControlState)

    t = controls.numpoints |> value |> get_t

    b = DiscreteClosedCurve(t, (t) -> (controls.boundaryshape[])(t))

    # don't like calling value here, need "snapshot" that has the same shape as the
    # state struct but where the fields are a concrete numeric type, not RealInRange
    bc_fn = controls.bcshape[]


    # Dirichlet and Laplace need to be in the controls)
    bc = Dirichlet(bc_fn.(t))


    pb = BoundaryValueProblem(Laplace(), bc, Interior(), b)

    return pb
end

# NOTE: WIP
function make_alg(controls::ControlState)
    return IndirectBVPAlgorithm(evalmethod=CauchyIntegral()), IndirectBIEAlgorithm()
end

function make_target(controls; n_grid=50)

    xmin, xmax, ymin, ymax = extrema(pb.boundary)

    # TODO: dont define eval domain every time
    xs = range(xmin, xmax, length=n_grid)
    ys = range(ymin, ymax, length=n_grid)
    x_test = stack((x, y) for y in ys for x in xs)
end


end

