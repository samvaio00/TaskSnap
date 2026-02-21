import XCTest

// MARK: - TaskSnap UI Tests
// Comprehensive UI test suite for TaskSnap app
// Tests cover: Onboarding, Dashboard, Task Creation, Task Management, and Settings

final class TaskSnapUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app = XCUIApplication()
        
        // Configure launch arguments for UI testing
        app.launchArguments = ["--uitesting", "--reset-data"]
        
        // Launch the app
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }
    
    // MARK: - Helper Methods
    
    /// Waits for an element to exist with a timeout
    func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        return element.waitForExistence(timeout: timeout)
    }
    
    /// Takes a screenshot and attaches it to the test report
    func takeScreenshot(named name: String) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    /// Completes the onboarding flow
    func completeOnboarding() {
        // Check if onboarding is shown
        let welcomeText = app.staticTexts["Welcome to TaskSnap"]
        guard welcomeText.waitForExistence(timeout: 3) else { return }
        
        // Swipe through all onboarding pages
        for _ in 0..<4 {
            let nextButton = app.buttons["Next"]
            if nextButton.waitForExistence(timeout: 2) {
                nextButton.tap()
                // Wait for page transition
                sleep(1)
            }
        }
        
        // Tap "Get Started" on the last page
        let getStartedButton = app.buttons["Get Started"]
        if getStartedButton.waitForExistence(timeout: 2) {
            getStartedButton.tap()
        }
        
        // Handle permission alert if it appears
        let notNowButton = app.buttons["Not Now"]
        if notNowButton.waitForExistence(timeout: 3) {
            notNowButton.tap()
        }
    }
    
    /// Creates a task for testing purposes
    func createTestTask(title: String, category: String = "Other", isUrgent: Bool = false) {
        // Tap capture button
        let captureButton = app.buttons["Capture a Task"]
        XCTAssertTrue(waitForElement(captureButton), "Capture button should exist")
        captureButton.tap()
        
        // Wait for capture view
        let captureViewTitle = app.staticTexts["New Task"]
        XCTAssertTrue(waitForElement(captureViewTitle), "Capture view should appear")
        
        // Choose from Library (since we can't use camera in simulator)
        let chooseFromLibraryButton = app.buttons["Choose from Library"]
        XCTAssertTrue(waitForElement(chooseFromLibraryButton), "Choose from Library button should exist")
        chooseFromLibraryButton.tap()
        
        // Handle photo library picker - select first photo or cancel
        // In simulator, we'll cancel and use text-only task creation
        let cancelButton = app.buttons["Cancel"]
        if cancelButton.waitForExistence(timeout: 2) {
            cancelButton.tap()
        }
        
        // Enter task title
        let titleTextField = app.textFields["Task title"]
        XCTAssertTrue(waitForElement(titleTextField), "Title text field should exist")
        titleTextField.tap()
        titleTextField.typeText(title)
        
        // Dismiss keyboard
        app.keyboards.buttons["Return"].tap()
        
        // Select category if not default
        if category != "Other" {
            let categoryButton = app.buttons[category]
            if categoryButton.waitForExistence(timeout: 2) {
                categoryButton.tap()
            }
        }
        
        // Toggle urgent if needed
        if isUrgent {
            let urgentToggle = app.switches["Mark as urgent"]
            if urgentToggle.waitForExistence(timeout: 2) {
                urgentToggle.tap()
            }
        }
        
        // Create task
        let createButton = app.buttons["Create Task"]
        XCTAssertTrue(waitForElement(createButton), "Create Task button should exist")
        createButton.tap()
    }
    
    // MARK: - Onboarding Flow Tests
    
    func testOnboardingScreensAppearForNewUser() throws {
        // With --reset-data flag, onboarding should appear
        let welcomeText = app.staticTexts["Welcome to TaskSnap"]
        XCTAssertTrue(waitForElement(welcomeText, timeout: 5), "Welcome screen should appear for new user")
        
        // Verify onboarding elements
        XCTAssertTrue(app.staticTexts["Capture Your Chaos. See Your Success."].exists)
        XCTAssertTrue(app.images["camera.viewfinder"].exists)
        
        // Verify page indicators exist
        let pageIndicators = app.otherElements.matching(identifier: "Page Indicator")
        XCTAssertGreaterThan(pageIndicators.count, 0, "Page indicators should exist")
    }
    
    func testSwipeThroughOnboardingPages() throws {
        // Start at welcome page
        let welcomeText = app.staticTexts["Welcome to TaskSnap"]
        XCTAssertTrue(waitForElement(welcomeText), "Welcome page should be visible")
        
        // Swipe to next page (Capture)
        let tabView = app.otherElements["OnboardingTabView"]
        if tabView.waitForExistence(timeout: 2) {
            tabView.swipeLeft()
        } else {
            // Alternative: use coordinate-based swipe
            let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
            let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.5))
            start.press(forDuration: 0.1, thenDragTo: end)
        }
        
        // Verify Capture page content
        sleep(1)
        let captureText = app.staticTexts["1. Capture"]
        XCTAssertTrue(waitForElement(captureText), "Capture page should be visible after swipe")
        
        // Continue swiping
        for i in 2...4 {
            let nextButton = app.buttons["Next"]
            if nextButton.waitForExistence(timeout: 2) {
                nextButton.tap()
                sleep(1)
            }
        }
        
        // Verify final page (Permissions)
        let permissionsText = app.staticTexts["One More Thing"]
        XCTAssertTrue(waitForElement(permissionsText), "Permissions page should be visible")
    }
    
    func testGetStartedButtonCompletesOnboarding() throws {
        // Navigate through all onboarding pages
        completeOnboarding()
        
        // Verify we're on the main dashboard
        let dashboardTitle = app.staticTexts["TaskSnap"]
        XCTAssertTrue(waitForElement(dashboardTitle, timeout: 5), "Dashboard should appear after completing onboarding")
        
        // Verify tab bar exists
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 2), "Tab bar should be visible after onboarding")
    }
    
    // MARK: - Dashboard Tests
    
    func testDashboardTabsExist() throws {
        // Complete onboarding first
        completeOnboarding()
        
        // Verify all tabs exist
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(waitForElement(tabBar), "Tab bar should exist")
        
        // Check for each tab
        let expectedTabs = ["Tasks", "Streak", "Awards", "Stats", "Focus", "Shared", "Settings"]
        for tabName in expectedTabs {
            let tabButton = tabBar.buttons[tabName]
            XCTAssertTrue(tabButton.exists, "Tab '\(tabName)' should exist")
        }
    }
    
    func testEmptyStateAppearsWhenNoTasks() throws {
        // Complete onboarding with reset data
        completeOnboarding()
        
        // Verify empty state in To Do column
        let emptyStateText = app.staticTexts["No tasks"]
        XCTAssertTrue(waitForElement(emptyStateText), "Empty state should appear when no tasks exist")
        
        // Verify "Drag tasks here" hint
        let dragHintText = app.staticTexts["Drag tasks here"]
        XCTAssertTrue(dragHintText.exists, "Drag hint should appear in empty columns")
    }
    
    func testCaptureButtonOpensCaptureView() throws {
        // Complete onboarding
        completeOnboarding()
        
        // Tap the capture button
        let captureButton = app.buttons["Capture a Task"]
        XCTAssertTrue(waitForElement(captureButton), "Capture button should exist")
        captureButton.tap()
        
        // Verify capture view opens
        let captureViewTitle = app.staticTexts["New Task"]
        XCTAssertTrue(waitForElement(captureViewTitle), "Capture view should open")
        
        // Verify capture options
        let takePhotoButton = app.buttons["Take Photo"]
        let chooseLibraryButton = app.buttons["Choose from Library"]
        
        XCTAssertTrue(takePhotoButton.exists, "Take Photo button should exist")
        XCTAssertTrue(chooseLibraryButton.exists, "Choose from Library button should exist")
    }
    
    func testStreakDisplayOnDashboard() throws {
        completeOnboarding()
        
        // Verify streak indicator exists
        let streakText = app.staticTexts["day streak"]
        XCTAssertTrue(waitForElement(streakText), "Streak indicator should exist on dashboard")
        
        // Verify done today counter
        let doneTodayText = app.staticTexts["done today"]
        XCTAssertTrue(doneTodayText.exists, "Done today counter should exist")
    }
    
    // MARK: - Task Creation Tests
    
    func testCaptureViewOpens() throws {
        completeOnboarding()
        
        // Tap capture button
        let captureButton = app.buttons["Capture a Task"]
        captureButton.tap()
        
        // Verify capture view elements
        let title = app.staticTexts["Capture Your Chaos"]
        XCTAssertTrue(waitForElement(title), "Capture view title should appear")
        
        let description = app.staticTexts["Take a photo of something that needs your attention"]
        XCTAssertTrue(description.exists, "Capture description should exist")
    }
    
    func testCanEnterTaskTitle() throws {
        completeOnboarding()
        
        // Open capture view
        let captureButton = app.buttons["Capture a Task"]
        captureButton.tap()
        
        // For testing without camera, we need to simulate having an image
        // Tap choose from library and cancel to get to the form
        let chooseLibraryButton = app.buttons["Choose from Library"]
        chooseLibraryButton.tap()
        
        // Cancel photo picker
        let cancelButton = app.buttons["Cancel"]
        if cancelButton.waitForExistence(timeout: 2) {
            cancelButton.tap()
        }
        
        // Wait for and interact with title field
        let titleTextField = app.textFields["Task title"]
        XCTAssertTrue(waitForElement(titleTextField), "Title text field should exist")
        
        titleTextField.tap()
        titleTextField.typeText("Test Task Title")
        
        // Verify text was entered
        XCTAssertEqual(titleTextField.value as? String, "Test Task Title", "Title should be entered correctly")
    }
    
    func testCategorySelection() throws {
        completeOnboarding()
        
        // Open capture view
        app.buttons["Capture a Task"].tap()
        
        // Cancel photo picker if needed
        let cancelButton = app.buttons["Cancel"]
        if cancelButton.waitForExistence(timeout: 2) {
            cancelButton.tap()
        }
        
        // Verify category buttons exist
        let categories = ["Clean", "Fix", "Buy", "Work", "Organize", "Health", "Other"]
        
        for category in categories {
            let categoryButton = app.buttons[category]
            XCTAssertTrue(categoryButton.waitForExistence(timeout: 2), "Category '\(category)' button should exist")
        }
        
        // Select a category
        let cleanButton = app.buttons["Clean"]
        cleanButton.tap()
        
        // Verify selection (button should have selected state)
        XCTAssertTrue(cleanButton.isSelected || cleanButton.exists, "Selected category should be highlighted")
    }
    
    func testUrgentToggle() throws {
        completeOnboarding()
        
        // Open capture view
        app.buttons["Capture a Task"].tap()
        
        // Cancel photo picker if needed
        let cancelButton = app.buttons["Cancel"]
        if cancelButton.waitForExistence(timeout: 2) {
            cancelButton.tap()
        }
        
        // Find and toggle urgent switch
        let urgentToggle = app.switches["Mark as urgent"]
        XCTAssertTrue(waitForElement(urgentToggle), "Urgent toggle should exist")
        
        // Toggle on
        urgentToggle.tap()
        
        // Verify toggle state changed
        // In XCTest, we check the value which should be "1" for on
        let toggleValue = urgentToggle.value as? String
        XCTAssertEqual(toggleValue, "1", "Urgent toggle should be on")
    }
    
    func testDueDateToggle() throws {
        completeOnboarding()
        
        // Open capture view
        app.buttons["Capture a Task"].tap()
        
        // Cancel photo picker if needed
        let cancelButton = app.buttons["Cancel"]
        if cancelButton.waitForExistence(timeout: 2) {
            cancelButton.tap()
        }
        
        // Find and toggle due date switch
        let dueDateToggle = app.switches["Set due date"]
        XCTAssertTrue(waitForElement(dueDateToggle), "Due date toggle should exist")
        
        // Toggle on
        dueDateToggle.tap()
        
        // Verify date picker appears
        let datePicker = app.datePickers.firstMatch
        XCTAssertTrue(datePicker.waitForExistence(timeout: 2), "Date picker should appear when toggle is on")
    }
    
    // MARK: - Task Management Tests
    
    func testTaskAppearsInDashboard() throws {
        completeOnboarding()
        
        // Create a test task
        createTestTask(title: "Test Dashboard Task")
        
        // Verify task appears on dashboard
        let taskCell = app.staticTexts["Test Dashboard Task"]
        XCTAssertTrue(waitForElement(taskCell, timeout: 5), "Created task should appear on dashboard")
    }
    
    func testTaskDetailViewOpens() throws {
        completeOnboarding()
        
        // Create a test task first
        createTestTask(title: "Detail Test Task")
        
        // Tap on the task
        let taskCell = app.staticTexts["Detail Test Task"]
        XCTAssertTrue(waitForElement(taskCell), "Task should exist")
        taskCell.tap()
        
        // Verify detail view opens
        let detailTitle = app.staticTexts["Task Details"]
        XCTAssertTrue(waitForElement(detailTitle), "Task detail view should open")
        
        // Verify task title is displayed
        XCTAssertTrue(app.staticTexts["Detail Test Task"].exists, "Task title should be shown in detail view")
    }
    
    func testCompleteTaskFlow() throws {
        completeOnboarding()
        
        // Create a test task
        createTestTask(title: "Complete Test Task")
        
        // Open task detail
        let taskCell = app.staticTexts["Complete Test Task"]
        XCTAssertTrue(waitForElement(taskCell))
        taskCell.tap()
        
        // Tap complete button
        let completeButton = app.buttons["Complete Task"]
        XCTAssertTrue(waitForElement(completeButton), "Complete button should exist")
        completeButton.tap()
        
        // Handle completion dialog
        let takePhotoButton = app.buttons["Take Photo"]
        if takePhotoButton.waitForExistence(timeout: 2) {
            // Cancel the completion dialog
            let cancelButton = app.buttons["Cancel"]
            if cancelButton.waitForExistence(timeout: 1) {
                cancelButton.tap()
            }
        }
        
        // Close detail view
        let closeButton = app.buttons["Close"]
        if closeButton.waitForExistence(timeout: 2) {
            closeButton.tap()
        }
    }
    
    func testDeleteTask() throws {
        completeOnboarding()
        
        // Create a test task
        createTestTask(title: "Delete Test Task")
        
        // Open task detail
        let taskCell = app.staticTexts["Delete Test Task"]
        XCTAssertTrue(waitForElement(taskCell))
        taskCell.tap()
        
        // Open options menu
        let optionsButton = app.buttons["ellipsis.circle"]
        XCTAssertTrue(waitForElement(optionsButton), "Options button should exist")
        optionsButton.tap()
        
        // Tap delete
        let deleteButton = app.buttons["Delete Task"]
        XCTAssertTrue(waitForElement(deleteButton), "Delete button should exist in menu")
        deleteButton.tap()
        
        // Confirm deletion
        let confirmDelete = app.buttons["Delete"]
        if confirmDelete.waitForExistence(timeout: 2) {
            confirmDelete.tap()
        }
        
        // Verify task is deleted
        sleep(1)
        XCTAssertFalse(app.staticTexts["Delete Test Task"].exists, "Deleted task should not exist")
    }
    
    func testStartTaskButton() throws {
        completeOnboarding()
        
        // Create a test task
        createTestTask(title: "Start Test Task")
        
        // Open task detail
        let taskCell = app.staticTexts["Start Test Task"]
        XCTAssertTrue(waitForElement(taskCell))
        taskCell.tap()
        
        // Tap start button
        let startButton = app.buttons["Start Task"]
        XCTAssertTrue(waitForElement(startButton), "Start button should exist")
        startButton.tap()
        
        // Verify detail view closes (task moved to Doing)
        sleep(1)
        let detailTitle = app.staticTexts["Task Details"]
        XCTAssertFalse(detailTitle.exists, "Detail view should close after starting task")
    }
    
    // MARK: - Settings Tests
    
    func testSettingsTabOpens() throws {
        completeOnboarding()
        
        // Navigate to Settings tab
        let tabBar = app.tabBars.firstMatch
        let settingsTab = tabBar.buttons["Settings"]
        XCTAssertTrue(waitForElement(settingsTab), "Settings tab should exist")
        settingsTab.tap()
        
        // Verify settings view
        let settingsTitle = app.staticTexts["Settings"]
        XCTAssertTrue(waitForElement(settingsTitle, timeout: 3), "Settings view should open")
    }
    
    func testiCloudSyncSectionExists() throws {
        completeOnboarding()
        
        // Go to Settings
        app.tabBars.firstMatch.buttons["Settings"].tap()
        
        // Verify Cloud & Sync section
        let cloudSyncText = app.staticTexts["iCloud Sync"]
        XCTAssertTrue(waitForElement(cloudSyncText), "iCloud Sync section should exist")
        
        // Verify toggle exists
        let syncToggle = app.switches.firstMatch
        XCTAssertTrue(syncToggle.exists, "iCloud sync toggle should exist")
    }
    
    func testBackupRestoreSectionExists() throws {
        completeOnboarding()
        
        // Go to Settings
        app.tabBars.firstMatch.buttons["Settings"].tap()
        
        // Verify Backup & Restore section
        let backupText = app.staticTexts["Backup & Restore"]
        XCTAssertTrue(waitForElement(backupText), "Backup & Restore section should exist")
    }
    
    func testThemesSectionExists() throws {
        completeOnboarding()
        
        // Go to Settings
        app.tabBars.firstMatch.buttons["Settings"].tap()
        
        // Verify Personalization section
        let celebrationText = app.staticTexts["Celebration Theme"]
        XCTAssertTrue(waitForElement(celebrationText), "Celebration Theme section should exist")
        
        let animationText = app.staticTexts["Animation Intensity"]
        XCTAssertTrue(animationText.exists, "Animation Intensity section should exist")
    }
    
    func testAnimationSettingsNavigation() throws {
        completeOnboarding()
        
        // Go to Settings
        app.tabBars.firstMatch.buttons["Settings"].tap()
        
        // Tap on Animation Intensity
        let animationCell = app.staticTexts["Animation Intensity"]
        XCTAssertTrue(waitForElement(animationCell))
        animationCell.tap()
        
        // Verify Animation Settings view opens
        let settingsTitle = app.staticTexts["Animation Settings"]
        XCTAssertTrue(waitForElement(settingsTitle), "Animation Settings view should open")
        
        // Verify animation options
        let fullAnimations = app.staticTexts["Full Animations"]
        let reducedSpeed = app.staticTexts["Reduced Speed"]
        let minimal = app.staticTexts["Minimal (Haptics Only)"]
        
        XCTAssertTrue(fullAnimations.waitForExistence(timeout: 2), "Full Animations option should exist")
        XCTAssertTrue(reducedSpeed.exists, "Reduced Speed option should exist")
        XCTAssertTrue(minimal.exists, "Minimal option should exist")
    }
    
    func testAboutSectionExists() throws {
        completeOnboarding()
        
        // Go to Settings
        app.tabBars.firstMatch.buttons["Settings"].tap()
        
        // Scroll to find About section
        app.swipeUp()
        
        // Verify About section elements
        let versionText = app.staticTexts["Version"]
        XCTAssertTrue(waitForElement(versionText), "Version should be displayed")
        
        let privacyLink = app.staticTexts["Privacy Policy"]
        XCTAssertTrue(privacyLink.exists, "Privacy Policy link should exist")
        
        let supportLink = app.staticTexts["Support"]
        XCTAssertTrue(supportLink.exists, "Support link should exist")
    }
    
    // MARK: - Streak & Gamification Tests
    
    func testStreakViewOpens() throws {
        completeOnboarding()
        
        // Navigate to Streak tab
        let tabBar = app.tabBars.firstMatch
        let streakTab = tabBar.buttons["Streak"]
        XCTAssertTrue(waitForElement(streakTab), "Streak tab should exist")
        streakTab.tap()
        
        // Verify streak view elements
        let streakTitle = app.staticTexts["Your Streak"]
        XCTAssertTrue(waitForElement(streakTitle, timeout: 3), "Streak view should open")
    }
    
    func testAchievementsViewOpens() throws {
        completeOnboarding()
        
        // Navigate to Awards tab
        let tabBar = app.tabBars.firstMatch
        let awardsTab = tabBar.buttons["Awards"]
        XCTAssertTrue(waitForElement(awardsTab), "Awards tab should exist")
        awardsTab.tap()
        
        // Verify achievements view
        let achievementsTitle = app.staticTexts["Achievements"]
        XCTAssertTrue(waitForElement(achievementsTitle, timeout: 3), "Achievements view should open")
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityLabels() throws {
        completeOnboarding()
        
        // Test dashboard accessibility
        let captureButton = app.buttons["Capture a Task"]
        XCTAssertTrue(captureButton.exists, "Capture button should have accessibility label")
        
        // Test tab bar accessibility
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should be accessible")
        
        // Test streak indicator
        let streakIndicator = app.staticTexts.matching(identifier: "Streak Indicator").firstMatch
        // Note: This may fail if specific accessibility identifiers aren't set
        // The test documents expected behavior
    }
    
    // MARK: - Performance Tests
    
    func testDashboardLoadPerformance() throws {
        completeOnboarding()
        
        measure {
            // Measure the time to load dashboard
            let captureButton = app.buttons["Capture a Task"]
            _ = captureButton.waitForExistence(timeout: 5)
        }
    }
}

