# NeuroFormats.jl

Handling of structural neuroimaging file formats for [Julia](https://julialang.org).


## About

In the NeuroFormats package, we will provide an API, similar to that of the [freesurferformats R package](https://github.com/dfsp-spirit/freesurferformats), for reading structural neuroimaging data files in Julia. The focus will be on surface-based data, as produced by [FreeSurfer](https://freesurfer.net).

Note that some basic packages for reading neuroimaging data files are available from [JuliaNeuroscience](https://github.com/JuliaNeuroscience), e.g., NIFTI volume and GIFTI mesh support.

## Features

* Read and write FreeSurfer per-vertex data in curv format (like `subject/surf/lh.thickness`): functions `read_curv()` and `write_curv()`
* Read brain meshes in FreeSurfer binary mesh format (like `subject/surf/lh.white`): `read_surf()`
* Read FreeSurfer label files (like `subject/label/lh.cortex.label`): `read_label()`
* Read FreeSurfer brain surface parcellations (like `subject/label/lh.aparc.annot`): `read_annot()`
* Read DTI track data from MRtrix3 TCK files: `read_tck()`
* Read DTI track data from DiffusionToolkit TRK files: `read_trk()`


## Installation

You can find [NeuroFormats on JuliaHub](https://juliahub.com/ui/Packages/NeuroFormats/zxLcF/), so all you need to do is:

```julia
Pkg.add("NeuroFormats")
```

from a Julia session.


## Documentation

The documentation is included with the package and can be [browsed online at JuliaHub](https://juliahub.com/docs/NeuroFormats/zxLcF/). It is not repeated on this website. 

Also keep in mind that you can always get help on a function named `read_curv` from within Julia by typing `?read_curv`. The [unit tests of this package](./test/) can also provide usage examples.


## Usage Example

Please keep in mind that the API is not very stable yet. If you still want to give it a try already, here is an example for what you can do (after following the installation steps above):

```julia
using NeuroFormats
curv_file = "path/to/subjects_dir/subjectX/surf/lh.thickness" # Adapt path to your data.
thickness = read_curv(curv_file) # An Array{Float32, 1} with your cortical thickness data.
```

More examples can be found in the documentation, see above.

## Development

### License

NeuroFormats is published under the GPL v3, see the [LICENSE file](./LICENSE) for the full license.


### Unit tests and continuous integration

Continuous integration results:

[![Build Status](https://travis-ci.org/dfsp-spirit/NeuroFormats.jl.svg?branch=main)](https://travis-ci.org/dfsp-spirit/NeuroFormats.jl) Travis CI under Linux


### Contributing

If you found a bug, have any question, suggestion or comment on freesurferformats, please [open an issue](https://github.com/dfsp-spirit/NeuroFormats.jl/issues). I will definitely answer and try to help.

Please see [CONTRIBUTING.md](CONTRIBUTING.md) for instructions on how to contribute code.

The NeuroFormats package was written by [Tim Schäfer](http://rcmd.org/ts/). To contact me in person, please use the email address given on my website.

