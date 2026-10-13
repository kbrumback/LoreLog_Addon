-- Lore Log: Narrator
-- Turns recorded facts into prose, one chapter at a time, only when the book
-- is open. Output is a list of { kind, text } blocks the UI lays out.
--
-- Quests are not narrated one by one. Each stay in a zone becomes a short
-- "scene": a handful of deeds woven together with connecting phrases, the
-- people involved named only a few times, and smaller tasks folded into a
-- single line, so a chapter reads like a story rather than a quest log.
local ADDON, ns = ...
local N = {}
ns.Narrator = N

local Format, Pick, Hash, Esc = ns.Format, ns.Pick, ns.Hash, ns.Esc

local SCENE_DEEDS = 4   -- concrete deeds told in full per scene
local SCENE_NAMES = 3   -- people named per scene before falling back to prose

local function Ctx()
    local D = ns.Data
    local p = ns.Player()
    local he, him, his, He, His = ns.Pronouns(p.sex)
    local ctx = {
        name = p.name or "The hero", race = p.race or "", class = p.class or "",
        classLower = (p.class or ""):lower(), level = p.level,
        he = he, him = him, his = his, He = He, His = His,
        gender = (p.sex == 3 and "woman") or (p.sex == 2 and "man") or "wanderer",
        classFile = p.classFile,
        faction = p.factionGroup or p.faction or "",
    }
    ctx.aRaceClass = ns.Article(ctx.race .. " " .. ctx.class)
    ctx.ARaceClass = (ctx.aRaceClass:gsub("^%l", string.upper))
    local originTpl = (D.GetRaceOrigin and D.GetRaceOrigin(p.raceFile, p.race, p.factionGroup))
        or D.raceOrigin[p.raceFile] or D.raceOrigin.default
    ctx.origin = Format(originTpl, ctx)
    ctx.calling = Format(D.classCalling[p.classFile] or D.classCalling.default, ctx)
    return ctx
end

-- Picks a template, skipping lines already used in this chapter so phrasing
-- does not repeat until a pool runs dry (then the pool starts over).
local function PickFresh(list, seed, used)
    if not list or #list == 0 then return "" end
    local n = #list
    seed = math.floor(tonumber(seed) or 0)
    if used then
        for i = 0, n - 1 do
            local tpl = list[((seed + i) % n) + 1]
            if not used[tpl] then
                used[tpl] = true
                return tpl
            end
        end
        for i = 1, n do used[list[i]] = nil end
    end
    local tpl = list[(seed % n) + 1]
    if used then used[tpl] = true end
    return tpl
end

local function Trim(s)
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function QuestTitle(e)
    if not e then return nil end
    if e.title and e.title ~= "" then return e.title end
    local id, char = e.id, ns.char
    if not id or not char then return nil end
    return (char.titles and char.titles[id])
        or (char.qdata and char.qdata[id] and char.qdata[id].title)
end

local function Category(e)
    local D = ns.Data
    local text = (((e and e.obj) or "") .. " " .. ((e and e.desc) or "") .. " " .. (QuestTitle(e) or "")):lower()
    for _, cat in ipairs(D.categoryOrder) do
        for _, kw in ipairs(D.keywords[cat]) do
            if text:find(kw, 1, true) then return cat end
        end
    end
    return "generic"
end

