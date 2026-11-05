

using Revise
using Bonito
using WGLMakie
using Observables

using BoundaryIntegralPDE
using BoundaryIntegralPDE.DevTools

using DemoWebsite


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


function make_plot(state; figsize=(200, 400))

    fig = Figure(; size=figsize)
    # ax = Axis(fig[1, 1]; aspect=AxisAspect(1), tellheight=true)
    ax = Axis3(fig[1, 1])


    tcf = surface!(ax, state.sol)

    @info tcf

    # Colorbar(
    #     fig[1, 1][1, 2],
    #     limits=@lift(extrema($state.sol.u[.!isnan.($state.sol.u)])),
    #     label="Electrostatic Potential",
    # )

    ax2 = Axis(fig[2, 1];
        limits=(nothing, (-1, 1)),
        xticks=MultiplesTicks(6, pi, "π"),
        xlabel="Parameter t",
        ylabel="Boundary Condition",
        tellwidth=false,
    )

    lns = lines!(ax2,
        @lift(get_t($(state.sol).prob.bc |> data |> length)),
        @lift($(state.sol).prob.bc |> data)
    )

    @info "done plotting"
    rowsize!(fig.layout, 2, Auto(0.2))

    return WGLMakie.WithConfig(fig; resize_to=:parent)
end



function _get(s, p)
    getproperty(s, p)[2].value[]
end

# modify the application state by reading the client state
function client_state_cb!(state, s)

    # recompute solution
    sol = sol_from_client_state(s)

    # set the observable state to the new simulation solution
    state.sol[] = sol

    return nothing
end



