module Model

# Definition of the data entities of this website:
# domain geometry and parameters, boundary condition shapes and parameters,
# solver configuration, etc.

using BoundaryIntegralPDE
using Observables

include("state.jl")

export SimulationState, simulate, simulate!


end # module Model
