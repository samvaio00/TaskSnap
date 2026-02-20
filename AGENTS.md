# TaskSnap - AI Agent Project Documentation

## Project Overview

**TaskSnap** is a product specification project for an iOS visual task management app designed specifically for users with ADHD (Attention Deficit Hyperactivity Disorder). The project currently exists as a set of detailed planning documents rather than a codebase with source files.

- **Project Type**: Product Specification / Planning Documents
- **Platform**: iOS (iPhone/iPad), with future Apple Watch support planned
- **Target Audience**: Adults with ADHD, visual learners, individuals with executive function challenges
- **Tagline**: "Capture Your Chaos. See Your Success."
- **MVP Budget**: $30K-50K
- **MVP Timeline**: 3-4 months

## Project Structure

This project directory contains only specification documents:

```
/Users/warnergears/Documents/Projects/SnapTask/
├── AGENTS.md              # This file - AI agent project documentation
├── TaskSnap Enhancement.md # Strategic improvements and feature analysis
└── TaskSnap.txt            # Full project specification document
```

### Key Documents

| File | Description |
|------|-------------|
| `TaskSnap.txt` | Complete product specification including features, UI/UX design, technical stack, and monetization |
| `TaskSnap Enhancement.md` | Strategic analysis document outlining ADHD-first design philosophy and competitive advantages |

## Technology Stack (Planned)

The specification outlines the following planned technical implementation:

| Component | Technology |
|-----------|------------|
| **Language** | Swift 5.0+ |
| **UI Framework** | SwiftUI |
| **Local Storage** | Core Data + FileManager |
| **AI/ML** | Vision Framework + Core ML (MobileNetV3) |
| **Widgets** | WidgetKit |
| **Sync** | iCloud (Pro tier) |

## Core Concept

TaskSnap replaces traditional text-heavy to-do lists with a photo-centric workflow:

1. **Capture**: Take a photo of something that needs attention (messy desk, broken item, etc.)
2. **Clarify**: AI suggests a task title, or user taps a quick category icon
3. **Complete**: Take an "after" photo to create a satisfying visual record of accomplishment

### Key Features (MVP - Phase 1)

- **Lock Screen & Home Screen Widgets**: One-tap photo capture
- **Dopamine Dashboard**: Kanban-style visual task board (To Do / Doing / Done)
- **Urgency Glow**: Visual indicators for approaching deadlines
- **Victory View**: Before-and-after photo comparison with celebration animations
- **Visual Streak Tracker**: Growing plant/character that responds to daily completion
- **Achievement Badges**: Pattern-based rewards ("Morning Warrior", "Clutter Buster")

### Advanced Features (Phase 2)

- **Focus Mode**: Visual task timer with shrinking circle progress indicator
- **Virtual Body Doubling Room**: Shared presence workspace for accountability
- **iCloud Sync & Shared Spaces**: Cross-device sync and family collaboration
- **Pattern Recognition**: AI insights into productivity patterns

## ADHD-First Design Principles

The app is designed with these core principles:

1. **Dopamine-First Design**: Every interaction provides immediate, satisfying feedback
2. **Reduce Time-to-Action**: Minimize steps between intention and action (widgets, quick capture)
3. **Embrace Visual Thinking**: Prioritize images and icons over text
4. **Support Executive Functions**: UI acts as external scaffold for working memory
5. **Sensory-Friendly & Customizable**: Themes, adjustable animations, choice of sounds

## Monetization Model

### Free Tier ("Starter")
- Up to 15 active tasks
- Core photo task creation and completion
- Basic AI title suggestions
- Standard animations and haptics
- Local storage only

### Pro Tier ("Momentum") - $5.99/month or $59.99/year
- Unlimited tasks
- iCloud sync across devices
- Advanced gamification and celebration themes
- Focus mode and virtual body doubling
- Enhanced analytics and AI features
- Priority support

## AI Strategy

- **MVP Approach**: Use pre-trained MobileNetV3 (no custom training)
- **Privacy-First**: All image processing on-device, photos never uploaded
- **Categories**: Focus on 10-12 broad, high-accuracy categories
- **Future**: Pattern recognition and "Clutter Score" analysis

## When Working on This Project

### If Adding Code
When this project transitions from specification to implementation:

1. **Create proper iOS project structure** with Xcode
2. **Follow SwiftUI best practices** for declarative UI
3. **Implement Core Data** for local persistence
4. **Integrate Core ML** with MobileNetV3 for on-device image classification
5. **Add WidgetKit extension** for lock screen widgets

### Document Maintenance

When modifying specifications:
- Keep both `TaskSnap.txt` and `TaskSnap Enhancement.md` in sync
- Update version numbers when making significant changes
- Document removed/deferred features with rationale

### Key Files to Reference

| Question | Refer To |
|----------|----------|
| What features are in MVP? | `TaskSnap.txt` - "MVP FEATURES (Phase 1)" section |
| What was removed from scope? | `TaskSnap Enhancement.md` - "Features REMOVED for MVP Viability" |
| What's the UI design approach? | `TaskSnap.txt` - "ENHANCED USER INTERFACE & EXPERIENCE" |
| What's the competitive advantage? | `TaskSnap Enhancement.md` - "Key Strategic Advantages" |

## Current Status

⚠️ **This is a planning/specification project only** - no source code exists yet.

The project is ready for:
- Development team review and estimation
- Prototype/MVP development
- Community validation (r/ADHD feedback as suggested in Enhancement doc)

## Notes for AI Agents

- This project contains **no build system, no tests, and no runnable code**
- All "architecture" references in this document refer to the **planned** architecture from specifications
- Any code generation should create new iOS/Swift project files from scratch
- The specifications are written in English and use iOS/macOS development terminology
