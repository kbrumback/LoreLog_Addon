-- Lore Log: Core
-- Namespace, event dispatch, saved variables and small shared helpers.
local ADDON, ns = ...
_G.LoreLog = ns

local GetMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
ns.version = (GetMeta and GetMeta(ADDON, "Version")) or "dev"
ns.ready = false

---------------------------------------------------------------------------
-- Event dispatch (one shared frame, no OnUpdate anywhere at rest)
---------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
local handlers = {}

function ns.On(event, fn)
    local list = handlers[event]
    if not list then
        -- Unknown events (API differences between clients) are skipped safely.
        if not pcall(eventFrame.RegisterEvent, eventFrame, event) then return false end
        list = {}
        handlers[event] = list
    end
    list[#list + 1] = fn
    return true
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
    local list = handlers[event]
    if not list then return end
    for i = 1, #list do list[i](...) end
end)

-- Runs fn once after `delay`, ignoring repeat calls in the meantime.
local pending = {}
function ns.Throttle(key, delay, fn)
    if pending[key] then return end
    pending[key] = true
    C_Timer.After(delay, function()
        pending[key] = nil
        fn()
    end)
end

---------------------------------------------------------------------------
-- Saved variables
---------------------------------------------------------------------------
local readyFns, loginFns = {}, {}
function ns.OnReady(fn)
    if ns.ready then fn() else readyFns[#readyFns + 1] = fn end
end
function ns.OnLogin(fn)
    if IsLoggedIn and IsLoggedIn() then fn() else loginFns[#loginFns + 1] = fn end
end

local ACCOUNT_DEFAULTS = {
    theme = "gilded",
    fontScale = 1,
    chatAnnounce = true,
    minimapAngle = 220,
    minimapHide = false,
}

local function CharDefaults()
    return {
        v = 1,
        events = {},     -- compact chronological event records
        companions = {}, -- [name] = { c = classFile, n = count, f = first, l = last, d = { [dungeon] = true } }
        titles = {},     -- [questID] = title (only for quests currently in the log)
        qdata = {},      -- [questID] = { npc = giver, turnin = turnin, obj = objective, desc = premise }
        dq = {},         -- [questID] = { d = dungeon, p = { names } } objectives finished inside a dungeon
        deaths = {},     -- [chapter] = count
        zones = {},      -- [zoneName] = true
    }
end

local function Fill(t, defaults)
    for k, v in pairs(defaults) do
        if t[k] == nil then t[k] = v end
    end
    return t
end

function ns.InitDB()
    if ns.ready then return end
    LoreLogDB = Fill(LoreLogDB or {}, ACCOUNT_DEFAULTS)
    LoreLogCharDB = Fill(LoreLogCharDB or {}, CharDefaults())
    ns.db, ns.char = LoreLogDB, LoreLogCharDB
    ns.ready = true
    for i = 1, #readyFns do readyFns[i]() end
    wipe(readyFns)
end

ns.On("ADDON_LOADED", function(name)
    if not name then return end
    if name == ADDON or name:lower() == ADDON:lower() then
        ns.InitDB()
    end
end)

local loggedInHandled = false
local function HandleLogin()
    if loggedInHandled then return end
    loggedInHandled = true
    ns.InitDB()
    for i = 1, #loginFns do loginFns[i]() end
    wipe(loginFns)
    if C_Timer and C_Timer.After then
        C_Timer.After(1.5, function()
            ns.Print("Chronicle loaded. Click the minimap button or type |cffffd100/lorelog|r to open your book.")
        end)
    end
end

ns.On("PLAYER_LOGIN", HandleLogin)

if IsLoggedIn and IsLoggedIn() then
    if C_Timer and C_Timer.After then
        C_Timer.After(0.05, HandleLogin)
    else
        HandleLogin()
    end
end

function ns.ResetCharacterData()
    wipe(LoreLogCharDB)
    Fill(LoreLogCharDB, CharDefaults())
    ns.char = LoreLogCharDB
end

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
function ns.Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cffd9a54cLore Log|r: " .. tostring(msg))
end

-- Deterministic string hash: the same deed always reads the same way.
function ns.Hash(s)
    s = tostring(s)
    local h = 5381
    for i = 1, #s do
        h = (h * 33 + s:byte(i)) % 4294967296
    end
    return h
end

function ns.Pick(list, seed)
    if not list or #list == 0 then return "" end
    seed = (type(seed) == "number" and seed) or 0
    return list[(math.floor(seed) % #list) + 1]
end

-- Replaces {tokens} using `extra` first, then `ctx`.
function ns.Format(tpl, ctx, extra)
    return (tpl:gsub("{(%w+)}", function(k)
        local v = extra and extra[k]
        if v == nil and ctx then v = ctx[k] end
        if v == nil then return "" end
        return tostring(v)
    end))
end

function ns.Join(list, max)
    local n = #list
    if n == 0 then return "" end
    if max and n > max then
        return table.concat(list, ", ", 1, max) .. " and " .. (n - max) .. " others"
    end
    if n == 1 then return list[1] end
    return table.concat(list, ", ", 1, n - 1) .. " and " .. list[n]
end

function ns.Article(word)
    local first = word:sub(1, 1):lower()
    return (first:find("[aeiou]") and "an " or "a ") .. word
end

function ns.Plural(n, singular, plural)
    return n .. " " .. (n == 1 and singular or (plural or singular .. "s"))
end

function ns.Esc(s)
    return (tostring(s or ""):gsub("|", "||"))
end

function ns.Spaced(s)
    return (s:gsub("(.)", "%1 "):gsub("%s+$", ""))
end

local ROMAN = { { 10, "X" }, { 9, "IX" }, { 5, "V" }, { 4, "IV" }, { 1, "I" } }
function ns.Roman(n)
    local out = ""
    for _, pair in ipairs(ROMAN) do
        while n >= pair[1] do
            out = out .. pair[2]
            n = n - pair[1]
        end
    end
    return out
end

function ns.Pronouns(sex)
    if sex == 2 then return "he", "him", "his", "He", "His" end
    if sex == 3 then return "she", "her", "her", "She", "Her" end
    return "they", "them", "their", "They", "Their"
end

function ns.Player()
    local p = {}
    p.name = UnitName("player")
    p.race, p.raceFile = UnitRace("player")
    p.class, p.classFile = UnitClass("player")
    p.sex = UnitSex("player")
    p.level = UnitLevel("player")
    local faction, factionGroup = UnitFactionGroup("player")
    p.faction = faction
    p.factionGroup = factionGroup or faction
    return p
end

-- Key binding headers (for Bindings.xml)
BINDING_HEADER_LORELOG_HEADER = "Lore Log"
BINDING_NAME_LORELOG_TOGGLE   = "Toggle Chronicle Window"

---------------------------------------------------------------------------
-- Chapters: every 5 levels (1-5, 6-10, ...)
---------------------------------------------------------------------------
ns.CHAPTER_SIZE = 5

function ns.ChapterOf(level)
    level = math.max(1, level or 1)
    return math.floor((level - 1) / ns.CHAPTER_SIZE) + 1
end

function ns.ChapterRange(c)
    return (c - 1) * ns.CHAPTER_SIZE + 1, c * ns.CHAPTER_SIZE
end

function ns.ChapterTitle(c)
    return ns.Data.chapterTitles[c] or ns.Data.chapterBeyond
end

-- A level-up to 6 closes chapter I rather than opening chapter II.
function ns.EventChapter(e)
    if e.k == "lvl" then return ns.ChapterOf((e.lvl or 2) - 1) end
    return ns.ChapterOf(e.lvl)
end

function ns.MaxChapter()
    local m = ns.ChapterOf(UnitLevel("player"))
    local ev = ns.char and ns.char.events
    if ev and #ev > 0 then
        local c = ns.EventChapter(ev[#ev])
        if c > m then m = c end
    end
    return m
end

function ns.BeginChapter()
    local ev = ns.char and ns.char.events
    if ev and #ev > 0 then
        local minCh = nil
        for i = 1, #ev do
            local c = ns.EventChapter(ev[i])
            if not minCh or c < minCh then minCh = c end
        end
        return minCh or 1
    end
    return 1
end
