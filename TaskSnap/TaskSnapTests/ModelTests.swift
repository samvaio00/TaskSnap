import XCTest
@testable import TaskSnap

// MARK: - TaskStatus Tests

class TaskStatusTests: XCTestCase {
    
    func testAllCasesExist() {
        let allCases = TaskStatus.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.todo))
        XCTAssertTrue(allCases.contains(.doing))
        XCTAssertTrue(allCases.contains(.done))
    }
    
    func testDisplayNames() {
        XCTAssertEqual(TaskStatus.todo.displayName, "To Do")
        XCTAssertEqual(TaskStatus.doing.displayName, "Doing")
        XCTAssertEqual(TaskStatus.done.displayName, "Done")
    }
    
    func testColorProperties() {
        XCTAssertEqual(TaskStatus.todo.color, "todoColor")
        XCTAssertEqual(TaskStatus.doing.color, "doingColor")
        XCTAssertEqual(TaskStatus.done.color, "doneColor")
    }
    
    func testRawValueRoundtrip() {
        // Test that raw values can be used to reconstruct the enum
        for status in TaskStatus.allCases {
            let rawValue = status.rawValue
            let reconstructed = TaskStatus(rawValue: rawValue)
            XCTAssertEqual(status, reconstructed)
        }
    }
    
    func testRawValues() {
        XCTAssertEqual(TaskStatus.todo.rawValue, "todo")
        XCTAssertEqual(TaskStatus.doing.rawValue, "doing")
        XCTAssertEqual(TaskStatus.done.rawValue, "done")
    }
}

// MARK: - TaskCategory Tests

class TaskCategoryTests: XCTestCase {
    
    func testAllCasesExist() {
        let allCases = TaskCategory.allCases
        XCTAssertEqual(allCases.count, 7)
        XCTAssertTrue(allCases.contains(.clean))
        XCTAssertTrue(allCases.contains(.fix))
        XCTAssertTrue(allCases.contains(.buy))
        XCTAssertTrue(allCases.contains(.work))
        XCTAssertTrue(allCases.contains(.organize))
        XCTAssertTrue(allCases.contains(.health))
        XCTAssertTrue(allCases.contains(.other))
    }
    
    func testDisplayNames() {
        XCTAssertEqual(TaskCategory.clean.displayName, "Clean")
        XCTAssertEqual(TaskCategory.fix.displayName, "Fix")
        XCTAssertEqual(TaskCategory.buy.displayName, "Buy")
        XCTAssertEqual(TaskCategory.work.displayName, "Work")
        XCTAssertEqual(TaskCategory.organize.displayName, "Organize")
        XCTAssertEqual(TaskCategory.health.displayName, "Health")
        XCTAssertEqual(TaskCategory.other.displayName, "Other")
    }
    
    func testIcons() {
        XCTAssertEqual(TaskCategory.clean.icon, "sparkles")
        XCTAssertEqual(TaskCategory.fix.icon, "wrench.fill")
        XCTAssertEqual(TaskCategory.buy.icon, "cart.fill")
        XCTAssertEqual(TaskCategory.work.icon, "briefcase.fill")
        XCTAssertEqual(TaskCategory.organize.icon, "folder.fill")
        XCTAssertEqual(TaskCategory.health.icon, "heart.fill")
        XCTAssertEqual(TaskCategory.other.icon, "tag.fill")
    }
    
    func testColorProperties() {
        XCTAssertEqual(TaskCategory.clean.color, "categoryClean")
        XCTAssertEqual(TaskCategory.fix.color, "categoryFix")
        XCTAssertEqual(TaskCategory.buy.color, "categoryBuy")
        XCTAssertEqual(TaskCategory.work.color, "categoryWork")
        XCTAssertEqual(TaskCategory.organize.color, "categoryOrganize")
        XCTAssertEqual(TaskCategory.health.color, "categoryHealth")
        XCTAssertEqual(TaskCategory.other.color, "categoryOther")
    }
    
    func testRawValueRoundtrip() {
        for category in TaskCategory.allCases {
            let rawValue = category.rawValue
            let reconstructed = TaskCategory(rawValue: rawValue)
            XCTAssertEqual(category, reconstructed)
        }
    }
}

// MARK: - UrgencyLevel Tests

class UrgencyLevelTests: XCTestCase {
    
    func testAllCases() {
        // Test all cases can be instantiated
        let none: UrgencyLevel = .none
        let low: UrgencyLevel = .low
        let medium: UrgencyLevel = .medium
        let high: UrgencyLevel = .high
        
        XCTAssertNotNil(none)
        XCTAssertNotNil(low)
        XCTAssertNotNil(medium)
        XCTAssertNotNil(high)
    }
    
