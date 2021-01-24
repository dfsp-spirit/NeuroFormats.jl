@testset "fs_surface.jl: read brain mesh" begin
        
    BRAIN_MESH_FILE = joinpath(get_testdata_dir(), "subjects_dir/subject1/surf/lh.tinysurface")
    surface = read_fs_surface(BRAIN_MESH_FILE) # a mesh with 5 vertices and 3 faces.

    # Header
    @test num_vertices(surface.header) == 5
    @test num_faces(surface.header) == 3

    # Content
    @test Base.ndims(surface.mesh.vertices) == 1
    @test Base.length(surface.mesh.vertices) == 5 * 3
    @test Base.ndims(surface.mesh.faces) == 1
    @test Base.length(surface.mesh.faces) == 3 * 3
end