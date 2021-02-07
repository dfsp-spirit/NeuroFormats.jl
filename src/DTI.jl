module DTI

export read_trk, DtiTrk, DtiTrkHeader
export read_tck, DtiTck, DtiTrack

include("./utils.jl")
include("./dti_trk.jl")
include("./dti_tck.jl")

end
