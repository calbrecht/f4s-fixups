final: prev:

{
  fzf = prev.fzf.overrideAttrs (old: {
    nativeBuildInputs = old.nativeBuildInputs ++ [ prev.makeWrapper ];
    postInstall = old.postInstall + ''
      wrapProgram "$out/bin/fzf" \
        --run "test -e ~/.config/fzf && source ~/.config/fzf"
      '';
  });

  ytfzf = prev.ytfzf.overrideAttrs (old: {
    pname = "ytfzf";
    version = "2.6.0-overlay";

    src = prev.fetchFromGitHub {
      owner = "calbrecht";
      repo = "ytfzf";
      rev = "ffc2f4cb5c19a254f014b853d5fb85746c6f805d";
      hash = "sha256-4V/FfppI4HF3SR/D0ymXuY6+dR46NxbxkuzwI4xU8dc=";
    };
  });
}
