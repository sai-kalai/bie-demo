# Definition of how the HTML representation of control elements
#
using Printf

function make_view(c::ControlState)

    return Grid(
        Bonito.Label("Number of Boundary Nodes"),
        make_view(c.numpoints; step=10),
        Bonito.Label("Boundary Geometry"),
        make_view(c.boundaryshape),
        Bonito.Label("Boundary Conditions"),
        make_view(c.bcshape)
        ;
        justify_content="begin",
        align_items="begin",
        class="dashboard-controls",
    )
end


# TODO: if the max/min properties are updated, that is also observed
function make_view(x::RealInRange; step=nothing, length=nothing, format=nothing)
    if isnothing(format)
        format = string
    end

    slider = Bonito.StylableSlider(
        range(x |> minimum, x |> maximum; step=step, length=length),
    )

    # Browser -> Julia
    on(slider.value) do v
        setvalue!(x, v)
    end

    slider[] = value(x)

    # getindex assign works
    on(observable(x);) do _
        slider[] = value(x)
    end

    # probably better to label with slider value instead of source of truth to
    # avoid one ws message.
    # also, displaying client side value remains functional if connection is lost
    return Bonito.Labeled(slider, map(format, slider.value)) # value is also an observable
end

function make_view(x::Choice)

    names = choices(x) |> collect

    dropdown = Bonito.Dropdown(
        names;
        index=findfirst(==(chosen(x)), names),
        option_to_string=string,
    )

    # Browser -> Julia
    on(dropdown.value) do key
        # equal check may be redundant if put in model but might be better to save network cost
        chosen(x) == key || setchosen!(x, key)
    end

    # Julia -> Browser
    on(observable(x)) do key
        dropdown.value[] == key || (dropdown.value[] = key)
    end

    # The selected variant determines which controls are displayed.
    variant_view = map(x._value) do key
        make_view(x._choices[key])
    end

    return Bonito.DOM.div(
        dropdown,
        variant_view;
        style=Bonito.Styles(
            "display" => "flex",
            "flex-direction" => "column",
            "gap" => "10px",
        ),
    )
end

function make_view(x::Union{Model.BCShape,Model.BoundaryShape})

    return Grid(
        map(make_view, observable(x))
    )

end

# function make_view(Type{Bonito.NumberInput}, ::RealValued)
#
# end



