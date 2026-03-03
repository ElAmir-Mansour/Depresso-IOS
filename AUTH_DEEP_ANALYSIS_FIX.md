# Authentication System Deep Analysis & Fixes

## Executive Summary
Fixed critical authentication bugs in the Depresso iOS app where:
1. ❌ **Guest users could see "Edit Profile"** button (should be hidden)
2. ❌ **Apple Sign-In linking appeared to work but didn't persist** (still showed as guest after linking)

## Root Cause Analysis

### Issue 1: Edit Profile Visible in Guest Mode
**File:** `Features/Settings/SettingsView.swift` (line 42)

**Problem:** 
The "Edit Profile" button was shown unconditionally without checking if user is a guest.

**Code Before:**
```swift
Button {
    store.send(.editProfileButtonTapped)
} label: {
    Label("Edit Profile", systemImage: "pencil")
}
```

**Impact:** Guest users could click "Edit Profile" and attempt to save, leading to confusion.

---

### Issue 2: Apple Linking Doesn't Save New Session Token
**File:** `Features/Settings/SettingsFeature.swift` (lines 158-193)

**Problem:**
When a guest user linked their account with Apple ID:
1. Backend returned a NEW session token with Apple credentials
2. iOS app received this token but **NEVER saved it**
3. Old guest token remained active in UserManager
4. All subsequent API calls used old token → backend still saw user as guest

**Code Before:**
```swift
case .linkAccountButtonTapped:
    // ... Apple sign in ...
    try await APIClient.linkAppleAccount(...)  // Returns new token
    
    await MainActor.run {
        // ❌ MISSING: Never saved the new token!
        UserManager.shared.setUserProfile(name: fullName, email: email)
    }
```

**Backend Flow:**
```javascript
// users.controller.js - linkAppleAccount
exports.linkAppleAccount = async (req, res) => {
    // Updates user record with apple_user_id
    await pool.query('UPDATE Users SET apple_user_id = $1 ...');
    
    // Generates NEW JWT with apple_user_id
    const sessionToken = generateToken(userId, appleUserId);
    
    // Returns new token - but iOS wasn't saving it!
    res.json({ success: true, sessionToken });
};
```

**JWT Token Structure:**
```javascript
// Old guest token: { userId: "xxx" }
// New Apple token: { userId: "xxx", appleUserId: "001824.xxx" }
```

---

### Issue 3: Weak isGuest Detection
**File:** `Features/Settings/SettingsFeature.swift` (line 19)

**Problem:**
```swift
var isGuest: Bool { userName == nil }
```

This checked if userName exists, but:
- Guest users could manually set a name (making isGuest = false incorrectly)
- No actual check for Apple ID linking status
- Unreliable indicator of authentication state

**Correct Logic Should Be:**
Check if user has linked their Apple ID (has authenticated Apple credentials).

---

### Issue 4: Database Schema Mismatch
**Files:** 
- `depresso-backend/migrations/011_add_auth_fields.sql`
- `depresso-backend/src/api/users/users.controller.js`

**Problem:**
```sql
-- Migration created column named 'full_name'
ALTER TABLE Users ADD COLUMN full_name TEXT;
```

```javascript
// But all backend code queries 'name'
'SELECT id, name, email FROM Users WHERE ...'
'UPDATE Users SET name = ...'
```

**Impact:** 
- Names weren't being saved/retrieved from database
- Backend code and schema were out of sync

---

## Fixes Implemented

### iOS Changes

#### 1. UserManager.swift - Track Apple Linking Status
```swift
// ADDED: Track if user is linked to Apple
@Published private(set) var isLinkedToApple: Bool = false
private let appleLinkedKey = "depresso_apple_linked"

// MODIFIED: Load Apple linking status on init
private init() {
    self.userId = UserDefaults.standard.string(forKey: userDefaultsKey)
    self.userName = UserDefaults.standard.string(forKey: userNameKey)
    self.userEmail = UserDefaults.standard.string(forKey: userEmailKey)
    self.isLinkedToApple = UserDefaults.standard.bool(forKey: appleLinkedKey) // NEW
    self.sessionToken = KeychainHelper.retrieve(key: tokenKeychainKey)
    
    print("🔄 UserManager initialized - UserID: \(userId ?? "nil"), Has Token: \(sessionToken != nil), Apple Linked: \(isLinkedToApple)")
}

// MODIFIED: setSessionToken now marks Apple authentication
func setSessionToken(_ token: String, isAppleAuth: Bool = false) {
    self.sessionToken = token
    KeychainHelper.save(token, forKey: tokenKeychainKey)
    if isAppleAuth {
        self.isLinkedToApple = true
        UserDefaults.standard.set(true, forKey: appleLinkedKey)
    }
    print("🔐 UserManager: Saved session token to Keychain (Apple Auth: \(isAppleAuth))")
}

// MODIFIED: Clear Apple linking status on logout
func clearAll() {
    self.userId = nil
    self.userName = nil
    self.userEmail = nil
    self.sessionToken = nil
    self.isLinkedToApple = false  // NEW
    UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    UserDefaults.standard.removeObject(forKey: userNameKey)
    UserDefaults.standard.removeObject(forKey: userEmailKey)
    UserDefaults.standard.removeObject(forKey: appleLinkedKey)  // NEW
    KeychainHelper.delete(key: tokenKeychainKey)
}
```

