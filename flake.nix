{
  description = "Nixpkgs fixups overlay";

  inputs = {};

  outputs = { self, nixpkgs, ... }@inputs:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config = { allowUnfree = true; };
      overlays = [
        self.overlay
      ];
    };
  in
  {
    legacyPackages."${system}" = pkgs;

    overlay = final: prev: {
      python3 = let
        packageOverrides = python-self: python-super: {
          taskw = python-super.taskw.overridePythonAttrs (old: {
            src = prev.fetchFromGitHub {
              owner = "ralphbean";
              repo = "taskw";
              rev = "3baf339370c7cb4c62d52cb6736ed0cb458a57b5";
              sha256 = "sha256-cGTQmSATNnImYCxdGAj/yprXCUWzmeOrkWeAE3dEW3Y=";
            };
          });
          bugwarrior = python-super.bugwarrior.overridePythonAttrs (old: {
            src = prev.fetchFromGitHub {
              owner = "ralphbean";
              repo = "bugwarrior";
              rev = "89bff55e533569b7390848f35b9dd95b552e50ae";
              sha256 = "sha256-ejx6REsmf1GtlpC8lJSLqllx7+BhzjhRKTYDZmVDHIU=";
            };
          });
          pychromecast-9 = python-super.PyChromecast.overridePythonAttrs (old: {
            src = python-super.fetchPypi {
              pname = "PyChromecast";
              version = "9.4.0";
              sha256 = "sha256-Y8PLrjxZHml7BmklEJ/VXGqkRyneAy+QVA5rusPeBHQ=";
            };
          });
        };
      in prev.python3.override {inherit packageOverrides;};
      pulseaudio-dlna = prev.pulseaudio-dlna.overridePythonAttrs (old: {
        src = prev.fetchFromGitHub {
          owner = "Cygn";
          repo = "pulseaudio-dlna";
          rev = "3cdcf84184548e91ea25fbe60f3850768e15c2a2";
          sha256 = "sha256-V+r5akxQ40ORvnYqR+q//0VV0vK54Oy1iz+iuQbPOtU=";
        };
        propagatedBuildInputs = [
          prev.python3Packages.pychromecast-9
        ] ++ (nixpkgs.lib.filter (
          pkg: pkg != prev.python3Packages.PyChromecast
        ) old.propagatedBuildInputs);
      });
    };
  };
}
