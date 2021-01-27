# Illustrates how to load a FreeSurfer brain mesh and export it to Wavefront Object format.
# You can open the result in Blender or other standard 3D modeling software.

using NeuroFormats

BRAIN_MESH_FILE = joinpath(ENV["HOME"], "develop/NeuroFormats.jl/test/data/subjects_dir/subject1/surf/lh.white")
surface = read_fs_surface(BRAIN_MESH_FILE)
export_to_obj(joinpath(ENV["HOME"], "brain.obj"), surface.mesh)

