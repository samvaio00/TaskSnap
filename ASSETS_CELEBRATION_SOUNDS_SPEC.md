# TaskSnap - Celebration Theme Sounds Specification 🎉

## Overview
Theme-specific sound effects that play during celebration animations (task completion, achievements). Each celebration theme has its own unique sound that matches the visual style.

**Location:** `TaskSnap/Resources/Sounds/Celebrations/`  
**Format:** MP3 (192 kbps)  
**Total Estimated Size:** ~1-2 MB

---

## Required Sound Files

### 1. Classic Success Sound
| Property | Value |
|----------|-------|
| **Filename** | `success.mp3` |
| **Theme** | Classic |
| **Duration** | 300-500 ms |
| **Description** | Clean, simple success chime. Universal positive sound that works with any celebration style. |
| **Usage** | Default theme, general celebrations |
| **Mood** | Positive, clean, professional |
| **Visual Match** | Classic confetti with standard colors |
| **Reference** | iOS success sound, pleasant bell, marimba |

**Requirements:**
- Single clear tone or simple two-tone
- Clean, not muddy
- Mid-range frequency
- Short and sweet

---

### 2. Party Horn Sound
| Property | Value |
|----------|-------|
| **Filename** | `party_horn.mp3` |
| **Theme** | Party |
| **Duration** | 400-700 ms |
| **Description** | Fun party horn or whistle sound. Upbeat and energetic like a celebration. |
| **Usage** | Party theme with rainbow confetti |
| **Mood** | Fun, energetic, celebratory |
| **Visual Match** | Rainbow confetti, wavy motion |
| **Reference** | Party horn, kazoo, slide whistle, birthday party |

**Requirements:**
- Upward pitch sweep
- Playful tone
- Not too long
- Can include party atmosphere

---

### 3. Fireworks Sound
| Property | Value |
|----------|-------|
| **Filename** | `fireworks.mp3` |
| **Theme** | Fire |
| **Duration** | 600-900 ms |
| **Description** | Firework explosion with crackle. Should feel hot and explosive like fire. |
| **Usage** | Fire theme with rising flames |
| **Mood** | Hot, explosive, powerful |
| **Visual Match** | Rising flames, fire particles |
| **Reference** | Firework pop, firecracker, sparkler crackle |

**Requirements:**
- Initial pop/explosion
- Crackle tail
- Not too loud or harsh
- Warm frequency content

---

### 4. Chime Sound
| Property | Value |
|----------|-------|
| **Filename** | `chime.mp3` |
| **Theme** | Diamond |
| **Duration** | 500-800 ms |
| **Description** | Crystal or glass chime sound. Elegant and sparkly like diamonds. |
| **Usage** | Diamond theme with sparkle effects |
| **Mood** | Elegant, sparkly, refined |
| **Visual Match** | Sparkle effects, diamond shapes |
| **Reference** | Crystal glass, wind chime, triangle instrument |

**Requirements:**
- Clear, ringing tone
- Slight reverb for sparkle
- High frequency content
- Pleasant decay

---

### 5. Celebration Sound
| Property | Value |
|----------|-------|
| **Filename** | `celebration.mp3` |
| **Theme** | Rainbow |
| **Duration** | 500-800 ms |
| **Description** | Upbeat, colorful celebration sound. Happy and inclusive. |
| **Usage** | Rainbow theme with wave motion |
| **Mood** | Happy, colorful, inclusive |
| **Visual Match** | Rainbow confetti, wave motion |
| **Reference** | Game win sound, happy jingle, bells |

**Requirements:**
- Major key (happy)
- Multiple tones (colorful feel)
- Medium tempo
- Positive energy

---

### 6. Birds Sound
| Property | Value |
|----------|-------|
| **Filename** | `birds.mp3` |
| **Theme** | Nature |
| **Duration** | 600-1000 ms |
| **Description** | Gentle birds chirping or nature sound. Organic and peaceful. |
| **Usage** | Nature theme with floating leaves |
| **Mood** | Peaceful, natural, organic |
| **Visual Match** | Floating leaves, flower particles |
| **Reference** | Songbirds, forest morning, gentle chirping |

**Requirements:**
- Gentle bird sounds
- Not harsh or squawking
- Natural, not synthetic
- Peaceful mood

---

### 7. Electric Sound
| Property | Value |
|----------|-------|
| **Filename** | `electric.mp3` |
| **Theme** | Neon |
| **Duration** | 300-500 ms |
| **Description** | Electric zap or synth sound. Modern and energetic. |
| **Usage** | Neon theme with electric zigzag motion |
| **Mood** | Electric, modern, energetic |
| **Visual Match** | Electric zigzag, neon colors |
| **Reference** | Synth zap, electric sound, 80s synth, sci-fi |

**Requirements:**
- Synth-based
- Quick attack
- Modern/digital sound
- Not too harsh

