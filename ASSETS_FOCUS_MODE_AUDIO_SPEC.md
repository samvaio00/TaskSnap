# TaskSnap - Focus Mode Background Sounds Specification 🎧

## Overview
Ambient background sounds for the Focus Mode feature. These are looping audio tracks designed to help users concentrate during focus sessions.

**Location:** `TaskSnap/Resources/Sounds/Focus/`  
**Format:** MP3 (192 kbps)  
**Looping:** All files must loop seamlessly  
**Total Estimated Size:** ~15-25 MB

---

## Required Audio Files

### 1. Rain Loop
| Property | Value |
|----------|-------|
| **Filename** | `rain_loop.mp3` |
| **Theme** | Gentle Rainfall |
| **Duration** | 3-5 minutes |
| **Description** | Soft, steady rainfall without thunder or heavy downpour. Should be calming and consistent. |
| **Usage** | Focus sound option for deep concentration |
| **Mood** | Calm, cozy, focusing |
| **Reference** | Light rain on leaves, gentle shower, rain on window |

**Requirements:**
- No thunder or lightning sounds
- Consistent volume throughout
- Natural rain texture (not synthetic-sounding)
- Seamless loop point (start and end at same volume/texture)
- Gentle, not heavy rain

---

### 2. Cafe Loop
| Property | Value |
|----------|-------|
| **Filename** | `cafe_loop.mp3` |
| **Theme** | Coffee Shop Ambience |
| **Duration** | 3-5 minutes |
| **Description** | Distant conversation, clinking cups, espresso machine sounds, footsteps. Should feel like a busy but not chaotic cafe. |
| **Usage** | Focus sound for people who work well with background chatter |
| **Mood** | Social, productive, warm |
| **Reference** | Starbucks/Coffee shop background noise, library cafe |

**Requirements:**
- Indistinct conversation (no clear words)
- Occasional coffee shop sounds (steam wand, cups clinking)
- Low to medium volume
- Should not be distracting
- Seamless loop

---

### 3. White Noise Loop
| Property | Value |
|----------|-------|
| **Filename** | `whitenoise_loop.mp3` |
| **Theme** | Sound Masking |
| **Duration** | 5-10 minutes |
| **Description** | Steady, unchanging white noise sound. Used for masking distractions. Can be true white noise or pink noise (more natural). |
| **Usage** | Noise cancellation, blocking external distractions |
| **Mood** | Neutral, blocking |
| **Reference** | TV static, fan hum, sound masking machines, airplane cabin |

**Requirements:**
- True white noise OR pink noise (preferred - less harsh)
- Absolutely seamless loop (no variation possible)
- Consistent volume
- No modulation or changes
- Can be longer duration due to uniformity

---

### 4. Forest Loop
| Property | Value |
|----------|-------|
| **Filename** | `forest_loop.mp3` |
| **Theme** | Forest Nature Sounds |
| **Duration** | 3-5 minutes |
| **Description** | Birds chirping, wind through trees, rustling leaves. Peaceful woodland atmosphere. |
| **Usage** | Calming focus environment, nature therapy |
| **Mood** | Peaceful, natural, grounding |
| **Reference** | Morning forest, nature reserve, woodland trail |

**Requirements:**
- Gentle bird sounds (not squawking or loud)
- Wind in trees (no strong gusts)
- No sudden loud animal sounds
- Natural, non-repetitive bird patterns
- Seamless loop

---

### 5. Ocean Loop
| Property | Value |
|----------|-------|
| **Filename** | `ocean_loop.mp3` |
| **Theme** | Ocean Waves |
| **Duration** | 2-4 minutes |
| **Description** | Gentle waves lapping on shore, distant seagulls (optional). Rhythmic and meditative. |
| **Usage** | Meditation, stress relief, deep focus |
| **Mood** | Calm, rhythmic, vast |
| **Reference** | Beach shoreline, gentle tide, peaceful ocean |

**Requirements:**
- Gentle waves (not crashing surf)
- Rhythmic pattern (breath-like quality)
- Optional very distant seagulls (barely audible)
- Seamless wave cycle
- Consistent rhythm

---

### 6. Fireplace Loop
| Property | Value |
|----------|-------|
| **Filename** | `fireplace_loop.mp3` |
| **Theme** | Crackling Fireplace |
| **Duration** | 2-4 minutes |
| **Description** | Wood fire crackling and popping, low fire roar. Cozy and warm atmosphere. |
| **Usage** | Cozy focus sessions, winter vibes, relaxation |
| **Mood** | Cozy, warm, comfortable |
| **Reference** | Indoor fireplace, campfire (without voices) |

**Requirements:**
- Natural crackling (not too frequent)
- Low fire rumble in background
- No sudden loud pops
- Warm, comforting tone
- Seamless loop

---

## Technical Specifications

