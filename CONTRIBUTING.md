
## Contributing to NeuroFormats.jl

I am very happy to accept [pull requests](https://help.github.com/en/github/collaborating-with-issues-and-pull-requests/creating-a-pull-request), provided you are fine with publishing your work under the [license of this project](https://github.com/dfsp-spirit/NeuroFormats.jl#license). If your PR is not just a fix but changes or adds lots of code, please get in touch by [opening an issue](https://github.com/dfsp-spirit/NeuroFormats.jl/issues) before starting the project so we can discuss it first. Development currently happens on the *develop* branch.

### Contribution workflow

If you want to contribute something, the general workflow is:

- Log into the Github website and fork the NeuroFormats.jl repository to your account.
- Checkout your forked repository to your computer. You will be on the maain branch. Change to the develop branch.
- Create a new branch and name it after your feature, e.g., `add_cool_new_feature` or `fix_issue_17`.
- Make changes to the NeuroFormats code and commit them into your branch.
- Make sure the existing unit tests are all green (see below). Adding new tests for your fix or the new features is even better.
- Create a pull request, requesting to merge your branch into the develop branch of my NeuroFormats repo.

### Setting up the development environment

Most likely you already have your development environment setup the way you prefer it when you decide to contribute. If not, here is a quick way to get started.

* Install Julia
* Install Visual Studio Code (VS Code)
* In VS Code install the Julia extension
* In VS Code change to the TERMINAL tab in the lower part of the code window, then run:

```shell
git clone https://github.com/dfsp-spirit/NeuroFormats.jl
cd NeuroFormats.jl
julia --project=.
```

Now you can add tests and make your changes.

To run the tests during development:

```julia
using Pkg
Pkg.test("NeuroFormats")
```
