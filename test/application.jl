# web application testing
@info "Testing Web Application"

using Test

using Bonito
using HTTP

using DemoWebsite
using DemoWebsite: ApplicationState, get_state, list_sessions
using DemoWebsite.ViewModel
using DemoWebsite.Model

@testset "Bonito Web Application" begin

    state = ApplicationState()
    @test state isa ApplicationState
    @test state.controls isa ControlState
    @test state.simulation isa SimulationState

    app = make_app(
    # ()->nothing
    )

    @test app isa Bonito.App

    @testset "running server" begin

        server = start_server(app)

        @test server.websocket_routes.table |> length == 0
        resp = HTTP.get("http://$(server.url):$(server.port)")
        @test resp.status == 200
        @test server |> list_sessions |> length == 1

        resp = HTTP.get("http://$(server.url):$(server.port)")
        @test resp.status == 200
        @test server |> list_sessions |> length == 2
        states = get_state.(list_sessions(server))
        @test states isa Vector{<:ApplicationState}
        @test states[1] != states[2]

        state = states[1]

        @test state.controls.numpoints[] == state.simulation._prob[].bc.σ |> length
        state.controls.numpoints[] = 42

        # TODO: too much private api
        @test state.simulation._sol[].bie_solution.u |> length == 42


        close(server) # manual closing is crazy
    end



    @testset "client interaction" begin
        # TODO: test ui with Electron
    end

end
