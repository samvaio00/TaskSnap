# TaskSnap - Audio Assets Specification 🎵

## Overview
This document specifies all audio assets needed for the Focus Mode background sounds feature.

**Location:** `TaskSnap/Resources/Sounds/`  
**Format:** MP3 (128-192 kbps)  
**Looping:** All files should loop seamlessly  
**Total Estimated Size:** ~15-25 MB

---

## Required Audio Files

### 1. Rain Loop
| Property | Value |
|----------|-------|
| **Filename** | `rain_loop.mp3` |
| **Theme** | Gentle Rainfall |
| **Description** | Soft, steady rainfall without thunder or heavy downpour. Should be calming and consistent. |
| **Usage** | Focus sound option for deep concentration |
| **Length** | 2-5 minutes (looping) |
| **Mood** | Calm, cozy, focusing |
| **Reference** | Light rain on leaves, gentle shower |

**Requirements:**
- No thunder or lightning sounds
- Consistent volume throughout
- Natural rain texture (not synthetic-sounding)
- Seamless loop point

---

### 2. Cafe Loop
| Property | Value |
|----------|-------|
| **Filename** | `cafe_loop.mp3` |
| **Theme** | Coffee Shop Ambience |
| **Description** | Distant conversation, clinking cups, espresso machine sounds, footsteps. Should feel like a busy but not chaotic cafe. |
| **Usage** | Focus sound for people who work well with background chatter |
| **Length** | 3-5 minutes (looping) |
| **Mood** | Social, productive, warm |
| **Reference** | Starbucks/Coffee shop background noise |

**Requirements:**
- Indistinct conversation (no clear words)
- Occasional coffee shop sounds (steam wand, cups)
- Low to medium volume
- Should not be distracting

---

### 3. White Noise Loop
| Property | Value |
|----------|-------|
| **Filename** | `whitenoise_loop.mp3` |
| **Theme** | Pure White Noise |
| **Description** | Steady, unchanging white noise sound. Used for masking distractions. |
| **Usage** | Noise cancellation, blocking external distractions |
| **Length** | 5-10 minutes (looping) |
| **Mood** | Neutral, focusing, sterile |
| **Reference** | TV static, fan hum, sound masking machines |

**Requirements:**
- True white noise (equal energy across frequencies)
- OR pink noise (more natural, less harsh)
- Absolutely seamless loop (no variation)
- Consistent volume

---

### 4. Forest Loop
| Property | Value |
|----------|-------|
| **Filename** | `forest_loop.mp3` |
| **Theme** | Forest Nature Sounds |
| **Description** | Birds chirping, wind through trees, rustling leaves. Peaceful woodland atmosphere. |
| **Usage** | Calming focus environment, nature therapy |
| **Length** | 3-5 minutes (looping) |
| **Mood** | Peaceful, natural, grounding |
| **Reference** | Morning forest, nature reserve |

**Requirements:**
- Gentle bird sounds (not squawking)
- Wind in trees (no strong gusts)
- No sudden loud animal sounds
- Natural, non-repetitive bird patterns

---

### 5. Ocean Loop
| Property | Value |
|----------|-------|
| **Filename** | `ocean_loop.mp3` |
| **Theme** | Ocean Waves |
| **Description** | Gentle waves lapping on shore, distant seagulls (optional). Rhythmic and meditative. |
| **Usage** | Meditation, stress relief, deep focus |
| **Length** | 2-4 minutes (looping) |
| **Mood** | Calm, rhythmic, vast |
| **Reference** | Beach shoreline, gentle tide |

**Requirements:**
- Gentle waves (not crashing surf)
- Rhythmic pattern (breath-like)
- Optional very distant seagulls
- Seamless wave cycle

---

### 6. Fireplace Loop
| Property | Value |
|----------|-------|
| **Filename** | `fireplace_loop.mp3` |
| **Theme** | Crackling Fireplace |
| **Description** | Wood fire crackling and popping, low fire roar. Cozy and warm atmosphere. |
| **Usage** | Cozy focus sessions, winter vibes |
| **Length** | 2-4 minutes (looping) |
| **Mood** | Cozy, warm, comfortable |
| **Reference** | Indoor fireplace, campfire (without voices) |

**Requirements:**
- Natural crackling (not too frequent)
- Low fire rumble in background
- No sudden loud pops
- Warm, comforting tone

---

## Optional Enhancement Files

These are nice-to-have for future versions:

