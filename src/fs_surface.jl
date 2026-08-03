# Functions for reading FreeSurfer brain surface meshes.

import Base.show

const TRIS_MAGIC_FILE_TYPE_NUMBER = 16777214

""" Models the header section of a file in FreeSurfer Surface format. The files are big endian. This header can usually be ignored. """
struct FsSurfaceHeader
    magic_b1::UInt8
    magic_b2::UInt8
    magic_b3::UInt8
    info_line::AbstractString
    num_vertices::Int32
    num_faces::Int32
end

""" Compute the number of vertices contained in an [`FsSurfaceHeader`](@ref) struct. """
num_vertices(sh::FsSurfaceHeader) = sh.num_vertices

""" Compute the number of faces contained in an [`FsSurfaceHeader`](@ref) struct. """
num_faces(sh::FsSurfaceHeader) = sh.num_faces


""" Models a trimesh. Vertices are defined by their xyz coordinates and contained in the `vertices` field as an `n*3` matrix, and faces are given as indices into the vertex array in the `faces` field. """
struct BrainMesh
    vertices::Array{Float32, 2}   # vertex xyz coords
    faces::Array{Int32, 2}        # indices of the 3 vertices forming the face / polygon / triangle
end

""" Compute the number of vertices contained in a [`BrainMesh`](@ref) struct. """
num_vertices(bm::BrainMesh) = Base.length(bm.vertices) / 3

""" Compute the number of faces contained in a [`BrainMesh`](@ref) struct. """
num_faces(bm::BrainMesh) = Base.length(bm.faces) / 3
Base.show(io::IO, x::BrainMesh) = @printf("Brain mesh with %d vertices and %d faces.\n", num_vertices(x), num_faces(x))

""" Models FreeSurfer Surface file. The `header` field is an [`FsSurfaceHeader`](@ref) struct that can usually be ignored, the `mesh` field is a [`BrainMesh`](@ref) struct. """
struct FsSurface
    header::FsSurfaceHeader
    mesh::BrainMesh
end

""" Compute the number of vertices contained in an [`FsSurface`](@ref) struct. """
num_vertices(fsf::FsSurface) = num_vertices(fsf.mesh)

""" Compute the number of faces contained in an [`FsSurface`](@ref) struct. """
num_faces(fsf::FsSurface) = num_faces(fsf.mesh)

Base.show(io::IO, x::FsSurface) = @printf("FreeSurfer brain mesh with %d vertices and %d faces.\n", num_vertices(x), num_faces(x))


""" Read header from a FreeSurfer brain surface file """
# For fixed length strings, we could do: my_line = bytestring(readbytes(fh, 4)) I guess.
function _read_surf_header(io::IO)
    header = FsSurfaceHeader(UInt8(hton(read(io, UInt8))), UInt8(hton(read(io, UInt8))), UInt8(hton(read(io, UInt8))),
                             read_variable_length_string(io),
                             Int32(hton(read(io, Int32))), Int32(hton(read(io, Int32))))
    magic = _interpret_fs_int24(header.magic_b1, header.magic_b2, header.magic_b3)
    if magic != TRIS_MAGIC_FILE_TYPE_NUMBER
        error("This is not a supported binary FreeSurfer Surface file: header magic code mismatch.")
    end
    header
end


"""
    read_surf(file::AbstractString)

Read a brain surface model represented as a mesh from a file in FreeSurfer binary surface format. Such a file typically represents a single hemisphere. Returns an [`FsSurface`](@ref) struct.

# Examples
```julia-repl
julia> surf_file = joinpath(tdd(), "subjects_dir/subject1/surf/lh.white");
julia> surf = read_surf(surf_file);
julia> Base.size(surf.mesh.faces, 1) # Get face count.
```
"""
function read_surf(file::AbstractString)
    file_io = open(file, "r")
    header = _read_surf_header(file_io)

    if header.num_vertices < 0
        error("Invalid surface file: num_vertices = $(header.num_vertices) (must be >= 0)")
    end
    if header.num_faces < 0
        error("Invalid surface file: num_faces = $(header.num_faces) (must be >= 0)")
    end
    _check_alloc(header.num_vertices, sizeof(Float32) * 3, "surface vertices ($(header.num_vertices) vertices × 3 coords)")
    _check_alloc(header.num_faces, sizeof(Int32) * 3, "surface faces ($(header.num_faces) faces × 3 indices)")
    vertices_raw = _read_vector_endian(file_io, Float32, Int64(header.num_vertices) * 3, endian="big")
    vertices::Array{Float32,2} = Base.reshape(vertices_raw, (3, Base.length(vertices_raw)÷3))'

    faces_raw = _read_vector_endian(file_io, Int32, Int64(header.num_faces) * 3, endian="big")
    faces::Array{Int32,2} = Base.reshape(faces_raw, (3, Base.length(faces_raw)÷3))'

    close(file_io)

    surface = FsSurface(header, BrainMesh(vertices, faces))
    surface
