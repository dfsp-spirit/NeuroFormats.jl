
module NeuroFormats

using Reexport

"""
    NeuroFormats.MAX_ALLOCATION_BYTES

A module-level `Ref{Int64}` controlling the maximum allowed memory allocation (in bytes) when
reading a single file. Defaults to 1 GiB (1024³ bytes).  Use [`set_max_allocation!`](@ref) to
change it.
"""
const MAX_ALLOCATION_BYTES = Ref{Int64}(1024^3)

"""
    set_max_allocation!(bytes::Integer)

Set the maximum allowed memory allocation per file (in bytes).  When a file header requests an
allocation larger than this limit, reading is aborted with an error.  The default is 1 GiB.

# Examples
```julia-repl
julia> NeuroFormats.set_max_allocation!(2 * 1024^3)  # raise to 2 GiB
```
"""
function set_max_allocation!(bytes::Integer)
    if bytes <= 0
        error("Maximum allocation must be positive, got $bytes.")
    end
    MAX_ALLOCATION_BYTES[] = Int64(bytes)
end

"""
    get_max_allocation()

Return the current maximum allowed memory allocation per file (in bytes).

# Examples
```julia-repl
julia> NeuroFormats.get_max_allocation()
1073741824
```
"""
get_max_allocation() = MAX_ALLOCATION_BYTES[]

include("./utils.jl")
export tdd
export set_max_allocation!, get_max_allocation

include("./FreeSurfer.jl")
using .FreeSurfer
@reexport using .FreeSurfer

include("./DTI.jl")
using .DTI
@reexport using .DTI

end # module
