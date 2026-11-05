"""
Representation of the application state: the problem, solution, and algorithm
and also the controllable parameters

"""

struct State{S,T,N}
    sol::Observable{S} # solution to a bvp, contains full information
    t::Observable{T} # current time being visualized

    # tree of controllable options
    controls::N
end


function State(sol::BVPSolution, controls)
    State(Observable(sol), Observable(0.), controls)
end


