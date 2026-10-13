-- Lore Log: UI
-- The book window. Built lazily on first open; renders only the selected
-- chapter and only while visible.
local ADDON, ns = ...
local UI = {}
ns.UI = UI

local WHITE = "Interface\\Buttons\\WHITE8x8"
local BACKDROP_TPL = BackdropTemplateMixin and "BackdropTemplate" or nil
local FRAME_W, FRAME_H = 820, 590
local HEADER_H = 72
local SIDEBAR_W = 226
local NAV_H = 44
local PAD_X, PAD_TOP, PAD_RIGHT, PAD_BOTTOM = 26, 20, 36, 20
local CONTENT_W = 516

-- Typography per block kind. `font` is a theme font role.
local STYLE = {
    kicker    = { font = "heading", size = 11,   color = "accent",  justify = "CENTER", after = 6 },
    title     = { font = "title",   size = 23,   color = "title",   justify = "CENTER", after = 6 },
    sub       = { font = "meta",    size = 12,   color = "meta",    justify = "CENTER", after = 6 },
    h2        = { font = "heading", size = 15,   color = "heading", after = 8 },
    p         = { font = "body",    size = 14,   color = "body",    after = 14 },
    quote     = { font = "meta",    size = 13.5, color = "body",    after = 14, indent = 16 },
    milestone = { font = "heading", size = 14,   color = "accent",  after = 4 },
    deeds     = { font = "meta",    size = 12,   color = "meta",    after = 14, indent = 12 },
    bullet    = { font = "body",    size = 13,   color = "body",    after = 6,  indent = 10 },
    meta      = { font = "meta",    size = 12,   color = "meta",    after = 10 },
}

local frame, sidebar, navChild, scroll, content, track, thumb
local titleFS, subFS, themeBtn
local selected, appliedTheme
local fsPool, fsUsed = {}, 0
local texPool, texUsed = {}, 0
local navButtons, textButtons = {}, {}

local function Theme() return ns.Themes.Get(ns.db.theme) end

local function C(key, alphaMul)
    local c = Theme().colors[key]
    return c[1], c[2], c[3], (c[4] or 1) * (alphaMul or 1)
end

local function SetFS(fs, role, size, unscaled)
    local t = Theme()
    local path = ns.Themes.ResolveFont(t.fonts[role] or t.fonts.body)
    local mul = (t.scale[role] or 1) * (unscaled and 1 or (ns.db.fontScale or 1))
    fs:SetFont(path, size * mul, "")
end

function UI.AccentHex()
    local r, g, b = C("accent")
    return ("%02x%02x%02x"):format(math.floor(r * 255), math.floor(g * 255), math.floor(b * 255))
end

local function SetGradient(tex, top, bottom)
    tex:SetColorTexture(1, 1, 1, 1)
    local ok = CreateColor and pcall(tex.SetGradient, tex, "VERTICAL",
        CreateColor(bottom[1], bottom[2], bottom[3], 1), CreateColor(top[1], top[2], top[3], 1))
    if not ok then tex:SetColorTexture(top[1], top[2], top[3], 1) end
end

---------------------------------------------------------------------------
-- Scrollbar (thin, themed; OnUpdate only while dragging)
---------------------------------------------------------------------------
local function UpdateThumb()
    if not track then return end
    local range = scroll:GetVerticalScrollRange()
    if range <= 0 then track:Hide() return end
    track:Show()
    local h = track:GetHeight()
    local view = scroll:GetHeight()
    local th = math.max(28, h * view / (view + range))
    thumb:SetHeight(th)
    local off = (h - th) * (scroll:GetVerticalScroll() / range)
    thumb:ClearAllPoints()
    thumb:SetPoint("TOP", track, "TOP", 0, -off)
end

local function ScrollTo(v)
    local range = scroll:GetVerticalScrollRange()
    scroll:SetVerticalScroll(math.max(0, math.min(v, range)))
    UpdateThumb()
end

