# TaskSnap - UI Sound Effects Specification 🔊

## Overview
Sound effects for user interface interactions and feedback. These are short, non-looping sounds that play in response to user actions.

**Location:** `TaskSnap/Resources/Sounds/UI/`  
**Format:** MP3 (192 kbps) or CAF (Apple optimized)  
**Total Estimated Size:** ~500 KB - 1 MB

---

## Required Sound Files

### 1. Button Tap Sound
| Property | Value |
|----------|-------|
| **Filename** | `button_tap.mp3` |
| **Duration** | 50-100 ms |
| **Description** | Short, subtle click sound for button presses. Should be satisfying but not distracting. |
| **Usage** | All button presses throughout the app |
| **Mood** | Neutral, satisfying |
| **Reference** | iOS keyboard click, light mechanical switch |

**Technical Requirements:**
- Sharp attack, quick decay
- Mid-frequency range (1-3 kHz)
- Consistent volume
- No reverb

---

### 2. Task Complete Sound
| Property | Value |
|----------|-------|
| **Filename** | `task_complete.mp3` |
| **Duration** | 300-500 ms |
| **Description** | Upbeat, positive sound that plays when a task is moved to "Done". Should feel rewarding and motivating. |
| **Usage** | Task completion, moving to Done column |
| **Mood** | Positive, celebratory, encouraging |
| **Reference** | Achievement unlock sound, success chime |

**Technical Requirements:**
- Ascending pitch sequence
- Bright, clear tone
- Gentle reverb for spaciousness
- Not overly long or complex

---

### 3. Success Sound
| Property | Value |
|----------|-------|
| **Filename** | `success.mp3` |
| **Duration** | 200-400 ms |
| **Description** | Generic success confirmation sound. Simpler than task complete, for general success states. |
| **Usage** | Settings saved, sync complete, general success |
| **Mood** | Positive, confirming |
| **Reference** | iOS "success" system sound, pleasant ding |

**Technical Requirements:**
- Clear, bell-like tone
- Short decay
- Consistent across app

---

### 4. Error Sound
| Property | Value |
|----------|-------|
| **Filename** | `error.mp3` |
| **Duration** | 150-250 ms |
| **Description** | Non-jarring error indication. Should communicate "something went wrong" without being alarming. |
| **Usage** | Validation errors, failed operations, warnings |
| **Mood** | Neutral, informing |
| **Reference** | iOS "error" system sound, soft thud |

**Technical Requirements:**
- Lower frequency than success
- Descending pitch optional
- Brief duration
- Not harsh or startling

---

### 5. Camera Shutter Sound
| Property | Value |
|----------|-------|
| **Filename** | `camera_shutter.mp3` |
| **Duration** | 100-200 ms |
| **Description** | Modern camera shutter sound for photo capture. Should feel like a real camera but not jarring. |
| **Usage** | Taking photos in camera view, saving images |
| **Mood** | Functional, satisfying |
| **Reference** | iPhone camera shutter, mirrorless camera |

**Technical Requirements:**
- Sharp mechanical sound
- Realistic but pleasant
- May include subtle film advance sound
- Respects system mute switch

---

### 6. Achievement Unlock Sound
| Property | Value |
|----------|-------|
| **Filename** | `achievement.mp3` |
| **Duration** | 600-1000 ms |
| **Description** | Epic, celebratory sound for unlocking achievements. More elaborate than task complete. |
| **Usage** | Badge unlock, milestone reached, streak records |
| **Mood** | Epic, rewarding, special |
| **Reference** | Game achievement sounds, level up sounds, fanfare |

**Technical Requirements:**
- Multi-layered (chime + flourish)
- Ascending melody
- Sparkle effects optional
- Can be longer than other UI sounds
- Build-up to climax

---

### 7. Streak Milestone Sound
| Property | Value |
|----------|-------|
| **Filename** | `streak_milestone.mp3` |
| **Duration** | 800-1200 ms |
| **Description** | Special sound for streak milestones (7 days, 30 days, etc.). Should feel like a major accomplishment. |
| **Usage** | 7-day streak, 30-day streak, 100-day streak |
| **Mood** | Triumphant, inspiring |
| **Reference** | Victory fanfare, epic win sound, orchestral hit |

**Technical Requirements:**
- Most elaborate UI sound
- Orchestral or synthesized epic feel
- Rising intensity
- Satisfying conclusion
- May include subtle applause or cheer

---

