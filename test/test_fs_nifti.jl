# Tests for reading and writing NIfTI-1 (.nii) files.

NII_FILE = joinpath(Base.source_dir(), "data/subjects_dir/subject1/mri/brain.nii")
MGH_FILE = joinpath(Base.source_dir(), "data/subjects_dir/subject1/mri/brain.mgz")

# This is the same vox2ras matrix that `mri_info` reports for the shared demo volume (see
# test_fs_mgh.jl). Note: reshape is column-major, so the literal below lists the 4 columns
# (x, y, z and the translation) of the matrix.
expected_vox2ras = Base.reshape([-1.,0,0,0, 0,0,-1,0, 0,1,0,0, 127.5,-98.6273,79.0953,1], (4,4))

@testset "Read the FreeSurfer-generated brain.nii and compare to brain.mgz" begin

    mgh = read_mgh(MGH_FILE)
    nii = read_nifti(NII_FILE)

    # Same volume geometry.
    @test size(nii.data) == size(mgh.data)
    @test size(nii.data) == (256, 256, 256, 1)

    # Same data type (UInt8 / MRI_UCHAR).
    @test nii.header.dtype == mgh.header.dtype
    @test nii.header.dtype == 0

    # RAS part of the header matches.
    @test nii.header.is_ras_good == mgh.header.is_ras_good
    @test nii.header.is_ras_good == 1
    @test all(isapprox.(nii.header.delta, mgh.header.delta, atol=0.05))
    @test all(isapprox.(nii.header.delta, [1.0, 1.0, 1.0], atol=0.05))
    @test all(isapprox.(nii.header.mdc, mgh.header.mdc, atol=0.05))
    @test all(isapprox.(nii.header.mdc, Base.reshape([-1.,0,0,0,0,-1,0,1,0], (3,3)), atol=0.05))
    @test all(isapprox.(nii.header.p_xyz_c, mgh.header.p_xyz_c, atol=0.05))
    @test all(isapprox.(nii.header.p_xyz_c, [-0.5, 29.4, -48.9], atol=0.05))

    # The vox2ras matrices agree.
    @test all(isapprox.(mgh_vox2ras(nii), mgh_vox2ras(mgh), atol=0.05))
    @test all(isapprox.(mgh_vox2ras(nii), expected_vox2ras, atol=0.05))

    # The voxel data is identical.
    @test nii.data == mgh.data
    @test nii.data[100, 100, 100, 1] == 77
    @test nii.data[110, 110, 110, 1] == 71
    @test nii.data[1, 1, 1, 1] == 0
    @test sum(Int32.(nii.data)) == 121035479
end


@testset "Reading brain.nii honors the s-form from the FreeSurfer reference" begin

    h = read_nifti_header(NII_FILE)

    # Single-file NIfTI volume.
    @test String(h.magic) == "n+1\0"
    @test h.sizeof_hdr == 348

    # The s-form rows must equal the rows of the reference vox2ras matrix.
    @test h.sform_code == 1
    @test all(isapprox.(h.srow_x, [-1.0, 0.0, 0.0, 127.5], atol=0.05))
    @test all(isapprox.(h.srow_y, [0.0, 0.0, 1.0, -98.6273], atol=0.05))
    @test all(isapprox.(h.srow_z, [0.0, -1.0, 0.0, 79.0953], atol=0.05))

    # The q-form offset is the RAS of voxel (0,0,0), i.e. the translation of vox2ras.
    @test h.qform_code == 1
    @test all(isapprox.([h.qoffset_x, h.qoffset_y, h.qoffset_z],
                        [127.5, -98.6273, 79.0953], atol=0.05))

    # qfac is stored in pixdim[1] and must be -1 for this left-handed volume.
    @test h.pixdim[1] == -1.0
end


