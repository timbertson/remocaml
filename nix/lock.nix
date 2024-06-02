final:
let
  pkgs = final.pkgs;
in
{
  context = {
    type = "opam";
    version = "1";
    root = "remocaml";
    ocamlPackages = pkgs.ocaml-ng.ocamlPackages_latest;
    repositories = {
      opam = (pkgs.fetchFromGitHub {
        hash = "sha256-C7jrdrhArKeYp+AzA5oLMTAOmv5V7Vq6AsCo/JujV+c=";
        owner = "ocaml";
        repo = "opam-repository";
        rev = "6c0498c5709e1f827f474353f4f4f8f09ffbf074";
      });
    };
  };
  specs = {
    angstrom = {
      pname = "angstrom";
      version = "0.16.0";
      depKeys = [
        ("bigstringaf")
        ("dune")
        ("ocaml")
        ("ocaml-syntax-shims")
      ];
      src = (pkgs.fetchurl {
        hash = "sha256-R4EL0xMG1XwKyD6z+Vsctvi92plFeqbmvNAvbduEEPA=";
        url = "https://github.com/inhabitedtype/angstrom/archive/0.16.0.tar.gz";
      });
      build = {
        buildPhase = "dune build -p angstrom -j $NIX_BUILD_CORES";
        installPhase = "";
        mode = "opam";
      };
    };
    asn1-combinators = {
      pname = "asn1-combinators";
      version = "0.2.6";
      depKeys = [
        ("cstruct")
        ("dune")
        ("ocaml")
        ("ptime")
        ("zarith")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-TBso8dIwOV/xrTuOjQOYGxABUGLsJw8p4lIZFOtkwvpNXfaDY+M56aEVjDtYrvDiUVb37Grd2FpYD+ytwX7frA==";
        url = "https://github.com/mirleft/ocaml-asn1-combinators/releases/download/v0.2.6/asn1-combinators-v0.2.6.tbz";
      });
      build = {
        buildPhase = "dune build -p asn1-combinators -j $NIX_BUILD_CORES";
        installPhase = "";
        mode = "opam";
      };
    };
    astring = {
      pname = "astring";
      version = "0.8.5";
      depKeys = [
        ("ocaml")
        ("ocamlbuild")
        ("ocamlfind")
        ("topkg")
      ];
      src = (pkgs.fetchurl {
        hash = "sha256-hlaSYwwHw6uHxmzfwnNMD9/Jw0pX+Oif/sfH0V56cPo=";
        url = "https://erratique.ch/software/astring/releases/astring-0.8.5.tbz";
      });
      build = {
        buildPhase = "ocaml pkg/pkg.ml build --pinned false";
        installPhase = "";
        mode = "opam";
      };
    };
    base = {
      pname = "base";
      version = "v0.15.1";
      depKeys = [
        ("dune")
        ("dune-configurator")
        ("ocaml")
        ("sexplib0")
      ];
      src = (pkgs.fetchurl {
        hash = "sha256-dV4wMXHqJn47pa96qOonU38zlNl8d9NAsQ+AbW72GhQ=";
        url = "https://github.com/janestreet/base/archive/refs/tags/v0.15.1.tar.gz";
      });
      build = {
        buildPhase = "dune build -p base -j $NIX_BUILD_CORES";
        installPhase = "";
        mode = "opam";
      };
    };
    base-bigarray = {
      pname = "base-bigarray";
      version = "base";
      depKeys = [
      ];
      build = {
        buildPhase = "";
        installPhase = "";
        mode = "opam";
      };
    };
    base-bytes = {
      pname = "base-bytes";
      version = "base";
      depKeys = [
        ("ocaml")
        ("ocamlfind")
      ];
      build = {
        buildPhase = "";
        installPhase = "";
        mode = "opam";
      };
    };
    base-threads = {
      pname = "base-threads";
      version = "base";
      depKeys = [
      ];
      build = {
        buildPhase = "";
        installPhase = "";
        mode = "opam";
      };
    };
    base-unix = {
      pname = "base-unix";
      version = "base";
      depKeys = [
      ];
      build = {
        buildPhase = "";
        installPhase = "";
        mode = "opam";
      };
    };
    base64 = {
      pname = "base64";
      version = "3.5.1";
      depKeys = [
        ("dune")
        ("ocaml")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-J4vSApgA2Q7Yj/WbnecjAT5kVSNVahZntkF41rUFin1tqR7//vNYnDVWm1+hDd7nTJP1o9FWuRRsivW3/kSurw==";
        url = "https://github.com/mirage/ocaml-base64/releases/download/v3.5.1/base64-3.5.1.tbz";
      });
      build = {
        buildPhase = "dune build -p base64 -j $NIX_BUILD_CORES";
        installPhase = "";
        mode = "opam";
      };
    };
    bigstringaf = {
      pname = "bigstringaf";
      version = "0.9.1";
      depKeys = [
        ("dune")
        ("dune-configurator")
        ("ocaml")
      ];
      src = (pkgs.fetchurl {
        hash = "sha256-h/mSd9YUmYtlUJQcUhjf4br+rBrSghJUyYfsKBpqVQs=";
        url = "https://github.com/inhabitedtype/bigstringaf/archive/0.9.1.tar.gz";
      });
      build = {
        buildPhase = "dune build -p bigstringaf -j $NIX_BUILD_CORES @install";
        installPhase = "";
        mode = "opam";
      };
    };
    bos = {
      pname = "bos";
      version = "0.2.1";
      depKeys = [
        ("astring")
        ("base-unix")
        ("fmt")
        ("fpath")
        ("logs")
        ("ocaml")
        ("ocamlbuild")
        ("ocamlfind")
        ("rresult")
        ("topkg")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-ja64pMLdHyRg9idK2hn08bbr6HX/g6k4yTQYzg5r23S4r8XJp9QQwcnfLa0DDk+idrbtLaWAY5SE6LW8kmELHQ==";
        url = "https://erratique.ch/software/bos/releases/bos-0.2.1.tbz";
      });
      build = {
        buildPhase = "ocaml pkg/pkg.ml build --dev-pkg false";
        installPhase = "";
        mode = "opam";
      };
    };
    ca-certs = {
      pname = "ca-certs";
      version = "0.2.3";
      depKeys = [
        ("astring")
        ("bos")
        ("dune")
        ("fpath")
        ("logs")
        ("mirage-crypto")
        ("ocaml")
        ("ptime")
        ("x509")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-6UURK+Oy8fvK65Wuu2AM1RGfHwVYPrzApKIN0VnYz+xa3DRDquZ47hWcDgwysdfAujukQF40g+P1ZeTSnT2g9w==";
        url = "https://github.com/mirage/ca-certs/releases/download/v0.2.3/ca-certs-0.2.3.tbz";
      });
      build = {
        buildPhase = "dune build -p ca-certs -j $NIX_BUILD_CORES @install";
        depexts = [
          (pkgs.ca_root_nss or null)
        ];
        installPhase = "";
        mode = "opam";
      };
    };
    camlp-streams = {
      pname = "camlp-streams";
      version = "5.0.1";
      depKeys = [
        ("dune")
        ("ocaml")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-LvqN1KY2IXyNSbrB5OflVY/C9Fz+pmUUFApZ/ZndCNYfufHheASZf/ZItxsTggpdSh63D+2dhIqiq9bkH4U8hg==";
        url = "https://github.com/ocaml/camlp-streams/archive/v5.0.1.tar.gz";
      });
      build = {
        buildPhase = "dune build -p camlp-streams -j $NIX_BUILD_CORES @install";
        installPhase = "";
        mode = "opam";
      };
    };
    cmdliner = {
      pname = "cmdliner";
      version = "1.3.0";
      depKeys = [
        ("ocaml")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-TEa8M0RE/3cmN96uL1ugNkXXobfbUjRwoSRqz855uXHHZNlky7AjiGObMWGyeXANmt6V2lUERvsyqkhJyKjygw==";
        url = "https://erratique.ch/software/cmdliner/releases/cmdliner-1.3.0.tbz";
      });
      build = {
        buildPhase = "make all PREFIX=$out";
        installPhase = ''
          make install "LIBDIR=${(final.siteLib "$out")}/cmdliner" DOCDIR=false
          make install-doc "LIBDIR=${(final.siteLib "$out")}/cmdliner" DOCDIR=false
        '';
        mode = "opam";
      };
    };
    cohttp = {
      pname = "cohttp";
      version = "6.0.0-beta2";
      depKeys = [
        ("base64")
        ("dune")
        ("http")
        ("logs")
        ("ocaml")
        ("ppx_sexp_conv")
        ("re")
        ("sexplib0")
        ("stringext")
        ("uri")
        ("uri-sexp")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-g+9TlGnZgoYhdKkp6brrWyo06TI+5XfYvnFI6+2eeF2DXVnMIpgrwIO7hy5FRGFuK/Ux7X7flrw5cVHCi/YY1g==";
        url = "https://github.com/mirage/ocaml-cohttp/releases/download/v6.0.0_beta2/cohttp-v6.0.0_beta2.tbz";
      });
      build = {
        buildPhase = "dune build -p cohttp -j $NIX_BUILD_CORES @install";
        installPhase = "";
        mode = "opam";
      };
    };
    cohttp-lwt = {
      pname = "cohttp-lwt";
      version = "6.0.0-beta2";
      depKeys = [
        ("cohttp")
        ("dune")
        ("http")
        ("logs")
        ("lwt")
        ("ocaml")
        ("ppx_sexp_conv")
        ("sexplib0")
        ("uri")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-g+9TlGnZgoYhdKkp6brrWyo06TI+5XfYvnFI6+2eeF2DXVnMIpgrwIO7hy5FRGFuK/Ux7X7flrw5cVHCi/YY1g==";
        url = "https://github.com/mirage/ocaml-cohttp/releases/download/v6.0.0_beta2/cohttp-v6.0.0_beta2.tbz";
      });
      build = {
        buildPhase = "dune build -p cohttp-lwt -j $NIX_BUILD_CORES @install";
        installPhase = "";
        mode = "opam";
      };
    };
    cohttp-lwt-unix = {
      pname = "cohttp-lwt-unix";
      version = "6.0.0-beta2";
      depKeys = [
        ("base-unix")
        ("cmdliner")
        ("cohttp")
        ("cohttp-lwt")
        ("conduit-lwt")
        ("conduit-lwt-unix")
        ("dune")
        ("fmt")
        ("http")
        ("logs")
        ("lwt")
        ("magic-mime")
        ("ocaml")
        ("ppx_sexp_conv")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-g+9TlGnZgoYhdKkp6brrWyo06TI+5XfYvnFI6+2eeF2DXVnMIpgrwIO7hy5FRGFuK/Ux7X7flrw5cVHCi/YY1g==";
        url = "https://github.com/mirage/ocaml-cohttp/releases/download/v6.0.0_beta2/cohttp-v6.0.0_beta2.tbz";
      });
      build = {
        buildPhase = "dune build -p cohttp-lwt-unix -j $NIX_BUILD_CORES @install";
        installPhase = "";
        mode = "opam";
      };
    };
    conduit = {
      pname = "conduit";
      version = "6.2.2";
      depKeys = [
        ("astring")
        ("dune")
        ("ipaddr")
        ("ipaddr-sexp")
        ("logs")
        ("ocaml")
        ("ppx_sexp_conv")
        ("sexplib")
        ("uri")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-q47lwrnYeYaRgdXf4RGu/u+qEAY9ifIdX8YCPop7g3OLJG3K3OfVg/W46RgCbNtzzGazKo1cL4dJZvo31eZ3GQ==";
        url = "https://github.com/mirage/ocaml-conduit/releases/download/v6.2.2/conduit-6.2.2.tbz";
      });
      build = {
        buildPhase = "dune build -p conduit -j $NIX_BUILD_CORES";
        installPhase = "";
        mode = "opam";
      };
    };
    conduit-lwt = {
      pname = "conduit-lwt";
      version = "6.2.2";
      depKeys = [
        ("base-unix")
        ("conduit")
        ("dune")
        ("lwt")
        ("ocaml")
        ("ppx_sexp_conv")
        ("sexplib")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-q47lwrnYeYaRgdXf4RGu/u+qEAY9ifIdX8YCPop7g3OLJG3K3OfVg/W46RgCbNtzzGazKo1cL4dJZvo31eZ3GQ==";
        url = "https://github.com/mirage/ocaml-conduit/releases/download/v6.2.2/conduit-6.2.2.tbz";
      });
      build = {
        buildPhase = "dune build -p conduit-lwt -j $NIX_BUILD_CORES";
        installPhase = "";
        mode = "opam";
      };
    };
    conduit-lwt-unix = {
      pname = "conduit-lwt-unix";
      version = "6.2.2";
      depKeys = [
        ("base-unix")
        ("ca-certs")
        ("conduit-lwt")
        ("dune")
        ("ipaddr")
        ("ipaddr-sexp")
        ("logs")
        ("lwt")
        ("ocaml")
        ("ppx_sexp_conv")
        ("uri")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-q47lwrnYeYaRgdXf4RGu/u+qEAY9ifIdX8YCPop7g3OLJG3K3OfVg/W46RgCbNtzzGazKo1cL4dJZvo31eZ3GQ==";
        url = "https://github.com/mirage/ocaml-conduit/releases/download/v6.2.2/conduit-6.2.2.tbz";
      });
      build = {
        buildPhase = "dune build -p conduit-lwt-unix -j $NIX_BUILD_CORES";
        installPhase = "";
        mode = "opam";
      };
    };
    conf-gmp = {
      pname = "conf-gmp";
      version = "4";
      depKeys = [
      ];
      build = {
        buildPhase = "sh -exc \"cc -c $CFLAGS -I/opt/homebrew/include -I/opt/local/include -I/usr/local/include test.c\"";
        depexts = [
          (pkgs.gmp)
        ];
        installPhase = "";
        mode = "opam";
      };
      extraSources = {
        "test.c" = (pkgs.fetchurl {
          hash = "sha256-VKMHNfHycaJTFSZ0fnVxb0SQ3XvBVG79ZJjM/jzE1vs=";
          url = "https://raw.githubusercontent.com/ocaml/opam-source-archives/main/patches/conf-gmp/test.c.4";
        });
      };
    };
    conf-gmp-powm-sec = {
      pname = "conf-gmp-powm-sec";
      version = "3";
      depKeys = [
        ("conf-gmp")
      ];
      build = {
        buildPhase = "sh -exc \"cc -c $CFLAGS -I/opt/homebrew/include -I/opt/local/include -I/usr/local/include test.c\"";
        installPhase = "";
        mode = "opam";
      };
      extraSources = {
        "test.c" = (pkgs.fetchurl {
          hash = "sha256-OIs4eVMCV6fm5ZtoII7ipS3nvjDkDrTTpUQZcI/a1JA=";
          url = "https://raw.githubusercontent.com/ocaml/opam-source-archives/main/patches/conf-gmp-powm-sec/test.c.3";
        });
      };
    };
    conf-python-3 = {
      pname = "conf-python-3";
      version = "9.0.0";
      depKeys = [
      ];
      build = {
        buildPhase = "python3 test.py";
        depexts = [
          (pkgs.python3)
        ];
        installPhase = "";
        mode = "opam";
      };
      extraSources = {
        "test.py" = (pkgs.fetchurl {
          hash = "sha256-UHOLWfdHv2Rk7Gmgg8fyHnaPCnffZSCgkWNsdLsbe3c=";
          url = "https://raw.githubusercontent.com/ocaml/opam-source-archives/main/patches/conf-python-3/test.py";
        });
      };
    };
    cppo = {
      pname = "cppo";
      version = "1.6.9";
      depKeys = [
        ("base-unix")
        ("dune")
        ("ocaml")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-Jv9ae384xGBmGXSyPKGQ8P6uOpnxl04P0SzPCHRb19kbe8FoxwpThbg3v/+VMODk5BzyafI92M8WymWACCRLRA==";
        url = "https://github.com/ocaml-community/cppo/archive/v1.6.9.tar.gz";
      });
      build = {
        buildPhase = "dune build -p cppo -j $NIX_BUILD_CORES";
        installPhase = "";
        mode = "opam";
      };
    };
    crunch = {
      pname = "crunch";
      version = "3.3.1";
      depKeys = [
        ("cmdliner")
        ("dune")
        ("ocaml")
        ("ptime")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-WqobZ0Vt0vXjq0UOpUfmL7orA0GknzskZpFi3OkbbqEVjBWU1gxt8+QW5xlIRBHFCuYQF8QLL3XukEAapUO9CA==";
        url = "https://github.com/mirage/ocaml-crunch/releases/download/v3.3.1/crunch-3.3.1.tbz";
      });
      build = {
        buildPhase = "dune build -p crunch -j $NIX_BUILD_CORES @install";
        installPhase = "";
        mode = "opam";
      };
    };
    csexp = {
      pname = "csexp";
      version = "1.5.2";
      depKeys = [
        ("dune")
        ("ocaml")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-vigQGLz8INTbFIlO9RxLg21jONL9/iLmPUb0BfjepzSeFvHA7NZfc9TIWiqA5hjNu4ydr8u58inwTxrcpbGXPA==";
        url = "https://github.com/ocaml-dune/csexp/releases/download/1.5.2/csexp-1.5.2.tbz";
      });
      build = {
        buildPhase = "dune build -p csexp -j $NIX_BUILD_CORES @install";
        installPhase = "";
        mode = "opam";
      };
    };
    cstruct = {
      pname = "cstruct";
      version = "6.2.0";
      depKeys = [
        ("dune")
        ("fmt")
        ("ocaml")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-jTP+azcHo5lNAiXNM8rd4LssqDTvAQluPfM6COSoxtAuvM3fVYpzmIuKVZW2X9wQ3mHvv4csbJ5VxxnH4ZxGPQ==";
        url = "https://github.com/mirage/ocaml-cstruct/releases/download/v6.2.0/cstruct-6.2.0.tbz";
      });
      build = {
        buildPhase = "dune build -p cstruct -j $NIX_BUILD_CORES";
        installPhase = "";
        mode = "opam";
      };
    };
    dkml-base-compiler = {
      pname = "dkml-base-compiler";
      version = "4.12.1-v1.0.2-prerel7";
      depKeys = [
        ("dkml-runtime-common")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-QPr1EKETQ5Z46iQkkFsa1secIjFcI/aI9rTmhdkLyDFhttDXTWW251AGWm3yNOxIRbBLU1Lcn7n7lEKhDvO7ow==";
        url = "https://github.com/diskuv/dkml-compiler/releases/download/1.0.2-prerel7-r2/src.tar.gz";
      });
      build = {
        buildPhase = ''
          sh scripts/macos-bundle-dump.sh
          install -d dl/ocaml/flexdll
          tar xCfz dl/ocaml dl/ocaml.tar.gz --strip-components=1
          tar xCfz dl/ocaml/flexdll dl/flexdll.tar.gz --strip-components=1
          install -d dkmldir
          sh -eufc "printf 'dkml_root_version=%s
          ' '4.12.1~v1.0.2~prerel7' | sed 's/[0-9.]*~v//; s/~/-/' > dkmldir/.dkmlroot"
          install -d dkmldir/vendor/drc
          sh -eufc "tar cCf '${(final.siteLib (final.getDrv "dkml-runtime-common"))}/dkml-runtime-common/' - . | tar xCf dkmldir/vendor/drc/ -"
          install -d dkmldir/vendor/dkml-compiler/src dkmldir/vendor/dkml-compiler/env
          install env/standard-compiler-env-to-ocaml-configure-env.sh dkmldir/vendor/dkml-compiler/env/
          sh -eufc "tar cCf src/ - . | tar xCf dkmldir/vendor/dkml-compiler/src/ -"
        '';
        installPhase = ''
          env TOPDIR=dkmldir/vendor/drc/all/emptytop DKML_REPRODUCIBLE_SYSTEM_BREWFILE=true/Brewfile dkmldir/vendor/dkml-compiler/src/r-c-ocaml-1-setup.sh -d dkmldir -t $out -f src-ocaml -g $out/share/mlcross -v dl/ocaml -z -edarwin_arm64 -adarwin_x86_64=vendor/dkml-compiler/env/standard-compiler-env-to-ocaml-configure-env.sh -k vendor/dkml-compiler/env/standard-compiler-env-to-ocaml-configure-env.sh
          sh -eufc "
              cd '$out'
    share/dkml/repro/100co/vendor/dkml-compiler/src/r-c-ocaml-2-build_host-noargs.sh
              "
          sh -eufc "
              cd '$out'
    share/dkml/repro/100co/vendor/dkml-compiler/src/r-c-ocaml-3-build_cross-noargs.sh
              "
        '';
        mode = "opam";
      };
      extraSources = {
        "dl/flexdll.tar.gz" = (pkgs.fetchurl {
          hash = "sha256-UabvLmf/R1wzp2s9yGQBoPKGyaMznugUUFPqAtL7WXQ=";
          url = "https://github.com/alainfrisch/flexdll/archive/0.39.tar.gz";
        });
        "dl/homebrew-bundle.tar.gz" = (pkgs.fetchurl {
          hash = "sha256-EMAkynhxzqNrTCeyYBlx0/psum83hVYTuvACbQ9VXnY=";
          url = "https://github.com/Homebrew/homebrew-bundle/archive/4756e4c4cf95485c5ea4da27375946c1dac2c71d.tar.gz";
        });
        "dl/ocaml.tar.gz" = (pkgs.fetchurl {
          hash = "sha256-9aSKkFV8tHrOexWQ/KsTYqGvOGKaIYNQ9pwiXFfpakE=";
          url = "https://github.com/ocaml/ocaml/archive/4.12.1.tar.gz";
        });
      };
    };
    dkml-runtime-common = {
      pname = "dkml-runtime-common";
      version = "1.0.2-prerel7";
      depKeys = [
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-FOBigDtOtfWKdOwuillzZWgwTpVUwy5n3vfWIo/PrvjWDToWw9cZcf5XiH13PjO7kfVf6rwbFH/Mb5qgd4RrHA==";
        url = "https://github.com/diskuv/dkml-runtime-common/releases/download/1.0.2-prerel7/src.tar.gz";
      });
      build = {
        buildPhase = "";
        installPhase = "./install.sh \"${(final.siteLib "$out")}/dkml-runtime-common\"";
        mode = "opam";
      };
    };
    domain-name = {
      pname = "domain-name";
      version = "0.4.0";
      depKeys = [
        ("dune")
        ("ocaml")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-8lrtsd32q4xJsVRc+I9JkBFKnnlU2Ryr8mDmzkcKvULdE16KVQhCYqd9TJ7kv/bcAMcTB7I6SNgtUFk7kQ7hcw==";
        url = "https://github.com/hannesm/domain-name/releases/download/v0.4.0/domain-name-0.4.0.tbz";
      });
      build = {
        buildPhase = "dune build -p domain-name -j $NIX_BUILD_CORES";
        installPhase = "";
        mode = "opam";
      };
    };
    dune = {
      pname = "dune";
      version = "3.15.3";
      depKeys = [
        ("base-threads")
        ("base-unix")
        ("ocaml")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-yIrHpu2TNKS8YjHs+w76qWHdqZvDhv1bklBRUf+DPfrwWNdTBfu2TEluVwBY7JAArGrdBt2no5XnV+kkrx0afw==";
        url = "https://github.com/ocaml/dune/releases/download/3.15.3/dune-3.15.3.tbz";
      });
      build = {
        buildPhase = ''
          ocaml boot/bootstrap.ml -j $NIX_BUILD_CORES
          ./_boot/dune.exe build dune.install --release --profile dune-bootstrap -j $NIX_BUILD_CORES
        '';
        installPhase = "";
        mode = "opam";
      };
    };
    dune-configurator = {
      pname = "dune-configurator";
      version = "3.15.3";
      depKeys = [
        ("base-unix")
        ("csexp")
        ("dune")
        ("ocaml")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-yIrHpu2TNKS8YjHs+w76qWHdqZvDhv1bklBRUf+DPfrwWNdTBfu2TEluVwBY7JAArGrdBt2no5XnV+kkrx0afw==";
        url = "https://github.com/ocaml/dune/releases/download/3.15.3/dune-3.15.3.tbz";
      });
      build = {
        buildPhase = ''
          rm -rf vendor/csexp
          rm -rf vendor/pp
          dune build -p dune-configurator -j $NIX_BUILD_CORES @install
        '';
        installPhase = "";
        mode = "opam";
      };
    };
    duration = {
      pname = "duration";
      version = "0.2.1";
      depKeys = [
        ("dune")
        ("ocaml")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-DenhXH1hiIct3ZmU8IYWxKGCLkrJJyTvosMS+7L8RM18vks2vPZqhFHVEMH8ld5IF2CvvKy4+D4YMmJZXc9fDA==";
        url = "https://github.com/hannesm/duration/releases/download/v0.2.1/duration-0.2.1.tbz";
      });
      build = {
        buildPhase = "dune build -p duration -j $NIX_BUILD_CORES";
        installPhase = "";
        mode = "opam";
      };
    };
    eqaf = {
      pname = "eqaf";
      version = "0.9";
      depKeys = [
        ("cstruct")
        ("dune")
        ("ocaml")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-Tff9PqNRVpU6FywaAhqrBbixIu6NPP2zT5btsbUTPR/ichuQy2QoeEHXcLFsL/5wVZxm6Q+NYakrc4V9oiVIxA==";
        url = "https://github.com/mirage/eqaf/releases/download/v0.9/eqaf-0.9.tbz";
      });
      build = {
        buildPhase = "dune build -p eqaf -j $NIX_BUILD_CORES";
        installPhase = "";
        mode = "opam";
      };
    };
    fmt = {
      pname = "fmt";
      version = "0.9.0";
      depKeys = [
        ("base-unix")
        ("cmdliner")
        ("ocaml")
        ("ocamlbuild")
        ("ocamlfind")
        ("topkg")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-Zs9Li7kiMqCR39pelNHBeEhqNYzcNLHuxRbUjqWstiCcDfy0FvDFFsUN292zyUVJpF5KbVxf0cgdM3TeyCOoOw==";
        url = "https://erratique.ch/software/fmt/releases/fmt-0.9.0.tbz";
      });
      build = {
        buildPhase = "ocaml pkg/pkg.ml build --dev-pkg false --with-base-unix true --with-cmdliner true";
        installPhase = "";
        mode = "opam";
      };
    };
    fpath = {
      pname = "fpath";
      version = "0.7.3";
      depKeys = [
        ("astring")
        ("ocaml")
        ("ocamlbuild")
        ("ocamlfind")
        ("topkg")
      ];
      src = (pkgs.fetchurl {
        hash = "sha256-ErCP8ZLQN9m21p6coZ0dOFGE8gsyN8JyMeQ3rIGs5w8=";
        url = "https://erratique.ch/software/fpath/releases/fpath-0.7.3.tbz";
      });
      build = {
        buildPhase = "ocaml pkg/pkg.ml build";
        installPhase = "";
        mode = "opam";
      };
    };
    gmap = {
      pname = "gmap";
      version = "0.3.0";
      depKeys = [
        ("dune")
        ("ocaml")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-cWFpgfWhXWsqR+GHAgg+UugfZUcHYIWxSJ9nb1CwzEfHwsT6GctYHih43D1PcTPQxQ2LUag5C+Dm4wMYkH2B0w==";
        url = "https://github.com/hannesm/gmap/releases/download/0.3.0/gmap-0.3.0.tbz";
      });
      build = {
        buildPhase = "dune build -p gmap -j $NIX_BUILD_CORES";
        installPhase = "";
        mode = "opam";
      };
    };
    http = {
      pname = "http";
      version = "6.0.0-beta2";
      depKeys = [
        ("dune")
        ("ocaml")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-g+9TlGnZgoYhdKkp6brrWyo06TI+5XfYvnFI6+2eeF2DXVnMIpgrwIO7hy5FRGFuK/Ux7X7flrw5cVHCi/YY1g==";
        url = "https://github.com/mirage/ocaml-cohttp/releases/download/v6.0.0_beta2/cohttp-v6.0.0_beta2.tbz";
      });
      build = {
        buildPhase = "dune build -p http -j $NIX_BUILD_CORES @install";
        installPhase = "";
        mode = "opam";
      };
    };
    ipaddr = {
      pname = "ipaddr";
      version = "5.6.0";
      depKeys = [
        ("domain-name")
        ("dune")
        ("macaddr")
        ("ocaml")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-ZqO+39kdrNbB3pujWrrD7yrTwshUP3tOKgzGKDqNQhOLSNAukE3wIy7p8yCSDoib3bvamlFIxca3L9AWTgxqNA==";
        url = "https://github.com/mirage/ocaml-ipaddr/releases/download/v5.6.0/ipaddr-5.6.0.tbz";
      });
      build = {
        buildPhase = "dune build -p ipaddr -j $NIX_BUILD_CORES";
        installPhase = "";
        mode = "opam";
      };
    };
    ipaddr-sexp = {
      pname = "ipaddr-sexp";
      version = "5.6.0";
      depKeys = [
        ("dune")
        ("ipaddr")
        ("ocaml")
        ("ppx_sexp_conv")
        ("sexplib0")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-ZqO+39kdrNbB3pujWrrD7yrTwshUP3tOKgzGKDqNQhOLSNAukE3wIy7p8yCSDoib3bvamlFIxca3L9AWTgxqNA==";
        url = "https://github.com/mirage/ocaml-ipaddr/releases/download/v5.6.0/ipaddr-5.6.0.tbz";
      });
      build = {
        buildPhase = "dune build -p ipaddr-sexp -j $NIX_BUILD_CORES";
        installPhase = "";
        mode = "opam";
      };
    };
    js_of_ocaml = {
      pname = "js_of_ocaml";
      version = "5.8.2";
      depKeys = [
        ("dune")
        ("js_of_ocaml-compiler")
        ("ocaml")
        ("ppxlib")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-Gigr+I66hIl0f1HiKDhb6Nkm5cV+/jOtbzJMMPvkEA6ZlwGSKEFytc3vkpIsphOWi/EW63BhlKh5iZut3QpH9A==";
        url = "https://github.com/ocsigen/js_of_ocaml/releases/download/5.8.2/js_of_ocaml-5.8.2.tbz";
      });
      build = {
        buildPhase = "dune build -p js_of_ocaml -j $NIX_BUILD_CORES @install";
        installPhase = "";
        mode = "opam";
      };
    };
    js_of_ocaml-compiler = {
      pname = "js_of_ocaml-compiler";
      version = "3.9.1";
      depKeys = [
        ("cmdliner")
        ("dune")
        ("menhir")
        ("ocaml")
        ("ocamlfind")
        ("ppxlib")
        ("yojson")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-+LiAvT/5/B2YxfZaHT2ekZ0Wog3Rwcl54VRkLR33w6/J1ojiT7vNWRl04d67NS2PP7Lg/7tt+UwtCMzY0/QnJw==";
        url = "https://github.com/ocsigen/js_of_ocaml/releases/download/3.9.1/js_of_ocaml-3.9.1.tbz";
      });
      build = {
        buildPhase = "dune build -p js_of_ocaml-compiler -j $NIX_BUILD_CORES";
        installPhase = "";
        mode = "opam";
      };
    };
    js_of_ocaml-lwt = {
      pname = "js_of_ocaml-lwt";
      version = "5.8.2";
      depKeys = [
        ("dune")
        ("js_of_ocaml")
        ("js_of_ocaml-ppx")
        ("lwt")
        ("lwt_log")
        ("ocaml")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-Gigr+I66hIl0f1HiKDhb6Nkm5cV+/jOtbzJMMPvkEA6ZlwGSKEFytc3vkpIsphOWi/EW63BhlKh5iZut3QpH9A==";
        url = "https://github.com/ocsigen/js_of_ocaml/releases/download/5.8.2/js_of_ocaml-5.8.2.tbz";
      });
      build = {
        buildPhase = "dune build -p js_of_ocaml-lwt -j $NIX_BUILD_CORES @install";
        installPhase = "";
        mode = "opam";
      };
    };
    js_of_ocaml-ppx = {
      pname = "js_of_ocaml-ppx";
      version = "5.8.2";
      depKeys = [
        ("dune")
        ("js_of_ocaml")
        ("ocaml")
        ("ppxlib")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-Gigr+I66hIl0f1HiKDhb6Nkm5cV+/jOtbzJMMPvkEA6ZlwGSKEFytc3vkpIsphOWi/EW63BhlKh5iZut3QpH9A==";
        url = "https://github.com/ocsigen/js_of_ocaml/releases/download/5.8.2/js_of_ocaml-5.8.2.tbz";
      });
      build = {
        buildPhase = "dune build -p js_of_ocaml-ppx -j $NIX_BUILD_CORES @install";
        installPhase = "";
        mode = "opam";
      };
    };
    lambda-term = {
      pname = "lambda-term";
      version = "3.3.2";
      depKeys = [
        ("dune")
        ("logs")
        ("lwt")
        ("lwt_react")
        ("mew_vi")
        ("ocaml")
        ("react")
        ("zed")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-eGSHaGRAWDN+Isec8fuxo2Rysk8RsdwEYfw4QZvm7AGwLY0KxF/tC8mfkbpMDxnTvaET6DTgZL7pc7c0UnuXZg==";
        url = "https://github.com/ocaml-community/lambda-term/archive/refs/tags/3.3.2.tar.gz";
      });
      build = {
        buildPhase = "dune build -p lambda-term -j $NIX_BUILD_CORES @install";
        installPhase = "";
        mode = "opam";
      };
    };
    logs = {
      pname = "logs";
      version = "0.7.0";
      depKeys = [
        ("base-threads")
        ("cmdliner")
        ("fmt")
        ("js_of_ocaml")
        ("lwt")
        ("ocaml")
        ("ocamlbuild")
        ("ocamlfind")
        ("topkg")
      ];
      src = (pkgs.fetchurl {
        hash = "sha256-hvSgKAfrGil6rkSXfZ9h5BnDFFil17I8b1VXXo5p1co=";
        url = "https://erratique.ch/software/logs/releases/logs-0.7.0.tbz";
      });
      build = {
        buildPhase = "ocaml pkg/pkg.ml build --pinned false --with-js_of_ocaml true --with-fmt true --with-cmdliner true --with-lwt true --with-base-threads true";
        installPhase = "";
        mode = "opam";
      };
    };
    lwt = {
      pname = "lwt";
      version = "5.7.0";
      depKeys = [
        ("base-threads")
        ("base-unix")
        ("cppo")
        ("dune")
        ("dune-configurator")
        ("ocaml")
        ("ocplib-endian")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-QuYpkgeDQoZzuZydemOSN8nms1B5tdkHvGfn6lBqz57a3EjOxYC9z9JBDtlBK/XmvMiwneL6fTXOFJCXPQXd0Q==";
        url = "https://github.com/ocsigen/lwt/archive/refs/tags/5.7.0.tar.gz";
      });
      build = {
        buildPhase = ''
          dune exec -p lwt src/unix/config/discover.exe -- --save --use-libev false
          dune build -p lwt -j $NIX_BUILD_CORES
        '';
        installPhase = "";
        mode = "opam";
      };
    };
    lwt_log = {
      pname = "lwt_log";
      version = "1.1.2";
      depKeys = [
        ("dune")
        ("lwt")
        ("ocaml")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-+5dticD4aLV0NKngkH/64IQv5I/HR924YJVNIPNnIvrqMV67C02sIC+b9yA7CgloFhTpYZ87vQ3Vn43Xu9UFdQ==";
        url = "https://github.com/ocsigen/lwt_log/archive/1.1.2.tar.gz";
      });
      build = {
        buildPhase = "dune build -p lwt_log -j $NIX_BUILD_CORES";
        installPhase = "";
        mode = "opam";
      };
    };
    lwt_ppx = {
      pname = "lwt_ppx";
      version = "2.1.0";
      depKeys = [
        ("dune")
        ("lwt")
        ("ocaml")
        ("ppxlib")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-1hY4m8ng2hHyWEOrdUGsLUDJVDcAqJRV8UEVszm75YzvK4rPCul/1U4VpMuTFJz+Hr/aMBqpOTMEX3a32TRBYA==";
        url = "https://github.com/ocsigen/lwt/archive/5.6.0.tar.gz";
      });
      build = {
        buildPhase = "dune build -p lwt_ppx -j $NIX_BUILD_CORES";
        installPhase = "";
        mode = "opam";
      };
    };
    lwt_react = {
      pname = "lwt_react";
      version = "1.2.0";
      depKeys = [
        ("cppo")
        ("dune")
        ("lwt")
        ("ocaml")
        ("react")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-1hY4m8ng2hHyWEOrdUGsLUDJVDcAqJRV8UEVszm75YzvK4rPCul/1U4VpMuTFJz+Hr/aMBqpOTMEX3a32TRBYA==";
        url = "https://github.com/ocsigen/lwt/archive/5.6.0.tar.gz";
      });
      build = {
        buildPhase = "dune build -p lwt_react -j $NIX_BUILD_CORES";
        installPhase = "";
        mode = "opam";
      };
    };
    macaddr = {
      pname = "macaddr";
      version = "5.6.0";
      depKeys = [
        ("dune")
        ("ocaml")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-ZqO+39kdrNbB3pujWrrD7yrTwshUP3tOKgzGKDqNQhOLSNAukE3wIy7p8yCSDoib3bvamlFIxca3L9AWTgxqNA==";
        url = "https://github.com/mirage/ocaml-ipaddr/releases/download/v5.6.0/ipaddr-5.6.0.tbz";
      });
      build = {
        buildPhase = "dune build -p macaddr -j $NIX_BUILD_CORES";
        installPhase = "";
        mode = "opam";
      };
    };
    magic-mime = {
      pname = "magic-mime";
      version = "1.3.1";
      depKeys = [
        ("dune")
        ("ocaml")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-YH90acqi6ACpLjxSSBJRCPrV4FE/QjCjftd0yGES6s2uDuUzxceOwnUuk56D4iAd1O4Cy7/5KuMuJWg3ENezZQ==";
        url = "https://github.com/mirage/ocaml-magic-mime/releases/download/v1.3.1/magic-mime-1.3.1.tbz";
      });
      build = {
        buildPhase = "dune build -p magic-mime -j $NIX_BUILD_CORES";
        installPhase = "";
        mode = "opam";
      };
    };
    menhir = {
      pname = "menhir";
      version = "20190924";
      depKeys = [
        ("ocaml")
        ("ocamlbuild")
        ("ocamlfind")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-6oqabXc1Kc9qwF5MbEUydw+7jldMm2Ru/O/pDZ8kVEdB4+jP2UyK/qBEfjQFmox5woKbRnZM46PW3LPn91mA/A==";
        url = "https://gitlab.inria.fr/fpottier/menhir/-/archive/20190924/archive.tar.gz";
      });
      build = {
        buildPhase = "make -f Makefile PREFIX=$out USE_OCAMLFIND=true docdir=false/menhir \"libdir=${(final.siteLib "$out")}/menhir\" mandir=$out/man/man1";
        installPhase = "make -f Makefile install PREFIX=$out docdir=false/menhir \"libdir=${(final.siteLib "$out")}/menhir\" mandir=$out/man/man1";
        mode = "opam";
      };
    };
    mew = {
      pname = "mew";
      version = "0.1.0";
      depKeys = [
        ("dune")
        ("ocaml")
        ("result")
        ("trie")
      ];
      src = (pkgs.fetchurl {
        hash = "sha256-ZNOM61LvV0yzFL3Wk/fkqcnkg+gKWFldsi8t92qKWeY=";
        url = "https://github.com/kandu/mew/archive/0.1.0.tar.gz";
      });
      build = {
        buildPhase = "dune build -p mew -j $NIX_BUILD_CORES";
        installPhase = "";
        mode = "opam";
      };
    };
    mew_vi = {
      pname = "mew_vi";
      version = "0.5.0";
      depKeys = [
        ("dune")
        ("mew")
        ("ocaml")
        ("react")
      ];
      src = (pkgs.fetchurl {
        hash = "sha256-ppL6fNzJ6A/ZOHxPYWd3drn8Ffn3F1tCIPzRpz0br9o=";
        url = "https://github.com/kandu/mew_vi/archive/0.5.0.tar.gz";
      });
      build = {
        buildPhase = "dune build -p mew_vi -j $NIX_BUILD_CORES";
        installPhase = "";
        mode = "opam";
      };
    };
    mirage-crypto = {
      pname = "mirage-crypto";
      version = "0.11.3";
      depKeys = [
        ("cstruct")
        ("dune")
        ("dune-configurator")
        ("eqaf")
        ("ocaml")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-e29OgShiK1PrIXaIG11hYPIk6GBsfdIar0eXTxXbeqR1z/r/MhSqqrug+JhjmPFZwfuxv/KSKMmwo/rmfvjXMQ==";
        url = "https://github.com/mirage/mirage-crypto/releases/download/v0.11.3/mirage-crypto-0.11.3.tbz";
      });
      build = {
        buildPhase = "dune build -p mirage-crypto -j $NIX_BUILD_CORES";
        installPhase = "";
        mode = "opam";
      };
    };
    mirage-crypto-ec = {
      pname = "mirage-crypto-ec";
      version = "0.11.3";
      depKeys = [
        ("cstruct")
        ("dune")
        ("dune-configurator")
        ("eqaf")
        ("mirage-crypto")
        ("mirage-crypto-rng")
        ("ocaml")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-e29OgShiK1PrIXaIG11hYPIk6GBsfdIar0eXTxXbeqR1z/r/MhSqqrug+JhjmPFZwfuxv/KSKMmwo/rmfvjXMQ==";
        url = "https://github.com/mirage/mirage-crypto/releases/download/v0.11.3/mirage-crypto-0.11.3.tbz";
      });
      build = {
        buildPhase = "dune build -p mirage-crypto-ec -j $NIX_BUILD_CORES";
        installPhase = "";
        mode = "opam";
      };
    };
    mirage-crypto-pk = {
      pname = "mirage-crypto-pk";
      version = "0.11.3";
      depKeys = [
        ("conf-gmp-powm-sec")
        ("cstruct")
        ("dune")
        ("eqaf")
        ("mirage-crypto")
        ("mirage-crypto-rng")
        ("ocaml")
        ("sexplib0")
        ("zarith")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-e29OgShiK1PrIXaIG11hYPIk6GBsfdIar0eXTxXbeqR1z/r/MhSqqrug+JhjmPFZwfuxv/KSKMmwo/rmfvjXMQ==";
        url = "https://github.com/mirage/mirage-crypto/releases/download/v0.11.3/mirage-crypto-0.11.3.tbz";
      });
      build = {
        buildPhase = "dune build -p mirage-crypto-pk -j $NIX_BUILD_CORES";
        installPhase = "";
        mode = "opam";
      };
    };
    mirage-crypto-rng = {
      pname = "mirage-crypto-rng";
      version = "0.11.3";
      depKeys = [
        ("cstruct")
        ("dune")
        ("dune-configurator")
        ("duration")
        ("logs")
        ("mirage-crypto")
        ("ocaml")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-e29OgShiK1PrIXaIG11hYPIk6GBsfdIar0eXTxXbeqR1z/r/MhSqqrug+JhjmPFZwfuxv/KSKMmwo/rmfvjXMQ==";
        url = "https://github.com/mirage/mirage-crypto/releases/download/v0.11.3/mirage-crypto-0.11.3.tbz";
      });
      build = {
        buildPhase = "dune build -p mirage-crypto-rng -j $NIX_BUILD_CORES";
        installPhase = "";
        mode = "opam";
      };
    };
    num = {
      pname = "num";
      version = "1.5";
      depKeys = [
        ("ocaml")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-EQ3QEUDByW9fBnqoJLtj90omQR3KplqvBMtsRLEWygKqq5UF9DHGaWQ4jOSjHYbaWSi0wOVVeADoNN6AvtRklQ==";
        url = "https://github.com/ocaml/num/archive/v1.5.tar.gz";
      });
      build = {
        buildPhase = "make PROFILE=release opam-modern";
        installPhase = "";
        mode = "opam";
      };
    };
    obus = {
      pname = "obus";
      version = "1.2.5";
      depKeys = [
        ("dune")
        ("lwt")
        ("lwt_log")
        ("lwt_ppx")
        ("lwt_react")
        ("menhir")
        ("ocaml")
        ("ppxlib")
        ("xmlm")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-S1QElxiKfXj08U+Uxrf9/0fdBkNqNOZQ/zeN13uz4qy3r9Rc1y2vTdugbnMumUTVYMKILcN4YvGx8btt835iBQ==";
        url = "https://github.com/ocaml-community/obus/releases/download/1.2.5/obus-1.2.5.tar.gz";
      });
      build = {
        buildPhase = "dune build -p obus -j $NIX_BUILD_CORES";
        installPhase = "";
        mode = "opam";
      };
    };
    ocaml = {
      pname = "ocaml";
      version = "4.12.1";
      depKeys = [
        ("dkml-base-compiler")
        ("ocaml-config")
      ];
      build = {
        buildPhase = "ocaml \"${(final.getDrv "ocaml-config")}/share/gen_ocaml_config.ml\" 4.12.1 ocaml";
        installPhase = "";
        mode = "opam";
      };
    };
    ocaml-compiler-libs = {
      pname = "ocaml-compiler-libs";
      version = "v0.12.4";
      depKeys = [
        ("dune")
        ("ocaml")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-l426jfph+Y+iT9p6nCbC6DcIHzfRaF/mNtwZz8MnipQM8BoQKTUEsYXEBnBrwQCLxUMT1Q8CO83qbVrGwHiLNQ==";
        url = "https://github.com/janestreet/ocaml-compiler-libs/releases/download/v0.12.4/ocaml-compiler-libs-v0.12.4.tbz";
      });
      build = {
        buildPhase = "dune build -p ocaml-compiler-libs -j $NIX_BUILD_CORES @install";
        installPhase = "";
        mode = "opam";
      };
    };
    ocaml-config = {
      pname = "ocaml-config";
      version = "3";
      depKeys = [
        ("dkml-base-compiler")
      ];
      build = {
        buildPhase = "";
        installPhase = "";
        mode = "opam";
      };
      extraSources = {
        "gen_ocaml_config.ml.in" = (pkgs.fetchurl {
          hash = "sha256-qa2NhKCJYRWWU6l425LRD2lFEBgrIGysuW1cn2O1Eh4=";
          url = "https://raw.githubusercontent.com/ocaml/opam-source-archives/main/patches/ocaml-config/gen_ocaml_config.ml.in.3";
        });
        "ocaml-config.install" = (pkgs.fetchurl {
          hash = "sha256-bk/ZP0zOa60O08CK/QJI2+fXgXEJKB3mKU5bXvVZcFE=";
          url = "https://raw.githubusercontent.com/ocaml/opam-source-archives/main/patches/ocaml-config/ocaml-config.install";
        });
      };
    };
    ocaml-syntax-shims = {
      pname = "ocaml-syntax-shims";
      version = "1.0.0";
      depKeys = [
        ("dune")
        ("ocaml")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-dcTGsL+hJnqKSagrpJTQjPCCP8g1CGPW09SXFSjLCeWiop4pgdBMdedq0PSTYLBaQyye/v+aT7wexrKJYDmYUg==";
        url = "https://github.com/ocaml-ppx/ocaml-syntax-shims/releases/download/1.0.0/ocaml-syntax-shims-1.0.0.tbz";
      });
      build = {
        buildPhase = "dune build -p ocaml-syntax-shims -j $NIX_BUILD_CORES @install";
        installPhase = "";
        mode = "opam";
      };
    };
    ocamlbuild = {
      pname = "ocamlbuild";
      version = "0.14.3";
      depKeys = [
        ("ocaml")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-3vj6HVSIkF/aMfcrf28OvczvpVqOmEpupKfB4IVujqH3gUQQIC4Pf31ecqyn6K4NZiP38rreeLDdghVd527E5Q==";
        url = "https://github.com/ocaml/ocamlbuild/archive/refs/tags/0.14.3.tar.gz";
      });
      build = {
        buildPhase = ''
          make -f configure.make all OCAMLBUILD_PREFIX=$out OCAMLBUILD_BINDIR=$out/bin "OCAMLBUILD_LIBDIR=${(final.siteLib "$out")}" OCAMLBUILD_MANDIR=$out/man OCAML_NATIVE=true OCAML_NATIVE_TOOLS=true
          make check-if-preinstalled all opam-install
        '';
        installPhase = "";
        mode = "opam";
      };
    };
    ocamlfind = {
      pname = "ocamlfind";
      version = "1.9.6";
      depKeys = [
        ("ocaml")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-z68YctbM2lSPB9MsxrkMOq/hNtKqZTngMUNwIXHuAZmt1VJpu6iUx3EVU13Ealg1kBpdfHV2iZnnLbUDv9gwJw==";
        url = "http://download.camlcity.org/download/findlib-1.9.6.tar.gz";
      });
      build = {
        buildPhase = ''
          ./configure -bindir $out/bin -sitelib "${(final.siteLib "$out")}" -mandir $out/man -config "${(final.siteLib "$out")}/findlib.conf" -no-custom -no-topfind
          make all
          make opt
        '';
        installPhase = ''
          make install
          install -m 0755 ocaml-stub $out/bin/ocaml
        '';
        mode = "opam";
      };
      extraSources = {
        "0001-Harden-test-for-OCaml-5.patch" = (pkgs.fetchurl {
          hash = "sha256-b8yl8ver+NYwTabDhTSFhAE/+4YCciqH+wusurWGf+g=";
          url = "https://raw.githubusercontent.com/ocaml/opam-source-archives/main/patches/ocamlfind/0001-Harden-test-for-OCaml-5.patch";
        });
      };
    };
    ocplib-endian = {
      pname = "ocplib-endian";
      version = "1.2";
      depKeys = [
        ("base-bytes")
        ("cppo")
        ("dune")
        ("ocaml")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-LnC+Xz1uN3SFxgZkoOI1w7mySo1ragOJXQksbkDVOBC/4fKS7mnlGBzm2qilgr/j1Z86+In0FxNPZYgSvluLhQ==";
        url = "https://github.com/OCamlPro/ocplib-endian/archive/refs/tags/1.2.tar.gz";
      });
      build = {
        buildPhase = "dune build -p ocplib-endian -j $NIX_BUILD_CORES @install";
        installPhase = "";
        mode = "opam";
      };
    };
    odoc = {
      pname = "odoc";
      version = "2.4.2";
      depKeys = [
        ("astring")
        ("cmdliner")
        ("cppo")
        ("crunch")
        ("dune")
        ("fmt")
        ("fpath")
        ("ocaml")
        ("odoc-parser")
        ("result")
        ("tyxml")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-jUjJngwlN5EXfdZSh85c7kfnxoBeM/OuDPbI59NJEo8m7rvjZFnDFCnBFRmtWXnb42+8uUA6X94ZmmmXaj+zpg==";
        url = "https://github.com/ocaml/odoc/releases/download/2.4.2/odoc-2.4.2.tbz";
      });
      build = {
        buildPhase = "dune build -p odoc -j $NIX_BUILD_CORES @install";
        installPhase = "";
        mode = "opam";
      };
    };
    odoc-parser = {
      pname = "odoc-parser";
      version = "2.4.2";
      depKeys = [
        ("astring")
        ("camlp-streams")
        ("dune")
        ("ocaml")
        ("result")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-jUjJngwlN5EXfdZSh85c7kfnxoBeM/OuDPbI59NJEo8m7rvjZFnDFCnBFRmtWXnb42+8uUA6X94ZmmmXaj+zpg==";
        url = "https://github.com/ocaml/odoc/releases/download/2.4.2/odoc-2.4.2.tbz";
      });
      build = {
        buildPhase = "dune build -p odoc-parser -j $NIX_BUILD_CORES @install";
        installPhase = "";
        mode = "opam";
      };
    };
    parsexp = {
      pname = "parsexp";
      version = "v0.15.0";
      depKeys = [
        ("base")
        ("dune")
        ("ocaml")
        ("sexplib0")
      ];
      src = (pkgs.fetchurl {
        hash = "sha256-0e6QKxKsfAyIiGMCWZDQaEVTD7dTKEVIFOXOW21D0ZM=";
        url = "https://ocaml.janestreet.com/ocaml-core/v0.15/files/parsexp-v0.15.0.tar.gz";
      });
      build = {
        buildPhase = "dune build -p parsexp -j $NIX_BUILD_CORES";
        installPhase = "";
        mode = "opam";
      };
    };
    pbkdf = {
      pname = "pbkdf";
      version = "1.2.0";
      depKeys = [
        ("cstruct")
        ("dune")
        ("mirage-crypto")
        ("ocaml")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-1vfV79dhuH3UIN3Pl8L51EAtzIHWXNH02BA5twxNjB6AO7r0JRSC3o3nB22p9AtIx+sWhOMeejFt61A2wZK9PA==";
        url = "https://github.com/abeaumont/ocaml-pbkdf/archive/1.2.0.tar.gz";
      });
      build = {
        buildPhase = "dune build -j $NIX_BUILD_CORES -p pbkdf @install";
        installPhase = "";
        mode = "opam";
      };
    };
    ppx_derivers = {
      pname = "ppx_derivers";
      version = "1.2.1";
      depKeys = [
        ("dune")
        ("ocaml")
      ];
      src = (pkgs.fetchurl {
        hash = "sha256-tlle4Yfep5KzH8VKDhUkqx5IvGBo0wZsRSFaE4zHO5U=";
        url = "https://github.com/ocaml-ppx/ppx_derivers/archive/1.2.1.tar.gz";
      });
      build = {
        buildPhase = "dune build -p ppx_derivers -j $NIX_BUILD_CORES";
        installPhase = "";
        mode = "opam";
      };
    };
    ppx_sexp_conv = {
      pname = "ppx_sexp_conv";
      version = "v0.15.1";
      depKeys = [
        ("base")
        ("dune")
        ("ocaml")
        ("ppxlib")
        ("sexplib0")
      ];
      src = (pkgs.fetchurl {
        hash = "sha256-40ZHhQxYmSpGPymxG4Y/mxMircCpjTsWAoASUH4MLp0=";
        url = "https://github.com/janestreet/ppx_sexp_conv/archive/refs/tags/v0.15.1.tar.gz";
      });
      build = {
        buildPhase = "dune build -p ppx_sexp_conv -j $NIX_BUILD_CORES";
        installPhase = "";
        mode = "opam";
      };
    };
    ppxlib = {
      pname = "ppxlib";
      version = "0.32.1";
      depKeys = [
        ("dune")
        ("ocaml")
        ("ocaml-compiler-libs")
        ("ppx_derivers")
        ("sexplib0")
        ("stdlib-shims")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-e5O2IrEZR43eA63PSZPnPqk3yRwoDkU8zuYxxoLYWJ7LMYQfEdahSWYjmVTiLgANqK++JaDwiVMschC2mMUlUw==";
        url = "https://github.com/ocaml-ppx/ppxlib/releases/download/0.32.1/ppxlib-0.32.1.tbz";
      });
      build = {
        buildPhase = "dune build -p ppxlib -j $NIX_BUILD_CORES @install";
        installPhase = "";
        mode = "opam";
      };
    };
    ptime = {
      pname = "ptime";
      version = "1.1.0";
      depKeys = [
        ("ocaml")
        ("ocamlbuild")
        ("ocamlfind")
        ("topkg")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-MJuDg/YbWIQOWKgoAuyPvGG3zJWkWQ04rUJ+SEy6r2bwP6jmSEtbaFVGiofnRa7RA79vEEHsBQYiMKn6X7hsxg==";
        url = "https://erratique.ch/software/ptime/releases/ptime-1.1.0.tbz";
      });
      build = {
        buildPhase = "ocaml pkg/pkg.ml build --dev-pkg false";
        installPhase = "";
        mode = "opam";
      };
    };
    re = {
      pname = "re";
      version = "1.11.0";
      depKeys = [
        ("dune")
        ("ocaml")
        ("seq")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-PjcSzBJm7B8nYg81COouu6M49Ag7B9imnczuH6z9wZcabDn53upmTSpi/X8s/S6ugWykwnSs+trumSo778S3Vw==";
        url = "https://github.com/ocaml/ocaml-re/releases/download/1.11.0/re-1.11.0.tbz";
      });
      build = {
        buildPhase = "dune build -p re -j $NIX_BUILD_CORES";
        installPhase = "";
        mode = "opam";
      };
    };
    react = {
      pname = "react";
      version = "1.2.2";
      depKeys = [
        ("ocaml")
        ("ocamlbuild")
        ("ocamlfind")
        ("topkg")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-GM3VRNSEIiugLba9k1FXFRZTLnocEHtZu+ORk4NymPXHReq2dU+Lxv8SWzh75wGMbW5qyZ+RklpeT1OvaIUisQ==";
        url = "https://erratique.ch/software/react/releases/react-1.2.2.tbz";
      });
      build = {
        buildPhase = "ocaml pkg/pkg.ml build --dev-pkg false";
        installPhase = "";
        mode = "opam";
      };
    };
    remocaml = {
      pname = "remocaml";
      version = "dev";
      depKeys = [
        ("cohttp-lwt")
        ("cohttp-lwt-unix")
        ("dune")
        ("lwt")
        ("lwt_ppx")
        ("lwt_react")
        ("obus")
        ("ppx_sexp_conv")
        ("rresult")
        ("vdoml")
      ];
      src = (final.pathSrc .././.);
      build = {
        buildPhase = "dune build -p remocaml";
        depexts = [
          (pkgs.sassc or null)
        ];
        installPhase = "";
        mode = "opam";
      };
    };
    result = {
      pname = "result";
      version = "1.5";
      depKeys = [
        ("dune")
        ("ocaml")
      ];
      src = (pkgs.fetchurl {
        hash = "sha256-fDpeI4VY9MGk9azKgWvHBaDhL2jcAAXGHdvy5sq47jI=";
        url = "https://github.com/janestreet/result/releases/download/1.5/result-1.5.tbz";
      });
      build = {
        buildPhase = "dune build -p result -j $NIX_BUILD_CORES";
        installPhase = "";
        mode = "opam";
      };
    };
    rresult = {
      pname = "rresult";
      version = "0.7.0";
      depKeys = [
        ("ocaml")
        ("ocamlbuild")
        ("ocamlfind")
        ("topkg")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-8btjHJhpljiOlobUnVrk2KrxQDT2hlxiqI+1jEjOGa0ut4UyfWnKJ8Ay+DWYTgvS79lptBVDhiijHz6E7EVR0w==";
        url = "https://erratique.ch/software/rresult/releases/rresult-0.7.0.tbz";
      });
      build = {
        buildPhase = "ocaml pkg/pkg.ml build --dev-pkg false";
        installPhase = "";
        mode = "opam";
      };
    };
    seq = {
      pname = "seq";
      version = "base";
      depKeys = [
        ("ocaml")
      ];
      build = {
        buildPhase = "";
        installPhase = "";
        mode = "opam";
      };
      extraSources = {
        "META.seq" = (pkgs.fetchurl {
          hash = "sha256-6VBitNBRnvgzXAL30PGVLRG4FMerfm1WaiBhFhYvor4=";
          url = "https://raw.githubusercontent.com/ocaml/opam-source-archives/main/patches/seq/META.seq";
        });
        "seq.install" = (pkgs.fetchurl {
          hash = "sha256-//kmwsTVqCtslMYMTDXrBuPTmXWJPr5rHw5lV8vjSQQ=";
          url = "https://raw.githubusercontent.com/ocaml/opam-source-archives/main/patches/seq/seq.install";
        });
      };
    };
    sexplib = {
      pname = "sexplib";
      version = "v0.15.1";
      depKeys = [
        ("dune")
        ("num")
        ("ocaml")
        ("parsexp")
        ("sexplib0")
      ];
      src = (pkgs.fetchurl {
        hash = "sha256-ddp9KQ2S11jAH0QflYnMzgMeETAVY+/eHBkUnTntvLw=";
        url = "https://github.com/janestreet/sexplib/archive/refs/tags/v0.15.1.tar.gz";
      });
      build = {
        buildPhase = "dune build -p sexplib -j $NIX_BUILD_CORES";
        installPhase = "";
        mode = "opam";
      };
    };
    sexplib0 = {
      pname = "sexplib0";
      version = "v0.15.1";
      depKeys = [
        ("dune")
        ("ocaml")
      ];
      src = (pkgs.fetchurl {
        hash = "sha256-6M2BfrO8P4SiBl+gJVqyuYaiS68cwynQVifFFkZCZ7M=";
        url = "https://github.com/janestreet/sexplib0/archive/refs/tags/v0.15.1.tar.gz";
      });
      build = {
        buildPhase = "dune build -p sexplib0 -j $NIX_BUILD_CORES";
        installPhase = "";
        mode = "opam";
      };
    };
    stdlib-shims = {
      pname = "stdlib-shims";
      version = "0.3.0";
      depKeys = [
        ("dune")
        ("ocaml")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-EVHX7ciSNRbpo2mVo/iTjTI6qt51mtNJ7RXW2FAdth/75jJ36XxNhhSc83EwasI98PWB7H4CYR9YM1Em4YcJgA==";
        url = "https://github.com/ocaml/stdlib-shims/releases/download/0.3.0/stdlib-shims-0.3.0.tbz";
      });
      build = {
        buildPhase = "dune build -p stdlib-shims -j $NIX_BUILD_CORES";
        installPhase = "";
        mode = "opam";
      };
    };
    stringext = {
      pname = "stringext";
      version = "1.6.0";
      depKeys = [
        ("dune")
        ("ocaml")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-2OvkD0K1mKm9mfHvSwC6k0WDhaSszRIa9moL87P41xNfV2dArfGkMIHdQJl3wiGf1L27Wz0TCIkNMB1VPtSZAA==";
        url = "https://github.com/rgrinberg/stringext/releases/download/1.6.0/stringext-1.6.0.tbz";
      });
      build = {
        buildPhase = "dune build -p stringext -j $NIX_BUILD_CORES";
        installPhase = "";
        mode = "opam";
      };
    };
    topkg = {
      pname = "topkg";
      version = "1.0.7";
      depKeys = [
        ("ocaml")
        ("ocamlbuild")
        ("ocamlfind")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-CeWfF1m/TbhHHwLQrv2NtgK0STKikcBcMSsUI3luehXRWY08YqDOx/CD7/jkEPrAk2NTPcS9ISCRS7lmTv6lNQ==";
        url = "https://erratique.ch/software/topkg/releases/topkg-1.0.7.tbz";
      });
      build = {
        buildPhase = "ocaml pkg/pkg.ml build --pkg-name topkg --dev-pkg false";
        installPhase = "";
        mode = "opam";
      };
    };
    trie = {
      pname = "trie";
      version = "1.0.0";
      depKeys = [
        ("dune")
        ("ocaml")
      ];
      src = (pkgs.fetchurl {
        hash = "sha256-wvgFTqRCFuajqWGyj3Yw4OPb+9G1BK50G+Iwy+MkmOo=";
        url = "https://github.com/kandu/trie/archive/1.0.0.tar.gz";
      });
      build = {
        buildPhase = "dune build -p trie -j $NIX_BUILD_CORES";
        installPhase = "";
        mode = "opam";
      };
    };
    tyxml = {
      pname = "tyxml";
      version = "4.6.0";
      depKeys = [
        ("dune")
        ("ocaml")
        ("re")
        ("seq")
        ("uutf")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-aXUO6vRnAUKCCHv5Yo8yePPl8A9MdAA1h1DSCGZM/D95pcuhZ2fSk15TR30aaGL+CMW4AbaQUuwS4J0ak6XptA==";
        url = "https://github.com/ocsigen/tyxml/releases/download/4.6.0/tyxml-4.6.0.tbz";
      });
      build = {
        buildPhase = "dune build -p tyxml -j $NIX_BUILD_CORES @install";
        installPhase = "";
        mode = "opam";
      };
    };
    uchar = {
      pname = "uchar";
      version = "0.0.2";
      depKeys = [
        ("ocaml")
        ("ocamlbuild")
      ];
      src = (pkgs.fetchurl {
        hash = "sha256-Rzl/MWy+diNK9Tx0oflFIVS6O9tU/O1cqslZ9Q9XWvA=";
        url = "https://github.com/ocaml/uchar/releases/download/v0.0.2/uchar-0.0.2.tbz";
      });
      build = {
        buildPhase = ''
          ocaml pkg/git.ml
          ocaml pkg/build.ml native=true native-dynlink=true
        '';
        installPhase = "";
        mode = "opam";
      };
    };
    uri = {
      pname = "uri";
      version = "4.4.0";
      depKeys = [
        ("angstrom")
        ("dune")
        ("ocaml")
        ("stringext")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-iDdBQ+DYqvbUCqPL11k/mDLpyXJ3OMbmUUmBJRUMg9VkbhO1c31cPoFITdBBEn9n+KzqE/3AMArE5GEHVZ+K4g==";
        url = "https://github.com/mirage/ocaml-uri/releases/download/v4.4.0/uri-4.4.0.tbz";
      });
      build = {
        buildPhase = "dune build -p uri -j $NIX_BUILD_CORES";
        installPhase = "";
        mode = "opam";
      };
    };
    uri-sexp = {
      pname = "uri-sexp";
      version = "4.4.0";
      depKeys = [
        ("dune")
        ("ppx_sexp_conv")
        ("sexplib0")
        ("uri")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-iDdBQ+DYqvbUCqPL11k/mDLpyXJ3OMbmUUmBJRUMg9VkbhO1c31cPoFITdBBEn9n+KzqE/3AMArE5GEHVZ+K4g==";
        url = "https://github.com/mirage/ocaml-uri/releases/download/v4.4.0/uri-4.4.0.tbz";
      });
      build = {
        buildPhase = "dune build -p uri-sexp -j $NIX_BUILD_CORES";
        installPhase = "";
        mode = "opam";
      };
    };
    utop = {
      pname = "utop";
      version = "2.14.0";
      depKeys = [
        ("base-threads")
        ("base-unix")
        ("cppo")
        ("dune")
        ("lambda-term")
        ("logs")
        ("lwt")
        ("lwt_react")
        ("ocaml")
        ("ocamlfind")
        ("react")
        ("xdg")
        ("zed")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-1kpatnFCQnm+E+vQgN6sfuRuLJvDq8/Dem3/FkEkzDq8UoAVJ8NdkWDsho+bjzNIgAJqrqrQLlBxEv2DkglIRQ==";
        url = "https://github.com/ocaml-community/utop/releases/download/2.14.0/utop-2.14.0.tbz";
      });
      build = {
        buildPhase = "dune build -p utop -j $NIX_BUILD_CORES @install";
        installPhase = "";
        mode = "opam";
      };
    };
    uucp = {
      pname = "uucp";
      version = "15.0.0";
      depKeys = [
        ("cmdliner")
        ("ocaml")
        ("ocamlbuild")
        ("ocamlfind")
        ("topkg")
        ("uutf")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-7krP9WZpYXZjIeheKH+51bjVBTMxnyK/b07OuUMkLfLQ4PTndcShQPaMoUKDeTjqpZJuIjYiFaM2X/5/h2iSOw==";
        url = "https://erratique.ch/software/uucp/releases/uucp-15.0.0.tbz";
      });
      build = {
        buildPhase = "ocaml pkg/pkg.ml build --dev-pkg false --with-uutf true --with-uunf false --with-cmdliner true";
        installPhase = "";
        mode = "opam";
      };
    };
    uuseg = {
      pname = "uuseg";
      version = "15.0.0";
      depKeys = [
        ("cmdliner")
        ("ocaml")
        ("ocamlbuild")
        ("ocamlfind")
        ("topkg")
        ("uucp")
        ("uutf")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-N+qDtYLdd5oCbPrhHwj11n73n85los8D8qmqvH613mDI6BJST6dTHk/24io7GCKONDigFDzkO+lfIyN8woNXbw==";
        url = "https://erratique.ch/software/uuseg/releases/uuseg-15.0.0.tbz";
      });
      build = {
        buildPhase = "ocaml pkg/pkg.ml build --dev-pkg false --with-uutf true --with-cmdliner true";
        installPhase = "";
        mode = "opam";
      };
    };
    uutf = {
      pname = "uutf";
      version = "1.0.3";
      depKeys = [
        ("cmdliner")
        ("ocaml")
        ("ocamlbuild")
        ("ocamlfind")
        ("topkg")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-UMxEhgIdpG+wgVbp2uwNV7TKRpsHMJxQjVqaQenbzx8y3sLte+AnMmVERT3K+cJTSRk5X9gm3Hdo78bMS/zJ+A==";
        url = "https://erratique.ch/software/uutf/releases/uutf-1.0.3.tbz";
      });
      build = {
        buildPhase = "ocaml pkg/pkg.ml build --dev-pkg false --with-cmdliner true";
        installPhase = "";
        mode = "opam";
      };
    };
    vdoml = {
      pname = "vdoml";
      version = "dev";
      depKeys = [
        ("conf-python-3")
        ("dune")
        ("js_of_ocaml")
        ("js_of_ocaml-lwt")
        ("js_of_ocaml-ppx")
        ("logs")
        ("lwt")
        ("lwt_ppx")
        ("ocaml")
        ("ocamlfind")
        ("odoc")
      ];
      build = {
        buildPhase = "dune build -p vdoml -j $NIX_BUILD_CORES";
        installPhase = "";
        mode = "opam";
      };
    };
    x509 = {
      pname = "x509";
      version = "0.16.5";
      depKeys = [
        ("asn1-combinators")
        ("base64")
        ("cstruct")
        ("domain-name")
        ("dune")
        ("fmt")
        ("gmap")
        ("ipaddr")
        ("logs")
        ("mirage-crypto")
        ("mirage-crypto-ec")
        ("mirage-crypto-pk")
        ("mirage-crypto-rng")
        ("ocaml")
        ("pbkdf")
        ("ptime")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-bdSU26eZ6rft3irxtjusYDW/SuBvOjbdT6mrzRPQw/4+k9xYSLZUBdxUAbF1X9MMcUgsuR90lbyc+3xb8V721w==";
        url = "https://github.com/mirleft/ocaml-x509/releases/download/v0.16.5/x509-0.16.5.tbz";
      });
      build = {
        buildPhase = "dune build -p x509 -j $NIX_BUILD_CORES";
        installPhase = "";
        mode = "opam";
      };
    };
    xdg = {
      pname = "xdg";
      version = "3.15.3";
      depKeys = [
        ("dune")
        ("ocaml")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-yIrHpu2TNKS8YjHs+w76qWHdqZvDhv1bklBRUf+DPfrwWNdTBfu2TEluVwBY7JAArGrdBt2no5XnV+kkrx0afw==";
        url = "https://github.com/ocaml/dune/releases/download/3.15.3/dune-3.15.3.tbz";
      });
      build = {
        buildPhase = ''
          rm -rf vendor/csexp
          rm -rf vendor/pp
          dune build -p xdg -j $NIX_BUILD_CORES @install
        '';
        installPhase = "";
        mode = "opam";
      };
    };
    xmlm = {
      pname = "xmlm";
      version = "1.4.0";
      depKeys = [
        ("ocaml")
        ("ocamlbuild")
        ("ocamlfind")
        ("topkg")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-afYRLmRmlSJW1nD+F1H+SueeINUPAY7OFwnrIkDLGwCWisfO4RB3HgYXo468HNtD6dFGRxzmasGxduShZgUx6w==";
        url = "https://erratique.ch/software/xmlm/releases/xmlm-1.4.0.tbz";
      });
      build = {
        buildPhase = "ocaml pkg/pkg.ml build --dev-pkg false";
        installPhase = "";
        mode = "opam";
      };
    };
    yojson = {
      pname = "yojson";
      version = "2.1.2";
      depKeys = [
        ("cppo")
        ("dune")
        ("ocaml")
        ("seq")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-MJy6dWjexR3iDHq43wMyWMJ1uNWLCjamaybmc6O8BQy9fjn/j+R5bokmPhJbzCHgTcNqOU88wgGVaIfu4fsoGg==";
        url = "https://github.com/ocaml-community/yojson/releases/download/2.1.2/yojson-2.1.2.tbz";
      });
      build = {
        buildPhase = "dune build -p yojson -j $NIX_BUILD_CORES @install";
        installPhase = "";
        mode = "opam";
      };
    };
    zarith = {
      pname = "zarith";
      version = "1.13";
      depKeys = [
        ("conf-gmp")
        ("ocaml")
        ("ocamlfind")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-pWL6i/T170Tyr2uajwKBgv0YTIn4xBRVrNwChRzA/DEk03dsDekw6NCc1dbYjMaJ+A9LWXBooGERMfRdBXsQHw==";
        url = "https://github.com/ocaml/Zarith/archive/release-1.13.tar.gz";
      });
      build = {
        buildPhase = ''
          sh -exc "LDFLAGS=\"$LDFLAGS -L/opt/local/lib -L/usr/local/lib\" CFLAGS=\"$CFLAGS -I/opt/local/include -I/usr/local/include\" ./configure"
          make
        '';
        installPhase = "make install";
        mode = "opam";
      };
    };
    zed = {
      pname = "zed";
      version = "3.2.3";
      depKeys = [
        ("dune")
        ("ocaml")
        ("react")
        ("result")
        ("uchar")
        ("uucp")
        ("uuseg")
        ("uutf")
      ];
      src = (pkgs.fetchurl {
        hash = "sha512-Y391EpVQ9kWUF1SdRL7Ra9xich0ungxrtb+rMMW8ZHjeFfrs6MCRtW8jg3XLeae8F2N1QA5UMSC7MdfqYmt8Ww==";
        url = "https://github.com/ocaml-community/zed/archive/refs/tags/3.2.3.tar.gz";
      });
      build = {
        buildPhase = "dune build -p zed -j $NIX_BUILD_CORES @install";
        installPhase = "";
        mode = "opam";
      };
    };
  };
}