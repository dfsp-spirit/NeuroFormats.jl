# Functions for reading MGH and MGZ files.

using CodecZlib


struct MghHeader
end

struct Mgh
    header::MghHeader
end


function read_mgh(file::AbstractString)
    is_mgz::Bool = _is_file_gzipped(file)
    io = read(file, "r")
    io = is_mgz ? CodecZlib.GzipDecompressorStream(io) : io
    header = _read_mgh_header(io::IO)

end


function _read_mgh_header(io::IO)
end


function _is_file_gzipped(file::AbstractString)
    io = open(file, "r")    
    is_gz = read(io, UInt8) == 0x1F && read(io, UInt8) == 0x8B
    close(io)
    return(is_gz)
end