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
    return obj ~= nil and pcall(function() return obj:IsValid() end) and obj:IsValid()
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
    if ok and type(s) == "string" then return s end
    return nil
end

local function getText(tb)
    if not isAlive(tb) then return nil end
    local ok, text = pcall(function()
        local t = tb:GetText()
        return asString(t)
    end)
    if ok then return text end
    return nil
end

local function setText(tb, str)
    if not isAlive(tb) or type(str) ~= "string" then return false end
    local ok = pcall(function()
        tb:SetText(FText(str))
    end)
    return ok
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

local function readSettingKey(row)
    if not isAlive(row) then return nil end
    local key
    local ok = pcall(function()
        key = row.SettingKey
    end)
    if not ok then return nil end
    return asString(key)
end

local function localizeToggleRow(row, lang)
    local key = readSettingKey(row)
    local labelText = getText(row.Label)
    local descText = getText(row.TextBlock)
    local useKey = key
    if (not useKey or useKey == "") and labelText then
        useKey = CANONICAL[labelText] or labelText
    end
    if useKey and useKey ~= "" then
        setText(row.Label, trLabel(lang, useKey))
        setText(row.TextBlock, trDesc(lang, useKey))
    else
        if labelText then setText(row.Label, trLabel(lang, labelText)) end
        if descText then setText(row.TextBlock, trDesc(lang, descText)) end
    end
    -- ON / OFF buttons
    local t1 = getText(row.btnOneText)
    local t2 = getText(row.btnTwoText)
    if t1 then setText(row.btnOneText, trLabel(lang, CANONICAL[t1] or t1)) end
    if t2 then setText(row.btnTwoText, trLabel(lang, CANONICAL[t2] or t2)) end
    -- Force common ON/OFF even if custom casing
    if t1 and (t1:upper() == "ON" or t1 == "开" or t1 == "开 " ) then setText(row.btnOneText, trLabel(lang, "ON")) end
    if t2 and (t2:upper() == "OFF" or t2 == "关" or t2 == "关 ") then setText(row.btnTwoText, trLabel(lang, "OFF")) end
    if not t1 then setText(row.btnOneText, trLabel(lang, "ON")) end
    if not t2 then setText(row.btnTwoText, trLabel(lang, "OFF")) end
end

local function localizeSliderRow(row, lang)
    local key = readSettingKey(row)
    local labelText = getText(row.Label)
    local descText = getText(row.TextBlock)
    local useKey = key
    if (not useKey or useKey == "") and labelText then
        useKey = CANONICAL[labelText] or labelText
    end
    if useKey and useKey ~= "" then
        setText(row.Label, trLabel(lang, useKey))
        setText(row.TextBlock, trDesc(lang, useKey))
    else
        if labelText then setText(row.Label, trLabel(lang, labelText)) end
        if descText then setText(row.TextBlock, trDesc(lang, descText)) end
    end
end

local function localizeKeybindRow(row, lang)
    localizeSliderRow(row, lang) -- same Label + TextBlock pattern
end

local function localizeHeaderRow(row, lang)
    local text = getText(row.TextBlock)
    if text then
        setText(row.TextBlock, trLabel(lang, text))
    end
end

local function walkWidgetTexts(root, lang, depth)
    depth = depth or 0
    if depth > 12 or not isAlive(root) then return end

    -- Direct known TextBlock-ish properties on this object
    local names = {
        "TextBlock", "Label", "Title", "TitleText", "Header", "btnOneText", "btnTwoText",
        "Text", "Content", "Description",
    }
    for _, name in ipairs(names) do
        local ok, child = pcall(function() return root[name] end)
        if ok and isAlive(child) then
            local cur = getText(child)
            if cur and cur ~= "" then
                local translated = trLabel(lang, cur)
                if translated == cur then
                    translated = trDesc(lang, cur)
                end
                if translated and translated ~= cur then
                    setText(child, translated)
                end
            end
        end
    end

    -- Button caption via GetContent / child text if present
    pcall(function()
        if root.GetChildrenCount ~= nil then
            local n = root:GetChildrenCount()
            if type(n) == "number" then
                for i = 0, n - 1 do
                    local child = root:GetChildAt(i)
                    walkWidgetTexts(child, lang, depth + 1)
                end
            end
        end
    end)
