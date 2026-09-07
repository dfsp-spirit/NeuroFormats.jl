# Functions for reading and writing NIfTI-1 volume files (.nii and .nii.gz).

using CodecZlib, TranscodingStreams
using Printf
using LinearAlgebra

# ---------------------------------------------------------------------------
# NIfTI-1 constants
# ---------------------------------------------------------------------------

""" Size of the fixed NIfTI-1 header, in bytes. """
const NIFTI_HEADER_SIZE = 348
""" Header size plus the 4-byte extension indicator. """
const NIFTI_HEADER_PLUS_EXT = 352
""" Default `vox_offset` written by this package (right after header + extension indicator). """
const NIFTI_DEFAULT_VOX_OFFSET = Float32(352)

""" NIfTI-1 data type code for unsigned 8-bit integer data. """
const DT_UINT8 = Int16(2)
""" NIfTI-1 data type code for signed 16-bit integer data. """
const DT_INT16 = Int16(4)
""" NIfTI-1 data type code for signed 32-bit integer data. """
const DT_INT32 = Int16(8)
""" NIfTI-1 data type code for 32-bit float data. """
const DT_FLOAT32 = Int16(16)

""" NIfTI-1 xform code meaning "no transform". """
const XFORM_UNKNOWN = Int16(0)
""" NIfTI-1 xform code meaning "Scanner Anat". """
const XFORM_SCANNER_ANAT = Int16(1)

""" Magic string of a single-file NIfTI-1 volume (`n+1\\0`). """
const NIFTI_MAGIC_SINGLE = UInt8['n', '+', '1', 0x00]
""" Magic string of a two-file NIfTI-1 volume (`ni1\\0`). """
const NIFTI_MAGIC_TWO = UInt8['n', 'i', '1', 0x00]

# Map NIfTI-1 datatype code -> (MGH dtype code, Julia element type).
const _nifti_dtype_to_mgh = Dict{Int16, Tuple{Int32, Type}}(
    DT_UINT8 => (0, UInt8),     # MRI_UCHAR
    DT_INT16 => (4, Int16),     # MRI_SHORT
    DT_INT32 => (1, Int32),     # MRI_INT
    DT_FLOAT32 => (3, Float32), # MRI_FLOAT
)
# Map MGH dtype code -> NIfTI-1 datatype code.
const _mgh_dtype_to_nifti = Dict{Int32, Int16}(0 => DT_UINT8, 4 => DT_INT16, 1 => DT_INT32, 3 => DT_FLOAT32)

# ---------------------------------------------------------------------------
# NIfTI-1 header type
# ---------------------------------------------------------------------------

"""
    Nifti1Header

Models the (fixed 348-byte) header of a single-file NIfTI-1 volume.

All fields mirror the on-disk layout. Note that the `dim` and `pixdim` vectors are 1-based in
Julia: `dim[1]` is the number of dimensions (`dim[0]` in the spec), `dim[2:5]` the voxel counts,
`pixdim[1]` is `qfac` (`pixdim[0]` in the spec) and `pixdim[2:4]` the voxel sizes in mm. The
`srow_x/y/z` vectors hold the full 4-element rows (linear part + translation) of the s-form.

Unused passthrough fields (like `data_type`, `db_name`) are kept as raw byte vectors so that no
information is lost when a file is read and written back.
"""
mutable struct Nifti1Header
    sizeof_hdr::Int32
    data_type::Vector{UInt8}
    db_name::Vector{UInt8}
    extents::Int32
    session_error::Int16
    regular::UInt8
    dim_info::UInt8
    dim::Vector{Int16}
    intent_p1::Float32
    intent_p2::Float32
    intent_p3::Float32
    intent_code::Int16
    datatype::Int16
    bitpix::Int16
    slice_start::Int16
    pixdim::Vector{Float32}
    vox_offset::Float32
    scl_slope::Float32
    scl_inter::Float32
    slice_end::Int16
    slice_code::UInt8
    xyzt_units::UInt8
    cal_max::Float32
    cal_min::Float32
    slice_duration::Float32
    toffset::Float32
    glmax::Int32
    glmin::Int32
    descrip::Vector{UInt8}
    aux_file::Vector{UInt8}
    qform_code::Int16
    sform_code::Int16
    quatern_b::Float32
    quatern_c::Float32
    quatern_d::Float32
    qoffset_x::Float32
    qoffset_y::Float32
    qoffset_z::Float32
    srow_x::Vector{Float32}
    srow_y::Vector{Float32}
    srow_z::Vector{Float32}
    intent_name::Vector{UInt8}
    magic::Vector{UInt8}
