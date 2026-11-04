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


function Controls(callback::Function)
    # These are Observable objects, and their state belongs to the session.
    client_state = (;
        numpoints=(
            "Number of Boundary Nodes",
            Bonito.StylableSlider(40:10:100; value=40)
        ),
        bdryrotation=(
            "Rotation (rad)",
            Bonito.StylableSlider(0:0.1:2pi; value=0)
        ),
        bdrysize=(
            "Diameter",
            Bonito.StylableSlider(0.8:0.1:3.)
        ),
        bdryfreq=(
            "Number of Tips",
            Bonito.StylableSlider(2:10; value=5)
        ),
        bdryampl=(
            "Size of Tips",
            Bonito.StylableSlider(0.3:0.1:2)
        ),
        bcampl=(
            "Amplitude",
            Bonito.StylableSlider(-1:1)
        ),
        bcalpha=(
            "Spread",
            Bonito.StylableSlider(0.1:0.1:5; value=1.)
        ),
        bcomega=(
            "Frequency",
            Bonito.StylableSlider(-10:0.1:10)
        ),
        bcphase=(
            "Phase",
            Bonito.StylableSlider(0:0.1:2pi)
        ),
        bccenter=(
            "Center",
            Bonito.StylableSlider(0:(pi/8):2pi; value=4pi / 8)
        )
    )

    # Preserve the existing callback behavior.
    # TODO: investigate forany
    foreach(client_state) do (name, widget)
        on(widget.value) do value
            callback(client_state)
        end
    end

    return Grid(
        ((
            Bonito.Label(name),
            widget,
            Bonito.Label(widget.value)
        ) for (name, widget) in client_state)...;
        justify_content="begin",
        align_items="begin",
        class="dashboard-controls",
    )
end


"""
    Dashboard()

Construct the dashboard DOM.
"""
function Dashboard()
    # The plot that the frontend displays.
    plot = make_plot(80; figsize=(1300, 760))

    controls = Controls() do client_state
        client_state_cb!(client_state)
    end

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

function make_app()
    grid = Dashboard()

    # Load the external stylesheet as a Bonito asset.
    stylesheet = Bonito.Asset(
        joinpath(@__DIR__, "..", "assets", "styles.css")
    )

    return App() do
        DOM.div(
            stylesheet,
            DOM.div(grid; class="dashboard-root"),
        )
    end
end
