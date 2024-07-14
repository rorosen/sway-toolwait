# Sway Toolwait

Really simple tool that runs a sway exec command and waits on a specified
workspace for a new window to appear. I use it to organize applications on
workspaces during startup. Also works with i3.

## How to Build

Use Nix to build it for your architecture.

```shell
nix build .\#packages.x86_64-linux.default
```

## How to Run

Specify at least the workspace and the exec command that should be run.

```shell
./result/bin/sway-toolwait --workspace 7 --command alacritty
```

You can also pass an `app_id` (or instance string for xwayland) that the new
window must match. You can get it from the output of `swaymsg -t get_tree`.

```shell
./result/bin/sway-toolwait --workspace 7 --command alacritty --waitfor Alacritty
```

Check `./result/bin/sway-toolwait --help` for all options.
