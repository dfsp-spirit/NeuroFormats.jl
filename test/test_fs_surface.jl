
@testset "fs_surface.jl: read brain mesh" begin

    BRAIN_MESH_FILE = joinpath(Base.source_dir(), "data/subjects_dir/subject1/surf/lh.tinysurface")
    surface = read_surf(BRAIN_MESH_FILE) # a mesh with 5 vertices and 3 faces.

    known_num_verts = 5
    known_num_faces = 3

    # Header
    @test num_vertices(surface.header) == known_num_verts
    @test num_faces(surface.header) == known_num_faces

    # Content
    @test Base.ndims(surface.mesh.vertices) == 2
    @test Base.length(surface.mesh.vertices) == known_num_verts * 3
    @test Base.ndims(surface.mesh.faces) == 2
    @test Base.length(surface.mesh.faces) == known_num_faces * 3

    # Data, checks for row-major versus column-major issue
    @test surface.mesh.faces[1,:] == Array{Int32,1}([0,1,3])
    @test surface.mesh.faces[2,:] == Array{Int32,1}([1,3,4])
    @test surface.mesh.faces[3,:] == Array{Int32,1}([2,2,2])
end


@testset "fs_surface.jl: export brain mesh to OBJ file" begin

    BRAIN_MESH_FILE = joinpath(Base.source_dir(), "data/subjects_dir/subject1/surf/lh.tinysurface")
    surface = read_surf(BRAIN_MESH_FILE) # a mesh with 5 vertices and 3 faces.

    tf = tempname()
    export_to_obj(tf, surface.mesh)

    # Basic test: check file only.
    @test Base.isfile(tf) == true
    fs = open(tf, "r")
    @test Base.length(readlines(fs)) == 5 + 3
end


@testset "fs_surface.jl: write and re-read brain mesh (roundtrip)" begin

    BRAIN_MESH_FILE = joinpath(Base.source_dir(), "data/subjects_dir/subject1/surf/lh.tinysurface")
    surface_orig = read_surf(BRAIN_MESH_FILE)

    tf = string(tempname(), ".surf")
    write_surf(tf, surface_orig)
    @test Base.isfile(tf)

    surface_read = read_surf(tf)

    # Compare header fields
    @test surface_read.header.num_vertices == surface_orig.header.num_vertices
    @test surface_read.header.num_faces == surface_orig.header.num_faces

    # Compare mesh data
    @test surface_read.mesh.vertices == surface_orig.mesh.vertices
    @test surface_read.mesh.faces == surface_orig.mesh.faces
end