---------------------------------------------------------------------------
-- Widgets
---------------------------------------------------------------------------
function UI.StyleTextButton(b)
    local path = b.font or ns.Themes.ResolveFont(Theme().fonts.heading)
    b.text:SetFont(path, b.fontSize or 12, "")
    b.text:SetText(b.labelFn and b.labelFn() or b.label)
    b:SetBackdropColor(C("accent", b.hover and 0.26 or 0.08))
    b:SetBackdropBorderColor(C("accent", b.hover and 0.9 or 0.4))
    b.text:SetTextColor(C(b.hover and "title" or "heading"))
end

local function TextButton(parent, w, h, label, onClick, tip)
    local b = CreateFrame("Button", nil, parent, BACKDROP_TPL)
    b:SetSize(w, h)
    b:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b.text = b:CreateFontString(nil, "OVERLAY")
    b.text:SetPoint("CENTER", 0, 0)
    b.label = label
    b:SetScript("OnClick", onClick)
    b:SetScript("OnEnter", function(self)
        self.hover = true
        UI.StyleTextButton(self)
        if tip then
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
            GameTooltip:SetText(tip[1], 1, 0.82, 0)
            if tip[2] then GameTooltip:AddLine(tip[2], 1, 1, 1, true) end
            GameTooltip:Show()
        end
    end)
    b:SetScript("OnLeave", function(self)
        self.hover = false
        UI.StyleTextButton(self)
        GameTooltip:Hide()
    end)
    textButtons[#textButtons + 1] = b
    return b
end

local function FontNav(b)
    SetFS(b.num, "heading", 14, true)
    SetFS(b.title, "heading", 12, true)
    SetFS(b.range, "meta", 10.5, true)
end

local function StyleNav(b)
    local isSel = b.key == selected
    if isSel then
        b.bg:SetColorTexture(C("select"))
    elseif b.hover then
        b.bg:SetColorTexture(C("accent", 0.07))
    else
        b.bg:SetColorTexture(0, 0, 0, 0)
    end
    b.bar:SetColorTexture(C("accent"))
    b.bar:SetShown(isSel)
    b.num:SetTextColor(C("accent", isSel and 1 or 0.75))
    b.title:SetTextColor(C(isSel and "title" or "heading"))
    b.range:SetTextColor(C("meta"))
end

local function NavButton(i)
    local b = navButtons[i]
    if b then return b end
    b = CreateFrame("Button", nil, navChild)
    b:SetSize(SIDEBAR_W, NAV_H)
    b:SetPoint("TOPLEFT", 0, -8 - (i - 1) * NAV_H)
    b.bg = b:CreateTexture(nil, "BACKGROUND")
    b.bg:SetAllPoints()
    b.bar = b:CreateTexture(nil, "ARTWORK")
    b.bar:SetPoint("TOPLEFT", 0, -4)
    b.bar:SetPoint("BOTTOMLEFT", 0, 4)
    b.bar:SetWidth(3)
    b.num = b:CreateFontString(nil, "OVERLAY")
    b.num:SetPoint("LEFT", 10, 0)
    b.num:SetWidth(28)
    b.num:SetJustifyH("LEFT")
    b.title = b:CreateFontString(nil, "OVERLAY")
    b.title:SetPoint("TOPLEFT", 42, -6)
    b.title:SetPoint("RIGHT", -8, 0)
    b.title:SetJustifyH("LEFT")
    b.title:SetWordWrap(false)
    b.range = b:CreateFontString(nil, "OVERLAY")
    b.range:SetPoint("TOPLEFT", b.title, "BOTTOMLEFT", 0, -2)
    b.range:SetPoint("RIGHT", -8, 0)
    b.range:SetJustifyH("LEFT")
    b.range:SetWordWrap(false)
    b:SetScript("OnClick", function(self) UI.Select(self.key) end)
    b:SetScript("OnEnter", function(self) self.hover = true; StyleNav(self) end)
    b:SetScript("OnLeave", function(self) self.hover = false; StyleNav(self) end)
    FontNav(b)
    navButtons[i] = b
    return b
end

---------------------------------------------------------------------------
-- Frame
---------------------------------------------------------------------------
function UI.Create()
    if frame then return frame end

    frame = CreateFrame("Frame", "LoreLogFrame", UIParent, BACKDROP_TPL)
    frame:SetSize(FRAME_W, FRAME_H)
    frame:SetFrameStrata("HIGH")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local p, _, rp, x, y = self:GetPoint()
        ns.db.pos = { p, rp, x, y }
    end)
    local pos = ns.db.pos
    if pos then
        frame:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
    else
        frame:SetPoint("CENTER", 0, 20)
    end
    frame:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    frame:Hide()
    tinsert(UISpecialFrames, "LoreLogFrame")

    frame.grad = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
    frame.grad:SetPoint("TOPLEFT", 1, -1)
    frame.grad:SetPoint("BOTTOMRIGHT", -1, 1)

    -- Inner hairline for a double-rule book edge
    frame.inner = CreateFrame("Frame", nil, frame, BACKDROP_TPL)
    frame.inner:SetPoint("TOPLEFT", 4, -4)
    frame.inner:SetPoint("BOTTOMRIGHT", -4, 4)
    frame.inner:SetBackdrop({ edgeFile = WHITE, edgeSize = 1 })

    -- Header
    frame.headerRule = frame:CreateTexture(nil, "ARTWORK")
    frame.headerRule:SetPoint("TOPLEFT", 5, -HEADER_H)
    frame.headerRule:SetPoint("TOPRIGHT", -5, -HEADER_H)
    frame.headerRule:SetHeight(1)

    local close = TextButton(frame, 26, 26, "\195\151", function() frame:Hide() end)
    close.font, close.fontSize = STANDARD_TEXT_FONT, 16
    close:SetPoint("TOPRIGHT", -16, -22)

    local sizeUp = TextButton(frame, 32, 26, "A+", function() UI.SetFontScale((ns.db.fontScale or 1) + 0.05) end,
        { "Larger text" })
    sizeUp:SetPoint("RIGHT", close, "LEFT", -8, 0)
    local sizeDown = TextButton(frame, 32, 26, "A-", function() UI.SetFontScale((ns.db.fontScale or 1) - 0.05) end,
        { "Smaller text" })
    sizeDown:SetPoint("RIGHT", sizeUp, "LEFT", -4, 0)

    themeBtn = TextButton(frame, 140, 26, "", function(_, button)
        UI.SetTheme(ns.Themes.Next(ns.db.theme, button == "RightButton" and -1 or 1))
    end, { "Change theme", "Left-click for the next theme, right-click for the previous one." })
    themeBtn.labelFn = function() return Theme().name end
    themeBtn:SetPoint("RIGHT", sizeDown, "LEFT", -8, 0)

    titleFS = frame:CreateFontString(nil, "OVERLAY")
    titleFS:SetPoint("TOPLEFT", 22, -14)
    titleFS:SetPoint("RIGHT", themeBtn, "LEFT", -12, 0)
    titleFS:SetJustifyH("LEFT")
    titleFS:SetWordWrap(false)
    subFS = frame:CreateFontString(nil, "OVERLAY")
    subFS:SetPoint("TOPLEFT", titleFS, "BOTTOMLEFT", 1, -4)
    subFS:SetPoint("RIGHT", themeBtn, "LEFT", -12, 0)
    subFS:SetJustifyH("LEFT")
    subFS:SetWordWrap(false)

    -- Sidebar (chapter list)
    sidebar = CreateFrame("ScrollFrame", nil, frame)
    sidebar:SetPoint("TOPLEFT", 5, -HEADER_H - 1)
    sidebar:SetPoint("BOTTOMLEFT", 5, 5)
    sidebar:SetWidth(SIDEBAR_W)
    sidebar.bg = sidebar:CreateTexture(nil, "BACKGROUND")
    sidebar.bg:SetAllPoints()
    navChild = CreateFrame("Frame", nil, sidebar)
    navChild:SetSize(SIDEBAR_W, 1)
    sidebar:SetScrollChild(navChild)
    sidebar:EnableMouseWheel(true)
    sidebar:SetScript("OnMouseWheel", function(self, delta)
        local v = self:GetVerticalScroll() - delta * NAV_H
        self:SetVerticalScroll(math.max(0, math.min(v, self:GetVerticalScrollRange())))
    end)
    frame.sideRule = frame:CreateTexture(nil, "ARTWORK")
    frame.sideRule:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 0, 0)
    frame.sideRule:SetPoint("BOTTOMLEFT", sidebar, "BOTTOMRIGHT", 0, 0)
    frame.sideRule:SetWidth(1)

    -- Story pane
    scroll = CreateFrame("ScrollFrame", nil, frame)
    scroll:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", PAD_X, -PAD_TOP)
    scroll:SetPoint("BOTTOMRIGHT", -PAD_RIGHT, PAD_BOTTOM)
    content = CreateFrame("Frame", nil, scroll)
    content:SetSize(CONTENT_W, 1)
    scroll:SetScrollChild(content)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        ScrollTo(self:GetVerticalScroll() - delta * 60)
    end)
    scroll:SetScript("OnScrollRangeChanged", UpdateThumb)

    track = CreateFrame("Frame", nil, frame)
    track:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 12, 0)
    track:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 12, 0)
    track:SetWidth(4)
    track.bg = track:CreateTexture(nil, "BACKGROUND")
    track.bg:SetAllPoints()
    thumb = CreateFrame("Button", nil, track)
    thumb:SetWidth(3)
    thumb:SetHitRectInsets(-6, -6, 0, 0)
    thumb.tex = thumb:CreateTexture(nil, "ARTWORK")
    thumb.tex:SetAllPoints()
    thumb:SetScript("OnMouseDown", function(self)
        local _, cy = GetCursorPosition()
        local startY, startScroll = cy / self:GetEffectiveScale(), scroll:GetVerticalScroll()
        self:SetScript("OnUpdate", function(s)
            local _, y = GetCursorPosition()
            y = y / s:GetEffectiveScale()
            local free = track:GetHeight() - s:GetHeight()
            if free > 0 then
                ScrollTo(startScroll + (startY - y) * scroll:GetVerticalScrollRange() / free)
            end
        end)
    end)
    thumb:SetScript("OnMouseUp", function(self) self:SetScript("OnUpdate", nil) end)

    -- Subtle open animation
    local fade = frame:CreateAnimationGroup()
    local a = fade:CreateAnimation("Alpha")
    a:SetFromAlpha(0)
    a:SetToAlpha(1)
    a:SetDuration(0.18)
    frame.fade = fade

    frame:SetScript("OnShow", function()
        if not selected then selected = ns.ChapterOf(UnitLevel("player")) end
        if appliedTheme ~= ns.db.theme then UI.ApplyTheme() end
        UI.RefreshNav()
        UI.Render()
        frame.fade:Play()
        if SOUNDKIT and SOUNDKIT.IG_SPELLBOOK_OPEN then PlaySound(SOUNDKIT.IG_SPELLBOOK_OPEN) end
        if ns.Tab then ns.Tab.Update() end
    end)
    frame:SetScript("OnHide", function()
        if SOUNDKIT and SOUNDKIT.IG_SPELLBOOK_CLOSE then PlaySound(SOUNDKIT.IG_SPELLBOOK_CLOSE) end
        if ns.Tab then ns.Tab.Update() end
    end)

    return frame
