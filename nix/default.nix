let sources = import ./sources.nix {}; in
{ pkgs, stdenv, lib,
	opam2nix ? pkgs.callPackage sources.opam2nix {},
	vdoml ? sources.vdoml,
}:
let
	ocaml = pkgs.ocaml-ng.ocamlPackages_4_12.ocaml;
	opamArgs = {
		inherit ocaml;
		src = {
			remocaml = sources.local { url = ../.; };
			vdoml = vdoml;
		};
		selection = ./opam-selection.nix;
	};
	opamPackages = opam2nix.build opamArgs;
in
{
	inherit opam2nix vdoml;
	inherit (opamPackages) remocaml;
	shell = opamPackages.remocaml.overrideAttrs (o: {
		propagatedBuildInputs = o.propagatedBuildInputs ++ [ opamPackages.utop ];
	});
	resolve = opam2nix.resolve opamArgs [
		"${vdoml}/vdoml.opam"
		../remocaml.opam
		"utop"
	];
}