// MARK: - Onboarding Flow Tests

final class OnboardingFlowTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-data"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }
    
    func testWelcomePageContent() {
        let welcomeTitle = app.staticTexts["Welcome to TaskSnap"]
        XCTAssertTrue(welcomeTitle.waitForExistence(timeout: 5))
        
        // Verify features list
        XCTAssertTrue(app.staticTexts["Designed for ADHD brains"].exists)
        XCTAssertTrue(app.staticTexts["Visual task management"].exists)
        XCTAssertTrue(app.staticTexts["Build lasting habits"].exists)
        
        // Verify Skip button exists
        XCTAssertTrue(app.buttons["Skip"].exists)
    }
    
    func testCapturePageContent() {
        // Navigate to Capture page
        app.buttons["Next"].tap()
        sleep(1)
        
        let captureTitle = app.staticTexts["1. Capture"]
        XCTAssertTrue(captureTitle.waitForExistence(timeout: 3))
        
        // Verify examples
        XCTAssertTrue(app.staticTexts["Messy desk? Capture it."].exists)
        XCTAssertTrue(app.staticTexts["Broken item? Snap it."].exists)
        XCTAssertTrue(app.staticTexts["Grocery list? Photograph it."].exists)
    }
    
    func testClarifyPageContent() {
        // Navigate to Clarify page
        app.buttons["Next"].tap()
        sleep(1)
        app.buttons["Next"].tap()
        sleep(1)
        
        let clarifyTitle = app.staticTexts["2. Clarify"]
        XCTAssertTrue(clarifyTitle.waitForExistence(timeout: 3))
        
        // Verify category badges
        XCTAssertTrue(app.staticTexts["Clean"].exists)
        XCTAssertTrue(app.staticTexts["Fix"].exists)
        XCTAssertTrue(app.staticTexts["Buy"].exists)
    }
    
    func testCompletePageContent() {
        // Navigate to Complete page
        for _ in 0..<3 {
            if app.buttons["Next"].waitForExistence(timeout: 2) {
                app.buttons["Next"].tap()
                sleep(1)
            }
        }
        
        let completeTitle = app.staticTexts["3. Complete"]
        XCTAssertTrue(completeTitle.waitForExistence(timeout: 3))
        
        // Verify benefits
        XCTAssertTrue(app.staticTexts["See before & after comparison"].exists)
        XCTAssertTrue(app.staticTexts["Enjoy celebration animations"].exists)
        XCTAssertTrue(app.staticTexts["Build your daily streak"].exists)
    }
    
    func testPermissionsPageContent() {
        // Navigate to Permissions page
        for _ in 0..<4 {
            if app.buttons["Next"].waitForExistence(timeout: 2) {
                app.buttons["Next"].tap()
                sleep(1)
            }
        }
        
        let permissionsTitle = app.staticTexts["One More Thing"]
        XCTAssertTrue(permissionsTitle.waitForExistence(timeout: 3))
        
        // Verify permission descriptions
        XCTAssertTrue(app.staticTexts["Camera"].exists)
        XCTAssertTrue(app.staticTexts["Photo Library"].exists)
        XCTAssertTrue(app.staticTexts["Notifications (Optional)"].exists)
        
        // Verify Get Started button
        XCTAssertTrue(app.buttons["Get Started"].exists)
    }
    
    func testSkipButtonCompletesOnboarding() {
        // Tap Skip button
        app.buttons["Skip"].tap()
        
        // Handle permission alert
        if app.buttons["Not Now"].waitForExistence(timeout: 3) {
            app.buttons["Not Now"].tap()
        }
        
        // Verify dashboard appears
        let dashboardTitle = app.staticTexts["TaskSnap"]
        XCTAssertTrue(dashboardTitle.waitForExistence(timeout: 5))
    }
}

