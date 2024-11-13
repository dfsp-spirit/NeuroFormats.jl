
@testset "utils.jl: read a fixed length string from a binary file" begin

    BRAIN_MESH_FILE = joinpath(Base.source_dir(), "data/subjects_dir/subject1/surf/lh.tinysurface")
    file_io = open(BRAIN_MESH_FILE, "r")

    @test Base.position(file_io) == 0

    b1 = read(file_io, UInt8)
    b2 = read(file_io, UInt8)
    b3 = read(file_io, UInt8)

    @test Base.position(file_io) == 3

    description = NeuroFormats.read_variable_length_string(file_io)
    @test description == "Created by anonymous on a perfect day.\n\n"

    @test Base.position(file_io) == (3 + Base.length(description))

    Base.seek(file_io, 3)
    description = NeuroFormats.read_variable_length_string(file_io, consume_zero = true)
    @test description == "Created by anonymous on a perfect day.\n\n"
    @test Base.position(file_io) == (3 + Base.length(description) + 1)

    close(file_io)
end