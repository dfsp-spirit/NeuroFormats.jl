
module FreeSurfer

#using LinearAlgebra
#using Reexport
using Printf

import Base.getindex, Base.size, Base.length, Base.reinterpret, Base.hton
export readcurv, curv_header


mutable struct CurvHeader
    curv_magic_b1::UInt8
    curv_magic_b2::UInt8
    curv_magic_b3::UInt8
    num_vertices::Int32
    num_faces::Int32
    values_per_vertex::Int32
end

mutable struct Curv
    header::CurvHeader
    data::Array{Float32, 1}
end

const CURV_MAGIC_HDR = 16777215::Int64
const CURV_HDR_SIZE = sizeof(CurvHeader)


""" Interpret 3 single-byte unsigned integers as a single integer, as used in several FreeSurfer file formats. """
function interpret_fs_int3(b1::UInt8, b2::UInt8, b3::UInt8)
    @printf("b1=%d, b2=%d, b3=%d (types: %s, %s, %s)\n", b1, b2, b3, typeof(b1), typeof(b2), typeof(b1));
    fsint = reinterpret(Int64, b1 << 16 + b2 << 8 + b3)
    fsint
end



""" Read header from a Curv file """
function readcurv_header(io::IO)
    header = CurvHeader(UInt8(hton(read(io,UInt8))), UInt8(hton(read(io,UInt8))), UInt8(hton(read(io,UInt8))), hton(read(io,Int32)), hton(read(io,Int32)), hton(read(io,Int32)))
    #curv_magic = interpret_fs_int3(header.curv_magic_b1, header.curv_magic_b2, header.curv_magic_b3)
    #if curv_magic != CURV_MAGIC_HDR
    #    error("This is not a binary FreeSurfer Curv file: header magic code mismatch.")
    #end
    header
end


""" 
    readcurv(file)

Read per-vertex data for brain meshes from the Curv file `file`. The file must be in FreeSurfer binary `Curv` format, like `lh.thickness`.

# Examples
```julia-repl
julia> curv = readcurv("~/study1/subject1/surf/lh.thickness")
```
"""
function readcurv(file::AbstractString; with_header::Bool=false)
    file_io = open(file, "r")
    header = readcurv_header(file_io)
    
    @printf("Loaded curv header with data for %d vertices, now at fh position %d.\n", header.num_vertices, Base.position(file_io))
    per_vertex_data = reinterpret(Float32, read(file_io, sizeof(Float32) * header.num_vertices))
    per_vertex_data .= ntoh.(per_vertex_data)
              
    close(file_io)

    if with_header
        curv = Curv(header, per_vertex_data)
        return curv
    else
        return per_vertex_data
    end
end


end # module