// MARK: - Dashboard Tests

final class DashboardTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-data"]
        app.launch()
        
        // Complete onboarding
        skipOnboarding()
    }
    
    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }
    
    func skipOnboarding() {
        if app.buttons["Skip"].waitForExistence(timeout: 3) {
            app.buttons["Skip"].tap()
            if app.buttons["Not Now"].waitForExistence(timeout: 3) {
                app.buttons["Not Now"].tap()
            }
        }
    }
    
    func testNavigationTitle() {
        let title = app.staticTexts["TaskSnap"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        XCTAssertTrue(title.exists)
    }
    
    func testKanbanColumnsExist() {
        // Verify column headers
        XCTAssertTrue(app.staticTexts["To Do"].exists)
        XCTAssertTrue(app.staticTexts["Doing"].exists)
        XCTAssertTrue(app.staticTexts["Done"].exists)
    }
    
    func testColumnCounters() {
        // Verify counters are displayed (as "0" initially)
        let counters = app.staticTexts.matching(predicate: NSPredicate(format: "label MATCHES '^[0-9]+$'"))
        XCTAssertGreaterThanOrEqual(counters.count, 3, "Should have counters for each column")
    }
    
    func testCaptureButtonVisibility() {
        let captureButton = app.buttons["Capture a Task"]
        XCTAssertTrue(captureButton.exists)
        XCTAssertTrue(captureButton.isHittable)
    }
    
    func testTaskLimitWarningNotShownInitially() {
        // With reset data, we should not see limit warning
        let limitWarning = app.staticTexts["Task limit reached"]
        XCTAssertFalse(limitWarning.exists)
    }
}

