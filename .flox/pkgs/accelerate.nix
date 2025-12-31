{ lib
, python3Packages
, stdenv
}:

# Override the accelerate package to disable tests on Darwin
# The package's test suite fails with "Trace/BPT trap" errors on macOS
python3Packages.accelerate.overridePythonAttrs (oldAttrs: {
  # Disable tests on Darwin platforms
  # The test suite crashes with signal 133 (SIGTRAP) on macOS
  doCheck = !stdenv.isDarwin;

  # Alternative: Could also use pytestCheckPhase = "" on Darwin
  # but doCheck = false is cleaner

  meta = oldAttrs.meta // {
    # Document the Darwin test issue
    knownIssues = [
      "Tests disabled on Darwin due to Trace/BPT trap errors during pytest execution"
    ];
  };
})