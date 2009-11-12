Feature: Browse samples
  As a customer
  I want to browse samples
  So that I can find samples of interest

  Scenario: Browsing by project and submitter
    Given I am logged in as a customer
    And I am on the samples page
    
    When I choose to browse by project and submitter

    Then I should see a hierarchical listing of samples by project and submitter

