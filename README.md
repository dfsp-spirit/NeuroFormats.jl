# NeuroFormats.jl

Handling of structural neuroimaging file formats for [Julia](https://julialang.org).


## About

In the NeuroFormats package, we will provide an API for reading structural neuroimaging data files in Julia. The focus will be on surface-based data, as produced by [FreeSurfer](https://freesurfer.net). The aim of the package is to allow scientists to access their neuroimaging data in Julia so they can use the language's power to implement custom data analysis pipelines.

Note that some functions for reading neuroimaging data files are available from [JuliaNeuroscience](https://github.com/JuliaNeuroscience), e.g., NIFTI volume and GIFTI mesh support. This package does not duplicate these functionalities.

## Features

* Read and write FreeSurfer per-vertex data in curv format (like `subject/surf/lh.thickness`): functions `read_curv()` and `write_curv()`
* Read brain meshes in FreeSurfer binary mesh format (like `subject/surf/lh.white`): `read_surf()`
* Read FreeSurfer label files (like `subject/label/lh.cortex.label`): `read_label()`
* Read FreeSurfer brain surface parcellations (like `subject/label/lh.aparc.annot`): `read_annot()`
* Read FreeSurfer MGH brain volumes (4D voxel images, like `subject/mri/brain.mgz`): `read_mgh()`
* Read DTI track data from MRtrix3 TCK files: `read_tck()`
* Read DTI track data from DiffusionToolkit TRK files: `read_trk()`


## Installation

You can find [NeuroFormats on JuliaHub](https://juliahub.com/ui/Packages/NeuroFormats/zxLcF/), so all you need to do is:

```julia
Pkg.add("NeuroFormats")
```

from a Julia session.


## Documentation

The documentation is included with the package and can be [browsed online at JuliaHub](https://juliahub.com/docs/NeuroFormats/zxLcF/0.2.1/). It is not repeated on this website.

Also keep in mind that you can always get help on a function named `read_curv` from within Julia by typing `?read_curv`. The [unit tests of this package](./test/) are essentially a collection of usage examples.


## Usage Examples

### Example 1: Cortical thickness on a brain mesh

This example shows how to load a FreeSurfer brain mesh with per-vertex data and visualize it in Julia using GLMakie:

```julia
using NeuroFormats
using GLMakie

# This uses the demo MRI data that comes with NeuroFormats, feel free to use your own FreeSurfer data.
fs_subject_dir = joinpath(tdd(), "subjects_dir/subject1/")

surf = read_surf(joinpath(fs_subject_dir, "surf/lh.white")) # The brain mesh.

# An Array{Float32, 1} with your cortical thickness data:
curv = read_curv(joinpath(fs_subject_dir, "surf/lh.thickness"))

vertices = surf.mesh.vertices
faces = surf.mesh.faces .+ 1

scene = mesh(vertices, faces, color = curv)
```

![Vis](./examples/julia_brainplot_NeuroFormats.png?raw=true "A 3D brain visualization created in Julia.")


### Example 2: An MRI volume

This example loads a 3D MRI scan of a brain and visualizes it.

```julia
using NeuroFormats
using GLMakie

mgh = read_mgh(joinpath(tdd(), "subjects_dir/subject1/mri/brain.mgz"))
volume = dropdims(mgh.data, dims = 4) # drop time dimension, we only have one frame here.

axis = range(0, stop = 1, length = size(volume, 1))
scene3d = contour(axis, axis, axis, volume, alpha = 0.1, levels = 6)
```

## Development

### License

NeuroFormats is free software published under the GPL v3, see the [LICENSE file](./LICENSE) for the full license.


### Unit tests and continuous integration

Continuous integration results:

[![Build Status](https://travis-ci.org/dfsp-spirit/NeuroFormats.jl.svg?branch=main)](https://travis-ci.org/dfsp-spirit/NeuroFormats.jl) Travis CI under Linux


### Contributing

If you found a bug, have any question, suggestion or comment on freesurferformats, please [open an issue](https://github.com/dfsp-spirit/NeuroFormats.jl/issues). I will definitely answer and try to help.

Please see [CONTRIBUTING.md](CONTRIBUTING.md) for instructions on how to contribute code.

The NeuroFormats package was written by [Tim Schäfer](http://rcmd.org/ts/). To contact me in person, please use the email address given on my website.
