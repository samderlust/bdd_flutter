import 'package:bdd_flutter/bdd_flutter.dart';
import 'package:example/src/cart.dart';
import 'package:flutter_test/flutter_test.dart';

/// Whether the cart accepts changes, written as `open` or `closed` in steps.
enum CartState { open, closed }

/// The steps of the feature "Shopping cart".
class ShoppingCartSteps {
  late Cart cart;

  /// `{state}` in an expression: `open` or `closed`, passed as a [CartState].
  @ParameterType(r'open|closed')
  static CartState state(String value) => CartState.values.byName(value);

  /// Runs after every scenario, even when a step fails.
  @After()
  Future<void> neverNegative() async {
    expect(cart.itemCount, greaterThanOrEqualTo(0));
  }

  @Given('an empty cart')
  Future<void> anEmptyCart() async {
    cart = Cart();
  }

  @When('I add {int} {string} at {float} each')
  Future<void> iAdd(int quantity, String item, double price) async {
    cart.add(item, price, quantity);
  }

  @When('I remove {string}')
  Future<void> iRemove(String item) async {
    cart.remove(item);
  }

  @Then('the cart has {int} item(s)')
  Future<void> theCartHas(int count) async {
    expect(cart.itemCount, count);
  }

  @Then('the total is {float}')
  Future<void> theTotalIs(double total) async {
    expect(cart.total, total);
  }

  @Then('the total for {string} is {float}')
  Future<void> theTotalFor(String item, double total) async {
    expect(cart.totalFor(item), total);
  }

  @Given('the cart is closed')
  Future<void> theCartIsClosed() async {
    cart.isClosed = true;
  }

  @Then('the cart should be {state}')
  Future<void> theCartShouldBe(CartState state) async {
    expect(cart.isClosed, state == CartState.closed);
  }

  @Then('I see the error {string}')
  Future<void> iSeeTheError(String message) async {
    expect(cart.error, message);
  }
}
