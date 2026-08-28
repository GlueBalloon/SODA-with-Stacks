--# Standardizer
-- Standardizer: single-table constructors for Soda elements.
--
-- Usage:
--   Soda.Window{ nil, {0.5, 0.5, 300, 200}, title = "Test", blurred = true }
--
-- Converts to:
--   Soda.Window{ parent = nil, x = 0.5, y = 0.5, w = 300, h = 200, title = "Test", blurred = true }

Soda.presets = {
    panel = {
        shape = Soda.RoundedRectangle,
        subStyle = {"translucent"},
        shapeArgs = {radius = 16},
    },
    iconBtn = {
        w = 40, h = 40,
        subStyle = {"icon", "button"},
    },
    row = {
        h = 40,
    },
}

local function applyPreset(t)
    if not t.preset then return end
    local preset = Soda.presets[t.preset]
    if not preset then return end
    for k, v in pairs(preset) do
        if k == "shapeArgs" then
            t.shapeArgs = t.shapeArgs or {}
            for pk, pv in pairs(v) do
                if t.shapeArgs[pk] == nil then t.shapeArgs[pk] = pv end
            end
        elseif t[k] == nil then
            t[k] = v
        end
    end
end

function Soda.measureText(str, style, wrapW)
    pushStyle()
    local sty = (style and style.text) or Soda.style.default.text
    Soda.setStyle(sty)
    if wrapW then textWrapWidth(wrapW) end
    local w, h = textSize(str or "")
    textWrapWidth()
    popStyle()
    return w, h
end

local function resolvedWidth(t)
    local edge = (t.parent and t.parent.w) or WIDTH
    local w, x = t.w, t.x or 0
    if type(w) ~= "number" then return nil end
    if w > 1 then return w end
    if w > 0 then return math.ceil(edge * w) end
    local x2 = edge + w
    local x1
    if x % 1 == 0 and x >= 0 then
        x1 = x
    elseif x < 0 then
        x1 = edge + x
    else
        x1 = math.ceil(edge * x)
    end
    return x2 - x1
end

