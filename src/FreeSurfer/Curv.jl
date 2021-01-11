
# Methods for reading FreeSurfer curv files containing per-vertex data for brain surface models (meshes).
# A typical example would be cortical thickness data for the left hemisphere in '$SUBJECT/surf/lh.thickness'. These files have no file extension.

module FreeSurfer

using Mmap

import Base.getindex, Base.size, Base.length
export readcurv


mutable struct CurvHeader
    curv_magic_b1::UInt8
    curv_magic_b2::UInt8
    curv_magic_b3::UInt8
    num_vertices::Int32
    num_faces::Int32
    values_per_vertex::Int32
end

const CURV_MAGIC_HDR = 16777215
const CURV_HDR_SIZE = sizeof(CurvHeader)


""" Interprete 3 single-byte unsigned integers as a single integer, as used in several FreeSurfer file formats. """
function interprete_fs_int3(b1::UInt8, b2::UInt8, b3::UInt8)
    reinterprete(Int32, (b1 << 16 + b2 << 8 + b3))
end


""" Read header from a Curv file """
function readcurv_header(io::IO)
    header = read(io, CurvHeader)
    curv_magic = interprete_fs_int3(header.curv_magic_b1, header.curv_magic_b2, header.curv_magic_b3)
    if curv_magic != CURV_MAGIC_HDR
        error("This is not a binary FreeSurfer Curv file: header magic code mismatch.")
    end
    header
end


""" Read a Curv file. """
function readcurv(file::AbstractString)
    file_io = open(file, "r")
    header = readcurv_header(file_io)
    ArrayType = Array{Float32, 1}

    
    seekstart(file_io)
    read(file_io, Int(CURV_HDR_SIZE))
    per_vertex_data = read!(file_io, ArrayType(header.num_vertices))            
    close(file_io)
end


end # module
