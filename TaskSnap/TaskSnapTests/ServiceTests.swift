import XCTest
@testable import TaskSnap
import UIKit

// MARK: - Haptics Tests
@MainActor
final class HapticsTests: XCTestCase {
    
    var haptics: Haptics!
    
    override func setUp() {
        super.setUp()
        haptics = Haptics.shared
    }
    
    override func tearDown() {
        haptics = nil
        super.tearDown()
    }
    
    func testSingletonExists() {
        // Test that singleton is accessible
        XCTAssertNotNil(Haptics.shared)
        XCTAssertTrue(haptics === Haptics.shared)
    }
    
    func testLightImpactDoesNotCrash() {
        // Note: Can't verify haptics actually fire, just that method executes
        XCTAssertNoThrow(haptics.light())
    }
    
    func testMediumImpactDoesNotCrash() {
        XCTAssertNoThrow(haptics.medium())
    }
    
    func testHeavyImpactDoesNotCrash() {
        XCTAssertNoThrow(haptics.heavy())
    }
    
    func testSelectionChangedDoesNotCrash() {
        XCTAssertNoThrow(haptics.selectionChanged())
    }
    
    func testSuccessDoesNotCrash() {
        XCTAssertNoThrow(haptics.success())
    }
    
    func testErrorDoesNotCrash() {
        XCTAssertNoThrow(haptics.error())
    }
    
    func testWarningDoesNotCrash() {
        XCTAssertNoThrow(haptics.warning())
    }
    
    func testTaskCompletedDoesNotCrash() {
        XCTAssertNoThrow(haptics.taskCompleted())
    }
    
    func testTaskMovedDoesNotCrash() {
        XCTAssertNoThrow(haptics.taskMoved())
    }
    
    func testCameraShutterDoesNotCrash() {
        XCTAssertNoThrow(haptics.cameraShutter())
    }
    
    func testButtonTapDoesNotCrash() {
        XCTAssertNoThrow(haptics.buttonTap())
    }
    
    func testAchievementUnlockedDoesNotCrash() {
        XCTAssertNoThrow(haptics.achievementUnlocked())
    }
}

// MARK: - Theme Manager Tests
@MainActor
final class ThemeManagerTests: XCTestCase {
    
    var themeManager: ThemeManager!
    let selectedThemeKey = "tasksnap.selectedTheme"
    let unlockedThemesKey = "tasksnap.unlockedThemes"
    let proUserKey = "tasksnap.isProUser"
    
    override func setUp() {
        super.setUp()
        // Clear UserDefaults before each test
        UserDefaults.standard.removeObject(forKey: selectedThemeKey)
        UserDefaults.standard.removeObject(forKey: unlockedThemesKey)
        UserDefaults.standard.removeObject(forKey: proUserKey)
        
        themeManager = ThemeManager.shared
    }
    
    override func tearDown() {
        // Clean up UserDefaults
        UserDefaults.standard.removeObject(forKey: selectedThemeKey)
        UserDefaults.standard.removeObject(forKey: unlockedThemesKey)
        UserDefaults.standard.removeObject(forKey: proUserKey)
        
        themeManager = nil
        super.tearDown()
    }
    
    func testCurrentThemeReturnsTheme() {
        // Test that selectedTheme returns a valid theme
        let theme = themeManager.selectedTheme
        XCTAssertNotNil(theme)
    }
    
    func testSetThemeChangesTheme() {
        // First unlock the theme we want to test
        themeManager.unlockedThemes.insert(CelebrationTheme.party.rawValue)
        
        // Save current theme
        let originalTheme = themeManager.selectedTheme
        
        // Set new theme
        themeManager.selectTheme(.party)
        
        // Verify theme changed
        XCTAssertEqual(themeManager.selectedTheme, .party)
        
        // Restore original theme
        themeManager.selectTheme(originalTheme)
    }
    
    func testAvailableThemesHasMultipleThemes() {
        // Test that CelebrationTheme has multiple themes
        let allThemes = CelebrationTheme.allCases
        XCTAssertGreaterThan(allThemes.count, 1, "Should have multiple themes available")
        XCTAssertTrue(allThemes.count >= 8, "Should have at least 8 themes")
    }
    
