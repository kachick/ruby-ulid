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
            # https://discourse.nixos.org/t/mkderivation-src-as-list-of-filenames/3537/2
            # srcs = [
            #   ./lib
            #   ./bin
            # ];
            # nativeBuildInputs = [ pkgs.makeWrapper ];
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
              # mkdir -p $out/lib
              cp -rf ./lib $out
              install -t $out/bin bin/console
              makeWrapper $out/bin/console $out/bin/wrapped_console \
                --prefix PATH : ${nixpkgs.lib.makeBinPath [ ruby ]}
            '';
            runtimeDependencies = [
              ruby
            ];
            shellHook = ''
              bundle install
            '';
          };

        packages.default = packages.ruby-ulid;

        # `nix run`
        apps = {
          irb = {
            type = "app";
            program = "${packages.ruby-ulid}/bin/wrapped_console";
          };
        };
      }
    );
}
