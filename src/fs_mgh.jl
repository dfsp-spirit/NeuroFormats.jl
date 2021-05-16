# Functions for reading MGH and MGZ files. These are always big endian.

using CodecZlib
using Printf
using LinearAlgebra

""" Models the header of a FreeSurfer brain volume file in MGH or MGZ format. The data in the `delta`, `mdc` and `p_xyz_c` fields must be used only if `is_ras_good` is 1, otherwise their contents is random."""
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

""" Alternate MghHeader constructor that does not require valid RAS information. """
MghHeader(ndim1::Integer, ndim2::Integer, ndim3::Integer, ndim4::Integer, dtype::Integer) = MghHeader(1, ndim1, ndim2, ndim3, ndim4, dtype, 0, Int16(0), zeros(Float32, 3), Base.reshape(zeros(Float32, 9), (3, 3)), zeros(Float32, 3))

""" Models a FreeSurfer brain volume file in MGH or MGZ format. The field `header` is an [`MghHeader`](@ref) struct, and the `data` field is a 4-dimensional numerical array. The exact data type of the `data` array depends on the file contents."""
struct Mgh{T<:Number}
    header::MghHeader
    data::AbstractArray{T}
end

const mri_dtype_names = Dict{Integer, String}(0 => "MRI_UCHAR", 1 => "MRI_INT", 3 => "MRI_FLOAT", 4 => "MRI_SHORT")
const mri_dtype_types = Dict{Integer, Type}(0 => UInt8, 1 => Int32, 3 => Float32, 4 => Int16)


"""
    read_mgh(file::AbstractString)

Read a file in FreeSurfer MGH or MGZ format.

These files typically contain 3D or 4D images, i.e., they represent voxel-based MRI data. They can also be used to store surface-based data though, in which case only 1 dimension is used (or 2 dimensions if data for several subjects or time points in included).

# Examples
```julia-repl
julia> mgh_file = joinpath(tdd(), "subjects_dir/subject1/mri/brain.mgz");
julia> mgh = read_mgh(mgh_file);
julia> Base.ndims(mgh.data) # Show data dimensions.
```
"""
function read_mgh(file::AbstractString)
    endian = "big"
    is_mgz::Bool = _is_file_gzipped(file)
    io = open(file, "r")
    io = is_mgz ? CodecZlib.GzipDecompressorStream(io) : io
    header = _read_mgh_header(io::IO)

    num_voxels = header.ndim1 * header.ndim2 * header.ndim3 * header.ndim4
    dtype = mri_dtype_types[header.dtype]
    data_raw::Array{dtype, 1} = _read_vector_endian(io, dtype, num_voxels, endian = endian)
    data::Array{dtype, 4} = Base.reshape(data_raw, (header.ndim1, header.ndim2, header.ndim3, header.ndim4))
    return(Mgh(header, data))
end


""" Read the header part of an MGH/MGZ file and set io to beginning of data part. """
function _read_mgh_header(io::IO)
    endian = "big"
    endian_func = Base.ntoh
    mgh_version::Int32 = Int32(endian_func(read(io, Int32)))

    if mgh_version != 1
        error("File not in MGH format.")
    end

    ndim1::Int32 = Int32(endian_func(read(io, Int32)))
    ndim2::Int32 = Int32(endian_func(read(io, Int32)))
    ndim3::Int32 = Int32(endian_func(read(io, Int32)))
    ndim4::Int32 = Int32(endian_func(read(io, Int32))) # a.k.a. nframes
    dtype::Int32 = Int32(endian_func(read(io, Int32)))
    dof::Int32 = Int32(endian_func(read(io, Int32)))

    if ! (dtype in keys(mri_dtype_names))
        error(@sprintf("Invalid or unsupported MRI data type '%d'.\n", dtype))
    end

    header_size_left = 256

    is_ras_good = Int16(endian_func(read(io, Int16)))
    header_size_left -= sizeof(Int16)

    if is_ras_good == 1
        delta = _read_vector_endian(io, Float32, 3, endian = endian) # xsize, ysize, zsize (voxel size along dimensions)
        mdc_raw = _read_vector_endian(io, Float32, 9, endian = endian) # matrix of direction cosines, a.k.a. x_r, x_a, x_s, y_r, y_a, y_s, z_r, z_a, z_s
        p_xyz_c = _read_vector_endian(io, Float32, 3, endian = endian) # x,y,z coord at center voxel, a.k.a. center RAS or CRAS

        ras_space_size = 3*4 + 4*3*4    # 60 bytes for the 3 vectors/matrices above.
        header_size_left -= ras_space_size
    else
        delta::Array{Float32, 1} = zeros(Float32, 3)
        mdc_raw::Array{Float32, 1} = zeros(Float32, 9)
        p_xyz_c::Array{Float32, 1} = zeros(Float32, 3)
    end

    mdc::Array{Float32, 2} = Base.reshape(mdc_raw, (3, 3))

    # skip to end of header / beginning of data
    discarded = _read_vector_endian(io, UInt8, header_size_left, endian = endian)

    header = MghHeader(mgh_version, ndim1, ndim2, ndim3, ndim4, dtype, dof, is_ras_good, delta, mdc, p_xyz_c)
    return(header)
