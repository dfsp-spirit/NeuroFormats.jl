# Functions for reading FreeSurfer annotation data.

""" Models the colortable included in a FreeSurfer annotation. """
struct ColorTable
    id::Array{Int32, 1}
    name::Array{AbstractString, 1}
    r::Array{Int32, 1}
    g::Array{Int32, 1}
    b::Array{Int32, 1}
    a::Array{Int32, 1}
    label::Array{Int32, 1}
end


""" Models a FreeSurfer brain surface parcellation from an annot file. """
struct FsAnnot
    vertex_indices::Array{Int32,1}
    vertex_labels::Array{Int32,1}
    colortable::ColorTable
end


"""
    read_fs_annot(file::AbstractString)

Read a FreeSurfer brain parcellation from an annot file. A brain parcellation divides the cortex into a set of
non-overlapping regions, based on a brain atlas. FreeSurfer parcellations assign a region code and a color to
each vertex of the mesh representing the reconstructed cortex.

See also: [`read_surf`] to read the mesh that belongs the parcellation, and [`read_curv`] to read per-vertex
data for the mesh or brain region vertices.
"""
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


""" Read colortable in new format from binary FreeSurfer annot file. """
function read_fs_annot_colortable(file_io::IO, num_colortable_entries::Int32)
    num_chars_orig_filename = Int32(hton(read(file_io, Int32)))
    seek(file_io, Base.position(file_io) + num_chars_orig_filename) # skip over useless file name.
    num_colortable_entries_duplicated = Int32(hton(read(file_io, Int32))) # number of entries is stored twice. don't ask me.

    id::Array{Int32, 1} = zeros(num_colortable_entries)
    name::Array{String, 1} = similar(id, String)
    r::Array{Int32, 1} = zeros(num_colortable_entries)
    g::Array{Int32, 1} = zeros(num_colortable_entries)
    b::Array{Int32, 1} = zeros(num_colortable_entries)
    a::Array{Int32, 1} = zeros(num_colortable_entries)
    label::Array{Int32, 1} = zeros(num_colortable_entries)

    for idx in [1:num_colortable_entries;]
        id[idx] = Int32(hton(read(file_io, Int32))) + 1
        entry_num_chars::Int32 = Int32(hton(read(file_io, Int32)))
        name_bytes = Array{UInt8,1}(zeros(entry_num_chars))
        readbytes!(file_io, name_bytes)
        name[idx] = String(name_bytes)
        if(Base.endswith(name[idx], "\0")) # strip trailing "\0"
            name[idx] = name[idx][1:(Base.length(name[idx])-1)]
        end

        # Read color information.
        r[idx] = Int32(hton(read(file_io, Int32)))
        g[idx] = Int32(hton(read(file_io, Int32)))
        b[idx] = Int32(hton(read(file_io, Int32)))
        a[idx] = Int32(hton(read(file_io, Int32)))
        label[idx] = r[idx] + g[idx]*2^8 + b[idx]*2^16 + a[idx]*2^24
    end
    ct = ColorTable(id, name, r, g, b, a, label)
    return ct
end