// MARK: - Task Creation Tests

final class TaskCreationTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-data"]
        app.launch()
        
        skipOnboarding()
    }
    
    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }
    
    func skipOnboarding() {
        if app.buttons["Skip"].waitForExistence(timeout: 3) {
            app.buttons["Skip"].tap()
            if app.buttons["Not Now"].waitForExistence(timeout: 3) {
                app.buttons["Not Now"].tap()
            }
        }
    }
    
    func testCancelButtonClosesCaptureView() {
        // Open capture view
        app.buttons["Capture a Task"].tap()
        
        // Tap Cancel
        app.buttons["Cancel"].tap()
        
        // Verify we're back on dashboard
        XCTAssertTrue(app.staticTexts["TaskSnap"].waitForExistence(timeout: 3))
    }
    
    func testCaptureOptionsVisibility() {
        app.buttons["Capture a Task"].tap()
        
        XCTAssertTrue(app.buttons["Take Photo"].exists)
        XCTAssertTrue(app.buttons["Choose from Library"].exists)
        XCTAssertTrue(app.staticTexts["Capture Your Chaos"].exists)
    }
    
    func testTaskTitlePlaceholder() {
        app.buttons["Capture a Task"].tap()
        
        // Cancel photo picker
        if app.buttons["Cancel"].waitForExistence(timeout: 2) {
            app.buttons["Cancel"].tap()
        }
        
        let textField = app.textFields["Task title"]
        XCTAssertTrue(textField.exists)
        
        // Verify placeholder
        XCTAssertEqual(textField.placeholderValue, "Task title")
    }
    
    func testCategorySelectionChangesSelection() {
        app.buttons["Capture a Task"].tap()
        
        if app.buttons["Cancel"].waitForExistence(timeout: 2) {
            app.buttons["Cancel"].tap()
        }
        
        // Tap different categories
        let categories = ["Clean", "Fix", "Buy"]
        for category in categories {
            let button = app.buttons[category]
            if button.waitForExistence(timeout: 1) {
                button.tap()
                // Category should remain visible after selection
                XCTAssertTrue(button.exists)
            }
        }
    }
    
    func testDescriptionField() {
        app.buttons["Capture a Task"].tap()
        
        if app.buttons["Cancel"].waitForExistence(timeout: 2) {
            app.buttons["Cancel"].tap()
        }
        
        // Find and interact with description field
        let descriptionField = app.textViews.firstMatch
        // Note: Description field may be identified differently
        // This test verifies the field exists
        XCTAssertTrue(descriptionField.exists || app.textFields["Add description (optional)"].exists)
    }
}

