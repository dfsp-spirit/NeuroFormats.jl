# Tests for reading TCK files.

@testset "Read DTI tracks from a MRtrix3 TCK file." begin
    
    TCK_FILE = joinpath(get_testdata_dir(), "DTI/simple_big_endian.tck")
    tck = read_tck(TCK_FILE)

    @test typeof(tck.header["file"]) == String
end