end


"""
    export_to_obj(file:: AbstractString, bm::BrainMesh)

Export a brain mesh to a Wavefront Object File.

Use [`read_surf`](@ref) to obtain a mesh to export. Exporting to the popular OBJ format is useful for loading the mesh in 3D modeling or visualization applications, like Blender3D.

# Examples
```julia-repl
julia> surf_file = joinpath(tdd(), "subjects_dir/subject1/surf/lh.white");
julia> surf = read_surf(surf_file);
julia> export_to_obj(tempname(), surf.mesh)
```
"""
function export_to_obj(file:: AbstractString, bm::BrainMesh)
    buffer::IOBuffer = IOBuffer()
    open(file, "w") do f
        for row_idx in 1:size(bm.vertices, 1)
            row = bm.vertices[row_idx, :]
            vertex_rep = @sprintf("v %f %f %f\n", row[1], row[2], row[3])
            print(buffer, vertex_rep)
        end
        for row_idx in 1:size(bm.faces, 1)
            row = bm.faces[row_idx, :]
            face_rep = @sprintf("f %d %d %d\n", row[1]+1, row[2]+1, row[3]+1)
            print(buffer, face_rep)
        end
        write(f, String(take!(buffer)))
    end
end


"""
    export_to_obj(file:: AbstractString, x::FsSurface)

Export the mesh of a FreeSurfer surface to a Wavefront Object File.

Use [`read_surf`](@ref) to obtain a mesh to export.

# Examples
```julia-repl
julia> surf_file = joinpath(tdd(), "subjects_dir/subject1/surf/lh.white");
julia> surf = read_surf(surf_file);
julia> export_to_obj(tempname(), surf)
```
"""
export_to_obj(file:: AbstractString, x::FsSurface) = export_to_obj(file, x.mesh)


"""
    write_surf(file::AbstractString, surf::FsSurface)

Write a brain surface mesh to a file in FreeSurfer binary surface format.

This is the inverse of [`read_surf`](@ref).  The output file will be compatible with
FreeSurfer tools that read binary surface files (e.g., `mris_convert`, `tksurfer`).

See also: [`read_surf`](@ref), [`export_to_obj`](@ref)

# Examples
```julia-repl
julia> surf_file = joinpath(tdd(), \"subjects_dir/subject1/surf/lh.white\");
julia> surf = read_surf(surf_file);
julia> write_surf(\"/tmp/lh.white\", surf);
```
"""
function write_surf(file::AbstractString, surf::FsSurface)
    file_io = open(file, "w")

    # Write magic bytes (TRIS_MAGIC_FILE_TYPE_NUMBER = 16777214 = 0xFFFFFE)
    write(file_io, ntoh(surf.header.magic_b1))
    write(file_io, ntoh(surf.header.magic_b2))
    write(file_io, ntoh(surf.header.magic_b3))

    # Write info line as raw bytes — no explicit null terminator needed:
    # the first 0x00 byte of the following big-endian Int32 serves as the
    # implicit null terminator that read_variable_length_string expects.
    info_bytes = Vector{UInt8}(surf.header.info_line)
    write(file_io, info_bytes)

    # Write vertex and face counts
    write(file_io, ntoh(surf.header.num_vertices))
    write(file_io, ntoh(surf.header.num_faces))

    # Write vertices (n × 3 Float32, row-major, big-endian)
    for row_idx in 1:size(surf.mesh.vertices, 1)
        for col_idx in 1:3
            write(file_io, ntoh(surf.mesh.vertices[row_idx, col_idx]))
        end
    end

    # Write faces (n × 3 Int32, row-major, big-endian, 0-based)
    for row_idx in 1:size(surf.mesh.faces, 1)
        for col_idx in 1:3
            write(file_io, ntoh(surf.mesh.faces[row_idx, col_idx]))
        end
    end

    close(file_io)
end

