{
  description = "Run a command and wait for a sway/i3 window to appear";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      crane,
      flake-utils,
      ...
    }:
    let
      mkSwayToolwait =
        pkgs:
        let
          craneLib = crane.mkLib pkgs;
          src = craneLib.cleanCargoSource (craneLib.path ./.);
          commonArgs = {
            inherit src;
            inherit (craneLib.crateNameFromCargoToml { cargoToml = ./Cargo.toml; }) pname version;
          };
          cargoArtifacts = craneLib.buildDepsOnly commonArgs;
        in
        craneLib.buildPackage (commonArgs // { inherit cargoArtifacts; });
    in
    (flake-utils.lib.eachDefaultSystem (system: {
      packages.default = mkSwayToolwait nixpkgs.legacyPackages.${system};
    }))
    // {
      overlays.default = _final: prev: { sway-toolwait = mkSwayToolwait prev; };
    };
}