---------------------------------------------------------------------------
-- Verbs: base / gerund / simple past / past participle
-- Rows with only a base are conjugated regularly from their first word.
---------------------------------------------------------------------------
local VERBS = {
    -- Irregular verbs commonly found in quest objectives and actions
    { "read", "reading", "read", "read" },
    { "write", "writing", "wrote", "written" },
    { "speak with", "speaking with", "spoke with", "spoken with" },
    { "speak to", "speaking to", "spoke to", "spoken to" },
    { "speak", "speaking", "spoke", "spoken" },
    { "talk to", "talking to", "talked to", "talked to" },
    { "confer with", "conferring with", "conferred with", "conferred with" },
    { "take up", "taking up", "took up", "taken up" },
    { "take", "taking", "took", "taken" },
    { "seek out", "seeking out", "sought out", "sought out" },
    { "seek", "seeking", "sought", "sought" },
    { "ride to", "riding to", "rode to", "ridden to" },
    { "ride", "riding", "rode", "ridden" },
    { "drive back", "driving back", "drove back", "driven back" },
    { "drive off", "driving off", "drove off", "driven off" },
    { "drive", "driving", "drove", "driven" },
    { "put down", "putting down", "put down", "put down" },
    { "put", "putting", "put", "put" },
    { "thin out", "thinning out", "thinned out", "thinned out" },
    { "thin", "thinning", "thinned", "thinned" },
    { "stop", "stopping", "stopped", "stopped" },
    { "get", "getting", "got", "got" },
    { "dig up", "digging up", "dug up", "dug up" },
    { "dig", "digging", "dug", "dug" },
    { "win", "winning", "won", "won" },
    { "rid", "ridding", "rid", "rid" },
    { "set", "setting", "set", "set" },
    { "find", "finding", "found", "found" },
    { "lend", "lending", "lent", "lent" },
    { "send", "sending", "sent", "sent" },
    { "see", "seeing", "saw", "seen" },
    { "stand", "standing", "stood", "stood" },
    { "strike down", "striking down", "struck down", "struck down" },
    { "strike", "striking", "struck", "struck" },
    { "bear", "bearing", "bore", "borne" },
    { "slay", "slaying", "slew", "slain" },
    { "bring down", "bringing down", "brought down", "brought down" },
    { "bring", "bringing", "brought", "brought" },
    { "fight", "fighting", "fought", "fought" },
    { "catch", "catching", "caught", "caught" },
    { "hold", "holding", "held", "held" },
    { "keep", "keeping", "kept", "kept" },
    { "deal with", "dealing with", "dealt with", "dealt with" },
    { "deal", "dealing", "dealt", "dealt" },
    { "light", "lighting", "lit", "lit" },
    { "feed", "feeding", "fed", "fed" },
    { "tell", "telling", "told", "told" },
    { "shoot down", "shooting down", "shot down", "shot down" },
    { "shoot", "shooting", "shot", "shot" },
    { "make", "making", "made", "made" },
    { "break", "breaking", "broke", "broken" },
    { "steal", "stealing", "stole", "stolen" },
    { "give", "giving", "gave", "given" },
    { "blow up", "blowing up", "blew up", "blown up" },
    { "blow", "blowing", "blew", "blown" },
    { "fly", "flying", "flew", "flown" },
    { "throw", "throwing", "threw", "thrown" },
    { "draw", "drawing", "drew", "drawn" },
    { "grow", "growing", "grew", "grown" },
    { "know", "knowing", "knew", "known" },
    { "shake", "shaking", "shook", "shaken" },
    { "wake", "waking", "woke", "woken" },
    { "run", "running", "ran", "run" },
    { "swim", "swimming", "swam", "swum" },
    { "drink", "drinking", "drank", "drunk" },
    { "sink", "sinking", "sank", "sunk" },
    { "eat", "eating", "ate", "eaten" },
    { "bite", "biting", "bit", "bitten" },
    { "hide", "hiding", "hid", "hidden" },
    { "fall", "falling", "fell", "fallen" },
    { "lead", "leading", "led", "led" },
    { "meet with", "meeting with", "met with", "met with" },
    { "meet", "meeting", "met", "met" },
    { "teach", "teaching", "taught", "taught" },
    { "buy", "buying", "bought", "bought" },
    { "think", "thinking", "thought", "thought" },
    { "build", "building", "built", "built" },
    { "hear", "hearing", "heard", "heard" },
    { "pay", "paying", "paid", "paid" },
    { "lay", "laying", "laid", "laid" },
    { "say", "saying", "said", "said" },
    { "sell", "selling", "sold", "sold" },
    { "bind", "binding", "bound", "bound" },
    { "wind", "winding", "wound", "wound" },
    { "grind", "grinding", "ground", "ground" },
    { "cut", "cutting", "cut", "cut" },
    { "hit", "hitting", "hit", "hit" },
    { "shut", "shutting", "shut", "shut" },
    { "cast", "casting", "cast", "cast" },
    { "ring", "ringing", "rang", "rung" },
    { "sing", "singing", "sang", "sung" },
    { "hang", "hanging", "hung", "hung" },
    { "choose", "choosing", "chose", "chosen" },
    { "freeze", "freezing", "froze", "frozen" },
    { "burn", "burning", "burned", "burned" },
    { "learn", "learning", "learned", "learned" },
    { "tear", "tearing", "tore", "torn" },
    { "wear", "wearing", "wore", "worn" },
    { "weave", "weaving", "wove", "woven" },
    { "sweep", "sweeping", "swept", "swept" },
    { "weep", "weeping", "wept", "wept" },
    { "creep", "creeping", "crept", "crept" },
    { "leap", "leaping", "leapt", "leapt" },
    { "kneel", "kneeling", "knelt", "knelt" },
    { "feel", "feeling", "felt", "felt" },
    { "leave", "leaving", "left", "left" },
    { "lose", "losing", "lost", "lost" },
    { "bend", "bending", "bent", "bent" },
    { "spend", "spending", "spent", "spent" },
    { "shed", "shedding", "shed", "shed" },
    { "spread", "spreading", "spread", "spread" },
    { "split", "splitting", "split", "split" },
    { "burst", "bursting", "burst", "burst" },
    { "hurt", "hurting", "hurt", "hurt" },
    { "cost", "costing", "cost", "cost" },
    { "stick", "sticking", "stuck", "stuck" },
    { "sting", "stinging", "stung", "stung" },
    { "swing", "swinging", "swung", "swung" },
    { "wring", "wringing", "wrung", "wrung" },
    { "cling", "clinging", "clung", "clung" },
    { "fling", "flinging", "flung", "flung" },
    { "sling", "slinging", "slung", "slung" },
    { "string", "stringing", "strung", "strung" },
    { "spin", "spinning", "spun", "spun" },
    { "shrink", "shrinking", "shrank", "shrunk" },
    { "spring", "springing", "sprang", "sprung" },
    { "stink", "stinking", "stank", "stunk" },
    { "arise", "arising", "arose", "arisen" },
    { "rise", "rising", "rose", "risen" },
    { "swear", "swearing", "swore", "sworn" },
    { "cleanse", "cleansing", "cleansed", "cleansed" },
    { "purify", "purifying", "purified", "purified" },
    { "slaughter", "slaughtering", "slaughtered", "slaughtered" },
    { "eliminate", "eliminating", "eliminated", "eliminated" },
    { "exterminate", "exterminating", "exterminated", "exterminated" },
    { "quell", "quelling", "quelled", "quelled" },
    { "subdue", "subduing", "subdued", "subdued" },
    { "salvage", "salvaging", "salvaged", "salvaged" },
    { "infiltrate", "infiltrating", "infiltrated", "infiltrated" },
    { "sabotage", "sabotaging", "sabotaged", "sabotaged" },
    { "investigate", "investigating", "investigated", "investigated" },
    { "retrieve", "retrieving", "retrieved", "retrieved" },
    { "recover", "recovering", "recovered", "recovered" },
    { "discover", "discovering", "discovered", "discovered" },
    { "uncover", "uncovering", "uncovered", "uncovered" },
    { "deliver", "delivering", "delivered", "delivered" },
    { "report to", "reporting to", "reported to", "reported to" },
    { "return to", "returning to", "returned to", "returned to" },
    { "search for", "searching for", "searched for", "searched for" },
    { "look for", "looking for", "looked for", "looked for" },
    { "probe into", "probing into", "probed into", "probed into" },
    { "check on", "checking on", "checked on", "checked on" },
    { "venture into", "venturing into", "ventured into", "ventured into" },
    { "travel to", "traveling to", "traveled to", "traveled to" },
    { "journey to", "journeying to", "journeyed to", "journeyed to" },
    { "come to", "coming to", "came to", "come to" },
    { "confront", "confronting", "confronted", "confronted" },
    { "defeat", "defeating", "defeated", "defeated" },
    { "gather", "gathering", "gathered", "gathered" },
    { "collect", "collecting", "collected", "collected" },
    { "destroy", "destroying", "destroyed", "destroyed" },
    { "protect", "protecting", "protected", "protected" },
    { "escort", "escorting", "escorted", "escorted" },
    { "scout", "scouting", "scouted", "scouted" },
    { "explore", "exploring", "explored", "explored" },
    { "assist", "assisting", "assisted", "assisted" },
    { "aid", "aiding", "aided", "aided" },
    { "help", "helping", "helped", "helped" },
    { "answer", "answering", "answered", "answered" },
    { "offer", "offering", "offered", "offered" },
    { "scour", "scouring", "scoured", "scoured" },
    { "secure", "securing", "secured", "secured" },
    { "carry", "carrying", "carried", "carried" },
    { "cull", "culling", "culled", "culled" },
    { "hunt", "hunting", "hunted", "hunted" },
    { "harvest", "harvesting", "harvested", "harvested" },
    { "defend", "defending", "defended", "defended" },
    { "rescue", "rescuing", "rescued", "rescued" },
    { "save", "saving", "saved", "saved" },
    { "clear", "clearing", "cleared", "cleared" },
    { "free", "freeing", "freed", "freed" },
    { "kill", "killing", "killed", "killed" },
    { "track", "tracking", "tracked", "tracked" },
    { "obtain", "obtaining", "obtained", "obtained" },
    { "use", "using", "used", "used" },
    { "place", "placing", "placed", "placed" },
    { "plant", "planting", "planted", "planted" },
    { "capture", "capturing", "captured", "captured" },
    { "test", "testing", "tested", "tested" },
    { "visit", "visiting", "visited", "visited" },
    { "inspect", "inspecting", "inspected", "inspected" },
    { "warn", "warning", "warned", "warned" },
    { "repair", "repairing", "repaired", "repaired" },
    { "acquire", "acquiring", "acquired", "acquired" },
    { "locate", "locating", "located", "located" },
    { "mine", "mining", "mined", "mined" },
    { "survey", "surveying", "surveyed", "surveyed" },
    { "guard", "guarding", "guarded", "guarded" },
    { "attack", "attacking", "attacked", "attacked" },
    { "assault", "assaulting", "assaulted", "assaulted" },
    { "purge", "purging", "purged", "purged" },
    { "banish", "banishing", "banished", "banished" },
    { "face", "facing", "faced", "faced" },
    { "loot", "looting", "looted", "looted" },
    { "skin", "skinning", "skinned", "skinned" },
    { "summon", "summoning", "summoned", "summoned" },
    { "activate", "activating", "activated", "activated" },
    { "board", "boarding", "boarded", "boarded" },
    { "poison", "poisoning", "poisoned", "poisoned" },
    { "disarm", "disarming", "disarmed", "disarmed" },
}

