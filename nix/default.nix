{ pkgs, stdenv, opam2nix, vdoml, extraPackages ? [] }:
let extraSpecs = opam2nix.toSpecs extraPackages; in
(opam2nix.buildOpamPackage {
	name = "remocaml";
	version = "0.1.0";
	src = ../.; # (pkgs.nix-update-source.fetch ./src.json).src;
	extraRepos = [
		vdoml.opam2nix.repo
	];
	specs = extraSpecs;
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
			# num = super.opamPackages.num // {
			# 	"1.1" = super.opamPackages.num."1.1".overrideAttrs (o: {
			# 		# Note: needs at least git commit 7dd5e935aaa2b902585b3b2d0e55ad9b2442fff0
			# 		# for findlib-install target
			# 		src = (pkgs.nix-update-source.fetch ./num.json).src;
			# 	});
			# };
		};
	};
}).overrideAttrs (o: with pkgs.lib; {
	buildInputs = o.buildInputs ++ [pkgs.sassc] ++ (map (spec: getAttr spec.name o.passthru.opam2nix.packages) extraSpecs);
})

