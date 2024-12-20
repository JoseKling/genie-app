module App

using GenieFramework
@genietools

include("hypothesis-testing.jl")
include("frequency-analysis.jl")

@page("/", "index.html")
end