### 7. Pink Noise Loop (Alternative to White Noise)
| Property | Value |
|----------|-------|
| **Filename** | `pinknoise_loop.mp3` |
| **Theme** | Pink Noise |
| **Description** | Like white noise but with reduced high frequencies. More natural and less harsh. |
| **Usage** | Alternative to white noise for sensitive ears |
| **Length** | 5-10 minutes |

### 8. Binaural Focus (Advanced)
| Property | Value |
|----------|-------|
| **Filename** | `binaural_focus.mp3` |
| **Theme** | Binaural Beats (40Hz Gamma) |
| **Description** | Binaural beats at 40Hz frequency. Requires headphones. |
| **Usage** | Scientific focus enhancement |
| **Length** | 10-30 minutes |
| **Note** | Research-backed for focus, but specialized use |

---

## Technical Specifications

### Audio Format
```
Format:        MP3
Bitrate:       128-192 kbps (VBR acceptable)
Sample Rate:   44.1 kHz (standard)
Channels:      Stereo (2.0) preferred, Mono acceptable
Duration:      2-5 minutes per file
File Size:     ~2-5 MB per file (at 192 kbps)
```

### Looping Requirements
All audio files must:
1. **Start and end at zero-crossing** (no click/pop at loop point)
2. **Have no fade in/out** at beginning/end (or match perfectly)
3. **Maintain consistent volume** throughout
4. **Avoid jarring elements** that become annoying when repeated

### Volume Levels
All files should be normalized to similar perceived loudness:
- **Target LUFS:** -16 LUFS (integrated)
- **True Peak:** -1 dBTP
- This ensures consistent volume across all sounds

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
- `"rain loop" "seamless" "ambience"`
- `"coffee shop" "cafe ambience" "background chatter"`
- `"white noise" "pink noise" "sound masking"`
- `"forest ambience" "nature sounds" "birds"`
- `"ocean waves" "beach ambience" "gentle waves"`
- `"fireplace" "crackling fire" "cozy fire"`

### Paid Resources (Higher Quality)
| Source | Price | Quality |
|--------|-------|---------|
| **Epidemic Sound** | $15/month | Professional |
| **Artlist** | $17/month | Professional |
| **AudioJungle** | $5-20 per track | Variable |
| **Soundsnap** | $29/month | Professional |
| **Pro Sound Effects** | $499 one-time | Premium |

---

## File Structure

```
TaskSnap/
└── TaskSnap/
    └── Resources/
        ├── Animations/          ✅ Already have MP4s
        │   ├── badge_unlock.mp4
        │   ├── capture_success.mp4
        │   ├── ...
        │   └── task_complete.mp4
        │
        └── Sounds/              ⬜ NEED THESE FILES
            ├── rain_loop.mp3
            ├── cafe_loop.mp3
            ├── whitenoise_loop.mp3
            ├── forest_loop.mp3
            ├── ocean_loop.mp3
            └── fireplace_loop.mp3
```

---

## Implementation Status

| File | Status | Fallback |
|------|--------|----------|
| `rain_loop.mp3` | ⬜ Needed | Procedural noise |
| `cafe_loop.mp3` | ⬜ Needed | Silence |
| `whitenoise_loop.mp3` | ⬜ Needed | Procedural noise |
| `forest_loop.mp3` | ⬜ Needed | Silence |
| `ocean_loop.mp3` | ⬜ Needed | Silence |
| `fireplace_loop.mp3` | ⬜ Needed | Silence |

**Current Behavior:** If audio files are not found, the app silently falls back to no sound ("None" option).

---

## Quality Checklist

Before adding audio files to the project, verify:

- [ ] File plays without errors in any media player
- [ ] Loop is seamless (no click/pop when repeating)
- [ ] Volume is consistent throughout
- [ ] No sudden loud sounds or jarring elements
- [ ] File is in MP3 format
- [ ] Filename matches exactly (case-sensitive)
- [ ] License allows commercial use in apps
- [ ] Duration is appropriate (2-5 minutes)
- [ ] File size is reasonable (< 10 MB per file)

---

## Next Steps

1. **Source Audio Files**
   - Download from free resources OR
   - Purchase from paid libraries OR
   - Record original sounds

2. **Quality Check**
   - Verify seamless looping
   - Normalize volume levels
   - Check file formats

3. **Add to Project**
   ```bash
   mkdir -p TaskSnap/Resources/Sounds/
   cp *.mp3 TaskSnap/Resources/Sounds/
   ```

4. **Test in App**
   - Each sound plays correctly
   - Volume control works
   - Looping is seamless
   - No memory leaks

---

**Document Version:** 1.0  
**Last Updated:** Feb 20, 2025  
**Author:** TaskSnap Development Team

