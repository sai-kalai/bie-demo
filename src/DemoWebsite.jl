
module DemoWebsite

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
include("application.jl")
include("startup.jl")


# export Model

export start_server, make_app

export main



function main()
    app = make_app()
    server = start_server(app)
end


end
