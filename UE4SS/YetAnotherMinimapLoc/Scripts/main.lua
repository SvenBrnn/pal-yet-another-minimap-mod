-- =====================================================================
-- YetAnotherMinimapLoc - UE4SS Lua companion
-- Localizes the in-game Minimap Settings panel (WBT_MinimapSettings) to
-- match the game's current language (zh* -> Chinese, otherwise English).
--
-- Does NOT replace the blueprint LogicMod. Install next to other UE4SS
-- mods, e.g.:
--   <UE4SS>/Mods/YetAnotherMinimapLoc/Scripts/main.lua
--   <UE4SS>/Mods/YetAnotherMinimapLoc/enabled.txt
-- =====================================================================

local PREFIX = "[YetAnotherMinimapLoc] "

local function log(msg)
    print(PREFIX .. tostring(msg))
end

local function isAlive(obj)
    if obj == nil then return false end
    local ok, valid = pcall(function() return obj:IsValid() end)
    return ok and valid == true
end

local function asString(value)
    if value == nil then return nil end
    if type(value) == "string" then return value end
    local ok, s = pcall(function()
        if value.ToString ~= nil then
            return value:ToString()
        end
        return tostring(value)
    end)
    if ok and type(s) == "string" then
        -- Strip common FText debug wrappers if present
        s = s:gsub("^.-TEXT%((.*)%)%s*$", "%1")
        s = s:gsub('^"(.*)"$', "%1")
        return s
    end
    return nil
end

local function getText(tb)
    if not isAlive(tb) then return nil end
    local ok, text = pcall(function()
        local t = tb:GetText()
        return asString(t)
    end)
    if ok and type(text) == "string" and text ~= "" then return text end
    -- Some widgets expose Text / Content instead of GetText
    for _, prop in ipairs({ "Text", "Content" }) do
        local ok2, val = pcall(function() return tb[prop] end)
        if ok2 then
            local s = asString(val)
            if s and s ~= "" then return s end
        end
    end
    return nil
end

local function setText(tb, str)
    if not isAlive(tb) or type(str) ~= "string" then return false end
    local ok1 = pcall(function()
        tb:SetText(FText(str))
    end)
    if ok1 then return true end
    local ok2 = pcall(function()
        tb:SetText(str)
    end)
    return ok2 == true
end

local function collectOf(className)
    local out = {}
    local ok, list = pcall(FindAllOf, className)
    if not ok or list == nil then return out end
    if type(list) == "table" then
        for _, obj in pairs(list) do
            if isAlive(obj) then table.insert(out, obj) end
        end
    elseif isAlive(list) then
        table.insert(out, list)
    end
    return out
end

local function classNameOf(obj)
    if not isAlive(obj) then return "" end
    local ok, name = pcall(function()
        local c = obj:GetClass()
        if c and c.GetFName then return asString(c:GetFName()) end
        if c and c.GetName then return asString(c:GetName()) end
        return asString(c)
    end)
    return (ok and name) or ""
end

local function looksLikeTextWidget(obj)
    local cn = classNameOf(obj)
    if cn == "" then return false end
    cn = cn:lower()
    return cn:find("textblock", 1, true)
        or cn:find("richtext", 1, true)
        or cn:find("paltext", 1, true)
        or cn == "text"
end

-- ---------------------------------------------------------------------------
-- Language detection (same approach as other Palworld UE4SS menus)
-- ---------------------------------------------------------------------------
local detectedMenuLanguage = nil
local lastMenuCulture = nil
local languageDetectionWarningLogged = false
local languageCachedAt = 0
local LANGUAGE_CACHE_TTL = 30 -- seconds; refresh periodically (title vs in-game)

local function detectMenuLanguage(force)
    local now = os.clock()
    if not force and detectedMenuLanguage ~= nil and (now - languageCachedAt) < LANGUAGE_CACHE_TTL then
        return detectedMenuLanguage
    end

    local culture
    local ok, err = pcall(function()
        local library = StaticFindObject("/Script/Engine.Default__KismetInternationalizationLibrary")
        if not isAlive(library) then
            error("KismetInternationalizationLibrary unavailable")
        end
        culture = library:GetCurrentLanguage()
        culture = asString(culture)
        if type(culture) ~= "string" or culture == "" then
            error("GetCurrentLanguage returned no culture")
        end
    end)

    if not ok then
        if not languageDetectionWarningLogged then
            languageDetectionWarningLogged = true
            log("language detection failed; defaulting to English: " .. tostring(err))
        end
        -- Do not hard-cache failures forever
        return detectedMenuLanguage or "en"
    end

    local language = culture:sub(1, 2):lower() == "zh" and "zh" or "en"
    detectedMenuLanguage = language
    languageCachedAt = now
    if culture ~= lastMenuCulture then
        lastMenuCulture = culture
        log(string.format("menu language: culture=%s -> %s", culture, language))
    end
    return language