end

local function localizeSettingsPanel(panel, lang)
    if not isAlive(panel) then return end

    -- Typed rows (preferred — SettingKey is authoritative)
    local function each(className, fn)
        local ok, list = pcall(FindAllOf, className)
        if not ok or list == nil then return end
        if type(list) == "table" then
            for _, obj in pairs(list) do
                if isAlive(obj) then fn(obj) end
            end
        elseif isAlive(list) then
            fn(list)
        end
    end

    each("WBP_SettingsRow_Toggle_C", function(r) localizeToggleRow(r, lang) end)
    each("WBP_SettingsRow_Slider_C", function(r) localizeSliderRow(r, lang) end)
    each("WBP_SettingsRow_Keybind_C", function(r) localizeKeybindRow(r, lang) end)
    each("WBP_SettingsRow_Header_C", function(r) localizeHeaderRow(r, lang) end)

    -- Chrome: title + Reset / Save / Cancel button captions
    walkWidgetTexts(panel, lang, 0)
    for _, name in ipairs({ "btnReset", "btnSave", "btnCancel", "ScrollBox" }) do
        local ok, child = pcall(function() return panel[name] end)
        if ok and isAlive(child) then
            walkWidgetTexts(child, lang, 0)
        end
    end
end

-- ---------------------------------------------------------------------------
-- Poll while a settings panel exists
-- ---------------------------------------------------------------------------
local lastLocalizedAt = 0
local lastPanelKey = nil
local POLL_MS = 400

local function objectKey(obj)
    if not isAlive(obj) then return nil end
    local ok, s = pcall(function()
        return string.format("%s", obj:GetFullName())
    end)
    if ok then return s end
    return tostring(obj)
end

local function findSettingsPanels()
    local found = {}
    local ok, list = pcall(FindAllOf, "WBT_MinimapSettings_C")
    if ok and list ~= nil then
        if type(list) == "table" then
            for _, obj in pairs(list) do
                if isAlive(obj) then table.insert(found, obj) end
            end
        elseif isAlive(list) then
            table.insert(found, list)
        end
    end
    return found
end

local function tickLocalize()
    local panels = findSettingsPanels()
    if #panels == 0 then
        lastPanelKey = nil
        return
    end

    local lang = detectMenuLanguage()
    -- Re-apply often enough that late-built rows (after BuildSettingsRows) get covered.
    local now = os.clock()
    local panelKey = objectKey(panels[1])
    local force = (panelKey ~= lastPanelKey) or (now - lastLocalizedAt > 0.75)
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

pcall(function()
    NotifyOnNewObject("/Script/Engine.World", function(_world)
        pcall(function()
            ExecuteWithDelay(800, function()
                onWorldChange()
            end)
        end)
    end)
end)

-- Apply as soon as the settings widget is constructed (rows may appear a tick later).
local function scheduleLocalize(panel, delayMs)
    ExecuteWithDelay(delayMs, function()
        ExecuteInGameThread(function()
            pcall(function()
                if not isAlive(panel) then return end
                localizeSettingsPanel(panel, detectMenuLanguage(true))
            end)
        end)
    end)
end

pcall(function()
    NotifyOnNewObject("/Game/Mods/YetAnotherMinimap/WBT_MinimapSettings.WBT_MinimapSettings_C", function(panel)
        scheduleLocalize(panel, 50)
        scheduleLocalize(panel, 250)
        scheduleLocalize(panel, 600)
    end)
end)

-- Class-name fallback (path above can differ by pak mount)
pcall(function()
    NotifyOnNewObject("WBT_MinimapSettings_C", function(panel)
        scheduleLocalize(panel, 100)
        scheduleLocalize(panel, 400)
    end)
end)

-- One-shot culture probe a few seconds after load (for log verification)
ExecuteWithDelay(4000, function()
    ExecuteInGameThread(function()
        pcall(function()
            detectMenuLanguage(true)
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
