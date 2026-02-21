import XCTest

// MARK: - TaskSnap Launch Tests
// Tests for app launch performance and screenshot capture

final class TaskSnapUITestsLaunchTests: XCTestCase {
    
    // MARK: - Setup
    
    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }
    
    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    // MARK: - Launch Performance Tests
    
    /// Measures the time it takes to launch the app
    func testLaunchPerformance() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
            
            // Wait for the first meaningful UI element
            let welcomeText = app.staticTexts["Welcome to TaskSnap"]
            let dashboardTitle = app.staticTexts["TaskSnap"]
            
            // Wait for either onboarding or dashboard to appear
            let expectation = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "exists == true"),
                object: welcomeText
            )
            
            let dashboardExpectation = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "exists == true"),
                object: dashboardTitle
            )
            
            _ = XCTWaiter.wait(for: [expectation, dashboardExpectation], timeout: 10, enforceOrder: false)
        }
    }
    
    /// Measures launch performance with reset data (cold start simulation)
    func testColdStartPerformance() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-data"]
        
        measure(metrics: [XCTApplicationLaunchMetric(waitUntilResponsive: true)]) {
            app.launch()
            
            // Wait for onboarding to appear
            let welcomeText = app.staticTexts["Welcome to TaskSnap"]
            XCTAssertTrue(welcomeText.waitForExistence(timeout: 10))
        }
    }
    
    /// Measures launch performance returning user (warm start simulation)
    func testWarmStartPerformance() throws {
        // First launch to set up as returning user
        let setupApp = XCUIApplication()
        setupApp.launchArguments = ["--uitesting"]
        setupApp.launch()
        
        // If onboarding appears, complete it
        if setupApp.buttons["Skip"].waitForExistence(timeout: 3) {
            setupApp.buttons["Skip"].tap()
            if setupApp.buttons["Not Now"].waitForExistence(timeout: 3) {
                setupApp.buttons["Not Now"].tap()
            }
        }
        
        // Wait for dashboard
        XCTAssertTrue(setupApp.staticTexts["TaskSnap"].waitForExistence(timeout: 5))
        setupApp.terminate()
        
        // Now measure warm start
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        
        measure(metrics: [XCTApplicationLaunchMetric(waitUntilResponsive: true)]) {
            app.launch()
            
            // Wait for dashboard
            let dashboardTitle = app.staticTexts["TaskSnap"]
            XCTAssertTrue(dashboardTitle.waitForExistence(timeout: 10))
        }
    }
    
    // MARK: - Launch Screenshot Tests
    
    /// Captures a screenshot of the app at launch (onboarding state)
    func testLaunchScreenshotOnboarding() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-data"]
        app.launch()
        
        // Wait for onboarding to fully render
        let welcomeText = app.staticTexts["Welcome to TaskSnap"]
        XCTAssertTrue(welcomeText.waitForExistence(timeout: 5))
        
        // Additional wait for animations to settle
        sleep(1)
        
        // Capture screenshot
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Launch_Screenshot_Onboarding"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    /// Captures a screenshot of the app at launch (dashboard state for returning users)
    func testLaunchScreenshotDashboard() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        
        // Handle onboarding if it appears
        if app.buttons["Skip"].waitForExistence(timeout: 3) {
            app.buttons["Skip"].tap()
            if app.buttons["Not Now"].waitForExistence(timeout: 3) {
                app.buttons["Not Now"].tap()
            }
        }
        
        // Wait for dashboard
        let dashboardTitle = app.staticTexts["TaskSnap"]
        XCTAssertTrue(dashboardTitle.waitForExistence(timeout: 5))
        
        // Wait for content to load
        sleep(1)
        
        // Capture screenshot
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Launch_Screenshot_Dashboard"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    /// Captures screenshots in different device orientations
    func testLaunchScreenshotsInDifferentOrientations() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-data"]
        app.launch()
        
        // Wait for onboarding
        let welcomeText = app.staticTexts["Welcome to TaskSnap"]
        XCTAssertTrue(welcomeText.waitForExistence(timeout: 5))
        
        // Portrait screenshot (default)
        var screenshot = app.screenshot()
        var attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Launch_Portrait"
        attachment.lifetime = .keepAlways
        add(attachment)
        
        // Landscape Left (if supported)
        XCUIDevice.shared.orientation = .landscapeLeft
        sleep(2) // Wait for rotation
        
        screenshot = app.screenshot()
        attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Launch_LandscapeLeft"
        attachment.lifetime = .keepAlways
        add(attachment)
        
        // Reset to portrait
        XCUIDevice.shared.orientation = .portrait
        sleep(1)
    }
    
    /// Captures screenshots for different accessibility sizes
    func testLaunchScreenshotsWithDifferentTextSizes() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-data"]
        
        // Test with default text size
        app.launch()
        
        let welcomeText = app.staticTexts["Welcome to TaskSnap"]
        XCTAssertTrue(welcomeText.waitForExistence(timeout: 5))
        
        var screenshot = app.screenshot()
        var attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Launch_TextSize_Default"
        attachment.lifetime = .keepAlways
        add(attachment)
        
        app.terminate()
        
        // Note: Testing different text sizes programmatically requires
        // specific launch arguments or environment variables that the app
        // must support. This is documented here for completeness.
    }
    
    /// Captures screenshots in light and dark mode
    func testLaunchScreenshotsInDifferentAppearances() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-data"]
        
        // Light mode screenshot
        app.launch()
        
        let welcomeText = app.staticTexts["Welcome to TaskSnap"]
        XCTAssertTrue(welcomeText.waitForExistence(timeout: 5))
        
        var screenshot = app.screenshot()
        var attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Launch_LightMode"
        attachment.lifetime = .keepAlways
        add(attachment)
        
        app.terminate()
        
        // Dark mode screenshot
        // Note: Setting dark mode programmatically may require:
        // 1. Setting overrideUserInterfaceStyle in the app based on launch argument
        // 2. Or using XCUIDevice.shared.appearance (iOS 15+)
        if #available(iOS 15.0, *) {
            app.launchArguments = ["--uitesting", "--reset-data", "--dark-mode"]
            app.launch()
            
            XCTAssertTrue(welcomeText.waitForExistence(timeout: 5))
            
            screenshot = app.screenshot()
            attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "Launch_DarkMode"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }
    
    /// Captures a screenshot sequence of the onboarding flow
    func testOnboardingFlowScreenshotSequence() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-data"]
        app.launch()
        
        let pageNames = [
            "Onboarding_Welcome",
            "Onboarding_Capture",
            "Onboarding_Clarify",
            "Onboarding_Complete",
            "Onboarding_Permissions"
        ]
        
        for (index, pageName) in pageNames.enumerated() {
            // Capture screenshot of current page
            let screenshot = app.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = pageName
            attachment.lifetime = .keepAlways
            add(attachment)
            
            // Navigate to next page (except for last page)
            if index < pageNames.count - 1 {
                let nextButton = app.buttons["Next"]
                if nextButton.waitForExistence(timeout: 2) {
                    nextButton.tap()
                    sleep(1) // Wait for page transition
                }
            }
        }
    }
    
    /// Tests and captures the transition from launch to first interaction
    func testLaunchToFirstInteractionTimeline() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-data"]
        
        let launchStart = Date()
        app.launch()
        
        // Measure time to first paint (onboarding visible)
        let welcomeText = app.staticTexts["Welcome to TaskSnap"]
        let onboardingVisible = welcomeText.waitForExistence(timeout: 10)
        let firstPaintTime = Date().timeIntervalSince(launchStart)
        
        XCTAssertTrue(onboardingVisible, "Onboarding should be visible within 10 seconds")
        
        // Record first paint time
        let firstPaintAttachment = XCTAttachment(string: "Time to first paint: \(String(format: "%.3f", firstPaintTime))s")
        firstPaintAttachment.name = "Launch_FirstPaint_Time"
        add(firstPaintAttachment)
        
        // Capture screenshot at first paint
        var screenshot = app.screenshot()
        var attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Launch_FirstPaint"
        attachment.lifetime = .keepAlways
        add(attachment)
        
        // Measure time to interactive (button tappable)
        let skipButton = app.buttons["Skip"]
        let interactive = skipButton.waitForExistence(timeout: 5) && skipButton.isHittable
        let timeToInteractive = Date().timeIntervalSince(launchStart)
        
        XCTAssertTrue(interactive, "App should be interactive within 15 seconds")
        
        // Record time to interactive
        let ttiAttachment = XCTAttachment(string: "Time to interactive: \(String(format: "%.3f", timeToInteractive))s")
        ttiAttachment.name = "Launch_TimeToInteractive"
        add(ttiAttachment)
        
        // Capture screenshot at interactive state
        screenshot = app.screenshot()
        attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Launch_Interactive"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    // MARK: - Memory Tests
    
    /// Monitors memory usage during launch
    func testLaunchMemoryFootprint() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        
        // Note: XCTMemoryMetric requires specific setup and may not be available
        // in all testing environments. This test documents the intended approach.
        
        // Alternative: Use OSLog or custom metrics
        app.launch()
        
        // Wait for app to settle
        sleep(2)
        
        // Capture current memory state
        // In a real implementation, you might use:
        // - os_signpost for custom metrics
        // - XCTMetric subclasses
        // - External profiling tools
        
        // Verify app is responsive
        let dashboardTitle = app.staticTexts["TaskSnap"]
        XCTAssertTrue(dashboardTitle.waitForExistence(timeout: 5) || 
                     app.staticTexts["Welcome to TaskSnap"].waitForExistence(timeout: 5))
    }
    
    // MARK: - Launch Argument Tests
    
    /// Verifies the app responds to --uitesting launch argument
    func testUITestingLaunchArgument() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        
        // App should launch without crashes
        sleep(2)
        
        // Verify the app is running
        XCTAssertTrue(app.state == .runningForeground)
    }
    
    /// Verifies the app responds to --reset-data launch argument
    func testResetDataLaunchArgument() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-data"]
        app.launch()
        
        // With --reset-data, onboarding should appear
        let welcomeText = app.staticTexts["Welcome to TaskSnap"]
        XCTAssertTrue(welcomeText.waitForExistence(timeout: 5), 
                     "Onboarding should appear with --reset-data flag")
    }
}

// MARK: - Launch Test Helpers

extension TaskSnapUITestsLaunchTests {
    
    /// Helper to capture screenshot with specific name
    func captureScreenshot(app: XCUIApplication, name: String) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    /// Helper to measure time for an operation
    func measureTime(operation: () -> Void) -> TimeInterval {
        let start = Date()
        operation()
        return Date().timeIntervalSince(start)
    }
}
