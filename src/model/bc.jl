
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
function (b::Bump)(t)
    return bump(
        t;
        value(b)...)
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
function (b::Sinusoidal)(t)
    return sinusoidal(t; value(b)...)
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

# i really don't like constructing sin and bump again
function (b::WavePacket)(t)
    sine = Sinusoidal(1., b.ω, b.ϕ)
    bump = Bump(1., b.α, b.μ)
    return b.A * bump(t) * sine(t)

end

const BC_SHAPES = (Bump, Sinusoidal, WavePacket)

function subtypes(::Type{BCShape})
    return BC_SHAPES
end
