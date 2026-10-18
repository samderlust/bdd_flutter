# Shows the Gherkin syntax supported through cucumber_gherkin:
# comments, several tags on one line, Rule with its own Background,
# Scenario Outline with several Examples blocks, But and * steps.
@unitTest @cart
Feature: Shopping cart
  Background: An empty cart
    Given an empty cart

  Scenario: Add and remove items
    When I add 2 "apple" at 1.5 each
    * I add 1 "pear" at 2 each
    But I remove "apple"
    Then the cart has 1 item
    And the total is 2

  Scenario Outline: Total for several items
    When I add <quantity> "<item>" at <price> each
    Then the total for "<item>" is <total>

    Examples: Small orders
      | item  | quantity | price | total |
      | apple | 1        | 1.5   | 1.5   |
      | pear  | 2        | 2     | 4     |

    Examples: Bulk orders
      | item   | quantity | price | total |
      | banana | 100      | 0.25  | 25    |

  Rule: A closed cart cannot change
    Background:
      Given the cart is closed

    Scenario: Adding to a closed cart
      When I add 1 "apple" at 1.5 each
      Then I see the error "Cart is closed"
      And the cart has 0 item
