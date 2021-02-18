# Functions for reading FreeSurfer annotation data for brain surfaces.

import Base.show
using Colors

""" Models the brain region table included in an [`FsAnnot`](@ref) FreeSurfer annotation. Each entry describes a brain region, which has a running numerical id, a name, a display color (r,g,b), and a unique integer label (computed from the color code) which is used in the corresponding [`FsAnnot`](@ref) to identify the region of a vertex. """
struct ColorTable
    id::Array{Int32, 1} # region index, not really needed. The label is relevant, see below.
    name::Array{AbstractString, 1}
    r::Array{Int32, 1}
    g::Array{Int32, 1}
    b::Array{Int32, 1}
    a::Array{Int32, 1}
    label::Array{Int32, 1}  # a unique label computed from r,g,b. Used in annot.vertex_labels to identify the region.
end


""" Models a FreeSurfer brain surface parcellation from an annot file. This is the result of applying a brain atlas (like Desikan-Killiani) to a subject. The `vertex_indices` are the 0-based indices used in FreeSurfer and should be ignored. The `vertex_labels` field contains the mesh vertices in order, and assigns to each vertex a brain region using the `label` field (not the `id` field!) from the `colortable`. The field `colortable` contains a [`ColorTable`](@ref) struct that describes the brain regions. """
struct FsAnnot
    vertex_indices::Array{Int32,1} # 0-based indices, not really needed.
    vertex_labels::Array{Int32,1}
    colortable::ColorTable
end

Base.show(io::IO, x::FsAnnot) = @printf("Brain surface parcellation for %d vertices containing %d regions.\n", Base.length(x.vertex_indices), Base.length(x.colortable.id))

"""
    regions(annot::FsAnnot)

Return the brain region names of the [`FsAnnot`](@ref) surface annotation.

# Examples
```julia-repl
julia> annot_file = joinpath(tdd(), "subjects_dir/subject1/label/lh.aparc.annot");
julia> annot = read_annot(annot_file);
julia> regions(annot) # show all regions
``` 
"""
regions(annot::FsAnnot) = annot.colortable.name


"""
    vertex_regions(annot::FsAnnot)

Compute the region names for all vertices in an [`FsAnnot`](@ref) brain surface parcellation.

# Examples
```julia-repl
julia> annot_file = joinpath(tdd(), "subjects_dir/subject1/label/lh.aparc.annot");
julia> annot = read_annot(annot_file);
julia> vertex_regions(annot) # show for each vertex the brain region it is part of.
``` 
"""
function vertex_regions(annot::FsAnnot)
    vrc = Array{String,1}(undef, Base.length(annot.vertex_indices))
    for region in regions(annot)
        region_idx = findfirst(x -> (x == region), annot.colortable.name)
        region_label = annot.colortable.label[region_idx]
        region_vertices = findall(region_label .== annot.vertex_labels)
        vrc[region_vertices] .= region
    end
    return(vrc)
end


"""
   vertex_colors(annot::FsAnnot)

Compute the vertex colors for all vertices in an [`FsAnnot`](@ref) brain surface parcellation. This function returns an Array{Colors.RBG, 1} of colors. See the Colors package for details. Useful for plotting the annotation.

Examples
```julia-repl
julia> annot_file = joinpath(tdd(), "subjects_dir/subject1/label/lh.aparc.annot");
julia> annot = read_annot(annot_file);
julia> vertex_colors(annot) # show the color for each vertex.
``` 
"""
function vertex_colors(annot::FsAnnot)
   vc = Array{Colors.RGB,1}(undef, Base.length(annot.vertex_indices))
   for region in regions(annot)
       region_idx = findfirst(x -> (x == region), annot.colortable.name)
       region_label = annot.colortable.label[region_idx]
       region_color = Colors.RGB(annot.colortable.r[region_idx]/255., annot.colortable.g[region_idx]/255., annot.colortable.b[region_idx]/255.)
       region_vertices = findall(region_label .== annot.vertex_labels)
       vc[region_vertices] .= region_color
   end
   return(vc)
end



""" 
    region_vertices(annot::FsAnnot, region::String)

Get all vertices of a region in an [`FsAnnot`](@ref) brain surface parcellation. Returns an integer vector, the vertex indices.

# Examples
```julia-repl
julia> annot_file = joinpath(tdd(), "subjects_dir/subject1/label/lh.aparc.annot");
julia> annot = read_annot(annot_file);
julia> region_vertices(annot, "bankssts") # show all vertices which are part of bankssts region.
``` 
"""
function region_vertices(annot::FsAnnot, region::String)
    region_idx = findfirst(x -> (x == region), annot.colortable.name)
    region_label = annot.colortable.label[region_idx]
    region_vertices = findall(region_label .== annot.vertex_labels)
    return(region_vertices)
