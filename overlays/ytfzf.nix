final: prev:

{
  fzf = prev.fzf.overrideAttrs (old: {
    nativeBuildInputs = old.nativeBuildInputs ++ [ prev.makeWrapper ];
    postInstall = old.postInstall + ''
      wrapProgram "$out/bin/fzf" \
        --run "test -e ~/.config/fzf && source ~/.config/fzf"
      '';
  });

  ytfzf = prev.ytfzf.overrideAttrs (old: rec {
    pname = "ytfzf";
    version = "2.6.0-overlay";

    src = prev.fetchFromGitHub {
      owner = "calbrecht";
      repo = "ytfzf";
      rev = "520485a19c02f572e530661aaf26a988f664e966";
      hash = "sha256-RBNQRrlhJzvi52SqTc7AmUU5T77cBUry+Wp3YcYkG7Y=";
    };
  });
}
