import 'package:example/src/cart.dart';
import 'package:flutter_test/flutter_test.dart';

/// Shared between the Background and the scenario classes.
late Cart cart;

class ShoppingCartBackground {
  Future<void> anEmptyCart() async {
    cart = Cart();
  }

}

class AddAndRemoveItemsScenario {
  Future<void> iAdd2AppleAt15Each() async {
    cart.add('apple', 1.5, 2);
  }

  Future<void> iAdd1PearAt2Each() async {
    cart.add('pear', 2, 1);
  }

  Future<void> iRemoveApple() async {
    cart.remove('apple');
  }

  Future<void> theCartHas1Item() async {
    expect(cart.itemCount, 1);
  }

  Future<void> theTotalIs2() async {
    expect(cart.total, 2);
  }

}

class TotalForSeveralItemsScenario {
  Future<void> iAddQuantityItemAtPriceEach(String quantity, String item, String price) async {
    cart.add(item, double.parse(price), int.parse(quantity));
  }

  Future<void> theTotalForItemIsTotal(String item, String total) async {
    expect(cart.totalFor(item), double.parse(total));
  }

}

class AddingToAClosedCartScenario {
  Future<void> theCartIsClosed() async {
    cart.isClosed = true;
  }

  Future<void> iAdd1AppleAt15Each() async {
    cart.add('apple', 1.5, 1);
  }

  Future<void> iSeeTheErrorCartIsClosed() async {
    expect(cart.error, 'Cart is closed');
  }

  Future<void> theCartHas0Item() async {
    expect(cart.itemCount, 0);
  }

}
