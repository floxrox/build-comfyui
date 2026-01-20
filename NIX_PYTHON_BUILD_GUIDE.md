# Nix Python Application Build Guide
## Lessons from ComfyUI: What Works, What Doesn't, and Why

> **Purpose**: A practical reference to avoid catastrophic build failures and apply proven patterns when packaging Python applications with Nix/Flox.

---

## 🔴 CRITICAL: Nix Expressions vs Manifest Builds

### The Primary Approach: Nix Expressions with `flox build`

**USE THIS**: Create proper Nix expressions (`.nix` files) and reference them from your manifest:

```toml
[build]
[build.myapp]
expression = """
  (import ./pkgs/myapp.nix {
    inherit lib python3 fetchFromGitHub makeWrapper;
  })
"""
```

**NOT THIS**: Inline shell commands in manifest builds will fail spectacularly:

```toml
[build]
[build.myapp]
command = """
  # This WILL fail with permission errors, unbound variables, etc.
  git clone ...
  pip install ...
"""
```

**Why**: Nix expressions respect the sandbox, use proper dependency management, and follow declarative patterns. Shell commands fight the system and break reproducibility.

---

## 🎯 Quick Reference: Decision Tree

```
Building a Python app with Flox + Nix?
├── ALWAYS → Create a .nix file with buildPythonApplication/Package
├── Reference it → Use expression = "(import ./pkg.nix {...})" in manifest
├── Has non-standard structure? → Set format = "other"
├── Has problematic dependencies?
│   ├── Not in nixpkgs? → Create FOD package in separate .nix
│   ├── Platform issues? → Create override in separate .nix
│   └── Complex requirements? → Multiple .nix files
└── Needs custom build? → Use Nix phases, NOT shell scripts
```

---

## ✅ PROVEN PATTERNS (Use These!)

### 1. Basic Python Application Structure

```nix
{ lib, python3, fetchFromGitHub, makeWrapper }:

python3.pkgs.buildPythonApplication rec {
  pname = "myapp";
  version = "1.0.0";
  format = "other";  # For non-standard apps

  src = fetchFromGitHub {
    owner = "owner";
    repo = "repo";
    rev = "v${version}";
    hash = "sha256-xxx";
  };

  propagatedBuildInputs = with python3.pkgs; [
    # Dependencies here
  ];

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;  # For interpreted code
  doCheck = false;   # Skip tests if not needed
  dontWrapPythonPrograms = true;  # Custom wrapper

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/${pname}
    cp -r . $out/share/${pname}/

    pythonEnv="${python3.withPackages (ps: propagatedBuildInputs)}"

    makeWrapper ${python3}/bin/python3 $out/bin/${pname} \
      --add-flags "$out/share/${pname}/main.py" \
      --suffix PYTHONPATH : "$out/share/${pname}" \
      --suffix PYTHONPATH : "$pythonEnv/${python3.sitePackages}"

    runHook postInstall
  '';
}
```

### 2. Dependency Management Pattern

```nix
propagatedBuildInputs = [
  # Layer 1: Custom FOD packages
  myCustomPackage

  # Layer 2: Overridden packages
  (python3.pkgs.somePackage.overridePythonAttrs (old: {
    doCheck = false;
  }))

  # Layer 3: Standard nixpkgs
] ++ (with python3.pkgs; [
  numpy
  scipy

  # Platform-specific
]) ++ lib.optionals stdenv.isLinux (with python3.pkgs; [
  linux-only-package
]) ++ lib.optionals (!stdenv.isDarwin) (with python3.pkgs; [
  breaks-on-darwin
]);
```

### 3. Package Override Pattern

```nix
# mypackage-override.nix
{ python3Packages, stdenv }:

python3Packages.problemPackage.overridePythonAttrs (oldAttrs: {
  # Only override what's broken
  doCheck = !stdenv.isDarwin;

  # Preserve and extend metadata
  meta = oldAttrs.meta // {
    knownIssues = ["Test fails on Darwin"];
  };
})
```

### 4. Fixed-Output Derivation (FOD) Pattern

```nix
# For packages not in nixpkgs
{ lib, python3 }:

python3.pkgs.buildPythonPackage rec {
  pname = "missing-package";
  version = "1.0.0";
  pyproject = true;

  # Pre-downloaded source
  src = ./sources/${pname}-${version}.tar.gz;

  build-system = with python3.pkgs; [
    setuptools
  ];

  propagatedBuildInputs = with python3.pkgs; [
    # Dependencies
  ];

  doCheck = false;
}
```

