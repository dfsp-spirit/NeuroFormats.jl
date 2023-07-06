# NeuroFormats.jl

Handling of structural neuroimaging file formats for [Julia](https://julialang.org).

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.8120740.svg)](https://doi.org/10.5281/zenodo.8120740) [![license](https://img.shields.io/github/license/dfsp-spirit/NeuroFormats.jl.svg)](https://github.com/dfsp-spirit/NeuroFormats.jl/blob/main/LICENSE) ![main](https://github.com/dfsp-spirit/NeuroFormats.jl/actions/workflows/CI.yml/badge.svg?branch=main)


## About

The NeuroFormats package provides an API for reading structural neuroimaging data files in Julia. The focus is on surface-based data, as produced by [FreeSurfer](https://freesurfer.net). The aim of the package is to allow scientists to access their neuroimaging data in Julia so they can use the language's power to implement custom data analysis pipelines.

Note that some functions for reading neuroimaging data files are available from [JuliaNeuroscience](https://github.com/JuliaNeuroscience), e.g., [NIFTI volume](https://github.com/JuliaNeuroscience/NIfTI.jl) and [GIFTI mesh](https://github.com/JuliaNeuroscience/GIFTI.jl) support. This package does not duplicate these functionalities.

This package is not under heavy development anymore, but that does not mean that it is unmaintained. I consider it pretty feature-complete, and the file formats do not change. If you feel this package is missing an important format, please open an issue.

## Features

* Read and write FreeSurfer per-vertex data in curv format (like `subject/surf/lh.thickness`): functions `read_curv()` and `write_curv()`
* Read brain meshes in FreeSurfer binary mesh format (like `subject/surf/lh.white`): `read_surf()`
* Read and write FreeSurfer label files (like `subject/label/lh.cortex.label`): `read_label()` and `write_label()`
* Read FreeSurfer brain surface parcellations (like `subject/label/lh.aparc.annot`): `read_annot()`
* Read and write FreeSurfer MGH and MGZ brain volumes (4D voxel images, like `subject/mri/brain.mgz`): `read_mgh()` and `write_mgh()`
* Read DTI track data from [MRtrix3](https://www.mrtrix.org/) TCK files: `read_tck()`
* Read DTI track data from [DiffusionToolkit](http://trackvis.org/dtk/) TRK files: `read_trk()`


## News

* 2023-07-06: We just released version 0.3.0 of NeuroFormats. This version has been updated for recent Julia versions and works with Julia 1.9. It also adds support for writing label files. See the [CHANGES](./CHANGES) for more details.

## Installation

You can find [NeuroFormats on JuliaHub](https://juliahub.com/ui/Packages/NeuroFormats/zxLcF/), so all you need to do is:

```julia
using Pkg
Pkg.add("NeuroFormats")
```

from a Julia session.


## Documentation

The documentation is included with the package and can be [browsed online at JuliaHub](https://juliahub.com/docs/NeuroFormats/zxLcF/0.3.0/). It is not repeated on this website.

Use `?` to access the package documentation from within Julia, e.g., get help on a function named `read_curv` from within Julia by typing `?read_curv`. I also encourage you to have a look at the [unit tests of this package](./test/), they are essentially a collection of usage examples.


## Usage Examples

### Example 1: Cortical thickness on a brain mesh

The following example shows how to load a FreeSurfer brain mesh with per-vertex data and visualize it in Julia using NeuroFormats and GLMakie.

Note: If you do not have `GLMakie` installed, install it with `Pkg.add()` as described for `NeuroFormats` above. In that case, the example below will take a while to execute the first time you run it, as the packages will need to be precompiled first. Afterwards, visualization will be almost instant.

```julia
using NeuroFormats
using GLMakie

# Uses NeuroFormats demo data, feel free to use your own FreeSurfer data.
fs_subject_dir = joinpath(tdd(), "subjects_dir/subject1/")

surf = read_surf(joinpath(fs_subject_dir, "surf/lh.white")) # The brain mesh.
curv = read_curv(joinpath(fs_subject_dir, "surf/lh.thickness")) # cortical thickness.

vertices = surf.mesh.vertices
faces = surf.mesh.faces .+ 1

scene = mesh(vertices, faces, color = curv)
```

![Vis](./examples/julia_brainplot_NeuroFormats.png?raw=true "A 3D brain surface visualization created in Julia.")


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

![VisVox](./examples/julia_brainplot_voxels_NeuroFormats.png?raw=true "A 3D brain volume visualization created in Julia.")


### Example 3: An atlas-based brain surface parcellation

```julia
using NeuroFormats
using GLMakie

fs_subject_dir = joinpath(tdd(), "subjects_dir/subject1/")

surf = read_surf(joinpath(fs_subject_dir, "surf/lh.white"))
annot = read_annot(joinpath(fs_subject_dir, "label/lh.aparc.annot")) # from Desikan-Killiani atlas

vertices = surf.mesh.vertices
faces = surf.mesh.faces .+ 1

scene = mesh(vertices, faces, color = vertex_colors(annot))
```

![VisAnnot](./examples/julia_brainplot_parcellation_NeuroFormats.png?raw=true "A 3D brain surface visualization created in Julia.")


## Development

### License

NeuroFormats is free software published under the GPL v3, see the [LICENSE file](./LICENSE) for the full license.

### Citing

Please consider citing NeuroFormats if you use it for your research.


[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.8120740.svg)](https://doi.org/10.5281/zenodo.8120740)

```
To cite package ‘NeuroFormats’ in publications use:

  Tim Schäfer (2023). NeuroFormats: Handling of structural neuroimaging file formats for Julia. Julia package version 0.3.0. https://juliahub.com/ui/Packages/NeuroFormats/zxLcF/

A BibTeX entry for LaTeX users is

  @Manual{,
    title = {NeuroFormats: Handling of structural neuroimaging file formats for Julia},
    author = {Tim Schäfer},
    year = {2023},
    note = {Julia package version 0.3.0},
    url = {https://juliahub.com/ui/Packages/NeuroFormats/zxLcF/},
  }
```

Be sure to adapt the package version to the version you actually used.


### Unit tests and continuous integration

Continuous integration results:

Main branch: ![main](https://github.com/dfsp-spirit/NeuroFormats.jl/actions/workflows/CI.yml/badge.svg?branch=main)

Develop branch: ![develop](https://github.com/dfsp-spirit/NeuroFormats.jl/actions/workflows/CI.yml/badge.svg?branch=develop)


### Contributing

If you found a bug, have any question, suggestion or comment on freesurferformats, please [open an issue](https://github.com/dfsp-spirit/NeuroFormats.jl/issues). I will definitely answer and try to help. You can also let me know if you need support for a new file format.

Please see [CONTRIBUTING.md](CONTRIBUTING.md) for instructions on how to contribute code.

The NeuroFormats package was written by [Tim Schäfer](https://ts.rcmd.org). To contact me in person, please use the email address given on my website.
