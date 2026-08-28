--# OverviewClassic
OverviewState = OverviewState or {}
OverviewState.selectedtTab = OverviewState.selectedtTab or 1

--all "local" assignments for the overview function at once, to make it easier to read
local wS, tabs, win, winStack, content
local aS, aboutTab, aboutSubPanel, demoSubPanel
local bS, buttonTab, buttonSubPanel, presetButtonGrid, textButtonsGrid, segmentStack, extrasRow
local swS, switchTab, switchRow, switchesPanel, switchContainer, switchStack1, switchStack2, switchStack3, togglesPanel, togglesStack
local slS, sliderTab, sliderTabColumns, sliderColumn1, sliderColumn2, sliderColumnSet, sliderStack1, sliderStack2, sliderStack3, sliderStack4
local dS, dialogTab, dSubPanel1, dSubPanel2, dSubPanel3, dSubPanels
local textEntryTab, scS, scrollTab
local lS, listsTab, dropdownStack, numberedListDropdown, plainListDropdown



-- overview
function overviewClassic()
    wS = winSettings()
    tabs = {}
    
    -- helpers
    if not calculatorPrepared then
        Soda.beforeRebuild = calculatorWasShown
        Soda.afterRebuild = restoreCalculatorIfShown
        calculatorPrepared = true
    end
    
    local function btnRowsNeeded(subH, itemH)
        local twoRowFloor = Layout.titleBand() + 2*itemH + 8 + 20
        return (subH >= twoRowFloor) and 2 or 1
    end
    
    local function showSegmented(i)
        OverviewState.selectedtTab = i
        for idx, p in ipairs(tabs) do
            if idx == i then p:show() else p:hide() end
        end
    end
    
    -- root window
    win = Soda.Window{
        x = wS.winX, y = wS.winY, w = wS.winW, h = wS.winH,
        title = "Soda v"..Soda.version.." Overview",
        styleAdd = wS.winStyleAdd,
        blurred = true,
        shadow = true,
        label = wS.winLabel,
    }
    
    -- root stack
    winStack = Soda.VStack{
        parent = win,
        x = 0, y = 0, w = 1, h = 1,
        padTop = wS.winStackPadTop,
        padLeft = 10,
        padRight = 10,
        gap = wS.winStackGap,
    }
    
    -- tab buttons 
    Soda.Segment{
        parent = winStack,
        h = wS.tabBarH,
        text = wS.segmentLabels,
        rows = wS.isPortrait and 2 or nil,
        rowGap = wS.isPortrait and 8 or nil,
        default = OverviewState.selectedtTab,
        callback = wS.isPortrait and function(subself, selected, title, globalIdx)
            if globalIdx then showSegmented(globalIdx, tabs) end
        end or function(self, selected)
            if selected and selected.idNo then showSegmented(selected.idNo, tabs) end
        end,
    }
    
    -- content frame
    content = Soda.Frame{
        parent = winStack,
        w = 1, h = wS.contentH,
    }
    
    ------------- Tab 1: About ---------------
    
    aS = aboutTabSettings(wS) 
    
    aboutTab = Soda.VStack{
        parent = content,
        x = 0, y = aS.panelInset, w = 1, h = -aS.panelInset,
        gap = 8,                           
        padBottom = aS.panelInset,     
    }
    
    aboutSubPanel = Soda.VStack{
        parent = aboutTab,
        x = 0, y = 0, w = 1,
        title = "About Soda",
        preset = "panel",
        justify = "center",
        padTop = Layout.titleBand(),
        gap = 5,
        styleAdd = {title = {fill = color(34, 94, 153)}},
    }
    
    Soda.Frame{
        parent = aboutSubPanel,
        w = 1, h = "auto",
        content = "Soda is a library for producing graphic user "..
        "interfaces like the one you are looking at now. Press the "..
        "segment buttons above to see the interface elements Soda "..
        "produces.",
    }
    
    Soda.Button{
        parent = aboutSubPanel,
        w = Layout.buttonW("Online Documentation", 140, 280), h = 40,
        title = "Online Documentation",
        selfAlign = "center",
        callback = function() openURL("https://github.com/Utsira/Soda/blob/master/README.md", true) end,
    }
    
    demoSubPanel = Soda.VStack{
        parent = aboutTab,
        x = 0, y = 0, w = 1, h = aS.demoH,
        title = "Demos",
        preset = "panel",
        justify = "center",
        padTop = Layout.titleBand(),
    }
    
    Soda.Button{
        parent = demoSubPanel,
        w = Layout.buttonW("Calculator", 120, 220), h = 40,
        title = "Calculator",
        selfAlign = "center",
        callback = function() calculator.window:show(RIGHT) end,
    }
    
    tabs[1] = aboutTab
    
    ------------- Tab 2: Buttons -------------
    
    bS = buttonTabSettings(wS) 
    
    buttonTab = Soda.VStack{
        parent = content,
        x = 0, y = bS.panelInset, w = 1, h = -bS.panelInset,
        gap = bS.bGap,
        padBottom = bS.panelInset + 4,   -- consistent bottom padding
    }
    
    -- Main sub-panel containing all button types
    buttonSubPanel = Soda.VStack{
        parent = buttonTab,
        x = 0, y = 0, w = 1,
        title = "Various styled and predefined buttons",
        preset = "panel",
        padTop = Layout.titleBand() + (Layout.isPortrait and bS.bGap or 0),
        padBottom = Layout.isPortrait and 0 or bS.bGap,
        gap = bS.bGap,
    }
    
    -- 1. Preset icon buttons (1/3 of the sub-panel)
    presetButtonGrid = Soda.Grid{
        parent = buttonSubPanel,
        h = 1/3,
        cols = math.ceil(10 / btnRowsNeeded(buttonSubPanel.h / 3, 40)),
    }
    
    Soda.BackButton{
        parent = presetButtonGrid,
        subStyle = {"darkIcon"},
    }
    
    Soda.ForwardButton{
        parent = presetButtonGrid,
        subStyle = {"darkIcon"},
    }
    
    Soda.SettingsButton{
        parent = presetButtonGrid,
        subStyle = {"darkIcon"},
        label = {x=0.5,y=0.56},
    }
    
    Soda.AddButton{
        parent = presetButtonGrid,
        subStyle = {"icon"},
    }
    
    Soda.QueryButton{
        parent = presetButtonGrid,
        subStyle = {"icon"},
    }
    
    Soda.MenuButton{
        parent = presetButtonGrid,
        subStyle = {"icon"},
    }
    
    Soda.DropdownButton{
        parent = presetButtonGrid,
    }
    
    Soda.CloseButton{
        parent = presetButtonGrid,
    }
    
    Soda.DeleteButton{
        parent = presetButtonGrid,
        w = 40, h = 40,
        subStyle = {"icon"},
        styleAdd = {icon = {text = {fontSize = 2.5}}},
    }
    
    Soda.Button{
        parent = presetButtonGrid,
        w = 40, h = 40,
        title = "i",
        shape = Soda.ellipse,
        style = {
            shape = {noFill=true,strokeWidth=1,stroke="blue"},
            text = {fill="blue"},
            highlight = {shape = {fill="blue",noStroke=true}, text = {fill="blue"}},
        },
    }
    
    -- 2. Styled text buttons (1/3 of the sub-panel)
    textButtonsGrid = Soda.Grid{
        parent = buttonSubPanel,
        h = 1/3,
        cols = math.ceil(6 / btnRowsNeeded(buttonSubPanel.h / 3, 40)),
    }
    
    -- Standard
    Soda.Button{
        parent = textButtonsGrid,
        w = bS.textButtonW, h = 40,
        title = "Standard",
    }
    
    -- Warning
    Soda.Button{
        parent = textButtonsGrid,
        w = bS.textButtonW, h = 40,
        title = "Warning",
        subStyle = {"warning"},
    }
    
    -- Square
    Soda.Button{
        parent = textButtonsGrid,
        w = bS.textButtonW, h = 40,
        title = "Square",
        shape = Soda.rect,
    }
    
    -- Lozenge
    Soda.Button{
        parent = textButtonsGrid,
        w = bS.textButtonW, h = 40,
        title = "Lozenge",
        shapeArgs = {radius = 20},
    }
    
    -- Globe icon (ellipse)
    Soda.Button{
        parent = textButtonsGrid,
        w = 40, h = 40,
        title = "\u{1f310}",
        shape = Soda.ellipse,
        style = {
            shape = {fill="white",stroke="lightGrey",strokeWidth=2},
            text = {fill="white"},
            highlight = {shape = {fill="blue",noStroke=true}, text = {fill="blue"}},
        },
    }
    
    -- Fork & knife icon
    Soda.Button{
        parent = textButtonsGrid,
        w = 40, h = 40,
        title = "\u{1f374}",
        style = {
            shape = {fill="white",stroke="lightGrey",strokeWidth=4},
            text = {fill="white"},
            highlight = {shape = {fill="blue",noStroke=true}, text = {fill="blue"}},
        },
    }
    
    -- 3. Segmented buttons (1/3 of the sub-panel)
    segmentStack = Soda.VStack{
        parent = buttonSubPanel,
        h = 1/3,
        justify = "center",
        padLeft = 20,
        padRight = 20,
    }
    
    Soda.Segment{
        parent = segmentStack,
        h = bS.segmentedH,
        text = {"Only one","segmented","button can","be selected","at a time"},
        rows = Layout.isPortrait and 2 or nil,
        rowGap = Layout.isPortrait and 8 or nil,
    }
    
    -- 4. Custom and specialty buttons (separate panel below)
    
    extrasRow = Soda.HStack{
        parent = buttonTab,
        h = bS.extrasH,
        title = bS.extrasTitle,
        preset = "panel",
        justify = "center",
        gap = bS.extrasSidePad,
        padLeft = bS.extrasSidePad,
        padRight = bS.extrasSidePad,
        padTop = bS.extrasTopPad,
    }
    
    Soda.Button{
        parent = extrasRow,
        w = bS.extrasItemSize, h = bS.extrasItemSize,
        title = "Image",
        shapeArgs = { tex = asset.builtin.Surfaces.Stone_Brick_Color },
        style = {
            shape = {fill = "white"},
            text = {fill = "white", fontSize = 0.85},
            highlight = {shape = {fill = "white"}, text = {fill = color(255, 210, 90)}},
        },
        selfAlign = "center",
    }
    
    Soda.Frame{
        parent = extrasRow,
        w = bS.extrasLabelW, h = bS.extrasItemSize,
        content = "Custom and\nspecialty\nbuttons",
        selfAlign = "center",
        hidden = Layout.isPortrait
    }
    
    Soda.ColorWheel{
        parent = extrasRow,
        w = bS.extrasItemSize, h = bS.extrasItemSize,
        selfAlign = "center",
    }
    
    tabs[2] = buttonTab
    
    ------ Tab 3: Switches / Toggles ---------
    
    swS = switchTabSettings(wS)
    
    switchTab = Soda.Frame{
        parent = content,
        x = 0, y = swS.panelInset, w = 1, h = -swS.panelInset,
    }
    
    switchRow = Soda.HStack{
        parent = switchTab,
        x = 0, y = 0, w = 1, h = 1,
        gap = swS.switchRowGap,
        padTop = swS.switchRowPadTop,
        padBottom = swS.switchRowPadBottom,
    }
    
    -- Switches panel
    switchesPanel = Soda.Frame{
        parent = switchRow,
        title = "iOS-style switches",
        preset = "panel",
    }
    
    -- Container for all switch items
    switchContainer = Soda.VStack{
        parent = switchesPanel,
        x = 0, y = 0, w = 1, h = 1,
        gap = swS.switchGap,
        justify = "center",
        padTop = swS.switchPadTop,
        padLeft = swS.switchPadSide,
        padRight = swS.switchPadSide,
    }
    
    -- Switch 1
    switchStack1 = Soda.VStack{
        parent = switchContainer,
        h = swS.switchItemH,
        title = swS.captionHidden and "" or "Use switches\nto toggle",
        label = swS.containerLabel,
        justify = swS.containerJustify,
        gap = 2,
    }
    Soda.Switch{
        parent = switchStack1,
        title = swS.captionHidden and "Use switches to toggle" or "",
        on = false,
        selfAlign = "start",
    }
    
    -- Switch 2
    switchStack2 = Soda.VStack{
        parent = switchContainer,
        h = swS.switchItemH,
        title = swS.captionHidden and "" or "...between\ntwo states",
        label = swS.containerLabel,
        justify = swS.containerJustify,
        gap = 2,
    }
    Soda.Switch{
        parent = switchStack2,
        title = swS.captionHidden and "...between two states" or "",
        on = true,
        selfAlign = "start",
    }
    
    -- Switch 3
    switchStack3 = Soda.VStack{
        parent = switchContainer,
        h = swS.switchItemH,
        title = swS.captionHidden and "" or "...on and off",
        label = swS.containerLabel,
        justify = swS.containerJustify,
        gap = 2,
    }
    Soda.Switch{
        parent = switchStack3,
        title = swS.captionHidden and "...on and off" or "",
        on = false,
        selfAlign = "start",
    }
    
    -- Toggles panel
    togglesPanel = Soda.Frame{
        parent = switchRow,
        title = swS.togglesTitle,
        preset = "panel",
    }
    
    togglesStack = Soda.VStack{
        parent = togglesPanel,
        x = 0, y = 0, w = 1, h = 1,
        gap = swS.toggleGap,
        justify = "center",
        padTop = swS.togglePadTop,
        padLeft = swS.togglePadSide,
        padRight = swS.togglePadSide,
    }
    
    Soda.Toggle{
        parent = togglesStack,
        h = 40,
        title = "Standard",
    }
    
    Soda.Toggle{
        parent = togglesStack,
        h = 40,
        title = "Square",
        shape = Soda.rect,
    }
    
    Soda.Toggle{
        parent = togglesStack,
        h = 40,
        title = "Over-rounded",
        shapeArgs = {radius = 20},
    }
    
    Soda.MenuToggle{
        parent = togglesStack,
        on = true,
        selfAlign = "center",
    }
    
    tabs[3] = switchTab
    
    -------------- Tab4: Sliders -------------
    
    slS = sliderTabSettings(wS)
    
    sliderTab = Soda.VStack{
        parent = content,
        x = 0, y = wS.panelInset, w = 1, h = -wS.panelInset,
        title = slS.panelTitle,
        preset = "panel",
        padTop = slS.panelPadTop,
    }
    
    sliderTabColumns = Soda.HStack{
        parent = sliderTab,
        gap = slS.colGap,
    }
    
    sliderColumn1 = Soda.VStack{
        parent = sliderTabColumns,
        w = slS.sliderColumn1W,
        justify = "center",
        gap = slS.interCellGap,
    }
    
    sliderColumn2 = Soda.VStack{
        parent = sliderTabColumns,
        w = slS.sliderColumn2W,
        justify = "center",
        gap = slS.interCellGap,
        hidden = slS.sliderColumn2Hidden,
    }
    
    sliderColumnSet = {sliderColumn1, sliderColumn2}
    
    sliderStack1 = Soda.VStack{
        parent = sliderColumnSet[slS.sliderStack1ColIdx],
        h = slS.sliderStack1H,
        title = slS.cap1Title,
        padTop = slS.cap1H,
        justify = "center",
    }
    
    Soda.Slider{
        parent = sliderStack1,
        w = slS.slider1W, h = 60,
        title = "",
        min = 1000,
        max = 2000,
        start = 1500,
        selfAlign = "center",
    }
    
    sliderStack2 = Soda.VStack{
        parent = sliderColumnSet[slS.sliderStack2ColIdx],
        h = slS.sliderStack2H,
        title = slS.cap2Title,
        padTop = slS.cap2H,
        justify = "center",
        hidden = slS.slider2Hidden,
    }
    
    Soda.Slider{
        parent = sliderStack2,
        w = slS.slider2W, h = 60,
        title = "",
        min = -10,
        max = 10,
        start = 0,
        decimalPlaces = 3,
        selfAlign = "center",
    }
    
    sliderStack3 = Soda.VStack{
        parent = sliderColumnSet[slS.sliderStack3ColIdx],
        h = slS.sliderStack3H,
        title = slS.cap3Title,
        padTop = slS.cap3H,
        justify = "center",
        hidden = slS.slider3Hidden,
    }
    
    Soda.Slider{
        parent = sliderStack3,
        w = slS.slider3W, h = 60,
        title = "",
        min = -50,
        max = 150,
        decimalPlaces = 1,
        snapPoints = {0, 100},
        selfAlign = "center",
    }
    
    sliderStack4 = Soda.VStack{
        parent = sliderColumnSet[slS.sliderStack4ColIdx],
        h = slS.sliderStack4H,
        title = slS.cap4Title,
        padTop = slS.cap4H,
        justify = "center",
        hidden = slS.slider4Hidden,
    }
    
    Soda.Slider{
        parent = sliderStack4,
        w = slS.slider4W, h = 60,
        title = "",
        min = -10000,
        max = 10000,
        start = 0,
        snapPoints = {0},
        selfAlign = "center",
    }
    
    tabs[4] = sliderTab
    
    ------------- Tab 5: Dialogs -------------
    
    dS = dialogTabSettings(wS)
    
    dialogTab = Soda.VStack{
        parent = content,
        x = 0, y = wS.panelInset, w = 1, h = -wS.panelInset,
        gap = dS.dGap,
    }
    
    dSubPanel1 = Soda.HStack{
        parent = dialogTab,
        h = dS.dSubPanel1H,
        title = dS.dSubPanel1Title,
        preset = "panel",
        align = "center",
        padTop = dS.dSubPanel1PadTop,
        gap = dS.rowGap,
        padLeft = dS.rowPadLeft,
        padRight = dS.rowPadRight,
        justify = dS.rowJustify,
    }
    
    dSubPanel2 = Soda.HStack{
        parent = dialogTab,
        h = dS.dSubPanel2H,
        title = dS.dSubPanel2Title,
        preset = "panel",
        align = "center",
        padTop = dS.dSubPanel2PadTop,
        gap = dS.rowGap,
        padLeft = dS.rowPadLeft,
        padRight = dS.rowPadRight,
        justify = dS.rowJustify,
    }
    
    dSubPanel3 = Soda.HStack{
        parent = dialogTab,
        h = dS.dSubPanel3H,
        title = dS.dSubPanel3Title,
        preset = "panel",
        align = "center",
        padTop = dS.dSubPanel3PadTop,
        gap = dS.rowGap,
        padLeft = dS.rowPadLeft,
        padRight = dS.rowPadRight,
        justify = dS.rowJustify,
        hidden = dS.dSubPanel3Hidden,
    }
    
    
    dSubPanels = {dSubPanel1, dSubPanel2, dSubPanel3}
    
    Soda.Button{
        parent = dSubPanels[dS.proceedPaneIdx],
        w = dS.btnW, h = 40,
        title = "Proceed dialog",
        callback = function()
            local content = "A 2-button\nProceed or cancel dialog"
            local w = Layout.isPhone and Layout.dialogW() or nil
            Soda.Alert2{
                title = "Alert",
                content = content,
                w = w,
                h = w and Layout.dialogH(content, w) or nil,
            }
        end,
    }
    
    Soda.Button{
        parent = dSubPanels[dS.alertPaneIdx],
        w = dS.btnW, h = 40,
        title = "Alert",
        subStyle = {"warning"},
        callback = function()
            local content = "A one-button\nalert"
            local w = Layout.isPhone and Layout.dialogW() or nil
            Soda.Alert{
                title = "Alert",
                content = content,
                y = Layout.isPhone and 0.5 or 0.6,
                w = w,
                h = w and Layout.dialogH(content, w) or 0.3,
            }
        end,
    }
    
    Soda.Button{
        parent = dSubPanels[dS.windowPaneIdx],
        w = dS.btnW, h = 40,
        title = "Window",
        callback = function()
            local content = "A regular window with optional ok, cancel, and close buttons and optional drop-shadow"
            local w = Layout.isPhone and Layout.dialogW() or nil
            Soda.Window{
                title = "Window",
                content = content,
                ok = true,
                cancel = true,
                close = true,
                shadow = true,
                callback = function() return true end,
                w = w,
                h = w and Layout.dialogH(content, w) or nil,
            }
        end,
    }
    
    Soda.Button{
        parent = dSubPanels[dS.proceedBlurredPaneIdx],
        w = dS.btnW, h = 40,
        title = "Proceed (blurred)",
        callback = function()
            local content = "A 2-button\nProceed or cancel dialog"
            local w = Layout.isPhone and Layout.dialogW() or nil
            Soda.Alert2{
                title = "Alert",
                content = content,
                blurred = true,
                w = w,
                h = w and Layout.dialogH(content, w) or nil,
                styleAdd = Layout.isPhone and wS.winStyleAdd or nil,
            }
        end,
    }
    
    Soda.Button{
        parent = dSubPanels[dS.alertBlurredPaneIdx],
        w = dS.btnW, h = 40,
        title = "Alert (blurred)",
        subStyle = {"warning"},
        callback = function()
            local content = "A one-button\nalert"
            local w = Layout.isPhone and Layout.dialogW() or nil
            Soda.Alert{
                title = "Alert",
                content = content,
                blurred = true,
                y = Layout.isPhone and 0.5 or 0.6,
                w = w,
                h = w and Layout.dialogH(content, w) or 0.3,
                styleAdd = Layout.isPhone and wS.winStyleAdd or nil,
            }
        end,
    }
    
    Soda.Button{
        parent = dSubPanels[dS.blurredWindowPaneIdx],
        w = dS.btnW, h = 40,
        title = "Window (blurred)",
        callback = function()
            local content = "A blurred window with ok, cancel, and close buttons"
            local w = Layout.isPhone and Layout.dialogW() or nil
            Soda.Window{
                title = "Blurred Window",
                content = content,
                blurred = true,
                ok = true,
                cancel = true,
                close = true,
                callback = function() return true end,
                w = w,
                h = w and Layout.dialogH(content, w) or nil,
                styleAdd = Layout.isPhone and wS.winStyleAdd or nil,
            }
        end,
    }
    
    tabs[5] = dialogTab
    
    --------- Tab 6: Text Entry --------------
    
    textEntryTab = Soda.VStack{
        parent = content,
        x = 0, y = wS.panelInset, w = 1, h = -wS.panelInset,
        title = "Text Entry fields with a draggable cursor",
        preset = "panel",
        gap = 40,
        justify = "center",
        padTop = Layout.titleBand(),
        padLeft = 10,
        padRight = 10,
    }
    
    Soda.TextEntry{
        parent = textEntryTab,
        h = 40,
        title = "Text Entry:",
        default = "Tap here to start editing this text",
    }
    
    Soda.TextEntry{
        parent = textEntryTab,
        h = 40,
        title = "Text Entry:",
        default = "Double-tap a word to select it and open the selection menu",
    }
    
    Soda.TextEntry{
        parent = textEntryTab,
        h = 40,
        title = "Text Entry:",
        default = "Scroll the text left and right by pulling the cursor over to either end of the box and holding your finger there. Also, note that the interface scrolls up if the text entry box is below the height of the keyboard.",
    }
    
    tabs[6] = textEntryTab
    
    ------------ Tab 7: Lists  ---------------
    
    lS = listsTabSettings(wS)
    
    listsTab = Soda.HStack{
        parent = content,
        x = 0, y = wS.panelInset, w = 1, h = -wS.panelInset,
        title = lS.panelTitle,
        preset = "panel",
        gap = 20,
        padTop = Layout.titleBand(),
        padLeft = 10,
        padRight = 10,
        padBottom = 10,
    }
    
    Soda.List{
        parent = listsTab,
        w = 0.5, h = lS.listH,
        text = {"Lists", "allow", "the", "user", "to", "select", "one", "option", "from", "a", "vertically", "scrolling", "list."},
        selfAlign = "center",
    }
    
    dropdownStack = Soda.VStack{
        parent = listsTab,
        h = lS.dropdownStackH,
        gap = 8,
        justify = "start",
        padTop = lS.dropdownStackPadTop,
    }
    
    plainListDropdown = Soda.DropdownList{
        parent = dropdownStack,
        h = 40,
        title = "A dropdown list",
        text = {"Dropdown", "lists", "are", "lists", "that", "dropdown", "from", "a", "button.", "Note", "that", "the", "button", "reports", "the", "selection", "made"},
        popupH = lS.dropdownPopupH,
    }
    
    numberedListDropdown = Soda.DropdownList{
        parent = dropdownStack,
        h = 40,
        title = "A numbered list",
        text = {"Lists", "and", "dropdown lists", "can", "be", "automatically", "enumerated", "if", "you", "wish"},
        enumerate = true,
        popupH = lS.dropdownPopupH,
    }
    
    tabs[7] = listsTab
    
    ------------ Tab 8: Scrolls --------------
    
    scS = scrollTabSettings(wS)
    
    scrollTab = Soda.Frame{
        parent = content,
        x = 0, y = wS.panelInset, w = 1, h = -wS.panelInset,
        title = scS.panelTitle,
        content = "",
        preset = "panel",
    }
    
    Soda.TextScroll{
        parent = scrollTab,
        x = 0, y = 0, w = 1, h = scS.innerH,
        textBody = string.rep([[
        
        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus vitae massa in sem mattis ullamcorper a eget metus. Nam ac maximus nulla, vel faucibus sapien. Aenean faucibus volutpat tristique. Curabitur condimentum volutpat velit, sit amet commodo tellus placerat a.
        
        Sed vitae metus quis mauris congue tincidunt vel sit amet lorem. Mauris lectus lorem, facilisis in dapibus et, congue quis nunc. Fusce convallis mi urna, vitae mattis felis sodales et. Aliquam et fringilla purus, eu vehicula diam. Sed facilisis mauris vitae augue sodales aliquam. In ultrices metus ut eleifend condimentum. Praesent venenatis rhoncus felis, eget vehicula orci ornare non. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Vivamus eget vulputate mauris. Pellentesque id tempus sapien.
        ]], 100),
    }
    
    tabs[8] = scrollTab
    
    showSegmented(OverviewState.selectedtTab, tabs)
    
    calculator.init()
end

-- -----------------------------------------------------------------
-- Helper functions
-- -----------------------------------------------------------------

local function calculatorWasShown()
    return calculator.window and not calculator.window.hidden
end

local function restoreCalculatorIfShown(wasShown)
    if wasShown and calculator.window then
        calculator.window:show()
    end
end
