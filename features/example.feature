@api
Feature: Drush driver
  In order to show functionality added by the Drush driver

  Scenario: Drush alias
    Given I am logged in as a user with the "authenticated user" role
    When I click "My account"
    Then I should see the heading "Member for"

  Scenario: Create a node
    Given I am logged in as a user with the "administrator" role
    When I am viewing an "article" content with the title "My article"
    Then I should see the heading "My article"
