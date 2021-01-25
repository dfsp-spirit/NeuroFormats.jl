# Functions for reading FreeSurfer brain surface meshes.


const TRIS_MAGIC_FILE_TYPE_NUMBER = 16777214

""" Models the header section of a file in FreeSurfer Surface format. The files are big endian. """
mutable struct FsSurfaceHeader
    magic_b1::UInt8
    magic_b2::UInt8
    magic_b3::UInt8
    info_line::AbstractString
    num_vertices::Int32
    num_faces::Int32
end

num_vertices(sh::FsSurfaceHeader) = sh.num_vertices
num_faces(sh::FsSurfaceHeader) = sh.num_faces


""" Models a trimesh. Vertices are defined by their xyz coordinates, and faces are given as indices into the vertex array. """
struct BrainMesh
    vertices::Array{Float32, 1}   # vertex xyz coords
    faces::Array{Int32, 1}        # indices of the 3 vertices forming the face / polygon / triangle
end

num_vertices(bm::BrainMesh) = Base.length(bm.vertices) / 3
num_faces(bm::BrainMesh) = Base.length(bm.faces) / 3


""" Models FreeSurfer Surface file. """
struct FsSurface
    header::FsSurfaceHeader
    mesh::BrainMesh
end

num_vertices(fsf::FsSurface) = num_vertices(fsf.mesh)
num_faces(fsf::FsSurface) = num_faces(fsf.mesh)


""" Read header from a FreeSurfer brain surface file """
# For fixed length strings, we could do: my_line = bytestring(readbytes(fh, 4)) I guess.
function read_fs_surface_header(io::IO)
    header = FsSurfaceHeader(UInt8(hton(read(io, UInt8))), UInt8(hton(read(io, UInt8))), UInt8(hton(read(io, UInt8))),
                             read_variable_length_string(io),
                             Int32(hton(read(io, Int32))), Int32(hton(read(io, Int32))))
    magic = interpret_fs_int24(header.magic_b1, header.magic_b2, header.magic_b3)
    if magic != TRIS_MAGIC_FILE_TYPE_NUMBER
        error("This is not a supported binary FreeSurfer Surface file: header magic code mismatch.")
    end
    header
end


""" 
    read_fs_surface(file::AbstractString)

Read a brain surface model represented as a mesh from a file in FreeSurfer binary surface format. Such a file typically represents a single hemisphere.

# Examples
```julia-repl
julia> mesh = read_fs_surface("~/study1/subject1/surf/lh.white")
```
"""
function read_fs_surface(file::AbstractString)
    file_io = open(file, "r")
    header = read_fs_surface_header(file_io)

    @printf("Reading %d vertices and %d faces at current position %d.\n", header.num_vertices, header.num_faces, Base.position(file_io))
    
    vertices::Array{Float32,1} = reinterpret(Float32, read(file_io, sizeof(Float32) * header.num_vertices * 3))
    vertices .= ntoh.(vertices)

    faces::Array{Int32} = reinterpret(Int32, read(file_io, sizeof(Int32) * header.num_faces * 3))
    faces .= ntoh.(faces)

    close(file_io)

    surface = FsSurface(header, BrainMesh(vertices, faces))
    surface 
end


""" Export a brain mesh to a Wavefront Object File. """
function export_to_obj(file:: AbstractString, bm::BrainMesh)
    open(file, "w") do f
        for row in eachrow(bm.vertices)
            write(f, "v ", row[1], " ", row[2], " ", row[3], "\n")
        end
        for row in eachrow(bm.faces)
            write(f, "f ", row[1], " ", row[2], " ", row[3], "\n")
        end
    end
end

