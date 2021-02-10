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

    # TODO: test RAS data

    # Test data.
    @test Base.ndims(mgh.data) == 4
    @test mgh.data[100, 100, 100, 1] == 77   # try on command line: mri_info --voxel 99 99 99 test/data/subjects_dir/subject1/mri/brain.mgz
    @test mgh.data[110, 110, 110, 1] == 71
    @test mgh.data[1, 1, 1, 1] == 0
end