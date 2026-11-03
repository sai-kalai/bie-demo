

using Revise
using Bonito
using WGLMakie
using Observables
using Profile
using ProfileView

using BoundaryIntegralEquations
using BoundaryIntegralEquations.DevTools



WGLMakie.activate!(; resize_to=:parent)


"""
    DefaultCard(content=DOM.div(), style=Styles(), attributes...)

create a generic card element
"""
function DefaultCard(
    content=DOM.div();
    style=Styles(),
    attributes...
)
    return Card(
        content;
        backgroundcolor=:silver,
        border_radius="2px",
        margin="0px",
        style=Styles(
            style,
            "color" => :white,
            "min-height" => "0",
            "min-width" => "0",
            "width" => "100%",
            "height" => "100%",
            "box-sizing" => "border-box",
            # "overflow" => "hidden",
        ),
        attributes...
    )
end

function Controls(callback::Function)

    # These are `Observable` objects, and their state belongs to `session`
    # ddwn = Dropdown(["a", "b", "c"])
    # ninp = NumberInput(10.0)
    # tinp = Bonito.TextField("helo")
    client_state = (;
        # hotreload=(
        #     "Hot Reload",
        #     Bonito.Checkbox(false)
        # ),
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
            Bonito.StylableSlider(0:(pi/8):2pi; value=4pi / 8))
    )

    # on(bttn.value) do clicked # registers a Julia-side event handler.
    #     simulate_cb(round(Int, sldr.value[]))
    # end
    # on(sldr.value) do v
    #     simulate_cb(round(Int, sldr.value[]))
    # end

    foreach(client_state) do (name, widget)
        on(widget.value) do v
            callback(client_state)
        end

    end

    grid = Grid(
        # bttn, Bonito.Label(clicks), # will be updated with `clicks`
        # sldr, Bonito.Label(sldr.value),
        # ddwn, Bonito.Label(ddwn.value),
        # ninp, Bonito.Label(ninp.value),
        # tinp, Bonito.Label(tinp.value)
        ((
            Bonito.Label(name),
            widget,
            Bonito.Label(widget.value)
            # columns="2fr min-content",
        )
         for (name, widget) in client_state)...
        ;
        # columns="2fr min-content",
        justify_content="begin",
        align_items="begin",
    )

    return grid

end

function get_t(n)
    range(0, 2π; length=n + 1)[1:(end-1)]
end

function setup(n)

    @info "setup n=$n"

    t = get_t(n)

    b = DiscreteClosedCurve(t, starfish)

    f = 10

    bc = Dirichlet(sin.(f .* t))

    pb = BoundaryValueProblem(Laplace(), bc, Interior(), b)

    return t, pb
end


function simulate(pb; n_grid=50)
    @info "simulate boundary = $(pb.boundary.x|>summary)"
    xmin, xmax, ymin, ymax = extrema(pb.boundary)

    xs = range(xmin, xmax, length=n_grid)
    ys = range(ymin, ymax, length=n_grid)
    x_test = stack((x, y) for y in ys for x in xs)
    # x_test = Fixtures.test_locations()

    sol = solve(
        pb,
        IndirectBVPAlgorithm(evalmethod=CauchyIntegral()),
        IndirectBIEAlgorithm(),
        ;
        target=x_test,
    )

    # update observable state


    return xs, ys, sol
end

mutable struct State
    pb
    sol
end

function make_plot(n; figsize=(200, 400))

    @info "making plot n=$n"

    @time begin
        t, pb = setup(n)
        xs, ys, sol = simulate(pb) # this sol needs to be an observable
    end

    @info "done simulating"

    global state
    state = Observable(State(pb, sol))

    @info "plotting"
    @time begin

        fig = Figure(; size=figsize)
        ax = Axis(fig[1, 1]; aspect=AxisAspect(1), tellheight=true)
        boundarycurve!(ax, @lift($state.pb.boundary))

        tcf = tricontourf!(ax, @lift $state.sol)

        @show extrema(state[].sol.u)
        @show tcf.colorrange[]

        Colorbar(
            fig[1, 1][1, 2],
            limits=@lift(extrema($state.sol.u[.!isnan.($state.sol.u)])),
            label="Electrostatic Potential",
        )


        ax2 = Axis(fig[2, 1];
            limits=(nothing, (-1, 1)),
            xticks=MultiplesTicks(6, pi, "π"),
            xlabel="Parameter t",
            ylabel="Boundary Condition",
            tellwidth=false,
        )
        lns = lines!(ax2,
            @lift(get_t($state.pb.bc |> data |> length)),
            @lift($state.pb.bc |> data)
        )

    end
    @info "done plotting"
    rowsize!(fig.layout, 2, Auto(0.2))

    @info fig, ax
    return fig
