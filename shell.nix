let
  pkgs = import ./nix/nixpkgs.nix;
in
pkgs.mkShell {
  buildInputs = with pkgs; [
    babashka
    bash
    curl
    jq
  ];
}
