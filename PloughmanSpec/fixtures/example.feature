Feature: Showing build output in simple format

    Scenario: Showing file compilation
        Given I have a file to compile
        When I pipe to xcpretty with "--simple --no-color"
        Then I should see a successful compilation message

    Scenario: Showing xib compilation
        Given I have a xib to compile
        When I pipe to xcpretty with "--simple --no-color"
        Then I should see a successful compilation message
