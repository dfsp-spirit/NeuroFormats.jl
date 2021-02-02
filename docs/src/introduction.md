# Introduction to NeuroFormats

## About the package

The NeuroFormats package aims to provide functions to read and write various file formats that are commonly using in computational neuroimaging. It focuses on structural MRI and surface-based analysis of the latter. The package enables scientists to write their own statistical analysis scripts in Julia instead of relying only on the methods implemented in standard neuroimaging software packages.

## Gotchas

When using the package, one should keep in mind that different programming languages and software packages use different indexing methods. E.g. in FreeSurfer, which is written in C/C++, the indices displayed in the software are zero-based: the first element is at index 0. In Julia however, the first element is at index 1.

## Conventions

The most relevant functions in the NeuroFormats package are named `read_<format>()` and `write_<format>`, where `<format>` is an abbreviation for the file format you are interested in, often the file extension if there is a commonly used file extension for the respective format. Here are some examples:

* `read_trk()` reads DTI tracts from files in the *trk* format used by DiffusionToolkit. The file names typically use the extension `.trk`.
* `read_curv()` reads FreeSurfer per-vertex data in *curv* Format. The file names do not have a fixed file extension. The function to write data to a *curv* file is `write_curv()`.

All functions from sub modules are reexported at the top level, so if you see `NeuroFormats.FreeSurfer.read_curv` in the API docs, you can just use `read_curv` after the initial `using NeuroFormats`.
