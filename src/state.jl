"""
Representation of the application state: the problem, solution, and algorithm

"""

struct State
    sol::Observable{Any} # solution to a bvp
    t::Observable{Float64} # current time being visualized
end

function State(sol::BVPSolution)

    State(sol, 0.)

end


