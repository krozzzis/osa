# For osa/ui/conflux.nix.
{ ... }:
{
  flake-file.inputs.conflux-icon-theme = {
    url = "github:MoshiurRahmanAdib/Conflux-Icon-Theme";
    flake = false;
  };
}
