# representation fo the contol structure

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
    print(io, "RealValued(", c.value[], ", range=", c.range, ")")
end
