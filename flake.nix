{
  inputs = {
    # Candidate channels
    #   - https://github.com/kachick/anylang-template/issues/17
    #   - https://discourse.nixos.org/t/differences-between-nix-channels/13998
    # How to update the revision
    #   - `nix flake update --commit-lock-file` # https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake-update.html
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      rec {
        devShells.default = with pkgs;
          mkShell {
            buildInputs = [
              # https://github.com/NixOS/nix/issues/730#issuecomment-162323824
              bashInteractive

              ruby_3_2
              # Required to build psych via irb dependency
              # https://github.com/kachick/irb-power_assert/issues/116
              # https://github.com/ruby/irb/pull/648
              libyaml

              dprint
              tree
              nil
              nixpkgs-fmt
              typos
              actionlint
            ];
          };

        packages.ruby-ulid = pkgs.stdenv.mkDerivation
          {
            name = "ruby-ulid";
            src = self;
            # https://discourse.nixos.org/t/adding-runtime-dependency-to-flake/27785
            buildInputs = with pkgs; [
              makeWrapper
            ];
            installPhase = ''
              mkdir -p $out/bin
              cp -rf ./lib $out
              install -t $out/bin bin/pure-console.rb
              makeWrapper $out/bin/pure-console.rb $out/bin/console \
                --prefix PATH : ${nixpkgs.lib.makeBinPath [ pkgs.ruby_3_2 ]}
            '';
            runtimeDependencies = [
              pkgs.ruby_3_2
              pkgs.libyaml
            ];
          };

        packages.default = packages.ruby-ulid;

        # `nix run`
        apps = {
          console = {
            type = "app";
            program = "${packages.ruby-ulid}/bin/console";
          };
        };
      }
    );
}