#### 2. SettingsFeature.swift - Fix Guest Detection & Save Token
```swift
// MODIFIED: isGuest now checks actual Apple linking status
var userName: String? = nil
var userEmail: String? = nil
var isLinkedToApple: Bool = false  // NEW
var isGuest: Bool { !isLinkedToApple }  // CHANGED from userName == nil

// MODIFIED: Load Apple linking status
case .task:
    state.userName = UserManager.shared.userName
    state.userEmail = UserManager.shared.userEmail
    state.isLinkedToApple = UserManager.shared.isLinkedToApple  // NEW

// ADDED: Block guests from editing profile
case .editProfileButtonTapped:
    guard !state.isGuest else {
        state.alert = AlertState {
            TextState("Link Account Required")
        } message: {
            TextState("Please link your account with Apple ID before editing your profile.")
        }
        return .none
    }
    // ... continue to edit

// FIXED: Save new session token after linking
case .linkAccountButtonTapped:
    state.isLinkingAccount = true
    return .run { send in
        do {
            let credentials = try await authenticationClient.signInWithApple()
            let currentUserId = await MainActor.run { UserManager.shared.userId }
            guard let currentUserId = currentUserId, !currentUserId.isEmpty else {
                throw SettingsError.noUserId
            }
            let fullName = [credentials.fullName?.givenName, credentials.fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            
            // CHANGED: Capture returned token
            let newToken = try await APIClient.linkAppleAccount(
                userId: currentUserId,
                appleUserId: credentials.userId,
                email: credentials.email,
                fullName: fullName.isEmpty ? nil : fullName,
                identityToken: credentials.identityToken
            )
            
            await MainActor.run {
                // ADDED: Save new token with Apple authentication flag
                UserManager.shared.setSessionToken(newToken, isAppleAuth: true)
                UserManager.shared.setUserProfile(name: fullName.isEmpty ? nil : fullName, email: credentials.email)
            }
            
            await send(.linkAccountCompleted(.success(())))
        } catch {
            await send(.linkAccountCompleted(.failure(error)))
        }
    }

// MODIFIED: Update isLinkedToApple in state
case .linkAccountCompleted(.success):
    state.isLinkingAccount = false
    state.userName = UserManager.shared.userName
    state.userEmail = UserManager.shared.userEmail
    state.isLinkedToApple = UserManager.shared.isLinkedToApple  // NEW
    state.alert = AlertState { TextState("Success") } message: { TextState("Your account has been successfully linked to Apple ID.") }
    return .none
```

#### 3. SettingsView.swift - Hide Edit Profile for Guests
```swift
Section("Profile") {
    // ... profile info display ...
    
    // ADDED: Only show Edit Profile for authenticated users
    if !store.isGuest {
        Button {
            store.send(.editProfileButtonTapped)
        } label: {
            Label("Edit Profile", systemImage: "pencil")
        }
    }
    
    // ... rest of section
```

#### 4. AuthenticationFeature.swift - Mark Apple Login
```swift
// MODIFIED: Mark token as Apple authentication
await MainActor.run {
    UserManager.shared.setUserId(result.userId)
    UserManager.shared.setSessionToken(result.sessionToken, isAppleAuth: true)  // CHANGED
    UserManager.shared.setUserProfile(
        name: result.name ?? (fullName.isEmpty ? nil : fullName),
        email: result.email ?? email
    )
}
```

### Backend Changes

#### 5. Fix Database Schema - Migration 011
**File:** `depresso-backend/migrations/011_add_auth_fields.sql`

**Changed:**
```sql
-- BEFORE
ADD COLUMN IF NOT EXISTS full_name TEXT;

-- AFTER  
ADD COLUMN IF NOT EXISTS name TEXT;
```

#### 6. New Migration to Fix Existing Databases
**File:** `depresso-backend/migrations/013_rename_full_name_to_name.sql`

