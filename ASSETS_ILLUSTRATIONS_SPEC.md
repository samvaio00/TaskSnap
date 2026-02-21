# TaskSnap - Illustrations & Graphics Specification 🎨

## Overview
Custom illustrations for onboarding, empty states, and marketing. These add personality and visual appeal beyond SF Symbols.

**Location:** `TaskSnap/Assets.xcassets/Illustrations/`  
**Format:** SVG (vector) preferred, PNG (raster) acceptable  
**Total Estimated Size:** ~1-2 MB (SVG) or ~5 MB (PNG)

---

## Art Direction

### Style Guidelines
- **Style:** Friendly, inclusive flat illustration with soft shadows
- **Character:** Optional friendly mascot character (plant/creature)
- **Colors:** TaskSnap brand colors (blue primary, green accent, warm neutrals)
- **Composition:** Simple, focused scenes with clear focal point
- **Accessibility:** High contrast, clear meaning without color

### Mood
- Encouraging and optimistic
- ADHD-friendly (calm but engaging)
- Professional but approachable
- Diverse and inclusive

---

## Required Illustrations

### 1. Onboarding Illustrations (5)
Full-screen illustrations for the 5-page onboarding flow.

#### 1.1 Welcome Screen
| Property | Value |
|----------|-------|
| **Filename** | `illustration_welcome` |
| **Scene** | Person holding phone, capturing a photo of a task (messy desk, plant, etc.) |
| **Mood** | Exciting, inviting |
| **Colors** | Blue primary, warm background |
| **Elements** | Phone/camera, task scene, sparkles of potential |
| **Text Companion** | "Welcome to TaskSnap" |

**Requirements:**
- Hero illustration
- Centered composition
- Room for title and subtitle text
- Optimistic energy

---

#### 1.2 Capture Screen
| Property | Value |
|----------|-------|
| **Filename** | `illustration_capture` |
| **Scene** | Hand holding phone, camera viewfinder visible, capturing something |
| **Mood** | Action-oriented, easy |
| **Colors** | Blue, camera UI elements |
| **Elements** | Hand, phone, viewfinder overlay, checkmark preview |
| **Text Companion** | "Capture Your Chaos" |

**Requirements:**
- Show the "photo-first" concept
- Simple hand representation
- Camera interface hints

---

#### 1.3 Clarify Screen
| Property | Value |
|----------|-------|
| **Filename** | `illustration_clarify` |
| **Scene** | AI/robot helper presenting category options, or magic sparkles organizing items |
| **Mood** | Helpful, magical, easy |
| **Colors** | Purple/blue (AI), category colors |
| **Elements** | AI helper OR sparkles, category icons floating |
| **Text Companion** | "AI Helps You Clarify" |

**Requirements:**
- Show AI assistance
- Not too technical/scary
- Friendly representation of AI

---

#### 1.4 Complete Screen
| Property | Value |
|----------|-------|
| **Filename** | `illustration_complete` |
| **Scene** | Before/after comparison, celebration, person happy with completed task |
| **Mood** | Triumphant, satisfying |
| **Colors** | Green (success), gold accents |
| **Elements** | Before/after, checkmark, celebration elements |
| **Text Companion** | "See Your Success" |

**Requirements:**
- Show transformation
- Celebratory but not overwhelming
- Clear before/after visual

---

#### 1.5 Streak/Permissions Screen
| Property | Value |
|----------|-------|
| **Filename** | `illustration_streak` |
| **Scene** | Growing plant character OR calendar with checkmarks, flame growing |
| **Mood** | Encouraging, motivating |
| **Colors** | Green (growth), orange (flame) |
| **Elements** | Plant growing, streak flame, calendar |
| **Text Companion** | "Build Your Streak" |

**Requirements:**
- Show growth over time
- Plant metaphor for streaks
- Friendly, nurturing feel

---

### 2. Empty State Illustrations (4)
Illustrations shown when there's no content.

#### 2.1 No Tasks
| Property | Value |
|----------|-------|
| **Filename** | `empty_no_tasks` |
| **Scene** | Friendly character holding camera, ready to capture |
| **Mood** | Inviting, ready-to-start |
| **Colors** | Blue, warm neutrals |
| **Elements** | Character, camera, empty task board hint |
| **Text** | "Ready to start? Capture your first task!" |

