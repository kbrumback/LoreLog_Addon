-- Lore Log: Data
-- All narrative building blocks. Tokens in {braces} are filled by the Narrator.
-- Common tokens: {name} {race} {class} {classLower} {he} {him} {his} {He} {His}
--                {gender} {aRaceClass} {zone} {companions} {dungeon}
--                {bosses} {level} {strike} {zones} {pre} {n}
-- Scene tokens:  {npc} {turnin} {names} {base} {past} {past2} {perfect} {gerund}
--                {list}
local ADDON, ns = ...
local D = {}
ns.Data = D

---------------------------------------------------------------------------
-- Chapters
---------------------------------------------------------------------------
D.chapterTitles = {
    "The Dawn of a Name",             -- 1-5
    "Beyond the Hearthfire",          -- 6-10
    "Where the Roads Divide",         -- 11-15
    "Forged in Trial",                -- 16-20
    "Whispers of the Dark",           -- 21-25
    "Steel and Oath",                 -- 26-30
    "Into the Untamed Wilds",         -- 31-35
    "The Weight of Renown",           -- 36-40
    "Where Legends Are Wrought",      -- 41-45
    "Embers of a Dying Age",          -- 46-50
    "The Gathering Storm",            -- 51-55
    "At the Threshold of Legend",     -- 56-60
}
D.chapterBeyond = "Beyond the Known Pages"

D.chapterIntros = {
    "Every legend begins in obscurity. For {name}, the first lessons were bitter and hard-won, and the world stretched out vast and unknowable beyond the hearthlight.",
    "The familiar fields faded behind {him}. {name} began to see that Azeroth was older, wider and stranger than {he} had ever dared to dream.",
    "With courage kindled and a name beginning to travel, {name} took to roads that wound ever farther from the place {he} once called home.",
    "The trials came harder now, as trials do for those marked for greater things, and {name} met each one a little stronger than the last.",
    "A shadow was stirring in the world. Its rumor reached {name} on the lips of frightened travelers, and {he} felt the first cold breath of what was to come.",
    "Steel and spell had become second nature. {name} now walked with the bearing of a seasoned {classLower}, and lesser folk stepped aside.",
    "The maps ran thin and the lands grew wild. {name} pressed on into country where few had walked and fewer had returned.",
    "Strangers began to speak the name of {name} before ever meeting {him}, and songs that did not yet exist began to wait for their verses.",
    "This was the forge where legends are wrought, or shattered. {name} had resolved to be the former.",
    "Ancient powers woke across the world, and {name} was drawn, step by inevitable step, toward the heart of their gathering.",
    "The sky darkened over Azeroth, and a storm long foretold at last drew near. {name} stood among the few who would not flee from it.",
    "The final ascent toward legend. Every scar, every friend, every fallen foe had led {name} to this hour, and the world held its breath.",
}
D.chapterBeyondIntro = "The chronicle reaches past the known pages, into the unwritten dark. {name}'s story is far from over."

D.lostPages    = "These pages were never inked. The chronicle began later in {name}'s journey, and what came before lives only in memory and in the dust of old roads."
D.emptyCurrent = "The page lies blank, waiting. The next deed will give it voice."
D.emptyPast    = "The road through these levels went unrecorded, a quiet stretch of years between the greater tales."
D.present      = "At level {level}, {name} stands in {zone}, and the next page of the saga is yet unwritten."
D.newChapter   = "A new chapter of the saga begins."
D.noCompanions = "No companion has yet shared {name}'s road. Those who fight beside {him} in the deep places, and who stand shoulder to shoulder with {him} in deeds well done, will be remembered here."

