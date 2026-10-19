# Stress test: unusual but valid Gherkin.
@smoke @widgetTest
Feature: Order processing
  Orders move from cart to delivery.
  This description spans two lines.

  Background: Logged-in user
    Given I am logged in as "admin"
    And the time is 09:00

  @unitTest @fast
  Scenario: Doc string and data table steps
    Given the following products:
      | name  | price |
      | apple | 1.5   |
    When I post the JSON:
      """json
      { "item": "apple", "qty": 2 }
      """
    Then the response status is 201

  @unitTest
  Scenario Outline: Placeholders inside doc strings and tables
    When I send the payload:
      """
      {"item": "<item>", "note": "it's $<price>"}
      """
    Then the table shows:
      | item   | price   |
      | <item> | <price> |

    Examples:
      | item  | price |
      | apple | 1.50  |
      | pear  | 2.00  |

  Scenario Outline: Same placeholder twice and <placeholder> in name
    When I move <qty> from "<from>" to "<to>" and back to "<from>"
    Then the stock of "<from>" is <left>
    And the snake_case <first_value> works

    @eu
    Examples: Europe
      | from   | to     | qty | left | first_value |
      | Berlin | Paris  | 1   | 9    | a           |
    @us
    Examples: USA
      | to     | from    | left | qty | first_value |
      | Austin | Seattle | 8    | 2   | b           |

  Scenario: Steps with symbols: 100% & (parens) / slashes
    Given a price of $10.00
    When I apply a 15% discount
    Then the price is $8.50
    * nothing else happens
    But no email is sent

  Rule: Cancellations
    Background:
      Given an order exists

    Scenario: Cancel before shipping
      When I cancel the order
      Then the order is "cancelled"

    Scenario: Cancel after shipping
      When the order has shipped
      And I cancel the order
      Then I see "Too late"

  Rule: Refunds

    @unitTest
    Scenario: 2 refunds in one day
      Given 2 refunds today
      Then the 3rd refund is blocked
