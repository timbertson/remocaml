{ pkgs, stdenv, opam2nix, vdoml, extraDeps ? [] }:
stdenv.mkDerivation {
	name = "remocaml";
	# src = ../.;
	buildInputs = opam2nix.build {
		specs = opam2nix.toSpecs ([
			"dune"
			"obus"
			"cohttp-lwt"
			"cohttp-lwt-unix"
			"lwt"
			"lwt_react"
			"ppx_sexp_conv"
			"vdoml"
		] ++ extraDeps);
		extraRepos = [
			vdoml.opam2nix.repo
		];
		ocamlAttr = "ocaml-ng.ocamlPackages_4_06.ocaml";
		overrides = { super, self }: {
			opamPackages = super.opamPackages // {
				# logs = super.opamPackages.logs // {
				# 	"0.6.2" = super.opamPackages.logs."0.6.2".overrideAttrs (o: {
				# 		buildPhase = ''
				# 			export OPAM2NIX_VERBOSE=1;
				# 		'' + o.buildPhase;
				# 	});
				# };
				num = super.opamPackages.num // {
					"1.1" = super.opamPackages.num."1.1".overrideAttrs (o: {
						# Note: needs at least git commit 7dd5e935aaa2b902585b3b2d0e55ad9b2442fff0
						# for findlib-install target
						src = (pkgs.nix-update-source.fetch ./num.json).src;
					});
				};
			};
		};
	} ++ [pkgs.sassc];
}

