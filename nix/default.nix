{ pkgs, stdenv, opam2nix, vdoml, self, extraSpecs ? [] }:
let
	opamPackages = opam2nix.build {
		inherit (pkgs.ocaml-ng.ocamlPackages_4_08) ocaml;
		src = {
			remocaml = self;
			vdoml = vdoml;
		};
		selection = ./opam-selection.nix;
	};
in
{
	inherit opam2nix vdoml;
	inherit (opamPackages) remocaml;
	shell = opamPackages.remocaml;
}

