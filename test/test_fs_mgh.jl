# Tests for reading FreeSurfer MGH and MGZ files.


@testset "Read a 3D/4D FreeSurfer MGH file." begin
    
    MGH_FILE = joinpath(get_testdata_dir(), "subjects_dir/subject1/mri/brain.mgz")
    mgh = read_mgh(MGH_FILE)

    # Test header.
    @test mgh.header.mgh_version == 1
    @test mgh.header.ndim1 == 256
    @test mgh.header.ndim2 == 256
    @test mgh.header.ndim3 == 256
    @test mgh.header.ndim4 == 1
    @test mgh.header.dtype == 0 # MRI_UCHAR
    @test mgh.header.dof == 0
    @test mgh.header.is_ras_good == 1

    # Teet RAS part of header
    @test all(isapprox.(mgh.header.delta, [1.0, 1.0, 1.0], atol=0.05))
    @test all(isapprox.(mgh.header.mdc, Base.reshape([-1.,0,0,0,0,-1,0,1,0], (3,3))))
    @test all(isapprox.(mgh.header.p_xyz_c, [-0.5, 29.4, -48.9], atol=0.05))

    # Test data.
    @test Base.ndims(mgh.data) == 4
    @test mgh.data[100, 100, 100, 1] == 77   # try on command line: mri_info --voxel 99 99 99 test/data/subjects_dir/subject1/mri/brain.mgz
    @test mgh.data[110, 110, 110, 1] == 71
    @test mgh.data[1, 1, 1, 1] == 0
end


@testset "Compute vox2ras matrix for MGH file." begin
    
    MGH_FILE = joinpath(get_testdata_dir(), "subjects_dir/subject1/mri/brain.mgz")
    mgh = read_mgh(MGH_FILE)
    
    # Use FreeSurfer's `mri_info` command line tool on the brain.mgz file to get this info:
    expected_vox2ras = Base.reshape([-1.,0,0,0, 0,0,-1,0, 0,1,0,0, 127.5,-98.6273,79.0953,1], (4,4))
    
    vox2ras = mgh_vox2ras(mgh)
    @test Base.length(vox2ras) == 16
    @test all(isapprox.(vox2ras, expected_vox2ras, atol=0.05))
end

