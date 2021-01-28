module FreeSurfer

using Printf

export read_curv, write_curv, read_fs_surface, num_vertices, num_faces, export_to_obj

include("./utils.jl")
include("./fs_common.jl")
include("./fs_curv.jl")
include("./fs_surface.jl")

end
