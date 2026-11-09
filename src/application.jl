
"""
    Dashboard layout definition

"""

"""
    DefaultCard(content=DOM.div(); class_name)

Create a dashboard container with a semantic CSS class.
"""
struct ApplicationState{C,S}
    controls::C
    simulation::S
end

# Default state
function ApplicationState()
    controls = ViewModel.ControlState()

    prob = make_prob(controls)
    alg = make_alg(controls)

    sol = simulate(prob, alg)

    return ApplicationState(
        controls,
        SimulationState(Observable(prob), Observable(alg), Observable(sol))
    )
end

function DefaultCard(content=DOM.div(); class_name)
    return Card(content; class=class_name)
end


function Controls(state::ApplicationState)

    controls = state.controls

    return make_view(controls)
end

function Controls(session::Bonito.Session)
    state = get_state(session)
    return Controls(state)
end

# should these be in view? should they take a session or a state?
function Dashboard(session::Bonito.Session)
    state = get_state(session)
    Dashboard(state)
end

function Dashboard(state::ApplicationState)
    # The plot that the frontend displays.


    plot = surface_plot(state.simulation; figsize=(1300, 760))

    controls = Controls(state)


    sidebar = DefaultCard(
        controls;
        class_name="dashboard-card dashboard-sidebar",
    )

    header = DefaultCard(
        "BoundaryIntegralEquations.jl live demo";
        class_name="dashboard-card dashboard-header",
    )

    main = DefaultCard(
        plot;
        class_name="dashboard-card dashboard-main",
    )

    footer = DefaultCard(
        DOM.a(
            "GitHub";
            href="https://github.com/sai-kalai/BoundaryIntegralEquations.jl",
        );
        class_name="dashboard-card dashboard-footer",
    )

    return Grid(
        sidebar,
        header,
        main,
        footer;
        columns="2fr 5fr",
        rows="1fr 10fr 1fr",
        areas="""
        'header header'
        'sidebar main'
        'footer footer';
        """,
        width="100%",
        height="100%",
        class="dashboard-grid",
    )
end

"""
Definition of the logic to create a webapp and serve it

"""




const APP_STATE_KEY = :demowebsite_state

function set_state!(session, state)
    Bonito.set_metadata!(session, APP_STATE_KEY, state)
end
function get_state(session)
    Bonito.get_metadata(session, APP_STATE_KEY) # crash here if no state
end

function make_app()
    # Load the external stylesheet as a Bonito asset.
    stylesheet = Bonito.Asset(
        joinpath(@__DIR__, "..", "assets", "styles.css")
    )

    return App() do session, request

        state = ApplicationState()

        set_state!(session, state)

        @info session

        ctr = state.controls


        # hotreload on any user input
        onany((ctr |> observables)...) do args...

            @info "syncing states"
            @time sync!(state.simulation, state.controls)
        end

        dashboard = Dashboard(session)
        # @info os
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

function start_server(app)
    server = Server(app, "0.0.0.0", 8080)
    route!(server, "/" => app)
    return server
end