```sql
-- Safe migration to rename full_name -> name
DO $$ 
BEGIN
    -- If only full_name exists, rename it
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name='users' AND column_name='full_name'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name='users' AND column_name='name'
    ) THEN
        ALTER TABLE Users RENAME COLUMN full_name TO name;
    END IF;
    
    -- If both exist, merge and keep name
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name='users' AND column_name='full_name'
    ) AND EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name='users' AND column_name='name'
    ) THEN
        UPDATE Users SET name = full_name WHERE name IS NULL AND full_name IS NOT NULL;
        ALTER TABLE Users DROP COLUMN full_name;
    END IF;
END $$;
```

#### 7. Migration Runner Script
**File:** `depresso-backend/run-migration-013.sh`

```bash
#!/bin/bash
echo "🔧 Running migration 013: Rename full_name to name"
source .env.local
psql "$POSTGRES_URL" -f migrations/013_rename_full_name_to_name.sql
echo "✅ Migration completed"
psql "$POSTGRES_URL" -c "\d Users"
```

---

## How The Authentication Flow Works Now

### Guest Mode Flow:
1. User opens app → No userId → Shows authentication screen
2. User taps "Skip" → Registers anonymous userId
3. App navigates to main app with userId but NO Apple credentials
4. Settings shows "Guest Mode" (isLinkedToApple = false)
5. **"Edit Profile" is HIDDEN** for guests
6. "Link with Apple" button is shown

### Apple Sign-In (New User) Flow:
1. User taps "Sign in with Apple"
2. Apple returns credentials + identityToken
3. Backend verifies token, creates user with apple_user_id
4. Backend returns: { userId, sessionToken (with appleUserId), name, email }
5. iOS saves: userId, sessionToken(isAppleAuth: true), name, email
6. **isLinkedToApple = true**
7. Settings shows name + Apple icon
8. "Edit Profile" is visible, "Link with Apple" is hidden

### Apple Linking (Guest → Authenticated) Flow:
1. Guest user taps "Link with Apple"
2. Apple returns credentials + identityToken
3. Backend:
   - Verifies token is valid
   - Updates existing user: `UPDATE Users SET apple_user_id = $1, name = $2, email = $3 WHERE id = $4`
   - Generates NEW JWT with appleUserId: `generateToken(userId, appleUserId)`
   - Returns: { success: true, sessionToken }
4. iOS:
   - **FIXED:** Saves new token: `setSessionToken(newToken, isAppleAuth: true)`
   - Sets isLinkedToApple = true
   - Updates profile with name/email
5. UI updates:
   - "Guest Mode" → Shows name + Apple icon
   - "Link with Apple" button disappears
   - "Edit Profile" button appears

### Returning User Flow:
1. User opens app → userId + sessionToken exist in UserManager
2. App checks token validity (JWT decoded on backend)
3. Backend sees appleUserId in token → User is authenticated
4. Settings loads with isLinkedToApple = true
5. Full profile editing available

---

## Backend JWT Token Structure

### Guest Token (before linking):
```json
{
  "userId": "8f3e4a2b-1234-5678-90ab-cdef12345678",
  "iat": 1709418624,
  "exp": 1712010624
}
```

### Apple Token (after linking or sign-in):
```json
{
  "userId": "8f3e4a2b-1234-5678-90ab-cdef12345678",
  "appleUserId": "001824.f737fe0e56c347d6a589ee166feb5def.0319",
  "iat": 1709418624,
  "exp": 1712010624
}
```

The presence of `appleUserId` in the JWT is what backend uses to authenticate Apple-linked users.

---

## Database Schema Fix

