{
  description = "Nixpkgs fixups overlay";

  nixConfig = {
    flake-registry = https://github.com/calbrecht/f4s-registry/raw/main/flake-registry.json;
  };

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
    nixops-extraArgs-patch = pkgs.writeText "nixops-extraArgs.patch" ''
      From 4e74a8697050249781f7220a665ec2eebdb0a6b4 Mon Sep 17 00:00:00 2001
From: Robin Gloster <mail@glob.in>
Date: Mon, 11 Jul 2022 18:33:32 +0200
Subject: [PATCH] eval-machine-info: fix deprecation warning

---
 nix/eval-machine-info.nix | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/nix/eval-machine-info.nix b/nix/eval-machine-info.nix
index e2e1def5..f2bc621f 100644
--- a/nix/eval-machine-info.nix
+++ b/nix/eval-machine-info.nix
@@ -57,9 +57,10 @@ rec {
                 networking.hostName = mkOverride 900 machineName;
                 deployment.targetHost = mkOverride 900 machineName;
                 environment.checkConfigurationOptions = mkOverride 900 checkConfigurationOptions;
+
+                _module.args = { inherit nodes resources uuid deploymentName; name = machineName; };
               }
             ];
-          extraArgs = { inherit nodes resources uuid deploymentName; name = machineName; };
         };
       }
     ) (attrNames (removeAttrs network [ "network" "defaults" "resources" "require" "_file" ])));
--
2.36.0

'';
  in
  {
    legacyPackages."${system}" = pkgs;

    overlay = final: prev: {

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

      goimapnotify = prev.goimapnotify.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
            substituteInPlace client.go \
            --replace 'client.Dial(fmt.Sprintf("%s:%d", conf.Host, conf.Port))' \
              'client.Dial(fmt.Sprintf("%s:%d", conf.Host, conf.Port))
                      err = c.StartTLS(&tls.Config{
                              ServerName:         conf.Host,
                              InsecureSkipVerify: !conf.TLSOptions.RejectUnauthorized,
                      })'

            substituteInPlace client.go \
            --replace 'client.Dial(conf.Host + fmt.Sprintf(":%d", conf.Port))' \
              'client.Dial(conf.Host + fmt.Sprintf(":%d", conf.Port))
                      err = c.StartTLS(&tls.Config{
                              ServerName:         conf.Host,
                              InsecureSkipVerify: !conf.TLSOptions.RejectUnauthorized,
                      })'
        '';
      });

      fmt_8 = prev.fmt_8.overrideAttrs (old: rec {
        version = "8.1.1";
        src = prev.fetchFromGitHub {
          owner = "fmtlib";
          repo = "fmt";
          rev = version;
          sha256 = "sha256-leb2800CwdZMJRWF5b1Y9ocK0jXpOX/nwo95icDf308=";
        };
      });

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

      nixops = prev.nixops.overrideAttrs (oldAttrs: {
        patches = (oldAttrs.patches or []) ++ [ nixops-extraArgs-patch ];
      });

