# Tests for reading FreeSurfer MGH and MGZ files.


@testset "Read a 3D/4D FreeSurfer MGH file." begin
    
    MGH_FILE = joinpath(get_testdata_dir(), "subjects_dir/subject1/mri/brain.mgz")
    mgh = read_mgh(MGH_FILE)

    @test mgh.header.mgh_version == 1
    @test mgh.header.ndim1 == 256
    @test mgh.header.ndim2 == 256
    @test mgh.header.ndim3 == 256
    @test mgh.header.ndim4 == 1
    @test mgh.header.dtype == 0 # MRI_UCHAR
    @test mgh.header.dof == 0
    @test mgh.header.is_ras_good == 1

end