local function resolveTitle(t, style)
    if type(t.title) ~= "table" then return end
    local w = resolvedWidth(t)
    if w then
        local chosen = t.title[#t.title]
        for i, s in ipairs(t.title) do
            local mw = Soda.measureText(s, style)
            if mw <= w then
                chosen = s
                break
            end
        end
        t.title = chosen
    else
        t.title = t.title[1]
    end
end

local function deepMerge(base, add)
    local out = {}
    for k, v in pairs(base) do out[k] = v end
    for k, v in pairs(add) do
        if type(v) == "table" and type(out[k]) == "table" then
            out[k] = deepMerge(out[k], v)
        else
            out[k] = v
        end
    end
    return out
end

local function applyStyleAdd(t)
    if not t.styleAdd then return end
    local base = t.style or (t.parent and t.parent.style) or Soda.style.default
    t.style = deepMerge(base, t.styleAdd)
    t.styleAdd = nil
end

local BTN_PAD = 16
local CONTENT_PAD = 16

local function resolveAutoSize(t, style)
    if t.w == "auto" then
        if type(t.title) == "string" and t.title ~= "" then
            local mw = Soda.measureText(t.title, style)
            t.w = mw + 2 * BTN_PAD
        else
            t.w = nil
        end
    end
    if t.h == "auto" then
        if t.content then
            local rw = resolvedWidth(t)
            local wrapW = rw and (rw * 0.9) or nil
            local _, mh = Soda.measureText(t.content, style, wrapW)
            t.h = mh + 2 * CONTENT_PAD
        else
            t.h = nil
        end
    end
end

local function isSodaInstance(v)
    return type(v) == "table" and getmetatable(v) ~= nil
end

local function parseGeom(geom)
    if geom == nil then return {} end
    if type(geom) ~= "table" then
        error("Soda.args: geometry must be a table or nil, got " .. type(geom))
    end
    
    local hasPositional = false
    local hasNamed = false
    local out = {}
    
    for i = 1, 4 do
        if geom[i] ~= nil then
            hasPositional = true
            break
        end
    end
    
    local namedKeys = {"x", "y", "w", "h"}
    for _, key in ipairs(namedKeys) do
        if geom[key] ~= nil then
            hasNamed = true
            break
        end
    end
    
    if hasPositional and hasNamed then
        error("Soda.args: cannot mix positional and named geometry values")
    end
    
    if hasPositional then
        for i, key in ipairs({"x", "y", "w", "h"}) do
            if geom[i] ~= nil then
                out[key] = geom[i]
            end
        end
    elseif hasNamed then
        for _, key in ipairs(namedKeys) do
            if geom[key] ~= nil then
                out[key] = geom[key]
            end
        end
    end
    
    return out
end

-- Soda.args converts { parent, geom, named... } to { parent = parent, x = x, ... }
function Soda.args(sigName, standardizerTable)
    if standardizerTable == nil then return {} end
    if type(standardizerTable) ~= "table" then
        error("Soda.args: expected a table, got " .. type(standardizerTable))
    end
    
    -- If it already has x,y,w,h keys, it's already in named format
    if standardizerTable.x ~= nil or standardizerTable.y ~= nil or standardizerTable.w ~= nil or standardizerTable.h ~= nil then
        return standardizerTable
    end
    
    local out = {}
    
    -- Position 1: parent
    local parent = standardizerTable[1]
    if parent ~= nil then
        if not isSodaInstance(parent) then
            error("Soda.args: position 1 (parent) must be a Soda instance or nil, got " .. type(parent))
        end
        out.parent = parent
    end
    
    -- Position 2: geometry
    local geom = standardizerTable[2]
    if geom ~= nil then
        if type(geom) ~= "table" then
            error("Soda.args: position 2 (geometry) must be a table or nil, got " .. type(geom))
        end
        local geomOut = parseGeom(geom)
        for k, v in pairs(geomOut) do
            out[k] = v
        end
    end
    
    -- All string keys (skip numeric positions 1 and 2)
    for k, v in pairs(standardizerTable) do
        if type(k) == "string" then
            out[k] = v
        end
    end
    
    return out
end

local function unifyToggleCallback(t, sigName)
    if sigName ~= "Toggle" then return end
    if type(t.callback) ~= "function" then return end
    local userCB = t.callback
    local userOffCB = t.callbackOff
    t.callback = function() userCB(true) end
    t.callbackOff = userOffCB or function() userCB(false) end
end

-- patch(): replace every class's init with a wrapper that converts
-- { parent, geom, named... } to { parent = parent, x = x, ... }
local function patch(cls, sigName)
    local old = cls.init
    cls.init = function(self, standardizerTable)
        local args = Soda.args(sigName, standardizerTable)
        applyPreset(args)
        applyStyleAdd(args)
        local effStyle = args.style or (args.parent and args.parent.style) or Soda.style.default
        resolveTitle(args, effStyle)
        resolveAutoSize(args, effStyle)
        unifyToggleCallback(args, sigName)
        return old(self, args)
    end
end

patch(Soda.Frame, "Frame")
patch(Soda.Button, "Button")
patch(Soda.Toggle, "Toggle")
patch(Soda.Switch, "Switch")
patch(Soda.Selector, "Selector")
patch(Soda.Slider, "Slider")
patch(Soda.TextEntry, "TextEntry")
patch(Soda.Scroll, "Scroll")
patch(Soda.ScrollShape, "ScrollShape")
patch(Soda.TextScroll, "TextScroll")
patch(Soda.List, "List")
patch(Soda.DropdownList, "DropdownList")
patch(Soda.ColorWheel, "ColorWheel")
patch(Soda.Window, "Window")
patch(Soda.TextWindow, "TextWindow")
patch(Soda.Stack, "Stack")
patch(Soda.Grid, "Grid")

local oldVStack = Soda.VStack
local oldHStack = Soda.HStack

Soda.VStack = function(standardizerTable)
    return oldVStack(Soda.args("VStack", standardizerTable))
end

Soda.HStack = function(standardizerTable)
    return oldHStack(Soda.args("HStack", standardizerTable))
end

local function wrapFactory(name, sigName)
    local old = Soda[name]
    Soda[name] = function(standardizerTable)
        return old(Soda.args(sigName, standardizerTable))
    end
end

for _, name in ipairs({
    "MenuButton", "BackButton", "ForwardButton", "CloseButton",
    "DropdownButton", "SettingsButton", "AddButton", "DeleteButton", "QueryButton",
}) do
    wrapFactory(name, "Button")
end

for _, name in ipairs({ "MenuToggle", "SettingsToggle" }) do
    wrapFactory(name, "Toggle")
end

local oldSegmentInit = Soda.Segment.init

Soda.Segment.init = function(self, standardizerTable)
    local t = Soda.args("Segment", standardizerTable)
    if t.rows and t.rows > 1 then
        Soda.Segment.buildRows(self, t)
    else
        oldSegmentInit(self, t)
    end
end

function Soda.Segment.buildRows(self, t)
    local rows = t.rows
    local rowGap = t.rowGap or 8
    local texts = t.text
    local panels = t.panels
    local nItems = #texts
    local perRow = math.ceil(nItems / rows)
    
    t.h = t.h or (40 * rows + rowGap * (rows - 1))
    
    Soda.Frame.init(self, {
        parent = t.parent, x = t.x, y = t.y, w = t.w, h = t.h,
        style = t.style, priority = t.priority,
    })
    
    local rowH = Soda.Stack.pxSize((self.h - rowGap * (rows - 1)) / rows)
    self.rowStrips = {}
    
    local userDefault = t.default or 1
    local defaultRow = math.ceil(userDefault / perRow)
    local defaultCol = userDefault - (defaultRow - 1) * perRow
    
    for r = 1, rows do
        local startI = (r - 1) * perRow + 1
        local stopI = math.min(nItems, r * perRow)
        if startI > nItems then break end
        
        local rowTexts, rowPanels = {}, panels and {} or nil
        for i = startI, stopI do
            rowTexts[#rowTexts + 1] = texts[i]
            if panels then rowPanels[#rowPanels + 1] = panels[i] end
        end
        
        local rowY = Soda.Stack.pxPos(self.h - r * rowH - (r - 1) * rowGap)
        
        local strip
        strip = Soda.Segment{
            parent = self, x = 0, y = rowY, w = 1, h = rowH,
            text = rowTexts,
            panels = rowPanels,
            subStyle = t.subStyle,
            noSelectionPossible = t.noSelectionPossible,
            default = (defaultRow == r) and defaultCol or 0,
            callback = function(selectedChild, title)
                for _, other in ipairs(self.rowStrips) do
                    if other ~= strip and other.selected then
                        other.selected.highlighted = false
                        if other.selected.panel then other.selected.panel:hide() end
                        other.selected = nil
                    end
                end
                local globalIdx = (strip.rowNo - 1) * perRow + selectedChild.idNo
                if t.callback then t.callback(selectedChild, title, globalIdx) end
            end,
        }
        strip.rowNo = r
        self.rowStrips[#self.rowStrips + 1] = strip
    end
end
