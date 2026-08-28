--# Stack

-- Soda.Stack / Soda.VStack / Soda.HStack / Soda.Grid / Soda.Spacer
--
-- API:
--   Soda.Stack{ ...all normal Frame params...,
--     dir = "v" | "h",                              -- default "v"
--     gap = 0,
--     pad = 0,                                       -- or padLeft/padRight/padTop/padBottom
--     justify = "start"|"center"|"end"|"between",     -- main axis, default "start"
--     align   = "fill"|"start"|"center"|"end",        -- how THIS stack aligns
--                                                      -- ITS children, default "fill"
--   }
--   Soda.VStack(t) / Soda.HStack(t)                   -- thin wrappers, set dir
--   Soda.Grid{ cols = n, rowGap = , colGap = ,
--              fit = "natural" | "fill",              -- default "natural"
--              cellAlign = "center"|"start"|"end",     -- default "center", both axes
--              ... }                                   -- uniform cells, reading order
--   Soda.Spacer{ parent = stack, flex = 1 }            -- invisible flexible filler
--
-- Per-child fields, read off the child at its own construction site:
--   flex      (weight, default 1 when the child is main-axis-flexible)
--   selfAlign (how the PARENT stack should align THIS child on the cross
--              axis; overrides the parent's own `align`). Named distinctly
--              from `align` so a stack nested inside a stack doesn't read
--              its own "align my children" setting as its parent's
--              "align me" instruction -- same key, opposite meaning,
--              would otherwise collide on every nested Stack.
--
-- A stack never resizes itself. No intrinsic/shrink-to-fit sizing. Hidden
-- children keep their slot (reflow-on-hide is out of scope). justify only
-- matters when no child is flexible.
--
-- Documented conventions / known degradations:
--   * A main-axis size <= 0 (including negative) is unsupported per spec;
--     rather than erroring, it is treated as flexible (weight 1, or the
--     child's own t.flex if given) so a bad value degrades gracefully.
--   * A non-"fill" cross-align with no declared cross size on the child
--     falls back to "fill" sizing (full content-box cross extent) rather
--     than erroring, since no sensible size is otherwise specified.
--   * Cross-axis "start"/"end" always map to Soda's own near/far edge for
--     that axis (left/right for x, bottom/top for y) -- ie "start" is
--     Soda's coordinate near-edge, not a reading-order assumption.
--   * align = "fill" (the default) OVERWRITES a child's declared cross
--     size. Any child whose cross size matters -- a `w = 0.49` column, a
--     fixed-geometry element like Soda.Switch (shapeArgs is a fixed
--     70x36 track, label pinned at x=80 -- "fill" renders it as a wide
--     empty box with the track floating at one end) -- MUST set
--     `selfAlign = "start"` or `"center"` at its own construction site.
--   * An over-stuffed stack (children + gaps exceeding the content box)
--     degrades by piling children at the near edge (pxPos clamps
--     negative positions to 0) rather than failing or shrinking content.
--     No overflow detection is performed.
--   * Soda.Slider draws its track at a hardcoded y = 20 and sizes its
--     knob and value label against h = 60. A Slider given any other
--     main-axis height by a stack renders with the track off-centre --
--     always declare `h = 60` for a Slider in a VStack (or `w = 60` in
--     an HStack, for whatever that's worth).
--   * Soda.Switch needs `selfAlign` (fixed geometry, see above).
--     Soda.Toggle does NOT have this problem and stretches cleanly with
--     the default `align = "fill"` -- its only asymmetry is a
--     left-justified title, which is cosmetic, not a broken layout.

Soda.Stack = class(Soda.Frame)
Soda.Stack.MIN_PX = 2

-- ---------------------------------------------------------------------
-- local helpers (no reference to any host-project Layout table)
-- ---------------------------------------------------------------------

-- clamp a computed pixel size to Soda.parseCoordSize's safe integer
-- pixel range: sizes must land as integers >= MIN_PX or they get
-- silently reinterpreted as proportional (0 < v <= 1).
local function pxSize(v)
    v = math.floor(v)
    if v < Soda.Stack.MIN_PX then v = Soda.Stack.MIN_PX end
    return v
end

-- clamp a computed pixel position to an integer >= 0 (parseCoordSize
-- reads integer >=0 as pixels-from-edge; stacks only ever emit
-- near-edge positions, never the negative/far-edge form). Documented
-- degradation: an over-stuffed stack piles children at 0 rather than
-- failing -- see header caveat.
local function pxPos(v)
    v = math.floor(v)
    if v < 0 then v = 0 end
    return v
end

-- exposed so other tabs (eg Sugar's multi-row Segment, which computes
-- its own row heights/positions and needs the same integer-pixel-clamp
-- guarantee) have one implementation to depend on instead of a second
-- copy that could drift.
Soda.Stack.pxSize = pxSize
Soda.Stack.pxPos = pxPos


local function resolvePad(t)
    local pad = t.pad or 0
    return {
        left = t.padLeft or pad,
        right = t.padRight or pad,
        top = t.padTop or pad,
        bottom = t.padBottom or pad,
    }
end

-- run fn with a clean, untranslated matrix, then restore. Layout can run
-- lazily from draw(), which fires AFTER the parent Frame has already
-- issued translate(self:left(), self:bottom()); resizing a child there
-- recurses into orientationChanged -> mesh:setMesh (eg Soda.Shadow),
-- which does its own immediate setContext/pushMatrix/drawShape work
-- with no resetMatrix of its own and would otherwise bake the
-- accumulated translate into the mesh.
local function withCleanMatrix(fn)
    pushStyle()
    pushMatrix()
    resetMatrix()
    fn()
    popMatrix()
    popStyle()
end

-- ---------------------------------------------------------------------
-- Soda.Stack
-- ---------------------------------------------------------------------

function Soda.Stack:init(t)
    self.dir = t.dir or "v"
    self.gap = t.gap or 0
    self.justify = t.justify or "start"
    self.align = t.align or "fill"
    self.stackPad = resolvePad(t)
    self.stackDirty = true
    self.lastChildCount = 0
    Soda.Frame.init(self, t)
end

function Soda.VStack(t)
    local copy = {}
    for k, v in pairs(t) do copy[k] = v end
    copy.dir = "v"
    return Soda.Stack(copy)
end

function Soda.HStack(t)
    local copy = {}
    for k, v in pairs(t) do copy[k] = v end
    copy.dir = "h"
    return Soda.Stack(copy)
end

-- entry point (a): lazy layout from draw, then delegate to Frame:draw.
-- wrapped in withCleanMatrix -- see that function's comment. Also gated
-- on breakPoint == nil: a non-nil breakPoint means this draw call is
-- happening INSIDE a Soda.Blur rebake (Blur:rebake -> setContext(target)
-- -> drawing(breakPoint) -> Soda.draw recursing with that breakPoint),
-- which is itself inside an active setContext. Laying out there would
-- resize a child, recursing into Shadow:setMesh -> Gaussian:setImage,
-- whose closing bare setContext() would clear the blur's render target
-- and spill the rest of the bake onto the screen. The real (non-blur)
-- draw pass already laid this out; skip during a bake.
function Soda.Stack:draw(breakPoint)
    if breakPoint == nil and (self.stackDirty or #self.child ~= self.lastChildCount) then
        withCleanMatrix(function() self:layout() end)
    end
    return Soda.Frame.draw(self, breakPoint)
end

-- entry point (b): Frame's own orientationChanged first, then re-layout.
-- nested stacks work because this override IS a child stack's own
-- orientationChanged, invoked by its parent's layout() below. Not run
-- mid-draw (fired from the top-level sizeChanged sweep, before any
-- translate is on the matrix), so no withCleanMatrix wrap needed here.
function Soda.Stack:orientationChanged()
    self:setPosition()
    for _,v in ipairs(self.mesh) do v:setMesh() end
    self.stackDirty = true
    self:layout()
end

-- entry point (c): public, idempotent. Never calls self:orientationChanged()
-- -- recursion runs downward only (into children), never back up into self.
function Soda.Stack:layout()
    for i, child in ipairs(self.child) do
        if not child.stackSpec and not child.stackExclude then
            local p = child.parameters or {}
            child.stackSpec = {
                x = p.x, y = p.y, w = p.w, h = p.h,
                flex = p.flex, selfAlign = p.selfAlign,
            }
        end
    end
    
    local n = #self.child
    if n == 0 then
        self.stackDirty = false
        self.lastChildCount = 0
        return
    end
    
    local pad = self.stackPad
    local mainKey, crossKey, mainPos, crossPos, mainContentFull, crossContentFull
    if self.dir == "h" then
        mainKey, crossKey = "w", "h"
        mainPos, crossPos = "x", "y"
        mainContentFull = self.w - pad.left - pad.right
        crossContentFull = self.h - pad.top - pad.bottom
    else
        mainKey, crossKey = "h", "w"
        mainPos, crossPos = "y", "x"
        mainContentFull = self.h - pad.top - pad.bottom
        crossContentFull = self.w - pad.left - pad.right
    end
    
    local includedCount = 0
    for i, child in ipairs(self.child) do
        if not child.stackExclude then includedCount = includedCount + 1 end
    end
    local gapTotal = (includedCount > 1) and (self.gap * (includedCount - 1)) or 0
    local availMain = mainContentFull - gapTotal
    if availMain < 0 then availMain = 0 end
    
    local mode, mainSizePx, flexWeight = {}, {}, {}
    local pixelTotal, fractionTotal, flexWeightTotal = 0, 0, 0
    for i, child in ipairs(self.child) do
        if not child.stackExclude then
            local spec = child.stackSpec
            local v = spec[mainKey]
            if v == nil or spec.flex ~= nil then
                mode[i] = "flex"
                flexWeight[i] = spec.flex or 1
                flexWeightTotal = flexWeightTotal + flexWeight[i]
            elseif v > 1 then
                mode[i] = "px"
                mainSizePx[i] = v
                pixelTotal = pixelTotal + v
            elseif v > 0 then
                mode[i] = "frac"
                mainSizePx[i] = v * availMain
                fractionTotal = fractionTotal + mainSizePx[i]
            else
                mode[i] = "flex"
                flexWeight[i] = spec.flex or 1
                flexWeightTotal = flexWeightTotal + flexWeight[i]
            end
        end
    end
    
    local leftover = availMain - pixelTotal - fractionTotal
    if leftover < 0 then leftover = 0 end
    for i, child in ipairs(self.child) do
        if not child.stackExclude and mode[i] == "flex" then
            if flexWeightTotal > 0 then
                mainSizePx[i] = leftover * (flexWeight[i] / flexWeightTotal)
            else
                mainSizePx[i] = 0
            end
        end
    end
    local anyFlexible = flexWeightTotal > 0
    
    local crossSizePx = {}
    for i, child in ipairs(self.child) do
        if not child.stackExclude then
            local spec = child.stackSpec
            local a = spec.selfAlign or self.align
            if a == "fill" then
                crossSizePx[i] = crossContentFull
            else
                local cv = spec[crossKey]
                if cv == nil then
                    crossSizePx[i] = crossContentFull
                elseif cv > 1 then
                    crossSizePx[i] = cv
                elseif cv > 0 then
                    crossSizePx[i] = cv * crossContentFull
                else
                    crossSizePx[i] = crossContentFull
                end
            end
        end
    end
    
    local actualMain, actualCross = {}, {}
    for i, child in ipairs(self.child) do
        if not child.stackExclude then
            local wantMain = pxSize(mainSizePx[i])
            local wantCross = pxSize(crossSizePx[i])
            local p = child.parameters
            local sizeChanged = (p[mainKey] ~= wantMain) or (p[crossKey] ~= wantCross)
            p[mainKey] = wantMain
            p[crossKey] = wantCross
            if sizeChanged then
                child:orientationChanged()
            else
                child:setPosition()
            end 
            actualMain[i] = child[mainKey]
            actualCross[i] = child[crossKey]
        end
    end
    
    local actualMainTotal = 0
    for i, child in ipairs(self.child) do
        if not child.stackExclude then actualMainTotal = actualMainTotal + actualMain[i] end
    end
    local actualGapTotal = (includedCount > 1) and (self.gap * (includedCount - 1)) or 0
    local extra = mainContentFull - actualMainTotal - actualGapTotal
    if extra < 0 then extra = 0 end
    
    local cursor, stepGap = 0, self.gap
    if not anyFlexible then
        if self.justify == "center" then
            cursor = extra * 0.5
        elseif self.justify == "end" then
            cursor = extra
        elseif self.justify == "between" and includedCount > 1 then
            stepGap = self.gap + extra / (includedCount - 1)
        end
    end
    
    for i, child in ipairs(self.child) do
        if not child.stackExclude then
            local size = actualMain[i]
            local locMain
            if self.dir == "v" then
                locMain = pad.bottom + mainContentFull - cursor - size
            else
                locMain = pad.left + cursor
            end
            cursor = cursor + size + stepGap
            
            local spec = child.stackSpec
            local a = spec.selfAlign or self.align
            local cSize = actualCross[i]
            local crossNear = (self.dir == "v") and pad.left or pad.bottom
            local locCross
            if a == "center" then
                locCross = crossNear + (crossContentFull - cSize) * 0.5
            elseif a == "end" then
                locCross = crossNear + (crossContentFull - cSize)
            else
                locCross = crossNear
            end
            
            child.parameters[mainPos] = pxPos(locMain)
            child.parameters[crossPos] = pxPos(locCross)
            child:setPosition()
        end
    end
    
    self.stackDirty = false
    self.lastChildCount = n
end

-- ---------------------------------------------------------------------
-- Soda.Grid: uniform CELLS, reading order (left-to-right, top-to-bottom).
-- Not a Stack subclass -- cell geometry is derived purely from
-- cols/gaps/pad, never from a per-child declared size.
--
-- fit = "natural" (default): children keep their own size (eg fixed
-- 40x40 icon buttons, mixed-width text buttons). The child is not told
-- a size at all; its actual post-setPosition() w/h is read back and
-- centred (or start/end-aligned per cellAlign) within its cell on BOTH
-- axes. A child larger than its cell is not clamped -- it will overflow
-- into neighbouring cells; no detection is performed.
-- fit = "fill": force every child to the uniform cell size (old
-- behaviour) -- for content designed to stretch, eg Grid'd sliders.
--
-- fit = "natural" children MUST declare pixel sizes (w > 1, h > 1) or
-- none at all. Two cases are unsupported and will misbehave:
--   * Proportional sizes (0 < w <= 1): setPosition resolves these
--     against the GRID's own width/height, not the cell -- a w = 0.45
--     child lands at 45% of the whole grid, not 45% of its cell.
--   * Negative sizes: parseCoordSize resolves a negative size from the
--     child's own loc (len = edge - loc + size). Natural mode reads
--     w back, computes a new locX from it, then calls setPosition()
--     again, which recomputes w from the new loc -- size depends on
--     position depends on size, and the two passes do not converge.
-- Use fit = "fill" for anything that needs proportional or negative
-- sizing.
-- ---------------------------------------------------------------------

Soda.Grid = class(Soda.Frame)

function Soda.Grid:init(t)
    self.cols = t.cols or 1
    self.rowGap = t.rowGap or t.gap or 0
    self.colGap = t.colGap or t.gap or 0
    self.gridPad = resolvePad(t)
    self.fit = t.fit or "natural"
    self.cellAlign = t.cellAlign or "center"
    self.stackDirty = true
    self.lastChildCount = 0
    Soda.Frame.init(self, t)
end

-- same breakPoint guard as Soda.Stack:draw -- see that comment.
function Soda.Grid:draw(breakPoint)
    if breakPoint == nil and (self.stackDirty or #self.child ~= self.lastChildCount) then
        withCleanMatrix(function() self:layout() end)
    end
    return Soda.Frame.draw(self, breakPoint)
end

function Soda.Grid:orientationChanged()
    self:setPosition()
    for _,v in ipairs(self.mesh) do v:setMesh() end
    self.stackDirty = true
    self:layout()
end

-- position `size` within a `cellSize`-wide span starting at `origin`,
-- per cellAlign, along one axis.
local function gridCellOffset(cellAlign, origin, cellSize, size)
    if cellAlign == "start" then
        return origin
    elseif cellAlign == "end" then
        return origin + (cellSize - size)
    else -- "center"
        return origin + (cellSize - size) * 0.5
    end
end

function Soda.Grid:layout()
    local n = #self.child
    if n == 0 then
        self.stackDirty = false
        self.lastChildCount = 0
        return
    end
    
    local pad = self.gridPad
    local cols = math.max(1, self.cols)
    local rows = math.ceil(n / cols)
    local contentW = self.w - pad.left - pad.right
    local contentH = self.h - pad.top - pad.bottom
    local cellW = pxSize((contentW - self.colGap * (cols - 1)) / cols)
    local cellH = pxSize((contentH - self.rowGap * (rows - 1)) / rows)
    local topEdge = self.h - pad.top
    
    for i, child in ipairs(self.child) do
        local col = (i - 1) % cols
        local row = (i - 1) // cols -- 0 = top row, reading order
        local cellX = pad.left + col * (cellW + self.colGap)      -- cell's near (left) edge
        local cellY = topEdge - (row + 1) * cellH - row * self.rowGap -- cell's near (bottom) edge
        
        local p = child.parameters
        local childW, childH
        
        if self.fit == "fill" then
            local sizeChanged = (p.w ~= cellW) or (p.h ~= cellH)
            p.w, p.h = cellW, cellH
            if sizeChanged then child:orientationChanged() else child:setPosition() end
            childW, childH = cellW, cellH
        else -- "natural": don't touch w/h, just re-run setPosition and read back
            child:setPosition()
            childW, childH = child.w, child.h
        end
        
        local locX = gridCellOffset(self.cellAlign, cellX, cellW, childW)
        local locY = gridCellOffset(self.cellAlign, cellY, cellH, childH)
        child.parameters.x = pxPos(locX)
        child.parameters.y = pxPos(locY)
        child:setPosition()
    end
    
    self.stackDirty = false
    self.lastChildCount = n
end

-- ---------------------------------------------------------------------
-- Soda.Spacer: invisible flexible filler.
-- ---------------------------------------------------------------------

function Soda.Spacer(t)
    t = t or {}
    local copy = {}
    for k, v in pairs(t) do copy[k] = v end
    -- set explicitly rather than relying on Soda's default parameters.w/h
    -- (0.4/0.3) being silently absent from stackSpec's read of p.w/p.h --
    -- that absence is what currently makes a Spacer flexible, which is
    -- correct but non-obvious; flex is the actual intent, so say so.
    copy.flex = copy.flex or 1
    local spacer = Soda.Frame(copy)
    spacer.sensor.doNotInterceptTouches = true
    return spacer
end

