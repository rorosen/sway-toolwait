{
  lib,
  rustPlatform,
  nix-gitignore,
}:
rustPlatform.buildRustPackage {
  pname = "sway-toolwait";
  version = "0.2.0";
  src = nix-gitignore.gitignoreSource [ ] ./.;
  cargoLock.lockFile = ./Cargo.lock;

  meta = {
    description = "Run a command and wait for a sway/i3 window to appear";
    homepage = "https://github.com/rorosen/sway-toolwait";
    license = lib.licenses.mit;
    maintainers = [ lib.maintainers.rorosen ];
  };
}
