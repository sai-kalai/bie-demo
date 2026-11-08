"""
Definition of the logic to create a webapp and serve it

"""

function start_server(app)
    server = Server(app, "0.0.0.0", 8080)
    route!(server, "/" => app)
    return server
end

function default_state()
    controls = Model.ControlState()

    sol = sol_from_controls(controls)

    state = State(Observable(sol), Observable(0.), controls)
    return state
end


# global registry for debugging
# const SESSIONS = Dict{SessionID, State}()


const APP_STATE_KEY = :demowebsite_state

function set_state!(session, state)
    set_metadata!(session, APP_STATE_KEY, state)
end
function get_state(session)
    get_metadata(session, APP_STATE_KEY) # crash here if no state
end

function make_app()
    # Load the external stylesheet as a Bonito asset.
    stylesheet = Bonito.Asset(
        joinpath(@__DIR__, "..", "assets", "styles.css")
    )

    return App() do session, request

        state = default_state()

        set_state!(session, state)

        @info session

        ctr = state.controls

        # NOTE: Takeaway
        # this code sucks, need to define a structured way to collect observables
        os = (
            ctr.numpoints |> observable,
            ctr.boundaryshape |> observable,
            (ctr.boundaryshape._choices |> values |> collect .|> Model.toobservables |> Iterators.flatten |> collect)...,
            ctr.bcshape |> observable,
            (ctr.bcshape._choices |> values |> collect .|> Model.toobservables |> Iterators.flatten |> collect)...,
        )

        @info os

        onany(os...) do args...
            sync!(state)
        end

        dashboard = Dashboard(session)
        # TODO: compute initial state in this callback so that it's unique to the session
        DOM.div(
            stylesheet,
            DOM.div(dashboard; class="dashboard-root"),
        )
    end
end

function list_sessions(server::Server=Bonito.get_server())
    lock(server.websocket_routes.lock) do
        [
            conn.session
            for (_, conn) in server.websocket_routes.table
            if conn isa Bonito.WebSocketConnection &&
                !isnothing(conn.session)
        ]
    end
end

# TODO: config struct with fixed schema for a specific application

#NOTE: Takeaway: tree is too flexible
# function problem_from_controls(tree::Node)
#
#     t = get(tree, :boundary, :numpoints) |> Model.value |> get_t
#
#     b = DiscreteClosedCurve(t, (t) -> starfish(
#         t;
#         t0=get(tree, :boundary, :rotation) |> oldvalue,
#         R=get(tree, :boundary, :size) |> oldvalue,
#         a=get(tree, :boundary, :ampl) |> oldvalue,
#         w=get(tree, :boundary, :freq) |> oldvalue,
#     ))
#
#     bc_fn = (_t) -> begin
#         A = get(tree, :bc, :ampl) |> oldvalue # maybe getvalue?
#         α = get(tree, :bc, :alpha) |> oldvalue
#         ω = get(tree, :bc, :omega) |> oldvalue
#         ϕ = get(tree, :bc, :phase) |> oldvalue
#         μ = get(tree, :bc, :center) |> oldvalue
#
#         return (A / (α * sqrt(2pi))) * exp(-(_t - μ)^2 / (2α^2)) * sin(ω * _t + ϕ)
#     end
#
#     bc = Dirichlet(
#         bc_fn.(t)
#     )
#
#     pb = BoundaryValueProblem(Laplace(), bc, Interior(), b)
#     return pb
# end

function problem_from_controls(controls::ControlState)

    t = controls.numpoints |> value |> get_t

    b = DiscreteClosedCurve(t, (t) -> (controls.boundaryshape |> value)(t))

    # don't like calling value here, need "snapshot" that has the same shape as the
    # state struct but where the fields are a concrete numeric type, not RealInRange
    bc_fn = controls.bcshape |> value


    bc = Dirichlet(
        bc_fn.(t)
    )

    @info bc

    pb = BoundaryValueProblem(Laplace(), bc, Interior(), b)
    return pb
end

function sol_from_controls(c)
    pb = problem_from_controls(c)
    xs, ys, sol = simulate(pb)

    return sol
end




