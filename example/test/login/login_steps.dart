import 'package:example/src/auth_provider.dart';
import 'package:example/src/auth_repository.dart';
import 'package:example/src/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'login.bdd_steps.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

/// The steps of the feature "Login".
class LoginSteps implements LoginStepsContract {
  @override
  late WidgetTester tester;

  late MockAuthRepository repository;

  @override
  Future<void> iHaveAMockAuthRepository() async {
    repository = MockAuthRepository();
  }

  @override
  Future<void> theMockReturnsASuccessfulLoginFor(String text) async {
    when(() => repository.login(text, any())).thenAnswer((_) async => User(name: 'Test User', email: text));
  }

  @override
  Future<void> theMockThrowsAnErrorForLogin() async {
    when(() => repository.login(any(), any())).thenThrow(Exception('Invalid credentials'));
  }

  @override
  Future<void> theMockAllowsLogout() async {
    when(() => repository.logout()).thenAnswer((_) async {});
  }

  @override
  Future<void> iPumpTheLoginScreenWithProviders() async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(create: (_) => AuthProvider(repository), child: const LoginScreen()),
      ),
    );
  }

  @override
  Future<void> iEnterInTheEmailField(String text) async {
    await tester.enterText(find.widgetWithText(TextField, 'Email'), text);
  }

  @override
  Future<void> iEnterInThePasswordField(String text) async {
    await tester.enterText(find.widgetWithText(TextField, 'Password'), text);
  }

  @override
  Future<void> iTapTheLoginButton() async {
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();
  }

  @override
  Future<void> iTapTheLogoutButton() async {
    await tester.tap(find.widgetWithText(ElevatedButton, 'Logout'));
    await tester.pumpAndSettle();
  }

  @override
  Future<void> iShouldSee(String text) async {
    expect(find.textContaining(text), findsWidgets);
  }
}