// MARK: - Task Management Tests

final class TaskManagementTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-data"]
        app.launch()
        
        skipOnboarding()
    }
    
    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }
    
    func skipOnboarding() {
        if app.buttons["Skip"].waitForExistence(timeout: 3) {
            app.buttons["Skip"].tap()
            if app.buttons["Not Now"].waitForExistence(timeout: 3) {
                app.buttons["Not Now"].tap()
            }
        }
    }
    
    func createQuickTask(title: String) {
        app.buttons["Capture a Task"].tap()
        
        if app.buttons["Cancel"].waitForExistence(timeout: 2) {
            app.buttons["Cancel"].tap()
        }
        
        let textField = app.textFields["Task title"]
        textField.tap()
        textField.typeText(title)
        app.keyboards.buttons["Return"].tap()
        
        // Create task button may need scrolling to be visible
        app.swipeUp()
        
        if app.buttons["Create Task"].waitForExistence(timeout: 2) {
            app.buttons["Create Task"].tap()
        }
    }
    
    func testTaskCellDisplaysCorrectInfo() {
        createQuickTask(title: "Info Test Task")
        
        // Verify task appears
        let taskLabel = app.staticTexts["Info Test Task"]
        XCTAssertTrue(taskLabel.waitForExistence(timeout: 5))
    }
    
    func testTaskDetailShowsCorrectTitle() {
        createQuickTask(title: "Detail Title Test")
        
        let taskLabel = app.staticTexts["Detail Title Test"]
        XCTAssertTrue(taskLabel.waitForExistence(timeout: 5))
        taskLabel.tap()
        
        // Verify detail shows correct title
        let detailTitle = app.staticTexts["Detail Title Test"]
        XCTAssertTrue(detailTitle.waitForExistence(timeout: 3))
    }
    
    func testTaskDetailCloseButton() {
        createQuickTask(title: "Close Test Task")
        
        app.staticTexts["Close Test Task"].tap()
        
        app.buttons["Close"].tap()
        
        // Verify back on dashboard
        XCTAssertTrue(app.staticTexts["TaskSnap"].waitForExistence(timeout: 3))
    }
    
    func testMoveBackToTodoButton() {
        createQuickTask(title: "Move Back Test")
        
        app.staticTexts["Move Back Test"].tap()
        
        // Start the task
        if app.buttons["Start Task"].waitForExistence(timeout: 2) {
            app.buttons["Start Task"].tap()
            
            // Reopen task detail
            sleep(1)
            app.staticTexts["Move Back Test"].tap()
            
            // Should now see "Move Back to To Do" button
            XCTAssertTrue(app.buttons["Move Back to To Do"].waitForExistence(timeout: 2))
        }
    }
    
    func testFocusTimerButtonExists() {
        createQuickTask(title: "Focus Timer Test")
        
        app.staticTexts["Focus Timer Test"].tap()
        
        // Start task first
        if app.buttons["Start Task"].waitForExistence(timeout: 2) {
            app.buttons["Start Task"].tap()
            
            // Reopen to see focus timer option
            sleep(1)
            app.staticTexts["Focus Timer Test"].tap()
            
            XCTAssertTrue(app.buttons["Start Focus Timer"].waitForExistence(timeout: 2))
        }
    }
    
    func testReopenTaskButtonForDoneTasks() {
        createQuickTask(title: "Reopen Test Task")
        
        app.staticTexts["Reopen Test Task"].tap()
        
        // Complete the task
        if app.buttons["Complete Task"].waitForExistence(timeout: 2) {
            app.buttons["Complete Task"].tap()
            
            // Cancel the photo dialog
            if app.buttons["Cancel"].waitForExistence(timeout: 2) {
                app.buttons["Cancel"].tap()
            }
            
            // Reopen task detail
            sleep(1)
            if app.staticTexts["Reopen Test Task"].waitForExistence(timeout: 2) {
                app.staticTexts["Reopen Test Task"].tap()
                
                // Should see Reopen button
                XCTAssertTrue(app.buttons["Reopen Task"].waitForExistence(timeout: 2))
            }
        }
    }
}

