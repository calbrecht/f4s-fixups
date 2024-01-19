final: prev:

{
  zfs-autobackup = prev.zfs-autobackup.overridePythonAttrs (old: rec {
    version = "3.2";

    src = prev.fetchPypi {
      inherit version;
      pname = "zfs_autobackup";
      sha256 = "sha256-rvtY7fsn2K2hueAsQkaPXcwxUAgE8j+GsQFF3eJKG2o=";
    };
  });
}
