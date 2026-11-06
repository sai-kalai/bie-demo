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
    print(io, "RealValued(", c |> value, ", range=", c.range, ")")
end

# data validation

# disallow directly accessing the value
function Base.getproperty(c::AbstractControl, name::Symbol)
    name === :value && @warn "reading observable directly"
    return getfield(c, name)
end

value(c::AbstractControl) = getfield(c, :value)[]

function set_value!(c::RealValued, x)::Bool
    a, b = extrema(c.range)
    a <= x <= b || return false
    getfield(c, :value)[] = x
    return true
end

# inplace modification convenience
function update!(f, c::AbstractControl)
    set_value!(c, f(value(c)))
end
