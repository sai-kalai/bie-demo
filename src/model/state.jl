"""
Representation of the application state: the problem, solution, and algorithm
"""

# TODO: maybe rename simulation.jl

using DemoWebsite: get_t

struct SimulationState{P,A,S}
    _prob::Observable{P}
    _alg::Observable{A}
    _sol::Observable{S} # solution to a bvp, contains full information about prob and alg anyways...
end


function SimulationState(prob, alg, sol)
    return SimulationState(
        Observable(prob),
        Observable(alg),
        Observable(sol),
    )

end

# default constructor
function SimulationState()
    pb = make_prob(
        20,
        :Laplace,
        t->(sin(t), cos(t)),
        :Dirichlet,
        sin,
        :Interior,
    )

    alg = make_alg(:Indirect, 0.05)

    sol = make_sol(pb, alg)

    return SimulationState(
        pb,
        alg,
        sol,
    )
end

# factory methods that clients can overload and use
function make_prob(
    n::Int,
    pde::Symbol,
    bdry_f::Function,
    bc_type::Symbol,
    bc_f::Function,
    side::Symbol,
)

    equation = begin
        if pde === :Laplace
            Laplace()
        else
            error("not supported: $pde")
        end
    end

    domainside = begin
        if side === :Interior
            Interior()
        else
            error("not supported: $side")
        end
    end

    t = get_t(n)|>collect


    b = DiscreteClosedCurve(t, bdry_f)

    bc = begin
        if bc_type === :Dirichlet
            Dirichlet(bc_f.(t))
        elseif bc_type === :Neumann
            Neumann(bc_f.(t))
        else
            error("not supported: $bc_type")
        end
    end

    return BoundaryValueProblem(equation, bc, domainside, b)
end
function make_alg(approach::Symbol, delta::Real)
    if approach === :Indirect
        return IndirectBVPAlgorithm(evalmethod=DistancePolicy(delta)), IndirectBIEAlgorithm()
    end
    error("not supported: $approach")
end

# the concrete types must support solve(prob, alg) -> sol
# The solution must support observable plotting e.g. via Makie recipe
# in principle, different simulation software can be used.


# function solve(state)
#     return solve(state._prob[], state._alg[])
# end



# TODO: decouple from simulation backend


# function simulate(pb, alg, target)
#     return solve(pb, alg; target=target)
# end


function simulate!(state::SimulationState)
    sol = make_sol(
        state._prob[],
        state._alg[],
    )

    # update observable state

    state._sol[] = sol
    return nothing
end


# NOTE: singleton for now, optimize later
# Actually domain needs to grow... either keep largest or disallow domain changing
# size, this costs. but measure first how much actually. And also implement
# evaluation from generator to avoid bulk heap allocation
# target = nothing

function make_sol(prob, alg::Tuple) # NOTE: splatting for now, solve later upstream
    return solve(prob, alg...; target=make_target(prob))
end
function make_sol(prob, alg) # NOTE: splatting for now, solve later upstream
    return solve(prob, alg; target=make_target(prob))
end


function make_target(prob; n_grid=50)

    # global target

    # if !isnothing(target)
    # return target
    # end

    xmin, xmax, ymin, ymax = extrema(prob.boundary) # TODO remove this coupling, but need to include target in bvp definition upstream
    # TODO: dont define eval domain every time
    xs = range(xmin, xmax, length=n_grid)
    ys = range(ymin, ymax, length=n_grid)
    target = stack((x, y) for y in ys for x in xs)
    return target
end



