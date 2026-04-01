import 'package:flutter_test/flutter_test.dart';
import 'login.bdd_scenarios.dart';

void main() {
  group('Login', () {
    testWidgets('Successful login', (tester) async {
      final scenario = SuccessfulLoginScenario();
      //Scenario: Successful login
      // Given I have a mock auth repository
      await scenario.iHaveAMockAuthRepository(tester);
      // And the mock returns a successful login for "test@test.com"
      await scenario.theMockReturnsASuccessfulLoginForTestTestCom(tester);
      // When I pump the login screen with providers
      await scenario.iPumpTheLoginScreenWithProviders(tester);
      // And I enter "test@test.com" in the email field
      await scenario.iEnterTestTestComInTheEmailField(tester);
      // And I enter "password" in the password field
      await scenario.iEnterPasswordInThePasswordField(tester);
      // And I tap the login button
      await scenario.iTapTheLoginButton(tester);
      // Then I should see "Welcome, Test User!"
      await scenario.iShouldSeeWelcomeTestUser(tester);
    });
    testWidgets('Failed login shows error', (tester) async {
      final scenario = FailedLoginShowsErrorScenario();
      //Scenario: Failed login shows error
      // Given I have a mock auth repository
      await scenario.iHaveAMockAuthRepository(tester);
      // And the mock throws an error for login
      await scenario.theMockThrowsAnErrorForLogin(tester);
      // When I pump the login screen with providers
      await scenario.iPumpTheLoginScreenWithProviders(tester);
      // And I enter "wrong@test.com" in the email field
      await scenario.iEnterWrongTestComInTheEmailField(tester);
      // And I enter "wrong" in the password field
      await scenario.iEnterWrongInThePasswordField(tester);
      // And I tap the login button
      await scenario.iTapTheLoginButton(tester);
      // Then I should see "Invalid credentials"
      await scenario.iShouldSeeInvalidCredentials(tester);
    });
    testWidgets('Logout after login', (tester) async {
      final scenario = LogoutAfterLoginScenario();
      //Scenario: Logout after login
      // Given I have a mock auth repository
      await scenario.iHaveAMockAuthRepository(tester);
      // And the mock returns a successful login for "test@test.com"
      await scenario.theMockReturnsASuccessfulLoginForTestTestCom(tester);
      // And the mock allows logout
      await scenario.theMockAllowsLogout(tester);
      // When I pump the login screen with providers
      await scenario.iPumpTheLoginScreenWithProviders(tester);
      // And I enter "test@test.com" in the email field
      await scenario.iEnterTestTestComInTheEmailField(tester);
      // And I enter "password" in the password field
      await scenario.iEnterPasswordInThePasswordField(tester);
      // And I tap the login button
      await scenario.iTapTheLoginButton(tester);
      // Then I should see "Welcome, Test User!"
      await scenario.iShouldSeeWelcomeTestUser(tester);
      // When I tap the logout button
      await scenario.iTapTheLogoutButton(tester);
      // Then I should see "Login"
      await scenario.iShouldSeeLogin(tester);
    });
  });
}
