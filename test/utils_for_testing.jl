
""" Unit testing helper function to find test data dir.

This is required because during tests, the base dir seems to be <package/test>, while it is <package> in the standard REPL.
"""
function get_testdata_dir()
if isdir("data/subjects_dir")
    return joinpath(dirname(@__FILE__), "data/")
elseif isdir("test/data/subjects_dir")
    return joinpath(dirname(@__FILE__), "test/data/")
else
    error("Could not determine test data directory from current working directory.")
end
nothing
end