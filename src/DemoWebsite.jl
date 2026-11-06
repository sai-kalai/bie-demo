
module DemoWebsite


using Bonito
using WGLMakie



using BoundaryIntegralPDE
using BoundaryIntegralPDE.DevTools

abstract type AbstractControl end

include("tree.jl")
include("control.jl")
include("compute.jl")
include("state.jl")
include("view.jl")
include("startup.jl")
include("layout.jl")
include("figures/surface.jl")



export DefaultCard, Controls, Dashboard, make_app

export State

export start_server, make_app

export main

export make_view

function main()
    app = make_app()
    server = start_server(app)
end


end
