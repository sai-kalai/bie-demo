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


function make_view(x::RealInRange)

    slider = Bonito.StylableSlider(
        range(x |> minimum, x |> maximum; length=10);
        # value=x |> value,
    )

    # Browser -> Julia
    on(slider.value) do v
        setvalue!(x, v)
        # state[] == v || (state[] = v)
    end

    # Julia -> Browser
    on(observable(x)) do v
        slider.value[] == v || (slider.value[] = v)
    end

    # backend => frontend
    map!(slider.index, observable(x)) do v # here it probably is impossible to not give observer...
        # slider index gets updated whenever state changes
        idx = slider_value_index(slider.values[], v)
        @info "slider set to idx: " idx
        idx
    end

    return slider
end

function make_view(x::Choice)


    names = choices(x) |> collect

    @show chosen(x), names

    dropdown = Bonito.Dropdown(
        names;
        index=findfirst(==(chosen(x)), names),
        option_to_string=string,
    )

    # Browser -> Julia
    on(dropdown.value) do key
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



