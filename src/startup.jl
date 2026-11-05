"""
Definition of the logic to create a webapp and serve it

"""

function start_server(app)
    server = Server(app, "0.0.0.0", 8080)
    route!(server, "/" => app)
    return server
end

function make_app()
    # Load the external stylesheet as a Bonito asset.
    stylesheet = Bonito.Asset(
        joinpath(@__DIR__, "..", "assets", "styles.css")
    )

    return App() do session, request
        client_state = default_client_state()

        sol = sol_from_client_state(client_state)

        state = State(sol)

        dashboard = Dashboard(state)
        # TODO: compute initial state in this callback so that it's unique to the session
        DOM.div(
            stylesheet,
            DOM.div(dashboard; class="dashboard-root"),
        )
    end
end


function default_control_tree()

    boundary = ControlGroup(
        "boundary",
        AbstractControlNode[
            RealValued("numpoints", 40:10:100; value=40),
            RealValued("bdryrotation", 0.0:0.1:2π; value=0.0),
            RealValued("bdrysize", 0.8:0.1:3.0),
            RealValued("bdryfreq", 2:10; value=5),
            RealValued("bdryampl", 0.3:0.1:2.0),
        ],
        always,
    )

    boundary_condition = ControlGroup(
        "boundary_condition",
        AbstractControlNode[
            RealValued("bcampl", -1:1),
            RealValued("bcalpha", 0.1:0.1:5.0; value=1.0),
            RealValued("bcomega", -10.0:0.1:10.0),
            RealValued("bcphase", 0.0:0.1:2π),
            RealValued("bccenter", 0.0:(π/8):2π; value=π / 2),
        ],
        always,
    )

    return ControlGroup(
        "root",
        AbstractControlNode[
            boundary,
            boundary_condition,
        ],
        always,
    )
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


# just for testing
function default_state()
    # initialize the state
    sol = default_sol()
    state = State(sol)
    return state
end

function default_sol()
    n = 100
    t, pb = setup(n)
    xs, ys, sol = simulate(pb) # this sol needs to be an observable
    return sol
end
