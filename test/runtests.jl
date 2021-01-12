using NeuroFormats
using Test

@testset "NeuroFormats.jl" begin
    
    CURV_LH_THICKNESS_FILE = joinpath(dirname(@__FILE__), "data/subjects_dir/subject1/surf/lh.thickness")
    curv = readcurv(CURV_LH_THICKNESS_FILE)

    # Header
    @test length(curv.header) == 4
  
    # Content
    @test flength(curv.data) == 149000
    @assert maximum(curv.data) == 5.5
end
