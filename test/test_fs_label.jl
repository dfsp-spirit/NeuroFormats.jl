
using DataFrames

@testset "A FreeSurfer surface label file can be read" begin
    
    LABEL_FILE = joinpath(get_testdata_dir(), "subjects_dir/subject1/label/lh.entorhinal_exvivo.label")
    fs_label = read_label(LABEL_FILE)

    @test typeof(fs_label) == DataFrames.DataFrame
    @test Base.length(fs_label[!, "vertex_index"]) == 1085
    @test fs_label[!, "vertex_index"][1] == 88791
    @test fs_label[!, "vertex_index"][1085] == 149165
end
