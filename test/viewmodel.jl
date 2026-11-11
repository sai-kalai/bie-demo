# ViewModel testing -> client interaction independent of GUI
#
@info "Testing ViewModel"

using Test

using Observables

using DemoWebsite.Model # feels weird having to import Model
using DemoWebsite.ViewModel
using DemoWebsite: get_t

rir() = RealInRange(randn(), randn() - 10, randn() + 10)

@testset "ViewModel" begin

    @testset "ControlState" begin
        # default constructor
        c = ControlState()
        @test c isa ControlState
        @test observables(c) |> collect isa Vector{<:Observable}


        # constructor
        c = ControlState(
            Switch(true),
            RealInRange(20, 60),
            Choice(BoundaryShape),
            Choice(BCShape),
        )
        @test c isa ControlState

        # factory methods for input data of simulations
        prob = make_prob(c)
        alg = make_alg(c)
        # missing link here to simulate


    end

    @testset "BCShape" begin

        t = get_t(20)

        # default constructor
        bump = Bump()
        sinusoidal = Sinusoidal()
        wavepacket = WavePacket()


        shapes = (;
            bump=Bump(rir(), rir(), rir(),),
            sinusoidal=Sinusoidal(rir(), rir(), rir()),
            wavepacket=WavePacket(rir(), rir(), rir(), rir(), rir()),
        )

        @test shapes.bump isa Bump
        @test shapes.sinusoidal isa Sinusoidal
        @test shapes.wavepacket isa WavePacket

        # callable interface and observables generator
        foreach(shapes) do shape
            @test shape.(t) isa AbstractVector{<:Real}
            @test observables(shape) |> collect isa Vector{<:Observable}
        end



    end


    @testset "Boundary" begin
        t = get_t(20)

        # default constructor
        starfish = Starfish()
        circ = Circumference()

        shapes = (;
            starfish=Starfish(rir(), rir(), rir(), RealInRange(1, 5)),
            circ=Circumference(rir()),
        )

        @test shapes.starfish isa Starfish
        @test shapes.circ isa Circumference


        # callable interface and observables generator
        foreach(shapes) do shape
            @test shape.(t) isa AbstractArray
            @test observables(shape) |> collect isa Vector{<:Observable}
        end


    end

    @testset "Primitives" begin

        @testset "RealInRange" begin

            @test RealInRange() isa RealInRange
            @test RealInRange() == RealInRange()

            # TODO:
            # r1 = RealInRange(Observable(0.), Observable(0.), Observable(1.))

            r2 = RealInRange(0., 0., 1.)

            @test r2._value[] == 0.
            @test r2._min[] == 0.
            @test r2._max[] == 1.

            # @test r1 == r2

            # @test_throws ArgumentError RealInRange(
            #     Observable()
            # )

            # interval bounds incorrect
            @test_throws ArgumentError RealInRange(0., 1., 0.)
            # val out of range
            @test_throws ArgumentError RealInRange(-1., 0., 1.)

            @test RealInRange(0., 1.) == RealInRange(0., 0., 1.)

            @test RealInRange(Float64) == RealInRange(0., 0., 1.)

            @test RealInRange(1.) == RealInRange(1., 1., 1.)

            r = RealInRange(0., 0., 1.)

            @test value(r) == r._value[]
            @test r[] == r._value[]
            @test minimum(r) == r._min[]
            @test maximum(r) == r._max[]

            setvalue!(r, 0.5)
            @test r[] == 0.5

            r[] = 0.4
            @test r[] == 0.4

            @test_throws ArgumentError r[] = 1.5
            @test_throws ArgumentError setvalue!(r, 1.5)
            @test r[] == 0.4


            setmaximum!(r, 0.9)
            # less than left bound
            @test_throws ArgumentError setmaximum!(r, -1.)
            #less than current value TODO: maybe just move both instead of throwing
            @test_throws ArgumentError setmaximum!(r, 0.3)
            @test maximum(r) == 0.9


            setminimum!(r, 0.1)
            # more than right bound
            @test_throws ArgumentError setminimum!(r, 2.)
            #more than current value
            @test_throws ArgumentError setminimum!(r, 0.6)
            @test minimum(r) == 0.1

            r = RealInRange(0.5, 0., 1.)
            @test observable(r) isa Observable{Float64}
            @test observable(r)[] == 0.5
            @test observable_min(r) isa Observable{Float64}
            @test observable_min(r)[] == 0.0
            @test observable_max(r) isa Observable{Float64}
            @test observable_max(r)[] == 1.0
            @test observables(r) |> collect isa Vector{Observable{Float64}}
            @test observables(r) |> length == 3

        end

        @testset "Switch" begin
            @test Switch() isa Switch

            # ctor
            s = Switch(true)
            #getter
            @test value(s) == true
            #getindex
            @test s[] == true

            # setindex
            s[] = false
            @test s[] == false
            #setter
            setvalue!(s, true)
            @test s[] == true

            # observable
            @test observable(s) isa Observable{Bool}
            @test observable(s)[] == true
            @test observables(s) |> collect isa Vector{Observable{Bool}}
            @test observables(s) |> length==1

        end

        @testset "Choice" begin

            @test_throws ArgumentError Choice()


            # ctor from instances
            c = Choice(-1, true)
            # parameter should be supertype
            @test typeof(c) === Choice{Integer}

            # setter
            setindex!(c, :Bool)
            @test_throws ArgumentError setindex!(c, :Float64)
            @test c|>chosen === :Bool
            @test c|>value === true
            @test c[] === true

            # setindex
            c[] = :Int64
            @test_throws ArgumentError c[] = :Float64

            @test c|>chosen === :Int64
            @test c|>value === -1
            @test c[] === -1

            @test c|>keys|>Set == (:Int64, :Bool)|>Set # WARN: order not guaranteed
            @test c|>values|>Set == (-1, true)|>Set
            @test c|>choices == Dict(:Int64=>-1, :Bool=>true)

            #observable
            @test observable(c) isa Observable{Symbol}
            @test observable(c)[] === :Int64
            @test observables(c) |> collect isa Vector{Observable{Symbol}}
            @test observables(c) |> length == 1
            # nested control elements
            c = Choice(RealInRange(), Switch())
            @show observables(c)
            @test observables(c)|>collect isa Vector{<:Observable}
            @test observables(c)|>length == 5 # 1 for the choice, 3 for the real, 1 for the switch

            # ctor from union
            abstract type A end
            struct B <: A end
            struct C <: A end
            c = Choice(Union{B,C})
            @test typeof(c) === Choice{A}
            @test c|>keys|>Set == Set((:B, :C))
            @test c|>values|>Set == Set((B(), C()))

        end
    end
end
