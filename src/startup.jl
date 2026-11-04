"""
Definition of the logic to create a webapp and serve it

"""

function start_server(app)
    server = Server(app, "0.0.0.0", 8080)
    route!(server, "/" => app)
    return server
end

function make_app(state::State)
    dashboard = Dashboard(state)

    # Load the external stylesheet as a Bonito asset.
    stylesheet = Bonito.Asset(
        joinpath(@__DIR__, "..", "assets", "styles.css")
    )

    return App() do
# TODO: compute initial state in this callback so that it's unique to the session
        DOM.div(
            stylesheet,
            DOM.div(dashboard; class="dashboard-root"),
        )
    end
end

function make_app()
    state = default_state()
    make_app(state)
end

function default_state()
    n = 100
    t, pb = setup(n)
    xs, ys, sol = simulate(pb) # this sol needs to be an observable
    # initialize the state
    state = State(sol)
end
