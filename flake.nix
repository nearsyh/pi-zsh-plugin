{
  description = "ZSH helper plugin for pi";

  outputs =
    { self, nixpkgs }:
    let
      forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.stdenv.mkDerivation {
            pname = "pi-zsh";
            version = self.shortRev or self.dirtyShortRev or "dev";
            src = self;

            installPhase = ''
              runHook preInstall
              mkdir -p $out/share/pi-zsh
              cp -r lib pi-zsh.plugin.zsh pi.theme.zsh README.md $out/share/pi-zsh/
              runHook postInstall
            '';
          };
        }
      );
    };
}
