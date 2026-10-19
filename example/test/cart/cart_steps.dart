import 'package:example/src/cart.dart';
import 'package:flutter_test/flutter_test.dart';

import 'cart.bdd_steps.g.dart';

/// The steps of the feature "Shopping cart".
class ShoppingCartSteps implements ShoppingCartStepsContract {
  late Cart cart;

  @override
  Future<void> anEmptyCart() async {
    cart = Cart();
  }

  @override
  Future<void> iAddAtEach(num quantity, String item, num price) async {
    cart.add(item, price.toDouble(), quantity.toInt());
  }

  @override
  Future<void> iRemove(String text) async {
    cart.remove(text);
  }

  @override
  Future<void> theCartHasItem(num number) async {
    expect(cart.itemCount, number);
  }

  @override
  Future<void> theTotalIs(num number) async {
    expect(cart.total, number);
  }

  @override
  Future<void> theTotalForIs(String item, num total) async {
    expect(cart.totalFor(item), total);
  }

  @override
  Future<void> theCartIsClosed() async {
    cart.isClosed = true;
  }

  @override
  Future<void> iSeeTheError(String text) async {
    expect(cart.error, text);
  }
}
