

@testset "fs_curv.jl: read curv with header" begin

CURV_LH_THICKNESS_FILE = joinpath(Base.source_dir(), "data/subjects_dir/subject1/surf/lh.thickness")
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

CURV_LH_THICKNESS_FILE = joinpath(Base.source_dir(), "data/subjects_dir/subject1/surf/lh.thickness")
curv_data = read_curv(CURV_LH_THICKNESS_FILE, with_header = false)

# Content
@test length(curv_data) == 149244
@test minimum(curv_data) == 0.0
@test maximum(curv_data) == 5.0
end


@testset "fs_curv.jl: write and re-read curv file" begin

CURV_LH_THICKNESS_FILE = joinpath(Base.source_dir(), "data/subjects_dir/subject1/surf/lh.thickness")
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


