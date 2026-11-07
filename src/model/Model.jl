module Model

# Definition of the data entities of this website:
# domain geometry and parameters, boundary condition shapes and parameters,
# solver configuration, etc.

using Observables
using BoundaryIntegralPDE

export ControlState, value, setvalue!, chosen, setchosen!, choices
export Choice, RealInRange
export observable, observable_max, observable_min

include("util.jl")
include("boundary.jl")
include("bc.jl")

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

end # module Model
