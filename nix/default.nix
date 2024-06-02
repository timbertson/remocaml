{ callPackage, stdenv, lib }:
let
	sources = callPackage ./sources.nix {};
	fetlock = callPackage sources.fetlock {};
	selection = fetlock.opam.load ./lock.nix {
		pkgOverrides = self: [
			(self.setSources {
				inherit (sources) vdoml;
				remocaml = sources.local { url = ../.; };
			})
		];
	};
	opamPackages = selection.drvsByName;
in

{
	inherit (opamPackages) remocaml vdoml;
	shell = opamPackages.remocaml.overrideAttrs (o: {
		VDOML_SRC = vdoml;
		propagatedBuildInputs = o.propagatedBuildInputs ++ [ opamPackages.utop ];
	});
}