@testset "Decode the q-form of brain.nii when the s-form is missing" begin

    h = read_nifti_header(NII_FILE)
    @test h.qform_code != 0

    # Remove the s-form so decoding has to fall back to the q-form.
    h.sform_code = Int16(0)
    fill!(h.srow_x, 0.0f0)
    fill!(h.srow_y, 0.0f0)
    fill!(h.srow_z, 0.0f0)

    mgh_header = NeuroFormats.FreeSurfer._mgh_header_from_nifti(h, (256, 256, 256, 1))

    # The q-form must decode to the same geometry as the s-form. Note: reconstructing the rotation
    # from the (float) quaternion carries a tiny rounding error (~1e-4 in the off-diagonal terms)
    # that is amplified by the ~128-voxel center offset, so a slightly larger tolerance is used
    # here than for the exact s-form path.
    @test mgh_header.is_ras_good == 1
    @test all(isapprox.(mgh_header.delta, [1.0, 1.0, 1.0], atol=0.05))
    @test all(isapprox.(mgh_header.mdc, Base.reshape([-1.,0,0,0,0,-1,0,1,0], (3,3)), atol=0.05))
    @test all(isapprox.(mgh_header.p_xyz_c, [-0.5, 29.4, -48.9], atol=0.1))

    vox2ras = mgh_vox2ras(Mgh(mgh_header, zeros(UInt8, 1, 1, 1, 1)))
    @test all(isapprox.(vox2ras, expected_vox2ras, atol=0.1))
end


@testset "fs_nifti.jl: write an MGH file as NIfTI matching the FreeSurfer reference" begin

    mgh = read_mgh(MGH_FILE)
    tf = tempname() * ".nii"
    write_nifti(tf, mgh)

    # Reading back the file we wrote (big-endian) must give the same volume.
    nii_re = read_nifti(tf)
    @test nii_re.data == mgh.data
    @test nii_re.header.dtype == mgh.header.dtype
    @test all(isapprox.(mgh_vox2ras(nii_re), expected_vox2ras, atol=0.05))

    # And the header we wrote must match the FreeSurfer reference file.
    h = read_nifti_header(tf)
    @test String(h.magic) == "n+1\0"
    @test h.sizeof_hdr == 348
    @test h.sform_code == 1
    @test h.qform_code == 1
    @test all(isapprox.(h.srow_x, [-1.0, 0.0, 0.0, 127.5], atol=0.05))
    @test all(isapprox.(h.srow_y, [0.0, 0.0, 1.0, -98.6273], atol=0.05))
    @test all(isapprox.(h.srow_z, [0.0, -1.0, 0.0, 79.0953], atol=0.05))
    @test all(isapprox.([h.qoffset_x, h.qoffset_y, h.qoffset_z],
                        [127.5, -98.6273, 79.0953], atol=0.05))
    @test h.pixdim[1] == -1.0

    # The voxel data of the file we wrote starts at vox_offset.
    @test h.vox_offset == 352.0

    rm(tf)
end


@testset "fs_nifti.jl: write and re-read gzip-compressed NIfTI" begin

    mgh = read_mgh(MGH_FILE)
    tf = tempname() * ".nii.gz"
    write_nifti(tf, mgh)
    @test NeuroFormats.FreeSurfer._is_file_gzipped(tf)

    nii_re = read_nifti(tf)
    @test nii_re.data == mgh.data
    @test all(isapprox.(mgh_vox2ras(nii_re), expected_vox2ras, atol=0.05))

    h = read_nifti_header(tf)
    @test all(isapprox.(h.srow_x, [-1.0, 0.0, 0.0, 127.5], atol=0.05))

    rm(tf)
end


@testset "fs_nifti.jl: writing an MGH volume without RAS info yields no geometry" begin

    # Build a tiny MGH header without any RAS information.
    header = MghHeader(1, 2, 3, 4, 1, 0, 0, 0, Float32[1, 1, 1],
                       zeros(Float32, 3, 3), zeros(Float32, 3))
    data = zeros(UInt8, 2, 3, 4, 1)
    mgh = Mgh(header, data)

    tf = tempname() * ".nii"
    write_nifti(tf, mgh)
    h = read_nifti_header(tf)
    @test h.sform_code == 0
    @test h.qform_code == 0
    @test all(isapprox.(h.srow_x, [0.0, 0.0, 0.0, 0.0], atol=0.05))

    # Reading it back must round-trip the voxel data.
    mgh_re = read_nifti(tf)
    @test size(mgh_re.data) == (2, 3, 4, 1)
    @test mgh_re.data == data
    @test mgh_re.header.is_ras_good == 0

    rm(tf)
end
