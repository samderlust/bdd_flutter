import 'package:bdd_flutter/bdd_flutter.dart';
import 'package:example/src/auth_provider.dart';
import 'package:example/src/auth_repository.dart';
import 'package:example/src/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart' hide When;
import 'package:provider/provider.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

/// The steps of the feature "Login".
class LoginSteps {
  late WidgetTester tester;

  late MockAuthRepository repository;

  @Given('I have a mock auth repository')
  Future<void> iHaveAMockAuthRepository() async {
    repository = MockAuthRepository();
  }

  @Given('the mock returns a successful login for {string}')
  Future<void> theMockReturnsASuccessfulLoginFor(String text) async {
    when(
      () => repository.login(text, any()),
    ).thenAnswer((_) async => User(name: 'Test User', email: text));
  }

  @Given('the mock throws an error for login')
  Future<void> theMockThrowsAnErrorForLogin() async {
    when(
      () => repository.login(any(), any()),
    ).thenThrow(Exception('Invalid credentials'));
  }

  @Given('the mock allows logout')
  Future<void> theMockAllowsLogout() async {
    when(() => repository.logout()).thenAnswer((_) async {});
  }

  @When('I pump the login screen with providers')
  Future<void> iPumpTheLoginScreenWithProviders() async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => AuthProvider(repository),
          child: const LoginScreen(),
        ),
      ),
    );
  }

  @When('I enter {string} in the email field')
  Future<void> iEnterInTheEmailField(String text) async {
    await tester.enterText(find.widgetWithText(TextField, 'Email'), text);
  }

  @When('I enter {string} in the password field')
  Future<void> iEnterInThePasswordField(String text) async {
    await tester.enterText(find.widgetWithText(TextField, 'Password'), text);
  }

  @When('I tap the login button')
  Future<void> iTapTheLoginButton() async {
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();
  }

  @When('I tap the logout button')
  Future<void> iTapTheLogoutButton() async {
    await tester.tap(find.widgetWithText(ElevatedButton, 'Logout'));
    await tester.pumpAndSettle();
  }

  @Then('I should see {string}')
  Future<void> iShouldSee(String text) async {
    expect(find.textContaining(text), findsWidgets);
  }
}
