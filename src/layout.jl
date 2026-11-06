"""
    Dashboard layout definition

"""

"""
    DefaultCard(content=DOM.div(); class_name)

Create a dashboard container with a semantic CSS class.
"""
function DefaultCard(content=DOM.div(); class_name)
    return Card(content; class=class_name)
end

function get_t(n)
    range(0, 2π; length=n + 1)[1:(end-1)]
end

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

function Controls(state)

    return Grid(
        Bonito.Label("Boundary Geometry"),
        map(state.controls[:boundary].children) do node
            sldr = Bonito.StylableSlider(node.control.range; value=node.control.state[])

            map!(sldr.index, node.control.state) do v
                # slider index gets updated whenever state changes
                slider_value_index(sldr.values[], v)
            end

            on(sldr.value) do v
                node.control.state[] = v
                sync!(state)
            end


            return (
                Bonito.Label(node.control.info.label),
                sldr,
                Bonito.Label(node.control.state)
            )
        end...,
        Bonito.Label("Boundary Conditions"),
        map(state.controls[:bc].children) do node
            sldr = Bonito.StylableSlider(node.control.range; value=node.control.state[])

            map!(sldr.index, node.control.state) do v
                # slider index gets updated whenever state changes
                slider_value_index(sldr.values[], v)
            end

            # todo: is it possible to have the same observable and not have to define listeners?
            on(sldr.value) do v
                node.control.state[] = v
                sync!(state)
            end
            return (
                Bonito.Label(node.control.info.label),
                sldr,
                Bonito.Label(node.control.state)
            )
        end...,
        ;
        justify_content="begin",
        align_items="begin",
        class="dashboard-controls",
    )
end


"""
    Dashboard()

Construct the dashboard DOM.
makes plots from solution state and ui elements from control state.
"""
function Dashboard(state::State)
    # The plot that the frontend displays.

    plot = surface_plot(state; figsize=(1300, 760))

    controls = Controls(state)

    sidebar = DefaultCard(
        controls;
        class_name="dashboard-card dashboard-sidebar",
    )

    header = DefaultCard(
        "BoundaryIntegralEquations.jl live demo";
        class_name="dashboard-card dashboard-header",
    )

    main = DefaultCard(
        plot;
        class_name="dashboard-card dashboard-main",
    )

    footer = DefaultCard(
        DOM.a(
            "GitHub";
            href="https://github.com/sai-kalai/BoundaryIntegralEquations.jl",
        );
        class_name="dashboard-card dashboard-footer",
    )

    return Grid(
        sidebar,
        header,
        main,
        footer;
        columns="2fr 5fr",
        rows="1fr 10fr 1fr",
        areas="""
        'header header'
        'sidebar main'
        'footer footer';
        """,
        width="100%",
        height="100%",
        class="dashboard-grid",
    )
end