end

---------------------------------------------------------------------------
-- Theming
---------------------------------------------------------------------------
function UI.ApplyTheme()
    if not frame then return end
    local t = Theme()
    appliedTheme = ns.db.theme
    frame:SetBackdropColor(C("bg"))
    frame:SetBackdropBorderColor(C("border", 0.9))
    SetGradient(frame.grad, t.colors.bg2, t.colors.bg)
    frame.inner:SetBackdropBorderColor(C("border", 0.3))
    frame.headerRule:SetColorTexture(C("border", 0.45))
    frame.sideRule:SetColorTexture(C("border", 0.3))
    sidebar.bg:SetColorTexture(C("sidebar"))
    track.bg:SetColorTexture(C("border", 0.15))
    thumb.tex:SetColorTexture(C("accent", 0.75))
    SetFS(titleFS, "title", 20, true)
    titleFS:SetTextColor(C("title"))
    SetFS(subFS, "meta", 12, true)
    subFS:SetTextColor(C("meta"))
    for _, b in ipairs(textButtons) do UI.StyleTextButton(b) end
    for _, b in ipairs(navButtons) do FontNav(b); StyleNav(b) end
end

function UI.SetTheme(key)
    if not ns.Themes.list[key] then return false end
    ns.db.theme = key
    if frame and frame:IsShown() then
        UI.ApplyTheme()
        UI.RefreshNav()
        UI.Render(true)
    end
    return true
