# Tests for reading TRK files.

@testset "Read DTI tracks from a DiffusionToolkit TRK file." begin

    TRK_FILE = joinpath(Base.source_dir(), "data/DTI/complex_big_endian.trk")
    trk = read_trk(TRK_FILE)

    @test trk.header.hdr_size == 1000
    @test Base.length(trk.tracks) == 3
    @test Base.length(trk.tracks[1].track_properties) == 5
end

