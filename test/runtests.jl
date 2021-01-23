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


@testset "fs_curv.jl: read curv with header" begin
    
    CURV_LH_THICKNESS_FILE = joinpath(get_testdata_dir(), "subjects_dir/subject1/surf/lh.thickness")
    curv = read_curv(CURV_LH_THICKNESS_FILE, with_header = true)

    # Header
    @test curv.header.curv_magic_b1 == 0xff
    @test curv.header.curv_magic_b2 == 0xff
    @test curv.header.curv_magic_b3 == 0xff
    @test curv.header.num_vertices == 149244
    @test curv.header.num_faces == 298484
    @test curv.header.values_per_vertex == 1
  
    # Content
    @test length(curv.data) == 149244
    @test minimum(curv.data) == 0.0
    @test maximum(curv.data) == 5.0
end
 

@testset "fs_curv.jl: read curv without header" begin
    
    CURV_LH_THICKNESS_FILE = joinpath(get_testdata_dir(), "subjects_dir/subject1/surf/lh.thickness")
    curv_data = read_curv(CURV_LH_THICKNESS_FILE, with_header = false)
  
    # Content
    @test length(curv_data) == 149244
    @test minimum(curv_data) == 0.0
    @test maximum(curv_data) == 5.0
end


@testset "fs_curv.jl: write and re-read curv file" begin
    
    CURV_LH_THICKNESS_FILE = joinpath(get_testdata_dir(), "subjects_dir/subject1/surf/lh.thickness")
    curv_data = read_curv(CURV_LH_THICKNESS_FILE, with_header = false)

    # Write and re-read
    tf = tempname()
    write_curv(tf, curv_data)
    curv_re = read_curv(tf, with_header = true) 

    # Header
    @test curv_re.header.curv_magic_b1 == 0xff
    @test curv_re.header.curv_magic_b2 == 0xff
    @test curv_re.header.curv_magic_b3 == 0xff
    @test curv_re.header.num_vertices == 149244
    @test curv_re.header.values_per_vertex == 1
  
    # Content
    @test length(curv_re.data) == length(curv_data)
    @test minimum(curv_re.data) == minimum(curv_data)
    @test maximum(curv_re.data) == maximum(curv_data)
    @test curv_re.data == curv_data
end


@testset "fs_common.jl: read fs int24" begin
    
    CURV_LH_THICKNESS_FILE = joinpath(get_testdata_dir(), "subjects_dir/subject1/surf/lh.thickness")
    file_io = open(CURV_LH_THICKNESS_FILE, "r")
    int24 = read_fs_int24(file_io)
    close(file_io)

    @test int24 == 16777215
end


