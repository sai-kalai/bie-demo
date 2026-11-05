
module DemoWebsite


using Bonito
using WGLMakie



using BoundaryIntegralPDE
using BoundaryIntegralPDE.DevTools


include("../scripts/layout.jl")
include("control.jl")
include("state.jl")
include("startup.jl")
include("layout.jl")


export DefaultCard, Controls, Dashboard, make_app

export State

export start_server, make_app

export main


function main()
    app = make_app()
    server = start_server(app)
end


end