end

function numpoints_cb!(n::Int)
    @info "callback n=$n"
    t, pb = setup(n)
    xs, ys, sol = simulate(pb)
    global state
    state[] = State(pb, sol)
    @info extrema(sol.u[.!isnan.(sol.u)])
    notify(state)
    return nothing
end


function _get(s, p)
    getproperty(s, p)[2].value[]
end

function client_state_cb!(s)

    # numpoints_cb!(round(Int, client_state.numpoints[2].value[]))


    # t = range(0, 2π; length=_get(s, :numpoints) + 1)[1:(end-1)]

    t = get_t(_get(s, :numpoints))

    b = DiscreteClosedCurve(t, (t) -> starfish(
        t;
        t0=_get(s, :bdryrotation),
        R=_get(s, :bdrysize),
        a=_get(s, :bdryampl),
        w=_get(s, :bdryfreq),
    ))


    bc_fn = (t) -> begin
        A = _get(s, :bcampl)
        α = _get(s, :bcalpha)
        ω = _get(s, :bcomega)
        ϕ = _get(s, :bcphase)
        μ = _get(s, :bccenter)

        return (A / (α * sqrt(2pi))) * exp(-(t - μ)^2 / (2α^2)) * sin(ω * t + ϕ)
    end

    bc = Dirichlet(
        bc_fn.(t)
    )

    pb = BoundaryValueProblem(Laplace(), bc, Interior(), b)

    xs, ys, sol = simulate(pb)
    global state
    state[] = State(pb, sol)
    @info extrema(sol.u[.!isnan.(sol.u)])
    notify(state)

    return nothing
end

"""
    Dashboard()

create a dashboard app

"""
function Dashboard()

    # The plot that the frontend displays
    plot = make_plot(80; figsize=(1300, 760))

    controls = Controls() do client_state # this is the callback passed to Controls
        client_state_cb!(client_state)
    end

    sidebar = DefaultCard(
        controls,
        style=Styles("overflow-y" => "scroll", "grid-area" => "sidebar",)
    )

    header = DefaultCard(
        "BoundaryIntegralEquations.jl live demo",
        style=Styles("grid-area" => "header")
    )

    main = DefaultCard(
        plot
        ;
        style=Styles("grid-area" => "main"),
        width="69px",
    )

    footer = DefaultCard(
        DOM.a("GitHub"; href="https://github.com/sai-kalai/BoundaryIntegralEquations.jl"),
        style=Styles("grid-area" => "footer")
    )

    grid_style = Styles(
        CSS(
            "height" => "100vh",
            "width" => "100%",
            "box-sizing" => "border-box",
            "margin" => "8",
            "padding" => "8",
            "position" => :relative,
            "overflow" => "hidden",
        ),
    )

    grid = Grid(
        sidebar, header, main, footer,
        columns="2fr 5fr",
        rows="1fr 10fr 1fr",
        areas="""
'header header'
'sidebar main'
'footer footer';
""",
        width="100%",
        height="100%",
        style=grid_style,
    )

    return grid
end

function start_server(app)
    server = Server(app, "0.0.0.0", 8080)
    route!(server, "/" => app)
    return server
end

function make_app()
    grid = Dashboard()

    global_style = Styles(
        CSS("body", "margin" => "0", "padding" => "0",))

    app = App() do
        return DOM.div(
            global_style,
            DOM.div(grid
                ;
                style=Styles(
                    "width" => "100%",
                    "height" => "100vh",
                    "overflow" => "hidden",
                )
            )
        )
    end

    return app
end

function main()
    app = make_app()
    server = start_server(app)
end


function prof_main()
    @profview begin
        main()
    end
end

