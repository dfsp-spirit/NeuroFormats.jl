# Functions for reading DTI tracks in TRK format. Used by DiffusionToolkit and TrackVis.
# See http://trackvis.org/docs/?subsect=fileformat for the spec.


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
    invert_x::Uint8
    invert_y::Uint8
    invert_z::Uint8
    swap_xy::Uint8
    swap_yz::Uint8
    swap_zx::Uint8
    n_count::Int32 # number of tracks
    version::Int32 # file format version
    hdr_size::Int32 # size of header, for endianness checking. Must be 1000 if read with correct endian setting.
end

struct DtiTrkTrack
    point_scalars::Array{Float64,1}
    point_coords::Array{Float64,1}
    track_properties::Array{Float64,1}
end

struct DtiTrk
    header::TrkHeader
    tracks::Array{DtiTrkTrack,1}
end


"""
    read_trk(file::AbstractString)

Read DTI tracks from a file in the TRK format used by DiffusionToolkit and TrackVis.
"""
function read_trk(file::AbstractString)
    endian = get_trk_endianness(file)
    endian_func = (endian == "little" ? Base.ltoh : Base.ntoh)

    io = open(file, "r")
    header = read_trk_header(io, endian)


    close(io)
end


function read_trk_header(io::IO, endian::AbstractString)
    endian_func = (endian == "little" ? Base.ltoh : Base.ntoh)
    header = DtiTrkHeader(
        read_fixed_length_string(io, 6),
        read_vector_endian(io, Int16, 3, endian=endian),
        read_vector_endian(io, Int32, 3, endian=endian),
        read_vector_endian(io, Float32, 3, endian=endian),
        Int16(endian_func(read(io, Int16))), # n_scalars
        read_fixed_length_string(io, 200), # scalar_names
        Int16(endian_func(read(io, Int16))), # n_properties
        read_fixed_length_string(io, 200), # property_names
        Base.reshape(read_vector_endian(io, Float32, 16, endian=endian), (4, 4))', # vox2ras matrix
        read_fixed_length_string(io, 444), # reserved
        read_fixed_length_string(io, 4), # voxel_order
        read_fixed_length_string(io, 4), # pad2
        read_vector_endian(io, Float32, 6, endian=endian), # image_orientation_patient
        read_fixed_length_string(io, 2), # pad1
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
    return header
end


""" Checks endianness of a TRK file using hdr_size field, returns one of "little" or "big". """
function get_trk_endianness(file::AbstractString)
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

