module BaseBenchmarks

using BenchmarkTools
using JLD
using Compat

import Compat: UTF8String, view

BenchmarkTools.DEFAULT_PARAMETERS.seconds = 1.0
BenchmarkTools.DEFAULT_PARAMETERS.samples = 10000
BenchmarkTools.DEFAULT_PARAMETERS.time_tolerance = 0.15
BenchmarkTools.DEFAULT_PARAMETERS.memory_tolerance = 0.01

const PARAMS_PATH = joinpath(dirname(@__FILE__), "..", "etc", "params.jld")
const SUITE = BenchmarkGroup()
const MODULES = Dict("array" => :ArrayBenchmarks,
                     "broadcast" => :BroadcastBenchmarks,
                     "dates" => :DatesBenchmarks,
                     "io" => :IOBenchmarks,
                     "linalg" => :LinAlgBenchmarks,
                     "micro" => :MicroBenchmarks,
                     "misc" => :MiscellaneousBenchmarks,
                     "nullable" => :NullableBenchmarks,
                     "parallel" => :ParallelBenchmarks,
                     "problem" => :ProblemBenchmarks,
                     "random" => :RandomBenchmarks,
                     "scalar" => :ScalarBenchmarks,
                     "shootout" => :ShootoutBenchmarks,
                     "simd" => :SIMDBenchmarks,
                     "sort" => :SortBenchmarks,
                     "sparse" => :SparseBenchmarks,
                     "string" => :StringBenchmarks,
                     "tuple" => :TupleBenchmarks)

load!(id::AbstractString; kwargs...) = load!(SUITE, id; kwargs...)

function load!(group::BenchmarkGroup, id::AbstractString; tune::Bool = true)
    modsym = MODULES[id]
    modpath = joinpath(dirname(@__FILE__), id, "$(modsym).jl")
    eval(BaseBenchmarks, :(include($modpath)))
    modsuite = eval(BaseBenchmarks, modsym).SUITE
    group[id] = modsuite
    tune && jldopen(PARAMS_PATH, "r") do file
        JLD.exists(file, id) && loadparams!(modsuite, read(file, id), :evals)
    end
    return group
end

loadall!(; kwargs...) = loadall!(SUITE; kwargs...)

function loadall!(group::BenchmarkGroup; verbose::Bool = true, tune::Bool = true)
    for id in keys(MODULES)
        verbose && print("loading group $(repr(id))..."); tic();
        load!(group, id; tune = false)
        verbose && println("done (took $(toq()) seconds)")
    end
    if tune
        jldopen(PARAMS_PATH, "r") do file
            for (id, suite) in group
                JLD.exists(file, id) && loadparams!(suite, read(file, id), :evals)
            end
        end
    end
    return group
end

end # module
