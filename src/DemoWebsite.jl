
module DemoWebsite


using Bonito
using WGLMakie



using BoundaryIntegralPDE
using BoundaryIntegralPDE.DevTools


include("../scripts/layout.jl")
include("state.jl")
include("startup.jl")
include("layout.jl")

export DefaultCard, Controls, Dashboard, make_app

export State


export start_server, make_app, default_state

export main


function main()

    state = default_state()
    app = make_app(state)
    server = start_server(app)
end


end
