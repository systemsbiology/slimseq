Feature: Generate Gerald config files
  In order to be able to run Gerald
  A user with staff access
  Should be able to create a Gerald config file
  
  Scenario: Make a Gerald config file using the default settings
    Given I am on the new gerald_configurations page
    And I press "Create"
    Then I should see "ANALYSIS eland_extended"
    And I should see "SEQUENCE_FORMAT --fasta"
    And I should see "ELAND_MULTIPLE_INSTANCES 8"
    And I should see the following parameters:
      | lane  | genome | seed_length | max_matches | use_bases |
      | 1     | mm9.fa | 25          | 5           | all       |
