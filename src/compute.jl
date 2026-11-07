# Definition of the algorithms that obtain numerical solutions

function simulate(pb; n_grid=50)
    @info "simulate boundary = $(pb.boundary.x|>summary)"
    xmin, xmax, ymin, ymax = extrema(pb.boundary)

    xs = range(xmin, xmax, length=n_grid)
    ys = range(ymin, ymax, length=n_grid)
    x_test = stack((x, y) for y in ys for x in xs)
    # x_test = Fixtures.test_locations()

    @info pb

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




