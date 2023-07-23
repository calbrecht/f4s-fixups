final: prev:

{
  lit = prev.lit.overridePythonAttrs (old: {
    prePatch = ''
      substituteInPlace ./lit/llvm/config.py \
        --replace "os.path.join(self.config.llvm_tools_dir, 'llvm-config')" \
                  "'${prev.llvm_11.dev}/bin/llvm-config'" \
        --replace "clang_dir, _ = self.get_process_output(" \
                  "" \
        --replace "    [clang, '-print-file-name=include'])" \
                  "clang_dir = '${prev.llvmPackages_11.clang}/resource-root/include'"
    '';
    nativeBuildInputs = [ prev.makeWrapper ];
    postInstall = ''
      wrapProgram $out/bin/lit \
        --set-default CLANG ${prev.llvmPackages_11.clang}/bin/clang
    '';
  });
}
