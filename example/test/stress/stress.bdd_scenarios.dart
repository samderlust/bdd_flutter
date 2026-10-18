import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

class OrderProcessingBackground {
  Future<void> iAmLoggedInAsAdmin() async {
    // TODO: Implement Given I am logged in as "admin"
  }

  Future<void> theTimeIs0900() async {
    // TODO: Implement And the time is 09:00
  }

}

class DocStringAndDataTableStepsScenario {
  Future<void> theFollowingProducts(List<List<String>> dataTable) async {
    expect(dataTable, [['name', 'price'], ['apple', '1.5']]);
  }

  Future<void> iPostTheJson(String docString) async {
    expect(jsonDecode(docString), {'item': 'apple', 'qty': 2});
  }

  Future<void> theResponseStatusIs201() async {
    // TODO: Implement Then the response status is 201
  }

}

class SamePlaceholderTwiceAndPlaceholderInNameScenario {
  Future<void> iMoveQtyFromFromToToAndBackToFrom(WidgetTester tester, String qty, String from, String to) async {
    // TODO: Implement When I move <qty> from "<from>" to "<to>" and back to "<from>"
  }

  Future<void> theStockOfFromIsLeft(WidgetTester tester, String from, String left) async {
    // TODO: Implement Then the stock of "<from>" is <left>
  }

  Future<void> theSnakeCaseFirstValueWorks(WidgetTester tester, String firstValue) async {
    // TODO: Implement And the snake_case <first_value> works
  }

}

class StepsWithSymbols100ParensSlashesScenario {
  Future<void> aPriceOf1000(WidgetTester tester) async {
    // TODO: Implement Given a price of $10.00
  }

  Future<void> iApplyA15Discount(WidgetTester tester) async {
    // TODO: Implement When I apply a 15% discount
  }

  Future<void> thePriceIs850(WidgetTester tester) async {
    // TODO: Implement Then the price is $8.50
  }

  Future<void> nothingElseHappens(WidgetTester tester) async {
    // TODO: Implement * nothing else happens
  }

  Future<void> noEmailIsSent(WidgetTester tester) async {
    // TODO: Implement But no email is sent
  }

}

class CancelBeforeShippingScenario {
  Future<void> anOrderExists(WidgetTester tester) async {
    // TODO: Implement Given an order exists
  }

  Future<void> iCancelTheOrder(WidgetTester tester) async {
    // TODO: Implement When I cancel the order
  }

  Future<void> theOrderIsCancelled(WidgetTester tester) async {
    // TODO: Implement Then the order is "cancelled"
  }

}

class CancelAfterShippingScenario {
  Future<void> anOrderExists(WidgetTester tester) async {
    // TODO: Implement Given an order exists
  }

  Future<void> theOrderHasShipped(WidgetTester tester) async {
    // TODO: Implement When the order has shipped
  }

  Future<void> iCancelTheOrder(WidgetTester tester) async {
    // TODO: Implement And I cancel the order
  }

  Future<void> iSeeTooLate(WidgetTester tester) async {
    // TODO: Implement Then I see "Too late"
  }

}

class X2RefundsInOneDayScenario {
  Future<void> refundsToday() async {
    // TODO: Implement Given 2 refunds today
  }

  Future<void> the3rdRefundIsBlocked() async {
    // TODO: Implement Then the 3rd refund is blocked
  }

}


class PlaceholdersInsideDocStringsAndTablesScenario {
  late Map<String, dynamic> payload;

  Future<void> iSendThePayload(String docString) async {
    payload = jsonDecode(docString) as Map<String, dynamic>;
  }

  Future<void> theTableShows(List<List<String>> dataTable) async {
    final row = dataTable[1];
    expect(row[0], payload['item']);
    expect(payload['note'], "it's \$${row[1]}");
  }

}

