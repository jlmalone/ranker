//
//  RankerUITestsLaunchTests.swift
//  RankerUITests
//
//  Created by Joseph Malone on 4/2/24.
//

import XCTest

final class RankerUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        if ProcessInfo.processInfo.environment["SIMULATOR_ONLY"] != nil {
            // Proceed with test setup
        } else {
            fatalError("Tests should only be run on the simulator.")
        }
        continueAfterFailure = false
    }

    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