end

function UI.SetFontScale(v)
    ns.db.fontScale = math.max(0.8, math.min(1.4, math.floor(v * 100 + 0.5) / 100))
    if frame and frame:IsShown() then UI.Render(true) end
end

---------------------------------------------------------------------------
-- Navigation & rendering
---------------------------------------------------------------------------
function UI.RefreshNav()
    local curCh = ns.ChapterOf(UnitLevel("player"))
    local maxCh = ns.MaxChapter()
    local n = 0
    for c = 1, maxCh do
        n = n + 1
        local b = NavButton(n)
        local lo, hi = ns.ChapterRange(c)
        b.key = c
        b.num:SetText(ns.Roman(c))
        b.title:SetText(ns.ChapterTitle(c))
        b.range:SetText(("Levels %d\226\128\147%d"):format(lo, hi) .. (c == curCh and "  \194\183  current" or ""))
        b:Show()
    end
    n = n + 1
    local b = NavButton(n)
    b.key = "companions"
    b.num:SetText("\194\167")
    b.title:SetText("Companions")
    b.range:SetText(ns.Plural(ns.Narrator.CompanionCount(), "fellow traveler"))
    b:Show()
    for i = n + 1, #navButtons do navButtons[i]:Hide() end
    navChild:SetHeight(n * NAV_H + 20)
    for i = 1, n do StyleNav(navButtons[i]) end

    local p = ns.Player()
    local epithet = ns.Narrator.Epithet and ns.Narrator.Epithet(p.level) or ""
    titleFS:SetText("The Chronicle of " .. (p.name or "") .. (epithet ~= "" and (" " .. epithet) or ""))
    subFS:SetText(("%s %s  \194\183  Level %d  \194\183  %s chronicled"):format(
        p.race or "", p.class or "", p.level or 1, ns.Plural(ns.Narrator.DeedCount(), "deed")))
