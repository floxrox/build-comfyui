# ComfyUI Flox Packages Documentation

**Branch:** v0.6.0
**ComfyUI Version:** 0.6.0

## Package Overview

This repository contains 16 Nix packages for building and running ComfyUI with Flox.

## Core Package

### comfyui.nix
- **Purpose**: Main ComfyUI application
- **Version**: 0.6.0 (matches ComfyUI version)
- **Imports**: 13 packages (all active packages except color-matcher and comfyui-plugins)
- **Build command**: `flox build comfyui`
- **Binary**: Provides `comfyui` and model download tools

## Frontend & UI Packages

### comfyui-frontend-package.nix
- **Purpose**: Web UI components for ComfyUI
- **Version**: 1.34.9 (from PyPI)
- **Type**: Python wheel package
- **Imported by**: comfyui.nix

### comfyui-embedded-docs.nix
- **Purpose**: Built-in documentation and help system
- **Version**: 0.3.1 (from PyPI)
- **Type**: Python wheel package
- **Imported by**: comfyui.nix

## Workflow Templates

### comfyui-workflow-templates.nix
- **Purpose**: Collection of example workflows
- **Version**: 0.7.63 (from PyPI)
- **Type**: Python wheel package (meta-package)
- **Imported by**: comfyui.nix
- **Depends on**: All 5 workflow sub-packages below

### Workflow Sub-packages

#### comfyui-workflow-templates-core.nix
- **Version**: 0.7.63
- **Purpose**: Core workflow templates
- **Imported by**: comfyui.nix, comfyui-workflow-templates.nix

#### comfyui-workflow-templates-media-api.nix
- **Version**: 0.7.63
- **Purpose**: API-based media workflows
- **Imported by**: comfyui.nix, comfyui-workflow-templates.nix

#### comfyui-workflow-templates-media-video.nix
- **Version**: 0.7.63
- **Purpose**: Video processing workflows
- **Imported by**: comfyui.nix, comfyui-workflow-templates.nix

#### comfyui-workflow-templates-media-image.nix
- **Version**: 0.7.63
- **Purpose**: Image processing workflows
- **Imported by**: comfyui.nix, comfyui-workflow-templates.nix

#### comfyui-workflow-templates-media-other.nix
- **Version**: 0.7.63
- **Purpose**: Other media workflows
- **Imported by**: comfyui.nix, comfyui-workflow-templates.nix

## Plugin System

### comfyui-plugins.nix
- **Purpose**: Custom node plugins (currently Impact Pack)
- **Version**: 0.6.0 (matches ComfyUI version for compatibility)
- **Impact Pack Version**: 8.28
- **Build command**: `flox build comfyui-plugins`
- **Provides**: `comfyui-activate-plugins`, `comfyui-download-impact-models`
- **Note**: Standalone package, not imported by comfyui.nix

## ML/AI Dependencies

### spandrel.nix
- **Purpose**: Model loading and architecture detection library
- **Version**: 0.4.0 (from PyPI)
- **Imported by**: comfyui.nix

### nunchaku.nix
- **Purpose**: FLUX model optimization library
- **Version**: 0.16.1 (from PyPI)
- **Imported by**: comfyui.nix

### controlnet-aux.nix
- **Purpose**: ControlNet preprocessors and utilities
- **Version**: 0.0.10 (from PyPI)
- **Imported by**: comfyui.nix

### gguf.nix
- **Purpose**: GGUF model format support
- **Version**: 0.11.0 (from PyPI)
- **Imported by**: comfyui.nix

### accelerate.nix
- **Purpose**: PyTorch acceleration utilities
- **Version**: 1.2.1 (from PyPI)
- **Imported by**: comfyui.nix

## Example/Reference Package

### color-matcher.nix
- **Purpose**: Example package demonstrating custom Python package building
- **Version**: 0.6.0
- **Status**: Working but not imported (reference implementation)
- **Note**: From initial repository architecture design

## Future Development

The following packages exist in the `nightly-broken-v091` branch and may be integrated in future releases:

### comfyui-manager.nix (TC)
- **Purpose**: Web UI for managing ComfyUI custom nodes
- **Version**: Will match ComfyUI version when integrated
- **Branch**: nightly-broken-v091

### comfyui-ultralytics.nix (TC)
- **Purpose**: YOLO model support and utilities
- **Version**: Will match ComfyUI version when integrated
- **Related**: Extends Impact Pack functionality
- **Branch**: nightly-broken-v091

### comfyui-impact-subpack.nix (TC)
- **Purpose**: Extended Impact Pack features with onnxruntime
- **Version**: Will match ComfyUI version when integrated
- **Branch**: nightly-broken-v091

## Versioning Strategy

### Lock-step Versioning (Our Packages)
Packages we maintain match ComfyUI's version to indicate compatibility:
- comfyui.nix → 0.6.0
- comfyui-plugins.nix → 0.6.0
- Future: comfyui-manager.nix, comfyui-ultralytics.nix, etc.

### Independent Versioning (Vendored Packages)
External packages maintain their upstream versions:
- PyPI packages: Use exact versions from PyPI
- GitHub packages: Use specific release tags

When ComfyUI updates, lock-step packages update together while vendored packages only update when their upstream changes.

## Building Packages

```bash
# Build main ComfyUI
flox build comfyui

# Build plugins separately
flox build comfyui-plugins

# Cannot build sub-packages directly (they're imported)
# The following will fail:
# flox build comfyui-frontend-package
```

## Package Dependencies Graph

```
comfyui.nix
├── comfyui-frontend-package.nix
├── comfyui-embedded-docs.nix
├── comfyui-workflow-templates.nix
│   ├── comfyui-workflow-templates-core.nix
│   ├── comfyui-workflow-templates-media-api.nix
│   ├── comfyui-workflow-templates-media-video.nix
│   ├── comfyui-workflow-templates-media-image.nix
│   └── comfyui-workflow-templates-media-other.nix
├── spandrel.nix
├── nunchaku.nix
├── controlnet-aux.nix
├── gguf.nix
└── accelerate.nix

Standalone:
├── comfyui-plugins.nix
└── color-matcher.nix (example only)
```