# General utility functions used throughout the project.


""" Read a variable length, 0-terminated C-style string from a binary file. The trailing zero will be read if consume_zero is set, but not included in the result. """
function read_variable_length_string(io::IO; consume_zero::Bool = false)
    res_string = ""
    while (! eof(io))
        char = read(io, UInt8)
        if char == 0
            if ! consume_zero
                Base.seek(io, Base.position(io) - 1)
            end
            break
        else
            res_string = res_string * Char(char)
        end
    end
    res_string
end


""" Read fixed length byte string from a stream. """
function _read_fixed_length_string(io::IO, num_chars::Integer; strip_trailing::Array{String,1}=["\0"])
    str_bytes = Array{UInt8,1}(zeros(num_chars))
    readbytes!(io, str_bytes)
    str = String(str_bytes)
    
    for suffix in strip_trailing
        if Base.endswith(str, suffix)
                str = str[1:(Base.length(str) - Base.length(suffix))]
        end
    end
    return str
end


""" Read a vector of given length and type with specified endianness from a file. """
function _read_vector_endian(io::IO, T::Type, n::Integer; endian::AbstractString="big")
    if ! (endian in ["little", "big"])
        error("Parameter 'endian' must be one of 'little' or 'big'.")
    end
    endian_func = (endian == "little" ? Base.ltoh : Base.ntoh)
    raw_data::Array{T,1} = reinterpret(T, read(io, sizeof(T) * n))
    raw_data .= endian_func.(raw_data)
    return raw_data
end

