using NeuroFormats
using Test

import Base.length, Base.maximum, Base.minimum, Base.fieldcount

# The easiest way to run these tests with the current version of your code
# seems to be the following one:
# - start a JULIA interpreter with `cd develop/NeuroFormats.jl; julia --project=.`, then:
# - run: `using Pkg; Pkg.test("NeuroFormats");`

# Common utility tests
include("./test_utils.jl")

# FreeSurfer tests
include("./test_fs_common.jl")
include("./test_fs_curv.jl")
include("./test_fs_surface.jl")
include("./test_fs_label.jl")
include("./test_fs_annot.jl")
include("./test_fs_mgh.jl")

# DTI tests
include("./test_dti_trk.jl")
include("./test_dti_tck.jl")
