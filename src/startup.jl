# logic that defines model and view state at startup of web application

function DefaultCard(content=DOM.div(); class_name)
    return Card(content; class=class_name)
end


function Controls(state::ApplicationState)

    controls = state.controls

    return make_view(controls)
end

function Controls(session::Bonito.Session)
    state = get_state(session)
    return Controls(state)
end

# should these be in view? should they take a session or a state?

function Dashboard(state::ApplicationState)
    # The plot that the frontend displays.


    plot = surface_plot(state.simulation; figsize=(1300, 760))

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
            href="https://github.com/sai-kalai/BoundaryIntegralPDE.jl",
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

"""
Definition of the logic to create a webapp and serve it

"""


