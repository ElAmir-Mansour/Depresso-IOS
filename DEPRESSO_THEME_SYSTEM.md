# ☕️ Depresso Thematic Design System Plan

## 1. The Core Concept: "The Comforting Coffee Shop"
The current app relies heavily on Apple's default SF Symbols (hearts, sparkels, generic people) and a generic purple/blue "mental health" color palette. 
Because the app is called **Depresso** (a brilliant play on Depression + Espresso), we need to lean completely into the **Coffee Shop Aesthetic**.

A coffee shop is universally associated with **warmth, comfort, grounding, taking a break, and ritual**. This is the perfect psychological metaphor for a mental wellness app. We don't want the app to feel like a hospital; we want it to feel like their favorite quiet café.

---

## 2. 🎨 The Color Palette: "The Roast"

Replace the standard generic `.blue` and `.purple` with a curated coffee palette.

*   **Primary Accent (`Color.ds.accent`)**: **"Rich Espresso"** (Deep, warm brown/caramel)
*   **Background Primary (`Color.ds.backgroundPrimary`)**: **"Oat Milk"** or **"Vanilla Cream"** (A very soft, warm off-white/beige for Light Mode, and a deep **"Midnight Roast"** dark brown for Dark Mode).
*   **Background Secondary (`Color.ds.backgroundSecondary`)**: **"Latte Foam"** (Slightly darker/lighter than primary to create card depth).
*   **Success Green**: **"Matcha Green"** (A soft, earthy green instead of bright neon green).
*   **Warning/Alert**: **"Chai Spice"** or **"Cinnamon"** (Warm burnt orange instead of harsh red).

---

## 3. 🖼️ Custom Iconography & Imagery (What you need to design)

Right now we use Apple's `SF Symbols`. You need to design custom, flat, minimalist SVG vectors to replace these. 

Here is your exact design hit-list:

### **The Navigation Tab Bar**
*   **Dashboard (Home):** A cozy coffee mug on a saucer.
*   **Journal:** A classic spiral notebook with a coffee stain ring on it, or a menu board.
*   **Community:** Three coffee cups clinking together (like a toast), or a cafe table.
*   **Insights:** A coffee drip or espresso shot pulling, with liquid drops forming a bar chart.

### **The "Streaks" & Gamification**
*   **Current:** Flame emoji (🔥)
*   **New Design:** **Coffee Beans (🫘)**. 
    *   *Concept:* "You've collected 12 beans in a row!"
    *   *Widget:* The widget shows a jar slowly filling up with coffee beans the longer their streak gets.

### **The Daily Assessment (PHQ-8)**
*   **Current:** "Daily Check-in"
*   **New Name:** **"The Daily Brew"** or **"Morning Cup"**.
*   **Imagery:** Instead of a generic checkmark, the assessment completion screen shows a beautifully illustrated cup of coffee with steam rising. 
*   **Mood Scale:**
    *   `Severe:` An empty, shattered espresso cup.
    *   `Moderate:` A lukewarm, half-empty cup.
    *   `Great:` A beautiful, perfectly poured latte with latte art (a heart in the foam).

### **The Community Tab (Share Story)**
*   **Action Button (FAB):** Instead of a generic `+` icon, the button should look like a **French Press** or a **Pour-over kettle**. 
*   **"Like" Button:** Instead of a standard heart, use a **"Sugar Cube"** or a **"Latte Art Heart"**.
*   **Comments:** A little speech bubble shaped like a puff of coffee steam.

### **The AI Companion (Journal)**
*   **Current Avatar:** A generic `sparkles` or brain icon.
*   **New Design:** **"Barista AI"**. Design a friendly, minimalist barista character, or a cute animated coffee machine (like a friendly espresso tamper).
*   **Typing Indicator:** Instead of three generic dots (`...`), animate three little drops of coffee dripping into a cup.

---

## 4. 🪟 UI Component Enhancements

### **From Glassmorphism to "Frosted Cafe Window"**
We currently use `.ultraThinMaterial` for the widgets and cards. Let's theme the copy and shadows to feel like looking through a frosted cafe window on a rainy day.
*   Shadows should be tinted slightly brown/amber instead of harsh black or gray.
*   Borders should be subtle caramel lines.

### **Empty States (When there is no data)**
*   **Current:** "No posts found" with an exclamation mark.
*   **New Design:** An illustration of an overturned, empty coffee mug with a spilled drop. 
*   *Text:* "Looks like the pot is empty. Be the first to brew a conversation here!"

---

## 5. ✍️ Copywriting & Microcopy

To fully sell the UI/UX, the text in the app must match the coffee theme.

*   **Loading Screen:** "Brewing your insights..." or "Grinding the beans..."
*   **Saving a Post:** "Pouring your story..."
*   **Error Message:** "Oops! We spilled the coffee. Try again."
*   **Welcome Message:** "Good morning, ElAmir. Your daily cup of mindfulness is ready."
*   **Support/Hotlines:** "The First Aid Kit" or "Emergency Espresso" - *“For when the day is just too bitter.”*

---

## 6. 🚀 Your Next Steps (The Designer's Action Plan)

If you want to make this app truly world-class and unique, here is what you need to design in Figma/Illustrator:

1.  **A Core Logo:** A minimalist, comforting coffee cup that represents "Depresso".
2.  **5 Custom Tab Icons:** (Mug, Notebook, Cafe Table, Chart Drops, Gear/Coffee Grinder for settings).
3.  **The "Bean" Icon:** A custom, stylized coffee bean vector to replace the streak flames.
4.  **3 Empty State Illustrations:**
    *   An empty cafe table (for no community posts).
    *   A spilled coffee cup (for errors).
    *   A steaming fresh cup (for success/check-in complete).
5.  **A Color Palette:** Pick exactly 5 colors (Dark Roast, Medium Roast, Light Latte, Matcha Green, Chai Orange).

Once you design these SVG vectors and pick the exact HEX color codes, give them to me, and **I will completely rewrite the `DS+Color.swift` and `DSIcons.swift` files to integrate your custom coffee system into the entire app!**