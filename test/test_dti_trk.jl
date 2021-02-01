# Tests for reading TRK files.

@testset "Read DTI tracks from a DiffusionToolkit TRK file." begin
    
    TRK_FILE = joinpath(get_testdata_dir(), "DTI/complex_big_endian.trk")
    trk = read_trk(TRK_FILE)

    @test trk.header.hdr_size == 1000
end

