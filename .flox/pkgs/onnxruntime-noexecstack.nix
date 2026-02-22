# onnxruntime-noexecstack: Patched onnxruntime for hardened kernels
# ================================================================
# The nixpkgs onnxruntime .so has GNU_STACK with RWE (executable stack).
# Hardened kernels (Debian 13+) refuse to load it:
#   "cannot enable executable stack as shared object requires: Invalid argument"
#
# This overrides the Python package and patches the single byte
# in the ELF header to clear PF_X from GNU_STACK (RWE -> RW).
#
# When nixpkgs fixes this upstream, remove this wrapper and use
# python3.pkgs.onnxruntime directly.

{ lib
, python3
}:

python3.pkgs.onnxruntime.overridePythonAttrs (old: {
  pname = "onnxruntime-noexecstack";

  postFixup = (old.postFixup or "") + ''
    # Find and patch all .so files that have executable stack
    find $out -name '*.so' 2>/dev/null | while read so; do
      # Check if this .so has PT_GNU_STACK with PF_X set
      python3 << PYEOF
import struct, sys

try:
    with open("$so", "r+b") as f:
        f.seek(0)
        magic = f.read(4)
        if magic != b'\x7fELF':
            sys.exit(0)
        ei_class = struct.unpack('B', f.read(1))[0]
        if ei_class != 2:
            sys.exit(0)
        f.seek(32)
        e_phoff = struct.unpack('<Q', f.read(8))[0]
        f.seek(54)
        e_phentsize = struct.unpack('<H', f.read(2))[0]
        e_phnum = struct.unpack('<H', f.read(2))[0]
        for i in range(e_phnum):
            offset = e_phoff + i * e_phentsize
            f.seek(offset)
            p_type = struct.unpack('<I', f.read(4))[0]
            if p_type == 0x6474e551:  # PT_GNU_STACK
                f.seek(offset + 4)
                p_flags = struct.unpack('<I', f.read(4))[0]
                if p_flags & 1:  # PF_X set
                    f.seek(offset + 4)
                    f.write(struct.pack('<I', p_flags & ~1))
                    print(f"Cleared execstack: $so")
                break
except Exception as e:
    print(f"Warning: Failed to patch $so: {e}")
PYEOF
    done || true
  '';

  nativeBuildInputs = (old.nativeBuildInputs or []) ++ [ python3 ];

  meta = old.meta // {
    description = "ONNX Runtime with execstack flag cleared for hardened kernels";
  };
})
