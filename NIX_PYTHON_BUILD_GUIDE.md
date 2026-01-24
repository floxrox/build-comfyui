# Nix Python Application Build Guide
## Lessons from ComfyUI: What Works, What Doesn't, and Why

> **Purpose**: Document the correct way to build Python applications with Nix/Flox, based on actual working patterns and catastrophic failures.

---

## 🔴 CRITICAL: Two Completely Separate Build Systems

Flox supports two **entirely independent** build systems:

### 1. Nix Expression Builds (The Solution for Complex Apps)
- Put `.nix` files in `.flox/pkgs/`
- Git add them
- Run `flox build <name>`
- **NO manifest involvement whatsoever**
- This is how professional packages are built

### 2. Manifest Builds (Failed for ComfyUI)
- Inline bash scripts in `[build.name]` sections
- Uses `command` field only
- Good for simple scripts, NOT complex applications
- This approach failed catastrophically for ComfyUI

---

## 🎯 The Correct Approach: Nix Expressions in `.flox/pkgs/`

### Step 1: Create Your Nix Expression

Create `.flox/pkgs/comfyui.nix`:

```nix
{ lib, python3, fetchFromGitHub, makeWrapper }:

python3.pkgs.buildPythonApplication rec {
  pname = "comfyui";
  version = "0.9.1";
  format = "other";  # For non-standard Python apps

  src = fetchFromGitHub {
    owner = "comfyanonymous";
    repo = "ComfyUI";
    rev = "v${version}";
    hash = "sha256-xxx";
  };

  propagatedBuildInputs = with python3.pkgs; [
    # Python dependencies
    torch
    torchvision
    torchaudio
    numpy
    # ... etc
  ];

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;
  doCheck = false;
  dontWrapPythonPrograms = true;

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

### Step 2: Build It

```bash
# Git add your Nix files
git add .flox/pkgs/*.nix

# Build
flox build comfyui

# Test
./result-comfyui/bin/comfyui
```

That's it. No manifest involvement. No `[build]` sections. Just Nix expressions.

---

## ✅ PROVEN PATTERNS (What Actually Works)

### 1. Project Structure for Nix Expression Builds

```
project/
├── .flox/
│   ├── env/
│   │   └── manifest.toml    # manifest is completely empty
│   └── pkgs/                 # Nix expressions go here
│       ├── myapp.nix
│       ├── dependency1.nix
│       └── override.nix
```

### 2. Dependency Management

```nix
propagatedBuildInputs = [
  # Custom FOD packages
  (import ./spandrel.nix { inherit lib python3; })

  # Overridden packages
  (python3.pkgs.somePackage.overridePythonAttrs (old: {
    doCheck = false;
  }))

  # Standard nixpkgs
] ++ (with python3.pkgs; [
  numpy
  scipy
]);
```

### 3. Fixed-Output Derivation (FOD) for Missing Packages

Create `.flox/pkgs/missing-package.nix`:

```nix
{ lib, python3 }:

python3.pkgs.buildPythonPackage rec {
  pname = "missing-package";
  version = "1.0.0";
  pyproject = true;

  # Pre-downloaded source
  src = ../sources/${pname}-${version}.tar.gz;

  build-system = with python3.pkgs; [
    setuptools
  ];

  doCheck = false;
}
```

---

## ❌ ANTI-PATTERNS (What Failed Catastrophically)

### 1. ❌ Manifest Builds for Complex Applications

```toml
[build]
[build.comfyui]
# THIS FAILED SPECTACULARLY
command = """
  git clone https://github.com/... $TMPDIR/src
  python3 -m venv $out/venv
  $out/venv/bin/pip install ...
"""
```

**Why it failed**:
- Manifest builds are for simple scripts, not applications
- No access to Nix Python infrastructure
- Violates sandbox (network access, permissions)
- Runtime variables ($FLOX_ENV_CACHE) undefined at build time

### 2. ❌ Using Venv/Pip in Any Nix Context

```bash
# NEVER DO THIS
python -m venv $out/venv
$out/venv/bin/pip install -r requirements.txt
```

**Why it fails**:
- Breaks reproducibility
- Fights Nix's package management
- Network access forbidden in sandbox
- Non-deterministic

### 3. ❌ Git Clone in Builds

```bash
# FAILS
git clone https://github.com/... /comfyui-src
```

**Why it fails**:
- Network access forbidden in pure builds
- Permission errors
- Non-reproducible

**Instead**: Use `fetchFromGitHub` in Nix expressions

### 4. ❌ Runtime Environment Variables in Build Scripts

```bash
# BROKEN
if [ -n "$FLOX_ENV_CACHE" ]; then  # Doesn't exist at build time
  # This will fail
fi
```

**Why it fails**:
- Build-time ≠ Runtime
- These variables don't exist in build sandbox

---

## 🎓 Key Principles

### 1. **Separation of Concerns**
- **Build time**: Nix expressions in `.flox/pkgs/`
- **Runtime**: Environment configuration in `manifest.toml`
- These are completely separate systems

### 2. **Use the Right Tool**
- Complex applications → Nix expressions
- Simple scripts → Manifest builds (maybe)
- Python apps → Always use `buildPythonApplication`

### 3. **Respect the Nix Way**
- Declarative, not imperative
- No network access during builds
- Use Nix's Python infrastructure
- Let Nix handle dependency management

---

## 📋 Build Checklist

Before building:
- [ ] Is your `.nix` file in `.flox/pkgs/`?
- [ ] Using `buildPythonApplication` or `buildPythonPackage`?
- [ ] Source fetched with `fetchFromGitHub`?
- [ ] Dependencies in `propagatedBuildInputs`?
- [ ] No `pip install` commands?
- [ ] No `git clone` in build?
- [ ] Git added your `.nix` files?

---

## 🔧 Debugging Tips

### When build fails:

1. **Check the error**:
   - "Permission denied" → Writing outside build dir
   - "unbound variable" → Runtime var in build
   - "Network access denied" → Using git/curl in build

2. **Common fixes**:
   - `doCheck = false` for broken tests
   - `format = "other"` for non-standard packages
   - Override packages with issues
   - Create FOD for missing packages

3. **Use Nix tools**:
   ```bash
   nix-build -K          # Keep failed build
   nix repl             # Test expressions
   nix-store --query    # Check dependencies
   ```

---

## 🚀 Success Formula

1. **Create `.nix` files in `.flox/pkgs/`**
2. **Use `buildPythonApplication`** with proper Nix patterns
3. **Manage dependencies** with `propagatedBuildInputs`
4. **Git add your files**
5. **Run `flox build <name>`**

---

## 💡 Remember

> **The path to Nix enlightenment: Use the right tool for the job.**

- Complex apps need Nix expressions
- Manifest builds are not for applications
- Don't mix paradigms (pip + nix = pain)
- When in doubt, check how nixpkgs does it

---

*Generated from the spectacular failures and eventual success of packaging ComfyUI with Nix/Flox*
