{
  inputs = {
    # Candidate channels
    #   - https://github.com/kachick/anylang-template/issues/17
    #   - https://discourse.nixos.org/t/differences-between-nix-channels/13998
    # How to update the revision
    #   - `nix flake update --commit-lock-file` # https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake-update.html
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      rec {
        formatter = pkgs.nixfmt-tree;
        devShells.default =
          with pkgs;
          mkShell {
            env.NIX_PATH = "nixpkgs=${nixpkgs.outPath}";
            buildInputs = [
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
              nixfmt-rfc-style
              typos
            ];
          };

        packages.ruby-ulid = pkgs.stdenv.mkDerivation {
          name = "ruby-ulid";
          src = self;
          installPhase = ''
            mkdir -p $out/bin
            cp -rf ./lib $out
          '';
          runtimeDependencies = [ pkgs.ruby_3_4 ];
        };

        # `nix run`
        apps = {
          ruby = {
            type = "app";
            program =
              with pkgs;
              lib.getExe (writeShellApplication {
                name = "ruby-with-ulid";
                runtimeInputs = [ ruby_3_4 ];
                text = ''
                  ruby -r"${packages.ruby-ulid}/lib/ulid" "$@"
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
                  irb -r"${packages.ruby-ulid}/lib/ulid" "$@"
                '';
              });
          };
        };
      }
    );
}
