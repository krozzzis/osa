# Collects sibling `inputs.nix` files scattered next to the denix modules
# that reference them, so a module can declare the flake input it needs
# without anyone hand-editing the root flake.nix. Each `inputs.nix` is a
# plain flake-file module: `{ ... }: { flake-file.inputs.foo.url = "..."; };`
#
# These files live inside ./modules, ./hosts, ./rices -- the same
# directories denix's own `paths` scans for NixOS/home-manager modules --
# so `findPaths` is also used to build denix's `exclude` list and keep it
# from trying (and failing) to interpret them as denix modules.
{ lib }:
rec {
  findPaths =
    dirs:
    let
      listFilesRecursive = dir:
        let
          entries = builtins.readDir dir;
          files = lib.mapAttrsToList (name: type:
            let p = dir + "/${name}"; in
            if type == "directory" then listFilesRecursive p
            else if name == "inputs.nix" then [ p ]
            else [ ]
          ) entries;
        in lib.concatLists files;
    in lib.filter (path: baseNameOf path == "inputs.nix") (lib.concatMap listFilesRecursive dirs);

  importModules = dirs: map (path: import path) (findPaths dirs);
}