end

""" Create an empty [`Nifti1Header`](@ref) with sensible defaults (single-file magic, 4 dims, `vox_offset` 352). """
function Nifti1Header()
    Nifti1Header(
        Int32(NIFTI_HEADER_SIZE), zeros(UInt8, 10), zeros(UInt8, 18),
        Int32(0), Int16(0), UInt8('r'), UInt8(0),
        zeros(Int16, 8),
        Float32(0), Float32(0), Float32(0), Int16(0),
        Int16(0), Int16(0), Int16(0), zeros(Float32, 8),
        NIFTI_DEFAULT_VOX_OFFSET, Float32(1), Float32(0),
        Int16(0), UInt8(0), UInt8(0),
        Float32(0), Float32(0), Float32(0), Float32(0),
        Int32(0), Int32(0),
        zeros(UInt8, 80), zeros(UInt8, 24),
        Int16(0), Int16(0),
        Float32(0), Float32(0), Float32(0),
        Float32(0), Float32(0), Float32(0),
        zeros(Float32, 4), zeros(Float32, 4), zeros(Float32, 4),
        zeros(UInt8, 16), copy(NIFTI_MAGIC_SINGLE),
    )
end

# ---------------------------------------------------------------------------
# Header reading / writing
# ---------------------------------------------------------------------------

""" Read the next 348 bytes as a [`Nifti1Header`](@ref), detecting the byte order from `sizeof_hdr`.

Returns a tuple `(header, endian)` where `endian` is `"big"` or `"little"` (the voxel data uses the
same byte order as the header). """
function _read_nifti1_header_full(io::IO)
    szbytes = read(io, 4)
    be = reinterpret(Int32, (UInt32(szbytes[1]) << 24) | (UInt32(szbytes[2]) << 16) |
                            (UInt32(szbytes[3]) << 8) | UInt32(szbytes[4]))
    le = reinterpret(Int32, (UInt32(szbytes[4]) << 24) | (UInt32(szbytes[3]) << 16) |
                            (UInt32(szbytes[2]) << 8) | UInt32(szbytes[1]))
    endian = ""
    if le == Int32(NIFTI_HEADER_SIZE)
        endian = "little"
        endian_func = Base.ltoh
    elseif be == Int32(NIFTI_HEADER_SIZE)
        endian = "big"
        endian_func = Base.ntoh
    else
        error("Invalid NIfTI-1 file: sizeof_hdr is $(Int32(be)) (expected $(NIFTI_HEADER_SIZE)).")
    end

    h = Nifti1Header()
    h.sizeof_hdr = Int32(NIFTI_HEADER_SIZE)
    h.data_type = read(io, 10)
    h.db_name = read(io, 18)
    h.extents = Int32(endian_func(read(io, Int32)))
    h.session_error = Int16(endian_func(read(io, Int16)))
    h.regular = read(io, UInt8)
    h.dim_info = read(io, UInt8)
    h.dim = _read_vector_endian(io, Int16, 8; endian = endian)
    h.intent_p1 = endian_func(read(io, Float32))
    h.intent_p2 = endian_func(read(io, Float32))
    h.intent_p3 = endian_func(read(io, Float32))
    h.intent_code = Int16(endian_func(read(io, Int16)))
    h.datatype = Int16(endian_func(read(io, Int16)))
    h.bitpix = Int16(endian_func(read(io, Int16)))
    h.slice_start = Int16(endian_func(read(io, Int16)))
    h.pixdim = _read_vector_endian(io, Float32, 8; endian = endian)
    h.vox_offset = endian_func(read(io, Float32))
    h.scl_slope = endian_func(read(io, Float32))
    h.scl_inter = endian_func(read(io, Float32))
    h.slice_end = Int16(endian_func(read(io, Int16)))
    h.slice_code = read(io, UInt8)
    h.xyzt_units = read(io, UInt8)
    h.cal_max = endian_func(read(io, Float32))
    h.cal_min = endian_func(read(io, Float32))
    h.slice_duration = endian_func(read(io, Float32))
    h.toffset = endian_func(read(io, Float32))
    h.glmax = Int32(endian_func(read(io, Int32)))
    h.glmin = Int32(endian_func(read(io, Int32)))
    h.descrip = read(io, 80)
    h.aux_file = read(io, 24)
    h.qform_code = Int16(endian_func(read(io, Int16)))
    h.sform_code = Int16(endian_func(read(io, Int16)))
    h.quatern_b = endian_func(read(io, Float32))
    h.quatern_c = endian_func(read(io, Float32))
    h.quatern_d = endian_func(read(io, Float32))
    h.qoffset_x = endian_func(read(io, Float32))
    h.qoffset_y = endian_func(read(io, Float32))
    h.qoffset_z = endian_func(read(io, Float32))
    h.srow_x = _read_vector_endian(io, Float32, 4; endian = endian)
    h.srow_y = _read_vector_endian(io, Float32, 4; endian = endian)
    h.srow_z = _read_vector_endian(io, Float32, 4; endian = endian)
    h.intent_name = read(io, 16)
    h.magic = read(io, 4)
    return (h, endian)