end

function UI.Select(key)
    selected = key
    for _, b in ipairs(navButtons) do
        if b:IsShown() then StyleNav(b) end
    end
    UI.Render()
end

local function AcquireFS()
    fsUsed = fsUsed + 1
    local fs = fsPool[fsUsed]
    if not fs then
        fs = content:CreateFontString(nil, "ARTWORK")
        fs:SetJustifyV("TOP")
        fs:SetWordWrap(true)
        fsPool[fsUsed] = fs
    end
    fs:ClearAllPoints()
    fs:Show()
    return fs
end

local function AcquireTex()
    texUsed = texUsed + 1
    local tex = texPool[texUsed]
    if not tex then
        tex = content:CreateTexture(nil, "ARTWORK")
        texPool[texUsed] = tex
    end
    tex:ClearAllPoints()
    tex:Show()
    return tex
end

function UI.Render(keepScroll)
    if not frame or not frame:IsShown() then return end
    for i = 1, fsUsed do fsPool[i]:Hide() end
    for i = 1, texUsed do texPool[i]:Hide() end
    fsUsed, texUsed = 0, 0

    local blocks
    if selected == "companions" then
        blocks = ns.Narrator.BuildCompanions()
    else
        blocks = ns.Narrator.BuildChapter(selected, { accentHex = UI.AccentHex() })
    end

    local y = 0
    for _, blk in ipairs(blocks) do
        local kind, text = blk[1], blk[2]
        if kind == "divider" then
            y = y + 8
            local w = math.floor(CONTENT_W * 0.28)
            local line = AcquireTex()
            line:SetColorTexture(C("accent", 0.45))
            line:SetSize(w, 1)
            line:SetPoint("TOP", content, "TOP", 0, -y)
            local dot = AcquireTex()
            dot:SetColorTexture(C("accent", 0.9))
            dot:SetSize(5, 5)
            dot:SetPoint("CENTER", line, "CENTER", 0, 0)
            y = y + 20
        else
            local st = STYLE[kind] or STYLE.p
            local fs = AcquireFS()
            SetFS(fs, st.font, st.size)
            fs:SetTextColor(C(st.color))
            fs:SetJustifyH(st.justify or "LEFT")
            fs:SetSpacing(0)
            local indent = st.indent or 0
            local blockW = math.max(10, math.floor(CONTENT_W - indent))
            fs:SetWidth(blockW)
            fs:SetText(text or "")
            fs:SetPoint("TOPLEFT", content, "TOPLEFT", indent, -y)
            local strH = fs:GetStringHeight()
            y = y + math.ceil(strH) + st.after
        end
    end
    content:SetHeight(math.max(1, y + 24))

    if keepScroll then
        ScrollTo(scroll:GetVerticalScroll())
    else
        ScrollTo(0)
    end
