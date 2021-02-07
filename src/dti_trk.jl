# Functions for reading DTI tracks in TRK format. Used by DiffusionToolkit and TrackVis.
# See http://trackvis.org/docs/?subsect=fileformat for the spec.

import Base.show
using Printf


""" Models the header of a TRK format file containing fiber tracks. """
struct DtiTrkHeader
    id::String # length 6 chars
    dim::Array{Int16,1} # length 3
    voxel_size::Array{Int32,1} # length 3
    voxel_origin::Array{Float32,1} # length 3
    n_scalars::Int16 # number of scalar values per point
    scalar_names::String # length 200 chars
    n_properties::Int16 # number of scalar values associated with a track
    property_names::String # length 200 chars
    vox2ras::Array{Float32,2} # 4x4 = 16
    reserved::String # length 444 chars
    voxel_order::String # length 4 chars
    pad2::String # length 4 chars
    image_orientation_patient::Array{Float32,1} # length 6
    pad1::String # length 2 chars
    invert_x::UInt8
    invert_y::UInt8
    invert_z::UInt8
    swap_xy::UInt8
    swap_yz::UInt8
    swap_zx::UInt8
    n_count::Int32 # number of tracks
    version::Int32 # file format version
    hdr_size::Int32 # size of header, for endianness checking. Must be 1000 if read with correct endian setting.
end


""" Models a single track for a TRK file. """
struct DtiTrack
    point_coords::Array{Float64,2}
    point_scalars::Array{Float64,1}
    track_properties::Array{Float64,1}
end

""" Models a DTI TRK file. """
struct DtiTrk
    header::DtiTrkHeader
    tracks::Array{DtiTrack,1}
end

Base.show(io::IO, x::DtiTrk) = @printf("DiffusionToolkit TRK data containing %d tracks.\n", Base.length(x.tracks))


"""
    read_trk(file::AbstractString)

Read DTI tracks from a file in the TRK format used by DiffusionToolkit and TrackVis.

Returns a [`DtiTrk`](@ref) struct.

See also: [`read_tck`](@ref) reads tracks from MRtrix3 files.

# Examples
```julia-repl
julia> trk_file = joinpath(tdd(), "DTI/complex_big_endian.trk");
julia> trk = read_trk(trk_file);
julia> Base.length(trk.tracks) # show track count
```
"""
function read_trk(file::AbstractString)
    endian = _get_trk_endianness(file)
    endian_func = (endian == "little" ? Base.ltoh : Base.ntoh)

    io = open(file, "r")
    header = _read_trk_header(io, endian)

    tracks = Array{DtiTrack,1}(undef, header.n_count)
    if header.n_count > 0
        for track_idx in [1:header.n_count;]
            num_points = Int32(endian_func(read(io, Int32)))
            #@printf("Reading track %d of %d with %d points, %d scalars and %d properties.\n", track_idx, header.n_count, num_points, header.n_scalars, header.n_properties)
            
            if num_points > 0
                track_point_coords = Base.reshape(zeros(Float32, num_points * 3), (3, num_points))' # gets filled below.
                track_point_scalars = zeros(Float32, num_points * header.n_scalars) # gets filled below.
                for point_idx in [1:num_points;]
                    track_point_coords[point_idx,:] = _read_vector_endian(io, Float32, 3, endian=endian)
                    if header.n_scalars > 0
                        start_idx = point_idx * header.n_scalars - header.n_scalars + 1
                        end_idx = start_idx + header.n_scalars - 1
                        track_point_scalars[start_idx:end_idx] = _read_vector_endian(io, Float32, header.n_scalars, endian=endian)
                    else
                        track_point_scalars = Array{Float32, 1}()
                    end
                end
            else
                track_point_coords = Array{Float32, 2}()
                track_point_scalars = Array{Float32, 1}()
            end

            if header.n_properties > 0
                track_properties = _read_vector_endian(io, Float32, header.n_properties, endian=endian)
            else
                track_properties = Array{Float32, 1}()
            end
            track = DtiTrack(track_point_coords, track_point_scalars, track_properties)
            tracks[track_idx] = track
        end
    end

    close(io)
    trk = DtiTrk(header, tracks)
    return trk
end


function _read_trk_header(io::IO, endian::AbstractString)
    endian_func = (endian == "little" ? Base.ltoh : Base.ntoh)
    header = DtiTrkHeader(
        _read_fixed_length_string(io, 6),
        _read_vector_endian(io, Int16, 3, endian=endian),
        _read_vector_endian(io, Int32, 3, endian=endian),
        _read_vector_endian(io, Float32, 3, endian=endian),
        Int16(endian_func(read(io, Int16))), # n_scalars
        _read_fixed_length_string(io, 200), # scalar_names
        Int16(endian_func(read(io, Int16))), # n_properties
        _read_fixed_length_string(io, 200), # property_names
        Base.reshape(_read_vector_endian(io, Float32, 16, endian=endian), (4, 4))', # vox2ras matrix
        _read_fixed_length_string(io, 444), # reserved
        _read_fixed_length_string(io, 4), # voxel_order
        _read_fixed_length_string(io, 4), # pad2
        _read_vector_endian(io, Float32, 6, endian=endian), # image_orientation_patient
        _read_fixed_length_string(io, 2), # pad1
        UInt8(endian_func(read(io, UInt8))),
        UInt8(endian_func(read(io, UInt8))),
        UInt8(endian_func(read(io, UInt8))),
        UInt8(endian_func(read(io, UInt8))),
        UInt8(endian_func(read(io, UInt8))),
        UInt8(endian_func(read(io, UInt8))),
        Int32(endian_func(read(io, Int32))),
        Int32(endian_func(read(io, Int32))),
        Int32(endian_func(read(io, Int32)))
    )
    if header.hdr_size != 1000
        error("File not in TRK format")
    end
    return header
end


""" Checks endianness of a TRK file using hdr_size field, returns one of "little" or "big". """
function _get_trk_endianness(file::AbstractString)
    file_io = open(file, "r")

    seek(file_io, 996)
    hdr_size_big = Int32(hton(read(file_io, Int32)))
    if hdr_size_big == 1000
        close(file_io)
        return "big"
    end

    seek(file_io, 996)
    hdr_size_little = Int32(ntoh(read(file_io, Int32)))
    if hdr_size_little == 1000
        close(file_io)
        return "little"
    end
    close(file_io)
    error(@sprintf("File '%s' is not in TRK format, header magic check failed.\n", file))
end

