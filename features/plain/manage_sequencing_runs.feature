Feature: Manage sequencing_runs
  In order to keep track of sequencing_runs
  A sequencing_run mechanic
  Should be able to manage several sequencing_runs
  
  Scenario: Register new sequencing_run
    And I am on the new sequencing_run page
    When I select "Flow cell name" from "sequencing_run_flow_cell_id"
    And I select "Super sequencer (GAII)" from "sequencing_run_instrument_id"
    And I fill in "sequencing_run_comment" with "Some clever comment about the flow cell"
    And I press "Create"
    Then I should see "Flow cell name"
    And I should see "Super sequencer"
    And I should see "Some clever comment about the flow cell"

  Scenario Outline: Delete sequencing_run
    And there are <initial> sequencing_runs
    When I delete the first sequencing_run
    Then there should be <after> sequencing_runs left
    
  Examples:
    | initial | after |
    | 4       | 3     |
    | 100     | 99    |
    | 1       | 0     |