---

### 8. Triumph Sound
| Property | Value |
|----------|-------|
| **Filename** | `triumph.mp3` |
| **Theme** | Gold |
| **Duration** | 700-1000 ms |
| **Description** | Royal fanfare or trumpet sound. Epic and prestigious. |
| **Usage** | Gold theme with royal celebration |
| **Mood** | Epic, royal, prestigious |
| **Visual Match** | Gold confetti, crown particles |
| **Reference** | Trumpet fanfare, royal announcement, brass |

**Requirements:**
- Brass/orchestral sound
- Triumphant feeling
- Slightly longer
- Epic quality

---

## Technical Specifications

### Audio Format
```
Format:        MP3
Bitrate:       192 kbps
Sample Rate:   44.1 kHz
Channels:      Stereo (2.0)
Duration:      300-1000 ms per file
File Size:     ~100-300 KB per file
Total Size:    ~1-2 MB for all 8 files
```

### Volume Normalization
- **Target LUFS:** -14 LUFS (slightly louder than ambient)
- **True Peak:** -1 dBTP
- Should be more prominent than background sounds

---

## File Structure

```
TaskSnap/
└── TaskSnap/
    └── Resources/
        └── Sounds/
            └── Celebrations/
                ├── success.mp3      (Classic)
                ├── party_horn.mp3   (Party)
                ├── fireworks.mp3    (Fire)
                ├── chime.mp3        (Diamond)
                ├── celebration.mp3  (Rainbow)
                ├── birds.mp3        (Nature)
                ├── electric.mp3     (Neon)
                └── triumph.mp3      (Gold)
```

---

## Implementation

The app uses `CelebrationTheme.soundEffect` to determine which sound to play:

```swift
// In CelebrationTheme enum
var soundEffect: String? {
    switch self {
    case .classic: return "success"
    case .party: return "party_horn"
    case .fire: return "fireworks"
    case .diamond: return "chime"
    case .rainbow: return "celebration"
    case .nature: return "birds"
    case .neon: return "electric"
    case .gold: return "triumph"
    }
}
```

Played via `SoundEffectManager` during animations.

---

## Theme-Sound Matching

| Theme | Visual Style | Sound Style |
|-------|--------------|-------------|
| Classic | Standard confetti | Clean chime |
| Party | Rainbow, wavy | Party horn |
| Fire | Rising flames | Fireworks |
| Diamond | Sparkle, elegant | Crystal chime |
| Rainbow | Colorful waves | Happy jingle |
| Nature | Floating leaves | Birds |
| Neon | Electric zigzag | Synth zap |
| Gold | Royal, crowns | Trumpet fanfare |

---

## Sourcing Options

### Free Resources
| Source | URL | License |
|--------|-----|---------|
| **Freesound.org** | freesound.org | CC0 / CC-BY |
| **Zapsplat** | zapsplat.com | Free with signup |
| **OpenGameArt** | opengameart.org | Various |

### Search Terms
- `"success" "chime" "bell" "positive"`
- `"party horn" "celebration" "birthday"`
- `"fireworks" "explosion" "crackle"`
- `"crystal" "chime" "glass" "sparkle"`
- `"birds" "chirping" "nature" "gentle"`
- `"electric" "zap" "synth" "sci-fi"`
- `"fanfare" "trumpet" "royal" "triumph"`

### Game Sound Packs
Many game sound effect packs include celebration sounds:
- "UI Sounds" packs
- "Game Effects" collections
- "Mobile Game Audio" bundles

---

## Quality Checklist

Before adding to project:
- [ ] Matches theme's visual style
- [ ] Not annoying when heard repeatedly
- [ ] Clear and distinct from other sounds
- [ ] Appropriate length (not too long)
- [ ] Filename matches exactly
- [ ] Volume balanced with other sounds
- [ ] No clipping or distortion

---

## Current Status

| File | Status | Theme |
|------|--------|-------|
| `success.mp3` | ⬜ Needed | Classic |
| `party_horn.mp3` | ⬜ Needed | Party |
| `fireworks.mp3` | ⬜ Needed | Fire |
| `chime.mp3` | ⬜ Needed | Diamond |
| `celebration.mp3` | ⬜ Needed | Rainbow |
| `birds.mp3` | ⬜ Needed | Nature |
| `electric.mp3` | ⬜ Needed | Neon |
| `triumph.mp3` | ⬜ Needed | Gold |

**Current Behavior:** If celebration sounds are not found, the app falls back to standard UI sounds or silence.

---

## Optional: Per-Theme Music

For future enhancement, each theme could have a short musical jingle:
- 2-3 seconds
- Composed specifically for the theme
- More memorable than sound effects

This is a post-launch consideration.

---

**Document Version:** 1.0  
**Last Updated:** Feb 21, 2025  
**Author:** TaskSnap Development Team
