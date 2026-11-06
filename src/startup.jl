"""
Definition of the logic to create a webapp and serve it

"""

function start_server(app)
    server = Server(app, "0.0.0.0", 8080)
    route!(server, "/" => app)
    return server
end

function default_state()
    control_tree = default_control_tree()

    sol = sol_from_controls(control_tree)

    state = State(Observable(sol), Observable(0.), control_tree)
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

function problem_from_controls(tree::Node)

    t = get_t(get(tree, :boundary, :numpoints).value[])

    b = DiscreteClosedCurve(t, (t) -> starfish(
        t;
        t0=get(tree, :boundary, :rotation).value[],
        R=get(tree, :boundary, :size).value[],
        a=get(tree, :boundary, :ampl).value[],
        w=get(tree, :boundary, :freq).value[],
    ))

    bc_fn = (_t) -> begin
        A = get(tree, :bc, :ampl).value[]
        α = get(tree, :bc, :alpha).value[]
        ω = get(tree, :bc, :omega).value[]
        ϕ = get(tree, :bc, :phase).value[]
        μ = get(tree, :bc, :center).value[]

        return (A / (α * sqrt(2pi))) * exp(-(_t - μ)^2 / (2α^2)) * sin(ω * _t + ϕ)
    end

    bc = Dirichlet(
        bc_fn.(t)
    )

    pb = BoundaryValueProblem(Laplace(), bc, Interior(), b)
    return pb
end

function sol_from_controls(c)
    pb = problem_from_controls(c)
    xs, ys, sol = simulate(pb)

    return sol
end




