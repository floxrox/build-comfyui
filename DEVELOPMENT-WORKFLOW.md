# Development Workflow Guide

This document provides step-by-step procedures for common development scenarios in the build-comfyui repository.

## Overview

### Branch Flow Summary
```
Testing → Staging → Production
   ↓        ↓         ↓
Direct    UAT      Release
Commits   Review   Ready
```

### Active Development Lines
- **latest line**: `latest-testing` → `latest-staging` → `latest` (newest ComfyUI version)
- **main line**: `main-testing` → `main-staging` → `main` (stable ComfyUI version)

### Historical Archives
- **v0.x.x branches**: Read-only archives for reproducible builds

## Scenarios and Procedures

### Scenario 1: Fixing a Bug in Current Stable (main)

When you need to fix an issue in the stable version:

1. **Start in main-testing**:
   ```bash
   git checkout main-testing
   git pull origin main-testing
   ```

2. **Develop and test**:
   ```bash
   # Make your changes
   flox build comfyui  # Validate build works
   ./result-comfyui/bin/comfyui --help  # Test binary
   ```

3. **Commit your fix**:
   ```bash
   git add .
   git commit -m "fix(main): description of fix"
   git push origin main-testing
   ```

4. **Promote to staging**:
   ```bash
   git checkout main-staging
   git pull origin main-staging
   git merge main-testing --no-ff
   git push origin main-staging
   ```

5. **UAT validation**:
   - Test thoroughly in staging environment
   - Verify fix resolves issue
   - Get approval if required

6. **Promote to production**:
   ```bash
   git checkout main
   git pull origin main
   git merge main-staging --no-ff
   git push origin main
   ```

7. **Consider cross-pollination**:
   - Evaluate if fix is needed in `latest` line
   - If so, repeat process in `latest-testing`

### Scenario 2: Adding Feature to Latest Version

When developing new features for the newest ComfyUI version:

1. **Start in latest-testing**:
   ```bash
   git checkout latest-testing
   git pull origin latest-testing
   ```

2. **Implement feature**:
   ```bash
   # Make your changes to .flox/pkgs/*.nix files
   flox build comfyui
   # Test functionality thoroughly
   ```

3. **Commit your feature**:
   ```bash
   git add .
   git commit -m "feat: description of new feature"
   git push origin latest-testing
   ```

4. **Promote through pipeline**:
   ```bash
   # To staging
   git checkout latest-staging
   git pull origin latest-staging
   git merge latest-testing --no-ff
   git push origin latest-staging

   # After UAT approval, to production
   git checkout latest
   git pull origin latest
   git merge latest-staging --no-ff
   git push origin latest
   ```

### Scenario 3: Emergency Hotfix

For critical issues requiring immediate attention:

1. **Identify the line**: Determine if issue affects `main` or `latest`

2. **Commit directly to testing**:
   ```bash
   git checkout [main-testing|latest-testing]
   # Make minimal fix
   flox build comfyui  # Validate
   git commit -m "hotfix: critical issue description"
   git push origin [main-testing|latest-testing]
   ```

3. **Fast-track promotion**:
   ```bash
   # Expedite through staging with clear justification
   git checkout [main-staging|latest-staging]
   git merge [main-testing|latest-testing] --no-ff
   git push origin [main-staging|latest-staging]

   # To production after minimal validation
   git checkout [main|latest]
   git merge [main-staging|latest-staging] --no-ff
   git push origin [main|latest]
   ```

4. **Document emergency process**: Include justification in commit messages

### Scenario 4: Version Rotation (New ComfyUI Release)

When a new ComfyUI version is released:

1. **Validate latest is stable**:
   ```bash
   git checkout latest
   # Ensure latest branch builds and functions correctly
   flox build comfyui
   # Run comprehensive tests
   ```

2. **Execute rotation immediately**:
   ```bash
   # Archive current main
   git checkout -b v0.9.1 main
   git push origin v0.9.1

   # Promote latest to main
   git checkout main
   git merge latest --no-ff -m "Promote v0.9.2 from latest to main"
   git push origin main
   ```

3. **Update latest to new version**:
   ```bash
   git checkout latest-testing
   # Edit .flox/pkgs/comfyui.nix:
   # - Update version = "0.9.3"
   # - Update source hash (build will fail with correct hash)
   flox build comfyui  # Get hash mismatch error
   # Copy correct hash to .nix file
   flox build comfyui  # Should succeed
   ```

4. **Validate new version**:
   ```bash
   # Test new version thoroughly
   ./result-comfyui/bin/comfyui --help
   # Promote through normal pipeline when ready
   ```

5. **Rollback if needed**:
   ```bash
   # If new version has problems:
   git checkout latest
   git reset --hard HEAD~1  # Revert to previous state
   # Or skip problematic version entirely
   ```

### Scenario 5: Working with Historical Versions

Historical branches (`v0.x.x`) are generally read-only:

1. **Reproducible builds**:
   ```bash
   git checkout v0.9.1
   flox build comfyui
   # Should build exactly the same as when originally released
   ```

2. **Reference only**: Use for comparing with current versions or understanding changes

3. **No active development**: Historical branches don't receive updates

## Branch Selection Guide

### Where Should I Start?

| Scenario | Branch |
|----------|--------|
| Bug fix for stable version | `main-testing` |
| New feature for newest version | `latest-testing` |
| Critical security fix | Appropriate `*-testing` branch |
| Version update | `latest-testing` |
| Research/comparison | `v0.x.x` (read-only) |

## Git Operations Reference

### Standard Promotion Flow
```bash
# Always follow this pattern:
git checkout [target-branch]
git pull origin [target-branch]
git merge [source-branch] --no-ff
git push origin [target-branch]
```

### Build Validation
```bash
# Always validate before promoting:
flox build comfyui
./result-comfyui/bin/comfyui --help
./result-comfyui/bin/comfyui-download
```

### Commit Message Conventions
- `fix(main): description` - Bug fixes for stable version
- `feat: description` - New features
- `hotfix: description` - Emergency fixes
- `chore: description` - Maintenance tasks
- `docs: description` - Documentation updates

## Pipeline Checklist

Before any commit:
- [ ] Changes tested locally with `flox build comfyui`
- [ ] Binary functions correctly
- [ ] Download tools work (if modified)
- [ ] Clear commit message following conventions

Before promotion:
- [ ] Source branch builds successfully
- [ ] Target branch is up to date
- [ ] Merge uses `--no-ff` flag
- [ ] Push completed successfully

## Troubleshooting

### Common Issues

**Merge conflicts during promotion**:
1. Resolve conflicts carefully
2. Test build after resolution
3. Complete merge and push

**Build failures after merge**:
1. Check for missing dependencies
2. Verify hash mismatches in .nix files
3. Test on clean checkout

**Accidental backwards merge**:
1. Reset to previous commit: `git reset --hard HEAD~1`
2. Force push to fix remote: `git push --force`
3. Re-do merge in correct direction

## Best Practices

1. **Always start in testing branches** for new work
2. **Test thoroughly** before each promotion
3. **Use clear commit messages** for future debugging
4. **Never merge backwards** (production → staging)
5. **Document emergency procedures** when deviating from normal flow
6. **Validate builds** at every step
7. **Keep historical branches pristine** for reproducible builds

---

*For questions about branching strategy, see ABOUT_THIS_REPO.md. For build procedures, see NIX_PYTHON_BUILD_GUIDE.md.*