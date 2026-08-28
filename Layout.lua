-- device / orientation adaptive constants and helpers.
-- everything device-specific lives here so it can be tuned in one place.
-- values marked "guess" are conservative and unverified on device.

Layout = Layout or {}

-- boolean gate: minDim < this = phone. explicit gate, not a smooth curve,
-- so iPad geometry never drifts (a continuous scale would touch iPad Mini).
Layout.PHONE_MAX_DIM = 500

-- portrait phone safe-area insets. trimmed from 60/34 to 30/20 - that
-- budget was conservative to begin with, and phone-landscape no longer
-- reads insetTop/insetBottom at all (see overview()), so this is now a
-- portrait-only lever. frees ~2-3 lines of window height for the
-- sliders/dialogs "more room" asks below.
Layout.INSET_PORTRAIT_TOP = 30
Layout.INSET_PORTRAIT_BOTTOM = 20
Layout.INSET_PORTRAIT_SIDE = 0
Layout.INSET_LANDSCAPE_TOP = 0
Layout.INSET_LANDSCAPE_BOTTOM = 21
Layout.INSET_LANDSCAPE_SIDE = 50

-- FULLSCREEN mode's built-in collapse control, bottom-left. trimmed from
-- 30 to 16. landscape no longer reads this (window height there is set
-- by explicit LANDSCAPE_TOP/BOTTOM_GAP instead), so in practice this is
-- portrait-only now. still unverified on device.
Layout.VIEWER_BTN_CLEARANCE = 16

-- calculator chrome height (display + title margins) at s=70 on iPad,
-- ie 450 - 4*70. named so Demo can derive winH from s on any device.
Layout.CALC_CHROME_H = 170

-- padding added on each side of measured text to get a button width.
Layout.BTN_PAD = 16

-- landscape phone header budget, restored to round-1 sizes (34/34) after
-- round-2's 16/28 cut caused the title-vs-tab-row overlap seen on
-- device. GAP is now doubly used: it separates title from tab row AND
-- (via panelTop) separates the tab row from the content panel below it.
Layout.LANDSCAPE_TITLE_H = 34
Layout.LANDSCAPE_TAB_H = 34
Layout.LANDSCAPE_GAP = 10

-- landscape phone window position, replacing the old symmetric
-- LANDSCAPE_OUTER_MARGIN + inset-based height. these are literal,
-- asymmetric top/bottom gaps from the screen edge to the window edge -
-- dropping insetTop/insetBottom/VIEWER_BTN_CLEARANCE from the landscape
-- height calc entirely is what frees the ~40px windfall that pays for
-- the header restore above without shrinking content.
Layout.LANDSCAPE_TOP_GAP = 5
Layout.LANDSCAPE_BOTTOM_GAP = 10
-- side margin only (width calc still uses insetSide too); unchanged
-- from the prior round's outer margin, not part of this ask.
Layout.LANDSCAPE_SIDE_MARGIN = 6

-- portrait phone window's outer margin, trimmed from 20 to 10 (see the
-- inset trims above for the rest of the portrait height windfall).
Layout.PORTRAIT_OUTER_MARGIN = 10

-- recompute every setup() and every sizeChanged(). cheap, call freely.
function Layout.update()
    Layout.isPortrait = HEIGHT > WIDTH
    Layout.minDim = math.min(WIDTH, HEIGHT)
    Layout.isPhone = Layout.minDim < Layout.PHONE_MAX_DIM
    Layout.fontScale = Layout.isPhone and 0.8 or 1
    if Layout.isPhone then
        if Layout.isPortrait then
            Layout.insetTop = Layout.INSET_PORTRAIT_TOP
            Layout.insetBottom = Layout.INSET_PORTRAIT_BOTTOM
            Layout.insetSide = Layout.INSET_PORTRAIT_SIDE
        else
            Layout.insetTop = Layout.INSET_LANDSCAPE_TOP
            Layout.insetBottom = Layout.INSET_LANDSCAPE_BOTTOM
            Layout.insetSide = Layout.INSET_LANDSCAPE_SIDE
        end
        Layout.insetBottom = Layout.insetBottom + Layout.VIEWER_BTN_CLEARANCE
    else
        Layout.insetTop, Layout.insetBottom, Layout.insetSide = 0, 0, 0
    end
end

-- Soda.setup() unconditionally sets baseFontSize = 20, so call this AFTER
-- Soda.setup(), and again after any rebuild, and always before building or
-- repositioning any element (Frame:setPosition calls getTextSize on labels).
function Layout.applyFont()
    Soda.baseFontSize = 20 * Layout.fontScale
end

