module Model

# Definition of the data entities of this website:
# domain geometry and parameters, boundary condition shapes and parameters,
# solver configuration, etc.

using BoundaryIntegralPDE
using Observables

# this is core model?
# i guess the core entities of this project are defined here
# export BoundaryIntegralPDE
#
include("state.jl")

export SimulationState, make_sol, simulate!
export make_prob, make_alg


end # module Model
