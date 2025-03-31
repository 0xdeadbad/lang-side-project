{
  mkShell,
  zig-dev,
  zls-dev,
  wakatime,
  tree-sitter-zig,
}:
mkShell {
  packages = [
    zig-dev
    zls-dev
    wakatime
    tree-sitter-zig
  ];
}
