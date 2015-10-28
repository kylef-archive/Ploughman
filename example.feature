Feature: An array

    Scenario: Appending to an array
        Given I have an empty array
         When I add 1 to the array
         Then I should have 1 item in the array

    Scenario: Filtering an array
        Given I have an array with the numbers 1 though 5
         When I filter the array for even numbers
         Then I should have 2 items in the array
