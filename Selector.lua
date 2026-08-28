--# Selector
Soda.Selector = class(Soda.Button) --press deactivates its siblings

function Soda.Selector:init(t)
    t.shape = t.shape or Soda.RoundedRectangle
    -- was unconditional (t.label = t.label or {...}), forcing a label
    -- even when no title exists -- the same shape of bug fixed in
    -- Slider/Switch/TextEntry/Window earlier: Frame:draw crashes on
    -- text(nil, ...) if self.label is truthy but self.title never got
    -- set. No current call site hits this (Segment/List always pass a
    -- title into their Selector children), but this matches Frame's own
    -- rule and closes the gap for any future caller.
    if not t.label and t.title then
        t.label = { x=0.5, y=0.5 }
    end
    t.highlightable = true
    t.subStyle = t.subStyle or {"button"}
    Soda.Frame.init(self, t)
    
    self.sensor = Soda.Gesture{parent=self, xywhMode = CENTER}
    self.sensor:onQuickTap(function(event) 
        self:callback() 
        self.parent:selectFromList(self) 
    end)
    
end
