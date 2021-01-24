@testset "fs_surface.jl: read brain mesh" begin
        
    BRAIN_MESH_FILE = joinpath(get_testdata_dir(), "subjects_dir/subject1/surf/lh.tinysurface")
    surface = read_fs_surface(BRAIN_MESH_FILE)

    # Header
    #@test surface.header.num_vertices == 5

    # Content
    @test Base.ndims(surface.mesh.vertices) == 1
    @test Base.ndims(surface.mesh.faces) == 1
end