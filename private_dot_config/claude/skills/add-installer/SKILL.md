---
name: add-installer
description: Add a package installer to this dotfiles repo.
---

# Add installer

1. Create `installers/packages/posix/NN-name.sh` and, when Windows applies,
   `installers/packages/win/NN-name.ps1` with the suitable number.
2. The leading number picks the install group: `0x` shell, `1x`–`2x` build,
   `3x` runtimes, `4x` editor, `5x` ai, `6x` tools, `7x` operations,
   `8x` terminal, `9x` input, `cx` communication, `gx` gaming,
   `dx` desktop extensions.
3. Read `installers/lib/posix/helpers.sh` (or `installers/lib/win/helpers.ps1`)
   and a neighboring installer for the available helpers and the expected
   shape.
4. Add the package to its group row in `PACKAGES.md`.