end

local function clearLanguageCache()
    detectedMenuLanguage = nil
    lastMenuCulture = nil
    languageCachedAt = 0
end

-- ---------------------------------------------------------------------------
-- Translation tables
-- Keys match SettingKey / section headers / fixed chrome strings from the
-- YetAnotherMinimap blueprint + YetAnotherMinimap.modconfig.json (0.9.x/0.10.x).
-- ---------------------------------------------------------------------------
local LABELS = {
    en = {
        -- chrome
        ["Minimap Settings"] = "Minimap Settings",
        ["Reset"] = "Reset",
        ["Save"] = "Save",
        ["Cancel"] = "Cancel",
        ["ON"] = "ON",
        ["OFF"] = "OFF",
        -- sections
        ["General"] = "General",
        ["Position and Size"] = "Position and Size",
        ["Scan"] = "Scan",
        ["Icon Scale"] = "Icon Scale",
        ["Performence tuning"] = "Performence tuning", -- upstream typo kept as source key
        ["Performance tuning"] = "Performance tuning",
        ["Zoom"] = "Zoom",
        ["Keymap"] = "Keymap",
        -- General
        ["Mod Logic Enabled"] = "Mod Logic Enabled",
        ["Rotate Map"] = "Rotate Map",
        ["Round Map"] = "Round Map",
        ["Opacity"] = "Opacity",
        ["Icon Color"] = "Icon Color",
        ["Hide Map In Base"] = "Hide Map In Base",
        ["Debug"] = "Debug",
        -- Position
        ["Size"] = "Size",
        ["PosX"] = "PosX",
        ["PosY"] = "PosY",
        -- Scan
        ["Treasure"] = "Treasure",
        ["Pals"] = "Pals",
        ["Egg"] = "Egg",
        ["Relics"] = "Relics",
        ["Notes"] = "Notes",
        ["Dungeon"] = "Dungeon",
        ["FastTravel"] = "FastTravel",
        ["Player Pals"] = "Player Pals",
        ["Players"] = "Players",
        ["NPCs"] = "NPCs",
        -- Icon scale
        ["Pal Scale"] = "Pal Scale",
        ["Relic Scale"] = "Relic Scale",
        ["Note Scale"] = "Note Scale",
        ["Dungeon Scale"] = "Dungeon Scale",
        ["Treasure Scale"] = "Treasure Scale",
        ["Egg Scale"] = "Egg Scale",
        ["FastTravel Scale"] = "FastTravel Scale",
        ["Player Scale"] = "Player Scale",
        ["Player Pal Scale"] = "Player Pal Scale",
        ["Member Scale"] = "Member Scale",
        ["NPC Scale"] = "NPC Scale",
        -- Performance
        ["Nativ"] = "Nativ",
        ["Native"] = "Native",
        ["Refresh Rate"] = "Refresh Rate",
        ["Scan Interval"] = "Scan Interval",
        -- Zoom
        ["Default Zoom"] = "Default Zoom",
        ["Super Zoom"] = "Super Zoom",
        -- Keymap
        ["Zoom"] = "Zoom",
        ["Map Move Mode"] = "Map Move Mode",
        ["Toggle Map"] = "Toggle Map",
        ["Map Up"] = "Map Up",
        ["Map Down"] = "Map Down",
        ["Map Left"] = "Map Left",
        ["Map Right"] = "Map Right",
        ["Map Bigger"] = "Map Bigger",
        ["Map Smaller"] = "Map Smaller",
        ["Zoom In"] = "Zoom In",
        ["Zoom Out"] = "Zoom Out",
    },
    zh = {
        ["Minimap Settings"] = "小地图设置",
        ["Reset"] = "重置",
        ["Save"] = "保存",
        ["Cancel"] = "取消",
        ["ON"] = "开",
        ["OFF"] = "关",
        ["General"] = "常规",
        ["Position and Size"] = "位置与大小",
        ["Scan"] = "扫描显示",
        ["Icon Scale"] = "图标缩放",
        ["Performence tuning"] = "性能调节",
        ["Performance tuning"] = "性能调节",
        ["Zoom"] = "缩放",
        ["Keymap"] = "快捷键",
        ["Mod Logic Enabled"] = "启用模组逻辑",
        ["Rotate Map"] = "旋转地图",
        ["Round Map"] = "圆形地图",
        ["Opacity"] = "透明度",
        ["Icon Color"] = "图标颜色",
        ["Hide Map In Base"] = "在据点中隐藏地图",
        ["Debug"] = "调试",
        ["Size"] = "大小",
        ["PosX"] = "水平位置 X",
        ["PosY"] = "垂直位置 Y",
        ["Treasure"] = "宝箱",
        ["Pals"] = "帕鲁",
        ["Egg"] = "帕鲁蛋",
        ["Relics"] = "遗物",
        ["Notes"] = "手记",
        ["Dungeon"] = "地下城",
        ["FastTravel"] = "快速旅行",
        ["Player Pals"] = "其他玩家帕鲁",
        ["Players"] = "其他玩家",
        ["NPCs"] = "NPC",
        ["Pal Scale"] = "帕鲁图标缩放",
        ["Relic Scale"] = "遗物图标缩放",
        ["Note Scale"] = "手记图标缩放",
        ["Dungeon Scale"] = "地下城图标缩放",
        ["Treasure Scale"] = "宝箱图标缩放",
        ["Egg Scale"] = "蛋图标缩放",
        ["FastTravel Scale"] = "快速旅行图标缩放",
        ["Player Scale"] = "玩家图标缩放",
        ["Player Pal Scale"] = "其他玩家帕鲁缩放",
        ["Member Scale"] = "其他玩家缩放",
        ["NPC Scale"] = "NPC 图标缩放",
        ["Nativ"] = "原生每帧渲染",
        ["Native"] = "原生每帧渲染",
        ["Refresh Rate"] = "刷新率",
        ["Scan Interval"] = "扫描间隔",
        ["Default Zoom"] = "默认缩放",
        ["Super Zoom"] = "超级缩放",
        ["Map Move Mode"] = "地图移动模式",
        ["Toggle Map"] = "切换地图显示",
        ["Map Up"] = "地图上移",
        ["Map Down"] = "地图下移",
        ["Map Left"] = "地图左移",
        ["Map Right"] = "地图右移",
        ["Map Bigger"] = "放大地图尺寸",
        ["Map Smaller"] = "缩小地图尺寸",
        ["Zoom In"] = "拉近视角",
        ["Zoom Out"] = "拉远视角",
    },
}

