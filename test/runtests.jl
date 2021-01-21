using NeuroFormats
using Test

import Base.length, Base.maximum, Base.minimum, Base.fieldcount

@testset "NeuroFormats.jl" begin
    
    #file = joinpath(dirname(@__FILE__), "test/data/subjects_dir/subject1/surf/lh.thickness")

    CURV_LH_THICKNESS_FILE = joinpath(dirname(@__FILE__), "data/subjects_dir/subject1/surf/lh.thickness")
    curv = readcurv(CURV_LH_THICKNESS_FILE, with_header = true)

    # Header
    #@test curv.header.magic == 16777215
    @test curv.header.num_vertices == 149244
    @test curv.header.num_faces == 298484
    @test curv.header.values_per_vertex == 1
  
    # Content
    @test length(curv.data) == 149244
    @assert minimum(curv.data) == 0.0
    @assert maximum(curv.data) == 5.0
end
