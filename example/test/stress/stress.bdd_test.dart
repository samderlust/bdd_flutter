import 'package:flutter_test/flutter_test.dart';
import 'stress.bdd_scenarios.dart';

void main() {
  group('Order processing', () {
    test('Doc string and data table steps', () async {
      final scenario = DocStringAndDataTableStepsScenario();
      final background = OrderProcessingBackground();
      //Background: Logged-in user
      await background.iAmLoggedInAsAdmin();
      await background.theTimeIs0900();
      //Scenario: Doc string and data table steps
      // Given the following products:
      await scenario.theFollowingProducts([['name', 'price'], ['apple', '1.5']]);
      // When I post the JSON:
      await scenario.iPostTheJson('{ "item": "apple", "qty": 2 }');
      // Then the response status is 201
      await scenario.theResponseStatusIs201();
    });
    test('Placeholders inside doc strings and tables', () async {
      final scenario = PlaceholdersInsideDocStringsAndTablesScenario();
      final background = OrderProcessingBackground();
      //Background: Logged-in user
      await background.iAmLoggedInAsAdmin();
      await background.theTimeIs0900();
      //Scenario: Placeholders inside doc strings and tables
      final examples = [
        {'item': 'apple','price': '1.50',},
        {'item': 'pear','price': '2.00',},
      ];
      for (var example in examples) {
      // When I send the payload:
      await scenario.iSendThePayload('{"item": "<item>", "note": "it\'s \$<price>"}'.replaceAll('<item>', example['item']!).replaceAll('<price>', example['price']!));
      // Then the table shows:
      await scenario.theTableShows([['item', 'price'], ['<item>'.replaceAll('<item>', example['item']!), '<price>'.replaceAll('<price>', example['price']!)]]);
      }
    });
    testWidgets('Same placeholder twice and <placeholder> in name', (tester) async {
      final scenario = SamePlaceholderTwiceAndPlaceholderInNameScenario();
      final background = OrderProcessingBackground();
      //Background: Logged-in user
      await background.iAmLoggedInAsAdmin();
      await background.theTimeIs0900();
      //Scenario: Same placeholder twice and <placeholder> in name
      final examples = [
        {'from': 'Berlin','to': 'Paris','qty': '1','left': '9','firstValue': 'a',},
        {'from': 'Seattle','to': 'Austin','qty': '2','left': '8','firstValue': 'b',},
      ];
      for (var example in examples) {
      // When I move <qty> from "<from>" to "<to>" and back to "<from>"
      await scenario.iMoveQtyFromFromToToAndBackToFrom(tester, example['qty']!, example['from']!, example['to']!);
      // Then the stock of "<from>" is <left>
      await scenario.theStockOfFromIsLeft(tester, example['from']!, example['left']!);
      // And the snake_case <first_value> works
      await scenario.theSnakeCaseFirstValueWorks(tester, example['firstValue']!);
      }
    });
    testWidgets('Steps with symbols: 100% & (parens) / slashes', (tester) async {
      final scenario = StepsWithSymbols100ParensSlashesScenario();
      final background = OrderProcessingBackground();
      //Background: Logged-in user
      await background.iAmLoggedInAsAdmin();
      await background.theTimeIs0900();
      //Scenario: Steps with symbols: 100% & (parens) / slashes
      // Given a price of $10.00
      await scenario.aPriceOf1000(tester);
      // When I apply a 15% discount
      await scenario.iApplyA15Discount(tester);
      // Then the price is $8.50
      await scenario.thePriceIs850(tester);
      // * nothing else happens
      await scenario.nothingElseHappens(tester);
      // But no email is sent
      await scenario.noEmailIsSent(tester);
    });
    testWidgets('Cancel before shipping', (tester) async {
      final scenario = CancelBeforeShippingScenario();
      final background = OrderProcessingBackground();
      //Background: Logged-in user
      await background.iAmLoggedInAsAdmin();
      await background.theTimeIs0900();
      //Scenario: Cancel before shipping
      // Given an order exists
      await scenario.anOrderExists(tester);
      // When I cancel the order
      await scenario.iCancelTheOrder(tester);
      // Then the order is "cancelled"
      await scenario.theOrderIsCancelled(tester);
    });
    testWidgets('Cancel after shipping', (tester) async {
      final scenario = CancelAfterShippingScenario();
      final background = OrderProcessingBackground();
      //Background: Logged-in user
      await background.iAmLoggedInAsAdmin();
      await background.theTimeIs0900();
      //Scenario: Cancel after shipping
      // Given an order exists
      await scenario.anOrderExists(tester);
      // When the order has shipped
      await scenario.theOrderHasShipped(tester);
      // And I cancel the order
      await scenario.iCancelTheOrder(tester);
      // Then I see "Too late"
      await scenario.iSeeTooLate(tester);
    });
    test('2 refunds in one day', () async {
      final scenario = X2RefundsInOneDayScenario();
      final background = OrderProcessingBackground();
      //Background: Logged-in user
      await background.iAmLoggedInAsAdmin();
      await background.theTimeIs0900();
      //Scenario: 2 refunds in one day
      // Given 2 refunds today
      await scenario.refundsToday();
      // Then the 3rd refund is blocked
      await scenario.the3rdRefundIsBlocked();
    });
  });
}
