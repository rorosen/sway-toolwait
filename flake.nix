{
  description = "Run a command and wait for a sway/i3 window to appear";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachSystem
      [
        "x86_64-linux"
        "aarch64-linux"
      ]
      (system: {
        packages.default = nixpkgs.legacyPackages.${system}.callPackage ./build.nix { };
      })
    // {
      overlays.default = _final: prev: { sway-toolwait = prev.callPackage ./build.nix { }; };
      homeManagerModules.default =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          cfg = config.wayland.windowManager.sway;
          mkToolwait =
            {
              command,
              workspace,
              waitFor,
              timeout,
            }:
            ''
              ${pkgs.sway-toolwait}/bin/sway-toolwait \
                --workspace ${builtins.toString workspace} \
                --command "${command}" \
                --timeout ${builtins.toString timeout} \
                ${if waitFor == "" then "--nocheck" else "--waitfor ${waitFor}"}
            '';

          toolwaitScript = pkgs.writeShellScript "sway-toolwait" ''
            ${builtins.concatStringsSep "\n" (map mkToolwait cfg.toolwait)}
          '';
        in
        {
          options.wayland.windowManager.sway.toolwait = lib.mkOption {
            type =
              with lib.types;
              listOf (submodule {
                options = {
                  command = lib.mkOption {
                    type = lib.types.nonEmptyStr;
                    description = "Command to run.";
                  };

                  workspace = lib.mkOption {
                    type = lib.types.ints.unsigned;
                    description = "Workspace number on which to run the command.";
                  };

                  waitFor = lib.mkOption {
                    type = lib.types.str;
                    default = "";
                    description = ''
                      app_id (wayland) or instance string (xwayland) to wait for.
                      Defaults to the attribute name.
                    '';
                  };

                  timeout = lib.mkOption {
                    type = lib.types.ints.unsigned;
                    default = 5;
                    description = "Maximum seconds to wait for a matching new windoe";
                  };
                };
              });
            default = [ ];
            example = lib.literalExpression ''
              [
                {
                  command = "''${pkgs.firefox}/bin/firefox";
                  workspace = 1;
                  waitFor = "firefox";
                }
                {
                  command = "''${pkgs.keepassxc}/bin/keepassxc";
                  workspace = 9;
                  waitFor = "org.keepassxc.KeePassXC";
                }
              ]
            '';
            description = ''
              Applications that should be launched synchronously on specific workspaces at startup.
            '';
          };
          config.wayland.windowManager.sway.extraConfig = lib.mkIf (cfg.toolwait != { }) (
            lib.mkAfter ''
              exec ${toolwaitScript}
            ''
          );
        };
    };
}
