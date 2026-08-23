# Android helpers

harbor-android owns Android SDK composition, the cargo-ndk/Gradle dev shell,
Rust+Gradle APK builders, flavor expansion, and pinned Maven-cache discovery.

The consumer still owns flavor names, Cargo features, Gradle modules, API/NDK
pins, manifests, signing, and package IDs. Pass `rustToolchain` from the
workspace (typically `rs-harbor.lib.mkToolchain`); do not add `rs-harbor` as an
input of this flake.

```nix
androidSdk = harbor-android.lib.mkAndroidSdk {
  inherit pkgs;
  platformVersions = ["34"];
  buildToolsVersions = ["34.0.0"];
  ndkVersions = ["29.0.14206865"];
};

devShells.android = harbor-android.lib.mkAndroidDevShell {
  inherit pkgs androidSdk;
  ndkVersion = "29.0.14206865";
  rustToolchain = toolchain.rustToolchain;
};
```

## Flavor table

```nix
android = harbor-android.lib.mkAndroidFlavorTable {
  inherit pkgs workspaceSrc cargoVendorDir androidSdk;
  rustToolchain = toolchain.rustToolchain;
  cargoNdkPlatform = 28;
  mavenCacheTar = ./nix/android/gradle-cache.tar;
  flavors.app = {
    cargoPkg = "my-game";
    gradleModule = ":app";
    packageModes = ["debug" "release"];
  };
};
```

## Maven cache contract

A hermetic APK needs both graphs: `cargoVendorDir` from
`craneLib.vendorCargoDeps`, and `mavenCacheTar` whose archive contains a
top-level `files-2.1/` directory. Extra siblings such as `metadata-2.107` are
allowed; the builder only requires `files-2.1`.

```sh
tar --sort=name --mtime='2026-01-01 00:00:00 UTC' \
  --owner=0 --group=0 --numeric-owner \
  -cf nix/android/gradle-cache.tar \
  -C android/.gradle-cache-android/caches/modules-2 files-2.1
```

`findLocalMavenCache` returns `null` when either the hash file or tarball is
absent. An empty or invalid committed hash fails evaluation.
