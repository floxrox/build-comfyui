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

historical branches don't get `<branch_name>-testing` because … they're historical.

## Development Pipeline Flow

### Active Development Lines (with testing/staging infrastructure)
```
latest-testing → latest-staging → latest
main-testing   → main-staging   → main
```

### Version Inheritance Chain
```
latest → main → v0.x.x
(newest) → (stable) → (historical archive)
```

### Branch Types
- **Active branches**: `latest`, `main` (with full testing/staging sub-branches)
- **Historical archives**: `v0.x.x` (standalone, read-only for reproducible builds)
- **Development rule**: Only work on active lines; historical branches are preserved for `git checkout v0.9.1 && flox build comfyui`

### Flow Rules
- **Testing branches**: Where fixes/updates are initially committed and validated
- **Staging branches**: Where changes from testing are promoted for UAT
- **Production branches**: Where changes from staging are promoted after approval
- **Direction**: Always flows testing → staging → production (NEVER backwards)
- **Inheritance**: Only during version rotation: latest → main → v0.x.x

## Version Rotation Procedures

### When New ComfyUI Version Released (Immediate Rotation)

When a new ComfyUI version becomes available (e.g., v0.9.3), we execute immediate rotation:

1. **Archive current main**:
   ```bash
   git checkout -b v0.9.1 main
   git push origin v0.9.1
   ```

2. **Promote latest to main**:
   ```bash
   git checkout main
   git merge latest --no-ff -m "Promote v0.9.2 from latest to main"
   git push origin main
   ```

3. **Update latest to new version**:
   - Edit `.flox/pkgs/comfyui.nix` in `latest-testing` branch
   - Update version number to new release
   - Update source hash
   - Test build with `flox build comfyui`

### Rollback Strategy
- **Problematic release**: Revert `latest` to previous known good state
- **Skip release**: Leave problematic version out of rotation entirely
- **Historical access**: Any version remains accessible via `git checkout v0.x.x && flox build comfyui`

### Branch Relationship Matrix

| Branch | Type | Fed By | Feeds Into | Purpose |
|--------|------|--------|------------|---------|
| `latest-testing` | Active | Direct commits | `latest-staging` | New version development |
| `latest-staging` | Active | `latest-testing` | `latest` | New version UAT |
| `latest` | Active | `latest-staging` | `main` (rotation) | Current newest version |
| `main-testing` | Active | Direct commits | `main-staging` | Stable version maintenance |
| `main-staging` | Active | `main-testing` | `main` | Stable version UAT |
| `main` | Active | `main-staging` | `v0.x.x` (rotation) | Current stable version |
| `v0.x.x` | Historical | `main` (rotation only) | None | Archived for reproducible builds |


## Reproducible Build Architecture

We preserve these historical versions so they can be rebuilt at any time: e.g., `git checkout v0.9.1` + `flox build comfyui`. In practice, building ComfyUI requires vendoring Python packages – or, in some cases, vendoring package source so we can always rebuild exactly the same versions (with exactly the same bits) of dependencies at any time, anywhere – and using fixed-output derivation patterns to preemptively grab dependencies that require network access and then build them in the isolated nix sandbox.

we build with flox build + nix expressions. we name the nix expression we use to build the base comfyui package `comfyui.nix`. this lives in `./.flox/pkgs/`, along with other complementary packages. the current build recipes in `./.flox/pkgs/` work (or seem to work). you should take some time to analyze and understand them.

consistent with this, you should read and understand `NIX_PYTHON_BUILD_GUIDE.md`. this is a lodestar document. so are `FLOX.md` and `FLOX-PYTHON.md`. `README.md` needs to be updated as the project evolves. `REPRODUCIBLE-BUILD-ARCHITECTURE.md` is also a lodestar document, but may need to be updated?

we will build with the expectation that comfyui will be launched from a runtime flox environment. in the runtime, the user should be able to define their own, custom versions of dependencies (like pytorch, torchvision, torchaudio, etc.) if desired, e.g., for cuda support. check out FLOX-PYTHON.md for more on this. the flox runtime environment should define a flox-managed service to run comfyui. it should bootstrap the creation of a venv in `[hook]`. we will augment this as we add features / functions to the comfyui build. i will provide the path to the flox comfyui runtime environment when we’re ready to work with it.

speaking of which, we want to build all that’s required to build comfyui into the main `comfyui.nix` package. we will create other packages (e.g., `comfyui-ultralytics`, `comfyui-plugins` [this last includes the comfyui impact pack], `comfyui-impact-subpack`, etc.) to build, package, and publish other optional assets. relatedly, we use a build repo for custom nodes and extras in `~/dev/testes$ cd build-comfyui-extras/`. you’ll want to study the nix expressions in `~/dev/testes$ cd build-comfyui-extras/.flox/pkgs/` to understand how this package is built and what we need to get it to work with our main `comfyui.nix` package.

last and no less important, we are using the default comfyui userspace path for workflows, models, custom nodes, loras, etc.; this lives at `$HOME/comfyui-work`.
