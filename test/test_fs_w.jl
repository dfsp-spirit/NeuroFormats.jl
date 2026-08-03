# Tests for reading and writing FreeSurfer W (paint) files.

@testset "Write and re-read a FreeSurfer W file (roundtrip)" begin

    # Create synthetic W data with 50 vertices
    num_vertices = 50
    w_data_orig = Int32.(mod.(1:num_vertices, 5))  # labels 1,2,3,4,0 cycling

    # Write to temp file
    tf = string(tempname(), ".w")
    write_w(tf, w_data_orig)
    @test Base.isfile(tf)

    # Read back raw data
    w_data_read = read_w(tf)
    @test w_data_read == w_data_orig

    # Read back with header
    wf = read_w(tf, with_header=true)
    @test wf.header.num_vertices == num_vertices
    @test wf.header.num_faces == 0
    @test wf.header.values_per_vertex == 1
    @test wf.data == w_data_orig
    @test wf.header.w_magic_b1 == 0xff
    @test wf.header.w_magic_b2 == 0xff
    @test wf.header.w_magic_b3 == 0xff
end

@testset "Read W file with zero vertices" begin

    tf = string(tempname(), ".w")
    write_w(tf, Int32[])
    @test Base.isfile(tf)

    w_data_read = read_w(tf)
    @test w_data_read == Int32[]
end

@testset "Write W file with various integer types" begin

    tf = string(tempname(), ".w")
    write_w(tf, Int16[10, 20, 30])
    w_data_read = read_w(tf)
    @test w_data_read == Int32[10, 20, 30]
end
