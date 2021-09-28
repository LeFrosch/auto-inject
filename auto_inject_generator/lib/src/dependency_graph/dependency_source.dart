abstract class DependencySource {
  final Type type;

  const DependencySource(this.type);

  String create();
}
