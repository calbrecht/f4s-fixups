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
        # no, it doesn't 2025-03-25
        #fcft = prev.fcft.overrideAttrs (old: rec {
        #  version = "3.2.0";
        #  src = prev.fetchFromGitea {
        #    domain = "codeberg.org";
        #    owner = "dnkl";
        #    repo = "fcft";
        #    rev = version;
        #    hash = "sha256-VMNjTOil50/GslSzZnBPkSoy0Vg0729ndaEAeXk00GI=";
        #  };
        #});
        wl-mirror = prev.wl-mirror.overrideAttrs (old: let
          newer = "0.18.0";
          older = prev.lib.versionOlder old.version newer;
        in rec {
          version = if older then newer else old.version;
          src = if older then (prev.fetchFromGitHub {
            owner = "Ferdi265";
            repo = "wl-mirror";
            rev = "v${version}";
            hash = "sha256-Ba7Q5tPM3L9P6D5sXHFgzSrJmVW10jdRLsv5BnEkhHs="; #prev.lib.fakeHash;
          }) else old.src;
          buildInputs = old.buildInputs ++ [
            prev.libgbm
          ];
          cmakeFlags = (old.cmakeFlags or []) ++ [
            "-DWITH_GBM=ON"
          ];
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
