# Tests for reading FreeSurfer MGH and MGZ files.


@testset "Read a 3D/4D FreeSurfer MGH file." begin
    
    MGH_FILE = joinpath(get_testdata_dir(), "subjects_dir/subject1/mri/brain.mgz")
    mgh = read_mgh(MGH_FILE)

    @test Base.length(mgh.header.dims) == 4
end