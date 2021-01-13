
module NeuroFormats

#using LinearAlgebra
#using Reexport

import Base.getindex, Base.size, Base.length, Base.reinterpret
export readcurv


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

const CURV_MAGIC_HDR = 16777215
const CURV_HDR_SIZE = sizeof(CurvHeader)


""" Interpret 3 single-byte unsigned integers as a single integer, as used in several FreeSurfer file formats. """
function interpret_fs_int3(b1::UInt8, b2::UInt8, b3::UInt8)
    reinterpret(Int, b1 << 16 + b2 << 8 + b3)
end



""" Read header from a Curv file """
function readcurv_header(io::IO)
    header = CurvHeader(read(io,UInt8), read(io,UInt8), read(io,UInt8), read(io,Int32), read(io,Int32), read(io,Int32))
    curv_magic = interpret_fs_int3(header.curv_magic_b1, header.curv_magic_b2, header.curv_magic_b3)
    if curv_magic != CURV_MAGIC_HDR
        error("This is not a binary FreeSurfer Curv file: header magic code mismatch.")
    end
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
function readcurv(file::AbstractString, with_header::Bool=false)
    file_io = open(file, "r")
    header = readcurv_header(file_io)
    ArrayType = Array{Float32, 1}

    
    seekstart(file_io)
    read(file_io, Int(CURV_HDR_SIZE))
    per_vertex_data = read!(file_io, ArrayType(header.num_vertices))            
    close(file_io)

    if with_header
        curv = Curv(header, per_vertex_data)
        return curv
    else
        return per_vertex_data
    end
end





end # module
