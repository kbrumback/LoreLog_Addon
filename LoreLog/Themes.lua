-- Lore Log: Themes
-- Each theme pairs a palette with a set of fonts (bundled OFL fonts in /Fonts).
local ADDON, ns = ...
local T = {}
ns.Themes = T

local P = "Interface\\AddOns\\" .. ADDON .. "\\Fonts\\"
local FRIZ = "Fonts\\FRIZQT__.TTF"
local MORPH = "Fonts\\MORPHEUS.TTF"

T.order = { "gilded", "parchment", "royal", "nightink", "fel", "classic" }

T.list = {
    gilded = {
        name = "Gilded Tome",
        desc = "Playfair Display and EB Garamond on dark leather and gold leaf.",
        fonts = {
            title = P .. "PlayfairDisplay-Bold.ttf",
            heading = P .. "PlayfairDisplay-Bold.ttf",
            body = P .. "EBGaramond-Regular.ttf",
            meta = P .. "EBGaramond-Italic.ttf",
        },
        scale = { body = 1.04, meta = 1.04 },
        colors = {
            bg = { 0.075, 0.058, 0.042 }, bg2 = { 0.15, 0.105, 0.065 },
            border = { 0.72, 0.56, 0.27 }, sidebar = { 0, 0, 0, 0.28 }, select = { 0.85, 0.65, 0.30, 0.16 },
            title = { 0.97, 0.83, 0.50 }, heading = { 0.92, 0.77, 0.47 }, body = { 0.91, 0.87, 0.79 },
            meta = { 0.66, 0.60, 0.51 }, accent = { 0.86, 0.66, 0.31 },
        },
    },
    parchment = {
        name = "Parchment Scroll",
        desc = "IM Fell English on sun-faded parchment, like an old field journal.",
        fonts = {
            title = P .. "IMFellEnglish-Regular.ttf",
            heading = P .. "IMFellEnglish-Regular.ttf",
            body = P .. "IMFellEnglish-Regular.ttf",
            meta = P .. "IMFellEnglish-Italic.ttf",
        },
        scale = { title = 1.04, body = 1.04, meta = 1.04 },
        colors = {
            bg = { 0.86, 0.78, 0.62 }, bg2 = { 0.95, 0.90, 0.78 },
            border = { 0.45, 0.31, 0.17 }, sidebar = { 0.40, 0.26, 0.12, 0.10 }, select = { 0.55, 0.25, 0.10, 0.14 },
            title = { 0.33, 0.16, 0.07 }, heading = { 0.42, 0.20, 0.09 }, body = { 0.19, 0.13, 0.08 },
            meta = { 0.42, 0.33, 0.23 }, accent = { 0.58, 0.22, 0.10 },
        },
    },
    royal = {
        name = "Royal Decree",
        desc = "Cinzel capitals and Cormorant Garamond in midnight and silver.",
        fonts = {
            title = P .. "Cinzel-Bold.ttf",
            heading = P .. "Cinzel-Bold.ttf",
            body = P .. "CormorantGaramond-Medium.ttf",
            meta = P .. "CormorantGaramond-MediumItalic.ttf",
        },
        scale = { title = 0.95, heading = 0.92, body = 1.08, meta = 1.08 },
        colors = {
            bg = { 0.05, 0.055, 0.11 }, bg2 = { 0.11, 0.10, 0.21 },
            border = { 0.72, 0.66, 0.92 }, sidebar = { 0, 0, 0, 0.30 }, select = { 0.62, 0.52, 0.95, 0.18 },
            title = { 0.94, 0.91, 1.00 }, heading = { 0.80, 0.73, 1.00 }, body = { 0.87, 0.87, 0.93 },
            meta = { 0.62, 0.60, 0.74 }, accent = { 0.68, 0.58, 0.98 },
        },
    },
    nightink = {
        name = "Night Ink",
        desc = "Lora on cool slate, a quiet, low-glare reading mode.",
        fonts = {
            title = P .. "Lora-Bold.ttf",
            heading = P .. "Lora-Bold.ttf",
            body = P .. "Lora-Regular.ttf",
            meta = P .. "Lora-Italic.ttf",
        },
        scale = {},
        colors = {
            bg = { 0.065, 0.075, 0.085 }, bg2 = { 0.10, 0.12, 0.14 },
            border = { 0.36, 0.43, 0.49 }, sidebar = { 0, 0, 0, 0.25 }, select = { 0.45, 0.70, 0.85, 0.14 },
            title = { 0.88, 0.92, 0.96 }, heading = { 0.74, 0.84, 0.92 }, body = { 0.80, 0.83, 0.86 },
            meta = { 0.54, 0.60, 0.66 }, accent = { 0.46, 0.72, 0.87 },
        },
    },
    fel = {
        name = "Fel Grimoire",
        desc = "Uncial Antiqua and Lora, inked in sickly fel-green.",
        fonts = {
            title = P .. "UncialAntiqua-Regular.ttf",
            heading = P .. "UncialAntiqua-Regular.ttf",
            body = P .. "Lora-Regular.ttf",
            meta = P .. "Lora-Italic.ttf",
        },
        scale = { title = 0.95, heading = 0.92 },
        colors = {
            bg = { 0.035, 0.06, 0.035 }, bg2 = { 0.07, 0.13, 0.05 },
            border = { 0.45, 0.85, 0.25 }, sidebar = { 0, 0, 0, 0.30 }, select = { 0.50, 0.95, 0.30, 0.14 },
            title = { 0.68, 1.00, 0.42 }, heading = { 0.60, 0.92, 0.38 }, body = { 0.83, 0.89, 0.79 },
            meta = { 0.55, 0.66, 0.50 }, accent = { 0.52, 0.95, 0.30 },
        },
    },
    classic = {
        name = "Azeroth Classic",
        desc = "The game's own Morpheus and Friz Quadrata. No extra fonts required.",
        fonts = { title = MORPH, heading = MORPH, body = FRIZ, meta = FRIZ },
        scale = { title = 1.05, heading = 1.02, body = 0.95, meta = 0.90 },
        colors = {
            bg = { 0.05, 0.05, 0.06 }, bg2 = { 0.12, 0.10, 0.08 },
            border = { 0.62, 0.62, 0.62 }, sidebar = { 0, 0, 0, 0.30 }, select = { 1.0, 0.82, 0.0, 0.14 },
            title = { 1.00, 0.82, 0.00 }, heading = { 1.00, 0.82, 0.00 }, body = { 0.93, 0.93, 0.93 },
            meta = { 0.65, 0.65, 0.65 }, accent = { 1.00, 0.82, 0.00 },
        },
    },
}

function T.Get(key)
    return T.list[key] or T.list.gilded
end

function T.Next(key, dir)
    local idx = 1
    for i, k in ipairs(T.order) do
        if k == key then idx = i break end
    end
    idx = ((idx - 1 + (dir or 1)) % #T.order) + 1
    return T.order[idx]
end

-- Verifies each font file once; missing files fall back to the default font.
local resolved = {}
local probe
function T.ResolveFont(path)
    if not path or path == "" then return STANDARD_TEXT_FONT end
    local r = resolved[path]
    if r then return r end
    if not probe and UIParent and UIParent.CreateFontString then
        probe = UIParent:CreateFontString(nil, "BACKGROUND")
    end
    if not probe then return path end
    probe:SetFont(STANDARD_TEXT_FONT, 12, "")
    local ok = probe:SetFont(path, 12, "")
    local currPath = probe:GetFont()
    local valid = (ok == true) or (ok == 1) or (currPath and currPath:lower() == path:lower())
    r = valid and path or STANDARD_TEXT_FONT
    resolved[path] = r
    return r
end
