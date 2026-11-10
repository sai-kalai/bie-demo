# domain model testing
@info "Testing Model"

using Test

using Observables

using DemoWebsite.Model


@testset "Model" begin

    pb = make_prob(20, :Laplace, t->(sin(t), cos(t)), :Dirichlet,
        sin, :Interior)

    alg = make_alg(:Indirect, 0.05)

    sol = make_sol(pb, alg)

    state = SimulationState(pb, alg, sol)

    @test state isa SimulationState
    @test state._prob isa Observable
    @test state._alg isa Observable
    @test state._sol isa Observable

    @test state._sol[].u isa Vector

    @testset "Default Constructor" begin
        sim = SimulationState()
        @test sim isa SimulationState
        @test sim._prob isa Observable
        @test sim._alg isa Observable
        @test sim._sol isa Observable
    end


    @testset "inplace simulate" begin

        valid = .!isnan.(state._sol[].u)

        state2 = deepcopy(state)
        state2 isa SimulationState

        @test (state2._sol[].u[valid] ≈ state._sol[].u[valid])


        #modify problem data, replace by new object...
        state2._prob[] = make_prob(20, :Laplace, t->(sin(t), cos(t)), :Dirichlet,
            t->2*sin(t), :Interior)

        @test state2._prob[] != state2._sol[].prob

        simulate!(state2)

        @test state2._prob[] == state2._sol[].prob
        @test state2._sol[].u[valid] ≈ 2. * state._sol[].u[valid]

    end

end
