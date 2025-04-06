@enableReporter
Feature: Counter
  Scenario: Increment
    Given I have a counter with value 0
    When I increment the counter by <value>
    Then the counter should have value <expected_value>
    Examples:
      | value | expected_value |
      | 1     | 1              |
      | 2     | 2              |
      | 3     | 3              |