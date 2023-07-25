{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    nixpkgs-ruby.url = "github:bobvanderlinden/nixpkgs-ruby";
    nixpkgs-ruby.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, nixpkgs-ruby, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        ruby = nixpkgs-ruby.lib.packageFromRubyVersionFile {
          file = ./.ruby-version;
          inherit system;
        };
      in
      rec {
        devShells.default = with pkgs;
          mkShell {
            buildInputs = [
              ruby
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
            # buildPhase = ''
            #   # https://github.com/NixOS/nix/issues/670#issuecomment-1211700127
            #   export HOME=$(pwd)
            #   task build
            # '';
            installPhase = ''
              mkdir -p $out/bin
              cp -rf ./lib $out
              install -t $out/bin bin/tutor.rb
              makeWrapper $out/bin/tutor.rb $out/bin/tutor \
                --prefix PATH : ${nixpkgs.lib.makeBinPath [ ruby ]}
            '';
            runtimeDependencies = [
              ruby
            ];
          };

        packages.default = packages.ruby-ulid;

        # `nix run`
        apps = {
          console = {
            type = "app";
            program = "${packages.ruby-ulid}/bin/tutor";
          };
        };
      }
    );
}