---------------------------------------------------------------------------
-- Character flavour
---------------------------------------------------------------------------
D.raceOrigin = {
    -- WoW Forever: The Skyborne (shen'dorei)
    Skyborne         = "heir to the ancient Highborne exiles of Zephras Isle",
    SkyborneElf      = "heir to the ancient Highborne exiles of Zephras Isle",
    Shendorei        = "heir to the ancient Highborne exiles of Zephras Isle",
    HighOrder        = "bearing ancient arcane mastery down from the heights of Zephras Isle to stand with the Alliance",
    Windshaper       = "attuned to the living storms of Zephras Isle and sworn to walk beside the Horde",

    -- Classic Playable Races
    Human    = "raised beneath the white spires of Stormwind",
    Dwarf    = "born in the snow-bound halls of Ironforge, where the forges never sleep",
    NightElf = "a child of the ancient boughs of Teldrassil, nursed on moonlight and old memory",
    Gnome    = "a tinkerer cast out from fallen Gnomeregan, with a bright mind and a long grudge",
    Orc      = "a free-born child of the Horde, forged in the red dust of Durotar",
    Scourge  = "risen from the grave with a will once more {his} own",
    Undead   = "risen from the grave with a will once more {his} own",
    Tauren   = "of the windswept plains of Mulgore, where the Earth Mother still listens",
    Troll    = "of the Darkspear tribe, born beneath the sun-baked cliffs of the Echo Isles",
    BloodElf = "of Quel'Thalas, where the memory of the Sunwell still burns",
    Draenei  = "a wanderer from the shattered Exodar, bearing the hope of a lost world",
    Goblin   = "a sharp-eyed opportunist schooled in the cutthroat courts of the trade princes",
    Worgen   = "of cursed Gilneas, noble and beast both",
    Pandaren = "a traveler from the mists of the Wandering Isle",
    default  = "whose origins are written in another book",
}

function D.GetRaceOrigin(raceFile, raceName, factionGroup)
    local rF = tostring(raceFile or "")
    local rN = tostring(raceName or "")
    local combined = (rF .. " " .. rN):lower()

    if combined:find("skyborne") or combined:find("shendorei") or combined:find("shen'dorei") then
        if factionGroup == "Alliance" or combined:find("high%s*order") then
            return D.raceOrigin.HighOrder
        elseif factionGroup == "Horde" or combined:find("windshaper") then
            return D.raceOrigin.Windshaper
        end
        return D.raceOrigin.Skyborne
    end

    if D.raceOrigin[rF] then return D.raceOrigin[rF] end
    if D.raceOrigin[rN] then return D.raceOrigin[rN] end

    local cleanF = rF:gsub("%s+", "")
    if D.raceOrigin[cleanF] then return D.raceOrigin[cleanF] end
    local cleanN = rN:gsub("%s+", "")
    if D.raceOrigin[cleanN] then return D.raceOrigin[cleanN] end

    if combined:find("night%s*elf") then return D.raceOrigin.NightElf end
    if combined:find("blood%s*elf") then return D.raceOrigin.BloodElf end
    if combined:find("human") then return D.raceOrigin.Human end
    if combined:find("dwarf") then return D.raceOrigin.Dwarf end
    if combined:find("gnome") then return D.raceOrigin.Gnome end
    if combined:find("orc") then return D.raceOrigin.Orc end
    if combined:find("undead") or combined:find("forsaken") or combined:find("scourge") then return D.raceOrigin.Undead end
    if combined:find("tauren") then return D.raceOrigin.Tauren end
    if combined:find("troll") then return D.raceOrigin.Troll end

    return D.raceOrigin.default
end

D.classCalling = {
    WARRIOR     = "who answers every question with tempered steel",
    PALADIN     = "sworn to bear the Light into every place darkness gathers",
    HUNTER      = "keen of eye, tireless of foot, and never far from a loyal beast",
    ROGUE       = "who prefers shadow to spotlight and the dagger to the debate",
    PRIEST      = "a voice of faith in a world that sorely needs one",
    SHAMAN      = "who hears the restless whispers of the elements and answers them",
    MAGE        = "a student of the arcane, ever hungry for its forbidden secrets",
    WARLOCK     = "who strikes bargains that wiser souls would refuse",
    DRUID       = "a keeper of the wild balance, shaped by claw and leaf and moon",
    DEATHKNIGHT = "who has known death and returned colder for it",
    MONK        = "whose fists and spirit move as one",
    DEMONHUNTER = "who gave up {his} sight to hunt the Legion in the dark",
    EVOKER      = "who carries the ancient fire of the dragonflights",
    default     = "whose path is still being chosen",
}

-- Used as: "{name} ... {strike} those who stood in the way"
D.classStrike = {
    WARRIOR = { "cut down", "cleaved through", "shattered the ranks of" },
    PALADIN = { "smote", "brought holy judgment upon", "struck down" },
    HUNTER  = { "loosed arrows upon", "hunted down", "tracked and felled" },
    ROGUE   = { "silenced", "ambushed", "left a trail of quiet ruin among" },
    PRIEST  = { "purged", "banished", "laid low" },
    SHAMAN  = { "called lightning down upon", "broke with earth and storm", "scattered" },
    MAGE    = { "reduced to ash", "froze and shattered", "unleashed arcane fury upon" },
    WARLOCK = { "withered with shadow", "set demons upon", "cursed and consumed" },
    DRUID   = { "tore through", "entangled and overwhelmed", "fell upon in a fury of claw and moonfire" },
    default = { "defeated", "overcame", "struck down" },
}

-- A single line of colour dropped into a scene after its first fight.
D.classFlavor = {
    WARRIOR = {
        "{His} blade did most of the talking, and it spoke without mercy.",
        "Steel rang upon steel, and it was {his} steel that rang last.",
        "{He} waded into the fray shield-first, as the old warriors did.",
        "Every battle ended the same way: with {name} still standing.",
    },
    PALADIN = {
        "The Light burned bright in {his} hands, and darkness recoiled.",
        "{He} fought with hammer and prayer in equal measure.",
        "Where {he} walked, the shadows seemed to shrink back in fear.",
        "{His} oaths held, and so did {his} shield.",
    },
    HUNTER = {
        "{His} arrows rarely missed, and {his} beast never strayed far from {his} side.",
        "{He} tracked {his} quarry with the patience of a true hunter.",
        "Few things escaped {his} eye, and fewer still escaped {his} bow.",
    },
    ROGUE = {
        "Most of {his} foes never saw the blade that ended them.",
        "{He} struck from the shadows and was gone before a cry could rise.",
        "{He} preferred a quiet knife to a loud battle, and the work went smoother for it.",
    },
    PRIEST = {
        "{His} prayers mended wounds as swiftly as {his} shadows opened them.",
        "Faith steadied {his} hand when the fighting turned grim.",
        "{He} carried the Light into places that had long forgotten it.",
    },
    SHAMAN = {
        "The elements answered when {he} called, and they did not answer gently.",
        "Thunder followed in {his} wake.",
        "Earth, fire and storm fought at {his} side like old comrades.",
    },
    MAGE = {
        "Frost and fire answered {his} call.",
        "More than one foe ended the day as a scorch mark upon the ground.",
        "{He} solved most problems the way mages do: loudly, and with fire.",
    },
    WARLOCK = {
        "Shadow and fel did {his} bidding, and {his} demon did the rest.",
        "{His} curses were slow, but they were certain.",
        "Wiser souls might have flinched at the powers {he} wielded. {He} did not.",
    },
    DRUID = {
        "{He} moved between shapes as easily as breathing.",
        "Claw, root and moonfire all served {him} well.",
        "The wild itself seemed to rise and fight upon {his} side.",
    },
    DEATHKNIGHT = {
        "Runes burned cold along {his} blade.",
        "{He} fought without fear, having already met death once and found it wanting.",
    },
    MONK = {
        "{He} moved through the fighting like water around stone.",
        "Fist and breath, strike and stillness: {he} made it look easy.",
    },
    DEMONHUNTER = {
        "{His} glaives sang, and fel fire followed.",
        "{He} hunted by senses no mortal eye could match.",
    },
    EVOKER = {
        "Dragonfire answered {his} call.",
        "{He} fought with the old fury of the dragonflights.",
    },
    default = {
        "{He} fought well, and {his} foes learned to regret it.",
        "It was hard work, and {he} did it well.",
    },
}

---------------------------------------------------------------------------
-- Prologue
---------------------------------------------------------------------------
D.prologue = {
    "Hear now the first page of a saga yet to be sung. It opens in {zone}, with {name}: {aRaceClass}, {calling}.",
    "Let it be written that in {zone}, {name} took the first step upon a long and perilous road: {aRaceClass}, {calling}.",
    "Thus begins the chronicle, in {zone}. Its hero is {name}: {aRaceClass}, {calling}.",
}
D.prologueSkyborne = {
    "High above the clouds of Azeroth, upon the floating crags of Zephras Isle, the chronicle of {name} begins. For ten thousand years the shen'dorei dwelt sheltered within the elemental realm of Skywall. Now the winds have shifted, and {name} steps forth into the wider world: {aRaceClass}, {calling}.",
    "The sanctuary of Zephras Isle kept the hidden people safe since the Great Sundering, but no peace endures forever. Here, upon the wind-carved towers, {name} took up the mantle of adventure: {aRaceClass}, {calling}.",
    "A new age dawns for the shen'dorei. Leaving the ancient heights of Zephras Isle behind, {name} sets out across Azeroth: {aRaceClass}, {calling}.",
}
D.prologueLate = "By then {name} had already reached level {level}, and many roads lay behind {him}, their stories untold."
D.prologuePre  = "{pre} deeds were already done before these pages were first inked, their details lost to the wind and the years."

---------------------------------------------------------------------------
-- Quests: classification
---------------------------------------------------------------------------
-- Checked in this order against the lowercased objective, premise and title.
D.categoryOrder = { "rescue", "combat", "mystery", "gather", "delivery" }
D.keywords = {
    rescue   = { "rescue", "missing", "lost ", "save ", "escape", "escort", "captive", "prisoner", "freedom",
                 "trapped", "injured", "wounded", "help ", "aid ", "blanchy" },
    combat   = { "kill", "slay", "slain", "hunt", "bounty", "cull", "destroy", "defeat", "wanted", "threat", "menace",
                 "assault", "attack", "battle", "invader", "raid", "purge", "vengeance", "revenge", "bane", "blood",
                 "brotherhood", "defias", "gnoll", "murloc", "kobold", "bandit", "thief", "thieves", "outlaw", "pirate",
                 "trogg", "spider", "wolf", "wolves", "boar", "bear", "lion", "tiger", "raptor", "beast", "ogre",
                 "dragon", "whelp", "drake", "elemental", "demon", "scourge", "undead", "ghoul", "zombie", "skeleton",
                 "cultist", "syndicate", "shadow council" },
    mystery  = { "secret", "myster", "investigat", "strange", "ancient", "relic", "artifact", "tome", "scroll",
                 "ritual", "curse", "vision", "spirit", "forgotten", "ruin", "tomb", "crypt", "mine", "barrow",
                 "cavern", "cave", "shrine", "altar", "temple", "tablet", "monument", "omen", "legend", "heirloom" },
    gather   = { "collect", "gather", "supplies", "harvest", "sample", "pelt", "ore", "herb", "ingredient",
                 "recipe", "cook", "meat", "fish", "fur", "hide", "egg", "venom", "essence", "crystal", "candle",
                 "tail", "fang", "tooth", "teeth", "claw", "bone", "horn", "scale", "eye", "ear", "head", "wing",
                 "feather", "timber", "wood", "gold", "silver", "iron", "copper", "pearl", "mushroom", "fungus",
                 "grain", "wheat", "flour", "exchange", "provisions", "reagent", "potion", "water", "ale", "wine",
                 "barrel", "ration", "goulash" },
    delivery = { "deliver", "report", "letter", "message", "note", "return", "speak", "seek", "journey",
                 "travel", "package", "crate", "orders", "envoy", "dispatch", "courier", "errand", "post" },
}

---------------------------------------------------------------------------
-- Quests: scenes
-- Each stay in a zone is told as one short passage. Deeds are woven together
-- with connecting phrases instead of being listed one per paragraph, and the
-- people involved are named only a few times per scene.
-- Deed tokens: {base} "thin out the Riverpaw Gnolls"
--              {past} "thinned out the Riverpaw Gnolls"
--              {perfect} "thinned out the Riverpaw Gnolls" (after "had")
--              {gerund} "thinning out the Riverpaw Gnolls"
---------------------------------------------------------------------------
D.sceneHook = {
    "It was {npc} who first called upon {him}, and so the tale began.",
    "{npc} bore troubles enough to occupy any {classLower}, and fate had sent one to the door.",
    "{npc} was quick to take the measure of the newcomer, and quicker still to find a use for {him}.",
    "Before {he} had even caught {his} breath, {npc} stood before {him} with a plea.",
    "Word of a capable {classLower} had reached {npc}, and with it, the requests.",
    "{npc} looked once upon {name} and judged that {he} would do.",
}

D.sceneFirst = {
    "{He} {past}.",
    "Before long, {he} had {perfect}.",
    "The first task was to {base}, and {he} saw it done.",
    "{His} days there began with {gerund}.",
    "There was no time to rest; {he} {past}.",
}
D.sceneFirstPair = {
    "{He} {past}, and then {past2}.",
    "First {he} {past}; soon after, {he} {past2}.",
    "{He} {past} and, before the day was out, {past2}.",
}
D.sceneNext = {
    "After that, {he} {past}.",
    "Then came the call to {base}, and {he} answered.",
    "Not long after, {he} had {perfect}.",
    "In time, {he} {past}.",
    "When that was done, {he} {past}.",
    "Still there was more to do: {he} {past}.",
}
D.sceneNextPair = {
    "In time {he} {past}, and after that {past2}.",
    "In the days that followed, {he} {past} and {past2}.",
    "Then {he} {past}, and {past2} besides.",
}

-- A deed promised in an earlier scene and finally completed here.
D.sceneKept = {
    "{He} kept {his} word to {npc} and {past}.",
    "True to {his} oath to {npc}, {he} {past}.",
}
D.sceneKeptAnon = {
    "True to an old promise, {he} {past}.",
    "{He} made good on a vow long carried and {past}.",
}

D.sceneErrands = {
    "Errands carried {him} back and forth between {names}.",
    "In the quiet hours, there were messages to bear for {names}.",
    "{He} spent no small part of {his} days carrying word to {names}.",
}
D.sceneErrandsAnon = {
    "In the lulls between, there were messages to carry and errands to run.",
    "Not every task called for a blade; some asked only for a pair of willing feet.",
}

D.sceneDungeon = {
    "Some of that work led {him} down into the dark of {dungeon}.",
    "Part of it drew {him} into the depths of {dungeon}, where daylight is only a rumor.",
}

D.sceneCompanions = {
    "{companions} fought at {his} side through part of it.",
    "{He} did not walk that road alone; {companions} shared it for a time.",
    "For a while, {companions} walked with {him}, and the burden grew lighter for it.",
}

D.sceneMore = {
    "And there was more besides: small deeds, quietly done, that filled the hours between the greater ones.",
    "Lesser tasks filled the gaps, the kind no bard sings of but every village remembers.",
    "Countless smaller favors went unrecorded, though never unappreciated.",
}
D.sceneVagueOnly = {
    "{He} lent a hand wherever one was needed.",
    "There was work to be done, and {he} did it without complaint.",
    "The tasks were small, but {he} saw every one of them through.",
}

D.scenePromise = {
    "Before moving on, {he} gave {npc} {his} solemn word to {base}.",
    "{npc} had one more boon to ask: that {he} {base}. {He} agreed.",
    "{He} also swore to {npc} that {he} would {base}, a deed for another day.",
}
D.scenePromiseAnon = {
    "{He} also resolved to {base}, though that task would have to wait for another dawn.",
    "One more task lingered at the back of {his} mind: to {base}.",
    "Before moving on, {he} vowed to {base}.",
}
D.scenePromiseMany = {
    "{He} left with more promises than {he} had arrived with.",
    "By the time {he} set out again, {his} pack was heavy and {his} list of oaths longer still.",
}

D.sceneClose = {
    "When it was done, {turnin} had good reason to remember the name {name}.",
    "{turnin} was the first to offer thanks, though by no means the last.",
    "{turnin} pressed a few coins into {his} hand, and a good word into the ears of all who would listen.",
}
-- Used when the closing figure was already named earlier in the scene.
D.sceneCloseKnown = {
    "By the end, even {turnin} had run out of things to ask of {him}.",
    "{turnin} could hardly find the words to thank {him}.",
}
D.sceneCloseAnon = {
    "By the time {he} moved on, the folk of {zone} had good reason to remember {his} name.",
    "{zone} was a little safer for {his} passing.",
    "When {he} finally departed, {zone} was quieter than {he} had found it.",
}

---------------------------------------------------------------------------
-- Quests: the active quest log, told as prose
---------------------------------------------------------------------------
D.threadsOpen = {
    "Unfinished business still trailed {him} through {zone}. {He} had yet to {list}.",
    "The road ahead was already crowded with promises: {he} had still to {list}.",
    "Not every thread of this tale has found its ending. {name} had still to {list}.",
}
D.threadsMore    = { "Other oaths waited further down the road.", "And those were only the most pressing of them." }
D.threadsVague   = { "Promises made but not yet kept still weighed upon {him} in {zone}." }
D.threadsReadyOne  = "One deed was already finished, waiting only to be told."
D.threadsReadyMany = "Several deeds were already finished, waiting only to be told."

---------------------------------------------------------------------------
-- Quests: live chat announcements (one deed at a time)
---------------------------------------------------------------------------
D.chatAccept = {
    withNPC = {
        "{npc} called upon {name} to {action}, and {he} answered.",
        "{name} gave {npc} {his} word: {he} would {action}.",
        "{npc} had need of a {classLower}. {name} set forth to {action}.",
        "{name} swore to {npc} that {he} would {action}.",
        "At {npc}'s urging, {name} set forth to {action}.",
    },
    noNPC = {
        "{name} set forth to {action}.",
        "{name} resolved that the hour had come to {action}.",
        "A new trial lay ahead: {name} vowed to {action}.",
    },
}

D.chatTurnin = {
    withNPC = {
        "Having {actionPerfect}, {name} returned to {turnin} to tell the tale.",
        "{name} came back to {turnin}, having {actionPerfect}.",
        "{name} {actionPast} and brought word to {turnin}.",
        "Word reached {turnin} that {name} had {actionPerfect}.",
        "{turnin} nodded with grim satisfaction as {name} delivered word of victory.",
        "{name} stood before {turnin} once more, the deed accomplished.",
    },
    noNPC = {
        "{name} {actionPast}.",
        "It took some doing, but {name} {actionPast}.",
        "With steady resolve, {name} {actionPast}.",
        "The deed was done as {name} {actionPast}.",
    },
    errand = {
        "{name} bore word to {turnin}.",
        "{name} made the long journey to {turnin}, as asked.",
        "{name} reached {turnin} and delivered {his} report.",
    },
    vague = {
        "{turnin} gave thanks to {name} for {his} help.",
        "Another favor repaid; {turnin} had {name} to thank.",
        "{name} completed the undertaking for {turnin}.",
    },
    vagueNoNPC = {
        "{name} saw another task through to its end.",
    },
}

---------------------------------------------------------------------------
-- Travel
---------------------------------------------------------------------------
D.zoneSpecial = {
    ["Zephras Isle"] = "{name} walked among the floating crags of Zephras Isle, where elemental winds whisper through ancient Highborne ruins and the memory of ten thousand years.",
}

D.zoneDiscover = {
    "Fresh horizons beckoned as {name} set foot in {zone} for the first time.",
    "The road led on to {zone}, a land {name} had known only in whispered tales.",
    "{zone} rose before {name}: new skies, new perils, and no shortage of people in need.",
    "{name} crested a rise and beheld {zone} spread out below, wide and unknown.",
    "It was {name}'s first sight of {zone}, and {he} paused a long moment to take it in.",
}
D.zoneReturn = {
    "The road led back to {zone}, as old roads will.",
    "{name} found {his} way to {zone} once more.",
    "Before long, {name} was back in {zone}.",
    "Once more, {zone} called {name} home.",
}
D.zoneContinue = {
    "{name} lingered in {zone}.",
    "There was more to be done in {zone}.",
    "{name} was not yet finished with {zone}.",
    "{zone} still had need of {him}.",
}
D.travelThrough = {
    "The road carried {name} through {zones}.",
    "{name} passed through {zones}, pausing only briefly.",
    "{His} travels took {him} through {zones} with little cause to linger.",
}

---------------------------------------------------------------------------
-- Dungeons
---------------------------------------------------------------------------
D.dungeonParty = {
    "Deep within {dungeon}, {name} fought alongside {companions}.",
    "{dungeon} swallowed the light, yet {name} pressed into its depths with {companions}.",
    "Few walk into {dungeon} by choice. {name} did, with {companions} at {his} side.",
}
D.raidParty = {
    "{name} joined a great host, {companions} among them, to challenge {dungeon}.",
    "Banners raised and blades drawn, {name} marched upon {dungeon} with {companions}.",
}
D.dungeonSolo = {
    "{name} ventured into {dungeon} alone.",
    "With no one to guard {his} back, {name} descended into {dungeon}.",
}
D.bossesGroup = {
    "Together they brought down {bosses}.",
    "When the dust settled, {bosses} lay defeated.",
    "{bosses} would trouble the world no longer.",
}
D.bossesSolo = {
    "There, {bosses} fell before {him}.",
    "{bosses} would trouble the world no longer.",
}
D.dungeonNoBoss = {
    "What horrors lurked within, the chronicle does not say, only that {name} walked out again.",
    "The depths kept their secrets, but {name} returned to tell of them.",
}

---------------------------------------------------------------------------
-- Levels
---------------------------------------------------------------------------
D.levelLines = {
    -- Chapter boundaries: each one closes a chapter and points toward the next.
    [6]  = "The first chapter closed behind {him}. {name} was a stranger to the road no longer, and the hearthfire had begun to fade from memory.",
    [11] = "The last familiar landmark slipped from sight. Ahead the roads began to divide, and {name} chose, as heroes must, to go on.",
    [16] = "Roads that once seemed endless had become paths {name} knew by heart. Harder trials were waiting, and {he} had begun to welcome them.",
    [21] = "The trials had left their mark, and {name} wore it well. Somewhere ahead, something old and patient was beginning to stir.",
    [26] = "The first whispers of darkness had hardened into certainty, and {name} did not turn back from them.",
    [31] = "Steel and oath were one now, and {name} stood tempered and ready. The maps were about to run out.",
    [36] = "The wild lands had tested {him} and been answered. Word of {name} had begun to travel faster than {he} could.",
    [41] = "Renown had found {name}, as it finds those who do not seek it. What it asks in return is greater deeds.",
    [46] = "The forge had done its work, and the hero who left it was not the one who entered. Ahead, an old age was dying, and its embers burned bright.",
    [51] = "Embers had flared into flame, and flame into the first thunder of a distant storm. {name} faced it without flinching.",
    [56] = "The storm was nearly upon the world. Only a few steps remained between {name} and the threshold of legend.",
    [61] = "The known pages end here, but the tale does not.",
    -- Milestones within a chapter
    [10] = "New powers stirred within, the first true sign of who {name} might yet become.",
    [20] = "By now the name {name} was spoken in taverns, and not always in whispers.",
    [30] = "Halfway to legend. The road behind was long, the road ahead longer still.",
    [40] = "At last {name} earned the right to ride, and the world grew a little smaller beneath {his} mount.",
    [50] = "Few reach such heights. Fewer still remain humble there.",
    [60] = "The summit at last. Level 60, and the greatest legends begin here.",
}
D.levelDefault = {
    "Stronger than before, {name} pressed on.",
    "Each scar told a story, and each story made {him} stronger.",
    "Another step upon the long road.",
    "Power gathered quietly within {him}, like a storm upon the horizon.",
    "The world had tested {name}, and {name} had answered.",
}

D.deathsOne  = "Death claimed {him} once in these pages, though not for long."
D.deathsMany = "Death claimed {him} {n} times in these pages, and each time {name} rose again."

---------------------------------------------------------------------------
-- The shape of the whole saga
---------------------------------------------------------------------------
-- Appended to the hero's name in the book's title, growing with each chapter.
D.epithets = {
    "the Unproven", "the Wanderer", "the Pathfinder", "the Tested", "the Watchful", "the Sworn",
    "the Far-Walker", "the Renowned", "the Forged", "the Ember-Touched", "the Stormwarden", "the Undaunted",
}
D.epithetBeyond = "the Legend"

-- Shown after "the next page is yet unwritten", hinting at the chapter to come.
D.foreshadow = {
    "Beyond the last hearthfire, the wider world was waiting.",
    "The roads ahead promised more than {he} yet understood.",
    "Harder trials lay ahead, and {he} would meet them.",
    "Something older than any rumor was stirring in the dark.",
    "The darkness was gathering, and {he} would soon have to face it.",
    "The maps were about to run out.",
    "Renown was coming, whether {he} wanted it or not.",
    "Legends are wrought in fire, and the forge was drawing near.",
    "Old powers were waking, and {his} road led toward them.",
    "A storm was gathering on the horizon.",
    "The threshold of legend was close at hand.",
    "What came after was not yet written.",
}

-- The companion who stood with the hero most often.
D.allyLines = {
    "Of all who shared {his} road, none stood with {him} more often than {ally}, and the bond held through {times}.",
    "{ally} was the one {name} could count on, shoulder to shoulder through {times}.",
    "Songs favor lone heroes, but {name} was never truly alone. {ally} was there for {times}.",
}
