module FreeSurfer

using Printf

export read_fs_int24, interpret_fs_int24, read_curv, write_curv

include("./fs_common.jl")
include("./fs_curv.jl")

end