---

#### 2.2 No Completed Tasks
| Property | Value |
|----------|-------|
| **Filename** | `empty_no_completed` |
| **Scene** | Character looking at empty Done column, encouraging gesture |
| **Mood** | Encouraging, patient |
| **Colors** | Blue, soft colors |
| **Elements** | Character, empty checkmark outline |
| **Text** | "No completed tasks yet. You've got this!" |

---

#### 2.3 Task Limit Reached
| Property | Value |
|----------|-------|
| **Filename** | `empty_limit_reached` |
| **Scene** | Full task board with "full" sign OR character with overflowing clipboard |
| **Mood** | Gentle nudge, not pushy |
| **Colors** | Orange/yellow (warning), friendly |
| **Elements** | Full board, upgrade hint, character |
| **Text** | "Task limit reached! Complete tasks or upgrade to Pro." |

---

#### 2.4 No Search Results
| Property | Value |
|----------|-------|
| **Filename** | `empty_no_results` |
| **Scene** | Character searching with magnifying glass, shrugging or confused |
| **Mood** | Helpful, understanding |
| **Colors** | Neutral, soft |
| **Elements** | Magnifying glass, search icon, question mark |
| **Text** | "No tasks found. Try a different search." |

---

### 3. Achievement Unlock Illustration (1)
Celebration illustration for major achievements.

#### 3.1 Achievement Unlocked
| Property | Value |
|----------|-------|
| **Filename** | `achievement_unlocked` |
| **Scene** | Character holding trophy/badge, celebration confetti |
| **Mood** | Triumphant, epic |
| **Colors** | Gold, all category colors |
| **Elements** | Character, trophy/badge, confetti, sparkles |
| **Usage** | Full-screen modal for rare achievements |

---

## Technical Specifications

### Image Formats

#### Option A: SVG (Preferred)
```
Format:        SVG (Vector)
Advantages:    Scales to any size, small file size, editable
Tools:         Figma, Illustrator, Sketch
Compatibility: iOS 13+ (SF Symbols style)
```

#### Option B: PNG (Raster)
```
Format:        PNG with transparency
Sizes:         @1x, @2x, @3x
Dimensions:    
  - Onboarding: 300×300 pt (@1x) → 600×600 px (@2x) → 900×900 px (@3x)
  - Empty State: 200×200 pt (@1x) → 400×400 px (@2x) → 600×600 px (@3x)
Color Space:   sRGB
```

**Recommendation:** Use SVG for illustrations (future-proof, scalable).

---

## File Structure

### SVG Structure
```
TaskSnap/
└── TaskSnap/
    └── Assets.xcassets/
        └── Illustrations/
            ├── illustration_welcome.imageset/
            │   ├── illustration_welcome.svg
            │   └── Contents.json
            ├── illustration_capture.imageset/
            │   └── ...
            ├── illustration_clarify.imageset/
            ├── illustration_complete.imageset/
            ├── illustration_streak.imageset/
            ├── empty_no_tasks.imageset/
            ├── empty_no_completed.imageset/
            ├── empty_limit_reached.imageset/
            ├── empty_no_results.imageset/
            └── achievement_unlocked.imageset/
```

---

## Color Palette

### Primary Brand Colors
| Color | Hex | Usage |
|-------|-----|-------|
| TaskSnap Blue | #007AFF | Primary actions, links |
| Success Green | #34C759 | Complete, success |
| Accent Orange | #FF9500 | Urgent, warnings |
| Warm Background | #F2F2F7 | Light mode backgrounds |
| Dark Background | #1C1C1E | Dark mode backgrounds |

### Illustration-Specific Colors
| Color | Hex | Usage |
|-------|-----|-------|
| Skin Tones | Various | Characters |
| Plant Green | #30D158 | Streak plant |
| Warm Gold | #FFD60A | Celebrations |
| Soft Purple | #BF5AF2 | AI/Magic |

---

## Character Design (Optional)

### Plant Mascot Concept
A friendly plant character that grows with the user's streak:
- **Sprout:** Days 1-3 (small, cute)
- **Growing:** Days 4-7 (developing leaves)
- **Blooming:** Days 8-30 (flowers appearing)
- **Mature:** 30+ days (full, lush plant)

