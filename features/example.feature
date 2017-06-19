@api
Feature: Drush driver
  In order to show functionality added by the Drush driver

  Scenario: Drush alias
    Given I am logged in as a user with the "authenticated user" role
    When I click "My account"
    Then I should see the heading "Member for"

  Scenario: Create and view a node with fields
    Given I am viewing an "Article" content:
    | title | My article with fields! |
    | body  | A placeholder           |
    Then I should see the heading "My article with fields!"
    And I should see the text "A placeholder"