end

""" Read the next 348 bytes as a [`Nifti1Header`](@ref) (discarding the detected byte order). """
function _read_nifti1_header(io::IO)::Nifti1Header
    return _read_nifti1_header_full(io)[1]
end

""" Write a [`Nifti1Header`](@ref) (348 bytes) to the stream in the given byte order (`"big"` or `"little"`). """
function _write_nifti1_header(io::IO, h::Nifti1Header; endian::AbstractString = "big")
    endian_func = (endian == "big" ? Base.ntoh : Base.ltoh)
    write(io, endian_func(h.sizeof_hdr))
    write(io, h.data_type)
    write(io, h.db_name)
    write(io, endian_func(h.extents))
    write(io, endian_func(h.session_error))
    write(io, h.regular)
    write(io, h.dim_info)
    for x in h.dim
        write(io, endian_func(x))
    end
    write(io, endian_func(h.intent_p1))
    write(io, endian_func(h.intent_p2))
    write(io, endian_func(h.intent_p3))
    write(io, endian_func(h.intent_code))
    write(io, endian_func(h.datatype))
    write(io, endian_func(h.bitpix))
    write(io, endian_func(h.slice_start))
    for x in h.pixdim
        write(io, endian_func(x))
    end
    write(io, endian_func(h.vox_offset))
    write(io, endian_func(h.scl_slope))
    write(io, endian_func(h.scl_inter))
    write(io, endian_func(h.slice_end))
    write(io, h.slice_code)
    write(io, h.xyzt_units)
    write(io, endian_func(h.cal_max))
    write(io, endian_func(h.cal_min))
    write(io, endian_func(h.slice_duration))
    write(io, endian_func(h.toffset))
    write(io, endian_func(h.glmax))
    write(io, endian_func(h.glmin))
    write(io, h.descrip)
    write(io, h.aux_file)
    write(io, endian_func(h.qform_code))
    write(io, endian_func(h.sform_code))
    write(io, endian_func(h.quatern_b))
    write(io, endian_func(h.quatern_c))
    write(io, endian_func(h.quatern_d))
    write(io, endian_func(h.qoffset_x))
    write(io, endian_func(h.qoffset_y))
    write(io, endian_func(h.qoffset_z))
    for x in h.srow_x
        write(io, endian_func(x))
    end
    for x in h.srow_y
        write(io, endian_func(x))
    end
    for x in h.srow_z
        write(io, endian_func(x))
    end
    write(io, h.intent_name)
    write(io, h.magic)
    return nothing
end

# ---------------------------------------------------------------------------
# Quaternion <-> rotation matrix helpers (NIfTI convention)
# ---------------------------------------------------------------------------