local DESCS = {
    en = {
        ["Mod Logic Enabled"] = "Whether the minimap mod is enabled or not.",
        ["Rotate Map"] = "Rotate the map. Disable to always point to north.",
        ["Round Map"] = "Displays a round map instead of a squared one.",
        ["Opacity"] = "Map opacity in percent.",
        ["Icon Color"] = "Color used to tint dungeons, eggs, fast travel points, chests, and notes on the map.",
        ["Hide Map In Base"] = "Automatically hide the map while inside a base. Disable to keep the map visible in your bases.",
        ["Debug"] = "Whether debug logging is enabled.",
        ["Size"] = "Size of the map.",
        ["PosX"] = "X Position of the map. Can be altered ingame using CTRL + F8.",
        ["PosY"] = "Y Position of the map. Can be altered ingame using CTRL + F8.",
        ["Treasure"] = "Whether to show treasure on map.",
        ["Pals"] = "Whether to show Pals on map.",
        ["Egg"] = "Whether to show Eggs on map.",
        ["Relics"] = "Whether to show Relics on map.",
        ["Notes"] = "Whether to show Notes on map.",
        ["Dungeon"] = "Whether to show Dungeons on map.",
        ["FastTravel"] = "Whether to show Fast Travel on map.",
        ["Player Pals"] = "Whether to show other players' active (summoned) Pals on map.",
        ["Players"] = "Whether to show other players on map.",
        ["NPCs"] = "Whether to show human NPCs on map.",
        ["Pal Scale"] = "Scale multiplier for pal icons.",
        ["Relic Scale"] = "Scale multiplier for relic icons.",
        ["Note Scale"] = "Scale multiplier for note icons.",
        ["Dungeon Scale"] = "Scale multiplier for dungeon icons.",
        ["Treasure Scale"] = "Scale multiplier for treasure icons.",
        ["Egg Scale"] = "Scale multiplier for egg icons.",
        ["FastTravel Scale"] = "Scale multiplier for fast travel icons.",
        ["Player Scale"] = "Scale multiplier for the player icon.",
        ["Player Pal Scale"] = "Scale multiplier for other players' pal icons.",
        ["Member Scale"] = "Scale multiplier for other player icons.",
        ["NPC Scale"] = "Scale multiplier for NPC icons.",
        ["Nativ"] = "Render on every frame instead of slider below.",
        ["Native"] = "Render on every frame instead of slider below.",
        ["Refresh Rate"] = "Refreshs per second - from 0.1 per second (every 10 seconds) to 30 per second",
        ["Scan Interval"] = "Seconds between minimap re-scans. Lower values are more responsive but cost more performance.",
        ["Default Zoom"] = "Default camera ortho width (map zoom level) on load.",
        ["Super Zoom"] = "Camera ortho width used while Super Zoom is toggled on.",
        -- "Zoom" SettingKey is the keybind row (section header only uses the label).
        ["Zoom"] = "Key to zoom in and out",
        ["Map Move Mode"] = "Key toggle the map move mode",
        ["Toggle Map"] = "Key to toggle map visibility",
        ["Map Up"] = "Key to move map up in move mode",
        ["Map Down"] = "Key to move map down in move mode",
        ["Map Left"] = "Key to move map left in move mode",
        ["Map Right"] = "Key to move map right in move mode",
        ["Map Bigger"] = "Key increase size in move mode",
        ["Map Smaller"] = "Key decrease size in move mode",
        ["Zoom In"] = "Key to zoom in while held",
        ["Zoom Out"] = "Key to zoom out while held",
        -- section descriptions (if shown)
        ["General"] = "General settings for the overlay.",
        ["Position and Size"] = "Position and Size of the Map.",
        ["Scan"] = "Scan for items.",
        ["Icon Scale"] = "Per-type icon scale multipliers.",
        ["Performence tuning"] = "Performence tuning",
        ["Performance tuning"] = "Performance tuning",
        ["Keymap"] = "Keymap for hotkeys",
    },
    zh = {
        ["Mod Logic Enabled"] = "是否启用小地图模组。",
        ["Rotate Map"] = "旋转地图。关闭则始终指向北方。",
        ["Round Map"] = "显示圆形地图，而不是方形地图。",
        ["Opacity"] = "地图透明度（百分比）。",
        ["Icon Color"] = "用于给地下城、蛋、快速旅行点、宝箱和手记图标着色的颜色。",
        ["Hide Map In Base"] = "在据点内自动隐藏地图。关闭后据点内仍显示地图。",
        ["Debug"] = "是否启用调试日志。",
        ["Size"] = "地图大小。",
        ["PosX"] = "地图的 X 位置。可在游戏内使用 CTRL + F8 调整。",
        ["PosY"] = "地图的 Y 位置。可在游戏内使用 CTRL + F8 调整。",
        ["Treasure"] = "是否在地图上显示宝箱。",
        ["Pals"] = "是否在地图上显示帕鲁。",
        ["Egg"] = "是否在地图上显示帕鲁蛋。",
        ["Relics"] = "是否在地图上显示遗物。",
        ["Notes"] = "是否在地图上显示手记。",
        ["Dungeon"] = "是否在地图上显示地下城。",
        ["FastTravel"] = "是否在地图上显示快速旅行点。",
        ["Player Pals"] = "是否在地图上显示其他玩家已召唤的帕鲁。",
        ["Players"] = "是否在地图上显示其他玩家。",
        ["NPCs"] = "是否在地图上显示人类 NPC。",
        ["Pal Scale"] = "帕鲁图标缩放倍率。",
        ["Relic Scale"] = "遗物图标缩放倍率。",
        ["Note Scale"] = "手记图标缩放倍率。",
        ["Dungeon Scale"] = "地下城图标缩放倍率。",
        ["Treasure Scale"] = "宝箱图标缩放倍率。",
        ["Egg Scale"] = "蛋图标缩放倍率。",
        ["FastTravel Scale"] = "快速旅行图标缩放倍率。",
        ["Player Scale"] = "玩家图标缩放倍率。",
        ["Player Pal Scale"] = "其他玩家帕鲁图标缩放倍率。",
        ["Member Scale"] = "其他玩家图标缩放倍率。",
        ["NPC Scale"] = "NPC 图标缩放倍率。",
        ["Nativ"] = "每帧原生渲染，而不是使用下方刷新率滑条。",
        ["Native"] = "每帧原生渲染，而不是使用下方刷新率滑条。",
        ["Refresh Rate"] = "每秒刷新次数（0.1 = 每 10 秒一次，最高 30）。",
        ["Scan Interval"] = "小地图重新扫描间隔（秒）。数值越小越灵敏，但性能开销更大。",
        ["Default Zoom"] = "加载时默认相机正交宽度（地图缩放级别）。",
        ["Super Zoom"] = "开启超级缩放时使用的相机正交宽度。",
        ["Zoom"] = "放大/缩小快捷键",
        ["Map Move Mode"] = "切换地图移动模式的快捷键",
        ["Toggle Map"] = "切换地图显示的快捷键",
        ["Map Up"] = "移动模式下将地图上移",
        ["Map Down"] = "移动模式下将地图下移",
        ["Map Left"] = "移动模式下将地图左移",
        ["Map Right"] = "移动模式下将地图右移",
        ["Map Bigger"] = "移动模式下增大地图尺寸",
        ["Map Smaller"] = "移动模式下减小地图尺寸",
        ["Zoom In"] = "按住时拉近视角",
        ["Zoom Out"] = "按住时拉远视角",
        ["General"] = "覆盖层的常规设置。",
        ["Position and Size"] = "地图的位置与大小。",
        ["Scan"] = "扫描并显示物品。",
        ["Icon Scale"] = "按类型设置图标缩放倍率。",
        ["Performence tuning"] = "性能调节",
        ["Performance tuning"] = "性能调节",
        ["Keymap"] = "快捷键映射",
    },
}

