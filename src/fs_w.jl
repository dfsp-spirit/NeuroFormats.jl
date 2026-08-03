# Functions for reading and writing FreeSurfer W files (paint / label files).
#
# W files store per-vertex integer labels for a brain surface mesh, e.g., cluster
# memberships or parcellation labels.  The binary format is identical to Curv except
# the data values are Int32 instead of Float32.

import Base.show

""" Models the header section of a file in FreeSurfer W (paint) format. """
struct WHeader
    w_magic_b1::UInt8
    w_magic_b2::UInt8
    w_magic_b3::UInt8
    num_vertices::Int32
    num_faces::Int32       # always 0 for W files
    values_per_vertex::Int32  # always 1 for W files
end


""" Models a FreeSurfer W (paint) file.  The `header` field contains a [`WHeader`](@ref),
the `data` field is an Int32 vector of per-vertex integer labels.  The values appear in
the same order as the vertices in the corresponding brain mesh (surf) file. """
struct WFile
    header::WHeader
    data::Array{Int32, 1}
end

Base.show(io::IO, x::WFile) = @printf("FreeSurfer per-vertex paint data for %d vertices.\n", Base.length(x.data))

const W_MAGIC_HDR = 16777215  # 0xFFFFFF, same as Curv


""" Read header from a W file. """
function _read_w_header(io::IO)
    header = WHeader(
        UInt8(hton(read(io, UInt8))),
        UInt8(hton(read(io, UInt8))),
        UInt8(hton(read(io, UInt8))),
        hton(read(io, Int32)),
        hton(read(io, Int32)),
        hton(read(io, Int32)),
    )
    if !(header.w_magic_b1 == 0xff && header.w_magic_b2 == 0xff && header.w_magic_b3 == 0xff)
        error("This is not a binary FreeSurfer W file: header magic code mismatch.")
    end
    header
end


"""
    read_w(file::AbstractString; with_header::Bool=false)

Read per-vertex integer paint data from the W file `file`.  The file must be in
FreeSurfer binary W (paint) format, like `lh.cortex.paint`.  Returns an
`Array{Int32,1}` with the data unless `with_header` is set, in which case a
[`WFile`](@ref) struct is returned instead.

W files store integer labels (e.g., cluster IDs, brain region indices) for each vertex
of a brain surface mesh.  The format is identical to the FreeSurfer Curv format except
that values are 32-bit signed integers instead of 32-bit floats.

See also: [`write_w`](@ref), [`read_curv`](@ref)

# Examples
```julia-repl
julia> w_data = read_w("/path/to/lh.cortex.paint");
julia> unique(w_data)        # show distinct labels
julia> count(x -> x == 1, w_data)  # count vertices with label 1
```
"""
function read_w(file::AbstractString; with_header::Bool=false)
    file_io = open(file, "r")
    header = _read_w_header(file_io)

    if header.num_vertices < 0
        error("Invalid W file: num_vertices = $(header.num_vertices) (must be >= 0)")
    end
    _check_alloc(header.num_vertices, sizeof(Int32), "W file per-vertex data ($(header.num_vertices) vertices)")
    per_vertex_data = _read_vector_endian(file_io, Int32, header.num_vertices, endian="big")

    close(file_io)

    if with_header
        wf = WFile(header, per_vertex_data)
        return wf
    else
        return per_vertex_data
    end
end


"""
    write_w(file::AbstractString, w_data::Vector{<:Integer})

Write an integer vector to a binary file in FreeSurfer W (paint) format.  The data
will be converted to `Int32`.

This function is typically used to write per-vertex integer labels for a brain mesh,
such as cluster memberships or parcellation results.

See also: [`read_w`](@ref)

# Examples
```julia-repl
julia> write_w("~/study1/subject1/surf/lh.myclusters.paint", Int32[1, 1, 2, 3, 3])
```
"""
function write_w(file::AbstractString, w_data::Vector{<:Integer})
    w_data = convert(Vector{Int32}, w_data)
    header = WHeader(0xff, 0xff, 0xff, length(w_data), 0, 1)
    file_io = open(file, "w")

    # Write header
    write(file_io, ntoh(header.w_magic_b1))
    write(file_io, ntoh(header.w_magic_b2))
    write(file_io, ntoh(header.w_magic_b3))
    write(file_io, ntoh(header.num_vertices))
    write(file_io, ntoh(header.num_faces))
    write(file_io, ntoh(header.values_per_vertex))

    # Write data
    for idx in eachindex(w_data)
        write(file_io, ntoh(w_data[idx]))
    end

    close(file_io)
end
