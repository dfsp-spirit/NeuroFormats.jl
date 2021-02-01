
module NeuroFormats

using Reexport

include("./utils.jl")
export read_variable_length_string

include("./FreeSurfer.jl")
using .FreeSurfer
@reexport using .FreeSurfer

include("./DTI.jl")
using .DTI
@reexport using .DTI

end # module
