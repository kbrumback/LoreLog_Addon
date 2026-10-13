-- Lore Log: Spellbook side tab
-- Adds a "The Story So Far" tab to the side of the spellbook, styled like the
-- spell school / specialization tabs. Works with the classic SpellBookFrame
-- and the modern PlayerSpellsFrame, whichever the client provides.
local ADDON, ns = ...
local Tab = {}
ns.Tab = Tab

local ICON = "Interface\\Icons\\INV_Misc_Book_09"
local TAB_NAME = "The Story So Far"
local tabs = {}

local function LastSkillTab()
    local last, i = nil, 1
    while _G["SpellBookSkillLineTab" .. i] do
        local t = _G["SpellBookSkillLineTab" .. i]
        if t:IsShown() then last = t end
        i = i + 1
    end
    return last
end

local function CountSkillTabs()
    local count = 0
    while _G["SpellBookSkillLineTab" .. (count + 1)] do
        count = count + 1
    end
    return count
end

local function Position(tab)
    if not tab then return end
    local parent = tab:GetParent()
    if not parent then return end
    tab:ClearAllPoints()
    if parent == SpellBookFrame then
        local last = LastSkillTab()
        if last then
            tab:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, -17)
        else
            local tabCount = math.max(1, CountSkillTabs())
            tab:SetPoint("TOPLEFT", parent, "TOPRIGHT", 0, -48 - (tabCount * 44))
        end
    else
        tab:SetPoint("TOPLEFT", parent, "TOPRIGHT", 0, -60)
    end
end

local function CreateTab(parent)
    local b = CreateFrame("CheckButton", "LoreLogSpellBookTab", parent)
    b:SetSize(32, 32)
    b:SetFrameLevel(parent:GetFrameLevel() + 10)

    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\SpellBook\\SpellBook-SkillLineTab")
    bg:SetSize(64, 64)
    bg:SetPoint("TOPLEFT", -3, 11)

    b:SetNormalTexture(ICON)
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    b:SetCheckedTexture("Interface\\Buttons\\CheckButtonHilight", "ADD")
    b:Show()

    b:SetScript("OnClick", function(self)
        ns.UI.Toggle()
        self:SetChecked(ns.UI.IsShown())
    end)
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(TAB_NAME, 1, 0.82, 0)
        GameTooltip:AddLine("Read the living chronicle of your journey.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return b
end

local function Attach(parent)
    if not parent or tabs[parent] then return end
    local tab = CreateTab(parent)
    tabs[parent] = tab
    parent:HookScript("OnShow", function()
        tab:Show()
        if C_Timer and C_Timer.After then
            C_Timer.After(0.02, function()
                Position(tab)
                tab:SetChecked(ns.UI.IsShown())
            end)
        else
            Position(tab)
            tab:SetChecked(ns.UI.IsShown())
        end
    end)
    Position(tab)
end

function Tab.Update()
    local shown = ns.UI.IsShown()
    for _, tab in pairs(tabs) do tab:SetChecked(shown) end
end

local hookedSkillTabs = false
local function TryAttach()
    if SpellBookFrame then Attach(SpellBookFrame) end
    if PlayerSpellsFrame then Attach(PlayerSpellsFrame) end
    if not hookedSkillTabs then
        if type(SpellBookFrame_UpdateSkillLineTabs) == "function" then
            hookedSkillTabs = true
            hooksecurefunc("SpellBookFrame_UpdateSkillLineTabs", function()
                if tabs[SpellBookFrame] then Position(tabs[SpellBookFrame]) end
            end)
        end
        if type(SpellBookFrame_Update) == "function" then
            hookedSkillTabs = true
            hooksecurefunc("SpellBookFrame_Update", function()
                if tabs[SpellBookFrame] then Position(tabs[SpellBookFrame]) end
            end)
        end
    end
end

ns.OnLogin(TryAttach)
ns.On("PLAYER_ENTERING_WORLD", TryAttach)
ns.On("ADDON_LOADED", function(name)
    if name == "Blizzard_PlayerSpells" or name == "Blizzard_SpellBook" then TryAttach() end
end)
