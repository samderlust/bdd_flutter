import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'stress.bdd_steps.g.dart';

/// The steps of the feature "Order processing".
class OrderProcessingSteps implements OrderProcessingStepsContract {
  @override
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

  @override
  Future<void> iAmLoggedInAs(String text) async {
    user = text;
  }

  @override
  Future<void> theTimeIs0900() async {
    expect(user, 'admin');
  }

  @override
  Future<void> theFollowingProducts(List<List<String>> dataTable) async {
    expect(dataTable, [
      ['name', 'price'],
      ['apple', '1.5'],
    ]);
  }

  @override
  Future<void> iPostTheJson(String docString) async {
    expect(jsonDecode(docString), {'item': 'apple', 'qty': 2});
    status = 201;
  }

  @override
  Future<void> theResponseStatusIs(num number) async {
    expect(status, number);
  }

  @override
  Future<void> iSendThePayload(String docString) async {
    payload = jsonDecode(docString) as Map<String, dynamic>;
  }

  @override
  Future<void> theTableShows(List<List<String>> dataTable) async {
    final row = dataTable[1];
    expect(row[0], payload['item']);
    expect(payload['note'], "it's \$${row[1]}");
  }

  @override
  Future<void> iMoveFromToAndBackTo(num qty, String from, String to, String from2) async {
    expect(from2, from);
    stock[from] = 10 - qty;
  }

  @override
  Future<void> theStockOfIs(String from, num left) async {
    expect(stock[from], left);
  }

  @override
  Future<void> theSnakeCaseWorks(String firstValue) async {
    expect(firstValue, isNotEmpty);
  }

  @override
  Future<void> aPriceOf1000() async {
    price = 10;
  }

  @override
  Future<void> iApplyA15Discount() async {
    price *= 0.85;
  }

  @override
  Future<void> thePriceIs850() async {
    expect(price, closeTo(8.5, 1e-9));
  }

  @override
  Future<void> nothingElseHappens() async {
    expect(emailsSent, 0);
  }

  @override
  Future<void> noEmailIsSent() async {
    expect(emailsSent, 0);
  }

  @override
  Future<void> anOrderExists() async {
    order = 'open';
  }

  @override
  Future<void> theOrderHasShipped() async {
    shipped = true;
  }

  @override
  Future<void> iCancelTheOrder() async {
    if (shipped) {
      message = 'Too late';
      return;
    }
    order = 'cancelled';
  }

  @override
  Future<void> theOrderIs(String text) async {
    expect(order, text);
  }

  @override
  Future<void> iSee(String text) async {
    expect(message, text);
  }

  @override
  Future<void> refundsToday(num number) async {
    refunds = number.toInt();
  }

  @override
  Future<void> the3rdRefundIsBlocked() async {
    expect(refunds + 1, greaterThan(2));
  }
}
