{
  description = "Nixpkgs fixups overlay";

  nixConfig = {
    flake-registry = "https://github.com/calbrecht/f4s-registry/raw/main/flake-registry.json";
  };

  outputs = { self, nixpkgs, ... }@inputs:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config = { allowUnfree = true; };
      overlays = [
        self.overlays.default
      ];
    };
  in
  {
    legacyPackages."${system}" = pkgs;

    overlays = {
      default = self.overlays.fixups;
      fixups = final: prev: {
        # foot needs newer fcft
        fcft = prev.fcft.overrideAttrs (old: rec {
          version = "3.2.0";
          src = prev.fetchFromGitea {
            domain = "codeberg.org";
            owner = "dnkl";
            repo = "fcft";
            rev = version;
            hash = "sha256-VMNjTOil50/GslSzZnBPkSoy0Vg0729ndaEAeXk00GI=";
          };
        });
      }
        #// (import ./overlays/mu.nix final prev)
        // (import ./overlays/goimapnotify.nix final prev)
        #// (import ./overlays/fmt_8.nix final prev)
        #// (import ./overlays/lit.nix final prev)
        #// (import ./overlays/python3.nix final prev)
        #// (import ./overlays/pulseaudio-dlna.nix final prev)
        #// (import ./overlays/f2fs-tools.nix final prev)
        // (import ./overlays/ytfzf.nix final prev)
        // (import ./overlays/zfs_autobackup.nix final prev)
        ;
    };
  };
}