-- Reverse map: any known English OR Chinese string -> canonical key
local CANONICAL = {}
local function buildCanonical()
    for lang, table_ in pairs(LABELS) do
        for key, text in pairs(table_) do
            CANONICAL[text] = key
            CANONICAL[key] = key
        end
    end
    -- English source labels equal keys for most entries already
    for key, _ in pairs(LABELS.en) do
        CANONICAL[key] = key
    end
end
buildCanonical()

local function trLabel(lang, keyOrText)
    if keyOrText == nil or keyOrText == "" then return keyOrText end
    local key = CANONICAL[keyOrText] or keyOrText
    local bag = LABELS[lang] or LABELS.en
    return bag[key] or LABELS.en[key] or keyOrText
end

local function trDesc(lang, keyOrText)
    if keyOrText == nil or keyOrText == "" then return keyOrText end
    -- Prefer SettingKey mapping; also accept matching an existing English/Chinese desc
    local key = CANONICAL[keyOrText]
    if not key then
        for k, v in pairs(DESCS.en) do
            if v == keyOrText then key = k break end
        end
        if not key then
            for k, v in pairs(DESCS.zh) do
                if v == keyOrText then key = k break end
            end
        end
    end
    if not key then
        -- If the text itself is a known key name
        if DESCS.en[keyOrText] or DESCS.zh[keyOrText] then key = keyOrText end
    end
    if not key then return keyOrText end
    local bag = DESCS[lang] or DESCS.en
    return bag[key] or DESCS.en[key] or keyOrText
