
module FreeSurfer

using Printf

import Base.getindex, Base.size, Base.length, Base.reinterpret, Base.hton
export read_curv

""" Models the header section of a file in Curv format. """
mutable struct CurvHeader
    curv_magic_b1::UInt8
    curv_magic_b2::UInt8
    curv_magic_b3::UInt8
    num_vertices::Int32
    num_faces::Int32
    values_per_vertex::Int32
end


""" Models the structure of a file in Curv format. """
mutable struct Curv
    header::CurvHeader
    data::Array{Float32, 1}
end

const CURV_MAGIC_HDR = 16777215::Int64
const CURV_HDR_SIZE = sizeof(CurvHeader)


""" Read header from a Curv file """
function read_curv_header(io::IO)
    header = CurvHeader(UInt8(hton(read(io,UInt8))), UInt8(hton(read(io,UInt8))), UInt8(hton(read(io,UInt8))), hton(read(io,Int32)), hton(read(io,Int32)), hton(read(io,Int32)))
    if !(header.curv_magic_b1 == 0xff && header.curv_magic_b2 == 0xff && header.curv_magic_b3 == 0xff)
        error("This is not a binary FreeSurfer Curv file: header magic code mismatch.")
    end
    header
end


""" 
    readcurv(file)

Read per-vertex data for brain meshes from the Curv file `file`. The file must be in FreeSurfer binary `Curv` format, like `lh.thickness`.

# Examples
```julia-repl
julia> curv = read_curv("~/study1/subject1/surf/lh.thickness")
```
"""
function read_curv(file::AbstractString; with_header::Bool=false)
    file_io = open(file, "r")
    header = read_curv_header(file_io)
    
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
