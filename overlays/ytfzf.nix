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
      rev = "bc0a760b53166fa6b22288571a1ac111a3a6ac0f";
      hash = "sha256-OPJVvo0TKHl8eaMikXNDeU43R34R0DlVyH+lHOKe9oY=";
    };
  });
}
