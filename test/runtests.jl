# test suite for the demo website

using SafeTestsets


@safetestset "Model" begin include("model.jl") end
@safetestset "Viewmodel" begin include("viewmodel.jl") end
@safetestset "View" begin include("view.jl") end
@safetestset "Comp" begin include("compute.jl") end
@safetestset "Applicat" begin include("application.jl") end

