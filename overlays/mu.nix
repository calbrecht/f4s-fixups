final: prev:

{
  mu = prev.mu.overrideAttrs (old: rec {
    pname = "mu";
    version = "1.10.5";

    src = prev.fetchFromGitHub {
      owner = "djcb";
      repo = "mu";
      rev = "v${version}";
      #rev = "551bc46b47b740ef90e3f01c333c50d039ee1a2f";
      #hash = "sha256-LZ3le0X9QPdeRczWkt1xglI2QpDjFUP8kGDTbTOBKDA=";
      hash = "sha256-ha3ckyRNzWF52unY6Pw2M6qeUdC68SGHFvzJ8Jbk2fY=";
    };

    postPatch = ''
      substituteInPlace mu4e/meson.build \
        --replace "'-o'" "'--no-validate', '--force', '-o'"
      substituteInPlace lib/utils/mu-test-utils.cc \
        --replace "/bin/rm" "rm"
    '';
  });
}