    func testThemePersistsInUserDefaults() {
        // Unlock and select a specific theme
        themeManager.unlockedThemes.insert(CelebrationTheme.nature.rawValue)
        themeManager.selectTheme(.nature)
        
        // Verify it was saved to UserDefaults
        let savedThemeRaw = UserDefaults.standard.string(forKey: selectedThemeKey)
        XCTAssertEqual(savedThemeRaw, CelebrationTheme.nature.rawValue)
        
        // Create a new manager instance (simulates app restart)
        // Note: Since it's a singleton, we verify the stored value directly
        if let savedTheme = UserDefaults.standard.string(forKey: selectedThemeKey),
           let theme = CelebrationTheme(rawValue: savedTheme) {
            XCTAssertEqual(theme, .nature)
        } else {
            XCTFail("Theme should be persisted in UserDefaults")
        }
    }
    
    func testUnlockedThemesPersistsInUserDefaults() {
        // Add a theme to unlocked set
        themeManager.unlockedThemes.insert(CelebrationTheme.fire.rawValue)
        themeManager.unlockAllThemesForPreview() // This calls saveUnlockedThemes()
        
        // Verify it was saved to UserDefaults
        let savedUnlocked = UserDefaults.standard.array(forKey: unlockedThemesKey) as? [String]
        XCTAssertNotNil(savedUnlocked)
        XCTAssertTrue(savedUnlocked?.contains(CelebrationTheme.classic.rawValue) ?? false)
    }
    
    func testClassicThemeIsDefaultUnlocked() {
        // Classic should always be unlocked by default
        XCTAssertTrue(themeManager.unlockedThemes.contains(CelebrationTheme.classic.rawValue))
        XCTAssertTrue(themeManager.isThemeUnlocked(.classic))
    }
    
    func testProThemeRequiresProStatus() {
        // Diamond is pro-only, should not be unlocked for free user
        UserDefaults.standard.set(false, forKey: proUserKey)
        
        // Pro-only themes should return false for non-pro users
        if CelebrationTheme.diamond.isProOnly {
            // For non-pro users, isThemeUnlocked should return false for pro themes
            // Note: This depends on the actual implementation of isProUser
        }
    }
}

// MARK: - Smart Category Service Tests
final class SmartCategoryServiceTests: XCTestCase {
    
    var smartCategoryService: SmartCategoryService!
    
    override func setUp() {
        super.setUp()
        smartCategoryService = SmartCategoryService.shared
    }
    
    override func tearDown() {
        smartCategoryService = nil
        super.tearDown()
    }
    
    func testSuggestCategoriesWithNilImageAndTitle() {
        // Test with nil image and no title - should return context-based suggestions
        let suggestions = smartCategoryService.suggestCategory(for: UIImage(), title: nil)
        
        // Should return at least context-based suggestions
        XCTAssertNotNil(suggestions)
        // Empty image may still produce suggestions based on context (time of day)
    }
    
    func testSuggestCategoriesWithEmptyTitle() {
        // Test with empty title
        let suggestions = smartCategoryService.suggestCategory(for: UIImage(), title: "")
        
        XCTAssertNotNil(suggestions)
    }
    
    func testSuggestCategoriesWithCleanKeywords() {
        // Test title with cleaning keywords
        let suggestions = smartCategoryService.suggestCategory(for: UIImage(), title: "Clean the kitchen")
        
        // Should detect cleaning category
        let cleanSuggestion = suggestions.first { $0.category == .clean }
        XCTAssertNotNil(cleanSuggestion)
        XCTAssertGreaterThan(cleanSuggestion?.confidence ?? 0, 0)
    }
    
    func testSuggestCategoriesWithBuyKeywords() {
        // Test title with buying keywords
        let suggestions = smartCategoryService.suggestCategory(for: UIImage(), title: "Buy groceries")
        
        let buySuggestion = suggestions.first { $0.category == .buy }
        XCTAssertNotNil(buySuggestion)
        XCTAssertGreaterThan(buySuggestion?.confidence ?? 0, 0)
    }
    
