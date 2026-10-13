# Lore Log

A lightweight, fully in-game chronicle and narrative log addon for **World of Warcraft: Forever** (Interface: `16001`).

**Lore Log** automatically observes your character's deeds—completed quests, dungeons, boss victories, companions, zone exploration, and deaths—and procedurally narrates your adventures as an illuminated storybook, chapter by chapter.

---

## Key Features

1. **Ultra-Low Resource Footprint (Zero Combat Overhead)**
   - Operates purely on event triggers (`QUEST_TURNED_IN`, `ZONE_CHANGED_NEW_AREA`, `PLAYER_LEVEL_UP`, `ENCOUNTER_END`).
   - **No constant `OnUpdate` polling tick** while playing.
   - Narrative generation happens purely **on-demand** when the storybook window is open.
   - Minimal memory footprint: Stores only compact event descriptors (`id`, `timestamp`, `zone`, `party`), not pre-rendered paragraphs.

2. **100% In-Game Only (No Companion App Required)**
   - Requires **no external software**, Node.js servers, web proxies, or secondary companion apps.
   - All deterministic procedural story generation runs natively within the game's Lua 5.1 runtime.

3. **Clean & Easy-To-Read Illuminated Chronicle**
   - Book layout with chapter selection, ornate headings, kicker lines, drop caps/quotes, and clean line spacing.
   - Built-in font scaling (`A+` / `A-` buttons in the header, or `/lorelog size <scale>`).
   - Smooth custom-scrolling story pane with section dividers.

4. **Context-Aware Character Flavour & WoW Forever Races**
   - Built specifically for **World of Warcraft: Forever**:
     - Full support for the new playable race: **Skyborne Elves** (*shen'dorei*) from **Zephras Isle**, including distinct narrative origins for **High Order** (Alliance) and **Windshaper** (Horde) orders.
     - Classic playable races (Humans of Stormwind, Orcs of Durotar, Night Elves of Teldrassil, Forsaken of Lordaeron, Dwarves of Ironforge, Tauren of Mulgore, Gnomes of Gnomeregan, Trolls of the Echo Isles).
     - Expanded WoW Forever class combinations (Undead Paladin, Dwarf Shaman, Orc Mage, Human Hunter, Troll Warlock, Gnome Priest, etc.).
     - Class & Combat Style (custom strike phrases and callings for all classes).
     - Gender & Pronouns (dynamically inflected throughout the story).
     - Active Quest Log ("Threads Yet Unwoven" woven narratively into the active chapter).

5. **Minimap Button & Keybindings**
   - Beautiful, gold-bordered book icon on your Minimap.
   - Left-click to toggle the chronicle; right-click to quick-switch visual themes; drag freely around the minimap rim.
   - Keybind support: Bind any key to open your chronicle via **Game Menu -> Key Bindings -> AddOns -> Lore Log**.

6. **Live Chronicle Announcements in Chat**
   - Procedurally narrates your deeds as they happen in your main chat window.
   - Complete a quest, discover a zone, defeat a dungeon boss, or gain a level, and Lore Log pens the moment live.
   - Toggle on or off anytime with `/lorelog chat`.

7. **Multiple Visual Themes & Bundled Fonts**
   - Includes real Open Font License (OFL) typefaces bundled directly in `LoreLog/Fonts/`:
     - **Gilded Tome**: *Playfair Display* & *EB Garamond* on dark leather with gold accents.
     - **Parchment Scroll**: *IM Fell English* on sun-aged parchment tones.
     - **Royal Decree**: *Cinzel* & *Cormorant Garamond* in regal midnight and silver.
     - **Night Ink**: *Lora* on slate dark mode for nighttime reading.
     - **Fel Grimoire**: *Uncial Antiqua* & *Lora* with demonic emerald accents.
     - **Azeroth Classic**: Blizzard's native *Morpheus* & *Friz Quadrata* fonts.
   - Switch themes on the fly from the UI header, minimap button, or via `/lorelog theme <name>`.

8. **Spellbook Side Tab ("The Story So Far")**
   - Integrates directly alongside your class spellbook / specialization tabs.
   - Supports both classic (`SpellBookFrame`) and modern (`PlayerSpellsFrame`) spellbook frames with overlap protection.
   - Clicking the tab smoothly toggles the chronicle window.

9. **Chapter System (5-Level Increments)**
   - Automatically segments your journey into thematic chapters:
     - **Chapter I**: Levels 1–5 (*Humble Beginnings*)
     - **Chapter II**: Levels 6–10 (*Beyond the Hearth*)
     - **Chapter III**: Levels 11–15 (*The Road Widens*)
     - **Chapter IV**: Levels 16–20 (*Tempered by Trial*)
     - ...up through Level 60 and beyond!

10. **Fellowship & Companion Tracking**
    - Automatically logs other players you party with to complete dungeon runs and quests.
    - Tracks dungeon runs, boss victories, first met dates, and total shared adventures.
    - Dedicated **Companions** page listing your most frequent allies.

---

## Installation

1. Copy the `LoreLog` directory into your World of Warcraft AddOns directory:
   ```
   World of Warcraft/_classic_beta_/Interface/AddOns/LoreLog
   ```
   *(or whichever folder corresponds to your WoW Forever installation)*

   **Quick Update:** Run `deploy.bat` or `powershell -ExecutionPolicy Bypass -File tools/deploy.ps1` to automatically update `C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns\LoreLog` with your latest files.

2. Ensure the directory structure looks like:
   ```
   Interface/AddOns/LoreLog/
   ├── Bindings.xml
   ├── Core.lua
   ├── Data.lua
   ├── Themes.lua
   ├── Tracker.lua
   ├── Narrator.lua
   ├── UI.lua
   ├── Minimap.lua
   ├── SpellbookTab.lua
   ├── LoreLog.toc
   └── Fonts/
       ├── Cinzel-Bold.ttf
       ├── CormorantGaramond-Medium.ttf
       ├── CormorantGaramond-MediumItalic.ttf
       ├── EBGaramond-Italic.ttf
       ├── EBGaramond-Regular.ttf
       ├── IMFellEnglish-Italic.ttf
       ├── IMFellEnglish-Regular.ttf
       ├── Lora-Bold.ttf
       ├── Lora-Italic.ttf
       ├── Lora-Regular.ttf
       ├── PlayfairDisplay-Bold.ttf
       ├── UncialAntiqua-Regular.ttf
       └── licenses/
   ```

3. Launch World of Warcraft Forever.
4. On the Character Select screen, click **AddOns** and ensure **Lore Log** is checked.

---

## In-Game Usage

### Opening the Book
- Click the **Lore Log Minimap Button** on your minimap.
- Click **The Story So Far** tab on the side of your Spellbook (`P`).
- Press your custom hotkey configured in **Key Bindings -> Lore Log**.
- Click the Lore Log icon in the Addon Compartment menu (if supported by your client).
- Type `/lorelog` or `/lore` in chat.

### Slash Commands
- `/lorelog` — Open or close the chronicle window.
- `/lorelog minimap` — Show or hide the minimap button.
- `/lorelog chat` — Toggle live chronicle announcements in chat.
- `/lorelog theme` — List all available themes.
- `/lorelog theme <name>` — Switch directly to a theme (e.g. `/lorelog theme parchment`).
- `/lorelog size <0.8 - 1.4>` — Adjust reading text scale (e.g. `/lorelog size 1.15`).
- `/lorelog reset confirm` — Erase this character's log and start fresh.

