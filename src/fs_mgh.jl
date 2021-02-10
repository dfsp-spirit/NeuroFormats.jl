# Functions for reading MGH and MGZ files. These are always big endian.

using CodecZlib
using Printf

struct MghHeader
    mgh_version::Int32
    ndim1::Int32   # size of first dimension.
    ndim2::Int32   # size of second dimension.
    ndim3::Int32   # size of third dimension. Dims 1 to 3 are typically spatial (for volume files).
    ndim4::Int32  # a.k.a. nframes, size of 4th dimension, this usually represents the time dimension, but may be anything.
    dtype::Int32 # MRI data type, see mri_dtype_names and mri_dtype_types.
    dof::Int32
    is_ras_good::Int16 # a.k.a. RAS_good_flag, determines whether the RAS-related header data is valid (1) or invalid (anything else). If invalid, ignore the vox2ras matrix.
    delta::Array{Float32,1}
    mdc::Array{Float32,2}
    p_xyz_c::Array{Float32,1}
end

struct Mgh
    header::MghHeader
end

const mri_dtype_names = Dict{Integer, String}(0 => "MRI_UCHAR", 1 => "MRI_INT", 3 => "MRI_FLOAT", 4 => "MRI_SHORT")
const mri_dtype_types = Dict{Integer, Integer}(0 => UInt8, 1 => Int32, 3 => Float32, 4 => Int16)

function read_mgh(file::AbstractString)
    is_mgz::Bool = _is_file_gzipped(file)
    io = read(file, "r")
    io = is_mgz ? CodecZlib.GzipDecompressorStream(io) : io
    header = _read_mgh_header(io::IO)

end


function _read_mgh_header(io::IO)
    endian = "big"
    endian_func = Base.ntoh
    mgh_version::Int32 = Int32(endian_func(read(file_io, Int32)))

    if mgh_version != 1
        error("File not in MGH format.")
    end

    ndim1::Int32 = Int32(endian_func(read(file_io, Int32)))
    ndim2::Int32 = Int32(endian_func(read(file_io, Int32)))
    ndim3::Int32 = Int32(endian_func(read(file_io, Int32)))
    nframes::Int32 = Int32(endian_func(read(file_io, Int32)))
    dtype::Int32 = Int32(endian_func(read(file_io, Int32)))
    dof::Int32 = Int32(endian_func(read(file_io, Int32)))

    if ! (dtype in keys(mri_dtype_names))
        error(@sprintf("Invalid or unsupported MRI data type '%d'.\n", dtype))
    end

    header_size_left = 256

    is_ras_good = Int16(endian_func(read(file_io, Int16)))
    header_size_left -= sizeof(Int16)

    if is_ras_good == 1
        delta = _read_vector_endian(io, Float32, 3, endian = endian) # xsize, ysize, zsize (voxel size along dimensions)
        mdc = _read_vector_endian(io, Float32, 9, endian = endian) # matrix of direction cosines, a.k.a. x_r, x_a, x_s, y_r, y_a, y_s, z_r, z_a, z_s
        p_xyz_c = _read_vector_endian(io, Float32, 3, endian = endian) # x,y,z coord at center voxel, a.k.a. center RAS or CRAS 

        ras_space_size = 3*4 + 4*3*4    # 60 bytes for the 3 vectors/matrices above.
        header_size_left -= RAS_space_size
    else
        delta::Array{Float32, 1} = zeros(Float32, 3)
        mdc::Array{Float32, 1} = zeros(Float32, 9)
        p_xyz_c::Array{Float32, 1} = zeros(Float32, 3)
    end

    # TODO: reshape mdc array to 2D (3x3)

    # skip to end of header / beginning of data
    discarded = _read_vector_endian(io, UInt8, header_size_left, endian = endian)

    header = MghHeader(mgh_version, ndim1, ndim2, ndim3, ndim4, dtype, dof, is_ras_good, delta, mdc, p_xyz_c)    
    return(header)
end


function _is_file_gzipped(file::AbstractString)
    io = open(file, "r")    
    is_gz = read(io, UInt8) == 0x1F && read(io, UInt8) == 0x8B
    close(io)
    return(is_gz)
end