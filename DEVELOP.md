# Development info for NeuroFormats.js

## Recommended dev environment

I used VisualStudio Code with the `Julia` extension.

## Running the unit tests

```shell
cd <repo>
julia
# now, in the julia interpreter, hit the ']' key. This changes the
# prompt from 'julia> ' to something like '(@v1.5) pkg> '. Then:
dev .
test NeuroFormats.jl
```

You can hit `CTRL + d` to exit once you're done.

## Releasing a new version

 To release a new version:

* Make sure you have updated the `CHANGES` file
* If there are new dependencies, make sure you added compat entries in `Project.toml`
* Bump the package version in `Project.toml`
* Git add and commit
* On the Github repo website, go to the commit and comment '@JuliaRegistrator register'.
* The bot will start some checks, if they succeed you are done: releasing on Juliahub and tagging the commit with the release version are done automatically. If the checks fail, fix the issues in a new commit and comment again. Just ignore the old attempt, you do not need to do anything about it.
