# Tests for reading FreeSurfer annotation data.


@testset "Read a FreeSurfer annotation and compute properties" begin

    ANNOT_FILE = joinpath(Base.source_dir(), "data/subjects_dir/subject1/label/lh.aparc.annot")
    fs_annot = read_annot(ANNOT_FILE)

    @test Base.length(fs_annot.vertex_indices) == 149244
    @test Base.length(fs_annot.vertex_labels) == 149244

    @test typeof(fs_annot.colortable) == NeuroFormats.FreeSurfer.ColorTable
    @test fs_annot.colortable.name[1] == "unknown"
    @test fs_annot.colortable.name[2] == "bankssts"

    @test fs_annot.colortable.r[1] == 25
    @test fs_annot.colortable.g[1] == 5
    @test fs_annot.colortable.b[1] == 25
    @test fs_annot.colortable.a[1] == 0
    @test fs_annot.colortable.label[1] == 1639705

    @test Base.length(regions(fs_annot)) == 36
    @test Base.length(region_vertices(fs_annot, "bankssts")) == 1722
    @test Base.length(vertex_regions(fs_annot)) == 149244

    @test label_from_rgb(fs_annot.colortable.r[1], fs_annot.colortable.g[1], fs_annot.colortable.b[1]) == fs_annot.colortable.label[1]
end


@testset "Derive per-vertex color information from a FreeSurfer annotation" begin

    ANNOT_FILE = joinpath(Base.source_dir(), "data/subjects_dir/subject1/label/lh.aparc.annot")
    fs_annot = read_annot(ANNOT_FILE)

    @test Base.length(vertex_colors(fs_annot)) == 149244
end


@testset "Write and re-read a FreeSurfer annotation (roundtrip)" begin

    ANNOT_FILE = joinpath(Base.source_dir(), "data/subjects_dir/subject1/label/lh.aparc.annot")
    annot_orig = read_annot(ANNOT_FILE)

    tf = string(tempname(), ".annot")
    write_annot(tf, annot_orig)
    @test Base.isfile(tf)

    annot_read = read_annot(tf)

    # Compare vertex data
    @test annot_read.vertex_indices == annot_orig.vertex_indices
    @test annot_read.vertex_labels == annot_orig.vertex_labels

    # Compare ColorTable
    @test annot_read.colortable.id == annot_orig.colortable.id
    @test annot_read.colortable.name == annot_orig.colortable.name
    @test annot_read.colortable.r == annot_orig.colortable.r
    @test annot_read.colortable.g == annot_orig.colortable.g
    @test annot_read.colortable.b == annot_orig.colortable.b
    @test annot_read.colortable.a == annot_orig.colortable.a
    @test annot_read.colortable.label == annot_orig.colortable.label

    # Verify the high-level API still works on the re-read data
    @test Base.length(regions(annot_read)) == 36
    @test Base.length(region_vertices(annot_read, "bankssts")) == 1722
end
