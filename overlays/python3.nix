final: prev:

{
  python3 = let
    packageOverrides = python-self: python-super: {

      pycurl = python-super.pycurl.overridePythonAttrs (old: {
        disabledTests = old.disabledTests ++ [
          "test_request_with_verifypeer"
          "test_getinfo_raw_certinfo"
          "test_request_with_certinfo"
          "test_request_without_certinfo"
        ];
      });
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

      youtube-dl = python-super.youtube-dl.overridePythonAttrs (old: {
        pname = "youtube-dl";
        version = "2022.05.15";

        src = prev.fetchFromGitHub {
          owner = "ytdl-org";
          repo = "youtube-dl";
          rev = "c7965b9fc2cae54f244f31f5373cb81a40e822ab";
          sha256 = "sha256-PrXo8mNlNTD+Fjcb93LUsY5huAR9UCcvR/ujb3zT+1g=";
          #sha256 = pkgs.lib.fakeSha256;
        };

        patches = [];
        postInstall = "";
      });

    };
  in prev.python3.override {inherit packageOverrides;};

  python3Packages = final.python3.pkgs;
}
