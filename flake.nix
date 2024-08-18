{
  description = "Run a command and wait for a sway/i3 window to appear";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system: {
      packages.default = nixpkgs.legacyPackages.${system}.callPackage ./build.nix { };
    })
    // {
      overlays.default = _final: prev: { sway-toolwait = prev.callPackage ./build.nix { }; };
    };
}
