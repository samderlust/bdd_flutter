Feature: Calculator

  Scenario: Add two numbers
    Given I have the number 1
    And I have the number 2
    When I add them together
    Then the result should be 3 

  @className("Subtract")
  Scenario: Subtract two numbers
    Given I have the number 5
    And I have the number 3
    When I subtract them
    Then the result should be 2

  Scenario: Multiply two numbers
    Given I have the number 2
    And I have the number 3
    When I multiply them
    Then the result should be 6
    
  Scenario: Divide two numbers
    Given I have the number <number1>
    And I have the number <number2>
    When I divide them
    Then the result should be <result>

    Examples:
      | number1 | number2 | result |
      | 10      | 2       | 5      |
      | 10      | 1       | 10     |
      | 10      | 10      | 1      |

    
    
    
