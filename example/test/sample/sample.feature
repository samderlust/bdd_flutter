Feature: Sample
  Scenario: Sample
    Given I have a sample feature
    When I run the sample feature
    Then I should see the sample feature

  @className("CounterCustomName")
  Scenario: Counter
    Given I have a counter
    When I increment the counter
    Then I should see the counter incremented

  @unitTest
  Scenario: Counter with examples
    Given I have a counter
    When I increment the <counter>
    Then I should see the counter incremented
    Examples:
      | counter |
      | 1       |
      | 2       |
      | 3       |
  
  @unitTest
  Scenario: Counter with parameters
    Given I have a counter
    When I increment the counter <counter>
    Then I should see the result <result>
    Examples:
      | counter | result |
      | 1       | 2      |
      | 2       | 3      |
      | 3       | 4      |