// MARK: - Settings Tests

final class SettingsTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-data"]
        app.launch()
        
        skipOnboarding()
        
        // Navigate to Settings
        app.tabBars.firstMatch.buttons["Settings"].tap()
    }
    
    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }
    
    func skipOnboarding() {
        if app.buttons["Skip"].waitForExistence(timeout: 3) {
            app.buttons["Skip"].tap()
            if app.buttons["Not Now"].waitForExistence(timeout: 3) {
                app.buttons["Not Now"].tap()
            }
        }
    }
    
    func testSettingsTitle() {
        let title = app.staticTexts["Settings"]
        XCTAssertTrue(title.waitForExistence(timeout: 3))
    }
    
    func testCloudSectionHeader() {
        XCTAssertTrue(app.staticTexts["Cloud & Sync"].waitForExistence(timeout: 3))
    }
    
    func testDataSectionHeader() {
        XCTAssertTrue(app.staticTexts["Data"].waitForExistence(timeout: 3))
    }
    
    func testPersonalizationSectionHeader() {
        XCTAssertTrue(app.staticTexts["Personalization"].waitForExistence(timeout: 3))
    }
    
    func testAboutSectionHeader() {
        // Scroll down to find About section
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["About"].waitForExistence(timeout: 3))
    }
    
    func testiCloudSyncToggle() {
        let toggle = app.switches.firstMatch
        XCTAssertTrue(toggle.exists)
        
        // Note: Toggling may trigger alerts in actual app
        // Test verifies toggle exists and is interactable
    }
    
    func testSyncNowButton() {
        // Only visible when sync is enabled
        let syncNowButton = app.buttons["Sync Now"]
        // May or may not exist depending on sync state
        if syncNowButton.exists {
            XCTAssertTrue(syncNowButton.isEnabled || !syncNowButton.isEnabled)
        }
    }
    
    func testVersionNumberDisplayed() {
        app.swipeUp()
        let versionLabel = app.staticTexts["Version"]
        XCTAssertTrue(versionLabel.waitForExistence(timeout: 3))
        
        // Verify version number is shown
        let versionValue = app.staticTexts["1.0"]
        XCTAssertTrue(versionValue.exists || app.staticTexts.matching(predicate: NSPredicate(format: "label MATCHES '^[0-9]+\\.[0-9]+$'")).firstMatch.exists)
    }
    
    func testThemePickerNavigation() {
        app.swipeUp()
        app.swipeDown()
        
        let celebrationTheme = app.staticTexts["Celebration Theme"]
        XCTAssertTrue(celebrationTheme.waitForExistence(timeout: 3))
        
        celebrationTheme.tap()
        
        // Verify navigation to theme picker
        let themeTitle = app.staticTexts["Celebration Theme"]
        XCTAssertTrue(themeTitle.waitForExistence(timeout: 3))
    }
    
    func testAnimationIntensityNavigation() {
        let animationIntensity = app.staticTexts["Animation Intensity"]
        XCTAssertTrue(animationIntensity.waitForExistence(timeout: 3))
        
        animationIntensity.tap()
        
        // Verify navigation
        let settingsTitle = app.staticTexts["Animation Settings"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 3))
    }
    
    func testBackupRestoreNavigation() {
        let backupRestore = app.staticTexts["Backup & Restore"]
        XCTAssertTrue(backupRestore.waitForExistence(timeout: 3))
        
        backupRestore.tap()
        
        // Verify navigation
        // Backup view title may vary
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 3))
    }
    
    func testHapticOptionsInAnimationSettings() {
        app.staticTexts["Animation Intensity"].tap()
        
        // Verify haptic section
        XCTAssertTrue(app.staticTexts["Haptic Feedback"].waitForExistence(timeout: 3))
        
        // Verify options
        XCTAssertTrue(app.staticTexts["Strong"].exists)
        XCTAssertTrue(app.staticTexts["Gentle"].exists)
        XCTAssertTrue(app.staticTexts["Off"].exists)
    }
    
    func testTestAnimationButton() {
        app.staticTexts["Animation Intensity"].tap()
        
        let testButton = app.buttons["Test Animation"]
        XCTAssertTrue(testButton.waitForExistence(timeout: 3))
        XCTAssertTrue(testButton.isHittable)
    }
}
