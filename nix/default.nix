let sources = import ./sources.nix {}; in
{ pkgs, stdenv, lib,
	opam2nix ? pkgs.callPackage sources.opam2nix {},
	vdoml ? sources.vdoml,
}:
let
	ocaml = pkgs.ocaml-ng.ocamlPackages_4_14.ocaml;
	opamArgs = {
		inherit ocaml;
		src = {
			remocaml = sources.local { url = ../.; };
			vdoml = vdoml;
		};
		selection = ./opam-selection.nix;
		override = {}: {
			dune = base: base.overrideAttrs (base: {
				buildInputs = (base.buildInputs or []) ++
				(lib.optionals stdenv.isDarwin (with pkgs.darwin.apple_sdk;
					[ frameworks.CoreServices ]
				));
			});
		};

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