### 8. Swipe Sound
| Property | Value |
|----------|-------|
| **Filename** | `swipe.mp3` |
| **Duration** | 80-150 ms |
| **Description** | Quick swish sound for swipe gestures. Should match the physical motion. |
| **Usage** | Swipe actions on task cards, dismiss gestures |
| **Mood** | Quick, functional |
| **Reference** | Card flip, paper swipe, whoosh |

**Technical Requirements:**
- White noise or filtered swoosh
- Matches gesture velocity
- Subtle, not distracting

---

### 9. Pop Sound
| Property | Value |
|----------|-------|
| **Filename** | `pop.mp3` |
| **Duration** | 50-100 ms |
| **Description** | Light pop sound for UI elements appearing or expanding. |
| **Usage** | Toast notifications, popovers, expanding cards |
| **Mood** | Light, playful |
| **Reference** | Bubble pop, cork pop (subtle) |

**Technical Requirements:**
- Short, snappy
- Mid to high frequency
- Fun but professional

---

## Technical Specifications

### Audio Format
```
Format:        MP3 (preferred) or CAF
Bitrate:       192 kbps (MP3)
Sample Rate:   44.1 kHz
Channels:      Mono (sufficient for UI sounds)
Duration:      See individual specs above
File Size:     ~50-150 KB per file
```

### Volume Normalization
All sounds should be normalized to similar perceived loudness:
- **Target LUFS:** -16 LUFS (integrated)
- **True Peak:** -1 dBTP
- Master volume will be controlled by app (0-100%)

### Naming Convention
- Use lowercase with underscores: `button_tap.mp3`
- Must match exactly in code (case-sensitive)
- No spaces or special characters

---

## File Structure

```
TaskSnap/
└── TaskSnap/
    └── Resources/
        └── Sounds/
            └── UI/
                ├── button_tap.mp3
                ├── task_complete.mp3
                ├── success.mp3
                ├── error.mp3
                ├── camera_shutter.mp3
                ├── achievement.mp3
                ├── streak_milestone.mp3
                ├── swipe.mp3
                └── pop.mp3
```

---

## Implementation

The app uses `SoundEffectManager` to play sounds:

```swift
SoundEffectManager.shared.play(.buttonTap)
SoundEffectManager.shared.play(.taskComplete, withHaptic: true)
```

**Fallback:** If custom sounds are not found, the app uses iOS system sounds as fallback.

---

## Sourcing Options

### Free Resources
| Source | URL | License |
|--------|-----|---------|
| **Freesound.org** | freesound.org | CC0 / CC-BY |
| **Zapsplat** | zapsplat.com | Free with signup |
| **Pixabay** | pixabay.com/sound-effects | Pixabay License |

### Search Terms
- `"UI click" "interface" "button"`
- `"success" "achievement" "game" "unlock"`
- `"camera" "shutter" "mechanical"`
- `"error" "warning" "alert" "soft"`
- `"swipe" "swoosh" "whoosh" "gesture"`

### Paid Resources (Higher Quality)
| Source | Price |
|--------|-------|
| **Epidemic Sound** | $15/month |
| **AudioJungle** | $5-20 per effect pack |
| **Soundsnap** | $29/month |

---

## Quality Checklist

Before adding to project:
- [ ] File plays correctly on iOS device
- [ ] Volume is consistent with other sounds
- [ ] No clipping or distortion
- [ ] Filename matches specification exactly
- [ ] File is in correct directory
- [ ] Sound is not annoying when repeated
- [ ] Works with app volume control
- [ ] Respects system mute switch

---

## Current Status

| File | Status | Fallback |
|------|--------|----------|
| `button_tap.mp3` | ⬜ Needed | System sound 1104 |
| `task_complete.mp3` | ⬜ Needed | System sound 1394 |
| `success.mp3` | ⬜ Needed | System sound 1394 |
| `error.mp3` | ⬜ Needed | System sound 1053 |
| `camera_shutter.mp3` | ⬜ Needed | System sound 1108 |
| `achievement.mp3` | ⬜ Needed | System sound 1395 |
| `streak_milestone.mp3` | ⬜ Needed | System sound 1395 |
| `swipe.mp3` | ⬜ Needed | System sound 1106 |
| `pop.mp3` | ⬜ Needed | System sound 1104 |

---

**Document Version:** 1.0  
**Last Updated:** Feb 21, 2025  
**Author:** TaskSnap Development Team