### 5. Proper Wrapper Pattern

```nix
# Create Python environment properly
pythonEnv="${python3.withPackages (ps: propagatedBuildInputs)}"

# Use makeWrapper with --suffix for overridability
makeWrapper ${python3}/bin/python3 $out/bin/myapp \
  --add-flags "$out/share/myapp/main.py" \
  --suffix PYTHONPATH : "$pythonEnv/${python3.sitePackages}"
```

---

## ❌ ANTI-PATTERNS (Never Do These!)

### 0. ❌ The Manifest Build Command Anti-Pattern (THIS IS THE BIG ONE!)

```toml
[build]
[build.myapp]
# THIS WILL FAIL CATASTROPHICALLY
command = """
  git clone https://github.com/... $TMPDIR/src
  python3 -m venv $out/venv
  $out/venv/bin/pip install ...
  # Any shell scripting here is WRONG
"""
```

**Why it fails**:
- Shell commands are NOT Nix expressions
- Violates sandbox (network access, permissions)
- Runtime variables ($FLOX_ENV_CACHE) don't exist at build time
- Non-reproducible and non-deterministic
- Fights every Nix principle

**Instead**: ALWAYS use `expression = "(import ./pkg.nix {...})"` with proper Nix files

### 1. ❌ The Venv/Pip Anti-Pattern (In Any Context)

```bash
# NEVER DO THIS - Not in Nix, not in manifest builds
python -m venv $out/venv
$out/venv/bin/pip install -r requirements.txt
```

**Why it fails**:
- Breaks reproducibility
- Fights Nix's package management
- Creates non-deterministic builds
- Pip downloads at build time = network sandbox violation

**Instead**: Use `propagatedBuildInputs` with Nix Python packages

### 2. ❌ The Git Clone Anti-Pattern

```bash
# FAILS SPECTACULARLY
git clone https://github.com/... /comfyui-src  # Permission denied!
# OR
git clone https://github.com/... $TMPDIR/src   # If TMPDIR not expanded properly
```

**Why it fails**:
- Network access forbidden in sandbox (in some build modes)
- Non-reproducible
- Permission errors when trying to write to root paths
- Path variable expansion issues

**Instead**: Use `fetchFromGitHub` or pre-download sources

### 3. ❌ The Environment Variable Anti-Pattern

```bash
# BROKEN - THESE DON'T EXIST DURING BUILD
if [ -n "$FLOX_ENV_CACHE" ]; then
  # This will fail
fi
```

**Why it fails**:
- Build-time ≠ Runtime
- Environment variables undefined in sandbox
- `unbound variable` errors

**Instead**: Use Nix variables like `$out`, `$src`

### 4. ❌ The Complex Shell Script Anti-Pattern

```nix
command = """
  # 100+ lines of fragile shell commands
  mkdir -p ...
  cd ...
  if [ ... ]; then
    pip install ...
  fi
  # etc...
"""
```

**Why it fails**:
- Any step fails → entire build fails
- Hard to debug
- Not idiomatic Nix

**Instead**: Use Nix phases and functions

### 5. ❌ The Conditional PYTHONPATH Anti-Pattern

```bash
# TERRIBLE LOGIC
if [ -d "$dir/torch" ]; then
  export PYTHONPATH="$dir:${PYTHONPATH}"
fi
```

**Why it fails**:
- Assumes package structure
- Brittle detection
- Misses packages without expected subdirs

**Instead**: Always add full site-packages or use `withPackages`

### 6. ❌ The Store Path Hardcoding Anti-Pattern

```nix
comfyui.store-path = "/nix/store/hash-package-version"
```

**Why it fails**:
- Store paths are outputs, not inputs
- Breaks after garbage collection
- Non-portable

**Instead**: Let Nix manage store paths

---

## 🎓 Key Principles

### 1. **Nix is Declarative**
- Describe the END STATE, not the steps
- No imperative commands during build
- Let Nix handle the "how"

### 2. **Respect the Sandbox**
- No network access
- No absolute paths outside build dir
- No runtime environment assumptions

### 3. **Use Nix's Python Infrastructure**
- `buildPythonPackage` for libraries
- `buildPythonApplication` for executables
- `withPackages` for environments
- `overridePythonAttrs` for fixes

