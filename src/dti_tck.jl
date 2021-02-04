

struct DtiTck
    header::Dict{String, String}
    tracks::Array{DtiTrkTrack,1}
end


"""
    read_tck(file::AbstractString)

Read DTI tracks from a MRtrix3 file in TCK format.

Returns a `DtiTck` struct with fields `header`: `Dict{String,String}` with file header data, and `tracks`: an `Array{DtiTrkTrack}`.

See also: [`read_trk`](@ref) reads tracks from DiffusionToolkit files.
"""
function read_tck(file::AbstractString)

    thi = _read_tck_header(file)
    header = thi.header
    derived = thi.derived

    dtype = (startswith(header["datatype"], "Float64") ? Float64 : Float32)
    data_offset::Int64 = parse(Int64, derived["data_offset"])
    num_tracks::Int64 = parse(Int64, header["count"])
    dtype_bytes::Int64 = (dtype == Float64 ? 8 : 4)
    endian = derived["endian"]
    endian_func = (endian == "little" ? Base.ltoh : Base.ntoh)
    num_to_read::Int64 = (filesize(file) - data_offset) / dtype_bytes 

    io::IO = open(file, "r")
    seek(io, data_offset)
    track_vector_raw = _read_vector_endian(io, dtype, num_to_read, endian=endian)

    # Rows consisting of NaNs are track separators, and the final EOF row is all Inf.
    track_matrix = Base.reshape(track_vector_raw, (3, Base.length(track_vector_raw)÷3))'
    tracks = Array{DtiTrkTrack,1}(undef, num_tracks)

    current_track_point_coords = Array{dtype, 1}()

    current_track_idx::Int64 = 1
    for row_idx in 1:Base.size(track_matrix, 1)
        if all(isinf(t) for t in track_matrix[row_idx,:])
            # End of track data reached, all done.
            break
        end

        if all(isnan(t) for t in track_matrix[row_idx,:])
            # Current track complete, add to tracks
            track_point_coords_matrix::Array{dtype, 2} = Base.reshape(current_track_point_coords, (3, Base.length(current_track_point_coords)÷3))'
            track = DtiTrkTrack(track_point_coords_matrix, Array{dtype, 1}(), Array{dtype, 1}()) # TCK format supports no sclars or properties, they are in separate files.
            tracks[current_track_idx] = track

            current_track_idx += 1
            current_track_point_coords = Array{dtype, 1}() # empty current matrix
        else
            append!(current_track_point_coords, track_matrix[row_idx,:]) # in track, just add current points coords.
        end
    end    

    tck = DtiTck(header, tracks)
    return(tck)
end


struct TrkHeaderInfo
    header::Dict{String, String}
    derived::Dict{String, String}
end


""" 
    _read_tck_header(io::IO)

Read the ASCII header part of a TCK file and return it as a dictionary. 

The header can contain arbitrary extra fields in addition to the required once, so we cannot use a struct. This function derives
some information from the raw header data and stores it in a sub dictionary under the key 'derived'.
"""
function _read_tck_header(file::AbstractString)
    io::IO = open(file, "r")
    lines = readlines(io)

    if lines[1] != "mrtrix tracks"
        error("File not in MRtrix TCK format: incorrect magic line.")
    end

    header = Dict{String, String}()
    derived = Dict{String, String}()

    for line_idx in [2:Base.length(lines);]
        line = lines[line_idx]
        if  line == "END"
            break
        else
            line_parts = split(line, ":")
            key = strip(line_parts[1])
            val = strip(line_parts[2])
            header[key] = val
            if key == "file"
                file_parts = split(val, ' ')
                file_indicator = strip(file_parts[1])
                if file_indicator != "."
                    error("Multi-file TCK format not supported yet.")
                end
                data_offset = strip(file_parts[2])
                derived["file_indicator"] = file_indicator
                derived["data_offset"] = data_offset
            end
        end
    end

    # Perform some sanity checks
    valid_datatypes::Array{String,1} = ["Float32BE", "Float32LE", "Float64BE", "Float64LE"];

    if ! (header["datatype"] in valid_datatypes) 
        error("Invalid datatype in TCK file header");
    end
    
    # Determine endianness of following binary data. 
    if endswith(header["datatype"], "BE") 
        derived["endian"] = "big"
    else
        derived["endian"] = "little";
    end

    thi = TrkHeaderInfo(header, derived)
    return(thi) 
end