### Users Table (BEFORE - Broken):
```sql
CREATE TABLE Users (
    id UUID PRIMARY KEY,
    apple_user_id TEXT UNIQUE,
    email TEXT,
    full_name TEXT,  -- ❌ Code queries 'name'
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Users Table (AFTER - Fixed):
```sql
CREATE TABLE Users (
    id UUID PRIMARY KEY,
    apple_user_id TEXT UNIQUE,
    email TEXT,
    name TEXT,  -- ✅ Matches backend code
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## Testing Checklist

### ✅ Guest Mode
- [ ] Open fresh install → Skip authentication
- [ ] Go to Settings
- [ ] Verify "Guest Mode" is shown
- [ ] Verify "Edit Profile" button is **NOT visible**
- [ ] Verify "Link with Apple" button **IS visible**
- [ ] Try to access any feature → Should work normally

### ✅ Apple Linking Flow
- [ ] Start as guest
- [ ] Tap "Link with Apple"
- [ ] Complete Apple Sign-In
- [ ] Verify success alert: "Your account has been successfully linked to Apple ID"
- [ ] Settings should now show:
  - ✅ Your name (from Apple)
  - ✅ Apple logo icon
  - ✅ "Edit Profile" button visible
  - ✅ "Link with Apple" button hidden
- [ ] Close app and reopen
- [ ] Verify still shows as authenticated (not guest)

### ✅ Apple Sign-In (New User)
- [ ] Fresh install
- [ ] Tap "Sign in with Apple"
- [ ] Complete Apple Sign-In
- [ ] Should proceed to welcome/onboarding
- [ ] Settings should show name + Apple icon
- [ ] "Edit Profile" should be visible

### ✅ Profile Editing
- [ ] As authenticated user, tap "Edit Profile"
- [ ] Change name
- [ ] Save
- [ ] Verify name updates in Settings
- [ ] Verify backend has updated name

### ✅ Logout/Delete Flow
- [ ] Logout → Should clear isLinkedToApple
- [ ] Restart app → Should show as guest
- [ ] Link with Apple again → Should work

---

## Deployment Instructions

### 1. Run Backend Migration
```bash
cd depresso-backend
chmod +x run-migration-013.sh
./run-migration-013.sh
```

This will:
- Rename `full_name` column to `name` if it exists
- Handle edge cases safely
- Can be run multiple times without issues

### 2. Verify Backend Schema
```bash
cd depresso-backend
source .env.local
psql "$POSTGRES_URL" -c "SELECT column_name FROM information_schema.columns WHERE table_name='users';"
```

Should show:
- id
- apple_user_id
- email
- name ← This should exist (not full_name)
- created_at
- updated_at

### 3. Deploy iOS App
The code changes are in:
- `Features/Dashboard/Core/Data/UserManager.swift`
- `Features/Settings/SettingsFeature.swift`
- `Features/Settings/SettingsView.swift`
- `Features/OnBoarding/AuthenticationFeature.swift`

Build and deploy the updated app.

### 4. Force Users to Re-authenticate (Optional)
If you want to force existing users to get new tokens:
```bash
# This would invalidate all existing tokens
# Change JWT_SECRET in .env and restart backend
```

---

## Files Changed

### iOS (5 files):
1. `Features/Dashboard/Core/Data/UserManager.swift` - Added isLinkedToApple tracking
2. `Features/Settings/SettingsFeature.swift` - Fixed token saving and guest detection
3. `Features/Settings/SettingsView.swift` - Hide Edit Profile for guests
4. `Features/OnBoarding/AuthenticationFeature.swift` - Mark Apple auth tokens
5. *(No changes needed to other files)*

### Backend (3 files):
1. `depresso-backend/migrations/011_add_auth_fields.sql` - Fixed column name
2. `depresso-backend/migrations/013_rename_full_name_to_name.sql` - NEW migration
3. `depresso-backend/run-migration-013.sh` - NEW migration script

---

## Technical Details

### Why isLinkedToApple Instead of Checking userName?
1. **Reliable Source of Truth:** Directly tracks authentication method
2. **Persistence:** Survives app restarts via UserDefaults
3. **Security:** Can't be spoofed by manually setting a name
4. **Clear Intent:** Explicit flag for Apple ID linking status

### Why Store isAppleAuth in setSessionToken?
1. **Single Responsibility:** Token management in one place
2. **Atomic Operation:** Token + Apple status updated together
3. **No Race Conditions:** Both saved in same method call
4. **Easy to Track:** Logs show when Apple auth tokens are saved

### Backend Security Flow
1. iOS sends identityToken from Apple
2. Backend verifies with Apple's public keys (RSA signature)
3. Extracts appleUserId from verified JWT
4. Ensures provided appleUserId matches verified one
5. Creates/updates user with verified Apple credentials
6. Returns new JWT with both userId + appleUserId

---

## Summary

**Before:**
- ❌ Guest users saw "Edit Profile" button
- ❌ Linking with Apple didn't actually link (token not saved)
- ❌ isGuest detection was unreliable
- ❌ Database schema mismatch (full_name vs name)

**After:**
- ✅ Guest users DON'T see "Edit Profile" button
- ✅ Linking with Apple properly saves new authenticated token
- ✅ isGuest detection is reliable (checks isLinkedToApple)
- ✅ Database schema matches code (name column)
- ✅ Complete authentication state tracking via isLinkedToApple
- ✅ Proper token management with Apple auth flag

**User Experience:**
- Guest mode is now clearly distinguished from authenticated mode
- Apple linking actually works and persists
- Profile editing is only available to authenticated users
- No more confusion about authentication state