""" Convert a 3x3 rotation matrix (columns = unit axis directions) to NIfTI q-form parameters.

Returns `(qfac, b, c, d)`. A negative determinant (a reflection) is encoded as `qfac = -1` and the
third column is negated before quaternion extraction (NIfTI convention). Uses Shepperd's method.
"""
function _mat33_to_quatern(m::Matrix{Float32})
    a11, a12, a13 = m[1, 1], m[1, 2], m[1, 3]
    a21, a22, a23 = m[2, 1], m[2, 2], m[2, 3]
    a31, a32, a33 = m[3, 1], m[3, 2], m[3, 3]
    det = a11 * (a22 * a33 - a23 * a32) -
          a12 * (a21 * a33 - a23 * a31) +
          a13 * (a21 * a32 - a22 * a31)
    qfac = det < 0.0f0 ? -1.0f0 : 1.0f0
    if qfac < 0.0f0
        a13 = -a13
        a23 = -a23
        a33 = -a33
    end

    trace = a11 + a22 + a33
    if trace > 0.0f0
        s = sqrt(trace + 1.0f0) * 2.0f0
        w = 0.25f0 * s
        x = (a32 - a23) / s
        y = (a13 - a31) / s
        z = (a21 - a12) / s
    elseif a11 > a22 && a11 > a33
        s = sqrt(1.0f0 + a11 - a22 - a33) * 2.0f0
        w = (a32 - a23) / s
        x = 0.25f0 * s
        y = (a12 + a21) / s
        z = (a13 + a31) / s
    elseif a22 > a33
        s = sqrt(1.0f0 + a22 - a11 - a33) * 2.0f0
        w = (a13 - a31) / s
        x = (a12 + a21) / s
        y = 0.25f0 * s
        z = (a23 + a32) / s
    else
        s = sqrt(1.0f0 + a33 - a11 - a22) * 2.0f0
        w = (a21 - a12) / s
        x = (a13 + a31) / s
        y = (a23 + a32) / s
        z = 0.25f0 * s
    end
    n = sqrt(w * w + x * x + y * y + z * z)
    if n > 0.0f0
        w /= n
        x /= n
        y /= n
        z /= n
    end
    if w < 0.0f0
        w = -w
        x = -x
        y = -y
        z = -z
    end
    return (qfac, x, y, z)
end

""" Build the rotation matrix from a unit quaternion `(a, b, c, d)`. """
function _quat_to_rotation(a::Float32, b::Float32, c::Float32, d::Float32)::Matrix{Float32}
    R = zeros(Float32, 3, 3)
    R[1, 1] = a * a + b * b - c * c - d * d
    R[1, 2] = 2.0f0 * (b * c - a * d)
    R[1, 3] = 2.0f0 * (b * d + a * c)
    R[2, 1] = 2.0f0 * (b * c + a * d)
    R[2, 2] = a * a + c * c - b * b - d * d
    R[2, 3] = 2.0f0 * (c * d - a * b)
    R[3, 1] = 2.0f0 * (b * d - a * c)
    R[3, 2] = 2.0f0 * (c * d + a * b)
    R[3, 3] = a * a + d * d - b * b - c * c
    return R
end

# ---------------------------------------------------------------------------
# Voxel-to-RAS (affine) handling
# ---------------------------------------------------------------------------

""" Decode the voxel-to-RAS affine (as a 4x4 matrix, translation = RAS of voxel (0,0,0)) from a
[`Nifti1Header`](@ref), preferring the s-form and falling back to the q-form. Returns `nothing` if
the header carries no transform. """
function _nifti_decode_affine(h::Nifti1Header)
    M = zeros(Float32, 4, 4)
    if h.sform_code > 0
        M[1, 1:4] = h.srow_x
        M[2, 1:4] = h.srow_y
        M[3, 1:4] = h.srow_z
        M[4, 4] = 1.0f0
        return M
    elseif h.qform_code > 0
        b = h.quatern_b
        c = h.quatern_c
        d = h.quatern_d
        a = sqrt(max(0.0f0, 1.0f0 - (b * b + c * c + d * d)))
        qfac = h.pixdim[1] < 0.0f0 ? -1.0f0 : 1.0f0
        R = _quat_to_rotation(a, b, c, d)
        R[:, 3] .*= qfac
        for j in 1:3
            M[1:3, j] = R[:, j] .* h.pixdim[j + 1]
        end
        M[1, 4] = h.qoffset_x
        M[2, 4] = h.qoffset_y
        M[3, 4] = h.qoffset_z
        M[4, 4] = 1.0f0
        return M
    end
    return nothing
