--# List
Soda = Soda or {}
Soda.List = class(Soda.ScrollShape)

function Soda.List:init(t)
    if type(t.text)=="string" then --can also accept a comma-separated list of values instead of a table
        local tab={}
        for word in t.text:gmatch("(.-),%s*") do
            tab[#tab+1] = word
        end
        t.text = tab
    end
    t.scrollHeight = #t.text * 40
    t.h = math.min(t.h or t.scrollHeight, t.scrollHeight)
    Soda.ScrollShape.init(self, t)
    for i,v in ipairs(t.text) do
        local number, panel = ""
        if t.enumerate then number = i..") " end
        
        if t.panels then
            panel = t.panels[i]
            panel:hide() --hide the panel by default
        end
        
        local item = Soda.Selector{parent = self, idNo = i, title = number..v, label = {x = 10, y = 0.5}, subStyle = {"listItem"}, shape = Soda.rect, highlightable = true, x = 0, y = -0.001 - (i-1)*40, w = 1, h = 42, panel = panel}
        
        item.sensor.doNotInterceptTouches = true
        
        if t.default and i==t.default then
            self:selectFromList(item)
        end
    end
    self.sensor:onDrag(function(event) self:verticalScroll(event.touch, event.tpos) end)
end

function Soda.List:clearSelection()
    if self.selected then
        self.selected.highlighted = false
        if self.selected.panel then self.selected.panel:hide() end
    end
    self.selected = nil
end

--- a factory for dropdown lists
Soda.DropdownList = class()

-- Soda's per-child x/y are corner coords resolved against the
-- IMMEDIATE parent's own pixel space, and Stack children only get
-- their real, final w/h once Soda.Stack:layout() runs -- which
-- happens lazily, from the Stack's own draw(), never during setup().
-- Reading self.button.w or its position synchronously during
-- DropdownList:init would catch its pre-layout placeholder size.
-- This mirrors why Soda's dialogs (Alert/Alert2/Window) are built
-- entirely inside their triggering button's callback rather than at
-- construction time: by the time a tap can happen, at least one full
-- draw/layout pass has already completed, so real sizes and
-- positions are trustworthy. buildList() below follows the same
-- rule.
local function ddAbsoluteCenter(frame)
    if not frame.parent then return frame.x, frame.y end
    local pcx, pcy = ddAbsoluteCenter(frame.parent)
    return pcx - frame.parent.w * 0.5 + frame.x, pcy - frame.parent.h * 0.5 + frame.y
end

-- standard dropdown placement: prefer opening below the button, but
-- flip to open above it when there isn't room below for at least a
-- usably-sized list AND there's more room above -- eg a button near
-- the bottom of the screen still gets a real-sized popup instead of
-- a sliver. If neither side has much room, fall back to below with
-- whatever space exists; there's nothing better to do at that point.
Soda.DropdownList.MIN_POPUP_H = 4 * 40 -- ~4 rows, a "fairly large" floor

function Soda.DropdownList:init(t)
    local parent = t.parent or nil
    self.default = t.default or ""
    if t.noSymbols then
        self.placeholder = t.title.." "..self.default
    else
        self.placeholder = "\u{25bc} "..t.title..": "..self.default
    end
    
    self.button = Soda.Button{
        parent = parent, x = t.x, y = t.y, w = t.w, h = t.h,
        title = self.placeholder,
        subStyle = {"listItem"},
        label = {x = 10, y = 0.5}
    }
    
    self.title = t.title
    self.callback = t.callback or null
    self.text = t.text
    self.panels = t.panels
    self.enumerate = t.enumerate
    self.popupH = t.popupH
    self.selectedDefault = t.default -- raw value (may be nil); the List's default highlighted index
    
    self.button.callback = function()
        if not self.list then self:buildList() end
        self.list:bringToFront()
        self.list:toggle()
        self.list.modal = not self.list.hidden
    end
end

-- built once, lazily, on first open -- see the comment above the
-- class for why this can't happen in :init().
function Soda.DropdownList:buildList()
    local callback = self.callback
    local bcx, bcy = ddAbsoluteCenter(self.button)
    local btnAbsLeft = math.floor(bcx - self.button.w * 0.5)
    local btnAbsBottom = math.floor(bcy - self.button.h * 0.5)
    local btnAbsTop = btnAbsBottom + self.button.h
    
    -- room down to the physical screen's own bottom edge (0), and up
    -- to its top edge (HEIGHT) -- not any enclosing window's edge; the
    -- popup is free to spill past the window that launched it.
    local availBelow = math.max(0, btnAbsBottom)
    local availAbove = math.max(0, HEIGHT - btnAbsTop)
    
    local naturalH = #self.text * 40
    -- self.popupH (eg the Overview Lists tab passing
    -- windowSettings.contentH) is a CAP, not an override -- it must
    -- never exceed the content's natural height either.
    local desiredH = math.min(self.popupH or naturalH, naturalH)
    
    local minUsable = math.min(desiredH, Soda.DropdownList.MIN_POPUP_H)
    local openAbove = false
    local popupH
    
    if availBelow >= minUsable then
        popupH = math.min(desiredH, availBelow)
    elseif availAbove > availBelow then
        openAbove = true
        popupH = math.min(desiredH, availAbove)
    else
        popupH = math.min(desiredH, availBelow)
    end
    popupH = math.floor(popupH)
    
    local listY
    if openAbove then
        listY = math.floor(btnAbsTop) -- list's bottom edge sits on the button's top edge
    else
        listY = math.floor(btnAbsBottom - popupH) -- list's top edge sits on the button's bottom edge
    end
    
    self.list = Soda.List{
        hidden = true,
        x = btnAbsLeft,
        y = listY,
        w = self.button.w,
        h = popupH,
        text = self.text,
        panels = self.panels,
        default = self.selectedDefault,
        enumerate = self.enumerate,
        callback = function(selected, txt)          -- List is a Frame, so this is already self-stripped
            self.button.title = txt
            self.button:setPosition()
            self.list:hide()                          -- use the reference we already have
            self.list.modal = false
            callback(selected, txt)                   -- forward to the end user, self-free
        end
    }
    
    -- dismiss the list when a tap occurs outside it
    local oldTouch = self.list.touched
    self.list.touched = function(self, t, tpos)
        if self.modal and t.state == BEGAN and not self.sensor:inbox(tpos) then
            self:hide()
            self.modal = false
            return true
        end
        return oldTouch(self, t, tpos)
    end
end

function Soda.DropdownList:clearSelection()
    if self.list then
        self.list:clearSelection()
    end
    self.button.title = self.placeholder
    self.button:setPosition()
end

function Soda.DropdownList:deactivate()
    self.button:deactivate()
end

function Soda.DropdownList:activate()
    self.button:activate()
end
