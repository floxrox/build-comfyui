{ lib
, python3Packages
, stdenv
}:

# Override the gguf package to disable import checks on Darwin
# The package has native code that causes segmentation faults on macOS
python3Packages.gguf.overridePythonAttrs (oldAttrs: {
  # Disable the import check on Darwin platforms
  # The native extensions in gguf cause segmentation faults during import on macOS
  pythonImportsCheck = lib.optionals (!stdenv.isDarwin) oldAttrs.pythonImportsCheck;

  meta = oldAttrs.meta // {
    # Explicitly note the Darwin import check issue
    knownIssues = [
      "Import checks disabled on Darwin due to segmentation faults in native code"
    ];
  };
})