# NeuroFormats.jl

Handling of structural neuroimaging file formats for [Julia](https://julialang.org).

## About

Some basic packages for reading neuroimaging data files are available from [JuliaNeuroscience](https://github.com/JuliaNeuroscience), e.g., NIFTI volume and GIFTI mesh support. In this NeuroFormats package, we will provide an API, similar to that of the [freesurferformats R package](https://github.com/dfsp-spirit/freesurferformats), for reading structural neuroimaging data files in Julia. The focus will be on surface-based data, as produced by [FreeSurfer](https://freesurfer.net).

## Installation

This is a very early package version, and the package is not yet registered. You will have to checkout the repo and start a Julia REPL in the directory:

```shell
git clone https://github.com/dfsp-spirit/NeuroFormats.jl
cd NeuroFormats.jl
julia --project=.
```

## Usage

This is a very early package version, please keep in mind that the API is not very stable yet. If you still want to give it a try already, here is what you can do:

```julia
using NeuroFormats
curv_file = "path/to/subjects_dir/subjectX/surf/lh.thickness" # Adapt path to your data.
thickness = read_curv(curv_file) # An Array{Float32, 1} with your cortical thickness data.
```

## Continuous integration results:

[![Build Status](https://travis-ci.org/dfsp-spirit/NeuroFormats.jl.svg?branch=main)](https://travis-ci.org/dfsp-spirit/NeuroFormats.jl) Travis CI under Linux
