
# Methods for reading FreeSurfer curv files containing per-vertex data for brain surface models (meshes).
# A typical example would be cortical thickness data for the left hemisphere in '$SUBJECT/surf/lh.thickness'. These files have no file extension.

module FreeSurfer

using Mmap

import Base.getindex, Base.size, Base.length
export curvread


mutable struct CurvHeader
    curv_magic::Int24
    num_vertices::Int32
    num_faces::Int32
    values_per_vertex::Int32
end

const CURV_MAGIC_HEADER = 16777215;


# Read header from a Curv file
function read_curv_header(io::IO)
    header = read(io, CurvHeader)
    if header.curv_magic != CURV_MAGIC_HEADER
        error("This is not a binary FreeSurfer Curv file: header magic code mismatch.")
    end
    header
end

end # module
