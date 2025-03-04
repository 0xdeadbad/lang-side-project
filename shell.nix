{
  mkShell,
  zig-dev,
  zls-dev,
  wakatime,
}:
mkShell {
  packages = [
    zig-dev
    zls-dev
    wakatime
  ];
}
