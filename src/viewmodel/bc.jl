
abstract type BCShape end

struct Bump{T} <: BCShape
    A::RealInRange{T}   #amplitude
    α::RealInRange{T} # stdev
    μ::RealInRange{T} #mean
end

defaultamplitude() = RealInRange(1., -1., 1.)

function Bump()
    return Bump(
        defaultamplitude(),
        RealInRange(1., 0., 5.),
        RealInRange(pi, 0, 2pi),
    )
end
function (b::Bump)(t::Real)
    return bump(
        t;
        tonamedtuple(b)...)
end
function bump(t; A, α, μ)
    (A / (α * sqrt(2pi))) * exp(-(t - μ)^2 / (2α^2))
end

struct Sinusoidal{T} <: BCShape
    A::RealInRange{T}
    ω::RealInRange{T} # wavenumber
    ϕ::RealInRange{T}
end
function Sinusoidal()
    return Sinusoidal(
        defaultamplitude(),
        RealInRange(-10., 10.),
        RealInRange(0., 2pi),)
end
function (b::Sinusoidal)(t::Real)
    return sinusoidal(t; tonamedtuple(b)...)
end
function sinusoidal(
    t; A, ω, ϕ
)
    return A * sin(ω * t + ϕ)
end

struct WavePacket{T} <: BCShape
    A::RealInRange{T}
    α::RealInRange{T}
    ω::RealInRange{T}
    ϕ::RealInRange{T}
    μ::RealInRange{T}
end

function WavePacket(sine::Sinusoidal, bump::Bump)
    return WavePacket(
        defaultamplitude(),
        bump.α,
        sine.ω,
        sine.ϕ,
        bump.μ,)
end
function WavePacket()
    return WavePacket(
        Sinusoidal(), Bump(),
    )
end

#NOTE: Takeaway: i really don't like constructing sin and bump again
#Also, constructing these types should be possible in "half observable" way and
#the observables should be usable in arithmetic. maybe just using the snapshot version is fine: snapshot before arithmetic so all fields are converted to current value
#Also, validation at snapshot time could be useful but also live updating of values, e.g. when the sise of a starship is too low, reduce the maximum tip size so no spurious or self intersecting curves occur
#and the thumbs in html move automatically
function (b::WavePacket)(t::Real)
    # TODO: another problem: this constructor doesn't work
    sine = Sinusoidal(RealInRange(1.), b.ω, b.ϕ)
    bmp = Bump(RealInRange(1.), b.α, b.μ)
    # TODO: also awkward value call here...
    return value(b.A) * bmp(t) * sine(t)

end

const BC_SHAPES = (Bump, Sinusoidal, WavePacket)

function subtypes(::Type{BCShape})
    return BC_SHAPES
end

# TODO: i really dislike this manual workflow but this interface is probably the correct
# way to subscribe to any of the sub-observables

# observables(x::Sinusoidal) = (observables(x.A)..., observables(x.ω)..., observables(x.ϕ)...)
# observables(x::Bump) = (observables(x.A)..., observables(x.μ)..., observables(x.α)...)
# observables(x::WavePacket) = (observables(x.A)..., observables(x.μ)..., observables(x.α)...)



observables(x::BCShape) = (observable(f) for f in fielditerator(x))
