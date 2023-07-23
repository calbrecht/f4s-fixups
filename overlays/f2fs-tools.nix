final: prev:

{
  f2fs-tools = prev.f2fs-tools.overrideAttrs (old: rec {
    version = "1.15.0";

    src = prev.fetchgit {
      url = "https://git.kernel.org/pub/scm/linux/kernel/git/jaegeuk/f2fs-tools.git";
      rev = "refs/tags/v${version}";
      sha256 = "sha256-RSWvdC6kV0KfyJefK9qyFCWjlezFc7DBOOn+uy7S3Lk=";
    };
  });
}
