# Tests for reading FreeSurfer annotation data.


@testset "Read a FreeSurfer annotation" begin
    
    ANNOT_FILE = joinpath(get_testdata_dir(), "subjects_dir/subject1/label/lh.aparc.annot")
    fs_annot = read_fs_annot(ANNOT_FILE)

    @test Base.length(fs_annot.vertex_indices) == 149244
    @test Base.length(fs_annot.vertex_labels) == 149244

    @test typeof(fs_annot.colortable) == NeuroFormats.FreeSurfer.ColorTable
    @test fs_annot.colortable.name[1] == "unknown"
    @test fs_annot.colortable.name[2] == "bankssts"

    @test Base.length(regions(fs_annot)) == 36
    @test Base.length(region_vertices(fs_annot, "bankssts")) == 1722
    @test Base.length(vertex_regions(fs_annot)) == 149244
end
