module FreeSurfer

using Printf

export read_curv, write_curv, Curv, CurvHeader
export read_surf, num_vertices, num_faces, export_to_obj, BrainMesh, FsSurface, FsSurfaceHeader
export read_label
export read_annot, FsAnnot, ColorTable, regions, vertex_regions, region_vertices, label_from_rgb

include("./utils.jl")
include("./fs_common.jl")
include("./fs_curv.jl")
include("./fs_surface.jl")
include("./fs_label.jl")
include("./fs_annot.jl")

end