end

""" Build an [`MghHeader`](@ref) from a [`Nifti1Header`](@ref) and the 4 volume dimensions.

The voxel-to-world transform of the NIfTI file is decomposed into the MGH RAS fields in the
FreeSurfer convention: `delta` are the voxel sizes (norms of the columns of the affine linear
part), the columns of `mdc` are the unit direction cosines of the 3 volume axes, and `p_xyz_c` is
the RAS of the center voxel (the NIfTI s/q-form translation is the RAS of voxel (0,0,0) and is
re-anchored to the center, using the same center index convention as [`mgh_vox2ras`](@ref))."""
function _mgh_header_from_nifti(h::Nifti1Header, dims::NTuple{4, Int})
    nd1, nd2, nd3, nd4 = dims
    if !haskey(_nifti_dtype_to_mgh, h.datatype)
        error("Unsupported NIfTI-1 data type $(h.datatype). Supported types are UINT8 (2), INT16 (4), INT32 (8), FLOAT32 (16).")
    end
    mgh_dtype = _nifti_dtype_to_mgh[h.datatype][1]

    M = _nifti_decode_affine(h)
    if M === nothing
        return MghHeader(1, Int32(nd1), Int32(nd2), Int32(nd3), Int32(nd4), mgh_dtype, 0,
                         Int16(0), zeros(Float32, 3), zeros(Float32, 3, 3), zeros(Float32, 3))
    end

    linear = M[1:3, 1:3]
    p0 = M[1:3, 4]
    delta = Float32[sqrt(sum(linear[:, j] .^ 2)) for j in 1:3]
    mdc = zeros(Float32, 3, 3)
    for j in 1:3
        if delta[j] > 0.0f0
            mdc[:, j] = linear[:, j] ./ delta[j]
        else
            # Degenerate column (zero voxel size): use a unit vector along the world axis.
            delta[j] = 1.0f0
            mdc[:, j] = Float32[j == i ? 1.0 : 0.0 for i in 1:3]
        end
    end
    # Center voxel index, same convention as mgh_vox2ras (real division ndim/2).
    c_crs = Float32[nd1 / 2, nd2 / 2, nd3 / 2]
    p_xyz_c = p0 .+ linear * c_crs
    return MghHeader(1, Int32(nd1), Int32(nd2), Int32(nd3), Int32(nd4), mgh_dtype, 0,
                     Int16(1), delta, mdc, p_xyz_c)
end

