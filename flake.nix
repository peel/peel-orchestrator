{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devenv.url = "github:cachix/devenv";
    flake-parts.url = "github:hercules-ci/flake-parts";
    ai-devtools.url = "path:/Users/peel/wrk/ai-devtools";
  };

  nixConfig = {
    extra-trusted-public-keys = [
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
    extra-substituters = [
      "https://devenv.cachix.org"
      "https://cache.numtide.com"
    ];
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];

      imports = [
        inputs.devenv.flakeModule
        inputs.ai-devtools.flakeModules.ai-tools
      ];

      perSystem = {pkgs, ...}: {
        ai-tools.enable = true;

        devenv.shells.default = {
          packages = [
            pkgs.alejandra
            pkgs.gh
            pkgs.jq
          ];
          difftastic.enable = true;
          git-hooks.hooks = {
            alejandra.enable = true;
            deadnix.enable = true;
          };
        };
      };
    };
}