end

local function normalizeSettingKey(key)
    if type(key) ~= "string" or key == "" then return nil end
    -- Blueprint stores keys as "Section::Field" (e.g. General::Hide Map In Base)
    local bare = key:match("::(.+)$")
    if bare and bare ~= "" then return bare end
    return key
end

local function readSettingKey(row)
    if not isAlive(row) then return nil end
    local key
    local ok = pcall(function()
        key = row.SettingKey
    end)
    if not ok then return nil end
    return normalizeSettingKey(asString(key))
end

local function applyLabelDesc(row, lang, useKey, labelWidget, descWidget)
    if useKey and useKey ~= "" then
        local lab = trLabel(lang, useKey)
        local desc = trDesc(lang, useKey)
        -- Only overwrite when we have a real translation (avoid painting "Section::Key")
        if lab and lab ~= useKey then
            setText(labelWidget, lab)
        else
            local cur = getText(labelWidget)
            local bare = normalizeSettingKey(cur) or cur
            if bare then
                local t = trLabel(lang, bare)
                if t and t ~= bare and t ~= cur then setText(labelWidget, t) end
            end
        end
        if desc and desc ~= useKey then
            setText(descWidget, desc)
        else
            local cur = getText(descWidget)
            local bare = normalizeSettingKey(cur) or cur
            if bare then
                local t = trDesc(lang, bare)
                if t and t ~= bare and t ~= cur then setText(descWidget, t) end
            end
        end
        return
    end
    local labelText = getText(labelWidget)
    local descText = getText(descWidget)
    if labelText then
        local bare = normalizeSettingKey(labelText) or CANONICAL[labelText] or labelText
        local t = trLabel(lang, bare)
        if t and t ~= labelText then setText(labelWidget, t) end
    end
    if descText then
        local t = trDesc(lang, descText)
        if t and t ~= descText then setText(descWidget, t) end
    end
