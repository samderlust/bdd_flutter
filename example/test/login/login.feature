Feature: Login

  Scenario: Successful login
    Given I have a mock auth repository
    And the mock returns a successful login for "test@test.com"
    When I pump the login screen with providers
    And I enter "test@test.com" in the email field
    And I enter "password" in the password field
    And I tap the login button
    Then I should see "Welcome, Test User!"

  Scenario: Failed login shows error
    Given I have a mock auth repository
    And the mock throws an error for login
    When I pump the login screen with providers
    And I enter "wrong@test.com" in the email field
    And I enter "wrong" in the password field
    And I tap the login button
    Then I should see "Invalid credentials"

  Scenario: Logout after login
    Given I have a mock auth repository
    And the mock returns a successful login for "test@test.com"
    And the mock allows logout
    When I pump the login screen with providers
    And I enter "test@test.com" in the email field
    And I enter "password" in the password field
    And I tap the login button
    Then I should see "Welcome, Test User!"
    When I tap the logout button
    Then I should see "Login"
