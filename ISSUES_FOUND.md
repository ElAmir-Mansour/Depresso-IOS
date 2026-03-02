# 🔍 ISSUES FOUND IN IOS APP

## ❌ PROBLEMS IDENTIFIED:

### 1. **CBT Guided Journal** - ✅ Backend Working, ⚠️ Not in Main App Tabs

**Status:** Backend API tested and working perfectly  
**Problem:** Feature exists but NOT visible in main app tabs

**Evidence:**
- ✅ Backend endpoint `/api/v1/journal/entries` working
- ✅ `GuidedJournalFeature.swift` exists in codebase
- ✅ Templates available (Gratitude, Thought Record)
- ⚠️ Only accessible via sparkles button in Journal tab
- ❌ Not a main tab (only Dashboard, Journal, Community, Support)

**Where it is:**
```
Journal Tab (Tab 1)
  → Sparkles button (top right)
    → Opens GuidedJournalView
      → Shows CBT templates
```

**Fix Needed:**
- User has to know to tap sparkles icon
- Should be more prominent or separate tab

---

### 2. **Community Trends** - ❌ NOT IMPLEMENTED

**Status:** Community posts work, but NO trends view

**Evidence:**
- ✅ Community posts display working
- ✅ Like/unlike functional
- ✅ Backend has `/research/stats` endpoint
- ❌ NO trends visualization in app
- ❌ No analytics dashboard for community

**What's Missing:**
- No "Trending Posts" section
- No "Most Liked" filter
- No engagement metrics display
- No time-based trends (daily/weekly)

**Available but Unused:**
- Backend endpoint: `/api/v1/research/stats`
- Backend endpoint: `/api/v1/research/sentiment`
- Data exists, just not displayed

---

### 3. **Research/Insights Feature** - ❌ NOT INTEGRATED IN MAIN APP

**Status:** Backend working, feature code exists, NOT in app tabs

**Evidence:**
- ✅ `Features/Research/` folder exists
- ✅ `ResearchDashboardView.swift` exists
- ✅ Backend endpoints working
- ❌ NOT in main app tabs
- ❌ NOT accessible from ContentView.swift

**Files Found:**
```
Features/Research/
  ├── Core/Data/PromptEngine.swift
  ├── Core/Data/ResearchEntry.swift
  ├── Views/RichInputView.swift
  └── Views/ResearchDashboardView.swift
```

**App Tabs (from ContentView.swift):**
```
Tab 0: Dashboard
Tab 1: Journal  
Tab 2: Community
Tab 3: Support
```

**Missing:** Tab 4 (Research/Insights)

---

### 4. **Journal Entries Source** - ✅ MIXED (Local + Backend)

**Where entries come from:**

#### A. AI Chat Messages (Journal Tab):
```
Source: AICompanionJournalFeature
  ├── Local: SwiftData (ChatMessage)
  ├── Backend: /api/v1/journal/entries/{id}/messages
  └── Sync: Both ways
```

#### B. CBT Guided Entries:
```
Source: GuidedJournalFeature  
  ├── Created: In app
  ├── Sent to: /api/v1/journal/entries
  └── Storage: Backend only (not shown in journal chat)
```

#### C. Community Posts:
```
Source: CommunityFeature
  ├── Local: SwiftData (CommunityPost)
  ├── Backend: /api/v1/community/posts
  └── Sync: Both ways
```

---

## 📊 CURRENT APP STRUCTURE:

```
Main Tabs:
┌─────────────────────────────────────┐
│ Tab 0: Dashboard (DashboardView)    │
│   • Health metrics (HealthKit)      │
│   • Achievements (SwiftData)        │
│   • Streaks (Backend sync)          │
│   • AI Insights (Local calc)        │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ Tab 1: Journal (JournalView)        │
│   • AI Chat companion               │
│   • Messages (SwiftData + Backend)  │
│   • [Hidden] CBT via sparkles ✨    │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ Tab 2: Community (CommunityView)    │
│   • Posts feed                      │
│   • Like/unlike                     │
│   • Create post                     │
│   ❌ NO trends view                 │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ Tab 3: Support (SupportView)        │
│   • Crisis resources                │
│   • Help & FAQ                      │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ ❌ MISSING: Research/Insights Tab   │
│   • Code exists but not integrated  │
│   • ResearchDashboardView unused    │
└─────────────────────────────────────┘
```

---

## 🎯 WHAT WORKS:

### ✅ Backend APIs (All tested and working):
1. User registration
2. AI chat (Gemini AI)
3. CBT journal entries (backend storage)
4. Community posts
5. Sentiment analysis
6. Research data submission
7. Assessments (PHQ-8, GAD-7)
8. Streak tracking

### ✅ App Features (Working but hidden/incomplete):
1. CBT templates - Hidden behind sparkles button
2. Research data collection - Code exists, not in UI
3. Community trends data - Backend has it, UI doesn't show

---

## 🔧 FIXES NEEDED:

### Priority 1: Make CBT More Visible
**Options:**
- Add "Guided Journal" button to dashboard
- Make sparkles button more prominent
- Add CBT shortcut to main menu

### Priority 2: Add Community Trends View
**Implement:**
- "Trending" tab in community
- Most liked posts section
- Engagement metrics
- Time-based filters

### Priority 3: Integrate Research Dashboard
**Options:**
- Add 5th tab for "Insights"
- Show research data visualization
- Display sentiment trends
- Show typing patterns

---

## 📱 SUMMARY:

**Backend:** ✅ 100% working  
**CBT Feature:** ⚠️ Hidden in app  
**Community Trends:** ❌ Not implemented in UI  
**Research Dashboard:** ❌ Not integrated  

**Data Sources:**
- Dashboard: Local (HealthKit) + Backend (streaks)
- Journal: Local (SwiftData) + Backend (AI + CBT)
- Community: Local (SwiftData) + Backend (sync)
- Research: Backend only (not displayed)

