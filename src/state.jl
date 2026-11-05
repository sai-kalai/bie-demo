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


# just for fun
function dance(state, n=100)
    for i in 1:n

        for c in state.controls[:bc].children
            c.control.state[] += 0.01*randn()
        end
        sync!(state)
        sleep(1/60)

    end
end
