# Read FreeSurfer ASCII label files. A label contains a set of vertex or voxel indices (some brain region, note though
# that the vertices must not be adjacent: the region can consist of several patches). It can also assign a value
# to each vertex/voxel. Sometimes the values are all left at zero, typically this is the case when one only wants to
# store the vertex/voxel indices (e.g., because they make up some region of interest).
#
# There seems to be no definite way to tell whether a label file contains a volume label (voxel indices) or a surface
# label (vertices). But it seems that if your label contains negative indices, it has to be a volume label.
#
# Note that we use surface label terminology to refer to the fields, but what is called 'vertex_indices' below may mean
# 'voxel_indices' in case of a volume label.

using CSV
using DataFrames

"""
     read_label(file::AbstractString)

Read a FreeSurfer ASCII label file and return the contents as a DataFrame. Both surface labels and volume labels are supported.

A label contains a set of vertex or voxel indices (some brain region, note though that the vertices must not be adjacent: the region
can consist of several patches). It can also assign a value to each vertex/voxel. Sometimes the values are all left at zero, typically
this is the case when one only wants to store the vertex/voxel indices (e.g., because they make up some region of interest). There seems
to be no definite way to tell whether a label file contains a volume label (voxel indices) or a surface label (vertices). But it seems
that if your label contains negative indices, it has to be a volume label.

Note that we use surface label terminology in the code to refer to the fields, but what is called 'vertex_indices' below may mean
'voxel_indices' in case of a volume label.

Returns a `DataFrames.DataFrame`.

# Examples
```julia-repl
julia> label_file = joinpath(tdd(), "subjects_dir/subject1/label/lh.entorhinal_exvivo.label");
julia> label = read_label(label_file);
julia> sum(label[!, "value"])
```

"""
function read_label(file::AbstractString)
    # The first line is a comment, and the 2nd one contains a single number: the number of vertex lines following.
    csv_element_count_reader = CSV.File(file; header=["vertex_count"], delim=" ", ignorerepeated=true, skipto=2, limit=1, types=[Int32], comment="#")
    num_vertices = csv_element_count_reader[1][1] # first row, first column.

    # Now that we know the line count, read those lines:
    column_names = ["vertex_index", "coord1", "coord2", "coord3", "value"]
    column_types = [Int32, Float32, Float32, Float32, Float32]
    csv_data_reader = CSV.File(file; header=column_names, delim=" ", ignorerepeated=true, skipto=3, limit=num_vertices, types=column_types, comment="#")

    df = DataFrame(csv_data_reader)
    return df
end

"""
     write_label(file::AbstractString, label::DataFrame)

Write a FreeSurfer label to an ASCII label file.

A label contains a set of vertex or voxel indices (some brain region, note though that the vertices must not be adjacent: the region
can consist of several patches). It can also assign a value to each vertex/voxel. Sometimes the values are all left at zero, typically
this is the case when one only wants to store the vertex/voxel indices (e.g., because they make up some region of interest). There seems
to be no definite way to tell whether a label file contains a volume label (voxel indices) or a surface label (vertices). But it seems
that if your label contains negative indices, it has to be a volume label.

Note that we use surface label terminology in the code to refer to the fields, but what is called 'vertex_indices' below may mean
'voxel_indices' in case of a volume label.

The input 'label' must be a DataFrame with the following columns:
- vertex_index: the vertex index (or voxel index) of the vertex/voxel in the label. Read as datatype int32.
- coord1: the x coordinate of the vertex/voxel in the label. Read as datatype float32.
- coord2: the y coordinate of the vertex/voxel in the label. Read as datatype float32.
- coord3: the z coordinate of the vertex/voxel in the label. Read as datatype float32.
- value: the value assigned to the vertex/voxel in the label. Read as datatype float32. If not relevant, set to 0.0.

# Examples
```julia-repl
julia> label_file = joinpath(tdd(), "subjects_dir/subject1/label/lh.entorhinal_exvivo.label");
julia> label = read_label(label_file);
julia> sum(label[!, "value"])
julia> write_label(joinpath(tdd(), "out.label"), label);
```

"""
function write_label(file::AbstractString, label::DataFrame)
    open(file, "w") do f
        write(f, "#!ascii label file exported from Julia using NeuroFormats.jl\n")
        write(f, string(size(label, 1)), "\n") # number of vertices
        # the columns in order are "vertex_index, x, y, z, value\n")
        for i in 1:size(label, 1)
            write(f, string(label[i, "vertex_index"]), " ", string(label[i, "coord1"]), " ", string(label[i, "coord2"]), " ", string(label[i, "coord3"]), " ", string(label[i, "value"]), "\n")
        end
    end
end
