--# Windows
--factories for various window types

--difference between dialog and window
--dialogs ok/cancel buttons occupy full width of window, like ios alerts. Are disposable (closing them kills them)
--window has discrete ok/cancel buttons. Has doNotKill option where dismissing window will hide it instead of killing it
Soda.Window = class(Soda.Frame)

function Soda.Window:init(t)
    t.shape = t.shape or Soda.RoundedRectangle
    t.shapeArgs = t.shapeArgs or {}
    t.shapeArgs.radius = t.shapeArgs.radius or 25
    if not t.label and t.title then
        t.label = {x=0.5, y=-15}
    end
    t.content = t.content or ""
    Soda.Frame.init(self, t)
    
    if t.ok then
        local title = "OK"
        if type(t.ok)=="string" then title = t.ok end
        Soda.Button{parent = self, title = title, x = -10, y = 10, w = 0.3, h = 40, 
            callback = function() 
                -- self:callback() invokes Frame's own already-wrapped,
                -- self-stripped callback (see FRAME.lua). Previously this
                -- referenced a bare local `callback` that had been
                -- dropped from this function, so tapping OK on any Window
                -- built with ok=true threw "attempt to call a nil value
                -- (global 'callback')". Using self:callback() here avoids
                -- needing to reintroduce that separate local at all.
                if self:callback() then self:closeAction() end
            end} --style = Soda.style.transparent,blurred = t.blurred,
    end
    
    if t.cancel then
        local title = "Cancel"
        if type(t.cancel)=="string" then title = t.cancel end
        Soda.Button{parent = self, title = title, x = 10, y = 10, w = 0.3, h = 40, callback = function() self:closeAction() end,  subStyle = {"warning"}} --style = Soda.style.warning 
    end
    
    local closeStyle = {"icon", "button"}
    if t.blurred then
        closeStyle = {"icon"}
    end
    if t.close then
        Soda.CloseButton{
            parent = self, 
            x = 5, y = -5, 
            shape = Soda.ellipse,
            callback = function() self:closeAction() end, 
            subStyle = closeStyle --style = Soda.style.icon
        }
    end
    -- t.shadow = true
    if t.draggable then
        self.sensor:onDrag(function(event) 
            if isKeyboardShowing() then return end -- no winsow drag when keyboard is showing
            self.x = self.x + event.touch.deltaX 
            self.y = self.y + event.touch.deltaY
            if Soda.Blur then Soda.Blur.markDirtyAbove(self) end --live-update any blur stacked above me
        end)
    end
end

function Soda.Window:closeAction()     --do we want to hide this Window or kill it?
    if self.doNotKill then
        self:hide()
    else
        self.kill = true 
    end
end

function Soda.Window2(t)
    t.shape = t.shape or Soda.RoundedRectangle
    t.shapeArgs = t.shapeArgs or {}
    t.shapeArgs.radius = 25
    t.style = t.style or Soda.style.thickStroke
    t.label = {x=0.5, y=-10}
    --   t.shadow = true
    return Soda.Frame(t)
end

Soda.TextWindow = class(Soda.Window)

function Soda.TextWindow:init(t)
    t.x = t.x or 0.5 
    t.y = t.y or 20
    t.w = t.w or 700
    t.h = t.h or -20
    t.style = t.style or Soda.style.thickStroke
    Soda.Window.init(self, t)
    
    self.scroll = Soda.TextScroll{
        
        parent = self,
        x = 10, y = 1, w = -20, h = -2,
        --   x = t.x or 0.5, y = t.y or 20, w = t.w or 700, h = t.h or -20,
        textBody = t.textBody,
        priority = 1
    }  
    
end

function Soda.TextWindow:inputString(str)
    self.scroll:inputString(str)
end

function Soda.TextWindow:clearString()
    self.scroll:clearString()
end

function Soda.Alert2(t)
    -- Alert2/Alert are plain factory functions, not classes, so they
    -- never go through Standardizer's patch() wrapper the way
    -- Soda.Frame/Button/Window etc. do. Left untranslated, the very next
    -- line (t.h = t.h or 0.25) sets t.h directly on a table that may
    -- still be holding its real geometry in positional form (t[2] =
    -- {nil,nil,w,h}) -- and once t.h is non-nil, Soda.args's own
    -- "already translated?" check short-circuits and returns the table
    -- as-is, so the real w/h packed into t[2] are never unpacked. On
    -- phone this meant every Alert2 call using the demo's positional
    -- syntax rendered full-width at a flat 25% height regardless of
    -- Layout.dialogW()/dialogH(). Translating here, before any of this
    -- function's own defaulting runs, fixes that. It's a safe no-op for
    -- callers already using named keys (see Windows-tab discussion).
    t = Soda.args("Alert2", t)
    t.shape = t.shape or Soda.RoundedRectangle
    t.shapeArgs = t.shapeArgs or {}
    t.shapeArgs.radius = 25
    t.label = t.label or {x=0.5, y=-15}
    
    t.h = t.h or 0.25
    t.shadow = true
    --   t.label = {x=0.5, y=0.6}
    t.alert = true  --if alert=true, underlying elements are inactive and darkened until alert is dismissed
    local callback = t.callback or null
    
    local this = Soda.Frame(t)
    
    local proceed = Soda.Button{
        parent = this, 
        title = t.ok or "Proceed", 
        x = 0.749, y = 0, w = 0.5, h = 50, 
        shapeArgs = {corners = 8, radius = 25}, 
        callback = function() this.kill = true callback() end,  
        subStyle = {"transparent"} --style = Soda.style.transparent
    } --style = Soda.style.transparent,blurred = t.blurred,
    
    local cancel = Soda.Button{
        parent = this, 
        title = t.cancel or "Cancel", 
        x = 0.251, y = 0, w = 0.5, h = 50, 
        shapeArgs = {corners = 1, radius = 25}, 
        callback = function() this.kill = true end,  
        subStyle = {"transparent"} --style = Soda.style.transparent
    } 
    
    return this
end

Soda.Confirm = Soda.Alert2

function Soda.Alert(t)
    -- same fix, same reasoning as Soda.Alert2 above.
    t = Soda.args("Alert", t)
    t.shape = t.shape or Soda.RoundedRectangle
    t.shapeArgs = t.shapeArgs or {}
    t.shapeArgs.radius = 25
    t.label = t.label or {x=0.5, y=-15}
    
    t.h = t.h or 0.25
    t.shadow = true
    --   t.label = {x=0.5, y=0.6}
    t.alert = true  --if alert=true, underlying elements are inactive and darkened until alert is dismissed
    local callback = t.callback or null
    
    local this = Soda.Frame(t)
    
    local ok = Soda.Button{
        parent = this, 
        title = t.ok or "OK", 
        x = 0, y = 0, w = 1, h = 50, 
        shapeArgs = {corners = 1 | 8, radius = 25}, 
        callback = function() this.kill = true callback() end,  
        subStyle = {"transparent"} --style = Soda.style.transparent
    } --style = Soda.style.transparent,blurred = t.blurred,
    return this
end
