# harbor-android

Reusable Android SDK, NDK, and APK helpers for Nix flakes.

- `mkAndroidSdk` — one `composeAndroidPackages` from caller `pkgs` (versions required)
- `mkAndroidDevShell` — `ANDROID_*` env + cargo-ndk / JDK / Gradle
- `mkAndroidApk` / `mkAndroidApkDevBuilder` / `mkAndroidFlavorTable` — Rust cdylib + Gradle APK
- `findLocalMavenCache` — optional host tarball pinned by a committed SHA-256

`rustToolchain` is an argument (usually from `rs-harbor.lib.mkToolchain`). This flake does not take `rs-harbor` as an input.

```bash
nix flake init -t github:caniko/harbor-android
```