end

function UI.OnDataChanged()
    if frame and frame:IsShown() then
        ns.Throttle("ll_render", 0.5, function()
            if frame:IsShown() then
                UI.RefreshNav()
                UI.Render(true)
            end
        end)
    end
end

function UI.Toggle()
    if not ns.ready then
        if ns.InitDB then ns.InitDB() end
    end
    UI.Create()
    frame:SetShown(not frame:IsShown())
end

function UI.IsShown()
    return frame and frame:IsShown() or false
end

---------------------------------------------------------------------------
-- Entry points
---------------------------------------------------------------------------
function LoreLog_OnAddonCompartmentClick()
    UI.Toggle()
end

SLASH_LORELOG1 = "/lorelog"
SLASH_LORELOG2 = "/lore"
SlashCmdList.LORELOG = function(msg)
    local cmd, arg = (msg or ""):lower():match("^%s*(%S*)%s*(.-)%s*$")
    if cmd == "" then
        UI.Toggle()
    elseif cmd == "minimap" then
        if ns.Minimap and ns.Minimap.Toggle then
            ns.Minimap.Toggle()
            ns.Print("Minimap button: " .. (ns.db.minimapHide and "|cffff0000hidden|r" or "|cff00ff00shown|r") .. ".")
        end
    elseif cmd == "chat" then
        ns.db.chatAnnounce = not (ns.db.chatAnnounce ~= false)
        ns.Print("Live chronicle announcements in chat: " .. (ns.db.chatAnnounce and "|cff00ff00enabled|r" or "|cffff0000disabled|r") .. ".")
    elseif cmd == "theme" then
        if arg ~= "" and UI.SetTheme(arg) then
            ns.Print("Theme set to " .. Theme().name .. ".")
        else
            ns.Print("Themes:")
            for _, k in ipairs(ns.Themes.order) do
                local t = ns.Themes.list[k]
                ns.Print(("  |cffffd100%s|r - %s %s"):format(k, t.name, t.desc))
            end
        end
    elseif cmd == "size" then
        local v = tonumber(arg)
        if v then UI.SetFontScale(v) end
        ns.Print(("Text size: %d%%"):format((ns.db.fontScale or 1) * 100))
    elseif cmd == "sync" or cmd == "backfill" then
        if ns.SyncCompletedQuests then
            ns.SyncCompletedQuests(true)
        else
            ns.Print("Sync function is not available.")
        end
    elseif cmd == "reset" then
        if arg == "confirm" then
            ns.ResetCharacterData()
            ns.BeginChronicle()
            selected = nil
            if UI.IsShown() then frame:Hide(); frame:Show() end
            ns.Print("This character's chronicle has been reset.")
        else
            ns.Print("This erases this character's chronicle. Type |cffffd100/lorelog reset confirm|r to proceed.")
        end
    else
        ns.Print("/lorelog - open or close the chronicle window")
        ns.Print("/lorelog sync - read completed quests and backfill past accomplishments")
        ns.Print("/lorelog minimap - show or hide the minimap button")
        ns.Print("/lorelog chat - toggle live narrative announcements in chat")
        ns.Print("/lorelog theme [name] - list or change themes")
        ns.Print("/lorelog size [0.8-1.4] - text size")
        ns.Print("/lorelog reset - start this character's chronicle over")
    end
end