#      glslang = (prev.glslang.override {
#        inherit (final) spirv-headers spirv-tools;
#      }).overrideAttrs (old: rec {
#        version = "1.3.204.1";
#
#        src = pkgs.fetchFromGitHub {
#          owner = "KhronosGroup";
#          repo = "glslang";
#          rev = "sdk-${version}";
#          sha256 = "sha256-Q0sk4bPj/skPat1n4GJyuXAlZqpfEn4Td8Bm2IBNUqE=";
#        };
#      });
#
#      opencl-clang = (prev.opencl-clang.override {
#        inherit (final) spirv-llvm-translator;
#        buildWithPatches = false;
#      }).overrideAttrs (old: {
#        version = "ocl-open-110";
#
#        passthru = {};
#
#        #patches = [];
#
#        src = pkgs.fetchFromGitHub {
#          owner = "intel";
#          repo = "opencl-clang";
#          rev = "bbdd1587f577397a105c900be114b56755d1f7dc";
#          sha256 = "sha256-qEZoQ6h4XAvSnJ7/gLXBb1qrzeYa6Jp6nij9VFo8MwQ=";
#        };
#      });
#
#      spirv-headers = prev.spirv-headers.overrideAttrs (old: rec {
#        version = "1.3.204.1";
#
#        src = pkgs.fetchFromGitHub {
#          owner = "KhronosGroup";
#          repo = "SPIRV-Headers";
#          rev = "sdk-${version}";
#          sha256 = "sha256-ks9JCj5rj+Xu++7z5RiHDkU3/sFXhcScw8dATfB/ot0=";
#        };
#      });
#
#      spirv-tools = (prev.spirv-tools.override {
#        inherit (final) spirv-headers;
#      }).overrideAttrs (old: rec {
#        version = "1.3.204.1";
#
#        src = pkgs.fetchFromGitHub {
#          owner = "KhronosGroup";
#          repo = "SPIRV-Tools";
#          rev = "sdk-${version}";
#          sha256 = "sha256-DSqZlwfNTbN4fyIrVBKltm5U2U4GthW3L+Ksw4lSVG8=";
#        };
#
#        prePatch = ''
#          substituteInPlace ./cmake/SPIRV-Tools.pc.in \
#            --replace '/@CMAKE_INSTALL_INCLUDEDIR@' "/include" \
#            --replace '/@CMAKE_INSTALL_LIBDIR@' "/lib"
#
#          substituteInPlace ./cmake/SPIRV-Tools-shared.pc.in \
#            --replace '/@CMAKE_INSTALL_INCLUDEDIR@' "/include" \
#            --replace '/@CMAKE_INSTALL_LIBDIR@' "/lib"
#        '';
#      });
#
#      spirv-llvm-translator = prev.spirv-llvm-translator.overrideAttrs (old: {
#          version = "llvm_release_110";
#
#          src = pkgs.fetchFromGitHub {
#            owner = "KhronosGroup";
#            repo = "SPIRV-LLVM-Translator";
#            rev = "99420daab98998a7e36858befac9c5ed109d4920";
#            sha256 = "sha256-/vUyL6Wh8hykoGz1QmT1F7lfGDEmG4U3iqmqrJxizOg=";
#          };
#
#          buildInputs = [
#            final.spirv-headers
#            final.spirv-tools
#          ] ++ old.buildInputs;
#
#          cmakeFlags = [
#            "-DLLVM_DIR=${prev.llvm_11.dev}"
#            "-DBUILD_SHARED_LIBS=YES"
#            "-DLLVM_SPIRV_BUILD_EXTERNAL=YES"
#            "-DLLVM_EXTERNAL_LIT=${final.lit}/bin/lit"
#          ] ++ old.cmakeFlags;
#
#          prePatch = ''
#            substituteInPlace ./test/CMakeLists.txt \
#              --replace 'SPIRV-Tools' 'SPIRV-Tools-shared'
#          '';
#
#          makeFlags = [ "llvm-spirv" ];
#
#          # FIXME lit should find our newly build libLLVMSPIRVLib.so.11
#          doCheck = false;
#      });
#
#      intel-graphics-compiler = let
#          vc_intrinsics_src = pkgs.fetchFromGitHub {
#            owner = "intel";
#            repo = "vc-intrinsics";
#            rev = "v0.3.0";
#            sha256 = "sha256-1Rm4TCERTOcPGWJF+yNoKeB9x3jfqnh7Vlv+0Xpmjbk=";
#          };
#      in (prev.intel-graphics-compiler.override {
#        inherit (final) spirv-llvm-translator;
#        opencl-clang = final.opencl-clang.overrideAttrs (old: {
#          clang = prev.llvmPackages_11.clang;
#          libclang = prev.llvmPackages_11.libclang;
#          spirv-llvm-translator = final.spirv-llvm-translator;
#        });
#        buildWithPatches = true;
#      }).overrideAttrs (old: rec {
#        version = "1.0.11061";
#
#        src = pkgs.fetchFromGitHub {
#          owner = "intel";
#          repo = "intel-graphics-compiler";
#          rev = "igc-${version}";
#          sha256 = "sha256-qS/+GTqHtp3T6ggPKrCDsrTb7XvVOUaNbMzGU51jTu4=";
#        };
#
#        buildInputs = [
#
#          final.spirv-headers
#        ] ++ old.buildInputs;
#
#        prePatch = ''
#          substituteInPlace ./external/SPIRV-Tools/CMakeLists.txt \
#            --replace '$'''{SPIRV-Tools_DIR}../../..' \
#                      '${final.spirv-tools}' \
#            --replace 'SPIRV-Headers_INCLUDE_DIR "/usr/include"' \
#                      'SPIRV-Headers_INCLUDE_DIR "${final.spirv-headers}/include"' \
#            --replace 'set_target_properties(SPIRV-Tools' \
#                      'set_target_properties(SPIRV-Tools-shared' \
#            --replace 'IGC_BUILD__PROJ__SPIRV-Tools SPIRV-Tools' \
#                      'IGC_BUILD__PROJ__SPIRV-Tools SPIRV-Tools-shared'
#
#          substituteInPlace ./IGC/AdaptorOCL/igc-opencl.pc.in \
#            --replace '/@CMAKE_INSTALL_INCLUDEDIR@' "/include" \
#            --replace '/@CMAKE_INSTALL_LIBDIR@' "/lib"
#        '';
#
#        cmakeFlags = [
#          "-Wno-dev"
#          "-DVC_INTRINSICS_SRC=${vc_intrinsics_src}"
#          "-DIGC_OPTION__SPIRV_TOOLS_MODE=Prebuilds"
#          #"-DIGC_OPTION__USE_PREINSTALLED_SPRIV_HEADERS=ON"
#        ] ++ (pkgs.lib.filter (
#          flag: (
#            "-DVC_INTRINSICS_SRC" != builtins.substring 0 19 flag
#          )
#        ) old.cmakeFlags);
#      });
#
#      intel-compute-runtime = (prev.intel-compute-runtime.override {
#        inherit (final) intel-graphics-compiler;
#      }).overrideAttrs (old: rec {
#        version = "22.17.23034";
#
#        src = pkgs.fetchFromGitHub {
#          owner = "intel";
#          repo = "compute-runtime";
#          rev = version;
#          sha256 = "sha256-ae6kPiVQe3+hcqXVu2ncCaVQAoMKoDHifrkKpt6uWX8=";
#
#
#        buildInputs = [
#          #final.opencl-clang
#          #final.opencl-clang.clang
#          #final.opencl-clang.libclang
#          #final.llvmPackages_11.llvm
#          #final.lld_11
#        ] ++ old.buildInputs;
#
#        #NIX_LD_FLAGS = "-L${prev.gccForLibs.lib}/lib";
#
#        cmakeFlags = [
#          #"-DNEO_DISABLE_BUILTINS_COMPILATION=ON"
#          "-DIGC_DIR=${final.intel-graphics-compiler}"
#        ] ++ (pkgs.lib.filter (
#          flag: (
#            "-DIGC_DIR" != builtins.substring 0 9 flag
#          )
#        ) old.cmakeFlags);
#      });
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

          youtube-dl = python-super.youtube-dl.overridePythonAttrs (old: {
            pname = "youtube-dl";
            version = "2022.05.15";

            src = prev.fetchFromGitHub {
              owner = "ytdl-org";
              repo = "youtube-dl";
              rev = "c7965b9fc2cae54f244f31f5373cb81a40e822ab";
              sha256 = "sha256-PrXo8mNlNTD+Fjcb93LUsY5huAR9UCcvR/ujb3zT+1g=";
              #sha256 = pkgs.lib.fakeSha256;
            };

            patches = [];
            postInstall = "";
          });

        };
      in prev.python3.override {inherit packageOverrides;};
      python3Packages = final.python3.pkgs;

      pulseaudio-dlna = prev.pulseaudio-dlna.overridePythonAttrs (old: {
        src = prev.fetchFromGitHub {
          owner = "Cygn";
          repo = "pulseaudio-dlna";
          rev = "25e7c21b1bbe51fe4ef68ef5ded126c3424ccd30";
          #rev = "3cdcf84184548e91ea25fbe60f3850768e15c2a2";
          sha256 = "sha256-qeTeCISHMs4iDhkcn301Kx7n2Gl7fNABz4UPfpt3+6E=";
          #sha256 = "sha256-V+r5akxQ40ORvnYqR+q//0VV0vK54Oy1iz+iuQbPOtU=";
        };
        #propagatedBuildInputs = [
        #  prev.python3Packages.pychromecast-9
        #] ++ (nixpkgs.lib.filter (
        #  pkg: pkg != prev.python3Packages.PyChromecast
        #) old.propagatedBuildInputs);
      });

      f2fs-tools = prev.f2fs-tools.overrideAttrs (old: rec {
        version = "1.15.0";

        src = prev.fetchgit {
          url = "https://git.kernel.org/pub/scm/linux/kernel/git/jaegeuk/f2fs-tools.git";
          rev = "refs/tags/v${version}";
          sha256 = "sha256-RSWvdC6kV0KfyJefK9qyFCWjlezFc7DBOOn+uy7S3Lk=";
        };
      });

    };
  };
}