end


"""
    label_from_rgb(r::Integer, g::Integer, b::Integer, a::Integer=0)

Compute the label from the color code of an [`FsAnnot`](@ref) brain region. Returns an integer, the label code.

# Examples
```julia-repl
julia> annot_file = joinpath(tdd(), "subjects_dir/subject1/label/lh.aparc.annot");
julia> annot = read_annot(annot_file);
julia> label_from_rgb(annot.colortable.r[1], annot.colortable.g[1], annot.colortable.b[1])
``` 
"""
label_from_rgb(r::Integer, g::Integer, b::Integer, a::Integer=0) = r + g*2^8 + b*2^16 + a*2^24


"""
    read_annot(file::AbstractString)

Read a FreeSurfer brain parcellation from an annot file. A brain parcellation divides the cortex into a set of
non-overlapping regions, based on a brain atlas. FreeSurfer parcellations assign a region label and a color to
each vertex of the mesh representing the reconstructed cortex.

See also: [`read_surf`](@ref) to read the mesh that belongs the parcellation, and [`read_curv`](@ref) to read per-vertex
data for the mesh or brain region vertices. Also see the convenience functions [`regions`](@ref), [`region_vertices`](@ref), [`label_from_rgb`](@ref), [`vertex_colors`](@ref) 
and [`vertex_regions`](@ref) to work with `FsAnnot` structs.

Returns an [`FsAnnot`](@ref) struct.

# Examples
```julia-repl
julia> annot_file = joinpath(tdd(), "subjects_dir/subject1/label/lh.aparc.annot");
julia> annot = read_annot(annot_file);
julia> regions(annot)
julia> Base.length(region_vertices(annot, "bankssts")) # show vertex count of bankssts brain region.
```
"""
function read_annot(file::AbstractString)
    file_io = open(file, "r")
    num_vertices = Int32(hton(read(file_io, Int32)))

    # The data is saved as a vertex index followed by its label label. This is repeated for all vertices.
    vertices_and_labels_raw = _read_vector_endian(file_io, Int32, num_vertices * 2, endian="big")

    # Separate vertices from labels
    vertices = vertices_and_labels_raw[[1:2:Base.length(vertices_and_labels_raw);]]
    labels = vertices_and_labels_raw[[2:2:Base.length(vertices_and_labels_raw);]]

    has_ColorTable = Int32(hton(read(file_io, Int32)))
    if has_ColorTable == 1
        num_ColorTable_entries = Int32(hton(read(file_io, Int32)))
        if num_ColorTable_entries > 0
            error("Old ColorTable format in annot files not supported yet. Please open an issue and attach a sample file if you need this.")
        else
            # If num_ColorTable_entries is negative, it is a version label (actually, the abs value is the version).
            ctable_format_version = -num_ColorTable_entries
            if ctable_format_version == 2
                num_ColorTable_entries = Int32(hton(read(file_io, Int32)))
                ColorTable = _read_annot_colortable(file_io, num_ColorTable_entries)
            else
                error("Unsupported ColorTable format version, only version 2 is supported.")
            end
        end
    else
        error("Annotation file does not contain a ColorTable.")
    end
    fs_annot = FsAnnot(vertices, labels, ColorTable)
    return(fs_annot)
end


""" Read regiontable/colortable in new format from binary FreeSurfer annot file. """
function _read_annot_colortable(file_io::IO, num_ColorTable_entries::Int32)
    num_chars_orig_filename = Int32(hton(read(file_io, Int32)))
    seek(file_io, Base.position(file_io) + num_chars_orig_filename) # skip over useless file name.
    num_ColorTable_entries_duplicated = Int32(hton(read(file_io, Int32))) # number of entries is stored twice. don't ask me.

    id::Array{Int32, 1} = zeros(num_ColorTable_entries)
    name::Array{String, 1} = similar(id, String)
    r::Array{Int32, 1} = zeros(num_ColorTable_entries)
    g::Array{Int32, 1} = zeros(num_ColorTable_entries)
    b::Array{Int32, 1} = zeros(num_ColorTable_entries)
    a::Array{Int32, 1} = zeros(num_ColorTable_entries)
    label::Array{Int32, 1} = zeros(num_ColorTable_entries)

    for idx in [1:num_ColorTable_entries;]
        id[idx] = Int32(hton(read(file_io, Int32))) + 1
        entry_num_chars::Int32 = Int32(hton(read(file_io, Int32)))
        name[idx] = _read_fixed_length_string(file_io, entry_num_chars)

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
