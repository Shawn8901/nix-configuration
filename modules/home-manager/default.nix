inputs:
{
  imports = [
    (import ./services/autoadb.nix inputs)
    (import ./services/noisetorch.nix inputs)
    (import ./env/vscode.nix inputs)
    (import ./env/browser.nix inputs)
  ];
}
