#!/usr/bin/env python3
"""
Fix TaskSnap.xcodeproj by adding new files properly
"""

import re
import uuid

def generate_uuid():
    """Generate a UUID in Xcode format (24 hex chars uppercase)"""
    return uuid.uuid4().hex[:24].upper()

def add_file_to_project(filepath, file_type, group_path):
    """
    Add a file to the Xcode project
    filepath: path relative to project root (e.g., "TaskSnap/Views/LaunchScreen.swift")
    file_type: PBX file type (e.g., "sourcecode.swift")
    group_path: Group path (e.g., ["TaskSnap", "Views"])
    """
    print(f"Would add: {filepath}")
    print(f"  Type: {file_type}")
    print(f"  Group: {'/'.join(group_path)}")
    print()

# New files to add
new_files = [
    # Views
    ("TaskSnap/Views/LaunchScreen.swift", "sourcecode.swift", ["TaskSnap", "Views"]),
    ("TaskSnap/Views/AnimationView.swift", "sourcecode.swift", ["TaskSnap", "Views"]),
    ("TaskSnap/Views/AnimationSettingsView.swift", "sourcecode.swift", ["TaskSnap", "Views"]),
    ("TaskSnap/Views/PatternInsightsView.swift", "sourcecode.swift", ["TaskSnap", "Views"]),
    ("TaskSnap/Views/SpaceDetailView.swift", "sourcecode.swift", ["TaskSnap", "Views"]),
    ("TaskSnap/Views/SharedSpacesListView.swift", "sourcecode.swift", ["TaskSnap", "Views"]),
    ("TaskSnap/Views/BackupRestoreView.swift", "sourcecode.swift", ["TaskSnap", "Views"]),
    ("TaskSnap/Views/ClutterScoreView.swift", "sourcecode.swift", ["TaskSnap", "Views"]),
    ("TaskSnap/Views/AnalyticsView.swift", "sourcecode.swift", ["TaskSnap", "Views"]),
    ("TaskSnap/Views/BodyDoublingRoomView.swift", "sourcecode.swift", ["TaskSnap", "Views"]),
    ("TaskSnap/Views/ThemePickerView.swift", "sourcecode.swift", ["TaskSnap", "Views"]),
    ("TaskSnap/Views/LoadingView.swift", "sourcecode.swift", ["TaskSnap", "Views"]),
    ("TaskSnap/Views/ErrorStateView.swift", "sourcecode.swift", ["TaskSnap", "Views"]),
    
    # Services
    ("TaskSnap/Services/SoundEffectManager.swift", "sourcecode.swift", ["TaskSnap", "Services"]),
    ("TaskSnap/Services/FocusSoundManager.swift", "sourcecode.swift", ["TaskSnap", "Services"]),
    ("TaskSnap/Services/PatternRecognitionService.swift", "sourcecode.swift", ["TaskSnap", "Services"]),
    ("TaskSnap/Services/ShareManager.swift", "sourcecode.swift", ["TaskSnap", "Services"]),
    ("TaskSnap/Services/TaskSuggestionService.swift", "sourcecode.swift", ["TaskSnap", "Services"]),
    ("TaskSnap/Services/BackupService.swift", "sourcecode.swift", ["TaskSnap", "Services"]),
    ("TaskSnap/Services/SmartCategoryService.swift", "sourcecode.swift", ["TaskSnap", "Services"]),
    ("TaskSnap/Services/ClutterScoreService.swift", "sourcecode.swift", ["TaskSnap", "Services"]),
    ("TaskSnap/Services/BodyDoublingManager.swift", "sourcecode.swift", ["TaskSnap", "Services"]),
    ("TaskSnap/Services/ThemeManager.swift", "sourcecode.swift", ["TaskSnap", "Services"]),
    ("TaskSnap/Services/NotificationManager.swift", "sourcecode.swift", ["TaskSnap", "Services"]),
    ("TaskSnap/Services/SyncManager.swift", "sourcecode.swift", ["TaskSnap", "Services"]),
    
    # Utils
    ("TaskSnap/Utils/PressableButton.swift", "sourcecode.swift", ["TaskSnap", "Utils"]),
    ("TaskSnap/Utils/AnimatedToggle.swift", "sourcecode.swift", ["TaskSnap", "Utils"]),
    ("TaskSnap/Utils/AccessibilitySettings.swift", "sourcecode.swift", ["TaskSnap", "Utils"]),
    ("TaskSnap/Utils/DynamicTypeModifier.swift", "sourcecode.swift", ["TaskSnap", "Utils"]),
    ("TaskSnap/Utils/HighContrastColors.swift", "sourcecode.swift", ["TaskSnap", "Utils"]),
    
    # ViewModels
    ("TaskSnap/ViewModels/AnalyticsViewModel.swift", "sourcecode.swift", ["TaskSnap", "ViewModels"]),
    
    # Models
    ("TaskSnap/Models/FocusSession.swift", "sourcecode.swift", ["TaskSnap", "Models"]),
    ("TaskSnap/Models/CelebrationTheme.swift", "sourcecode.swift", ["TaskSnap", "Models"]),
]

print("Files that need to be added to Xcode project:")
print("=" * 60)
for filepath, file_type, group_path in new_files:
    add_file_to_project(filepath, file_type, group_path)

print("\n" + "=" * 60)
print("\nIMPORTANT: Xcode project files should be modified by Xcode,")
print("not manually edited. Options:")
print()
print("1. EASIEST: Open Xcode and drag files into the project")
print("   - Open TaskSnap.xcodeproj in Xcode")
print("   - Drag new files into appropriate groups")
print()
print("2. Use xcodeproj gem (if installed):")
print("   gem install xcodeproj")
print("   ruby -rxcodeproj -e '...'")
print()
print("3. Regenerate project with tuist/xcodegen")
print()
print("Recommended: Use Option 1 (drag in Xcode)")