**Personality:**
- Supportive and encouraging
- Celebrates with the user
- Shows emotion through leaves/flowers
- Gender-neutral and inclusive

---

## Implementation

### Current Implementation (SF Symbols)
```swift
// Onboarding currently uses SF Symbols
Image(systemName: "camera.fill")
    .font(.system(size: 100))
```

### With Custom Illustrations
```swift
// Replace with custom illustrations
Image("illustration_welcome")
    .resizable()
    .scaledToFit()
    .frame(maxHeight: 300)

// Or SVG (iOS 13+)
Image("illustration_welcome")
    .resizable()
    .aspectRatio(contentMode: .fit)
```

### Dark Mode Support
- Provide dark mode variants OR
- Use colors that work on both backgrounds OR
- Add background shape behind illustration

---

## Sourcing Options

### Hire Illustrator
- **Dribbble:** dribbble.com/designers (search "illustration")
- **Fiverr:** fiverr.com (character design, flat illustration)
- **99designs:** 99designs.com
- **Upwork:** upwork.com

**Budget Estimate:** $500-1500 for full illustration set

### Illustration Style References
- **Airbnb Illustrations:** Friendly, inclusive characters
- **Stripe Illustrations:** Clean, professional
- **Headspace:** Calm, approachable
- **Duolingo:** Character-driven, fun

### Stock Illustrations (Base)
- **Blush:** blush.design (customizable characters)
- **Humaaans:** humaaans.com (mix-and-match people)
- **Open Peeps:** openpeeps.com (hand-drawn style)
- **Storyset:** storyset.com (free illustrations)
- **unDraw:** undraw.co (open source illustrations)

**Note:** Stock illustrations can be customized to match brand colors.

---

## Design Deliverables

### For Each Illustration:
1. **Source File** (.ai, .fig, .sketch)
2. **SVG Export** (if using vector)
3. **PNG Exports** (1x, 2x, 3x)
4. **Dark Mode Variant** (if needed)
5. **Usage Guidelines** (size, placement)

### Style Guide:
1. **Character Sheet** (if using mascot)
2. **Color Palette** (exact hex codes)
3. **Composition Guidelines**
4. **Typography Pairing**

---

## Quality Checklist

Before adding to project:
- [ ] Clear at small sizes (empty states)
- [ ] Detailed enough for large sizes (onboarding)
- [ ] Works in light and dark mode
- [ ] On-brand colors
- [ ] Appropriate mood for context
- [ ] Room for text overlay
- [ ] Filename matches specification
- [ ] Assets properly added to .xcassets
- [ ] File size reasonable (< 500 KB per illustration)

---

## Current Status

| Illustration | Status | Priority |
|--------------|--------|----------|
| Welcome | ⬜ Needed | Medium |
| Capture | ⬜ Needed | Medium |
| Clarify | ⬜ Needed | Medium |
| Complete | ⬜ Needed | Medium |
| Streak | ⬜ Needed | Medium |
| Empty - No Tasks | ⬜ Needed | Low |
| Empty - No Completed | ⬜ Needed | Low |
| Empty - Limit Reached | ⬜ Needed | Low |
| Empty - No Results | ⬜ Needed | Low |
| Achievement Unlocked | ⬜ Needed | Low |

**Current Behavior:** Using SF Symbols which are clean, professional, and work well.

**Priority:** Medium for onboarding (would enhance first impression), Low for empty states.

---

## Post-Launch Enhancement Plan

**Phase 1:** Onboarding illustrations (highest impact)
**Phase 2:** Empty state illustrations
**Phase 3:** Achievement celebration illustration
**Phase 4:** Animated illustrations (Lottie)

---

## Alternative: Lottie Animations

For future enhancement, illustrations could be animated using Lottie:
- Plant growing animation
- Camera shutter animation
- Confetti/celebration animation
- Smooth onboarding transitions

**Benefits:** Small file size, scalable, smooth 60fps
**Tools:** After Effects + Bodymovin plugin

---

**Document Version:** 1.0  
**Last Updated:** Feb 21, 2025  
**Author:** TaskSnap Development Team
