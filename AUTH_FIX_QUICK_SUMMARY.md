# AUTH FIX - Quick Summary

## What Was Wrong?

### 🐛 Bug 1: Edit Profile Shows for Guests
You could see "Edit Profile" even in guest mode - shouldn't be there!

**Why:** No check to hide it for guest users

**Fixed:** Added `if !store.isGuest` condition to hide button in guest mode

---

### 🐛 Bug 2: Apple Linking Doesn't Work
When you linked with Apple, it said "success" but you stayed in guest mode.

**Why:** The new authentication token from Apple was NEVER saved! 
- Backend sent you a proper Apple-authenticated token
- iOS app just threw it away and kept using the old guest token
- Backend kept seeing you as guest because of old token

**Fixed:** 
1. Capture the new token from backend: `let newToken = try await APIClient.linkAppleAccount(...)`
2. Save it properly: `UserManager.shared.setSessionToken(newToken, isAppleAuth: true)`

---

### 🐛 Bug 3: Backend Schema Mismatch
Database had column `full_name` but code tried to read/write `name`

**Why:** Migration created wrong column name

**Fixed:** 
- Updated migration to create `name` column
- Created new migration to rename existing `full_name` → `name`

---

## What Changed?

### iOS App (4 files):
1. **UserManager.swift** - Now tracks `isLinkedToApple` status
2. **SettingsFeature.swift** - Saves Apple token properly, better guest detection
3. **SettingsView.swift** - Hides Edit Profile for guests
4. **AuthenticationFeature.swift** - Marks Apple tokens as authenticated

### Backend (2 files):
1. **Migration 011** - Fixed to create `name` column
2. **Migration 013** - New migration to fix existing databases

---

## What To Do Now?

### 1. Run Backend Migration (REQUIRED!)
```bash
cd depresso-backend
./run-migration-013.sh
```

This fixes the database schema so names are saved properly.

### 2. Rebuild iOS App
Your changes are saved. Build and run in Xcode.

### 3. Test It
- Start fresh (or logout)
- Skip to guest mode → Edit Profile should be HIDDEN
- Link with Apple → Should show your name and Edit Profile button
- Restart app → Should still show as authenticated (not guest)

---

## Key Fix Details

**Before Linking:**
- Token: `{ userId: "abc123" }`
- isLinkedToApple: `false`
- Shows: Guest Mode
- Edit Profile: Hidden ❌

**After Linking:**
- Token: `{ userId: "abc123", appleUserId: "001824.xxx" }` ← NEW TOKEN SAVED
- isLinkedToApple: `true`
- Shows: Your Name + Apple Icon
- Edit Profile: Visible ✅

**The Critical Line:**
```swift
// Line 199 in SettingsFeature.swift - THIS WAS MISSING!
UserManager.shared.setSessionToken(newToken, isAppleAuth: true)
```

Without this line, you got a new token but never used it. Now it's saved and you're properly authenticated! 🎉