""" Build a [`Nifti1Header`](@ref) from an [`Mgh`](@ref) volume, deriving dims, data type and the
s-form/q-form from the MGH header (if it carries RAS information). """
function _nifti_header_from_mgh(mgh::Mgh)::Nifti1Header
    mghh = mgh.header
    d1, d2, d3, d4 = Int(mghh.ndim1), Int(mghh.ndim2), Int(mghh.ndim3), Int(mghh.ndim4)
    if any(x -> x > 32767, (d1, d2, d3, d4))
        error("MGH dimensions exceed the NIfTI-1 int16 limit (32767). Cannot write as NIfTI.")
    end
    if !haskey(_mgh_dtype_to_nifti, mghh.dtype)
        error("MGH data type $(mghh.dtype) cannot be represented as a NIfTI-1 data type.")
    end

    h = Nifti1Header()
    h.dim[1] = d4 > 1 ? Int16(4) : Int16(3)
    h.dim[2] = Int16(d1)
    h.dim[3] = Int16(d2)
    h.dim[4] = Int16(d3)
    h.dim[5] = Int16(d4)
    h.dim[6:8] .= Int16(1)
    h.datatype = _mgh_dtype_to_nifti[mghh.dtype]
    h.bitpix = mghh.dtype == 0 ? Int16(8) : (mghh.dtype == 4 ? Int16(16) : Int16(32))
    h.vox_offset = NIFTI_DEFAULT_VOX_OFFSET
    h.scl_slope = 1.0f0
    h.scl_inter = 0.0f0
    h.pixdim .= 1.0f0

    if mghh.is_ras_good == 1
        delta = Float32.(mghh.delta)
        linear = mghh.mdc * LinearAlgebra.Diagonal(delta) # columns = axis dirs * voxel size
        c_crs = Float32[d1 / 2, d2 / 2, d3 / 2]
        p0 = mghh.p_xyz_c .- linear * c_crs

        # s-form: the voxel-to-RAS affine itself (its translation is the RAS of voxel (0,0,0)).
        h.sform_code = XFORM_SCANNER_ANAT
        h.srow_x = Float32[linear[1, 1], linear[1, 2], linear[1, 3], p0[1]]
        h.srow_y = Float32[linear[2, 1], linear[2, 2], linear[2, 3], p0[2]]
        h.srow_z = Float32[linear[3, 1], linear[3, 2], linear[3, 3], p0[3]]

        # q-form: encode the same affine as a quaternion.
        colnorm = Float32[sqrt(sum(linear[:, j] .^ 2)) for j in 1:3]
        if all(colnorm .> 0.0f0)
            rot = linear ./ reshape(colnorm, 1, 3) # columns = unit axis directions
            qfac, qb, qc, qd = _mat33_to_quatern(rot)
            h.qform_code = XFORM_SCANNER_ANAT
            h.pixdim[1] = qfac
            h.quatern_b = qb
            h.quatern_c = qc
            h.quatern_d = qd
            h.qoffset_x = p0[1]
            h.qoffset_y = p0[2]
            h.qoffset_z = p0[3]
        else
            h.qform_code = XFORM_UNKNOWN
        end
    else
        h.sform_code = XFORM_UNKNOWN
        h.qform_code = XFORM_UNKNOWN
    end
    return h
end

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

"""
    read_nifti(file::AbstractString)

Read a file in NIfTI-1 format (`.nii`, or `.nii.gz` if the file is gzip-compressed) and return it
as an [`Mgh`](@ref) volume. This makes converting between NIfTI-1 and FreeSurfer MGH/MGZ formats
trivial: read a NIfTI file and write it with [`write_mgh`](@ref), or vice versa.

Only standard-compliant single-file NIfTI-1 volumes are supported, with the data types UINT8,
INT16, INT32 and FLOAT32 (matching the data types the MGH volume model supports). Both big- and
little-endian files can be read.

If the NIfTI file carries a voxel-to-world transform (s-form preferred, q-form as fallback), it
is converted into the MGH RAS header fields (`delta`, `mdc`, `p_xyz_c`) such that
[`mgh_vox2ras`](@ref) reconstructs the exact transform stored in the file. This includes the
re-anchoring of the NIfTI translation (the RAS of voxel (0,0,0)) to the MGH center voxel.

# Examples
```julia-repl
julia> nii_file = joinpath(tdd(), "subjects_dir/subject1/mri/brain.nii");
julia> mgh = read_nifti(nii_file);
julia> size(mgh.data)
```
"""
function read_nifti(file::AbstractString)
    is_gz = _is_file_gzipped(file)
    raw_io = open(file, "r")
    io = is_gz ? CodecZlib.GzipDecompressorStream(raw_io) : raw_io
    h, endian = _read_nifti1_header_full(io)

    # Validate magic string.
    if h.magic == NIFTI_MAGIC_TWO
        close(io)
        error("Two-file NIfTI volumes (.hdr/.img pairs) are not supported, only single-file .nii volumes.")
    end
    if h.magic != NIFTI_MAGIC_SINGLE
        close(io)
        error("Invalid NIfTI-1 magic string $(h.magic). Only single-file .nii volumes are supported.")
    end
    ndim = Int(h.dim[1])
    if !(1 <= ndim <= 7)
        close(io)
        error("Invalid NIfTI-1 file: dim[1] = $ndim (must be in 1..=7).")
    end
    if h.dim[2] <= 0
        close(io)
        error("Invalid NIfTI-1 file: dim[2] = $(h.dim[2]). FreeSurfer surface data stored in NIfTI files is not supported.")
    end
    if any(x -> x > 1, h.dim[6:8])
        close(io)
        error("NIfTI files with more than 4 dimensions are not supported.")
    end
    dims = (Int(h.dim[2]), max(Int(h.dim[3]), 1), max(Int(h.dim[4]), 1), max(Int(h.dim[5]), 1))
    (nd1, nd2, nd3, nd4) = dims

    if !haskey(_nifti_dtype_to_mgh, h.datatype)
        close(io)
        error("Unsupported NIfTI-1 data type $(h.datatype). Supported types are UINT8 (2), INT16 (4), INT32 (8), FLOAT32 (16).")
    end
    (mgh_dtype, T) = _nifti_dtype_to_mgh[h.datatype]

    num_voxels = Int64(nd1) * Int64(nd2) * Int64(nd3) * Int64(nd4)
    _check_alloc(num_voxels, sizeof(T), "NIfTI voxel data ($(nd1)×$(nd2)×$(nd3)×$(nd4))")

    # Validate / honor the voxel data offset.
    if !(h.vox_offset >= Float32(NIFTI_HEADER_SIZE)) || !isfinite(h.vox_offset)
        close(io)
        error("Invalid NIfTI-1 file: vox_offset = $(h.vox_offset).")
    end
    vox_offset = Int(h.vox_offset)
    to_skip = vox_offset - NIFTI_HEADER_SIZE
    if to_skip > 0
        read(io, to_skip) # skip any data between header and voxel data (extensions)
    end

    # Byte order of the voxel data is the same as the header.
    raw = _read_vector_endian(io, T, num_voxels, endian = endian)

    slope = h.scl_slope == 0.0f0 ? 1.0f0 : h.scl_slope
    inter = h.scl_inter
    if slope != 1.0f0 || inter != 0.0f0
        vals = Float32.(raw) .* slope .+ inter
        if T == UInt8
            vals = round.(clamp.(vals, 0.0f0, 255.0f0))
        elseif T != Float32
            vals = round.(vals)
        end
        raw = convert.(T, vals)
    end
    data = reshape(raw, (nd1, nd2, nd3, nd4))

    mgh_header = _mgh_header_from_nifti(h, dims)
    close(io)
    return Mgh(mgh_header, data)
