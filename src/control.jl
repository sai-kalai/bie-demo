# representation fo the contol structure

# The data model for controls specifies the validity of values and can be
# configured at app startup. The view implementations produce valid HTML from
# the control configuration.

_alltrue(args...) = true

struct ControlInfo
    label::String
    tooltip::String
end
function ControlInfo()
    return ControlInfo("", "")
end

# materialized as e.g. sliders, number inputs
struct RealValued{T,R<:AbstractRange{T}} <: AbstractControl
    state::Observable{T} # current value
    range::R # TODO: make observable, some configurations may be invalid after state changes
    info::ControlInfo
end
function RealValued(range; value=first(range), info=ControlInfo())
    return RealValued(Observable(value), range, info,)
end

# e.g. dropdown menu
# "sum ADT"
struct CategoricalEnumeration{T} <: AbstractControl
    state::Observable{T}
    variants::Vector{T}
    info::ControlInfo
end

# e.g. checkbox
struct Boolean <: AbstractControl
    state::Observable{Bool}
    info::ControlInfo
end

function Base.show(io::IO, c::RealValued)
    print(io, "RealValued(", c.state[], ", range=", c.range, ")")
end
