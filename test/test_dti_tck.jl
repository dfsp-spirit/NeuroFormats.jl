# Tests for reading TCK files.

@testset "Read DTI tracks from a MRtrix3 TCK file." begin

    TCK_FILE = joinpath(Base.source_dir(), "data/DTI/simple_big_endian.tck")
    tck = read_tck(TCK_FILE)

    # test header
    @test typeof(tck.header["file"]) == String
    @test tck.header["file"] == ". 67"
    @test tck.header["datatype"] == "Float32BE"
    @test tck.header["count"] == "0000000003"

    # test data
    @test Base.length(tck.tracks) == 3
end

