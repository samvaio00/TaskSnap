# TaskSnap - Achievement Badge Artwork Specification 🏆

## Overview
Custom badge designs for the 26 achievements in TaskSnap. These replace the current SF Symbols with unique, visually appealing artwork.

**Location:** `TaskSnap/Assets.xcassets/AchievementBadges/`  
**Format:** PNG (with transparency) or SVG (vector)  
**Total Estimated Size:** ~2-3 MB (PNG) or ~500 KB (SVG)

---

## Art Direction

### Style Guidelines
- **Style:** Flat design with subtle depth (Material Design 3 style)
- **Shape:** Circular badge with optional decorative elements
- **Colors:** Bronze (#CD7F32), Silver (#C0C0C0), Gold (#FFD700) base with accent colors
- **Size:** Clear at small sizes (32×32pt) and large (120×120pt)
- **Consistency:** All badges share common design language

### Design Elements
1. **Base Shape:** Circular metal badge
2. **Tier Indicator:** Bronze/Silver/Gold coloring
3. **Icon:** Theme-specific symbol in center
4. **Details:** Ribbons, stars, or decorative elements for higher tiers
5. **States:** Locked (grayscale) and Unlocked (full color)

---

## Badge Categories

### Category 1: Getting Started (5 Badges)
These are entry-level achievements to onboard new users.

| Badge | Name | Tier | Concept |
|-------|------|------|---------|
| `badge_first_task` | First Capture | Bronze | Camera with sparkles |
| `badge_first_complete` | First Win | Bronze | Checkmark with ribbon |
| `badge_photo_journalist` | Photo Journalist | Bronze | Stack of photos |
| `badge_category_explorer` | Category Explorer | Bronze | Folder with magnifying glass |
| `badge_daily_user` | Daily User | Bronze | Calendar with checkmark |

**Design Notes:**
- Bronze tier with blue accent
- Simple, welcoming designs
- Clear metaphors for first-time actions

---

### Category 2: Streaks (5 Badges)
Daily completion streak achievements.

| Badge | Name | Tier | Concept |
|-------|------|------|---------|
| `badge_streak_3` | Getting Started | Bronze | Small flame (3 lines) |
| `badge_streak_7` | Week Warrior | Silver | Medium flame with "7" |
| `badge_streak_14` | Two Weeks Strong | Silver | Larger flame with "14" |
| `badge_streak_30` | Monthly Master | Gold | Crowned flame with "30" |
| `badge_streak_100` | Century Club | Gold | Epic flame with "100", stars |

**Design Notes:**
- Progressive flame growth
- Bronze → Silver → Gold progression
- Numbers clearly visible
- 100 badge should be extra special (epic design)

---

### Category 3: Productivity (6 Badges)
Task completion and productivity milestones.

| Badge | Name | Tier | Concept |
|-------|------|------|---------|
| `badge_task_5` | Getting Things Done | Bronze | "5" with task paper |
| `badge_task_25` | Task Master | Silver | "25" with stars |
| `badge_task_50` | Half Century | Silver | "50" with laurel |
| `badge_task_100` | Century | Gold | "100" with crown |
| `badge_bulk_5` | Power Hour | Bronze | Lightning bolt with "5" |
| `badge_bulk_10` | Super Sunday | Gold | Explosion with "10" |

**Design Notes:**
- Numbers prominent
- Task/document motifs
- Lightning/explosion for bulk badges

---

### Category 4: Explorer (5 Badges)
Feature exploration and category variety.

| Badge | Name | Tier | Concept |
|-------|------|------|---------|
| `badge_categories_5` | Jack of All Trades | Silver | 5 category icons |
| `badge_clean_10` | Clean Machine | Bronze | Sparkles and spray |
| `badge_fix_10` | Handyman | Bronze | Tools crossed |
| `badge_organize_10` | Organizer | Bronze | Files in order |
| `badge_health_10` | Health Hero | Bronze | Heart with bandage |

**Design Notes:**
- Category-specific imagery
- Color-coded by category type
- Clean Machine = blue/clean theme

---

### Category 5: Master (5 Badges)
Elite achievements for power users.

| Badge | Name | Tier | Concept |
|-------|------|------|---------|
| `badge_early_bird` | Early Bird | Gold | Sun rising with bird |
| `badge_night_owl` | Night Owl | Gold | Moon with owl silhouette |
| `badge_quick_5` | Speed Demon | Silver | Stopwatch with checkmark |
| `badge_perfect_week` | Perfect Week | Gold | "7/7" with calendar |
| `badge_weekend_warrior` | Weekend Warrior | Bronze | Calendar showing Sat/Sun |

**Design Notes:**
- Gold tier for most (elite status)
- Time-based icons (sun, moon, clock)
- Premium feel

---

## Technical Specifications

### Image Formats

#### Option A: PNG (Raster)
```
Format:        PNG with transparency
Sizes:         @1x, @2x, @3x
Dimensions:    
  - @1x: 60×60 pt (display), 120×120 px (export)
  - @2x: 120×120 pt, 240×240 px
  - @3x: 180×180 pt, 360×360 px
Color Space:   sRGB
File Naming:   badge_[name]@1x.png, @2x, @3x
```

#### Option B: SVG (Vector)
```
Format:        SVG (Single Scale)
Advantages:    One file, scales perfectly
Requirements:  Keep vectors simple for performance
Tool:          Illustrator, Figma, Sketch
```

**Recommendation:** Use SVG for badges (cleaner, smaller, future-proof).

---

## File Structure

### PNG Structure
```
TaskSnap/
└── TaskSnap/
    └── Assets.xcassets/
        └── AchievementBadges/
            ├── badge_first_task.imageset/
            │   ├── badge_first_task@1x.png
            │   ├── badge_first_task@2x.png
            │   ├── badge_first_task@3x.png
            │   └── Contents.json
            ├── badge_first_complete.imageset/
            │   └── ...
            └── ... (26 badge folders)
```

### SVG Structure (iOS 13+)
```
TaskSnap/
└── TaskSnap/
    └── Assets.xcassets/
        └── AchievementBadges/
            ├── badge_first_task.imageset/
            │   ├── badge_first_task.svg
            │   └── Contents.json
            └── ... (26 badge folders)
```

---

## Design Templates

### Base Badge Template
```
Outer Ring:     4pt stroke, metallic gradient
Inner Circle:   Filled with tier color
Icon Area:      60% of diameter
Detail Elements: Bottom ribbon or side stars
```

### Tier Specifications

| Tier | Base Color | Accent | Detail Level |
|------|------------|--------|--------------|
| Bronze | #CD7F32 | #8B4513 | Simple |
| Silver | #C0C0C0 | #808080 | Moderate |
| Gold | #FFD700 | #B8860B | Elaborate |

### State Variations

**Unlocked State:**
- Full color
- Metallic sheen
- Subtle shadow

**Locked State:**
- Grayscale
- Muted/dimmed
- No sheen
- Simpler detail

---

## Implementation

Current code uses SF Symbols:
```swift
struct Achievement {
    let icon: String  // Currently SF Symbol name
    // ...
}
```

With custom badges:
```swift
struct Achievement {
    let icon: String        // SF Symbol (fallback)
    let badgeName: String?  // Custom badge asset name
    // ...
}

// Usage
if let badge = achievement.badgeName {
    Image(badge)  // Custom badge
} else {
    Image(systemName: achievement.icon)  // Fallback
}
```

---

## Sourcing Options

### Hire Designer
- **Dribbble:** dribbble.com/designers
- **Fiverr:** fiverr.com (badge/icon designers)
- **99designs:** 99designs.com
- **Upwork:** upwork.com

**Budget Estimate:** $200-500 for 26 badges

### Design Tools (DIY)
- **Figma:** figma.com (free, collaborative)
- **Sketch:** sketch.com (Mac)
- **Adobe Illustrator:** adobe.com
- **Affinity Designer:** affinity.serif.com

### Badge Template Resources
- **Streamline Icons:** streamlineicons.com
- **Flaticon:** flaticon.com (base icons)
- **Noun Project:** thenounproject.com

---

## Design Deliverables

### For Each Badge:
1. **Vector Source File** (.ai, .fig, .sketch)
2. **SVG Export** (if using vector)
3. **PNG Exports** (1x, 2x, 3x)
4. **Preview** (how it looks in app)

### Style Guide:
1. **Color Palette** (exact hex codes)
2. **Typography** (if text used)
3. **Spacing Guidelines**
4. **Common Elements Library**

---

## Quality Checklist

Before adding to project:
- [ ] Clear at 32×32 pt size
- [ ] Recognizable at 16×16 pt (extreme small)
- [ ] Looks good at 120×120 pt (detail view)
- [ ] Consistent style across all badges
- [ ] Proper transparency
- [ ] Tier colors correct (bronze/silver/gold)
- [ ] Locked state version created
- [ ] Filename matches specification
- [ ] Assets properly added to .xcassets

---

## Current Status

| Item | Status | Notes |
|------|--------|-------|
| Design Direction | ⬜ Needed | Create style guide |
| Base Templates | ⬜ Needed | Bronze/Silver/Gold templates |
| Category 1 Badges | ⬜ Needed | 5 starter badges |
| Category 2 Badges | ⬜ Needed | 5 streak badges |
| Category 3 Badges | ⬜ Needed | 6 productivity badges |
| Category 4 Badges | ⬜ Needed | 5 explorer badges |
| Category 5 Badges | ⬜ Needed | 5 master badges |

**Current Behavior:** Using SF Symbols (`camera.fill`, `flame.fill`, `bolt.fill`, etc.) which works well but lacks uniqueness.

**Priority:** Low (SF Symbols are professional and acceptable for launch)

---

## Post-Launch Enhancement Plan

**Phase 1:** Bronze tier badges (most common)
**Phase 2:** Silver tier badges
**Phase 3:** Gold tier badges (rarest, most prestigious)
**Phase 4:** Special unlock animations per badge

---

**Document Version:** 1.0  
**Last Updated:** Feb 21, 2025  
**Author:** TaskSnap Development Team
