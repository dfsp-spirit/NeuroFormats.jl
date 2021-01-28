# Functions for reading FreeSurfer annotation data.

using DataFrames.DataFrame


struct FsAnnot
    vertex_indices::Array{Int32,1}
    vertex_labels::Array{Int32,1}
    colortable::DataFrame
end


function read_fs_annot(file::AbstractString)
    file_io = open(file, "r")
    num_vertices = Int32(hton(read(file_io, Int32)))

    # The data is saved as a vertex index followed by its label code. This is repeated for all vertices.
    vertices_and_labels_raw::Array{Int32,1} = reinterpret(Int32, read(file_io, sizeof(Int32) * num_vertices * 2))
    vertices_and_labels_raw .= ntoh.(vertices_and_labels_raw)

    # Separate vertices from labels
    vertices = vertices_and_labels_raw[[1:2:Base.length(vertices_and_labels_raw);]]
    labels = vertices_and_labels_raw[[2:2:Base.length(vertices_and_labels_raw);]]

    has_colortable = Int32(hton(read(file_io, Int32)))
    if has_colortable == 1
        num_colortable_entries = Int32(hton(read(file_io, Int32)))
        if num_colortable_entries > 0
            error("Old colortable format in annot files not supported yet. Please open an issue and attach a sample file if you need this.")
        else
            # If num_colortable_entries is negative, it is a version code (actually, the abs value is the version).
            ctable_format_version = -num_colortable_entries
            if ctable_format_version == 2
                num_colortable_entries = Int32(hton(read(file_io, Int32)))
                # TODO: read new format colortable here
                colortable = read_fs_annot_colortable(file_io, num_colortable_entries)
            else
                error("Unsupported colortable format version, only version 2 is supported.")
            end
        end
    else
        error("Annotation file does not contain a colortable.")
    end
    fs_annot = FsAnnot(vertices, labels, colortable)
    return(fs_annot)
end


function read_fs_annot_colortable(file_io::IO, num_colortable_entries::Int32)

end
