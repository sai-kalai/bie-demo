# Definition of how the HTML representation of control elements


# function make_view(Type{Bonito.StylableSlider}, ::AbstractControl)
#
# end


# taken from Bonito current version
function slider_value_index(values::AbstractVector, value)
    isempty(values) && throw(ArgumentError("Slider: `values` must be non-empty"))
    exact = findfirst((==)(value), values)
    exact === nothing || return exact
    if value isa Real && eltype(values) <: Real
        return argmin(abs.(values .- value))
    end
    @warn "Slider: value $(value) not in values; defaulting to the first element"
    return firstindex(values)
end

function make_view(::Type{Bonito.StylableSlider}, c::RealValued)

    sldr = Bonito.StylableSlider(c.range; value=c.value[])

    # backend => frontend
    map!(sldr.index, c.value) do v
        # slider index gets updated whenever state changes
        idx = slider_value_index(sldr.values[], v)
        @info "slider set to idx: " idx
        idx
    end

    # frontend => backend
    on(sldr.value) do v
        # TODO: replace this by guarded setter
        @info "control set to: " v
        c.value[] = v
    end

    return sldr
end

default_view(::RealValued) = Bonito.StylableSlider

function make_view(c::AbstractControl)
    return make_view(default_view(c), c)
end

# function make_view(Type{Bonito.NumberInput}, ::RealValued)
#
# end



