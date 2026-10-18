import 'package:flutter_test/flutter_test.dart';
import 'cart.bdd_scenarios.dart';

void main() {
  group('Shopping cart', () {
    test('Add and remove items', () async {
      final scenario = AddAndRemoveItemsScenario();
      final background = ShoppingCartBackground();
      //Background: An empty cart
      await background.anEmptyCart();
      //Scenario: Add and remove items
      // When I add 2 "apple" at 1.5 each
      await scenario.iAdd2AppleAt15Each();
      // * I add 1 "pear" at 2 each
      await scenario.iAdd1PearAt2Each();
      // But I remove "apple"
      await scenario.iRemoveApple();
      // Then the cart has 1 item
      await scenario.theCartHas1Item();
      // And the total is 2
      await scenario.theTotalIs2();
    });
    test('Total for several items', () async {
      final scenario = TotalForSeveralItemsScenario();
      final background = ShoppingCartBackground();
      //Background: An empty cart
      await background.anEmptyCart();
      //Scenario: Total for several items
      final examples = [
        {'item': 'apple','quantity': '1','price': '1.5','total': '1.5',},
        {'item': 'pear','quantity': '2','price': '2','total': '4',},
        {'item': 'banana','quantity': '100','price': '0.25','total': '25',},
      ];
      for (var example in examples) {
      // When I add <quantity> "<item>" at <price> each
      await scenario.iAddQuantityItemAtPriceEach( example['quantity']!, example['item']!, example['price']!);
      // Then the total for "<item>" is <total>
      await scenario.theTotalForItemIsTotal( example['item']!, example['total']!);
      }
    });
    test('Adding to a closed cart', () async {
      final scenario = AddingToAClosedCartScenario();
      final background = ShoppingCartBackground();
      //Background: An empty cart
      await background.anEmptyCart();
      //Scenario: Adding to a closed cart
      // Given the cart is closed
      await scenario.theCartIsClosed();
      // When I add 1 "apple" at 1.5 each
      await scenario.iAdd1AppleAt15Each();
      // Then I see the error "Cart is closed"
      await scenario.iSeeTheErrorCartIsClosed();
      // And the cart has 0 item
      await scenario.theCartHas0Item();
    });
  });
}
