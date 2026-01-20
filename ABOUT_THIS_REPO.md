i want to turn this into a repo for building comfyui using flox build with nix expressions. i want to build against the upstream comfyui github repo. i want to use a branching strategy to build and preserve distinct versions of comfyui releases as nix expressions. to start with, i want to focus on `main`, which will be comfyui 0.9.1.

right now we have a very basic branching strategy:

main = 0.6.0
nightly = 0.9.1
historical = 0.6.0

i want to transform this repo to implement a strategy where `nightly` becomes `latest` and `historical` goes away, with the branch name `historical` replaced by older/deprecated versions of comfyui, like so:

main = 0.9.1
latest = 0.9.2
v0.9.0 = 0.9.0
v0.8.11 = 0.8.11

we’ll use the following semantics + structure to build `main` and `latest`:

main-testing = we build, run, and validate our comfyui package
main-staging = we queue release candidates for UAT; once approved, we promote to main

latest-testing = we build, run, and validate our comfyui package
latest-staging = we queue release candidates for UAT; once approved, we promote to latest

historical branches don’t get `<branch_name>-testing` because … they’re historical.

when new releases of comfyui – e.g., comfyui 0.9.3 -- become available, we’ll use the following strategy:


current `latest` (i.e., comfyui v0.9.2) becomes new `main`
current `main` becomes `v<version_number>`, e.g., current `main` (0.9.1) becomes `v0.9.1`.


we preserve these historical versions so they can be rebuilt at any time: e.g., `git checkout v0.9.1` + `flox build comfyui`. in practice, building comfyui will require vendoring python packages – or, in some cases, vendoring package source so we can always rebuild exactly the same versions (with exactly the same bits) of dependencies at any time, anywhere – and using fixed-output derivation patterns to preemptively grab dependencies that require network access and then build them in the isolated nix sandbox.

we build with flox build + nix expressions. we name the nix expression we use to build the base comfyui package `comfyui.nix`. this lives in `./.flox/pkgs/`, along with other complementary packages. the current build recipes in `./.flox/pkgs/` work (or seem to work). you should take some time to analyze and understand them.

consistent with this, you should read and understand `NIX_PYTHON_BUILD_GUIDE.md`. this is a lodestar document. so are `FLOX.md` and `FLOX-PYTHON.md`. `README.md` needs to be updated as the project evolves. `REPRODUCIBLE-BUILD-ARCHITECTURE.md` is also a lodestar document, but may need to be updated?

we will build with the expectation that comfyui will be launched from a runtime flox environment. in the runtime, the user should be able to define their own, custom versions of dependencies (like pytorch, torchvision, torchaudio, etc.) if desired, e.g., for cuda support. check out FLOX-PYTHON.md for more on this. the flox runtime environment should define a flox-managed service to run comfyui. it should bootstrap the creation of a venv in `[hook]`. we will augment this as we add features / functions to the comfyui build. i will provide the path to the flox comfyui runtime environment when we’re ready to work with it.

speaking of which, we want to build all that’s required to build comfyui into the main `comfyui.nix` package. we will create other packages (e.g., `comfyui-ultralytics`, `comfyui-plugins` [this last includes the comfyui impact pack], `comfyui-impact-subpack`, etc.) to build, package, and publish other optional assets. relatedly, we use a build repo for custom nodes and extras in `~/dev/testes$ cd build-comfyui-extras/`. you’ll want to study the nix expressions in `~/dev/testes$ cd build-comfyui-extras/.flox/pkgs/` to understand how this package is built and what we need to get it to work with our main `comfyui.nix` package.

last and no less important, we are using the default comfyui userspace path for workflows, models, custom nodes, loras, etc.; this lives at `$HOME/comfyui-work`.
