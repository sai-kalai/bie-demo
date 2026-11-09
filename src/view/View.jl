
module View

using Bonito
using WGLMakie

include("html.jl")
include("figures/bc.jl")
include("figures/boundary.jl")
include("figures/surface.jl")


export make_view, surface_plot

end
