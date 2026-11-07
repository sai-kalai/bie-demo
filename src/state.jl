"""
Representation of the application state: the problem, solution, and algorithm
and also the controllable parameters

"""

struct State{S,T,C}
    sol::Observable{S} # solution to a bvp, contains full information about
    # computed boundary shape, conditions, results
    t::Observable{T} # current time being visualized

    # tree of controllable options
    controls::C # contains state of user driven choices
end


function State(sol::BVPSolution, controls)
    State(Observable(sol), Observable(0.), controls)
end


# just for fun
function dance(state, n=100)
    for i in 1:n

        for c in getchildren(state.controls[:bc])
            update!(c) do x
                x + 0.01 * randn()
            end
        end
        sync!(state)
        sleep(1 / 60)

    end
end


# modify the application state by reading the client state
function sync!(state)

    # recompute solution
    sol = sol_from_controls(state.controls)

    # set the observable state to the new simulation solution
    state.sol[] = sol

    return nothing
end