end

local function localizeToggleRow(row, lang)
    local key = readSettingKey(row)
    local labelText = getText(row.Label)
    local useKey = key
    if (not useKey or useKey == "") and labelText then
        useKey = normalizeSettingKey(labelText) or CANONICAL[labelText] or labelText
    end
    applyLabelDesc(row, lang, useKey, row.Label, row.TextBlock)

    -- ON / OFF buttons
    local t1 = getText(row.btnOneText)
    local t2 = getText(row.btnTwoText)
    if t1 then
        local u = t1:upper()
        if u == "ON" or t1 == "开" then setText(row.btnOneText, trLabel(lang, "ON"))
        else setText(row.btnOneText, trLabel(lang, CANONICAL[t1] or t1)) end
    else
        setText(row.btnOneText, trLabel(lang, "ON"))
    end
    if t2 then
        local u = t2:upper()
        if u == "OFF" or t2 == "关" then setText(row.btnTwoText, trLabel(lang, "OFF"))
        else setText(row.btnTwoText, trLabel(lang, CANONICAL[t2] or t2)) end
    else
        setText(row.btnTwoText, trLabel(lang, "OFF"))
    end
end

local function localizeSliderRow(row, lang)
    local key = readSettingKey(row)
    local labelText = getText(row.Label)
    local useKey = key
    if (not useKey or useKey == "") and labelText then
        useKey = normalizeSettingKey(labelText) or CANONICAL[labelText] or labelText
    end
    applyLabelDesc(row, lang, useKey, row.Label, row.TextBlock)
end

local function localizeKeybindRow(row, lang)
    localizeSliderRow(row, lang)
end

local function localizeHeaderRow(row, lang)
    local text = getText(row.TextBlock)
    if not text then return end
    local bare = normalizeSettingKey(text) or text
    -- Prefer section title; if current text is a known section description, map back to title.
    local titleKey = bare
    if not LABELS.en[bare] then
        for k, v in pairs(DESCS.en) do
            if v == text or v == bare then titleKey = k break end
        end
        for k, v in pairs(DESCS.zh) do
            if v == text or v == bare then titleKey = k break end
        end
    end
    local title = trLabel(lang, titleKey)
    if title and title ~= text then
        setText(row.TextBlock, title)
    end
end

local debugOnce = false
local lastApplyStats = ""

