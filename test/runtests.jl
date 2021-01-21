using NeuroFormats
using Test

import Base.length, Base.maximum, Base.minimum, Base.fieldcount

# The easiest way to run these tests with the current version of your code
# seems to be the following one:
# - start a JULIA interpreter, then:
# - run: `using Pkg; Pkg.test("NeuroFormats");` 


""" Unit testing helper function to find test data dir.

    This is required because during tests, the base dir seems to be <package/test>, while it is <package> in the standard REPL.
"""
function get_testdata_dir()
    if isdir("data/subjects_dir")
        return joinpath(dirname(@__FILE__), "data/")
    elseif isdir("test/data/subjects_dir")
        return joinpath(dirname(@__FILE__), "test/data/")
    else
        error("Could not determine test data directory from current working directory.")
    end
    nothing
end


@testset "fs_curv.jl" begin
    
    CURV_LH_THICKNESS_FILE = joinpath(get_testdata_dir(), "subjects_dir/subject1/surf/lh.thickness")
    curv = readcurv(CURV_LH_THICKNESS_FILE, with_header = true)

    # Header
    @test curv.header.curv_magic_b1 == 0xff
    @test curv.header.curv_magic_b2 == 0xff
    @test curv.header.curv_magic_b3 == 0xff
    @test curv.header.num_vertices == 149244
    @test curv.header.num_faces == 298484
    @test curv.header.values_per_vertex == 1
  
    # Content
    @test length(curv.data) == 149244
    @assert minimum(curv.data) == 0.0
    @assert maximum(curv.data) == 5.0
end
