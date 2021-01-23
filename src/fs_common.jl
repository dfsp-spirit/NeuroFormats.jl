# Common functions for reading FreeSurfer data files.

import Base.hton, Base.ntoh


function read_fs_int24(io::IO; endian::AbstractString = "little") 
    if ! (endian in ["little", "big"])
        error("Parameter 'endian' must be one of 'little' or 'big'.")
    end

    sub_values::Array{Int64,1} = zeros(3)
    endian_func = (endian == "little" ? ltoh : ntoh)
   
    b1::Int64 = Int64(endian_func(read(io, UInt8)))
    b2::Int64 = Int64(endian_func(read(io, UInt8)))
    b3::Int64 = Int64(endian_func(read(io, UInt8)))
    fs_int24 = b1 << 16 + b2 << 8 + b3
    return fs_int24
end


""" Interpret 3 single-byte unsigned integers as a single integer, as used in several FreeSurfer file formats. """
function interpret_fs_int24(b1::Integer, b2::Integer, b3::Integer)
    @printf("b1=%d, b2=%d, b3=%d (types: %s, %s, %s)\n", b1, b2, b3, typeof(b1), typeof(b2), typeof(b1));
    fs_int24::Int64 = Int64(b1) << 16 + Int64(b2) << 8 + Int64(b3)
    return fs_int24
end


