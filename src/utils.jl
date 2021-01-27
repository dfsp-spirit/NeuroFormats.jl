# General utility functions used throughout the project.


#https://stackoverflow.com/questions/61264545/read-null-terminated-string-from-byte-vector-in-julia


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