local function normalizeWs(s)
    if type(s) ~= "string" then return s end
    return (s:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", ""))
end

-- Exact English description -> translated description (safe: never matches short titles)
local DESC_EN_TO_KEY = nil
local function buildDescIndex()
    DESC_EN_TO_KEY = {}
    for k, v in pairs(DESCS.en) do
        DESC_EN_TO_KEY[normalizeWs(v)] = k
    end
    -- also index Chinese so re-apply is stable
    for k, v in pairs(DESCS.zh) do
        DESC_EN_TO_KEY[normalizeWs(v)] = k
    end
end
buildDescIndex()

local function translateAnyString(lang, cur)
    if not cur or cur == "" then return cur end
    local bare = normalizeSettingKey(cur) or cur
    -- Labels / chrome first
    local t = trLabel(lang, bare)
    if t ~= bare and t ~= cur then return t end
    t = trLabel(lang, cur)
    if t ~= cur then return t end
    -- Exact description paragraphs only (used by color picker rows etc. that
    -- are not WBP_SettingsRow_*). Short labels never equal full EN descs.
    local norm = normalizeWs(cur)
    local key = DESC_EN_TO_KEY[norm]
    if not key then
        -- Multiline / soft-wrap variants: match distinctive EN substrings
        local lower = norm:lower()
        if lower:find("tint dungeons", 1, true) or lower:find("fast travel points, chests", 1, true) then
            key = "Icon Color"
        end
    end
    if key then
        local bag = DESCS[lang] or DESCS.en
        local d = bag[key] or DESCS.en[key]
        if d and d ~= cur then return d end
    end
    return cur
end

local function walkWidgetTexts(root, lang, depth, stats)
    depth = depth or 0
    stats = stats or { visited = 0, changed = 0 }
    if depth > 16 or not isAlive(root) then return stats end
    stats.visited = stats.visited + 1

    -- Direct known TextBlock-ish properties on this object
    local names = {
        "TextBlock", "Label", "Title", "TitleText", "Header", "btnOneText", "btnTwoText",
        "Description", "Value",
    }
    for _, name in ipairs(names) do
        local ok, child = pcall(function() return root[name] end)
        if ok and isAlive(child) then
            local cur = getText(child)
            if cur and cur ~= "" then
                local translated = translateAnyString(lang, cur)
                if translated and translated ~= cur then
                    if setText(child, translated) then
                        stats.changed = stats.changed + 1
                    end
                end
            elseif looksLikeTextWidget(child) then
                -- property holds the text widget itself
            end
        end
    end

    -- If this node itself is a text widget, translate its content
    if looksLikeTextWidget(root) then
        local cur = getText(root)
        if cur and cur ~= "" then
            local translated = translateAnyString(lang, cur)
            if translated and translated ~= cur then
                if setText(root, translated) then
                    stats.changed = stats.changed + 1
                end
            end
        end
    end

    -- UPanelWidget children
    pcall(function()
        if root.GetChildrenCount ~= nil then
            local n = root:GetChildrenCount()
            if type(n) == "number" then
                for i = 0, n - 1 do
                    local child = root:GetChildAt(i)
                    walkWidgetTexts(child, lang, depth + 1, stats)
                end
            end
        end
    end)

    -- UWidget GetAllChildren (TArray)
    pcall(function()
        if root.GetAllChildren ~= nil then
            local children = root:GetAllChildren()
            if children ~= nil then
                local n = nil
                pcall(function() n = children:GetArrayNum() end)
                if type(n) ~= "number" then pcall(function() n = #children end) end
                if type(n) == "number" then
                    for i = 1, n do
                        local child = children[i]
                        if child == nil and children.Get then
                            pcall(function() child = children:Get(i - 1) end)
                        end
                        walkWidgetTexts(child, lang, depth + 1, stats)
                    end
                end
            end
        end
    end)

    -- WidgetTree root for user widgets
    pcall(function()
        local tree = root.WidgetTree
        if isAlive(tree) and isAlive(tree.RootWidget) then
            walkWidgetTexts(tree.RootWidget, lang, depth + 1, stats)
        end
    end)

    return stats
end

local function localizeSettingsPanel(panel, lang)
    if not isAlive(panel) then return end

    local toggles = collectOf("WBP_SettingsRow_Toggle_C")
    local sliders = collectOf("WBP_SettingsRow_Slider_C")
    local keybinds = collectOf("WBP_SettingsRow_Keybind_C")
    local headers = collectOf("WBP_SettingsRow_Header_C")

    -- Also try fully-qualified blueprint paths (some UE4SS builds need them)
    if #toggles == 0 then
        toggles = collectOf("/Game/Mods/YetAnotherMinimap/Components/WBP_SettingsRow_Toggle.WBP_SettingsRow_Toggle_C")
    end
    if #sliders == 0 then
        sliders = collectOf("/Game/Mods/YetAnotherMinimap/Components/WBP_SettingsRow_Slider.WBP_SettingsRow_Slider_C")
    end
    if #keybinds == 0 then
        keybinds = collectOf("/Game/Mods/YetAnotherMinimap/Components/WBP_SettingsRow_Keybind.WBP_SettingsRow_Keybind_C")
    end
    if #headers == 0 then
        headers = collectOf("/Game/Mods/YetAnotherMinimap/Components/WBP_SettingsRow_Header.WBP_SettingsRow_Header_C")
    end

    for _, r in ipairs(toggles) do localizeToggleRow(r, lang) end
    for _, r in ipairs(sliders) do localizeSliderRow(r, lang) end
    for _, r in ipairs(keybinds) do localizeKeybindRow(r, lang) end
    for _, r in ipairs(headers) do localizeHeaderRow(r, lang) end

    -- Chrome + deep walk: title, Reset/Save/Cancel, any missed rows
    local stats = { visited = 0, changed = 0 }
    walkWidgetTexts(panel, lang, 0, stats)
    for _, name in ipairs({ "btnReset", "btnSave", "btnCancel", "ScrollBox" }) do
        local ok, child = pcall(function() return panel[name] end)
        if ok and isAlive(child) then
            walkWidgetTexts(child, lang, 0, stats)
        end
    end

    local summary = string.format(
        "lang=%s toggles=%d sliders=%d keybinds=%d headers=%d walk_changed=%d walk_visited=%d",
        tostring(lang), #toggles, #sliders, #keybinds, #headers, stats.changed, stats.visited
    )
    if summary ~= lastApplyStats then
        lastApplyStats = summary
        log("apply " .. summary)
    end

    if not debugOnce and (#toggles + #sliders + #keybinds + #headers) > 0 then
        debugOnce = true
        local sample = toggles[1] or sliders[1] or keybinds[1]
        if sample then
            log(string.format(
                "sample key=%s label=%s desc=%s",
                tostring(readSettingKey(sample)),
                tostring(getText(sample.Label)),
                tostring(getText(sample.TextBlock))
            ))
        end
        if headers[1] then
            log("sample header=" .. tostring(getText(headers[1].TextBlock)))
        end
    end
end

-- ---------------------------------------------------------------------------
-- Poll while a settings panel exists
-- ---------------------------------------------------------------------------
local lastLocalizedAt = 0
local lastPanelKey = nil
local POLL_MS = 250

local function objectKey(obj)
    if not isAlive(obj) then return nil end
    local ok, s = pcall(function()
        return string.format("%s", obj:GetFullName())
    end)
    if ok then return s end
    return tostring(obj)
end

local function findSettingsPanels()
    local found = collectOf("WBT_MinimapSettings_C")
    if #found == 0 then
        found = collectOf("/Game/Mods/YetAnotherMinimap/WBT_MinimapSettings.WBT_MinimapSettings_C")
    end
    return found
end

local function tickLocalize()
    local panels = findSettingsPanels()
    if #panels == 0 then
        lastPanelKey = nil
        debugOnce = false
        lastApplyStats = ""
        return
    end

    local lang = detectMenuLanguage(true)
    -- Re-apply continuously while open: blueprint BuildSettingsRows can repaint
    -- English after our first pass (and late rows appear after Construct).
    local now = os.clock()
    local panelKey = objectKey(panels[1])
    local force = (panelKey ~= lastPanelKey) or (now - lastLocalizedAt > 0.35)
    if not force then return end

    lastPanelKey = panelKey
    lastLocalizedAt = now

    for _, panel in ipairs(panels) do
        local ok, err = pcall(localizeSettingsPanel, panel, lang)
        if not ok then
            log("localize failed: " .. tostring(err))
        end
    end
end

-- World change -> drop language cache (title screens sometimes report "en")
-- Debounced: NotifyOnNewObject(World) fires very frequently during streaming.
local lastWorldClearAt = 0
local function onWorldChange()
    local now = os.clock()
    if now - lastWorldClearAt < 5 then return end
    lastWorldClearAt = now
    clearLanguageCache()
    lastPanelKey = nil
    lastLocalizedAt = 0
    log("world change; language cache cleared")
end

-- Avoid NotifyOnNewObject delayed callbacks that can throw
-- "[Lua::Registry::get_function_ref] Ref was not function" on this UE4SS build.
-- Polling is enough once the panel exists.
pcall(function()
    NotifyOnNewObject("/Script/Engine.World", function(_world)
        pcall(function()
            ExecuteWithDelay(800, function()
                onWorldChange()
            end)
        end)
    end)
end)

-- One-shot culture probe a few seconds after load (for log verification)
ExecuteWithDelay(4000, function()
    pcall(function()
        ExecuteInGameThread(function()
            pcall(function()
                detectMenuLanguage(true)
            end)
        end)
    end)
end)

LoopAsync(POLL_MS, function()
    local ok, err = pcall(function()
        ExecuteInGameThread(function()
            pcall(tickLocalize)
        end)
    end)
    if not ok then
        pcall(function() log("poll error: " .. tostring(err)) end)
    end
    return false
end)

log("loaded — settings panel follows game language (zh/en)")
