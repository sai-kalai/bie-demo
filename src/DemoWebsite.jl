
module DemoWebsite


using Bonito
using WGLMakie



using BoundaryIntegralPDE
using BoundaryIntegralPDE.DevTools


include("../scripts/layout.jl")
include("layout.jl")

export DefaultCard, Controls, Dashboard, make_app

end
