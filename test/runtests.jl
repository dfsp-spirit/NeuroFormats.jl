using NeuroFormats
using Test

import Base.length, Base.maximum, Base.minimum, Base.fieldcount

# The easiest way to run these tests with the current version of your code
# seems to be the following one:
# - start a JULIA interpreter, then:
# - run: `using Pkg; Pkg.test("NeuroFormats");` 


include("./utils_for_testing.jl")

include("./test_fs_common.jl")
include("./test_fs_curv.jl")
include("./test_fs_surface.jl")

