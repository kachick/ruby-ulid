{
  inputs = {
    # Candidate channels
    #   - https://github.com/kachick/anylang-template/issues/17
    #   - https://discourse.nixos.org/t/differences-between-nix-channels/13998
    # How to update the revision
    #   - `nix flake update --commit-lock-file` # https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake-update.html
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      inherit (nixpkgs) lib;
      forAllSystems = lib.genAttrs lib.systems.flakeExposed;
    in
    {
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            env = {
              # Fix nixd pkgs versions in the inlay hints
              NIX_PATH = "nixpkgs=${pkgs.path}";
            };

            buildInputs = (
              with pkgs;
              [
                # https://github.com/NixOS/nix/issues/730#issuecomment-162323824
                bashInteractive

                ruby_3_4
                # Required to build psych via irb dependency
                # https://github.com/kachick/irb-power_assert/issues/116
                # https://github.com/ruby/irb/pull/648
                libyaml

                dprint
                tree
                nixd
                nixfmt-tree
                nixfmt-rfc-style
                typos
              ]
            );
          };
        }
      );

      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          ruby-ulid = pkgs.stdenv.mkDerivation {
            name = "ruby-ulid";
            src = self;
            installPhase = ''
              mkdir -p $out/bin
              cp -rf ./lib $out
            '';
            runtimeDependencies = [ pkgs.ruby_3_4 ];
          };
        }
      );

      apps = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          ruby = {
            type = "app";
            program =
              with pkgs;
              lib.getExe (writeShellApplication {
                name = "ruby-with-ulid";
                runtimeInputs = [ ruby_3_4 ];
                text = ''
                  ruby -r"${self.packages.${system}.ruby-ulid}/lib/ulid" "$@"
                '';
              });
          };

          irb = {
            type = "app";
            program =
              with pkgs;
              lib.getExe (writeShellApplication {
                name = "irb-with-ulid";
                runtimeInputs = [
                  ruby_3_4
                  libyaml
                ];
                text = ''
                  irb -r"${self.packages.${system}.ruby-ulid}/lib/ulid" "$@"
                '';
              });
          };
        }
      );
    };
}
