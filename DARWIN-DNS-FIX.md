# Fixing c-ares DNS Resolution on macOS (Darwin)

## The Problem

On macOS with Nix-built Python environments, you may see:

```
Failed to create DNS resolver channel with automatic monitoring of resolver configuration changes.
Falling back to socket state callback: Failed to initialize c-ares channel
Cannot connect to comfyregistry.
```

This affects ComfyUI Manager's ability to connect to the registry for updates and custom node listings.

## Why This Happens

The `c-ares` library is an asynchronous DNS resolver used by `grpcio` and `aiohttp`. On macOS, c-ares needs access to:

1. **SystemConfiguration framework** - macOS's native way to query DNS settings
2. **Network state notifications** - to detect when DNS servers change (e.g., switching WiFi networks)

When built in a Nix environment without proper Darwin framework dependencies, c-ares falls back to reading `/etc/resolv.conf`, which on modern macOS is often empty or points to a local stub resolver that doesn't work correctly outside the system context.

## The Fix

Add the `SystemConfiguration` framework to the Nix build inputs.

### In a Flox manifest (`manifest.toml`)

```toml
[options]
systems = ["aarch64-darwin", "x86_64-darwin", "x86_64-linux", "aarch64-linux"]

[install]
# ... other packages ...

# Darwin-specific: needed for c-ares DNS resolution
[install.darwin-frameworks]
pkg-path = "darwin.apple_sdk.frameworks.SystemConfiguration"
systems = ["aarch64-darwin", "x86_64-darwin"]
```

### In a Nix expression (flake or derivation)

```nix
{
  buildInputs = [
    # ... other inputs ...
  ] ++ lib.optionals stdenv.isDarwin [
    darwin.apple_sdk.frameworks.SystemConfiguration
  ];
}
```

Or if you're using `mkShell`:

```nix
mkShell {
  packages = [
    python3
    # ... other packages ...
  ] ++ lib.optionals stdenv.isDarwin [
    darwin.apple_sdk.frameworks.SystemConfiguration
  ];
}
```

## Additional Frameworks That May Help

If `SystemConfiguration` alone doesn't fix it, you might also need:

```nix
darwin.apple_sdk.frameworks.CoreFoundation
darwin.apple_sdk.frameworks.Security
darwin.apple_sdk.frameworks.CoreServices
```

In a Flox manifest:

```toml
[install.darwin-cf]
pkg-path = "darwin.apple_sdk.frameworks.CoreFoundation"
systems = ["aarch64-darwin", "x86_64-darwin"]

[install.darwin-security]
pkg-path = "darwin.apple_sdk.frameworks.Security"
systems = ["aarch64-darwin", "x86_64-darwin"]

[install.darwin-cs]
pkg-path = "darwin.apple_sdk.frameworks.CoreServices"
systems = ["aarch64-darwin", "x86_64-darwin"]
```

## Testing

After adding the framework(s), rebuild/reactivate the environment and check if ComfyUI Manager can connect:

```bash
# Reactivate Flox environment
flox activate

# Start ComfyUI and watch for DNS errors
comfyui 2>&1 | grep -i "c-ares\|dns\|comfyregistry"
```

If successful, you should no longer see the "Failed to initialize c-ares channel" message.

## Alternative: Disable ComfyUI Manager Registry

If you don't need the registry (you manage custom nodes manually), you can disable the network check in ComfyUI Manager's settings. This avoids the DNS issue entirely but means you lose auto-update functionality.

## Related Issues

- The DNS failure may cause socket file descriptors to leak, compounding the "Too many open files" error
- Even with the fix, you should keep `ulimit -n 10240` in your activation hook as a safeguard

## References

- [c-ares library](https://c-ares.org/)
- [Nix Darwin frameworks](https://nixos.org/manual/nixpkgs/stable/#sec-darwin)
- [grpcio DNS resolution issues](https://github.com/grpc/grpc/issues?q=c-ares+darwin)