local function Regular(v)
    if v:find("[^aeiou]y$") then return v .. "ing", v:sub(1, -2) .. "ied" end
    if v:find("ee$") then return v .. "ing", v .. "d" end
    if v:find("e$") then return v:sub(1, -2) .. "ing", v .. "d" end
    return v .. "ing", v .. "ed"
end

local function RegularPhrase(phrase)
    local v, rest = phrase:match("^(%a+)(.*)$")
    if not v then return "undertaking " .. phrase, "undertook " .. phrase end
    local g, p = Regular(v:lower())
    return g .. rest, p .. rest
end

for _, row in ipairs(VERBS) do
    local g, p = RegularPhrase(row[1])
    row[2] = row[2] or g
    row[3] = row[3] or p
    row[4] = row[4] or row[3]
end
table.sort(VERBS, function(a, b) return #a[1] > #b[1] end)

local function MatchVerb(s)
    if not s then return nil end
    local low = s:lower()
    for _, row in ipairs(VERBS) do
        local b = row[1]
        if low == b or low:sub(1, #b + 1) == b .. " " then
            return row, s:sub(#b + 1)
        end
    end
    return nil
end

-- Returns gerund, simple past, past participle for an action phrase.
local function Conjugate(action)
    local row, rest = MatchVerb(action)
    if row then return row[2] .. rest, row[3] .. rest, row[4] .. rest end
    local g, p = RegularPhrase(action)
    return g, p, p
end

---------------------------------------------------------------------------
-- Turning quest objectives into action phrases
---------------------------------------------------------------------------
local UNCOUNTABLE = {
    meat = true, flesh = true, ore = true, silk = true, linen = true, cloth = true, blood = true,
    dust = true, venom = true, ichor = true, wool = true, vermin = true, sheep = true, deer = true,
    fish = true, kin = true, moss = true, silt = true, sand = true, ash = true, bark = true,
    grain = true, wheat = true, corn = true, dirt = true, water = true, oil = true, ooze = true,
}
local F_TO_VES = { wolf = "wolves", thief = "thieves", elf = "elves", dwarf = "dwarves", leaf = "leaves",
                   half = "halves", wife = "wives", knife = "knives", life = "lives", hoof = "hooves" }

local function Pluralize(phrase)
    local head, word = phrase:match("^(.-)(%a+)$")
    if not word then return phrase end
    local low = word:lower()
    if UNCOUNTABLE[low] or low:find("s$") then return phrase end
    local plural
    if F_TO_VES[low] then
        plural = F_TO_VES[low]
        if word:find("^%u") then plural = plural:gsub("^%l", string.upper) end
    elseif low:find("man$") and not low:find("shaman$") and not low:find("talisman$") then plural = word:sub(1, -4) .. word:sub(-3, -3) .. "en"
    elseif low:find("[^aeiou]y$") then plural = word:sub(1, -2) .. "ies"
    elseif low:find("[xz]$") or low:find("[cs]h$") then plural = word .. "es"
    else plural = word .. "s" end
    return head .. plural
end

local NAME_TITLES = {
    mother = true, father = true, captain = true, lieutenant = true, sergeant = true, king = true,
    queen = true, lord = true, lady = true, chief = true, chieftain = true, marshal = true, prince = true,
    princess = true, baron = true, overlord = true, warlord = true, high = true, grand = true, old = true,
    commander = true, general = true, master = true, brother = true, sister = true, elder = true,
}

local GROUP_KILL  = { "thin the ranks of the %s", "drive back the %s", "hunt down the %s", "cut down the %s",
                      "scatter the %s", "break the %s" }
local SINGLE_KILL = { "bring down %s", "end the reign of %s", "strike down %s", "stand against %s", "slay %s" }
local GROUP_ITEM  = { "gather %s", "collect %s", "gather up %s", "amass %s" }
local SINGLE_ITEM = { "recover %s", "find %s", "retrieve %s", "reclaim %s" }
local KILL_VERBS  = { slay = true, kill = true, defeat = true, destroy = true }
local ITEM_VERBS  = { collect = true, gather = true, bring = true, obtain = true, retrieve = true, acquire = true }

local function SingleTarget(noun)
    noun = noun:gsub("^[Tt]he%s+", "")
    if noun:find("%'s") then return noun end                  -- "Garrick Padfoot's Head"
    if not noun:find("%s") then return noun end                  -- "Hogger"
    if noun:find(" the ") or noun:find(",") then return noun end  -- "Morgan the Collector"
    local first = noun:match("^(%a+)")
    if first and NAME_TITLES[first:lower()] then return noun end   -- "Mother Fang"
    return "the " .. noun
end

-- Returns an action phrase ("thin out the Riverpaw Gnolls") and its kind
-- ("kill", "item" or nil) for a raw objective line.
local function CleanObjective(obj, seed)
    if not obj or obj == "" then return nil end
    seed = seed or 0
    local s = tostring(obj):gsub("[\r\n]+", " ")
    local _, total = s:match("(%d+)%s*/%s*(%d+)")
    total = tonumber(total)

    s = s:gsub("%s*%(%s*%d+%s*/%s*%d+%s*%)", "")
    s = s:gsub(":%s*%d+%s*/%s*%d+", "")
    s = s:gsub("%s*%d+%s*/%s*%d+", "")
    -- If there is a colon separating a sub-header from the objective (e.g. "Defend the Abbey: 8 Defias Thugs")
    if s:find(":") then s = s:gsub("^.-:%s*", "") end
    s = s:gsub("^%s*%d+%s+", "")
    s = s:gsub("^(%a+)%s+%d+%s+", "%1 ")
    -- Strip trailing turn-in instructions, destination directions, and navigation clauses
    s = s:gsub("%s*[,;.]?%s*[Aa]nd%s+then%s+[Ss]peak%s+with%s+.*$", "")
    s = s:gsub("%s*[,;.]?%s*[Aa]nd%s+then%s+[Ss]peak%s+to%s+.*$", "")
    s = s:gsub("%s*[,;.]?%s*[Aa]nd%s+then%s+[Rr]eport%s+to%s+.*$", "")
    s = s:gsub("%s*[,;.]?%s*[Aa]nd%s+then%s+[Rr]eturn%s+to%s+.*$", "")
    s = s:gsub("%s*[,;.]?%s*[Aa]nd%s+then%s+[Tt]alk%s+to%s+.*$", "")
    s = s:gsub("%s*[,;.]?%s*[Aa]nd%s+then%s+[Dd]eliver%s+.*$", "")
    s = s:gsub("%s*[,;.]?%s*[Aa]nd%s+[Ss]peak%s+with%s+.*$", "")
    s = s:gsub("%s*[,;.]?%s*[Aa]nd%s+[Ss]peak%s+to%s+.*$", "")
    s = s:gsub("%s*[,;.]?%s*[Aa]nd%s+[Rr]eport%s+to%s+.*$", "")
    s = s:gsub("%s*[,;.]?%s*[Aa]nd%s+[Rr]eturn%s+to%s+.*$", "")
    s = s:gsub("%s*[,;.]?%s*[Aa]nd%s+[Tt]alk%s+to%s+.*$", "")
    s = s:gsub("%s*[,;.]?%s*[Aa]nd%s+[Bb]ring%s+.*%s+to%s+.*$", "")
    s = s:gsub("%s*[,;.]?%s*[Aa]nd%s+[Dd]eliver%s+.*%s+to%s+.*$", "")
    s = s:gsub("%s*[,;.]?%s*[Aa]nd%s+[Tt]ake%s+.*%s+to%s+.*$", "")
    s = s:gsub("%s*[,;.]?%s*[Aa]nd%s+[Gg]ive%s+.*%s+to%s+.*$", "")
    s = s:gsub("%s*[,;]%s*[Tt]hen%s+[Ss]peak%s+with%s+.*$", "")
    s = s:gsub("%s*[,;]%s*[Tt]hen%s+[Ss]peak%s+to%s+.*$", "")
    s = s:gsub("%s*[,;]%s*[Tt]hen%s+[Rr]eport%s+to%s+.*$", "")
    s = s:gsub("%s*[,;]%s*[Tt]hen%s+[Rr]eturn%s+to%s+.*$", "")
    s = s:gsub("%s*[,;]%s*[Tt]hen%s+[Tt]alk%s+to%s+.*$", "")
    s = s:gsub("%s+then%s+[Ss]peak%s+with%s+.*$", "")
    s = s:gsub("%s+then%s+[Ss]peak%s+to%s+.*$", "")
    s = s:gsub("%s+then%s+[Rr]eport%s+to%s+.*$", "")
    s = s:gsub("%s+then%s+[Rr]eturn%s+to%s+.*$", "")
    s = s:gsub("%s+then%s+[Tt]alk%s+to%s+.*$", "")
    s = s:gsub("%s*%.%s*[Ss]peak%s+with%s+.*$", "")
    s = s:gsub("%s*%.%s*[Rr]eport%s+to%s+.*$", "")
    s = s:gsub("%s*%.%s*[Rr]eturn%s+to%s+.*$", "")
    if not (s:find("^[Rr]eport%s+to%s+") or s:find("^[Rr]eturn%s+to%s+")
            or s:find("^[Ss]peak%s+to%s+") or s:find("^[Tt]alk%s+to%s+")
            or s:find("^[Tt]ravel%s+to%s+") or s:find("^[Vv]enture%s+to%s+")
            or s:find("^[Jj]ourney%s+to%s+") or s:find("^[Rr]ide%s+to%s+")
            or s:find("^[Dd]eliver%s+")) then
        s = s:gsub("%s+to%s+[%a%s%'-]+%s+in%s+.*$", "")
    end
    s = Trim(s:gsub("[%p%s]+$", ""))
    if s == "" then return nil end

    local kind, noun
    local passive = s:match("^(.-)%s+[Ss]lain$") or s:match("^(.-)%s+[Kk]illed$") or s:match("^(.-)%s+[Dd]efeated$")
    if passive then
        kind, noun = "kill", passive
    elseif s:match("^(.-)%s+[Dd]estroyed$") then
        return "destroy the " .. s:match("^(.-)%s+[Dd]estroyed$"), "kill"
    else
        s = s:gsub("^[Tt]alk to%s+", "speak with "):gsub("^[Ss]peak to%s+", "speak with ")
        local row, rest = MatchVerb(s)
        if row then
            local verb = row[1]
            rest = Trim(rest)
            if KILL_VERBS[verb] and rest ~= "" then
                kind, noun = "kill", rest
            elseif ITEM_VERBS[verb] and rest ~= "" then
                kind, noun = "item", rest
            else
                return verb .. (rest ~= "" and (" " .. rest) or "")
            end
        elseif not total and s:find("%s") and s:find("^%u%l+%s+%l") then
            -- An imperative we don't know ("Venture into the mine"): keep it.
            return (s:gsub("^%u", string.lower))
        else
            kind, noun = "item", s
        end
    end

    noun = Trim(noun:gsub("^[Tt]he%s+", ""))
    if noun == "" then return nil end
    local single = (total == 1)
    if not single and total and total > 1 then noun = Pluralize(noun) end

    local tpl
    if kind == "kill" then
        tpl = single and Pick(SINGLE_KILL, seed) or Pick(GROUP_KILL, seed)
        return tpl:format(single and SingleTarget(noun) or noun), "kill"
    end
    if single then
        return Pick(SINGLE_ITEM, seed):format(SingleTarget(noun)), "item"
    end
    return Pick(GROUP_ITEM, seed):format(noun), "item"
end

local TITLE_GERUNDS = {
    culling = "cull", slaying = "slay", hunting = "hunt", gathering = "gather", collecting = "collect",
    harvesting = "harvest", recovering = "recover", finding = "find", searching = "search for",
    investigating = "investigate", defending = "defend", protecting = "protect", rescuing = "rescue",
    saving = "save", delivering = "deliver", clearing = "clear", securing = "secure",
}

local function DeriveActionFromTitle(title, cat)
    if not title or title == "" then return nil end
    local t = Trim(title)

    local gerund, rest = t:match("^(%a+ing)%s+(.+)$")
    if gerund and TITLE_GERUNDS[gerund:lower()] then
        return TITLE_GERUNDS[gerund:lower()] .. " " .. rest
    end

    local row, after = MatchVerb(t)
    if row then return row[1] .. after end

    local wanted = t:match("^[Ww]anted:%s*(.+)") or t:match("^[Bb]ounty:%s*(.+)")
    if wanted then return "bring in " .. wanted end

    local bounty = t:match("^[Bb]ounty on%s+(.+)")
    if bounty then return "hunt down " .. bounty end

    local target = t:match("^[Aa]%s+[Mm]essage to%s+(.+)") or t:match("^[Aa]%s+[Ll]etter to%s+(.+)")
    if target then return "deliver a message to " .. target end
    target = t:match("^[Tt]he [Ss]earch for%s+(.+)") or t:match("^[Ii]n [Ss]earch of%s+(.+)")
    if target then return "search for " .. target end
    target = t:match("^[Ii]n [Dd]efense of%s+(.+)")
    if target then return "defend " .. target end
    target = t:match("^[Tt]rouble [ia][nt]%s+(.+)")
    if target then return "look into the trouble in " .. target end
    target = t:match("^[Tt]he [Tt]hreat of%s+(.+)")
    if target then return "face the threat of " .. target end
    if t:find("^[Aa]%s+[Tt]hreat [Ww]ithin") then return "face the threat within" end
    target = t:match("^[Tt]he [Ff]ate of%s+(.+)")
    if target then return "uncover the fate of " .. target end
    target = t:match("^[Tt]he [Ll]egend of%s+(.+)")
    if target then return "seek out the legend of " .. target end

    -- Noun phrases or quest titles without explicit verbs
    local cleanT = t:gsub("^[Tt]he%s+", "the "):gsub("^[Aa]%s+", "a "):gsub("^[Aa]n%s+", "an ")

    if cat == "combat" then
        if cleanT:find("^the ") then
            return "strike against " .. cleanT
        else
            return "hunt down " .. cleanT
        end
    elseif cat == "gather" then
        if cleanT:find("^[Aa]%s") or cleanT:find("^[Aa]n%s") then
            return "recover " .. cleanT
        else
            return "gather " .. cleanT
        end
    elseif cat == "mystery" then
        return "investigate " .. cleanT
    elseif cat == "rescue" then
        return "come to the aid of " .. cleanT
    elseif cat == "delivery" then
        return "deliver word concerning " .. cleanT
    end

    if #t > 3 and #t < 35 then
        return "see to the matter of " .. t
    end

    return nil
end

local FALLBACK_ACTIONS = {
    combat   = { "take up the hunt", "drive back the rising threat", "scour the wilds for hostile forces",
                 "stand against the gathering darkness" },
    gather   = { "gather supplies", "scour the land for provisions", "collect what was needed",
                 "salvage what the land still offered" },
    mystery  = { "look into the strange rumors", "seek out answers", "probe into the strange omens",
                 "follow a trail of whispers to its end" },
    rescue   = { "aid those in peril", "seek out the lost", "bring the lost back from the brink" },
    delivery = { "carry word across the land", "deliver an urgent dispatch", "bear tidings across the wild roads" },
    generic  = { "lend {his} aid", "answer the call", "lend a helping hand", "heed a plea for help" },
}

local ERRAND_VERBS = { ["speak with"] = true, ["report to"] = true, ["return to"] = true,
                       ["confer with"] = true, ["deliver"] = true }

-- Everything the narrator needs to tell one quest.
local function Describe(e, ctx)
    local seed = Hash((e.id or 0) .. ":" .. (e.t or 0))
    local cat = Category(e)
    local action, kind = CleanObjective(e.obj, seed)
    if not action then action = DeriveActionFromTitle(QuestTitle(e), cat) end

    -- "Assist Marshal Dughan" tells us nothing a story can use.
    if action and e.npc and e.npc ~= "" then
        local low, npc = action:lower(), e.npc:lower()
        for _, v in ipairs({ "assist ", "aid ", "help " }) do
            if low == v .. npc then action = nil break end
        end
    end

    local vague = false
    if not action then
        vague = true
        action = Pick(FALLBACK_ACTIONS[cat] or FALLBACK_ACTIONS.generic, seed)
    end
    action = action:gsub("{his}", ctx.his or "their")
    if kind == "kill" then cat = "combat" end

    local gerund, past, perfect = Conjugate(action)
    local d = { base = action, gerund = gerund, past = past, perfect = perfect, cat = cat, vague = vague }

    local row, rest = MatchVerb(action)
    if row and ERRAND_VERBS[row[1]] then
        d.errand = true
        local who = Trim(rest or "")
        if row[1] ~= "deliver" and who:find("^%u") then d.target = who end
    end
    return d
end

local function DeedExtra(d, d2)
    local x = { base = Esc(d.base), past = Esc(d.past), perfect = Esc(d.perfect), gerund = Esc(d.gerund) }
    if d2 then x.past2 = Esc(d2.past) end
    return x
end

local function MostCommon(list)
    local best, bestN, counts = nil, 0, {}
    for _, v in ipairs(list) do
        counts[v] = (counts[v] or 0) + 1
        if counts[v] > bestN then best, bestN = v, counts[v] end
    end
    return best
end

---------------------------------------------------------------------------
-- Scenes: one stay in a zone, told as a few connected sentences
---------------------------------------------------------------------------
-- quests:   the (already filtered) accept/turn-in events of this stay
-- promised: [questID] = true for quests accepted in earlier scenes
local function BuildScene(zone, quests, ctx, used, promised, seed)
    local D = ns.Data
    local out = {}
    local budget, mentioned = SCENE_NAMES, {}
    local function say(pool, s, extra)
        local tpl = PickFresh(pool, s, used)
        if tpl ~= "" then out[#out + 1] = Format(tpl, ctx, extra) end
    end
    local function canName(name)
        return name and name ~= "" and (mentioned[name] or budget > 0)
    end
    local function name(n)
        if not mentioned[n] then budget = budget - 1; mentioned[n] = true end
        return Esc(n)
    end

    local deeds, errands, promises = {}, {}, {}
    local givers, turnins, companions, compSeen, dungeons = {}, {}, {}, {}, {}
    local vague, completed, kept = 0, 0, nil

    for _, q in ipairs(quests) do
        local d = Describe(q, ctx)
        if q.npc and q.npc ~= "" then givers[#givers + 1] = q.npc end
        if q.k == "accept" then
            promises[#promises + 1] = { d = d, q = q }
        else
            completed = completed + 1
            local t = q.turnin or q.npc
            if t and t ~= "" then turnins[#turnins + 1] = t end
            if q.p then
                for _, n in ipairs(q.p) do
                    if not compSeen[n] then compSeen[n] = true; companions[#companions + 1] = n end
                end
            end
            if q.d and q.d ~= zone and #dungeons == 0 then dungeons[1] = q.d end
            if d.errand then
                local who = d.target or q.turnin
                if who and who ~= "" then errands[#errands + 1] = who else errands[#errands + 1] = false end
            elseif d.vague then
                vague = vague + 1
            elseif not kept and q.id and promised[q.id] then
                kept = { d = d, q = q }
            else
                deeds[#deeds + 1] = d
            end
        end
    end

    -- Who set things in motion
    local hook = MostCommon(givers)
    if hook and canName(hook) and (#quests > 1 or seed % 2 == 0) then
        say(D.sceneHook, seed + 1, { npc = name(hook) })
    end

    -- A promise from an earlier page, finally kept
    local first = true
    if kept then
        local npc = kept.q.npc
        if npc and npc ~= "" and canName(npc) then
            local x = DeedExtra(kept.d); x.npc = name(npc)
            say(D.sceneKept, seed + 2, x)
        else
            say(D.sceneKeptAnon, seed + 2, DeedExtra(kept.d))
        end
        first = false
    end

    -- The deeds themselves, woven in ones and twos
    local shown = math.min(#deeds, SCENE_DEEDS)
    local flavored, i = false, 1
    while i <= shown do
        local a, b = deeds[i], (i + 1 <= shown) and deeds[i + 1] or nil
        local pair = b and (Hash(seed .. ":" .. i) % 3 ~= 0)
        local pool = pair and (first and D.sceneFirstPair or D.sceneNextPair)
                          or (first and D.sceneFirst or D.sceneNext)
        say(pool, seed + i * 7, DeedExtra(a, pair and b or nil))
        if not flavored and (a.cat == "combat" or (pair and b.cat == "combat")) then
            flavored = true
            say(D.classFlavor[ctx.classFile] or D.classFlavor.default, seed + 31)
        end
        first = false
        i = i + (pair and 2 or 1)
    end

    if dungeons[1] then
        say(D.sceneDungeon, seed + 41, { dungeon = Esc(dungeons[1]) })
    end

    if #companions > 0 then
        say(D.sceneCompanions, seed + 43, { companions = Esc(ns.Join(companions, 3)) })
    end

    -- Errands become one line about the people {he} ran between
    if #errands > 0 then
        local names, seen = {}, {}
        for _, who in ipairs(errands) do
            if who and not seen[who] and not mentioned[who] and #names < 2 then
                seen[who] = true
                names[#names + 1] = who
            end
        end
        if #names > 0 and budget >= #names then
            for k, n in ipairs(names) do names[k] = name(n) end
            say(D.sceneErrands, seed + 47, { names = ns.Join(names) })
        else
            say(D.sceneErrandsAnon, seed + 47)
        end
    end

    -- Everything too small or too vague to tell in full
    local extra = math.max(0, #deeds - SCENE_DEEDS) + vague
    if extra > 0 then
        if #deeds == 0 and not kept and #errands == 0 then
            say(D.sceneVagueOnly, seed + 53)
        else
            say(D.sceneMore, seed + 53)
        end
    end

    -- Promises made here, to be kept in a later scene
    for k, p in ipairs(promises) do
        if k > 2 then break end
        local npc = p.q.npc
        if not p.d.vague then
            if npc and npc ~= "" and not mentioned[npc] and budget > 0 then
                local x = DeedExtra(p.d); x.npc = name(npc)
                say(D.scenePromise, seed + 59 + k, x)
            else
                say(D.scenePromiseAnon, seed + 59 + k, DeedExtra(p.d))
            end
        end
    end
    if #promises >= 3 then say(D.scenePromiseMany, seed + 67) end

    -- A closing beat, when there was real work done
    if completed > 1 or (completed == 1 and seed % 2 == 1) then
        local t = MostCommon(turnins)
        local z = { zone = Esc(zone or "these lands") }
        if t and mentioned[t] then
            z.turnin = Esc(t)
            say(D.sceneCloseKnown, seed + 71, z)
        elseif t and budget > 0 then
            z.turnin = name(t)
            say(D.sceneClose, seed + 71, z)
        elseif zone then
            say(D.sceneCloseAnon, seed + 71, z)
        end
    end

    return out
end

---------------------------------------------------------------------------
-- Dungeons, prologue, levels
---------------------------------------------------------------------------
local function DungeonParagraph(e, ctx, used)
    local D = ns.Data
    local seed = Hash((e.d or "") .. (e.t or 0))
    local extra = { dungeon = Esc(e.d or "a nameless dungeon") }
    local s = {}
    if e.p and #e.p > 0 then
        extra.companions = Esc(ns.Join(e.p, 5))
        s[1] = Format(PickFresh(e.r and D.raidParty or D.dungeonParty, seed, used), ctx, extra)
    else
        s[1] = Format(PickFresh(D.dungeonSolo, seed, used), ctx, extra)
    end
    if e.b then
        extra.bosses = Esc(ns.Join(e.b))
        s[2] = Format(PickFresh((e.p and #e.p > 0) and D.bossesGroup or D.bossesSolo, seed + 1, used), ctx, extra)
    else
        s[2] = Format(PickFresh(D.dungeonNoBoss, seed + 1, used), ctx, extra)
    end
    return table.concat(s, " ")
end

local function Prologue(e, ctx)
    local D = ns.Data
    local extra = { zone = Esc(e.z or "a quiet corner of Azeroth"), level = e.lvl or 1, pre = e.pre }
    local p = ns.Player()
    local raceCombined = ((p.race or "") .. " " .. (p.raceFile or "")):lower()
    local isSkyborne = raceCombined:find("skyborne") or raceCombined:find("shendorei") or raceCombined:find("shen'dorei")
                    or (e.z and tostring(e.z):find("Zephras"))
    local pool = (isSkyborne and D.prologueSkyborne) or D.prologue
    local s = { Format(Pick(pool, Hash("begin" .. (e.t or 0))), ctx, extra) }
    if (e.lvl or 1) > 1 then s[#s + 1] = Format(D.prologueLate, ctx, extra) end
    if e.pre and e.pre > 0 then s[#s + 1] = Format(D.prologuePre, ctx, extra) end
    return table.concat(s, " ")
end

local function LevelLine(e, ctx, hi)
    local D = ns.Data
    local tpl = D.levelLines[e.lvl] or Pick(D.levelDefault, Hash("lvl" .. e.lvl .. (e.t or 0)))
    local text = Format(tpl, ctx, { level = e.lvl })
    if hi and e.lvl == hi + 1 then text = text .. " " .. D.newChapter end
    return text
end

---------------------------------------------------------------------------
-- Live chat lines (one deed at a time)
---------------------------------------------------------------------------
local function QuestChatLine(e, ctx)
    local D = ns.Data
    local seed = Hash((e.id or 0) .. ":chat:" .. (e.k or "") .. (e.t or 0))
    local d = Describe(e, ctx)
    local npc = e.npc
    if (not npc or npc == "") and e.obj and ns.ExtractNPCFromText then
        npc = ns.ExtractNPCFromText(e.obj)
    end
    local turnin = e.turnin or npc
    local extra = {
        npc = Esc(npc or ""), turnin = Esc(turnin or ""), zone = Esc(e.z or "the wilds"),
        action = Esc(d.base), actionPast = Esc(d.past), actionPerfect = Esc(d.perfect),
        actionGerund = Esc(d.gerund),
    }
    local pool
    if e.k == "accept" then
        pool = (npc and npc ~= "") and D.chatAccept.withNPC or D.chatAccept.noNPC
    else
        local hasT = turnin and turnin ~= ""
        local mentionsT = hasT and d.base:lower():find(turnin:lower(), 1, true)
        if (d.errand or mentionsT) and hasT then
            pool = D.chatTurnin.errand
        elseif mentionsT then
            pool = D.chatTurnin.noNPC
        elseif d.vague then
            pool = hasT and D.chatTurnin.vague or D.chatTurnin.vagueNoNPC
        else
            pool = hasT and D.chatTurnin.withNPC or D.chatTurnin.noNPC
        end
    end
    return Format(Pick(pool, seed), ctx, extra)
end

function N.GenerateChatSentence(e)
    if e.k == "accept" or e.k == "q" then
        return QuestChatLine(e, Ctx())
    end
    return N.GenerateEventSentence(e)
end

function N.GenerateEventSentence(e)
    local ctx = Ctx()
    local D = ns.Data
    if e.k == "accept" or e.k == "q" then
        return QuestChatLine(e, ctx)
    elseif e.k == "lvl" then
        return "The chronicle marks a new height: level " .. e.lvl .. ". " .. LevelLine(e, ctx)
    elseif e.k == "dng" then
        return DungeonParagraph(e, ctx)
    elseif e.k == "zone" then
        if D.zoneSpecial and e.z and D.zoneSpecial[e.z] then
            return Format(D.zoneSpecial[e.z], ctx, { zone = Esc(e.z) })
        end
        return Format(Pick(D.zoneDiscover, Hash(e.z or "")), ctx, { zone = Esc(e.z or "new lands") })
    end
    return nil
end

---------------------------------------------------------------------------
-- Chapter
---------------------------------------------------------------------------
local function CurrentZone()
    local z = GetRealZoneText()
    if not z or z == "" then z = GetZoneText() end
    return z
end

function N.BuildChapter(ch, opts)
    local D = ns.Data
    local ctx = Ctx()
    local out = {}
    local function add(kind, text) out[#out + 1] = { kind, text } end
    local used, promised = {}, {}

    local lo, hi = ns.ChapterRange(ch)
    local curCh = ns.ChapterOf(UnitLevel("player"))

    add("kicker", ns.Spaced("CHAPTER " .. ns.Roman(ch)))
    add("title", ns.ChapterTitle(ch))
    add("sub", ("Levels %d \226\128\147 %d"):format(lo, hi))
    add("divider")

    local events, hasBegin = {}, false
    for _, e in ipairs(ns.char.events) do
        if ns.EventChapter(e) == ch then
            events[#events + 1] = e
            if e.k == "begin" then hasBegin = true end
        end
    end

    if #events == 0 and ch < ns.BeginChapter() then
        add("p", Format(D.lostPages, ctx))
        return out
    end

    if not hasBegin then
        add("quote", Format(D.chapterIntros[ch] or D.chapterBeyondIntro, ctx))
    end

    local stats = { q = 0, zones = {}, nz = 0, dng = 0 }
    local companions, compSeen = {}, {}
    local function noteZone(z)
        if z and not stats.zones[z] then stats.zones[z] = true; stats.nz = stats.nz + 1 end
    end
    local function noteCompanions(list)
        if not list then return end
        for _, n in ipairs(list) do
            if not compSeen[n] then compSeen[n] = true; companions[#companions + 1] = n end
        end
    end

    local group, lastZone, passing = nil, nil, {}

    local function travelSentence(seed)
        local s = Format(PickFresh(D.travelThrough, seed, used), ctx, { zones = Esc(ns.Join(passing, 4)) })
        wipe(passing)
        return s
    end

    local function flush()
        if not group then return end
        local g = group
        group = nil
        local qs = g.quests
        if #qs == 0 then
            if g.zone and not g.isBegin then passing[#passing + 1] = g.zone end
            lastZone = g.zone
            return
        end
        local seed = Hash(ch .. (g.zone or "") .. (g.t or 0))
        local sentences = {}
        if #passing > 0 then sentences[#sentences + 1] = travelSentence(seed + 5) end
        if g.zone and not g.isBegin then
            local openers = (g.discovered and D.zoneDiscover) or (g.zone == lastZone and D.zoneContinue) or D.zoneReturn
            sentences[#sentences + 1] = Format(PickFresh(openers, seed, used), ctx, { zone = Esc(g.zone) })
        end

        -- A quest both taken and finished during this stay is told once, as done.
        local turninIds = {}
        for _, q in ipairs(qs) do
            if q.k == "q" and q.id then turninIds[q.id] = true end
        end
        local filtered = {}
        for _, q in ipairs(qs) do
            if q.k ~= "accept" or not (q.id and turninIds[q.id]) then
                filtered[#filtered + 1] = q
            end
        end
        if #filtered == 0 then filtered = qs end

        for _, s in ipairs(BuildScene(g.zone, filtered, ctx, used, promised, seed)) do
            sentences[#sentences + 1] = s
        end
        for _, q in ipairs(filtered) do
            if q.k == "accept" and q.id then promised[q.id] = true end
        end

        -- Long scenes are split into two paragraphs so the page can breathe.
        if #sentences >= 6 then
            local cut = math.ceil(#sentences / 2)
            add("p", table.concat(sentences, " ", 1, cut))
            add("p", table.concat(sentences, " ", cut + 1))
        elseif #sentences > 0 then
            add("p", table.concat(sentences, " "))
        end
        lastZone = g.zone
    end

    for _, e in ipairs(events) do
        if e.k == "begin" then
            flush()
            add("p", Prologue(e, ctx))
            noteZone(e.z)
            group = { zone = e.z, quests = {}, t = e.t, isBegin = true }
        elseif e.k == "zone" then
            flush()
            noteZone(e.z)
            group = { zone = e.z, quests = {}, t = e.t, discovered = true }
        elseif e.k == "accept" or e.k == "q" then
            if not group or group.zone ~= e.z then
                flush()
                group = { zone = e.z, quests = {}, t = e.t }
            end
            group.quests[#group.quests + 1] = e
            if e.k == "q" then
                stats.q = stats.q + 1
            end
            noteZone(e.z)
            noteCompanions(e.p)
        elseif e.k == "dng" then
            flush()
            add("p", DungeonParagraph(e, ctx, used))
            stats.dng = stats.dng + 1
            noteCompanions(e.p)
        elseif e.k == "lvl" then
            flush()
            add("milestone", "Level " .. e.lvl)
            add("quote", LevelLine(e, ctx, hi))
        end
    end
    flush()
    if #passing > 0 then add("p", travelSentence(Hash(ch .. "end"))) end

    if #events == 0 then
        if ch == curCh and not hasBegin and ch == ns.BeginChapter() then
            add("p", Prologue({ lvl = UnitLevel("player"), z = CurrentZone(), t = time() }, ctx))
        end
        add("p", Format(ch == curCh and D.emptyCurrent or D.emptyPast, ctx))
    end

    -- Chapter summary
    local deaths = ns.char.deaths[ch] or 0
    if stats.q + stats.dng + deaths + #companions > 0 or ch == curCh then
        add("divider")
    end
    if ch == curCh then
        add("h2", "The Ink Is Still Wet")
        local ahead = D.foreshadow and D.foreshadow[ch]
        add("p", Format(D.present, ctx, { zone = Esc(CurrentZone() or "the wilds") })
            .. (ahead and (" " .. Format(ahead, ctx)) or ""))
    end
    if stats.q + stats.dng > 0 then
        local bits = { ns.Plural(stats.q, "deed") }
        if stats.nz > 0 then bits[#bits + 1] = ns.Plural(stats.nz, "land") end
        if stats.dng > 0 then bits[#bits + 1] = ns.Plural(stats.dng, "dungeon") end
        if deaths > 0 then bits[#bits + 1] = ns.Plural(deaths, "death") end
        add("meta", table.concat(bits, "  \194\183  "))
    end
    if deaths > 0 then
        add("quote", Format(deaths == 1 and D.deathsOne or D.deathsMany, ctx, { n = deaths }))
    end
    if #companions > 0 then
        add("h2", "Fellow Travelers")
        local ally, allyN = nil, 0
        for _, n in ipairs(companions) do
            local c = ns.char.companions[n]
            if c and (c.n or 0) > allyN then ally, allyN = n, c.n end
        end
        if ally and allyN >= 2 and D.allyLines then
            add("p", Format(Pick(D.allyLines, Hash(ally)), ctx,
                { ally = Esc(ally), times = ns.Plural(allyN, "adventure") }))
        end
        add("p", Esc(ns.Join(companions, 12)))
    end

    -- The quest log, told as unfinished business rather than a checklist
    if ch == curCh then
        local quests = ns.GetActiveQuests()
        if #quests > 0 then
            add("h2", "Threads Yet Unwoven")
            local pending, seen, ready = {}, {}, 0
            for _, q in ipairs(quests) do
                if q.done then
                    ready = ready + 1
                else
                    local qd = ns.char and ns.char.qdata and ns.char.qdata[q.id]
                    local d = Describe({
                        id = q.id, title = q.title,
                        obj = qd and qd.obj, desc = qd and qd.desc, npc = qd and qd.npc,
                    }, ctx)
                    if not d.vague and not seen[d.base] then
                        seen[d.base] = true
                        pending[#pending + 1] = Esc(d.base)
                    end
                end
            end
            local zoneX = { zone = Esc(CurrentZone() or "these lands") }
            local seed = Hash("threads" .. #quests .. ready)
            local s = {}
            if #pending > 0 then
                local shown = {}
                for k = 1, math.min(4, #pending) do shown[k] = pending[k] end
                zoneX.list = ns.Join(shown)
                s[#s + 1] = Format(Pick(D.threadsOpen, seed), ctx, zoneX)
                if #pending > 4 then s[#s + 1] = Format(Pick(D.threadsMore, seed + 1), ctx) end
            elseif ready == 0 then
                s[#s + 1] = Format(Pick(D.threadsVague, seed), ctx, zoneX)
            end
            if ready > 0 then
                s[#s + 1] = Format(ready == 1 and D.threadsReadyOne or D.threadsReadyMany, ctx)
            end
            add("p", table.concat(s, " "))
        end
    end
    return out
end

---------------------------------------------------------------------------
-- Companions page
---------------------------------------------------------------------------
function N.BuildCompanions()
    local D = ns.Data
    local ctx = Ctx()
    local out = {}
    local function add(kind, text) out[#out + 1] = { kind, text } end

    add("kicker", ns.Spaced("FELLOWSHIP"))
    add("title", "Companions")
    add("sub", Format("Those who walked beside {name}", ctx))
    add("divider")

    local list = {}
    for name, c in pairs(ns.char.companions) do list[#list + 1] = { name = name, c = c } end
    table.sort(list, function(a, b)
        if a.c.n ~= b.c.n then return a.c.n > b.c.n end
        return a.name < b.name
    end)

    if #list == 0 then
        add("p", Format(D.noCompanions, ctx))
        return out
    end

    for i, item in ipairs(list) do
        if i > 60 then
            add("meta", ("\226\128\166and %d more."):format(#list - 60))
            break
        end
        local c = item.c
        local bits = {}
        local cls = c.c and LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[c.c]
        if cls then bits[#bits + 1] = cls end
        bits[#bits + 1] = ns.Plural(c.n, "shared adventure")
        if c.f then bits[#bits + 1] = "first met " .. date("%b %d, %Y", c.f) end
        add("h2", Esc(item.name))
        add("meta", table.concat(bits, "  \194\183  "))
        if c.d then
            local ds = {}
            for d in pairs(c.d) do ds[#ds + 1] = Esc(d) end
            table.sort(ds)
            add("p", "Together they braved " .. ns.Join(ds) .. ".")
        end
    end
    return out
end

-- A title the hero earns as the chapters pass, e.g. "the Tested".
function N.Epithet(level)
    local D = ns.Data
    local ch = ns.ChapterOf(level or 1)
    return (D.epithets and D.epithets[ch]) or D.epithetBeyond or ""
end

function N.CompanionCount()
    local n = 0
    for _ in pairs(ns.char.companions) do n = n + 1 end
    return n
end

function N.DeedCount()
    local n = 0
    for _, e in ipairs(ns.char.events) do
        if e.k == "q" then n = n + 1 end
    end
    return n
end
