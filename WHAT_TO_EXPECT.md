# 👀 What You Should See - Visual Guide

## 🎯 Quick Visual Checklist

### When You Launch the App:

#### 1️⃣ Dashboard - Top Right Corner
```
┌─────────────────────────────────────┐
│ Dashboard                    [�� ●] │  ← Sync Indicator
│                                      │
│  Good morning, User!         🔥 5    │
│  ┌────────────────────────────────┐ │
│  │ 🔥 5-Day Streak               │ │
│  └────────────────────────────────┘ │
│                                      │
│  ┌────────────────────────────────┐ │
│  │ ❤️  Ready for your check-in?  │ │  ← Prominent CTA
│  │     Share how you're feeling  │ │
│  │     today                 →   │ │
│  └────────────────────────────────┘ │
```

**Look for:**
- 🟢 Green dot with "Synced" text in top-right
- Large check-in card with heart icon
- Blue border around check-in card (if not completed)

---

#### 2️⃣ First-Time User (Delete & Reinstall)
```
┌─────────────────────────────────────┐
│                                      │
│         [Backdrop Overlay]          │
│                                      │
│  ┌──────────────────────────────┐  │
│  │        ✨                    │  │
│  │                              │  │
│  │  Take Your First Check-in   │  │
│  │                              │  │
│  │  Daily check-ins help you   │  │
│  │  track patterns...          │  │
│  │                              │  │
│  │  [  Start Check-in  ]       │  │  ← Blue button
│  │      Maybe Later            │  │
│  └──────────────────────────────┘  │
│                                      │
└─────────────────────────────────────┘
```

**Look for:**
- Centered card with shadow
- Sparkles icon at top
- Animated entrance (scales up)
- Feel haptic feedback when it appears

---

#### 3️⃣ Journal - Empty State
```
┌─────────────────────────────────────┐
│ Mindful Moments              ✨     │
│                                      │
│                                      │
│         [Sun Icon with Glow]        │
│                                      │
│    How are you feeling today?       │
│                                      │
│    I'm here to listen. Share        │
│    your thoughts...                 │
│                                      │
│   [ 😊 Good day        ]            │  ← Quick Prompts
│   [ 😔 Struggling      ]            │
│   [ 💭 Reflective      ]            │
│                                      │
└─────────────────────────────────────┘
```

**Look for:**
- 3 emoji buttons with rounded borders
- Welcoming empty state text
- Sun icon with gradient

---

#### 4️⃣ Settings - Logout Button
```
┌─────────────────────────────────────┐
│ Settings                        ✓   │
│                                      │
│  Profile                            │
│  ┌────────────────────────────────┐ │
│  │ John Doe                       │ │
│  │ john@example.com      🍎      │ │
│  │                                │ │
│  │ [🚪 Logout]                    │ │  ← Red button
│  └────────────────────────────────┘ │
│                                      │
│  Appearance                         │
│  ┌────────────────────────────────┐ │
│  │ Theme          [Auto ▼]       │ │
│  └────────────────────────────────┘ │
```

**Look for:**
- Red/destructive styled logout button
- Door icon next to "Logout" text
- Theme picker dropdown

---

## 🎨 Color Reference

### Semantic Colors You Should See:

**Success** (Green - #4CAF50)
- ✅ Sync indicator when synced
- ✅ Completed check-in status
- ✅ Positive feedback messages

**Error** (Red - #EF5350)
- ❌ Sync failed indicator
- ❌ Form validation errors
- ❌ Logout button

**Warning** (Orange - #FF9800)
- ⚠️ Offline indicator
- ⚠️ Caution messages

**Info** (Blue - #2196F3)
- ℹ️ Syncing status
- ℹ️ Information messages

---

## 🔘 Button Variants You Should See

### Throughout the App:

**Primary (Blue)**
- "Start Check-in" button
- "Send" in journal
- Main action buttons

**Secondary (Outlined)**
- "Skip Tour" on welcome
- "View More" buttons
- Less important actions

**Success (Green) - NEW!**
- "Complete" actions
- "Save" confirmations
- Positive completions

**Destructive (Red)**
- "Logout" button
- "Delete Account" button
- Dangerous actions

**Tertiary (Light Background)**
- Quick prompts in journal
- Filter chips
- Soft actions

---

## 📱 Animation Behaviors

### What Should Animate:

1. **FTUE Overlay Entrance**
   - Scales from 0.8 → 1.0
   - Fades in opacity 0 → 1
   - Spring animation (bouncy)
   - Haptic feedback on appear

2. **Check-in Card**
   - Subtle pulse on border when active
   - Checkmark bounces when completed

3. **Sync Indicator**
   - Spinner rotates when syncing
   - Color transitions smoothly
   - "Synced" fades in

4. **Buttons**
   - Scale down slightly on press (0.96)
   - Fade opacity on press (0.8)
   - Spring back on release

---

## 🧪 Interactive Tests

### Test These Interactions:

1. **Sync Indicator Click**
   - Tap on "Synced" indicator
   - Should do nothing (just status display)
   - If failed, "Retry" button should appear

2. **FTUE Overlay**
   - Tap backdrop → Dismisses
   - Tap "Maybe Later" → Dismisses
   - Tap "Start Check-in" → Opens assessment
   - After dismiss → Never shows again

3. **Check-in Card**
   - Tap anywhere on card → Opens assessment
   - After completion → Shows green checkmark
   - Border disappears when completed

4. **Quick Prompts**
   - Tap "😊 Good day" → Fills message field
   - Cursor should be at end of text
   - Can immediately send or edit

---

## ⚡ Performance Expectations

### Should Feel Fast:

- **App launch**: < 2 seconds
- **Dashboard load**: < 1 second (with cache)
- **FTUE animation**: Smooth 60fps
- **Transitions**: < 300ms
- **Button feedback**: Instant (< 100ms)

---

## 🐛 Common Issues & Solutions

### If You Don't See FTUE Overlay:

**Check:**
1. Did you delete the app first?
2. Is UserDefaults clean?
3. Do you have existing assessments?

**Fix:**
```bash
# Reset UserDefaults in simulator
xcrun simctl privacy booted reset all ElAmir.Depresso
```

### If Sync Indicator Missing:

**Check:**
1. Is it hidden behind something?
2. View hierarchy in Xcode debugger
3. Check DashboardView.swift line 54-60

### If Colors Look Wrong:

**Check:**
1. Dark mode vs Light mode
2. Color space settings
3. DS+Color.swift hex values

---

## ✅ Final Checklist

Before marking as complete:

- [ ] Sync indicator visible and functional
- [ ] FTUE shows for new users
- [ ] FTUE dismisses properly
- [ ] Logout button exists
- [ ] Journal prompts visible
- [ ] Check-in CTA prominent
- [ ] Colors are semantic and consistent
- [ ] Buttons have clear hierarchy
- [ ] Animations are smooth
- [ ] No crashes or freezes
- [ ] Dark mode works correctly
- [ ] Landscape works (iPhone)
- [ ] iPad layout acceptable

---

## 📸 Screenshot Checklist

If everything looks good, capture:

1. Dashboard with sync indicator
2. FTUE overlay (first-time)
3. Check-in CTA card
4. Journal empty state with prompts
5. Settings with logout button
6. Button variants showcase
7. Dark mode versions

---

**All features are implemented and ready to test!** 🎉
