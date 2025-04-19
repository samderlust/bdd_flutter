Feature: Counter
  Background: I have a counter with value 0
    Given I have a counter with value 0
    
  Scenario: Increment
    When I increment the counter by <value>
    Then the counter should have value <expected_value>
    Examples:
      | value | expected_value |
      | 1     | 1              |
      | 2     | 2              |
      | 3     | 3              |