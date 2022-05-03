{
  description = "Nixpkgs fixups overlay";

  inputs = {};

  outputs = { self, nixpkgs, ... }@inputs:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config = { allowUnfree = true; };
      overlays = [
        self.overlay
      ];
    };
  in
  {
    legacyPackages."${system}" = pkgs;

    overlay = final: prev: {

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

      glslang = (prev.glslang.override {
        inherit (final) spirv-headers spirv-tools;
      }).overrideAttrs (old: rec {
        version = "1.3.204.1";

        src = pkgs.fetchFromGitHub {
          owner = "KhronosGroup";
          repo = "glslang";
          rev = "sdk-${version}";
          sha256 = "sha256-Q0sk4bPj/skPat1n4GJyuXAlZqpfEn4Td8Bm2IBNUqE=";
        };
      });

      opencl-clang = (prev.opencl-clang.override {
        inherit (final) spirv-llvm-translator;
        buildWithPatches = false;
      }).overrideAttrs (old: {
        version = "ocl-open-110";

        passthru = {};

        #patches = [];

        src = pkgs.fetchFromGitHub {
          owner = "intel";
          repo = "opencl-clang";
          rev = "bbdd1587f577397a105c900be114b56755d1f7dc";
          sha256 = "sha256-qEZoQ6h4XAvSnJ7/gLXBb1qrzeYa6Jp6nij9VFo8MwQ=";
        };
      });

      spirv-headers = prev.spirv-headers.overrideAttrs (old: rec {
        version = "1.3.204.1";

        src = pkgs.fetchFromGitHub {
          owner = "KhronosGroup";
          repo = "SPIRV-Headers";
          rev = "sdk-${version}";
          sha256 = "sha256-ks9JCj5rj+Xu++7z5RiHDkU3/sFXhcScw8dATfB/ot0=";
        };
      });

      spirv-tools = (prev.spirv-tools.override {
        inherit (final) spirv-headers;
      }).overrideAttrs (old: rec {
        version = "1.3.204.1";

        src = pkgs.fetchFromGitHub {
          owner = "KhronosGroup";
          repo = "SPIRV-Tools";
          rev = "sdk-${version}";
          sha256 = "sha256-DSqZlwfNTbN4fyIrVBKltm5U2U4GthW3L+Ksw4lSVG8=";
        };

        prePatch = ''
          substituteInPlace ./cmake/SPIRV-Tools.pc.in \
            --replace '/@CMAKE_INSTALL_INCLUDEDIR@' "/include" \
            --replace '/@CMAKE_INSTALL_LIBDIR@' "/lib"

          substituteInPlace ./cmake/SPIRV-Tools-shared.pc.in \
            --replace '/@CMAKE_INSTALL_INCLUDEDIR@' "/include" \
            --replace '/@CMAKE_INSTALL_LIBDIR@' "/lib"
        '';
      });

      spirv-llvm-translator = prev.spirv-llvm-translator.overrideAttrs (old: {
          version = "llvm_release_110";

          src = pkgs.fetchFromGitHub {
            owner = "KhronosGroup";
            repo = "SPIRV-LLVM-Translator";
            rev = "99420daab98998a7e36858befac9c5ed109d4920";
            sha256 = "sha256-/vUyL6Wh8hykoGz1QmT1F7lfGDEmG4U3iqmqrJxizOg=";
          };

          buildInputs = [
            final.spirv-headers
            final.spirv-tools
          ] ++ old.buildInputs;

          cmakeFlags = [
            "-DLLVM_DIR=${prev.llvm_11.dev}"
            "-DLLVM_SPIRV_BUILD_EXTERNAL=YES"
            "-DLLVM_EXTERNAL_LIT=${final.lit}/bin/lit"
          ] ++ old.cmakeFlags;

          makeFlags = [ "llvm-spirv" ];

          doCheck = true;
      });

      intel-graphics-compiler = let
          vc_intrinsics_src = pkgs.fetchFromGitHub {
            owner = "intel";
            repo = "vc-intrinsics";
            rev = "v0.3.0";
            sha256 = "sha256-1Rm4TCERTOcPGWJF+yNoKeB9x3jfqnh7Vlv+0Xpmjbk=";
          };
      in (prev.intel-graphics-compiler.override {
        inherit (final) spirv-llvm-translator;
        opencl-clang = final.opencl-clang.overrideAttrs (old: {
          clang = prev.llvmPackages_11.clang;
          libclang = prev.llvmPackages_11.libclang;
          spirv-llvm-translator = final.spirv-llvm-translator;
        });
        buildWithPatches = true;
      }).overrideAttrs (old: rec {
        version = "1.0.11061";

        src = pkgs.fetchFromGitHub {
          owner = "intel";
          repo = "intel-graphics-compiler";
          rev = "igc-${version}";
          sha256 = "sha256-qS/+GTqHtp3T6ggPKrCDsrTb7XvVOUaNbMzGU51jTu4=";
        };

        buildInputs = [
          final.spirv-tools
          final.spirv-headers
        ] ++ old.buildInputs;

        prePatch = ''
          substituteInPlace ./external/SPIRV-Tools/CMakeLists.txt \
            --replace '$'''{SPIRV-Tools_DIR}../../..' \
                      '${final.spirv-tools}' \
            --replace 'SPIRV-Headers_INCLUDE_DIR "/usr/include"' \
                      'SPIRV-Headers_INCLUDE_DIR "${final.spirv-headers}/include"' \
            --replace 'set_target_properties(SPIRV-Tools' \
                      'set_target_properties(SPIRV-Tools-static' \
            --replace 'IGC_BUILD__PROJ__SPIRV-Tools SPIRV-Tools' \
                      'IGC_BUILD__PROJ__SPIRV-Tools SPIRV-Tools-static'

          substituteInPlace ./IGC/AdaptorOCL/igc-opencl.pc.in \
            --replace '/@CMAKE_INSTALL_INCLUDEDIR@' "/include" \
            --replace '/@CMAKE_INSTALL_LIBDIR@' "/lib"
        '';

        cmakeFlags = [
          "-Wno-dev"
          "-DVC_INTRINSICS_SRC=${vc_intrinsics_src}"
          "-DIGC_OPTION__SPIRV_TOOLS_MODE=Prebuilds"
          "-DIGC_OPTION__USE_PREINSTALLED_SPRIV_HEADERS=ON"
        ] ++ (pkgs.lib.filter (
          flag: (
            "-DVC_INTRINSICS_SRC" != builtins.substring 0 19 flag
          )
        ) old.cmakeFlags);
      });

      intel-compute-runtime = (prev.intel-compute-runtime.override {
        inherit (final) intel-graphics-compiler;
      }).overrideAttrs (old: rec {
        version = "22.17.23034";

        src = pkgs.fetchFromGitHub {
          owner = "intel";
          repo = "compute-runtime";
          rev = version;
          sha256 = "sha256-ae6kPiVQe3+hcqXVu2ncCaVQAoMKoDHifrkKpt6uWX8=";
        };

        buildInputs = [
          #final.opencl-clang
          #final.opencl-clang.clang
          #final.opencl-clang.libclang
          #final.llvmPackages_11.llvm
          #final.lld_11
        ] ++ old.buildInputs;

        #NIX_LD_FLAGS = "-L${prev.gccForLibs.lib}/lib";

        cmakeFlags = [
          #"-DNEO_DISABLE_BUILTINS_COMPILATION=ON"
          "-DIGC_DIR=${final.intel-graphics-compiler}"
        ] ++ (pkgs.lib.filter (
          flag: (
            "-DIGC_DIR" != builtins.substring 0 9 flag
          )
        ) old.cmakeFlags);
      });

      python3 = let
        packageOverrides = python-self: python-super: {

          pycurl = python-super.pycurl.overridePythonAttrs (old: {
            disabledTests = old.disabledTests ++ [
              "test_request_with_verifypeer"
              "test_getinfo_raw_certinfo"
              "test_request_with_certinfo"
              "test_request_without_certinfo"
            ];
          });
          taskw = python-super.taskw.overridePythonAttrs (old: {
            src = prev.fetchFromGitHub {
              owner = "ralphbean";
              repo = "taskw";
              rev = "3baf339370c7cb4c62d52cb6736ed0cb458a57b5";
              sha256 = "sha256-cGTQmSATNnImYCxdGAj/yprXCUWzmeOrkWeAE3dEW3Y=";
            };
          });
          bugwarrior = python-super.bugwarrior.overridePythonAttrs (old: {
            src = prev.fetchFromGitHub {
              owner = "ralphbean";
              repo = "bugwarrior";
              rev = "89bff55e533569b7390848f35b9dd95b552e50ae";
              sha256 = "sha256-ejx6REsmf1GtlpC8lJSLqllx7+BhzjhRKTYDZmVDHIU=";
            };
          });
          pychromecast-9 = python-super.PyChromecast.overridePythonAttrs (old: {
            src = python-super.fetchPypi {
              pname = "PyChromecast";
              version = "9.4.0";
              sha256 = "sha256-Y8PLrjxZHml7BmklEJ/VXGqkRyneAy+QVA5rusPeBHQ=";
            };
          });
        };
      in prev.python3.override {inherit packageOverrides;};
      python3Packages = final.python3.pkgs;
      pulseaudio-dlna = prev.pulseaudio-dlna.overridePythonAttrs (old: {
        src = prev.fetchFromGitHub {
          owner = "Cygn";
          repo = "pulseaudio-dlna";
          rev = "3cdcf84184548e91ea25fbe60f3850768e15c2a2";
          sha256 = "sha256-V+r5akxQ40ORvnYqR+q//0VV0vK54Oy1iz+iuQbPOtU=";
        };
        propagatedBuildInputs = [
          prev.python3Packages.pychromecast-9
        ] ++ (nixpkgs.lib.filter (
          pkg: pkg != prev.python3Packages.PyChromecast
        ) old.propagatedBuildInputs);
      });
    };
  };
}
