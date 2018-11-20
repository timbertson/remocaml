{ pkgs ? import <nixpkgs> {}}:
let drv = {
	pkgs ? pkgs,
	opam2nixBin ? null,
	vdoml ? null,
	opam2nix ? pkgs.callPackage ../../ocaml/opam2nix-packages/nix/release/default.nix { inherit opam2nixBin; }
}: pkgs.callPackage ./nix {
	inherit opam2nix;
	extraPackages = ["utop"];
};
in
(pkgs.nix-pin.api {}).callPackage drv {}
