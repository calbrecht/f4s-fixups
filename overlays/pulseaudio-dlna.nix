final: prev:

{
  pulseaudio-dlna = prev.pulseaudio-dlna.overridePythonAttrs (old: {
    src = prev.fetchFromGitHub {
      owner = "Cygn";
      repo = "pulseaudio-dlna";
      rev = "25e7c21b1bbe51fe4ef68ef5ded126c3424ccd30";
      #rev = "3cdcf84184548e91ea25fbe60f3850768e15c2a2";
      sha256 = "sha256-qeTeCISHMs4iDhkcn301Kx7n2Gl7fNABz4UPfpt3+6E=";
      #sha256 = "sha256-V+r5akxQ40ORvnYqR+q//0VV0vK54Oy1iz+iuQbPOtU=";
    };
    #propagatedBuildInputs = [
      #  prev.python3Packages.pychromecast-9
      #] ++ (nixpkgs.lib.filter (
        #  pkg: pkg != prev.python3Packages.PyChromecast
        #) old.propagatedBuildInputs);
  });
}
