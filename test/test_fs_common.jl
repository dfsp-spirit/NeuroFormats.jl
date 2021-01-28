


@testset "fs_common.jl: read fs int24" begin
    
    CURV_LH_THICKNESS_FILE = joinpath(get_testdata_dir(), "subjects_dir/subject1/surf/lh.thickness")
    file_io = open(CURV_LH_THICKNESS_FILE, "r")
    int24 = NeuroFormats.FreeSurfer.read_fs_int24(file_io)
    close(file_io)

    @test int24 == 16777215
end


@testset "fs_common.jl: interpret fs int24" begin

    CURV_LH_THICKNESS_FILE = joinpath(get_testdata_dir(), "subjects_dir/subject1/surf/lh.thickness")
    curv = read_curv(CURV_LH_THICKNESS_FILE, with_header = true)
    
    int24 = NeuroFormats.FreeSurfer.interpret_fs_int24(curv.header.curv_magic_b1, curv.header.curv_magic_b2, curv.header.curv_magic_b3)
    
    @test int24 == 16777215
end