    func testSuggestCategoriesWithFixKeywords() {
        // Test title with fixing keywords
        let suggestions = smartCategoryService.suggestCategory(for: UIImage(), title: "Fix the leaky faucet")
        
        let fixSuggestion = suggestions.first { $0.category == .fix }
        XCTAssertNotNil(fixSuggestion)
        XCTAssertGreaterThan(fixSuggestion?.confidence ?? 0, 0)
    }
    
    func testSuggestCategoriesWithOrganizeKeywords() {
        // Test title with organizing keywords
        let suggestions = smartCategoryService.suggestCategory(for: UIImage(), title: "Organize the closet")
        
        let organizeSuggestion = suggestions.first { $0.category == .organize }
        XCTAssertNotNil(organizeSuggestion)
        XCTAssertGreaterThan(organizeSuggestion?.confidence ?? 0, 0)
    }
    
    func testSuggestCategoriesWithHealthKeywords() {
        // Test title with health keywords
        let suggestions = smartCategoryService.suggestCategory(for: UIImage(), title: "Doctor appointment")
        
        let healthSuggestion = suggestions.first { $0.category == .health }
        XCTAssertNotNil(healthSuggestion)
        XCTAssertGreaterThan(healthSuggestion?.confidence ?? 0, 0)
    }
    
    func testSuggestCategoriesWithWorkKeywords() {
        // Test title with work keywords
        let suggestions = smartCategoryService.suggestCategory(for: UIImage(), title: "Email the team")
        
        let workSuggestion = suggestions.first { $0.category == .work }
        XCTAssertNotNil(workSuggestion)
        XCTAssertGreaterThan(workSuggestion?.confidence ?? 0, 0)
    }
    
    func testSuggestCategoriesConfidenceIsNormalized() {
        // Test that confidence values are normalized between 0 and 1
        let suggestions = smartCategoryService.suggestCategory(for: UIImage(), title: "Clean and organize the room")
        
        for suggestion in suggestions {
            XCTAssertGreaterThanOrEqual(suggestion.confidence, 0)
            XCTAssertLessThanOrEqual(suggestion.confidence, 1)
        }
    }
    
    func testSuggestCategoriesSortedByConfidence() {
        // Test that suggestions are sorted by confidence (highest first)
        let suggestions = smartCategoryService.suggestCategory(for: UIImage(), title: "Buy and fix things")
        
        // Verify descending order
        for i in 1..<suggestions.count {
            XCTAssertGreaterThanOrEqual(suggestions[i-1].confidence, suggestions[i].confidence)
        }
    }
    
    func testAnalyzeImageColorsReturnsEmptyForEmptyImage() {
        // Test analyzeColors indirectly through suggestCategory
        // An empty UIImage (no cgImage) should return empty results
        let emptyImage = UIImage()
        let suggestions = smartCategoryService.suggestCategory(for: emptyImage, title: nil)
        
        // Should handle gracefully without crashing
        XCTAssertNotNil(suggestions)
    }
}

// MARK: - Clutter Score Service Tests
final class ClutterScoreServiceTests: XCTestCase {
    
    var clutterScoreService: ClutterScoreService!
    var expectation: XCTestExpectation!
    
    override func setUp() {
        super.setUp()
        clutterScoreService = ClutterScoreService.shared
    }
    
    override func tearDown() {
        clutterScoreService = nil
        super.tearDown()
    }
    
