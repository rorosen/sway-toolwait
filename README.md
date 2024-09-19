# Sway Toolwait

Really simple tool that runs a sway exec command and waits on a specified workspace for a new window
to appear. I use it to organize applications on workspaces during startup. Also works with i3.

## How to Build

```shell
nix build .\#packages.x86_64-linux.default
```

## How to Run

Specify at least the workspace and the exec command to run. This will just wait for any new window
to appear, ignoring which window it is.

```shell
./result/bin/sway-toolwait --workspace 7 --command alacritty
```

You can also use the `--waitfor` argument to pass an `app_id` (or instance string for xwayland) that
the new window must match. You can get it for example from the output of `swaymsg -t get_tree`.

```shell
./result/bin/sway-toolwait --workspace 7 --command alacritty --waitfor Alacritty
```

Use a trailing `--` to specify additional arguments that are passed to the exec command.

```shell
./result/bin/sway-toolwait --workspace 7 --command alacritty --waitfor Alacritty -- --working-directory /my/work/dir
```

Check `./result/bin/sway-toolwait --help` for all options.

## Usage with Home Manager

Import the provided home manager module and use the `wayland.windowManager.sway.toolwait` option.

```nix
imports = [ inputs.sway-toolwait.homeManagerModules.default ];

wayland.windowManager.sway.toolwait = [
  {
    command = "${pkgs.firefox}/bin/firefox";
    workspace = 1;
    waitFor = "firefox";
  }
  {
    command = "${pkgs.alacritty}/bin/alacritty";
    workspace = 2;
    waitFor = "Alacritty";
  }
  {
    command = "${pkgs.keepassxc}/bin/keepassxc";
    workspace = 10;
    waitFor = "org.keepassxc.KeePassXC";
  }
];
```
