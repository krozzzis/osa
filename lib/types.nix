{ lib }:
let
  inherit (lib) mkOption types;
in
{
  # Application handles often point at a complete denix module attrset. A
  # submodule type would force that recursive attrset while options are still
  # being resolved, so validate its public fields without forcing extra keys.
  app = types.addCheck types.attrs (
    app:
    app ? pkg
    && types.package.check app.pkg
    && (!(app ? desktop) || app.desktop == null || types.str.check app.desktop)
  );

  font = types.submodule {
    options = {
      pkg = mkOption {
        type = types.package;
        description = "Font package.";
      };
      name = mkOption {
        type = types.nonEmptyStr;
        description = "Fontconfig family name.";
      };
    };
  };

}
