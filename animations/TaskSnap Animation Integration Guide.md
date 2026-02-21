# TaskSnap Animation Integration Guide

## Overview
This guide explains when and how to use each of the 6 animations in the TaskSnap iOS app. All animations are 4 seconds long, square aspect ratio (optimized for iOS), and include embedded audio.

---

## Animation Files & Usage

### 1. **capture_success.mp4**
**Trigger:** When user successfully captures a photo for a new task  
**Placement:** Full-screen overlay or modal after camera capture  
**Duration:** 4 seconds  
**User Action:** Auto-dismisses after animation, transitions to task detail screen  

**Implementation Notes:**
- Play immediately after photo is captured and saved
- Can be skipped by tapping screen (for power users)
- Consider haptic feedback at the "snap" moment (0.5s mark)

**Emotional Goal:** Satisfaction, "gotcha!", task initiation success

---

### 2. **task_complete.mp4**
**Trigger:** When user marks a task as complete (after taking "after" photo)  
**Placement:** Full-screen overlay showing before/after photos with animation overlay  
**Duration:** 4 seconds  
**User Action:** Auto-dismisses, then shows satisfaction rating prompt  

**Implementation Notes:**
- This is the PRIMARY dopamine reward moment
- Never allow skipping this animation (it's the core motivation loop)
- Strong haptic feedback at confetti explosion (1.5s mark)
- Consider allowing users to replay this animation from completed task gallery

**Emotional Goal:** Pure celebration, dopamine rush, sense of accomplishment

---

### 3. **streak_grow.mp4**
**Trigger:** When user completes at least one task on consecutive days (streak continues)  
**Placement:** Modal popup after first task completion of the day  
**Duration:** 4 seconds  
**User Action:** Tap to dismiss after animation completes  

**Implementation Notes:**
- Only show once per day (first task completion)
- Display current streak number at end of animation
- Consider showing at app launch if user completed tasks yesterday
- Medium haptic feedback at bloom moment (2.5s mark)

**Emotional Goal:** Growth, momentum, "you're building something"

---

### 4. **streak_break.mp4**
**Trigger:** When user returns to app after missing a day (streak broken)  
**Placement:** Modal popup at app launch  
**Duration:** 4 seconds  
**User Action:** Tap "Start Fresh" button after animation  

**Implementation Notes:**
- Only show ONCE when streak breaks (don't remind repeatedly)
- Gentle haptic feedback at sun appearance (2.5s mark)
- Include a "Start Fresh" or "New Streak" button after animation
- Tone should be encouraging, not guilt-inducing

**Emotional Goal:** Compassion, hope, "it's okay to restart"

---

### 5. **badge_unlock.mp4**
**Trigger:** When user earns an achievement badge  
**Placement:** Full-screen modal overlay  
**Duration:** 4 seconds  
**User Action:** Tap to dismiss and view badge details  

**Implementation Notes:**
- Queue multiple badge unlocks (don't stack animations)
- Strong haptic feedback at badge "thunk" moment (1.5s mark)
- After animation, show badge detail screen with description
- Consider sharing option after viewing badge

**Achievement Types:**
- "Morning Warrior" - Complete 3 tasks before 10 AM
- "Clutter Buster" - Complete 5 cleaning tasks
- "Streak Master" - 7-day streak
- "Photo Pro" - 50 tasks completed with before/after photos

**Emotional Goal:** Epic achievement, "you're a legend"

---

### 6. **focus_start.mp4**
**Trigger:** When user taps "Start Timer" on a task (Focus Mode)  
**Placement:** Full-screen or overlay around task photo  
**Duration:** 4 seconds  
**User Action:** Auto-transitions to focus mode timer view  

**Implementation Notes:**
- Gentle haptic feedback at circle completion (1.5s mark)
- After animation, show timer countdown with task photo
- Background should remain slightly darkened during focus session
- Consider continuing the gentle pulse animation during timer

**Emotional Goal:** Calm focus, centering, "time to lock in"

---

## Technical Implementation Guidelines

### iOS Integration (SwiftUI)

```swift
import AVKit

struct AnimationView: View {
    let animationName: String
    @State private var player: AVPlayer?
    
    var body: some View {
        VideoPlayer(player: player)
            .onAppear {
                if let url = Bundle.main.url(forResource: animationName, withExtension: "mp4") {
                    player = AVPlayer(url: url)
                    player?.play()
                }
            }
            .ignoresSafeArea()
    }
}
```

### Haptic Feedback Integration

```swift
import CoreHaptics

func triggerHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle) {
    let generator = UIImpactFeedbackGenerator(style: style)
    generator.impactOccurred()
}

// Usage:
// capture_success: .medium at 0.5s
// task_complete: .heavy at 1.5s
// streak_grow: .medium at 2.5s
// badge_unlock: .heavy at 1.5s
// focus_start: .light at 1.5s
```

### User Preferences

Allow users to control animation experience in Settings:

- **Animation Intensity:** Full / Reduced / Minimal
  - Full: All animations play at full length
  - Reduced: Animations play at 2x speed
  - Minimal: Only show static image with sound

- **Sound Effects:** On / Off
  - Respects system silent mode
  - Individual volume control in settings

- **Haptic Feedback:** Strong / Gentle / Off

---

## File Specifications

| Filename | Duration | Resolution | Format | Audio |
|----------|----------|------------|--------|-------|
| capture_success.mp4 | 4s | 1080x1080 | H.264 | Embedded |
| task_complete.mp4 | 4s | 1080x1080 | H.264 | Embedded |
| streak_grow.mp4 | 4s | 1080x1080 | H.264 | Embedded |
| streak_break.mp4 | 4s | 1080x1080 | H.264 | Embedded |
| badge_unlock.mp4 | 4s | 1080x1080 | H.264 | Embedded |
| focus_start.mp4 | 4s | 1080x1080 | H.264 | Embedded |

**Total File Size:** ~15-25 MB (all 6 animations)

---

## ADHD-Friendly Design Principles Applied

1. **Immediate Feedback:** All animations trigger instantly when action is completed
2. **Dopamine Optimization:** Celebratory animations are more dramatic than neutral ones
3. **Compassionate Design:** Streak break animation is gentle and encouraging
4. **Sensory Control:** Users can adjust intensity in settings
5. **Clear Purpose:** Each animation has a distinct emotional goal and visual style

---

## Testing Checklist

- [ ] All animations play smoothly on iPhone 8 and newer
- [ ] Audio plays correctly (respects silent mode)
- [ ] Haptic feedback triggers at correct moments
- [ ] Animations can be skipped where appropriate
- [ ] File sizes are optimized for app bundle
- [ ] Animations work in both light and dark mode
- [ ] Reduced motion accessibility setting is respected
- [ ] Animations don't cause battery drain during extended use

---

**Note:** These animations are designed to be the emotional core of TaskSnap's ADHD-friendly experience. They transform mundane task completion into rewarding, dopamine-generating moments that keep users engaged and motivated.


---

## New User-Provided Animations

### 7. **daily_goal_complete.mp4** (formerly Checkliststyletaskcomplete.mp4)
**Trigger:** When user completes ALL tasks for the day OR achieves a daily goal milestone (e.g., 5+ tasks in one day)  
**Placement:** Full-screen modal at end of day or when daily goal is reached  
**Duration:** 8 seconds  
**User Action:** Tap to dismiss  

**Implementation Notes:**
- This is a major milestone animation, so the 8-second duration is justified
- Use this INSTEAD of task_complete.mp4 for the final task of the day
- The high energy and confetti are perfect for a "you did it!" moment
- Strong haptic feedback throughout the confetti explosion

**Emotional Goal:** Overwhelming joy, "I crushed it!", daily victory

---

### 8. **organize_task_complete.mp4** (formerly CleanUpTaskCompleted.mp4)
**Trigger:** When user completes a task specifically categorized as "Clean" or "Organize"  
**Placement:** Full-screen overlay, replacing the standard task_complete.mp4 for this category  
**Duration:** 8 seconds  
**User Action:** Auto-dismisses, then shows satisfaction rating prompt  

**Implementation Notes:**
- Use logic to check task category before playing completion animation
- The calm, magical style is a perfect reward for tidying up
- The 8-second duration provides a moment of zen-like satisfaction
- Gentle, sparkling haptic feedback throughout

**Emotional Goal:** Calm satisfaction, peace, "everything is in its place"

---

## Updated File Specifications

| Filename | Duration | Resolution | Format | Audio |
|----------|----------|------------|--------|-------|
| capture_success.mp4 | 4s | 1080x1080 | H.264 | Embedded |
| task_complete.mp4 | 4s | 1080x1080 | H.264 | Embedded |
| streak_grow.mp4 | 4s | 1080x1080 | H.264 | Embedded |
| streak_break.mp4 | 4s | 1080x1080 | H.264 | Embedded |
| badge_unlock.mp4 | 4s | 1080x1080 | H.264 | Embedded |
| focus_start.mp4 | 4s | 1080x1080 | H.264 | Embedded |
| **daily_goal_complete.mp4** | **8s** | **1280x720** | **H.264** | **Embedded** |
| **organize_task_complete.mp4** | **8s** | **1280x720** | **H.264** | **Embedded** |

**Total File Size:** ~25-35 MB (all 8 animations)
