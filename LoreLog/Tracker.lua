-- Lore Log: Tracker
-- Records compact facts about the journey. No prose is stored; the Narrator
-- writes the story on demand when the book is opened.
local ADDON, ns = ...
local CQ = C_QuestLog
local MAX_EVENTS = 6000

local function Ready(fn)
    return function(...)
        if ns.ready then fn(...) end
    end
end

local function Zone()
    local z = GetRealZoneText()
    if not z or z == "" then z = GetZoneText() end
    if z == "" then return nil end
    return z
end

function ns.AnnounceEvent(e)
    if not ns.db or ns.db.chatAnnounce == false then return end
    if not ns.Narrator then return end
    if e.k ~= "q" and e.k ~= "accept" and e.k ~= "lvl" and e.k ~= "dng" and e.k ~= "zone" then return end
    local text = (ns.Narrator.GenerateChatSentence and ns.Narrator.GenerateChatSentence(e))
              or (ns.Narrator.GenerateEventSentence and ns.Narrator.GenerateEventSentence(e))
    if text and text ~= "" then
        DEFAULT_CHAT_FRAME:AddMessage("|cffd9a54c[Lore Log]|r " .. text)
    end
end

function ns.AddEvent(e, pos)
    local ev = ns.char.events
    e.t = e.t or time()
    e.lvl = e.lvl or UnitLevel("player")
    if pos and pos >= 1 and pos <= #ev then
        table.insert(ev, pos, e)
    else
        ev[#ev + 1] = e
    end
    if #ev > MAX_EVENTS then table.remove(ev, 1) end
    if ns.UI and ns.UI.OnDataChanged then ns.UI.OnDataChanged() end
    ns.AnnounceEvent(e)
end

local function ParseQuestLogEntry(i)
    if not GetQuestLogTitle then return nil end
    local vals = { GetQuestLogTitle(i) }
    local title = vals[1]
    if not title or title == "" then return nil end

    local isHeader = false
    local isComplete = false
    local questID = nil

    -- 3.3.5: 9 returns (title, level, tag, group, isHeader, collapsed, isComplete, isDaily, questID)
    if #vals >= 9 then
        isHeader = (vals[5] == 1 or vals[5] == true)
        isComplete = (vals[7] == 1 or vals[7] == true)
        questID = (type(vals[9]) == "number" and vals[9] > 0 and vals[9]) or nil
    -- 2.4.3: 7 returns (title, level, tag, group, isHeader, collapsed, isComplete)
    elseif #vals >= 7 then
        isHeader = (vals[5] == 1 or vals[5] == true)
        isComplete = (vals[7] == 1 or vals[7] == true)
        questID = (type(vals[#vals]) == "number" and vals[#vals] > 0 and vals[#vals]) or i
    -- 1.12: 6 returns (title, level, tag, isHeader, collapsed, isComplete)
    elseif #vals == 6 then
        isHeader = (vals[4] == 1 or vals[4] == true)
        isComplete = (vals[6] == 1 or vals[6] == true)
        questID = i
    else
        isHeader = (vals[4] == 1 or vals[4] == true or vals[5] == 1 or vals[5] == true)
        questID = (type(vals[#vals]) == "number" and vals[#vals] > 0 and vals[#vals]) or i
    end

    return title, isHeader, isComplete, questID
end

local function FindQuestLogInLog(id, title)
    if not GetNumQuestLogEntries then return nil end
    for i = 1, GetNumQuestLogEntries() do
        local qTitle, isHeader, _, qID = ParseQuestLogEntry(i)
        if not isHeader then
            if id and qID and qID == id then
                return i
            elseif title and qTitle and qTitle:lower() == title:lower() then
                return i, qID
            end
        end
    end
    return nil
end

---------------------------------------------------------------------------
-- Quest log access (modern API with a legacy fallback)
---------------------------------------------------------------------------
function ns.GetActiveQuests()
    local out = {}
    if CQ and CQ.GetNumQuestLogEntries and CQ.GetInfo then
        local header
        for i = 1, CQ.GetNumQuestLogEntries() do
            local info = CQ.GetInfo(i)
            if info then
                if info.isHeader then
                    header = info.title
                elseif not info.isHidden and info.questID and info.questID > 0 then
                    out[#out + 1] = {
                        id = info.questID, title = info.title, zone = header,
                        done = CQ.IsComplete and CQ.IsComplete(info.questID) or false,
                    }
                end
            end
        end
    elseif GetNumQuestLogEntries then
        local header
        for i = 1, GetNumQuestLogEntries() do
            local title, isHeader, isComplete, questID = ParseQuestLogEntry(i)
            if title then
                if isHeader then
                    header = title
                elseif questID then
                    out[#out + 1] = { id = questID, title = title, zone = header, done = isComplete }
                end
            end
        end
    end
    return out
end

local function QuestTitle(id)
    local t = ns.char.titles[id]
    if not t and ns.char.qdata and ns.char.qdata[id] then t = ns.char.qdata[id].title end
    if not t and CQ and CQ.GetTitleForQuestID then t = CQ.GetTitleForQuestID(id) end
    return t
end

local function CurrentNPC()
    local name = UnitName("npc")
    if not name or name == "" or name == UNKNOWNOBJECT then
        name = UnitName("questnpc")
    end
    if not name or name == "" or name == UNKNOWNOBJECT then
        if UnitExists("target") and not UnitIsPlayer("target") then
            name = UnitName("target")
        end
    end
    if name and name ~= "" and name ~= UNKNOWNOBJECT then
        return name
    end
    return nil
end

function ns.CacheQuestData(id, title, npc, text, obj)
    if not id or id <= 0 then return end
    local char = ns.char
    if not char then return end
    char.qdata = char.qdata or {}
    local qd = char.qdata[id] or {}
    char.qdata[id] = qd

    if title and title ~= "" then
        char.titles[id] = title
        qd.title = title
    end
    if npc and npc ~= "" then
        qd.npc = qd.npc or npc
    end
    if text and text ~= "" then
        qd.desc = qd.desc or text
    end
    if obj and obj ~= "" then
        qd.obj = qd.obj or obj
    end
end

function ns.UpdateQuestTurnin(id, turnin, reward)
    if not id or id <= 0 then return end
    local char = ns.char
    if not char then return end
    char.qdata = char.qdata or {}
    local qd = char.qdata[id] or {}
    char.qdata[id] = qd
    if turnin and turnin ~= "" then
        qd.turnin = turnin
    end
    if reward and reward ~= "" then
        qd.reward = reward
    end
end

local function ExtractNPCFromText(text)
    if not text then return nil end
    local name = text:match("[Rr]eport to ([%w%s%'-]+) in")
              or text:match("[Rr]eport to ([%w%s%'-]+) at")
              or text:match("[Rr]eport to ([%w%s%'-]+)%.")
              or text:match("[Rr]eport to ([%w%s%'-]+)")
              or text:match("[Rr]eturn to ([%w%s%'-]+) in")
              or text:match("[Rr]eturn to ([%w%s%'-]+) at")
              or text:match("[Rr]eturn to ([%w%s%'-]+)%.")
              or text:match("[Rr]eturn to ([%w%s%'-]+)")
              or text:match("[Ss]peak with ([%w%s%'-]+) in")
              or text:match("[Ss]peak with ([%w%s%'-]+) at")
              or text:match("[Ss]peak with ([%w%s%'-]+)%.")
              or text:match("[Ss]peak with ([%w%s%'-]+)")
              or text:match("[Tt]alk to ([%w%s%'-]+)")
    if name and #name > 2 and #name < 30 and not name:find("the ") and not name:find("your ") then
        return (name:gsub("^%s+", ""):gsub("%s+$", ""))
    end
    return nil
end
ns.ExtractNPCFromText = ExtractNPCFromText

local function ScanQuestLogDetails()
    local char = ns.char
    if not char then return end
    char.qdata = char.qdata or {}
    local updatedAny = false

    if CQ and CQ.GetNumQuestLogEntries and CQ.GetInfo then
        for i = 1, CQ.GetNumQuestLogEntries() do
            local info = CQ.GetInfo(i)
            if info and not info.isHeader and info.questID and info.questID > 0 then
                local id = info.questID
                local qd = char.qdata[id] or {}
                char.qdata[id] = qd
                if info.title and info.title ~= "" then
                    char.titles[id] = info.title
                    qd.title = info.title
                end
                if not qd.desc and CQ.GetQuestDescription then
                    local desc = CQ.GetQuestDescription(id)
                    if desc and desc ~= "" then qd.desc = desc; updatedAny = true end
                end
                if not qd.obj and CQ.GetQuestObjectives then
                    local objs = CQ.GetQuestObjectives(id)
                    if objs and #objs > 0 and objs[1].text then
                        qd.obj = objs[1].text
                        updatedAny = true
                    end
                end
                if not qd.npc and qd.obj then
                    qd.npc = ExtractNPCFromText(qd.obj)
                end
            end
        end
    elseif GetNumQuestLogEntries then
        local numEntries = GetNumQuestLogEntries()
        local oldSel = GetQuestLogSelection and GetQuestLogSelection()
        for i = 1, numEntries do
            local title, isHeader, isComplete, questID = ParseQuestLogEntry(i)
            if not isHeader and title and questID then
                local qd = char.qdata[questID] or {}
                char.qdata[questID] = qd
                char.titles[questID] = title
                qd.title = title
                if (not qd.desc or not qd.obj) and SelectQuestLogEntry then
                    SelectQuestLogEntry(i)
                    if GetQuestLogQuestText then
                        local desc, obj = GetQuestLogQuestText()
                        if desc and desc ~= "" and not qd.desc then qd.desc = desc; updatedAny = true end
                        if obj and obj ~= "" and not qd.obj then qd.obj = obj; updatedAny = true end
                    end
                    if not qd.obj and GetNumQuestLeaderBoards then
                        local numLB = GetNumQuestLeaderBoards(i) or GetNumQuestLeaderBoards() or 0
                        if numLB > 0 and GetQuestLogLeaderBoard then
                            local lbText = GetQuestLogLeaderBoard(1, i) or GetQuestLogLeaderBoard(1)
                            if lbText and lbText ~= "" then
                                qd.obj = lbText
                                updatedAny = true
                            end
                        end
                    end
                end
                if not qd.npc and qd.obj then
                    qd.npc = ExtractNPCFromText(qd.obj)
                end
            end
        end
        if oldSel and SelectQuestLogEntry then
            SelectQuestLogEntry(oldSel)
        end
    end

    -- Backfill details into active chronicle events if they were accepted before log text resolved
    if char.events then
        for _, ev in ipairs(char.events) do
            if ev.id and char.qdata[ev.id] then
                local qd = char.qdata[ev.id]
                if (not ev.desc or ev.desc == "") and qd.desc then ev.desc = qd.desc; updatedAny = true end
                if (not ev.obj or ev.obj == "") and qd.obj then ev.obj = qd.obj; updatedAny = true end
                if (not ev.npc or ev.npc == "") and qd.npc then ev.npc = qd.npc; updatedAny = true end
            end
        end
    end

    if updatedAny and ns.UI and ns.UI.OnDataChanged then
        ns.UI.OnDataChanged()
    end
end

---------------------------------------------------------------------------
-- Group helpers & companions
---------------------------------------------------------------------------
function ns.GroupMembers()
    local list = {}
    if not IsInGroup() then return list end
    local raid = IsInRaid()
    local n = raid and GetNumGroupMembers() or GetNumSubgroupMembers()
    local prefix = raid and "raid" or "party"
    for i = 1, n do
        local unit = prefix .. i
        if UnitExists(unit) and UnitIsPlayer(unit) and not UnitIsUnit(unit, "player") then
            local name = GetUnitName(unit, true)
            if name and name ~= UNKNOWNOBJECT then
                local _, cls = UnitClass(unit)
                list[#list + 1] = { name, cls }
            end
        end
    end
    return list
end

local function Credit(name, cls, dungeon)
    local comps = ns.char.companions
    local c = comps[name]
    if not c then
        c = { n = 0, f = time() }
        comps[name] = c
    end
    if cls and cls ~= "" then c.c = cls end
    c.n = c.n + 1
    c.l = time()
    if dungeon then
        c.d = c.d or {}
        c.d[dungeon] = true
    end
end

---------------------------------------------------------------------------
-- Dungeon runs (persisted in char.run so a /reload mid-dungeon is safe)
---------------------------------------------------------------------------
local function RunNames(run)
    local names = {}
    for name in pairs(run.p) do names[#names + 1] = name end
    table.sort(names)
    return names
end

local function UpdateRunParty()
    local run = ns.char.run
    if not run then return end
    for _, m in ipairs(ns.GroupMembers()) do
        run.p[m[1]] = m[2] or ""
    end
end

local function SnapshotComplete()
    local set = {}
    for _, q in ipairs(ns.GetActiveQuests()) do
        if q.done then set[q.id] = true end
    end
    return set
end

local function FinishRun()
    local run = ns.char.run
    if not run then return end
    ns.char.run = nil
    local worthy = #run.b > 0 or (run.q or 0) > 0 or (time() - run.t) >= 180
    if not worthy then return end
    local names = RunNames(run)
    for _, name in ipairs(names) do Credit(name, run.p[name], run.d) end
    ns.AddEvent({
        k = "dng", d = run.d, r = run.r, lvl = run.lvl, t = run.t,
        p = #names > 0 and names or nil,
        b = #run.b > 0 and run.b or nil,
    }, run.i)
end

local function CheckInstance()
    local inInstance, kind = IsInInstance()
    local char = ns.char
    if inInstance and (kind == "party" or kind == "raid") then
        local name = GetInstanceInfo()
        if char.run and char.run.d ~= name then FinishRun() end
        if not char.run then
            char.run = {
                d = name, t = time(), p = {}, b = {}, q = 0,
                r = (kind == "raid") or nil,
                lvl = UnitLevel("player"),
                pre = SnapshotComplete(),
                i = #char.events + 1,
            }
        end
        UpdateRunParty()
    else
        FinishRun()
    end
end

-- Flags quests whose objectives finish while inside the dungeon.
local function ScanDungeonQuests()
    local run = ns.char.run
    if not run then return end
    local dq = ns.char.dq
    for _, q in ipairs(ns.GetActiveQuests()) do
        if q.title then ns.char.titles[q.id] = q.title end
        if q.done and not run.pre[q.id] and not dq[q.id] then
            dq[q.id] = { d = run.d, p = RunNames(run) }
            run.pre[q.id] = true
        end
    end
end

---------------------------------------------------------------------------
-- Chronicle start
---------------------------------------------------------------------------
local RACE_STARTER_ZONES = {
    Human       = "Northshire Valley",
    Dwarf       = "Coldridge Valley",
    Gnome       = "Coldridge Valley",
    NightElf    = "Shadowglen",
    Draenei     = "Ammen Vale",
    Worgen      = "Gilneas",
    Orc         = "Valley of Trials",
    Troll       = "Valley of Trials",
    Tauren      = "Camp Narache",
    Scourge     = "Deathknell",
    Undead      = "Deathknell",
    BloodElf    = "Sunstrider Isle",
    Goblin      = "Kezan",
    Pandaren    = "The Wandering Isle",
    Dracthyr    = "The Forbidden Reach",
}

local scanTooltip
local function GetQuestInfoFromTooltip(id)
    if not scanTooltip and CreateFrame then
        scanTooltip = CreateFrame("GameTooltip", "LoreLogScanTooltip", UIParent or WorldFrame, "GameTooltipTemplate")
        scanTooltip:SetOwner(WorldFrame or UIParent, "ANCHOR_NONE")
    end
    if not scanTooltip or not scanTooltip.SetHyperlink then return nil, nil end
    scanTooltip:ClearLines()
    scanTooltip:SetHyperlink("quest:" .. id)
    local titleObj = _G["LoreLogScanTooltipTextLeft1"]
    local title = titleObj and titleObj:GetText()
    if title and (title == "" or title:find("^quest:%d+") or title:find("^Quest %d+")) then
        title = nil
    end
    local level = nil
    local numLines = (scanTooltip.NumLines and scanTooltip:NumLines()) or 6
    for i = 2, math.min(numLines, 6) do
        local line = _G["LoreLogScanTooltipTextLeft" .. i]
        local text = line and line:GetText()
        if text then
            local l = text:match("^[Ll]evel%s+(%d+)")
                   or text:match("^[Rr]equires%s+[Ll]evel%s+(%d+)")
                   or text:match("Level%s+(%d+)")
            if l then
                level = tonumber(l)
                break
            end
        end
    end
    return title, level
end

local function GetQuestDifficulty(id)
    if CQ and CQ.GetQuestDifficultyLevel then
        local lvl = CQ.GetQuestDifficultyLevel(id)
        if lvl and lvl > 0 then return lvl end
    end
    if CQ and CQ.GetQuestMinLevel then
        local lvl = CQ.GetQuestMinLevel(id)
        if lvl and lvl > 0 then return lvl end
    end
    if CQ and CQ.GetQuestReqLevel then
        local lvl = CQ.GetQuestReqLevel(id)
        if lvl and lvl > 0 then return lvl end
    end
    if GetQuestDifficultyLevel then
        local lvl = GetQuestDifficultyLevel(id)
        if lvl and lvl > 0 then return lvl end
    end
    return nil
end

local function GetQuestDetails(id)
    local title = ns.char and ns.char.titles and ns.char.titles[id]
    if not title and CQ and CQ.GetTitleForQuestID then
        title = CQ.GetTitleForQuestID(id)
        if title == "" then title = nil end
    end
    local lvl = GetQuestDifficulty(id)

    if not title or not lvl then
        local ttTitle, ttLvl = GetQuestInfoFromTooltip(id)
        if not title and ttTitle then title = ttTitle end
        if not lvl and ttLvl then lvl = ttLvl end
    end

    if title and title ~= "" and ns.char and ns.char.titles then
        ns.char.titles[id] = title
    end

    return title, lvl
end

local function GetCompletedQuestIDs()
    local ids = {}
    local seen = {}
    if CQ and CQ.GetAllCompletedQuestIDs then
        local raw = CQ.GetAllCompletedQuestIDs()
        if raw then
            for _, id in ipairs(raw) do
                if type(id) == "number" and id > 0 and not seen[id] then
                    seen[id] = true
                    ids[#ids + 1] = id
                end
            end
        end
    end
    if #ids == 0 and GetQuestsCompleted then
        local raw = {}
        local res = GetQuestsCompleted(raw) or raw
        for id, v in pairs(res) do
            if v and type(id) == "number" and id > 0 and not seen[id] then
                seen[id] = true
                ids[#ids + 1] = id
            end
        end
    end
    return ids
end

function ns.OnQuestDataLoaded(questID)
    if not questID or questID <= 0 then return end
    local title, lvl = GetQuestDetails(questID)
    if not title or title == "" then return end

    local updated = false
    if ns.char and ns.char.events then
        for _, e in ipairs(ns.char.events) do
            if e.id == questID then
                if not e.title or e.title == "" or e.title:find("^Quest #") then
                    e.title = title
                    updated = true
                end
                if lvl and (not e.lvl or e.lvl == 1) then
                    e.lvl = lvl
                    updated = true
                end
                break
            end
        end
    end
    if updated and ns.UI and ns.UI.OnDataChanged then
        ns.UI.OnDataChanged()
    end
end

function ns.SyncCompletedQuests(manual)
    local char = ns.char
    if not char then return end

    local compIDs = GetCompletedQuestIDs()
    if #compIDs == 0 then
        if QueryQuestsCompleted then
            QueryQuestsCompleted()
        end
        if manual then
            ns.Print("Querying completed quests from server... Please try again in a few moments.")
        end
        return
    end

    -- Identify existing recorded quest IDs
    local recorded = {}
    for _, e in ipairs(char.events) do
        if e.id and (e.k == "q" or e.k == "accept") then
            recorded[e.id] = true
        end
    end

    local missing = {}
    for _, id in ipairs(compIDs) do
        if not recorded[id] then
            missing[#missing + 1] = id
        end
    end

    if #missing == 0 then
        if manual then
            ns.Print(("All %d completed quests are already recorded in your chronicle."):format(#compIDs))
        end
        return
    end

    local curLvl = UnitLevel("player") or 1
    local _, raceFile = UnitRace("player")
    local starterZone = (raceFile and RACE_STARTER_ZONES[raceFile]) or Zone() or "these lands"

    local liveTime = time()
    if #char.events > 0 and char.events[1].t then
        liveTime = char.events[1].t
    end

    local newEvents = {}
    local pendingLoads = 0

    for _, id in ipairs(missing) do
        local title, qLvl = GetQuestDetails(id)
        if not title and CQ and CQ.RequestLoadQuestByID then
            CQ.RequestLoadQuestByID(id)
            pendingLoads = pendingLoads + 1
        end

        newEvents[#newEvents + 1] = {
            k = "q",
            id = id,
            title = title or ("Quest #" .. id),
            lvl = qLvl or 1,
            z = (qLvl and qLvl <= 5 and starterZone) or nil,
        }
    end

    -- Sort by quest level ascending, then by ID
    table.sort(newEvents, function(a, b)
        local alvl = a.lvl or 1
        local blvl = b.lvl or 1
        if alvl ~= blvl then return alvl < blvl end
        return (a.id or 0) < (b.id or 0)
    end)

    -- Ensure opening begin event at level 1
    local beginEvent = nil
    if #char.events > 0 and char.events[1].k == "begin" then
        beginEvent = char.events[1]
        if newEvents[1] and (newEvents[1].lvl or 1) <= 5 then
            beginEvent.lvl = 1
            if not beginEvent.z or beginEvent.z == "" then
                beginEvent.z = starterZone
            end
            beginEvent.pre = nil
        end
    else
        beginEvent = {
            k = "begin",
            z = starterZone,
            lvl = 1,
            t = liveTime - (#newEvents * 120) - 1000,
        }
        table.insert(char.events, 1, beginEvent)
    end

    local baseT = liveTime - (#newEvents * 60) - 60
    for i, e in ipairs(newEvents) do
        e.t = baseT + (i * 60)
    end

    -- Check which level milestones already exist
    local existingLevels = {}
    for _, e in ipairs(char.events) do
        if e.k == "lvl" and e.lvl then
            existingLevels[e.lvl] = true
        end
    end

    local milestones = {}
    for m = 6, curLvl, ns.CHAPTER_SIZE do
        if not existingLevels[m] then
            milestones[#milestones + 1] = m
        end
    end

    local backfillList = {}
    local mIdx = 1
    for _, e in ipairs(newEvents) do
        while mIdx <= #milestones and (e.lvl or 1) >= milestones[mIdx] do
            local mLvl = milestones[mIdx]
            backfillList[#backfillList + 1] = {
                k = "lvl",
                lvl = mLvl,
                t = (e.t or baseT) - 1,
            }
            mIdx = mIdx + 1
        end
        backfillList[#backfillList + 1] = e
    end

    while mIdx <= #milestones do
        local mLvl = milestones[mIdx]
        local lastT = (#backfillList > 0 and backfillList[#backfillList].t) or baseT
        backfillList[#backfillList + 1] = {
            k = "lvl",
            lvl = mLvl,
            t = lastT + 1,
        }
        mIdx = mIdx + 1
    end

    local insertPos = 2
    for _, e in ipairs(backfillList) do
        table.insert(char.events, insertPos, e)
        insertPos = insertPos + 1
    end

    while #char.events > MAX_EVENTS do
        table.remove(char.events, 2)
    end

    if ns.UI and ns.UI.OnDataChanged then
        ns.UI.OnDataChanged()
    end

    if manual or #newEvents > 0 then
        ns.Print(("Backfilled %d past completed quests into your chronicle."):format(#newEvents))
        if pendingLoads > 0 then
            ns.Print(("Requesting details from server for %d quests..."):format(pendingLoads))
        end
    end
end

---------------------------------------------------------------------------
-- Chronicle start
---------------------------------------------------------------------------
function ns.BeginChronicle()
    local char = ns.char
    if not char then return end
    if #char.events > 0 then
        local z = Zone()
        if z and char.events[1] and char.events[1].k == "begin" and (not char.events[1].z or char.events[1].z == "") then
            char.events[1].z = z
            char.zones[z] = true
        end
        return
    end
    local pre = 0
    local compIDs = GetCompletedQuestIDs()
    pre = #compIDs
    local _, raceFile = UnitRace("player")
    local z = (raceFile and RACE_STARTER_ZONES[raceFile]) or Zone()
    if z then char.zones[z] = true end
    ns.AddEvent({ k = "begin", z = z, lvl = 1, pre = pre > 0 and pre or nil })
    if pre > 0 then
        ns.SyncCompletedQuests(false)
    end
end

ns.OnLogin(function()
    local char = ns.char
    ns.BeginChronicle()
    -- Cache active quest titles (without wiping permanent completed titles)
    for _, q in ipairs(ns.GetActiveQuests()) do
        if q.title and q.title ~= "" then char.titles[q.id] = q.title end
    end
    ScanQuestLogDetails()
    if QueryQuestsCompleted then
        QueryQuestsCompleted()
    end
    ns.SyncCompletedQuests(false)
end)

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
ns.On("QUEST_QUERY_COMPLETE", Ready(function()
    ns.SyncCompletedQuests(false)
end))

ns.On("QUEST_DATA_LOAD_RESULT", Ready(function(questID, success)
    if success and questID and questID > 0 then
        ns.OnQuestDataLoaded(questID)
    end
end))

ns.On("PLAYER_ENTERING_WORLD", Ready(function()
    ns.BeginChronicle()
    CheckInstance()
    ScanQuestLogDetails()
    ns.SyncCompletedQuests(false)
end))

ns.On("ZONE_CHANGED_NEW_AREA", Ready(function()
    CheckInstance()
    if IsInInstance() then return end
    local z = Zone()
    if z and not ns.char.zones[z] then
        ns.char.zones[z] = true
        ns.AddEvent({ k = "zone", z = z })
    end
end))

ns.On("GROUP_ROSTER_UPDATE", Ready(function()
    if ns.char.run then UpdateRunParty() end
end))

ns.On("ENCOUNTER_END", Ready(function(_, encounterName, _, _, success)
    local run = ns.char.run
    if not run or success ~= 1 or not encounterName then return end
    for _, b in ipairs(run.b) do
        if b == encounterName then return end
    end
    run.b[#run.b + 1] = encounterName
end))

ns.On("QUEST_LOG_UPDATE", Ready(function()
    if ns.char.run then ns.Throttle("ll_dq", 1, ScanDungeonQuests) end
    ns.Throttle("ll_scan_log", 2, ScanQuestLogDetails)
end))

local pendingDetail = {}

ns.On("QUEST_DETAIL", Ready(function()
    local id = GetQuestID and GetQuestID()
    local title = GetTitleText and GetTitleText()
    local text = GetQuestText and GetQuestText()
    local obj = GetObjectiveText and GetObjectiveText()
    local npc = CurrentNPC()
    pendingDetail = {
        id = (id and id > 0 and id) or nil,
        title = title,
        npc = npc,
        desc = text,
        text = text,
        obj = obj,
        t = time(),
    }
    if id and id > 0 then
        ns.CacheQuestData(id, title, npc, text, obj)
    end
end))

-- Classic passes (index, questID); modern passes (questID).
ns.On("QUEST_ACCEPTED", Ready(function(...)
    local arg1, arg2 = ...
    local logIndex = nil
    local id = nil

    if type(arg1) == "number" and type(arg2) == "number" then
        logIndex = arg1
        id = arg2
    elseif type(arg1) == "number" then
        if arg1 <= 40 and GetQuestLogTitle then
            logIndex = arg1
            local _, _, _, qID = ParseQuestLogEntry(arg1)
            id = qID or arg1
        else
            id = arg1
        end
    end
    if not id or id <= 0 then
        id = (GetQuestID and GetQuestID()) or (pendingDetail and pendingDetail.id)
    end

    local title = (GetTitleText and GetTitleText()) or (CQ and CQ.GetTitleForQuestID and CQ.GetTitleForQuestID(id))
    local text = GetQuestText and GetQuestText()
    local obj = GetObjectiveText and GetObjectiveText()
    local npc = CurrentNPC()

    if not logIndex and (id or title) then
        logIndex = FindQuestLogInLog(id, title)
    end

    -- Try reading directly from the log entry that was just added
    if logIndex and SelectQuestLogEntry then
        local oldSel = GetQuestLogSelection and GetQuestLogSelection()
        SelectQuestLogEntry(logIndex)
        if GetQuestLogQuestText then
            local lDesc, lObj = GetQuestLogQuestText()
            if lDesc and lDesc ~= "" then text = lDesc end
            if lObj and lObj ~= "" then obj = lObj end
        end
        if GetNumQuestLeaderBoards then
            local numLB = GetNumQuestLeaderBoards(logIndex) or GetNumQuestLeaderBoards() or 0
            for lbIdx = 1, numLB do
                local lbText = GetQuestLogLeaderBoard(lbIdx, logIndex) or GetQuestLogLeaderBoard(lbIdx)
                if lbText and lbText ~= "" then
                    obj = lbText
                    break
                end
            end
        end
        local qTitle, _, _, qID = ParseQuestLogEntry(logIndex)
        if qTitle and (not title or title == "") then title = qTitle end
        if qID and (not id or id <= 0) then id = qID end
        if oldSel and SelectQuestLogEntry then SelectQuestLogEntry(oldSel) end
    end

    if pendingDetail and (time() - (pendingDetail.t or 0)) < 30 then
        if (not text or text == "") and (pendingDetail.desc or pendingDetail.text) then
            text = pendingDetail.desc or pendingDetail.text
        end
        if (not obj or obj == "") and pendingDetail.obj then obj = pendingDetail.obj end
        if (not npc or npc == "") and pendingDetail.npc then npc = pendingDetail.npc end
        if (not title or title == "") and pendingDetail.title then title = pendingDetail.title end
        if (not id or id <= 0) and pendingDetail.id then id = pendingDetail.id end
    end

    if not id or id <= 0 then
        id = 1
    end

    ns.CacheQuestData(id, title, npc, text, obj)
    local qd = ns.char.qdata and ns.char.qdata[id]

    local e = {
        k = "accept",
        id = id,
        title = (title and title ~= "") and title or nil,
        z = Zone(),
        npc = (qd and qd.npc) or npc,
        obj = (qd and qd.obj) or obj,
        desc = (qd and qd.desc) or text,
        t = time(),
        lvl = UnitLevel("player"),
    }
    ns.AddEvent(e)
    ns.Throttle("ll_scan_log", 0.5, ScanQuestLogDetails)
end))

ns.On("QUEST_REMOVED", Ready(function(questID)
    if not questID or questID <= 0 then return end
    local char = ns.char
    if not char then return end
    if char.titles then char.titles[questID] = nil end
    if char.qdata then char.qdata[questID] = nil end
    if char.dq then char.dq[questID] = nil end

    local ev = char.events
    local removed = false
    for i = #ev, 1, -1 do
        if ev[i].id == questID and ev[i].k == "accept" then
            table.remove(ev, i)
            removed = true
            break
        end
    end
    if removed and ns.UI and ns.UI.OnDataChanged then
        ns.UI.OnDataChanged()
    end
end))

ns.On("QUEST_PROGRESS", Ready(function()
    local id = GetQuestID and GetQuestID()
    local turnin = CurrentNPC()
    if id and id > 0 then
        ns.UpdateQuestTurnin(id, turnin)
    end
end))

ns.On("QUEST_COMPLETE", Ready(function()
    local id = GetQuestID and GetQuestID()
    local title = GetTitleText and GetTitleText()
    local turnin = CurrentNPC()
    local reward = GetRewardText and GetRewardText()
    if id and id > 0 then
        ns.UpdateQuestTurnin(id, turnin, reward)
        if title and title ~= "" then
            ns.CacheQuestData(id, title, nil, nil, nil)
        end
    end
end))

ns.On("QUEST_TURNED_IN", Ready(function(questID, xpReward, moneyReward)
    local char = ns.char
    local qd = char.qdata and char.qdata[questID]
    local turninNPC = CurrentNPC() or (qd and qd.turnin)

    local e = {
        k = "q",
        id = questID,
        title = QuestTitle(questID),
        z = Zone(),
        npc = qd and qd.npc,
        turnin = turninNPC or (qd and qd.npc),
        obj = qd and qd.obj,
        desc = qd and qd.desc,
        t = time(),
        lvl = UnitLevel("player"),
    }
    if moneyReward and moneyReward > 0 then e.m = moneyReward end
    if xpReward and xpReward > 0 then e.xp = xpReward end

    local classOf = {}
    local party
    local dq, run = char.dq[questID], char.run
    if dq then
        e.d, party = dq.d, dq.p
        if run then for n, c in pairs(run.p) do classOf[n] = c end end
    elseif run then
        e.d, party = run.d, RunNames(run)
        for n, c in pairs(run.p) do classOf[n] = c end
    elseif IsInGroup() then
        party = {}
        for _, m in ipairs(ns.GroupMembers()) do
            party[#party + 1] = m[1]
            classOf[m[1]] = m[2]
        end
    end
    if party and #party > 0 then
        e.p = party
        for _, n in ipairs(party) do Credit(n, classOf[n]) end
    end
    if run then run.q = (run.q or 0) + 1 end

    char.dq[questID] = nil
    if e.title and e.title ~= "" then char.titles[questID] = e.title end
    if char.qdata then char.qdata[questID] = nil end
    ns.AddEvent(e)
end))

ns.On("PLAYER_LEVEL_UP", Ready(function(newLevel)
    ns.AddEvent({ k = "lvl", lvl = newLevel })
end))

ns.On("PLAYER_DEAD", Ready(function()
    local ch = ns.ChapterOf(UnitLevel("player"))
    ns.char.deaths[ch] = (ns.char.deaths[ch] or 0) + 1
end))
