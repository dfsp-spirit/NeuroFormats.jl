module FreeSurfer

using Printf

export read_curv, write_curv, read_fs_surface, num_vertices, num_faces, export_to_obj, read_fs_label

include("./utils.jl")
include("./fs_common.jl")
include("./fs_curv.jl")
include("./fs_surface.jl")
include("./fs_label.jl")

end
