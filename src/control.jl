# representation fo the UI state and constraints
# validation at this layer prevents invalid visualization states
#
# actually, this is the view!

# The data model for controls specifies the validity of values and can be
# configured at app startup. The view implementations produce valid HTML from
# the control configuration.


# Represents the state of UI. maybe validity doesn't belong here. Composable
# and flexible tree structure determines schema.

_alltrue(args...) = true

# this couples to display...
struct ControlInfo
    label::String
    tooltip::String
end
function ControlInfo()
    return ControlInfo("", "")
end

# materialized as e.g. sliders, number inputs
struct RealValued{T,R<:AbstractRange{T}} <: AbstractControl
    value::Observable{T} # current value
    range::R # TODO: make observable, some configurations may be invalid after state changes
    info::ControlInfo

    function RealValued(
        value::Observable{T},
        range::R,
        info::ControlInfo
    ) where {T,R<:AbstractRange{T}}

        is_in_range(value[], range) ||
            throw(ArgumentError("Initial value outside allowed range"))
        new{T,R}(value, range, info)
    end
end
function RealValued(range; value=first(range), info=ControlInfo())
    return RealValued(Observable(value), range, info,)
end

# e.g. dropdown menu
# "sum ADT"
struct CategoricalEnumeration{T} <: AbstractControl
    value::Observable{T}
    variants::Vector{T}
    info::ControlInfo
end

# e.g. checkbox
struct Boolean <: AbstractControl
    value::Observable{Bool}
    info::ControlInfo
end

function Base.show(io::IO, c::RealValued)
    print(io, "RealValued(", c |> oldvalue, ", range=", c.range, ")")
end

# data validation

# disallow directly accessing the value
function Base.getproperty(c::AbstractControl, name::Symbol)
    name === :value && @warn "reading observable directly"
    return getfield(c, name)
end

oldvalue(c::AbstractControl) = getfield(c, :value)[]

function set_value!(c::RealValued, x)::Bool
    is_in_range(x, c.range) || return false
    @info "value set to: " x
    getfield(c, :value)[] = x
    return true
end

function is_in_range(x, rng)
    a, b = extrema(rng)
    a <= x <= b
end

# inplace modification convenience
function update!(f, c::AbstractControl)
    set_value!(c, f(oldvalue(c)))
end


function make_config(controls::Node)

end


# function make_controls(config::SimulationConfig)
#     boundary = make_controls(config.boundary)
#     bc = make_controls(config.bc)
#
#     numpoints = Node(:numpoints, RealValued(40:10:100;
#         value=40,
#         info=ControlInfo("Number of Boundary Points", ""))
#     )
#
#     return Node(:root, nothing, [
#         Node(:boundary, nothing, [
#             boundary..., numpoints
#         ]),
#         Node(:bc, nothing, bc)])
#
# end
#
# function make_controls(config::Starfish)
#     return [
#         Node(:rotation, RealValued(
#             0.0:0.1:2π;
#             value=config.t0,
#             info=ControlInfo("Rotation", "")
#         ),
#         ),
#         Node(:size, RealValued(0.8:0.1:3.0;
#             value=config.R,
#             info=ControlInfo("Size", "")),
#         ),
#         Node(:freq, RealValued(1:1:10;
#             value=config.w,
#             info=ControlInfo("Number of Tips", "")
#         ),
#         ),
#         Node(:ampl, RealValued(0.3:0.1:2.0;
#             value=config.a,
#             info=ControlInfo("Size of Tips", "")
#         ),
#         ),]
#
#
# end
#
# function make_controls(config::Circle)
#     return [
#         Node(:size, RealValued(0.8:0.1:3.0;
#             value=config.R,
#             info=ControlInfo("Size", "")),
#         ),
#     ]
# end
#
# # TODO: this is better with convert
#
# function make_controls(b::Bump)
#     return [
#         Node(:amplitude, RealValued(0.0:0.01:10.0; value=b.A)),
#         Node(:width, RealValued(0.01:0.01:5.0; value=b.α)),
#         Node(:center, RealValued(-π:0.01:π; value=b.μ)),
#     ]
# end
#
# function make_controls(b::Sine)
#     return [
#         Node(:amplitude, RealValued(0.0:0.01:10.0; value=b.A)),
#         Node(:frequency, RealValued(0.1:0.1:20.0; value=b.ω)),
#         Node(:phase, RealValued(-π:0.01:π; value=b.ϕ)),
#     ]
# end
#
# function make_controls(b::WavePacket)
#     return [
#         Node(:amplitude, RealValued(0.0:0.01:10.0; value=b.A)),
#         Node(:width, RealValued(0.01:0.01:5.0; value=b.α)),
#         Node(:frequency, RealValued(0.1:0.1:20.0; value=b.ω)),
#         Node(:phase, RealValued(-π:0.01:π; value=b.ϕ)),
#         Node(:center, RealValued(-π:0.01:π; value=b.μ)),
#     ]
# end
