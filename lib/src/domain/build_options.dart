/// Options passed from the CLI to control build behavior.
class BuildOptions {
  /// When true, regenerates all files regardless of manifest state.
  final bool force;

  const BuildOptions({
    this.force = false,
  });
}