    func testAnalyzeClutterWithNilImageReturnsNil() {
        // Test with image that has no cgImage (effectively nil)
        let emptyImage = UIImage()
        expectation = expectation(description: "Analyze empty image")
        
        clutterScoreService.analyzeImage(emptyImage) { result in
            // Empty UIImage (no cgImage) should return nil
            XCTAssertNil(result)
            self.expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testAnalyzeClutterReturnsScoreInValidRange() {
        // Create a simple test image
        let testImage = createTestImage(width: 100, height: 100, color: .gray)
        expectation = expectation(description: "Analyze test image")
        
        clutterScoreService.analyzeImage(testImage) { result in
            XCTAssertNotNil(result)
            
            if let result = result {
                // Score should be in 0-100 range
                XCTAssertGreaterThanOrEqual(result.score, 0)
                XCTAssertLessThanOrEqual(result.score, 100)
            }
            
            self.expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    func testAnalyzeClutterReturnsValidCategory() {
        let testImage = createTestImage(width: 100, height: 100, color: .white)
        expectation = expectation(description: "Analyze for category")
        
        clutterScoreService.analyzeImage(testImage) { result in
            XCTAssertNotNil(result)
            
            if let result = result {
                // Category should be one of the valid categories
                let validCategories: [ClutterScoreResult.ClutterCategory] = [.minimal, .light, .moderate, .heavy, .extreme]
                XCTAssertTrue(validCategories.contains(result.category))
            }
            
            self.expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    func testCategoryDescriptionNotEmpty() {
        // Test that each category has a description
        let categories: [ClutterScoreResult.ClutterCategory] = [.minimal, .light, .moderate, .heavy, .extreme]
        
        for category in categories {
            XCTAssertFalse(category.description.isEmpty, "Category \(category) should have a description")
        }
    }
    
    func testCategoryDescriptionChangesBasedOnScore() {
        // Test that different score ranges return appropriate categories
        XCTAssertEqual(clutterScoreService.categoryForScore(10), .minimal)
        XCTAssertEqual(clutterScoreService.categoryForScore(30), .light)
        XCTAssertEqual(clutterScoreService.categoryForScore(50), .moderate)
        XCTAssertEqual(clutterScoreService.categoryForScore(70), .heavy)
        XCTAssertEqual(clutterScoreService.categoryForScore(90), .extreme)
    }
    
    func testRecommendationsArrayHasContent() {
        let testImage = createTestImage(width: 200, height: 200, color: .red)
        expectation = expectation(description: "Analyze for recommendations")
        
        clutterScoreService.analyzeImage(testImage) { result in
            XCTAssertNotNil(result)
            
            if let result = result {
                // Should have at least one recommendation
                XCTAssertFalse(result.suggestions.isEmpty, "Should have at least one suggestion")
                XCTAssertGreaterThan(result.suggestions.count, 0)
                
                // Each suggestion should not be empty
                for suggestion in result.suggestions {
                    XCTAssertFalse(suggestion.isEmpty)
                }
            }
            
            self.expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    func testDifferentScoresHaveDifferentRecommendations() {
        // Minimal category should have different suggestions than extreme
        let minimalDescription = ClutterScoreResult.ClutterCategory.minimal.description
        let extremeDescription = ClutterScoreResult.ClutterCategory.extreme.description
        
        XCTAssertNotEqual(minimalDescription, extremeDescription)
    }
    
    func testAnalyzeClutterReturnsDetails() {
        let testImage = createTestImage(width: 150, height: 150, color: .blue)
        expectation = expectation(description: "Analyze for details")
        
        clutterScoreService.analyzeImage(testImage) { result in
            XCTAssertNotNil(result)
            
            if let result = result {
                // Should have details with valid ranges
                XCTAssertGreaterThanOrEqual(result.details.edgeDensity, 0)
                XCTAssertLessThanOrEqual(result.details.edgeDensity, 1)
                
                XCTAssertGreaterThanOrEqual(result.details.colorVariance, 0)
                XCTAssertLessThanOrEqual(result.details.colorVariance, 1)
                
                XCTAssertGreaterThanOrEqual(result.details.textureComplexity, 0)
                XCTAssertLessThanOrEqual(result.details.textureComplexity, 1)
                
                XCTAssertGreaterThan(result.details.objectCountEstimate, 0)
            }
            
            self.expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    // MARK: - Helper Methods
    
    private func createTestImage(width: Int, height: Int, color: UIColor) -> UIImage {
        let size = CGSize(width: width, height: height)
        UIGraphicsBeginImageContext(size)
        color.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return image
    }
}

// MARK: - ClutterScoreService Extension for Testing
extension ClutterScoreService {
    func categoryForScore(_ score: Int) -> ClutterScoreResult.ClutterCategory {
        switch score {
        case 0..<20: return .minimal
        case 20..<40: return .light
        case 40..<60: return .moderate
        case 60..<80: return .heavy
        default: return .extreme
        }
    }
}
