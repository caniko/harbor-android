{harbor-meta}: {...}: {
  imports = [
    harbor-meta.treefmtModules.nix
    harbor-meta.treefmtModules.toml
    ./treefmt/java.nix
    ./treefmt/kotlin.nix
  ];
  projectRootFile = "flake.nix";
  settings.excludes = [
    ".github/workflows/*.yaml"
    "checks/fixtures/**"
    "templates/**"
    "tests/fixtures/**"
  ];
}
