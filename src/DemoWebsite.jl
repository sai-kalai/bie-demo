
module DemoWebsite

using Observables
using Bonito
using WGLMakie


using BoundaryIntegralPDE
using BoundaryIntegralPDE.DevTools

# abstract type AbstractControl end

# util, temporary fix
function get_t(n)
    range(0, 2π; length=n + 1)[1:(end-1)]
end

include("model/Model.jl")
include("viewmodel/ViewModel.jl")
include("view/View.jl")

using .Model
using .ViewModel
using .View

include("compute.jl")
include("startup.jl")
include("application.jl")


export Model

export DefaultCard, Controls, Dashboard, make_app


export start_server, make_app

export main

export make_view


function main()
    app = make_app()
    server = start_server(app)
end


end