    func testColorProperties() {
        XCTAssertEqual(UrgencyLevel.none.color, "")
        XCTAssertEqual(UrgencyLevel.low.color, "urgencyLow")
        XCTAssertEqual(UrgencyLevel.medium.color, "urgencyMedium")
        XCTAssertEqual(UrgencyLevel.high.color, "urgencyHigh")
    }
    
    func testShouldGlowProperty() {
        // shouldGlow should be true for medium and high
        XCTAssertFalse(UrgencyLevel.none.shouldGlow)
        XCTAssertFalse(UrgencyLevel.low.shouldGlow)
        XCTAssertTrue(UrgencyLevel.medium.shouldGlow)
        XCTAssertTrue(UrgencyLevel.high.shouldGlow)
    }
}

// MARK: - StreakManager Tests

@MainActor
class StreakManagerTests: XCTestCase {
    
    var streakManager: StreakManager!
    var mockUserDefaults: UserDefaults!
    
    override func setUp() {
        super.setUp()
        // Create a mock UserDefaults suite for testing
        mockUserDefaults = UserDefaults(suiteName: "test.streak.manager")!
        mockUserDefaults.removePersistentDomain(forName: "test.streak.manager")
        
        // Initialize a fresh StreakManager
        streakManager = StreakManager()
        
        // Reset the manager's state
        streakManager.currentStreak = 0
        streakManager.longestStreak = 0
        streakManager.lastCompletionDate = nil
        streakManager.plantGrowthStage = 0
    }
    
    override func tearDown() {
        // Clean up mock UserDefaults
        mockUserDefaults.removePersistentDomain(forName: "test.streak.manager")
        mockUserDefaults = nil
        streakManager = nil
        super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertEqual(streakManager.currentStreak, 0)
        XCTAssertEqual(streakManager.longestStreak, 0)
        XCTAssertNil(streakManager.lastCompletionDate)
        XCTAssertEqual(streakManager.plantGrowthStage, 0)
    }
    
    func testRecordTaskCompletion_IncrementsStreak() {
        // Record first completion
        streakManager.recordTaskCompletion()
        
        XCTAssertEqual(streakManager.currentStreak, 1)
        XCTAssertEqual(streakManager.longestStreak, 1)
        XCTAssertNotNil(streakManager.lastCompletionDate)
        XCTAssertEqual(streakManager.plantGrowthStage, 1)
    }
    
    func testRecordTaskCompletion_ConsecutiveDays() {
        // Simulate yesterday's completion
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        
        streakManager.lastCompletionDate = yesterday
        streakManager.currentStreak = 3
        streakManager.longestStreak = 3
        
        // Record today's completion
        streakManager.recordTaskCompletion()
        
        XCTAssertEqual(streakManager.currentStreak, 4)
        XCTAssertEqual(streakManager.longestStreak, 4)
        XCTAssertEqual(streakManager.plantGrowthStage, 4)
    }
    
    func testRecordTaskCompletion_SameDay() {
        // Simulate today's completion
        streakManager.lastCompletionDate = Date()
        streakManager.currentStreak = 3
        streakManager.longestStreak = 5
        
        // Record another completion today
        streakManager.recordTaskCompletion()
        
        // Streak should not change
        XCTAssertEqual(streakManager.currentStreak, 3)
        XCTAssertEqual(streakManager.longestStreak, 5)
    }
    
    func testRecordTaskCompletion_StreakResetAfterMissedDay() {
        // Simulate completion from 2 days ago
        let calendar = Calendar.current
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: Date())!
        
        streakManager.lastCompletionDate = twoDaysAgo
        streakManager.currentStreak = 5
        streakManager.longestStreak = 10
        
        // Record completion today
        streakManager.recordTaskCompletion()
        