### 4. **Separate Concerns**
- One package per .nix file
- Clear dependency hierarchy
- Modular, composable builds

### 5. **Keep It Simple**
- Complex shell scripts = fragile builds
- Use Nix patterns, not workarounds
- If it feels hacky, it probably is

---

## 📋 Build Checklist

Before building:
- [ ] Using `buildPythonApplication` or `buildPythonPackage`?
- [ ] Source fetched with `fetchFromGitHub` or similar?
- [ ] Dependencies in `propagatedBuildInputs`?
- [ ] No `pip install` commands?
- [ ] No `git clone` in build?
- [ ] No hardcoded `/nix/store` paths?
- [ ] Platform-specific issues handled?
- [ ] Using `makeWrapper` for executables?
- [ ] No runtime env vars in build script?
- [ ] Following Nix Python conventions?

---

## 🔧 Debugging Tips

### When build fails:

1. **Check the error carefully**
   - "Permission denied" → Trying to write outside build dir
   - "unbound variable" → Runtime var used in build
   - "Network access denied" → Using git/curl/wget in build

2. **Simplify**
   - Remove complexity
   - Test minimal version
   - Add features incrementally

3. **Use Nix tools**
   - `nix-build -K` to keep failed build
   - `nix repl` to test expressions
   - `nix-store --query --tree` for dependencies

4. **Common fixes**:
   - `doCheck = false` for broken tests
   - `format = "other"` for non-standard packages
   - Override packages with issues
   - Create FOD for missing packages

---

## 📚 Complete Workflow with Nix Expressions

### Step 1: Create Your Nix Expression

Create `pkgs/myapp.nix`:

```nix
{ lib, python3, fetchFromGitHub, makeWrapper }:

python3.pkgs.buildPythonApplication rec {
  pname = "myapp";
  version = "1.0.0";
  format = "other";  # For non-standard structure

  src = fetchFromGitHub {
    owner = "owner";
    repo = "repo";
    rev = "v${version}";
    hash = "sha256-xxx";
  };

  propagatedBuildInputs = with python3.pkgs; [
    # Your dependencies
  ];

  # ... rest of build configuration
}
```

### Step 2: Reference in Manifest

In `manifest.toml`:

```toml
[build]
[build.myapp]
# ALWAYS use expression, NOT command
expression = """
  (import ./pkgs/myapp.nix {
    inherit lib python3 fetchFromGitHub makeWrapper;
  })
"""
```

### Step 3: Build with Flox

```bash
# Build your package
flox build myapp

# Test the build
./result/bin/myapp

# Install in environment
[install]
myapp.pkg-path = "path/to/built/package"
```

### Complete Example: Multi-Package Project

Directory structure:
```
project/
├── .flox/
│   ├── env/
│   │   └── manifest.toml
│   └── sources/        # Pre-downloaded vendored sources
├── pkgs/
│   ├── myapp.nix       # Main application
│   ├── dependency1.nix # FOD package
│   └── override.nix    # Platform-specific override
```

Manifest with multiple builds:
```toml
[build]
[build.dependency1]
expression = "(import ./pkgs/dependency1.nix { inherit lib python3; })"

[build.myapp]
expression = """
  (import ./pkgs/myapp.nix {
    inherit lib python3 fetchFromGitHub makeWrapper;
    customDep = dependency1;  # Reference other build
  })
"""
```

---

## 🚀 Success Formula

1. **ALWAYS use Nix expressions** - Create `.nix` files, NOT shell commands
2. **Reference with `expression`** - Use `expression = "(import ./pkg.nix {...})"` in manifest
3. **Use Nix patterns** - `buildPythonApplication`, `propagatedBuildInputs`, `makeWrapper`
4. **Handle dependencies properly** - FOD packages, overrides, or nixpkgs
5. **Test with `flox build`** - Build incrementally, test each component
6. **Document issues** - Platform problems, workarounds

**The Golden Rule**: If you're writing bash commands in a manifest build, you're doing it wrong. Write a Nix expression instead.

---

## 💡 Remember

> **The path to Nix enlightenment is paved with idiomatic patterns, not clever workarounds.**

When in doubt:
- Check how nixpkgs does it
- Use the simplest approach that works
- Let Nix handle complexity
- Don't mix paradigms (pip + nix = pain)

---
