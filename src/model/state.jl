"""
Representation of the application state: the problem, solution, and algorithm
"""

# TODO: maybe rename simulation.jl


struct SimulationState{P,A,S}
    _prob::Observable{P}
    _alg::Observable{A}
    _sol::Observable{S} # solution to a bvp, contains full information about prob and alg anyways...
end

# the concrete types must support solve(prob, alg) -> sol
# The solution must support observable plotting e.g. via Makie recipe
# in principle, different simulation software can be used.


# function solve(state)
#     return solve(state._prob[], state._alg[])
# end



# TODO: decouple from simulation backend


# function simulate(pb, alg, target)
#     return solve(pb, alg; target=target)
# end


function simulate!(state::SimulationState, target)
    sol = simulate(
        state._prob[],
        state._alg[],
        target,
    )

    # update observable state

    state._sol[] = sol
    return nothing
end


function simulate(prob, alg, target)
    return solve(prob, alg; target=target)
end
