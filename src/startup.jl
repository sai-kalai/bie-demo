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


STATE=nothing

function make_app()
    # Load the external stylesheet as a Bonito asset.
    stylesheet = Bonito.Asset(
        joinpath(@__DIR__, "..", "assets", "styles.css")
    )

    return App() do session, request

        state = default_state()

        global STATE
        STATE = state # for debug

        dashboard = Dashboard(state)
        # TODO: compute initial state in this callback so that it's unique to the session
        DOM.div(
            stylesheet,
            DOM.div(dashboard; class="dashboard-root"),
        )
    end
end
function default_control_tree()
    return Node(:root, nothing, [
        Node(:boundary, nothing, [
            Node(:numpoints, RealValued(40:10:100; value=40)),
            Node(:rotation, RealValued(0.0:0.1:2π; value=0.0)),
            Node(:size, RealValued(0.8:0.1:3.0)),
            Node(:freq, RealValued(2:10; value=5)),
            Node(:ampl, RealValued(0.3:0.1:2.0)),
        ]),
        Node(:bc, nothing, [
            Node(:ampl, RealValued(-1:1)),
            Node(:alpha, RealValued(0.1:0.1:5.0; value=1.0)),
            Node(:omega, RealValued(-10.0:0.1:10.0)),
            Node(:phase, RealValued(0.0:0.1:2π)),
            Node(:center, RealValued(0.0:(π/8):2π; value=π / 2)),
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

# read data from client and produce a new simulation solution
function sol_from_client_state(s)

    t = get_t(_get(s, :numpoints))

    b = DiscreteClosedCurve(t, (t) -> starfish(
        t;
        t0=_get(s, :bdryrotation),
        R=_get(s, :bdrysize),
        a=_get(s, :bdryampl),
        w=_get(s, :bdryfreq),
    ))


    bc_fn = (t) -> begin
        A = _get(s, :bcampl)
        α = _get(s, :bcalpha)
        ω = _get(s, :bcomega)
        ϕ = _get(s, :bcphase)
        μ = _get(s, :bccenter)

        return (A / (α * sqrt(2pi))) * exp(-(t - μ)^2 / (2α^2)) * sin(ω * t + ϕ)
    end

    bc = Dirichlet(
        bc_fn.(t)
    )

    pb = BoundaryValueProblem(Laplace(), bc, Interior(), b)

    xs, ys, sol = simulate(pb)

    return sol
end


