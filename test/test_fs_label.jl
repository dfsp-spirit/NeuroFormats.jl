
using DataFrames

@testset "A FreeSurfer surface label file can be read" begin

    LABEL_FILE = joinpath(get_testdata_dir(), "subjects_dir/subject1/label/lh.entorhinal_exvivo.label")
    fs_label = read_label(LABEL_FILE)

    @test typeof(fs_label) == DataFrames.DataFrame
    @test Base.length(fs_label[!, "vertex_index"]) == 1085
    @test fs_label[!, "vertex_index"][1] == 88791
    @test fs_label[!, "vertex_index"][1085] == 149165
end

@testset "A FreeSurfer surface label file can be read, written and re-read" begin

    LABEL_FILE = joinpath(get_testdata_dir(), "subjects_dir/subject1/label/lh.entorhinal_exvivo.label")
    fs_label = read_label(LABEL_FILE)

    @test typeof(fs_label) == DataFrames.DataFrame
    @test Base.length(fs_label[!, "vertex_index"]) == 1085
    @test fs_label[!, "vertex_index"][1] == 88791
    @test fs_label[!, "vertex_index"][1085] == 149165

    tf = tempname()
    write_label(tf, fs_label)
    fs_label_reread = read_label(tf)
    @test typeof(fs_label_reread) == DataFrames.DataFrame
    @test Base.length(fs_label_reread[!, "vertex_index"]) == 1085
    @test fs_label_reread[!, "vertex_index"][1] == 88791
    @test fs_label_reread[!, "vertex_index"][1085] == 149165
end
