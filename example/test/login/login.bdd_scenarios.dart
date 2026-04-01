import 'package:example/src/auth_provider.dart';
import 'package:example/src/auth_repository.dart';
import 'package:example/src/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class SuccessfulLoginScenario {
  late MockAuthRepository mockAuthRepo;
  late AuthProvider authProvider;

  Future<void> iHaveAMockAuthRepository(WidgetTester tester) async {
    mockAuthRepo = MockAuthRepository();
    authProvider = AuthProvider(mockAuthRepo);
  }

  Future<void> theMockReturnsASuccessfulLoginForTestTestCom(WidgetTester tester) async {
    when(
      () => mockAuthRepo.login('test@test.com', 'password'),
    ).thenAnswer((_) async => User(name: 'Test User', email: 'test@test.com'));
  }

  Future<void> iPumpTheLoginScreenWithProviders(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider, child: const MaterialApp(home: LoginScreen())),
    );
  }

  Future<void> iEnterTestTestComInTheEmailField(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).first, 'test@test.com');
  }

  Future<void> iEnterPasswordInThePasswordField(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).last, 'password');
  }

  Future<void> iTapTheLoginButton(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();
  }

  Future<void> iShouldSeeWelcomeTestUser(WidgetTester tester) async {
    expect(find.text('Welcome, Test User!'), findsOneWidget);
  }
}

class FailedLoginShowsErrorScenario {
  late MockAuthRepository mockAuthRepo;
  late AuthProvider authProvider;

  Future<void> iHaveAMockAuthRepository(WidgetTester tester) async {
    mockAuthRepo = MockAuthRepository();
    authProvider = AuthProvider(mockAuthRepo);
  }

  Future<void> theMockThrowsAnErrorForLogin(WidgetTester tester) async {
    when(() => mockAuthRepo.login(any(), any())).thenThrow(Exception('Invalid credentials'));
  }

  Future<void> iPumpTheLoginScreenWithProviders(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider, child: const MaterialApp(home: LoginScreen())),
    );
  }

  Future<void> iEnterWrongTestComInTheEmailField(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).first, 'wrong@test.com');
  }

  Future<void> iEnterWrongInThePasswordField(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).last, 'wrong');
  }

  Future<void> iTapTheLoginButton(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();
  }

  Future<void> iShouldSeeInvalidCredentials(WidgetTester tester) async {
    expect(find.textContaining('Invalid credentials'), findsOneWidget);
  }
}

class LogoutAfterLoginScenario {
  late MockAuthRepository mockAuthRepo;
  late AuthProvider authProvider;

  Future<void> iHaveAMockAuthRepository(WidgetTester tester) async {
    mockAuthRepo = MockAuthRepository();
    authProvider = AuthProvider(mockAuthRepo);
  }

  Future<void> theMockReturnsASuccessfulLoginForTestTestCom(WidgetTester tester) async {
    when(
      () => mockAuthRepo.login('test@test.com', 'password'),
    ).thenAnswer((_) async => User(name: 'Test User', email: 'test@test.com'));
  }

  Future<void> theMockAllowsLogout(WidgetTester tester) async {
    when(() => mockAuthRepo.logout()).thenAnswer((_) async {});
  }

  Future<void> iPumpTheLoginScreenWithProviders(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider, child: const MaterialApp(home: LoginScreen())),
    );
  }

  Future<void> iEnterTestTestComInTheEmailField(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).first, 'test@test.com');
  }

  Future<void> iEnterPasswordInThePasswordField(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).last, 'password');
  }

  Future<void> iTapTheLoginButton(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();
  }

  Future<void> iShouldSeeWelcomeTestUser(WidgetTester tester) async {
    expect(find.text('Welcome, Test User!'), findsOneWidget);
  }

  Future<void> iTapTheLogoutButton(WidgetTester tester) async {
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();
  }

  Future<void> iShouldSeeLogin(WidgetTester tester) async {
    expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
  }
}
