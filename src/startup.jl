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

        dashboard = Dashboard(state)
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



# TODO: how to make this data compiletime, but allow each session to evolve it?
function default_control_tree()
    return Node(:root, nothing, [
        Node(:boundary, nothing, [
            Node(:numpoints, RealValued(40:10:100;
                value=40,
                info=ControlInfo("Number of Boundary Points", ""))
            ),
            Node(:rotation, RealValued(
                0.0:0.1:2π;
                value=0.0,
                info=ControlInfo("Rotation", "")
            ),
            ),
            Node(:size, RealValued(0.8:0.1:3.0;
                info=ControlInfo("Size", "")),
            ),
            Node(:freq, RealValued(1:1:10;
                value=5,
                info=ControlInfo("Number of Tips", "")
            ),
            ),
            Node(:ampl, RealValued(0.3:0.1:2.0;
                info=ControlInfo("Size of Tips", "")
            ),
            ),
        ]),
        Node(:bc, nothing, [
            Node(:ampl, RealValued(-1:0.1:1
                ;
                info=ControlInfo("Amplitude", "")
            )),
            Node(:alpha,
                RealValued(0.1:0.1:5.0;
                    value=1.0,
                    info=ControlInfo("Spread", "")
                )
            ),
            Node(:omega, RealValued(-10.0:0.1:10.0;
                info=ControlInfo("Frequency", ""),
            )),
            Node(:phase, RealValued(0.0:0.1:2π;
                info=ControlInfo("Phase", "")
            )
            ),
            Node(:center, RealValued(0.0:0.1:2π;
                value=0.,
                info=ControlInfo("Location", "")
            ),
            ),
        ],)
    ])
end

# TODO: config struct with fixed schema for a specific application

function problem_from_controls(tree::Node)

    t = get_t(getcontrol(tree, :boundary, :numpoints).state[])

    b = DiscreteClosedCurve(t, (t) -> starfish(
        t;
        t0=getcontrol(tree, :boundary, :rotation).state[],
        R=getcontrol(tree, :boundary, :size).state[],
        a=getcontrol(tree, :boundary, :ampl).state[],
        w=getcontrol(tree, :boundary, :freq).state[],
    ))

    bc_fn = (_t) -> begin
        A = getcontrol(tree, :bc, :ampl).state[]
        α = getcontrol(tree, :bc, :alpha).state[]
        ω = getcontrol(tree, :bc, :omega).state[]
        ϕ = getcontrol(tree, :bc, :phase).state[]
        μ = getcontrol(tree, :bc, :center).state[]

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




