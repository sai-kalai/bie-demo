# Logic and data storage for Bonito web app
#
using Bonito

struct ApplicationState{C,S}
    controls::C
    simulation::S
end

# Default state
function ApplicationState()
    controls = ViewModel.ControlState()

    prob = ViewModel.make_prob(controls)
    alg = ViewModel.make_alg(controls)

    sol = Model.simulate(prob, alg)

    return ApplicationState(
        controls,
        SimulationState(Observable(prob), Observable(alg), Observable(sol))
    )
end

# Store one state per browser session
const APP_STATE_KEY = :demowebsite_applicationstate

function set_state!(session, state)
    Bonito.set_metadata!(session, APP_STATE_KEY, state)
end
function get_state(session)
    Bonito.get_metadata(session, APP_STATE_KEY) # crash here if no state
end

function make_app(view_factory=Dashboard)
    # Load the external stylesheet as a Bonito asset.
    stylesheet = Bonito.Asset(
        joinpath(@__DIR__, "..", "assets", "styles.css")
    )

    return App() do session, request

        state = ApplicationState()

        set_state!(session, state)

        ctr = state.controls


        timestamp = time_ns()

        # hotreload on any user input
        onany((ctr |> observables)...) do args...
            @info "syncing states"

            delta = (time_ns() - timestamp) ÷ 10^6

            if delta > 16 # 16 ms approx 60 fps
                # i += 1
                # acc += delta
                @time sync!(state.simulation, state.controls)
                # @warn delta
                timestamp = time_ns()
            end
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
