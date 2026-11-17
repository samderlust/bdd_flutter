import 'package:bdd_flutter/bdd_flutter.dart';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

/// The steps of the feature "Order processing".
class OrderProcessingSteps {
  late WidgetTester tester;

  String? user;
  int? status;
  late Map<String, dynamic> payload;
  final Map<String, num> stock = {};
  double price = 0;
  int emailsSent = 0;
  String order = 'none';
  bool shipped = false;
  String? message;
  int refunds = 0;

  @Given('I am logged in as {string}')
  Future<void> iAmLoggedInAs(String text) async {
    user = text;
  }

  @Given('the time is 09:00')
  Future<void> theTimeIs0900() async {
    expect(user, 'admin');
  }

  @Given('the following products:')
  Future<void> theFollowingProducts(List<List<String>> dataTable) async {
    expect(dataTable, [
      ['name', 'price'],
      ['apple', '1.5'],
    ]);
  }

  @When('I post the JSON:')
  Future<void> iPostTheJson(String docString) async {
    expect(jsonDecode(docString), {'item': 'apple', 'qty': 2});
    status = 201;
  }

  @Then('the response status is {num}')
  Future<void> theResponseStatusIs(num number) async {
    expect(status, number);
  }

  @When('I send the payload:')
  Future<void> iSendThePayload(String docString) async {
    payload = jsonDecode(docString) as Map<String, dynamic>;
  }

  @Then('the table shows:')
  Future<void> theTableShows(List<List<String>> dataTable) async {
    final row = dataTable[1];
    expect(row[0], payload['item']);
    expect(payload['note'], "it's \$${row[1]}");
  }

  @When('I move {num} from {string} to {string} and back to {string}')
  Future<void> iMoveFromToAndBackTo(
    num qty,
    String from,
    String to,
    String from2,
  ) async {
    expect(from2, from);
    stock[from] = 10 - qty;
  }

  @Then('the stock of {string} is {num}')
  Future<void> theStockOfIs(String from, num left) async {
    expect(stock[from], left);
  }

  @Then('the snake_case {} works')
  Future<void> theSnakeCaseWorks(String firstValue) async {
    expect(firstValue, isNotEmpty);
  }

  @Given(r'a price of $10.00')
  Future<void> aPriceOf1000() async {
    price = 10;
  }

  @When('I apply a 15% discount')
  Future<void> iApplyA15Discount() async {
    price *= 0.85;
  }

  @Then(r'the price is $8.50')
  Future<void> thePriceIs850() async {
    expect(price, closeTo(8.5, 1e-9));
  }

  @Then('nothing else happens')
  Future<void> nothingElseHappens() async {
    expect(emailsSent, 0);
  }

  @Then('no email is sent')
  Future<void> noEmailIsSent() async {
    expect(emailsSent, 0);
  }

  @Given('an order exists')
  Future<void> anOrderExists() async {
    order = 'open';
  }

  @When('the order has shipped')
  Future<void> theOrderHasShipped() async {
    shipped = true;
  }

  @When('I cancel the order')
  Future<void> iCancelTheOrder() async {
    if (shipped) {
      message = 'Too late';
      return;
    }
    order = 'cancelled';
  }

  @Then('the order is {string}')
  Future<void> theOrderIs(String text) async {
    expect(order, text);
  }

  @Then('I see {string}')
  Future<void> iSee(String text) async {
    expect(message, text);
  }

  @Given('{num} refunds today')
  Future<void> refundsToday(num number) async {
    refunds = number.toInt();
  }

  @Then('the 3rd refund is blocked')
  Future<void> the3rdRefundIsBlocked() async {
    expect(refunds + 1, greaterThan(2));
  }
}
