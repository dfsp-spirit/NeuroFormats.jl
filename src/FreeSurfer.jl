module FreeSurfer

using Printf

export read_curv, write_curv, read_fs_surface, num_vertices, num_faces, export_to_obj, read_fs_label, read_fs_annot, FsAnnot, ColorTable, regions, vertex_regions, region_vertices

include("./utils.jl")
include("./fs_common.jl")
include("./fs_curv.jl")
include("./fs_surface.jl")
include("./fs_label.jl")
include("./fs_annot.jl")

end
