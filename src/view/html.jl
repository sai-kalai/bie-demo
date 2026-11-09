# Definition of how the HTML representation of control elements

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

    names = keys(x) |> collect

    @info names

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
    variant_view = map(observable(x)) do _
        make_view(value(x))
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


floatformat(v) = @sprintf("%.2f", v)
intformat(v) = @sprintf("%d", v)

# NOTE: this seems tedious to define individually, but may be the correct choice
# TODO: find a better abstraction for defining formatting
function make_view(x::Model.Starfish)
    return Bonito.DOM.div(
        Bonito.Label("Size"),
        make_view(x.R; length=100, format=floatformat),
        Bonito.Label("Rotation"),
        make_view(x.t0; length=100, format=floatformat), # make default be inferred from dtype of RealInRange
        Bonito.Label("Number of Tips"),
        make_view(x.w; step=1, format=intformat),
        Bonito.Label("Size of Tips"),
        make_view(x.a; length=100, format=floatformat),
    )
end

function make_view(x::Model.Circle)
    return Bonito.DOM.div(
        Bonito.Label("Size"),
        make_view(x.R; length=100, format=floatformat),
    )
end

function make_view(x::Model.Bump)
    return Bonito.DOM.div(
        Bonito.Label("Amplitude"),
        make_view(x.A; length=100, format=floatformat),
        Bonito.Label("Spread"),
        make_view(x.α; length=100, format=floatformat),
        Bonito.Label("Center"),
        make_view(x.μ; length=100, format=floatformat),
    )
end

function make_view(x::Model.Sinusoidal)
    return Bonito.DOM.div(
        Bonito.Label("Amplitude"),
        make_view(x.A; length=100, format=floatformat),
        Bonito.Label("Frequency"),
        make_view(x.ω; length=100, format=floatformat),
        Bonito.Label("Phase"),
        make_view(x.ϕ; length=100, format=floatformat),
    )
end

function make_view(x::Model.WavePacket)
    return Bonito.DOM.div(
        Bonito.Label("Amplitude"),
        make_view(x.A; length=100, format=floatformat),
        Bonito.Label("Spread"),
        make_view(x.α; length=100, format=floatformat),
        Bonito.Label("Center"),
        make_view(x.μ; length=100, format=floatformat),
        Bonito.Label("Frequency"),
        make_view(x.ω; length=100, format=floatformat),
        Bonito.Label("Phase"),
        make_view(x.ϕ; length=100, format=floatformat),
    )
end

