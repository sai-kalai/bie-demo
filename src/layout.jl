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

function Controls(state::State)

    controls = state.controls

    return make_view(controls)
end

function Controls(session::Session)
    state = get_state(session)
    return Controls(state)
end

function Dashboard(session::Session)
    state = get_state(session)
    Dashboard(state)
end

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

