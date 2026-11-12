
# logic that uses current ViewModel input data to produce output data and
# update the SimulationModel


# using .ViewModel, .Model

# function simulation_from_controls(c::ControlState)
#
#     return sol
# end

# just for fun
# function dance(state, n=100)
#     for i in 1:n
#         # TODO update
#         # for c in getchildren(state.controls[:bc])
#         #     update!(c) do x
#         #         x + 0.01 * randn()
#         #     end
#         # end
#         sync!(state)
#         sleep(1 / 60)
#     end
# end


# modify the application state by reading the client state
function sync!(s::SimulationState, c::ControlState)

    # construct model from viewmodel
    s._prob[] = make_prob(c)
    s._alg[] = make_alg(c)

    # compute
    simulate!(s)

    return nothing
end



