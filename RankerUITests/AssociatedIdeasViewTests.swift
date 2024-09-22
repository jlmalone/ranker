import Foundation

import XCTest

class AssociatedIdeasViewTests: XCTestCase {

    let app = XCUIApplication()

    func testAssociatedIdeasFlow() {

        if ProcessInfo.processInfo.environment["SIMULATOR_ONLY"] != nil {
            // Proceed with test setup
        } else {
            fatalError("Tests should only be run on the simulator.")
        }
        app.launch()

        // Navigate to the first word's associated ideas
        let firstWord = app.staticTexts.element(boundBy: 0)
        firstWord.tap()

        // Enter text into the associated ideas text field
        let textField = app.textFields["Enter associated word"]
        textField.tap()
        textField.typeText("An associated idea")

        // Start and stop recording
        let recordButton = app.buttons["Record"]
        recordButton.tap()
        sleep(2)  // Simulate 2 seconds of recording
        let stopButton = app.buttons["Stop"]
        stopButton.tap()

        // Verify that the transcript appears
        let transcriptText = app.staticTexts["This is a sample transcript of the recorded audio."]
        XCTAssertTrue(transcriptText.waitForExistence(timeout: 5))

        // Save and exit
        let doneButton = app.buttons["Done"]
        doneButton.tap()
    }
}
