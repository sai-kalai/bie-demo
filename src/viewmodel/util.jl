# Definition of Control model primitives. These are datatypes that provide:
#   - observable state
#   - validated constructors and setters
#   - default (zero-argument) constructors
#   - factory methods for domain object                                                                                                                                      r

# constructor without arguments determines default value,
# setters perform validation before altering observable state
# value must be within accepted set of values
# snapshot must provide

# definition of a real-valued state that must remain in a range
struct RealInRange{T<:Real}
    _value::Observable{T}
    _min::Observable{T}
    _max::Observable{T}

    function RealInRange{T}(
        value::Observable{T},
        min::Observable{T},
        max::Observable{T}
    ) where T

        min[] <= max[] ||
            throw(ArgumentError("Minimum must be less than or equal to maximum"))

        min[] <= value[] <= max[] ||
            throw(ArgumentError("Value must be within range"))

        new{T}(value, min, max)
    end
end
function RealInRange(value::Real, min::Real, max::Real)
    v, lo, hi = promote(value, min, max)

    T = typeof(v)

    RealInRange{T}(
        Observable(v),
        Observable(lo),
        Observable(hi)
    )
end
RealInRange(min::Real, max::Real) =
    RealInRange(min, min, max)
RealInRange(::Type{T}=Float64) where T<:Real =
    RealInRange(zero(T), zero(T), one(T))
RealInRange(val::Real) = RealInRange(val, val)

# Getters return values, not observables

value(x::RealInRange) = x._value[]
Base.minimum(x::RealInRange) = x._min[]
Base.maximum(x::RealInRange) = x._max[]

# Setters
function setvalue!(x::RealInRange{T}, v::Real) where T
    v = convert(T, v)
    isinrange(v, minimum(x), maximum(x)) ||
        throw(ArgumentError("Value outside allowed range"))
    x._value[] = v
    return v
end
# this should be the preferred api
function Base.setindex!(x::RealInRange{T}, v::Real) where T
    setvalue!(x, v)
end
function Base.getindex(x::RealInRange{T}) where T
    value(x)
end
# TODO: experiment with setindex! and notify() to provide observable-like api
# also how to make setters also use setindex?

function setminimum!(x::RealInRange{T}, v::Real) where T
    v = convert(T, v)

    v < maximum(x) ||
        throw(ArgumentError("Minimum must be less than maximum"))

    v <= value(x) ||
        throw(ArgumentError("New minimum exceeds current value"))

    x._min[] = v
    return v
end

function setmaximum!(x::RealInRange{T}, v::Real) where T
    v = convert(T, v)

    v > minimum(x) ||
        throw(ArgumentError("Maximum must be greater than minimum"))

    v >= value(x) ||
        throw(ArgumentError("New maximum is below current value"))

    x._max[] = v
    return v
end
function isinrange(val, min, max)
    min <= val <= max
end


# representation of a sum algebraic datatype
# definition of an enumeration state that must be constrained
# to an inheritance hierarchy. Concrete types must provide a zero-argument
# constructor
# A is the abstract type
struct Choice{A}
    _chosen::Observable{Symbol} # currently selected #TODO: bad naming
    _choices::Dict{Symbol,A} # keep other variants alive to restore previous state # TODO: maybe namedtuple here
end
function Choice(::Type{A}) where A
    isabstracttype(A) ||
        throw(ArgumentError("$A must be abstract"))

    variants = filter(T -> !isabstracttype(T), subtypes(A))

    isempty(variants) &&
        throw(ArgumentError("$A has no concrete direct subtypes"))

    # sort!(variants; by=string)

    choices = Dict{Symbol,A}()

    for T in variants
        key = Symbol(nameof(T))

        # prob not needed
        haskey(choices, key) &&
            throw(ArgumentError("Duplicate variant name: $key"))

        # must support default constructor
        choices[key] = T()
    end

    return Choice{A}(Observable(choices |> keys |> first), choices)
end

# getters
# #currently chosen key
chosen(x::Choice)::Symbol = x._chosen[]
# currently chosen value
function value(x::Choice{A})::A where A
    x._choices[chosen(x)]
end

function Base.getindex(x::Choice)
    return value(x)
end

Base.keys(x::Choice) = keys(x._choices)
Base.values(x::Choice) = values(x._choices)
choices(x::Choice) = x._choices

function setchosen!(x::Choice, key::Symbol)
    haskey(x._choices, key) ||
        throw(ArgumentError("Unknown choice: $key, expected one of $(x._choices|>keys|>collect)"))
    x._chosen[] = key
    return value(x)
end
function Base.setindex!(x::Choice, key::Symbol)
    setchosen!(x, key)
end

struct Switch
    _value::Observable{Bool}
end
Switch(initial::Bool=false) = Switch(Observable(initial))
value(x::Switch) = x._value[]
function setvalue!(x::Switch, v::Bool)
    x._value[] = v
    return v
end
Base.getindex(x::Switch) = value(x)
Base.setindex!(x::Switch, v::Bool) = setvalue!(x, v)


# get observables directly : WARN: observers can potentially alter the state
observable(x::RealInRange) = x._value
observable_min(x::RealInRange) = x._min # NOTE: again, how to avoid having different function names
observable_max(x::RealInRange) = x._max

observable(x::Choice) = x._chosen
observable(x::Switch) = x._value

# get all the observables in the options
observables(x::RealInRange) = (observable(x), observable_min(x), observable_max(x))
observables(x::Switch) = (observable(x),)
observables(x::Choice) = x |> values .|> observables |> Iterators.flatten |> collect


