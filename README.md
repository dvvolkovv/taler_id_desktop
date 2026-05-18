# taler_id_desktop (ARCHIVED)

This repository has been merged into [taler_id_mobile](https://github.com/dvvolkovv/taler_id_mobile) as part of the unified-codebase migration completed 2026-05-15.

The mobile repository now ships all 5 platforms — iOS, Android, macOS, Windows, Linux — from a single codebase, with platform-specific code gated through `lib/core/platform/` abstractions.

## Desktop releases

Download for macOS, Windows, or Linux at https://id.taler.tirol — first end-user desktop release shipped 2026-05-18 (v1.0.74+167).

## Source code

https://github.com/dvvolkovv/taler_id_mobile

## Why archive

This repo's last meaningful commit was at v1.0.48 (April 2026). Mobile had since shipped to v1.0.71 with substantial new features. Keeping two diverging codebases became unsustainable — every fix had to be applied twice or skipped. The unified-repo migration eliminated that drift.

This repository is preserved in read-only mode for git history reference. No new commits will be merged here.