end

"""
    read_nifti_header(file::AbstractString)

Read only the header of a NIfTI-1 file (`.nii` or gzip-compressed) and return it as a
[`Nifti1Header`](@ref). See [`read_nifti`](@ref) to read header and data into an [`Mgh`](@ref).
"""
function read_nifti_header(file::AbstractString)::Nifti1Header
    is_gz = _is_file_gzipped(file)
    raw_io = open(file, "r")
    io = is_gz ? CodecZlib.GzipDecompressorStream(raw_io) : raw_io
    h = _read_nifti1_header(io)
    close(io)
    return h
end

"""
    write_nifti(file::AbstractString, mgh::Mgh)

Write an [`Mgh`](@ref) volume to a file in NIfTI-1 format (single-file `.nii`, big-endian). If the
file name ends in `.nii.gz` (or `.NII.GZ`), the file is written gzip-compressed.

The NIfTI header (dimensions, data type, and, if the volume carries RAS information, the s-form
and q-form) is derived from the MGH header. The voxel data is written as-is (no scaling is
applied). Since NIfTI voxel order is the same as in MGH files (the first dimension varies
fastest), the volume can be read back unchanged with [`read_nifti`](@ref), and converting between
MGH/MGZ and NIfTI files is just reading one format and writing the other.

# Examples
```julia-repl
julia> mgh = read_mgh(joinpath(tdd(), "subjects_dir/subject1/mri/brain.mgz"));
julia> write_nifti("brain.nii", mgh);
julia> mgh2 = read_nifti("brain.nii");
```
"""
function write_nifti(file::AbstractString, mgh::Mgh)
    is_gz = endswith(lowercase(file), ".nii.gz")
    h = _nifti_header_from_mgh(mgh)
    file_io = open(file, "w")
    if is_gz
        file_io = TranscodingStream(GzipCompressor(), file_io)
    end
    _write_nifti1_header(file_io, h; endian = "big")
    # 4-byte extension indicator (0 = no extensions).
    write(file_io, ntoh(Int32(0)))
    # Write voxel data (first dimension varies fastest, same as in MGH files).
    for x in mgh.data
        write(file_io, ntoh(x))
    end
    close(file_io)
    return nothing
end
