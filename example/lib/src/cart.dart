/// A shopping cart used by the `cart.feature` example.
class Cart {
  final Map<String, int> _quantities = {};
  final Map<String, double> _prices = {};
  bool isClosed = false;
  String? error;

  int get itemCount => _quantities.values.fold(0, (sum, q) => sum + q);

  double get total => _quantities.entries.fold(0, (sum, e) => sum + e.value * _prices[e.key]!);

  double totalFor(String item) => (_quantities[item] ?? 0) * (_prices[item] ?? 0);

  void add(String item, double price, int quantity) {
    if (isClosed) {
      error = 'Cart is closed';
      return;
    }
    _prices[item] = price;
    _quantities[item] = (_quantities[item] ?? 0) + quantity;
  }

  void remove(String item) => _quantities.remove(item);
}
