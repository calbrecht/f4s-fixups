final: prev:

{
  fmt_8 = prev.fmt_8.overrideAttrs (old: rec {
    version = "8.1.1";
    src = prev.fetchFromGitHub {
      owner = "fmtlib";
      repo = "fmt";
      rev = version;
      sha256 = "sha256-leb2800CwdZMJRWF5b1Y9ocK0jXpOX/nwo95icDf308=";
    };
  });
}