-- clamp a derived height/width so a RoundedRectangle with corner radius r
-- never collapses (landmine F). r defaults to 8, RoundedRectangle's default.
function Layout.clampDim(v, r)
    local minV = 2 * (r or 8) + 4
    if v < minV then return minV end
    return v
end

-- generic floor, eg guaranteeing TextScroll never gets a 0-or-negative
-- boxW (landmine E).
function Layout.clampMin(v, minV)
    if v < minV then return minV end
    return v
end

-- fixed slider pixel widths (300/400/500) overflow a 390pt-wide phone.
-- no-op on iPad (isPhone gate); on phone, cap to whatever fits minDim.
function Layout.sliderWidth(originalW)
    if not Layout.isPhone then return originalW end
    return math.min(originalW, Layout.minDim - 40)
end

-- measures str at the CURRENT Soda text style (same style Frame uses for
-- titles/content), honoring wrapW if given. only accurate once
-- Layout.applyFont() has already set Soda.baseFontSize for this frame -
-- measuring before that silently returns widths off by the font-scale
-- ratio (20/16 = 1.25x too wide on phone). always call after applyFont().
function Layout.measure(str, wrapW)
    pushStyle()
    Soda.setStyle(Soda.style.default.text)
    if wrapW then textWrapWidth(wrapW) end
    local w, h = textSize(str)
    textWrapWidth()
    popStyle()
    return w, h
end

-- candidates is an array of strings, longest/original first. returns the
-- first whose measured width fits maxW, or the last one if none fit.
-- call sites should pass the ORIGINAL iPad string as candidates[1] so this
-- degrades to phone-only shortening without needing a separate iPad path.
function Layout.fitText(candidates, maxW)
    for i, s in ipairs(candidates) do
        local w = Layout.measure(s)
        if w <= maxW then return s end
    end
    return candidates[#candidates]
end

-- measured text width + padding, clamped to [minW, maxW].
function Layout.buttonW(str, minW, maxW)
    local w = Layout.measure(str) + 2 * Layout.BTN_PAD
    if w < minW then w = minW end
    if maxW and w > maxW then w = maxW end
    return w
end

-- vertical strip reserved at the top of a titled panel for its caption.
-- no child of a titled panel should be positioned inside this band.
function Layout.titleBand()
    return Layout.isPhone and 26 or 30
end

-- floor for a single-row titled sub-panel holding one row of itemH-tall
-- children: title band + the item + 20px of real breathing room (10 above
-- the item, 10 below). earlier revision used +10 total with no slack,
-- which was mathematically "positive" but visually touched in real
-- rendering (see report). every floor below now carries real margin.
function Layout.rowFloor(itemH)
    return Layout.titleBand() + itemH + 20
end

-- replaces the old fixed "-110" content-panel top reserve. rows=1 (single
-- segment row, landscape orientation) reproduces 110 exactly - identical
-- to the pre-adaptation original in that case, EXCEPT on phone landscape,
-- which now uses the restored LANDSCAPE_* budget above (34+34+10=78 -
-- still tighter than iPad's 110 but no longer causes title/tab overlap).
-- rows=2 (portrait, ANY device including iPad) reserves the extra 50px
-- the second segment row actually needs: this is a genuine bug fix for
-- content bleeding under the second row, applied on every device since
-- the untouched rows=1 case already covers iPad landscape byte-for-byte.
function Layout.panelTop(rows)
    if Layout.isPhone and not Layout.isPortrait then
        return Layout.LANDSCAPE_TITLE_H + Layout.LANDSCAPE_TAB_H + Layout.LANDSCAPE_GAP
    end
    return 60 + rows * 40 + (rows - 1) * 10 + 10
end

-- how many fixed-height items (height itemH, gap between) fit in availH.
-- always returns at least 1. used to size sub-panels within a content
-- panel, and to size fixed-height children (switches, sliders...) within
-- one sub-panel, so a starved tab drops items instead of shrinking type
-- past the point of being usable.
function Layout.maxItems(availH, itemH, gap)
    local n = math.floor((availH + gap) / (itemH + gap))
    if n < 1 then n = 1 end
    return n
end

-- dialog geometry. phone-gated at every call site in Overview; iPad keeps
-- Soda.Alert/Alert2/Window's own w=0.4/h=0.25-0.3 defaults untouched.
function Layout.dialogW()
    return math.min(WIDTH - 40, 420)
end

function Layout.dialogH(content, w, buttonRowH)
    local cw, ch = Layout.measure(content, w * 0.9)
    buttonRowH = buttonRowH or 50
    local h = Layout.titleBand() + ch + buttonRowH + 20
    return Layout.clampMin(h, 140)
end
