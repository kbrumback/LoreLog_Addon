-- Lore Log: Minimap Button
-- A lightweight, draggable minimap button that works seamlessly across Classic / WoW Forever.
local ADDON, ns = ...
local MinimapButton = {}
ns.Minimap = MinimapButton

local btn

local function UpdatePosition()
    if not btn then return end
    local angle = math.rad(ns.db.minimapAngle or 220)
    local radius = 80
    local x = math.cos(angle) * radius
    local y = math.sin(angle) * radius
    btn:ClearAllPoints()
    btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function MinimapButton.SetShown(show)
    ns.db.minimapHide = not show
    if btn then btn:SetShown(show) end
end

function MinimapButton.Toggle()
    MinimapButton.SetShown(ns.db.minimapHide)
end

function MinimapButton.Create()
    if btn then return btn end

    btn = CreateFrame("Button", "LoreLogMinimapButton", Minimap)
    btn:SetSize(32, 32)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel((Minimap:GetFrameLevel() or 8) + 5)
    btn:SetClampedToScreen(true)
    btn:SetDontSavePosition(true)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:RegisterForDrag("LeftButton")

    -- Icon
    local icon = btn:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", 0, 0)
    icon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
    btn.icon = icon

    -- Circular border / tracking border
    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT", 0, 0)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    btn.border = border

    -- Highlight
    local hl = btn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetSize(24, 24)
    hl:SetPoint("CENTER", 0, 0)
    hl:SetTexture("Interface\\Buttons\\CheckButtonHilight")
    hl:SetBlendMode("ADD")

    UpdatePosition()

    -- Dragging
    btn:SetScript("OnDragStart", function(self)
        self.dragging = true
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local cx, cy = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            cx, cy = cx / scale, cy / scale
            local deg = math.deg(math.atan2(cy - my, cx - mx))
            ns.db.minimapAngle = deg
            UpdatePosition()
        end)
    end)

    btn:SetScript("OnDragStop", function(self)
        self.dragging = false
        self:SetScript("OnUpdate", nil)
    end)

    -- Clicks
    btn:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            ns.UI.Toggle()
        elseif button == "RightButton" then
            local nextTheme = ns.Themes.Next(ns.db.theme, 1)
            ns.UI.SetTheme(nextTheme)
            local t = ns.Themes.Get(nextTheme)
            ns.Print("Theme switched to |cffffd100" .. t.name .. "|r.")
            if self:IsMouseOver() then
                self:GetScript("OnEnter")(self)
            end
        end
    end)

    -- Tooltip
    btn:SetScript("OnEnter", function(self)
        if self.dragging then return end
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("|cffd9a54cLore Log|r")
        GameTooltip:AddLine("A living chronicle of your journey in Azeroth.", 0.9, 0.9, 0.9, true)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cffffffffLeft-Click:|r Open / close chronicle", 0.8, 0.8, 0.8)
        local t = ns.Themes.Get(ns.db.theme)
        GameTooltip:AddLine("|cffffffffRight-Click:|r Switch theme (|cffd9a54c" .. t.name .. "|r)", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("|cff888888Drag to move around the minimap|r", 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)

    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    if ns.db.minimapHide then btn:Hide() end
    return btn
end

ns.OnReady(function()
    MinimapButton.Create()
end)
