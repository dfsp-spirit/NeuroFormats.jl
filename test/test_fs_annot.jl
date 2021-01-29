# Tests for reading FreeSurfer annotation data.

using DataFrames

@testset "Read a FreeSurfer annotation" begin
    
    ANNOT_FILE = joinpath(get_testdata_dir(), "subjects_dir/subject1/label/lh.aparc.annot")
    fs_annot = read_fs_annot(ANNOT_FILE)

    @test typeof(fs_annot.colortable) == NeuroFormats.FreeSurfer.ColorTable
end
