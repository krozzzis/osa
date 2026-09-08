{
  delib,
  lib,
  ...
}:
delib.module {
  name = "osa.ai.opencode";

  options = { myconfig, ... }: {
    osa.ai.opencode.enable = delib.boolOption myconfig.user.gui.enable;
  };

  home.ifEnabled =
    { myconfig, ... }:
    let
      enabledServers = lib.filterAttrs (_name: srv: srv.enable) myconfig.user.dev.mcp;

      mkMcpServer =
        _name: server:
        {
          type = server.type;
          enabled = true;
        }
        // lib.optionalAttrs (server.command != null) {
          command = server.command;
        }
        // lib.optionalAttrs (server.url != null) {
          url = server.url;
        };

      mcpServers = builtins.listToAttrs (
        map (name: {
          inherit name;
          value = mkMcpServer name myconfig.user.dev.mcp.${name};
        }) (builtins.attrNames enabledServers)
      );
    in
    {
      programs.opencode = {
        enable = true;
        settings = {
          mcp = mcpServers;
          permission = {
            read = "allow";
            edit = "allow";
            bash = "allow";
            glob = "allow";
            grep = "allow";
            list = "allow";
            websearch = "allow";
            webfetch = "allow";
            todowrite = "allow";
          };
        };
        # Прозрачная тема — без background, чтобы была видна прозрачность wezterm
        themes.transparent = {
          theme = {
            primary = "#89b4fa";
            secondary = "#fab387";
            accent = "#cba6f7";
            error = "#f38ba8";
            warning = "#fab387";
            success = "#a6e3a1";
            info = "#89dceb";
            text = "#cdd6f4";
            textMuted = "#6c7086";
            background = "none";
            backgroundPanel = "none";
            backgroundElement = "none";
            border = "none";
            borderActive = "none";
            borderSubtle = "none";
            diffAdded = "#a6e3a1";
            diffRemoved = "#f38ba8";
            diffContext = "#6c7086";
            diffHunkHeader = "#6c7086";
            diffAddedBg = "none";
            diffRemovedBg = "none";
            diffContextBg = "none";
            diffHighlightAdded = "#a6e3a1";
            diffHighlightRemoved = "#f38ba8";
            diffLineNumber = "#6c7086";
            diffAddedLineNumberBg = "none";
            diffRemovedLineNumberBg = "none";
            markdownText = "#cdd6f4";
            markdownHeading = "#89b4fa";
            markdownLink = "#89b4fa";
            markdownLinkText = "#89b4fa";
            markdownCode = "#a6e3a1";
            markdownBlockQuote = "#6c7086";
            markdownEmph = "#f38ba8";
            markdownStrong = "#fab387";
            markdownHorizontalRule = "#6c7086";
            markdownListItem = "#89b4fa";
            markdownListEnumeration = "#89b4fa";
            markdownImage = "#89b4fa";
            markdownImageText = "#89b4fa";
            markdownCodeBlock = "#cdd6f4";
            syntaxComment = "#6c7086";
            syntaxKeyword = "#cba6f7";
            syntaxFunction = "#89b4fa";
            syntaxVariable = "#cdd6f4";
            syntaxString = "#a6e3a1";
            syntaxNumber = "#fab387";
            syntaxType = "#89dceb";
            syntaxOperator = "#89b4fa";
            syntaxPunctuation = "#9399b2";
          };
        };
        tui.theme = "transparent";
      };
    };
}
