
module View

using Observables
using Observables: ObservablePair
using Bonito
using WGLMakie

# TODO: make this an ext package to support different plotting/etc
using ..ViewModel
using ..Model


include("html.jl")
include("figures/bc.jl")
include("figures/boundary.jl")
include("figures/surface.jl")


export make_view, surface_plot

end
