@api
Feature: Drush driver
  In order to show functionality added by the Drush driver

  Scenario: Drush alias
    Given I am logged in as a user with the "authenticated user" role
    When I click "My account"
    Then I should see the heading "Member for"
