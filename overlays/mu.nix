final: prev:

{
  mu = prev.mu.overrideAttrs (old: rec {
    pname = "mu";
    version = "2023-01-11";

    src = prev.fetchFromGitHub {
      owner = "djcb";
      repo = "mu";
      #rev = "v${version}";
      rev = "551bc46b47b740ef90e3f01c333c50d039ee1a2f";
      hash = "sha256-LZ3le0X9QPdeRczWkt1xglI2QpDjFUP8kGDTbTOBKDA=";
    };

    postPatch = ''
      ls -la .
      substituteInPlace mu4e/meson.build \
      --replace "'-o'" "'--no-validate', '--force', '-o'"
      substituteInPlace lib/utils/mu-test-utils.cc \
      --replace "/bin/rm" "rm"
    '';
  });
}
