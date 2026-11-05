# Definition of the surface plot

function surface_plot(state; figsize=(200, 400))

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