### Audio Format
```
Format:        MP3
Bitrate:       192 kbps (VBR acceptable)
Sample Rate:   44.1 kHz (standard)
Channels:      Stereo (2.0) preferred, Mono acceptable
Duration:      2-5 minutes per file (see individual specs)
File Size:     ~2-5 MB per file (at 192 kbps)
Total Size:    ~15-25 MB for all 6 files
```

### Looping Requirements (CRITICAL)
All audio files must:
1. **Start and end at zero-crossing** (no click/pop at loop point)
2. **Have no fade in/out** at beginning/end (or fade must match perfectly)
3. **Maintain consistent volume** throughout
4. **Avoid jarring elements** that become annoying when repeated
5. **Be tested looping for 10+ minutes** without noticeable repetition

### Volume Normalization
All files should be normalized to similar perceived loudness:
- **Target LUFS:** -16 LUFS (integrated)
- **True Peak:** -1 dBTP
- This ensures consistent volume when switching between sounds

---

## File Structure

```
TaskSnap/
└── TaskSnap/
    └── Resources/
        └── Sounds/
            └── Focus/
                ├── rain_loop.mp3
                ├── cafe_loop.mp3
                ├── whitenoise_loop.mp3
                ├── forest_loop.mp3
                ├── ocean_loop.mp3
                └── fireplace_loop.mp3
```

---

## Implementation

The app uses `FocusSoundManager` to play background sounds:

```swift
FocusSoundManager.shared.play(sound: .rain)
FocusSoundManager.shared.setVolume(0.7)
```

**Features:**
- Seamless looping (AVAudioPlayer with `-1` loops)
- Volume control (0-100%)
- Fade in/out on start/stop
- Mixes with other app audio

---

## Sourcing Options

### Free Resources (Creative Commons)
| Source | URL | License | Quality |
|--------|-----|---------|---------|
| **Freesound.org** | freesound.org | CC0 / CC-BY | Variable |
| **Pixabay** | pixabay.com/sound-effects | Pixabay License | Good |
| **Zapsplat** | zapsplat.com | Free with signup | Professional |
| **BBC Sound Effects** | bbcsfx.acropolis.org.uk | RemArc License | Archive |

### Search Terms
Use these keywords on sound libraries:
- `"rain loop" "seamless" "ambience" "nature"`
- `"coffee shop" "cafe ambience" "background chatter" "indistinct"`
- `"white noise" "pink noise" "sound masking" "seamless loop"`
- `"forest ambience" "nature sounds" "birds" "wind trees"`
- `"ocean waves" "beach ambience" "gentle waves" "shoreline"`
- `"fireplace" "crackling fire" "cozy fire" "wood fire"`

### Paid Resources (Higher Quality)
| Source | Price | Quality |
|--------|-------|---------|
| **Epidemic Sound** | $15/month | Professional |
| **Artlist** | $17/month | Professional |
| **AudioJungle** | $5-20 per track | Variable |
| **Soundsnap** | $29/month | Professional |
| **Pro Sound Effects** | $499 one-time | Premium |

### Recommended Paid Packs
- "Nature Sounds" packs
- "Ambience Loops" collections
- "Cafe/Restaurant" sound packs
- "Fireplace" specialty packs

---

## Quality Checklist

Before adding to project:
- [ ] File plays without errors in any media player
- [ ] Loop is seamless (test 5+ loops in a row)
- [ ] No click/pop at loop point
- [ ] Volume is consistent throughout
- [ ] No sudden loud sounds or jarring elements
- [ ] File is in MP3 format
- [ ] Filename matches exactly (case-sensitive)
- [ ] License allows commercial use in apps
- [ ] Duration is appropriate (2-5 minutes)
- [ ] File size is reasonable (< 10 MB per file)
- [ ] Not annoying when looped for 30+ minutes

---

## Current Status

| File | Status | Fallback |
|------|--------|----------|
| `rain_loop.mp3` | ⬜ Needed | Silence |
| `cafe_loop.mp3` | ⬜ Needed | Silence |
| `whitenoise_loop.mp3` | ⬜ Needed | Procedural noise (can be generated) |
| `forest_loop.mp3` | ⬜ Needed | Silence |
| `ocean_loop.mp3` | ⬜ Needed | Silence |
| `fireplace_loop.mp3` | ⬜ Needed | Silence |

**Current Behavior:** If audio files are not found, the app falls back to "None" (no sound) option.

---

## Alternative: Procedural Generation

For white noise specifically, the app could generate it procedurally using `AVAudioEngine`:

```swift
// Generate pink/white noise in real-time
// Pros: No file size, infinite loop, customizable
// Cons: Uses CPU, may sound synthetic
```

This is implemented as a fallback option.

---

**Document Version:** 1.0  
**Last Updated:** Feb 21, 2025  
**Author:** TaskSnap Development Team