        // Streak should reset to 1
        XCTAssertEqual(streakManager.currentStreak, 1)
        // Longest streak should remain unchanged
        XCTAssertEqual(streakManager.longestStreak, 10)
        XCTAssertEqual(streakManager.plantGrowthStage, 1)
    }
    
    func testCheckAndResetStreakIfNeeded() {
        // Simulate completion from 2 days ago
        let calendar = Calendar.current
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: Date())!
        
        streakManager.lastCompletionDate = twoDaysAgo
        streakManager.currentStreak = 5
        
        streakManager.checkAndResetStreakIfNeeded()
        
        XCTAssertEqual(streakManager.currentStreak, 0)
        XCTAssertEqual(streakManager.plantGrowthStage, 0)
    }
    
    func testCheckAndResetStreakIfNeeded_NoResetForConsecutiveDay() {
        // Simulate yesterday's completion
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        
        streakManager.lastCompletionDate = yesterday
        streakManager.currentStreak = 5
        
        streakManager.checkAndResetStreakIfNeeded()
        
        // Streak should not be reset
        XCTAssertEqual(streakManager.currentStreak, 5)
    }
    
    func testPlantImageName_WhenStreakIsZero() {
        streakManager.currentStreak = 0
        XCTAssertEqual(streakManager.plantImageName, "plant_wilted")
    }
    
    func testPlantImageName_WhenStreakIsActive() {
        streakManager.currentStreak = 5
        XCTAssertEqual(streakManager.plantImageName, "plant_stage_5")
    }
    
    func testPlantGrowthStageCapsAt10() {
        streakManager.currentStreak = 15
        streakManager.updatePlantGrowthStage()
        XCTAssertEqual(streakManager.plantGrowthStage, 10)
    }
    
    func testPlantDescription_Stage0() {
        streakManager.plantGrowthStage = 0
        XCTAssertEqual(streakManager.plantDescription, "Your plant needs care. Complete a task to help it grow!")
    }
    
    func testPlantDescription_Stage1to3() {
        streakManager.plantGrowthStage = 2
        XCTAssertEqual(streakManager.plantDescription, "Your sprout is growing! Keep going!")
    }
    
    func testPlantDescription_Stage4to6() {
        streakManager.plantGrowthStage = 5
        XCTAssertEqual(streakManager.plantDescription, "Your plant is thriving! Great work!")
    }
    
    func testPlantDescription_Stage7to9() {
        streakManager.plantGrowthStage = 8
        XCTAssertEqual(streakManager.plantDescription, "Your plant is flourishing! You're amazing!")
    }
    
    func testPlantDescription_Stage10() {
        streakManager.plantGrowthStage = 10
        XCTAssertEqual(streakManager.plantDescription, "Your plant is fully grown! You're a TaskSnap master!")
    }
    
    func testIsStreakAtRisk_WhenYesterdayCompleted() {
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        
        streakManager.lastCompletionDate = yesterday
        streakManager.currentStreak = 3
        
        XCTAssertTrue(streakManager.isStreakAtRisk)
    }
    
    func testIsStreakAtRisk_WhenTodayCompleted() {
        streakManager.lastCompletionDate = Date()
        streakManager.currentStreak = 3
        
        XCTAssertFalse(streakManager.isStreakAtRisk)
    }
    
    func testIsStreakAtRisk_WhenNoStreak() {
        streakManager.lastCompletionDate = nil
        streakManager.currentStreak = 0
        
        XCTAssertFalse(streakManager.isStreakAtRisk)
    }
    
    func testUserDefaultsPersistence() {
        // Record a completion to trigger save
        streakManager.recordTaskCompletion()
        
        // Create a new instance to test loading from UserDefaults
        let newManager = StreakManager()
        
        // The new manager should load the saved data
        XCTAssertEqual(newManager.currentStreak, 1)
        XCTAssertEqual(newManager.longestStreak, 1)
        XCTAssertNotNil(newManager.lastCompletionDate)
    }
}

// MARK: - TaskLimitManager Tests

class TaskLimitManagerTests: XCTestCase {
    
    var taskLimitManager: TaskLimitManager!
    
    override func setUp() {
        super.setUp()
        taskLimitManager = TaskLimitManager.shared
    }
    
    override func tearDown() {
        taskLimitManager = nil
        super.tearDown()
    }
    
    func testFreeTierLimit() {
        XCTAssertEqual(taskLimitManager.freeTierLimit, 15)
    }
    
    func testCanCreateTask_UnderLimit() {
        // Should be able to create task when under the limit
        XCTAssertTrue(taskLimitManager.canCreateTask(currentTaskCount: 0))
        XCTAssertTrue(taskLimitManager.canCreateTask(currentTaskCount: 5))
        XCTAssertTrue(taskLimitManager.canCreateTask(currentTaskCount: 14))
    }
    
    func testCanCreateTask_AtLimit() {
        // Should not be able to create task when at the limit
        XCTAssertFalse(taskLimitManager.canCreateTask(currentTaskCount: 15))
    }
    
    func testCanCreateTask_OverLimit() {
        // Should not be able to create task when over the limit
        XCTAssertFalse(taskLimitManager.canCreateTask(currentTaskCount: 16))
        XCTAssertFalse(taskLimitManager.canCreateTask(currentTaskCount: 20))
    }
    
    func testRemainingTasks() {
        XCTAssertEqual(taskLimitManager.remainingTasks(currentTaskCount: 0), 15)
        XCTAssertEqual(taskLimitManager.remainingTasks(currentTaskCount: 5), 10)
        XCTAssertEqual(taskLimitManager.remainingTasks(currentTaskCount: 14), 1)
        XCTAssertEqual(taskLimitManager.remainingTasks(currentTaskCount: 15), 0)
        XCTAssertEqual(taskLimitManager.remainingTasks(currentTaskCount: 16), 0)
    }
    
    func testLimitMessage() {
        XCTAssertEqual(taskLimitManager.limitMessage, "Free tier: 15 tasks max")
    }
    
    func testIsProUser() {
        // For MVP, should always return false
        XCTAssertFalse(taskLimitManager.isProUser)
    }
}