end


""" Determine whether a file is in gzip format. """
function _is_file_gzipped(file::AbstractString)
    io = open(file, "r")
    is_gz::Bool = read(io, UInt8) == 0x1F && read(io, UInt8) == 0x8B
    close(io)
    return(is_gz)
end


"""
    mgh_vox2ras(mgh::Mgh)

Compute the vox2ras matrix for an [`Mgh`](@ref) instance. Requires valid RAS header data. The vox2ras matrix can be used to compute the `x`, `y`, `z` RAS coordinates of a voxel based on its `i`, `j` and `k` indices in the first three dimensions of the volume. Its inverse, the ras2vox matrix, can be used to compute the indices of the voxel that occupies a point in space given by its `x`, `y`, `z` RAS coordinates.

# Examples
```julia-repl
julia> mgh_file = joinpath(tdd(), "subjects_dir/subject1/mri/brain.mgz");
julia> mgh = read_mgh(mgh_file);
julia> mgh_vox2ras(mgh)
```
"""
function mgh_vox2ras(mgh::Mgh)
    hdr = mgh.header

    if hdr.is_ras_good != 1
        error("Cannot compute vox2ras matrix for MGH, RAS data invalid according to header.")
    end

    D = Base.reshape(zeros(Float32, 9), (3, 3))
    diag_indices = LinearAlgebra.diagind(D)
    D[diag_indices] = hdr.delta # delta = [xsize, ysize, zsize] #(voxel size along dimensions)
    p_crs_c = [hdr.ndim1/2, hdr.ndim2/2, hdr.ndim3/2]       # CRS indices of the center voxel

    mdc_scaled = hdr.mdc * D # Scaled by the voxel dimensions (xsize, ysize, zsize)

    p_xyz_0 = hdr.p_xyz_c - (mdc_scaled * p_crs_c) # the x,y,z location at CRS=0,0,0 (also known as P0 RAS or 'first voxel RAS').

    M = Base.reshape(zeros(Float32, 16), (4, 4))
    M[1:3,1:3] = mdc_scaled #as.matrix(mdc_scaled)
    M[4,1:4] = [0.,0,0,1] # affine row
    M[1:3,4] = p_xyz_0
    return(M)
end


"""
    write_mgh(file::AbstractString, mgh::Mgh)

Write an Mgh instance containing a 4D array to a binary file in FreeSurfer MGH format.

This function is typically used to write volume-based neuroimaging data for a single subject/timepoint (3D) or for several subjects or timepoints (4D). One can also use it for per-vertex data for single subjects (1D) or groups (2D), of course. The subject/timepoint dimension is dimenions #4.

See also: [`read_mgh`](@ref)

"""
function write_mgh(file::AbstractString, mgh::Mgh)
    file_io =  open(file, "w")
    
    # Write header
    write(file_io, ntoh(mgh.header.mgh_version))
    write(file_io, ntoh(mgh.header.ndim1))
    write(file_io, ntoh(mgh.header.ndim2))
    write(file_io, ntoh(mgh.header.ndim3))
    write(file_io, ntoh(mgh.header.ndim4))
    write(file_io, ntoh(mgh.header.dtype))
    write(file_io, ntoh(mgh.header.dof))


    # Write RAS info part of header
    header_size_left = 256
    write(file_io, ntoh(mgh.header.is_ras_good))
    header_size_left -= sizeof(Int16)
    if mgh.header.is_ras_good == 1
        for idx in eachindex(mgh.header.delta)
            write(file_io, ntoh(mgh.header.delta[idx]))
        end
        for idx in eachindex(mgh.header.mdc)
            write(file_io, ntoh(mgh.header.mdc[idx]))
        end
        for idx in eachindex(mgh.header.p_xyz_c)
            write(file_io, ntoh(mgh.header.p_xyz_c[idx]))
        end
        header_size_left -= 60
    end

    # Fill rest of header space.
    zero::Int8 = 0
    for _i in 1:header_size_left
        write(file_io, ntoh(zero))
    end


    # Write data
    for idx in eachindex(mgh.data)
        write(file_io, ntoh(mgh.data[idx]))
    end

    close(file_io) 
end
