/// List utilities.
extension ListX<T> on List<T> {
  /// Returns the first element matching [test], or `null` if none found.
  T? firstWhereOrNull(bool Function(T) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
