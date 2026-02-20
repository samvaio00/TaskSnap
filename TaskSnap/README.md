# TaskSnap - Visual Task Management for the ADHD Brain

**TaskSnap** is an iOS visual task management app designed specifically for users with ADHD (Attention Deficit Hyperactivity Disorder). It replaces traditional text-heavy to-do lists with a photo-centric workflow that aligns with the cognitive strengths of visual thinkers.

> **Tagline:** "Capture Your Chaos. See Your Success."

## Features

### Core Loop (MVP)
1. **Capture** - Instantly photograph a task with zero friction
2. **Clarify** - AI suggests a title, or tap a quick-category icon
3. **Complete** - Take an "after" photo to create a satisfying visual record

### MVP Features

#### 1. Frictionless Photo Capture
- **Lock Screen & Home Screen Widgets** - One-tap photo capture
- **Post-Capture Triage** - Simple screen with large category buttons
- **AI-Powered Title Suggestion** - On-device image analysis

#### 2. Dopamine Dashboard
- **Visual Grid View** - Clean, visually scannable grid of tasks
- **"Urgency Glow"** - Animated glow for approaching deadlines
- **Kanban Board** - Drag between "To Do", "Doing", and "Done"

#### 3. Victory View
- **Before-and-After Comparison** - Interactive slider
- **Micro-Celebrations** - Confetti and haptic feedback
- **Daily Gallery** - Visual summary of accomplishments

#### 4. Gamification
- **Visual Streak Tracker** - Growing plant character
- **Achievement Badges** - Pattern-based rewards
- **Progress Stats** - Daily and weekly tracking

## Technology Stack

| Component | Technology |
|-----------|------------|
| Language | Swift 5.0+ |
| UI Framework | SwiftUI |
| Local Storage | Core Data + FileManager |
| AI/ML | Vision Framework + Core ML (MobileNetV3 - for future) |
| Widgets | WidgetKit |

## Project Structure

```
TaskSnap/
├── TaskSnap/
│   ├── TaskSnapApp.swift           # App entry point
│   ├── PersistenceController.swift  # Core Data setup
│   ├── Info.plist                  # App configuration
│   ├── TaskSnap.xcdatamodeld/      # Core Data model
│   ├── Assets.xcassets/            # App icons and colors
│   ├── Models/
│   │   ├── Task.swift              # Task model and enums
│   │   ├── Achievement.swift       # Achievement system
│   │   └── StreakManager.swift     # Streak tracking
│   ├── Views/
│   │   ├── ContentView.swift       # Main tab view
│   │   ├── DashboardView.swift     # Kanban board
│   │   ├── CaptureView.swift       # Photo capture flow
│   │   ├── TaskDetailView.swift    # Task details
│   │   ├── VictoryView.swift       # Completion celebration
│   │   ├── StreakView.swift        # Streak tracking UI
│   │   ├── AchievementView.swift   # Achievements UI
│   │   ├── ConfettiView.swift      # Celebration animation
│   │   └── UrgencyGlow.swift       # Urgency indicator
│   ├── ViewModels/
│   │   ├── TaskViewModel.swift     # Task management
│   │   ├── CaptureViewModel.swift  # Capture flow logic
│   │   └── GamificationViewModel.swift # Gamification logic
│   ├── Services/
│   │   └── ImageClassificationService.swift # AI image analysis
│   └── Utils/
│       ├── Haptics.swift           # Haptic feedback
│       └── Extensions.swift        # Swift extensions
└── TaskSnapWidgets/
    ├── TaskSnapWidgets.swift       # Widget implementation
    └── Info.plist                  # Widget configuration
```

## Installation

### Requirements
- iOS 17.0+
- Xcode 15.0+
- Swift 5.0+

### Setup
1. Clone or download the project
2. Open `TaskSnap.xcodeproj` in Xcode
3. Build and run on a simulator or physical device

## Usage

### Creating a Task
1. Tap the "Capture a Task" button or use the widget
2. Take a photo of something that needs attention
3. Select a category (Clean, Fix, Buy, Work, etc.)
4. Add optional details and due date
5. Save the task

### Managing Tasks
- View tasks in the Kanban-style Dashboard
- Tap a task to view details
- Move tasks between columns by changing status
- Mark tasks complete with an "after" photo

### Tracking Progress
- View your streak on the Streak tab
- Track achievements in the Awards tab
- Check daily progress in the Dashboard header

## ADHD-First Design Principles

1. **Dopamine-First Design** - Every interaction provides immediate, satisfying feedback
2. **Reduce Time-to-Action** - Minimize steps between intention and action
3. **Embrace Visual Thinking** - Prioritize images and icons over text
4. **Support Executive Functions** - UI acts as external scaffold for working memory
5. **Sensory-Friendly & Customizable** - Adjustable animations and themes

## Privacy

- All photos processed on-device
- Photos stored locally in app documents
- No server uploads for image analysis
- User data stays on device

## Future Enhancements (Phase 2)

- **Focus Mode** - Visual task timer with shrinking circle
- **Virtual Body Doubling Room** - Shared presence workspace
- **iCloud Sync** - Cross-device synchronization
- **Advanced AI** - Pattern recognition and insights

## License

This project is created based on the TaskSnap product specification.

---

*Designed for the ADHD brain. Capture your chaos. See your success.*
