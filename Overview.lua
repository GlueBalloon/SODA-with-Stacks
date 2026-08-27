OverviewState = OverviewState or {}
OverviewState.selectedtTab = OverviewState.selectedtTab or 1

-- "local" assignments for the overview function, all at once, so that the structure of the Soda elements is easier to read
local wS, tabs, win, winStack, content
local aS, aboutTab, aboutSubPanel, demoSubPanel
local bS, buttonTab, buttonSubPanel, presetButtonGrid, textButtonsGrid, segmentStack, extrasRow
local swS, switchTab, switchRow, switchesPanel, switchContainer, switchStack1, switchStack2, switchStack3, togglesPanel, togglesStack
local slS, sliderTab, sliderTabColumns, sliderColumn1, sliderColumn2, sliderColumnSet, sliderStack1, sliderStack2, sliderStack3, sliderStack4
local dS, dialogTab, dSubPanel1, dSubPanel2, dSubPanel3, dSubPanels
local textEntryTab, scS, scrollTab
local lS, listsTab, dropdownStack, numberedListLabel, numberedListDropdown, plainListLabel, plainListDropdown

-- overview
function overview()
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
    nil,
    {wS.winX, wS.winY, wS.winW, wS.winH},
    title = "Soda v"..Soda.version.." Overview",
    styleAdd = wS.winStyleAdd,
    blurred = true,
    shadow = true,
    label = wS.winLabel,
  }

  -- root stack
  winStack = Soda.VStack{
    win,
    {0, 0, 1, 1},
    padTop = wS.winStackPadTop,
    padLeft = 10,
    padRight = 10,
    gap = wS.winStackGap,
  }

  -- tab buttons 
  Soda.Segment{
    winStack,
    {nil, nil, nil, wS.tabBarH},
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
    winStack,
    {nil, nil, 1, wS.contentH},
  }

  ------------- Tab 1: About ---------------
  
  aS = aboutTabSettings(wS) 
  
  aboutTab = Soda.VStack{
    content,
    {0, aS.panelInset, 1, -aS.panelInset},
    gap = 8,                           
    padBottom = aS.panelInset,     
  }
  
  aboutSubPanel = Soda.VStack{
    aboutTab,
    {0, 0, 1, nil},
    title = "About Soda",
    preset = "panel",
    justify = "center",
    padTop = Layout.titleBand(),
    gap = 5,
    styleAdd = {title = {fill = color(34, 94, 153)}},
  }
  
  Soda.Frame{
    aboutSubPanel,
    {nil, nil, 1, "auto"},
    content = "Soda is a library for producing graphic user "..
    "interfaces like the one you are looking at now. Press the "..
    "segment buttons above to see the interface elements Soda "..
    "produces.",
  }
  
  Soda.Button{
    aboutSubPanel,
    {nil, nil, Layout.buttonW("Online Documentation", 140, 280), 40},
    title = "Online Documentation",
    selfAlign = "center",
    callback = function() openURL("https://github.com/Utsira/Soda/blob/master/README.md", true) end,
  }
  
  demoSubPanel = Soda.VStack{
    aboutTab,
    {0, 0, 1, aS.demoH},
    title = "Demos",
    preset = "panel",
    justify = "center",
    padTop = Layout.titleBand(),
  }
  
  Soda.Button{
    demoSubPanel,
    {nil, nil, Layout.buttonW("Calculator", 120, 220), 40},
    title = "Calculator",
    selfAlign = "center",
    callback = function() calculator.window:show(RIGHT) end,
  }
  
  tabs[1] = aboutTab

  ------------- Tab 2: Buttons -------------

  bS = buttonTabSettings(wS) 
  
  buttonTab = Soda.VStack{
    content,
    {0, bS.panelInset, 1, -bS.panelInset},
    gap = bS.bGap,
    padBottom = bS.panelInset + 4,   -- consistent bottom padding
  }
  
  -- Main sub-panel containing all button types
  buttonSubPanel = Soda.VStack{
    buttonTab,
    {0, 0, 1, nil},
    title = "Various styled and predefined buttons",
    preset = "panel",
    padTop = Layout.titleBand() + (Layout.isPortrait and bS.bGap or 0),
    padBottom = Layout.isPortrait and 0 or bS.bGap,
    gap = bS.bGap,
  }
  
  -- 1. Preset icon buttons (1/3 of the sub-panel)
  presetButtonGrid = Soda.Grid{
    buttonSubPanel,
    {nil, nil, nil, 1/3},
    cols = math.ceil(10 / btnRowsNeeded(buttonSubPanel.h / 3, 40)),
  }
  
  Soda.BackButton{
    presetButtonGrid,
    nil,
    subStyle = {"darkIcon"},
  }
  
  Soda.ForwardButton{
    presetButtonGrid,
    nil,
    subStyle = {"darkIcon"},
  }
  
  Soda.SettingsButton{
    presetButtonGrid,
    nil,
    subStyle = {"darkIcon"},
    label = {x=0.5,y=0.56},
  }
  
  Soda.AddButton{
    presetButtonGrid,
    nil,
    subStyle = {"icon"},
  }
  
  Soda.QueryButton{
    presetButtonGrid,
    nil,
    subStyle = {"icon"},
  }
  
  Soda.MenuButton{
    presetButtonGrid,
    nil,
    subStyle = {"icon"},
  }
  
  Soda.DropdownButton{
    presetButtonGrid,
    nil,
  }
  
  Soda.CloseButton{
    presetButtonGrid,
    nil,
  }
  
  Soda.DeleteButton{
    presetButtonGrid,
    {nil, nil, 40, 40},
    subStyle = {"icon"},
    styleAdd = {icon = {text = {fontSize = 2.5}}},
  }
  
  Soda.Button{
    presetButtonGrid,
    {nil, nil, 40, 40},
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
    buttonSubPanel,
    {nil, nil, nil, 1/3},
    cols = math.ceil(6 / btnRowsNeeded(buttonSubPanel.h / 3, 40)),
  }
  
  -- Standard
  Soda.Button{
    textButtonsGrid,
    {nil, nil, bS.textButtonW, 40},
    title = "Standard",
  }
  
  -- Warning
  Soda.Button{
    textButtonsGrid,
    {nil, nil, bS.textButtonW, 40},
    title = "Warning",
    subStyle = {"warning"},
  }
  
  -- Square
  Soda.Button{
    textButtonsGrid,
    {nil, nil, bS.textButtonW, 40},
    title = "Square",
    shape = Soda.rect,
  }
  
  -- Lozenge
  Soda.Button{
    textButtonsGrid,
    {nil, nil, bS.textButtonW, 40},
    title = "Lozenge",
    shapeArgs = {radius = 20},
  }
  
  -- Globe icon (ellipse)
  Soda.Button{
    textButtonsGrid,
    {nil, nil, 40, 40},
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
    textButtonsGrid,
    {nil, nil, 40, 40},
    title = "\u{1f374}",
    style = {
      shape = {fill="white",stroke="lightGrey",strokeWidth=4},
      text = {fill="white"},
      highlight = {shape = {fill="blue",noStroke=true}, text = {fill="blue"}},
    },
  }
    
  -- 3. Segmented buttons (1/3 of the sub-panel)
  segmentStack = Soda.VStack{
    buttonSubPanel,
    {nil, nil, nil, 1/3},
    justify = "center",
    padLeft = 20,
    padRight = 20,
  }
  
  Soda.Segment{
    segmentStack,
    {nil, nil, nil, bS.segmentedH},
    text = {"Only one","segmented","button can","be selected","at a time"},
    rows = Layout.isPortrait and 2 or nil,
    rowGap = Layout.isPortrait and 8 or nil,
  }
  
  -- 4. Custom and specialty buttons (separate panel below)
    
  extrasRow = Soda.HStack{
    buttonTab,
    {nil, nil, nil, bS.extrasH},
    title = bS.extrasTitle,
    preset = "panel",
    justify = "center",
    gap = bS.extrasSidePad,
    padLeft = bS.extrasSidePad,
    padRight = bS.extrasSidePad,
    padTop = bS.extrasTopPad,
  }
  
  Soda.Button{
    extrasRow,
    {nil, nil, bS.extrasItemSize, bS.extrasItemSize},
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
    extrasRow,
    {nil, nil, bS.extrasLabelW, bS.extrasItemSize},
    content = "Custom and\nspecialty\nbuttons",
    selfAlign = "center",
    hidden = Layout.isPortrait
  }
  
  Soda.ColorWheel{
    extrasRow,
    {nil, nil, bS.extrasItemSize, bS.extrasItemSize},
    selfAlign = "center",
  }
  
  tabs[2] = buttonTab
  
  ------ Tab 3: Switches / Toggles ---------
  
  swS = switchTabSettings(wS)
  
  switchTab = Soda.Frame{
    content,
    {0, swS.panelInset, 1, -swS.panelInset},
  }
  
  switchRow = Soda.HStack{
    switchTab,
    {0, 0, 1, 1},
    gap = swS.switchRowGap,
    padTop = swS.switchRowPadTop,
    padBottom = swS.switchRowPadBottom,
  }
  
  -- Switches panel
  switchesPanel = Soda.Frame{
    switchRow,
    {nil, nil, nil, nil},
    title = "iOS-style switches",
    preset = "panel",
  }
  
  -- Container for all switch items
  switchContainer = Soda.VStack{
    switchesPanel,
    {0, 0, 1, 1},
    gap = swS.switchGap,
    justify = "center",
    padTop = swS.switchPadTop,
    padLeft = swS.switchPadSide,
    padRight = swS.switchPadSide,
  }
  
  -- Switch 1
  switchStack1 = Soda.VStack{
    switchContainer,
    {nil, nil, nil, swS.switchItemH},
    title = swS.captionHidden and "" or "Use switches\nto toggle",
    label = swS.containerLabel,
    justify = swS.containerJustify,
    gap = 2,
  }
  Soda.Switch{
    switchStack1,
    nil,
    title = swS.captionHidden and "Use switches to toggle" or "",
    on = false,
    selfAlign = "start",
  }
  
  -- Switch 2
  switchStack2 = Soda.VStack{
    switchContainer,
    {nil, nil, nil, swS.switchItemH},
    title = swS.captionHidden and "" or "...between\ntwo states",
    label = swS.containerLabel,
    justify = swS.containerJustify,
    gap = 2,
  }
  Soda.Switch{
    switchStack2,
    nil,
    title = swS.captionHidden and "...between two states" or "",
    on = true,
    selfAlign = "start",
  }
  
  -- Switch 3
  switchStack3 = Soda.VStack{
    switchContainer,
    {nil, nil, nil, swS.switchItemH},
    title = swS.captionHidden and "" or "...on and off",
    label = swS.containerLabel,
    justify = swS.containerJustify,
    gap = 2,
  }
  Soda.Switch{
    switchStack3,
    nil,
    title = swS.captionHidden and "...on and off" or "",
    on = false,
    selfAlign = "start",
  }
  
  -- Toggles panel
  togglesPanel = Soda.Frame{
    switchRow,
    {nil, nil, nil, nil},
    title = swS.togglesTitle,
    preset = "panel",
  }
  
  togglesStack = Soda.VStack{
    togglesPanel,
    {0, 0, 1, 1},
    gap = swS.toggleGap,
    justify = "center",
    padTop = swS.togglePadTop,
    padLeft = swS.togglePadSide,
    padRight = swS.togglePadSide,
  }
  
  Soda.Toggle{
    togglesStack,
    {nil, nil, nil, 40},
    title = "Standard",
  }
  
  Soda.Toggle{
    togglesStack,
    {nil, nil, nil, 40},
    title = "Square",
    shape = Soda.rect,
  }
  
  Soda.Toggle{
    togglesStack,
    {nil, nil, nil, 40},
    title = "Over-rounded",
    shapeArgs = {radius = 20},
  }
  
  Soda.MenuToggle{
    togglesStack,
    nil,
    on = true,
    selfAlign = "center",
  }
  
  tabs[3] = switchTab

  -------------- Tab4: Sliders -------------

  slS = sliderTabSettings(wS)
  
  sliderTab = Soda.VStack{
    content,
    {0, wS.panelInset, 1, -wS.panelInset},
    title = slS.panelTitle,
    preset = "panel",
    padTop = slS.panelPadTop,
  }
  
  sliderTabColumns = Soda.HStack{
    sliderTab,
    {nil, nil, nil, nil},
    gap = slS.colGap,
  }
  
  sliderColumn1 = Soda.VStack{
    sliderTabColumns,
    {nil, nil, slS.sliderColumn1W, nil},
    justify = "center",
    gap = slS.interCellGap,
  }
  
  sliderColumn2 = Soda.VStack{
    sliderTabColumns,
    {nil, nil, slS.sliderColumn2W, nil},
    justify = "center",
    gap = slS.interCellGap,
    hidden = slS.sliderColumn2Hidden,
  }
  
  sliderColumnSet = {sliderColumn1, sliderColumn2}
  
  sliderStack1 = Soda.VStack{
    sliderColumnSet[slS.sliderStack1ColIdx],
    {nil, nil, nil, slS.sliderStack1H},
    title = slS.cap1Title,
    padTop = slS.cap1H,
    justify = "center",
  }
    
  Soda.Slider{
    sliderStack1,
    {nil, nil, slS.slider1W, 60},
    title = "",
    min = 1000,
    max = 2000,
    start = 1500,
    selfAlign = "center",
  }
  
  sliderStack2 = Soda.VStack{
    sliderColumnSet[slS.sliderStack2ColIdx],
    {nil, nil, nil, slS.sliderStack2H},
    title = slS.cap2Title,
    padTop = slS.cap2H,
    justify = "center",
    hidden = slS.slider2Hidden,
  }
  
  Soda.Slider{
    sliderStack2,
    {nil, nil, slS.slider2W, 60},
    title = "",
    min = -10,
    max = 10,
    start = 0,
    decimalPlaces = 3,
    selfAlign = "center",
  }
  
  sliderStack3 = Soda.VStack{
    sliderColumnSet[slS.sliderStack3ColIdx],
    {nil, nil, nil, slS.sliderStack3H},
    title = slS.cap3Title,
    padTop = slS.cap3H,
    justify = "center",
    hidden = slS.slider3Hidden,
  }
  
  Soda.Slider{
    sliderStack3,
    {nil, nil, slS.slider3W, 60},
    title = "",
    min = -50,
    max = 150,
    decimalPlaces = 1,
    snapPoints = {0, 100},
    selfAlign = "center",
  }
  
  sliderStack4 = Soda.VStack{
    sliderColumnSet[slS.sliderStack4ColIdx],
    {nil, nil, nil, slS.sliderStack4H},
    title = slS.cap4Title,
    padTop = slS.cap4H,
    justify = "center",
    hidden = slS.slider4Hidden,
  }
  
  Soda.Slider{
    sliderStack4,
    {nil, nil, slS.slider4W, 60},
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
    content,
    {0, wS.panelInset, 1, -wS.panelInset},
    gap = dS.dGap,
  }
  
  dSubPanel1 = Soda.HStack{
    dialogTab,
    {nil, nil, nil, dS.dSubPanel1H},
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
    dialogTab,
    {nil, nil, nil, dS.dSubPanel2H},
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
    dialogTab,
    {nil, nil, nil, dS.dSubPanel3H},
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
    dSubPanels[dS.proceedPaneIdx],
    {nil, nil, dS.btnW, 40},
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
    dSubPanels[dS.alertPaneIdx],
    {nil, nil, dS.btnW, 40},
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
    dSubPanels[dS.windowPaneIdx],
    {nil, nil, dS.btnW, 40},
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
    dSubPanels[dS.proceedBlurredPaneIdx],
    {nil, nil, dS.btnW, 40},
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
    dSubPanels[dS.alertBlurredPaneIdx],
    {nil, nil, dS.btnW, 40},
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
    dSubPanels[dS.blurredWindowPaneIdx],
    {nil, nil, dS.btnW, 40},
    title = "Blurred Window",
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
      }
    end,
  }
  
  tabs[5] = dialogTab

  --------- Tab 6: Text Entry --------------
  
  textEntryTab = Soda.VStack{
    content,
    {0, wS.panelInset, 1, -wS.panelInset},
    title = "Text Entry fields with a draggable cursor",
    preset = "panel",
    gap = 40,
    justify = "center",
    padTop = Layout.titleBand(),
    padLeft = 10,
    padRight = 10,
  }
  
  Soda.TextEntry{
    textEntryTab,
    {nil, nil, nil, 40},
    title = "Text Entry:",
    default = "Tap here to start editing this text",
  }
  
  Soda.TextEntry{
    textEntryTab,
    {nil, nil, nil, 40},
    title = "Text Entry:",
    default = "Double-tap a word to select it and open the selection menu",
  }
  
  Soda.TextEntry{
    textEntryTab,
    {nil, nil, nil, 40},
    title = "Text Entry:",
    default = "Scroll the text left and right by pulling the cursor over to either end of the box and holding your finger there. Also, note that the interface scrolls up if the text entry box is below the height of the keyboard.",
  }
  
  tabs[6] = textEntryTab
  
  ------------ Tab 7: Lists  ---------------

  lS = listsTabSettings(wS)
  
  listsTab = Soda.HStack{
    content,
    {0, wS.panelInset, 1, -wS.panelInset},
    title = lS.panelTitle,
    preset = "panel",
    gap = 20,
    padTop = Layout.titleBand(),
    padLeft = 10,
    padRight = 10,
    padBottom = 10,
  }
  
  Soda.List{
    listsTab,
    {nil, nil, 0.5, lS.listH},
    text = {"Lists", "allow", "the", "user", "to", "select", "one", "option", "from", "a", "vertically", "scrolling", "list."},
    selfAlign = "center",
  }
  
  dropdownStack = Soda.VStack{
    listsTab,
    {nil, nil, nil, lS.dropdownStackH},
    gap = 8,
    justify = "center",
    padTop = lS.dropdownStackPadTop,
  }
  
  numberedListLabel = Soda.Frame{
    dropdownStack,
    {nil, nil, nil, 24},
    content = "(no selection)",
  }
  
  numberedListDropdown = Soda.DropdownList{
    dropdownStack,
    {nil, nil, nil, 40},
    title = "A numbered list",
    text = {"Lists", "and", "dropdown lists", "can", "be", "automatically", "enumerated", "if", "you", "wish"},
    enumerate = true,
    popupH = lS.dropdownPopupH,
    callback = function(this, selected, txt)
      numberedListLabel.content = "\""..txt.."\""
    end,
  }
  
  plainListLabel = Soda.Frame{
    dropdownStack,
    {nil, nil, nil, 24},
    content = "(no selection)",
  }
  
  plainListDropdown = Soda.DropdownList{
    dropdownStack,
    {nil, nil, nil, 40},
    title = "A dropdown list",
    text = {"Dropdown", "lists", "are", "lists", "that", "dropdown", "from", "a", "button.", "Note", "that", "the", "button", "reports", "the", "selection", "made"},
    popupH = lS.dropdownPopupH,
    callback = function(this, selected, txt)
      plainListLabel.content = "\""..txt.."\""
    end,
  }
  
  tabs[7] = listsTab
  
  ------------ Tab 8: Scrolls --------------

  scS = scrollTabSettings(wS)
  
  scrollTab = Soda.Frame{
    content,
    {0, wS.panelInset, 1, -wS.panelInset},
    title = scS.panelTitle,
    content = "",
    preset = "panel",
  }
  
  Soda.TextScroll{
    scrollTab,
    {0, 0, 1, scS.innerH},
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

function winSettings()
  local winSet = {}
  
  winSet.segmentLabels = {
    "About", "Buttons", "Switches", "Sliders",
    "Dialogs", "Text Entry", "Lists", "Scrolls"
  }
  
  winSet.winStyleAdd = Layout.isPhone and {
    text = {fill = "white", font = "HelveticaNeue-Light", fontSize = 1},
    textBox = {font = "Inconsolata", fill = "white", fontSize = 1},
    translucent = {
      shape = {fill = "darkTrans", stroke = "grey"},
      text = {},
      title = {fill = color(169, 207, 223)},
    },
  } or nil
  
  if Layout.isPhone and Layout.isPortrait then
    winSet.winX = 0.5
    winSet.winY = 0.5
    winSet.winW = Layout.clampMin(WIDTH - 2*Layout.insetSide - Layout.PORTRAIT_OUTER_MARGIN, 220)
    winSet.winH = Layout.clampMin(HEIGHT - Layout.insetTop - Layout.insetBottom - Layout.PORTRAIT_OUTER_MARGIN, 300)
    winSet.winLabel = nil
    winSet.winStackPadTop = 55
    winSet.tabBarH = 90
    winSet.winStackGap = 4
    winSet.panelInset = 4
    winSet.isPortrait = true
    
  elseif Layout.isPhone and not Layout.isPortrait then
    winSet.winX = 0.5
    winSet.winY = Layout.LANDSCAPE_BOTTOM_GAP
    winSet.winW = Layout.clampMin(WIDTH - 2*Layout.insetSide - Layout.LANDSCAPE_SIDE_MARGIN, 220)
    winSet.winH = Layout.clampMin(HEIGHT - Layout.LANDSCAPE_TOP_GAP - Layout.LANDSCAPE_BOTTOM_GAP, 300)
    winSet.winLabel = {x = 0.5, y = -8}
    winSet.winStackPadTop = Layout.LANDSCAPE_TITLE_H
    winSet.tabBarH = Layout.LANDSCAPE_TAB_H
    winSet.winStackGap = 4
    winSet.panelInset = 4
    winSet.isPortrait = false
    
  else -- iPad
    winSet.winX = nil
    winSet.winY = nil
    winSet.winW = 0.97
    winSet.winH = 0.7
    winSet.winLabel = nil
    winSet.winStackPadTop = 60
    winSet.tabBarH = 40
    winSet.winStackGap = 4
    winSet.panelInset = 10
    winSet.isPortrait = false
  end
  
  winSet.contentH = winSet.winH - winSet.winStackPadTop - winSet.tabBarH - winSet.winStackGap
  
  return winSet
end

function aboutTabSettings(windowSettings)
  local aS = {}
  aS.demoH = Layout.titleBand() + 40 + (Layout.isPhone and not Layout.isPortrait and 30 or 45)
  aS.panelInset = windowSettings.panelInset
  return aS
end

function buttonTabSettings(windowSettings)
  local bS = {}
  bS.panelInset = windowSettings.panelInset
  bS.bGap = 8
  bS.extraItemH = Layout.isPortrait and 114 or 56
  bS.extrasH = Layout.rowFloor(bS.extraItemH)
  bS.segmentedH = Layout.isPortrait and 88 or 40
  bS.extrasTitle = Layout.isPortrait and  {"Custom and specialty buttons", "Custom buttons"} or nil
  bS.extrasSidePad = 10 
  bS.extrasTopPad = Layout.isPortrait and Layout.titleBand() or 0
  bS.extrasItemSize = bS.extrasH - bS.extrasTopPad - 2*bS.extrasSidePad
  bS.extrasLabelW = Layout.isPortrait and 0 or 0.6
  bS.textButtonW = math.max(Layout.buttonW("Standard",50,160), Layout.buttonW("Warning",50,160),
  Layout.buttonW("Square",50,160), Layout.buttonW("Lozenge",50,160))
  return bS
end

function switchTabSettings(windowSettings)
  local swS = {}
  swS.panelInset = windowSettings.panelInset
  
  swS.switchRowGap = 10
  swS.switchRowPadTop = 10
  swS.switchRowPadBottom = 10
  
  swS.switchPadTop = Layout.titleBand()
  swS.switchPadSide = 20
  swS.switchGap = 8
  
  local isPortraitPhone = Layout.isPhone and Layout.isPortrait
  local capH = 55
  local swH = 40
  local gapInside = 2
  
  swS.captionHidden = not isPortraitPhone
  
  if isPortraitPhone then
    swS.switchItemH = capH + swH + gapInside
    -- Increase the +2 to +8 for more gap between caption and switch
    swS.containerLabel = {x = 10, y = -swS.switchItemH/2 + capH/2 + 14}
    swS.containerJustify = "end"
  else
    swS.switchItemH = swH
    swS.containerLabel = nil
    swS.containerJustify = "center"
  end
  
  swS.togglesTitle = Layout.isPhone and "Text and preset-based\ntoggles" or "Text and preset-based toggles"
  swS.togglePadTop = Layout.titleBand()
  swS.togglePadSide = 20
  swS.toggleGap = 8
  
  return swS
end

function sliderTabSettings(windowSettings)
  local slS = {}
  
  slS.panelTitle = Layout.isPhone
  and "Sliders. At slow slide speeds\nmovement becomes more fine-grained"
  or "Sliders. At slow slide speeds movement becomes more fine-grained"
  
  slS.panelPadTop = Layout.isPhone and (Layout.titleBand() + 20) or Layout.titleBand()
  
  local sliderH = 60
  local cap4TitleWrapped = "Make fine +/- adjustments\nby tapping either side of the lever"
  
  if Layout.isPhone and not Layout.isPortrait then
    slS.colGap = 20
    slS.interCellGap = 14
    slS.sliderColumn1W = 0.5
    slS.sliderColumn2W = 0.5
    slS.sliderColumn2Hidden = false
    slS.sliderStack1ColIdx = 1
    slS.sliderStack2ColIdx = 1
    slS.sliderStack3ColIdx = 2
    slS.sliderStack4ColIdx = 2
    
    slS.cap1H = 34
    slS.cap2H = 34
    slS.cap3H = 34
    slS.cap4H = 34
    
    slS.cap1Title = "Integer slider"
    slS.cap2Title = "Floating point slider (3 decimal places)"
    slS.cap3Title = "Slider with snap points"
    slS.cap4Title = cap4TitleWrapped
    
    slS.slider1W = 0.9
    slS.slider2W = 0.9
    slS.slider3W = 0.9
    slS.slider4W = 0.9
    
    slS.slider2Hidden = false
    slS.slider3Hidden = false
    slS.slider4Hidden = false
    
    slS.sliderStack1H = slS.cap1H + sliderH
    slS.sliderStack2H = slS.cap2H + sliderH
    slS.sliderStack3H = slS.cap3H + sliderH
    slS.sliderStack4H = slS.cap4H + sliderH
    
  else
    slS.colGap = 0
    slS.interCellGap = 10
    slS.sliderColumn1W = 1
    slS.sliderColumn2W = 0
    slS.sliderColumn2Hidden = true
    slS.sliderStack1ColIdx = 1
    slS.sliderStack2ColIdx = 1
    slS.sliderStack3ColIdx = 1
    slS.sliderStack4ColIdx = 1
    
    slS.cap1H = 30
    slS.cap2H = 30
    slS.cap3H = 30
    slS.cap4H = 74
    
    slS.cap1Title = "Integer slider"
    slS.cap2Title = "Floating point slider (3 decimal places)"
    slS.cap3Title = "Slider with snap points"
    slS.cap4Title = cap4TitleWrapped
    
    if Layout.isPhone then
      slS.slider1W = Layout.sliderWidth(300)
      slS.slider2W = Layout.sliderWidth(300)
      slS.slider3W = Layout.sliderWidth(300)
      slS.slider4W = Layout.sliderWidth(300)
      
      local sliderStack1H = slS.cap1H + sliderH
      local sliderStack2H = slS.cap2H + sliderH
      local sliderStack3H = slS.cap3H + sliderH
      local sliderStack4H = slS.cap4H + sliderH
      local cellHeights = {sliderStack1H, sliderStack2H, sliderStack3H, sliderStack4H}
      
      local availH = windowSettings.contentH - 2 * windowSettings.panelInset - slS.panelPadTop
      local nSliders = 4
      local total = sliderStack1H + sliderStack2H + sliderStack3H + sliderStack4H + 3 * slS.interCellGap
      while nSliders > 1 and total > availH do
        total = total - cellHeights[nSliders] - slS.interCellGap
        nSliders = nSliders - 1
      end
      
      slS.slider2Hidden = nSliders < 2
      slS.slider3Hidden = nSliders < 3
      slS.slider4Hidden = nSliders < 4
      
      slS.sliderStack1H = sliderStack1H
      slS.sliderStack2H = slS.slider2Hidden and 0 or sliderStack2H
      slS.sliderStack3H = slS.slider3Hidden and 0 or sliderStack3H
      slS.sliderStack4H = slS.slider4Hidden and 0 or sliderStack4H
      
    else
      slS.slider1W = 300
      slS.slider2W = 400
      slS.slider3W = 500
      slS.slider4W = 0.9
      
      slS.slider2Hidden = false
      slS.slider3Hidden = false
      slS.slider4Hidden = false
      
      slS.sliderStack1H = slS.cap1H + sliderH
      slS.sliderStack2H = slS.cap2H + sliderH
      slS.sliderStack3H = slS.cap3H + sliderH
      slS.sliderStack4H = slS.cap4H + sliderH
    end
  end
  
  return slS
end

function dialogTabSettings(windowSettings)
  local dS = {}
  local isLandscapePhone = Layout.isPhone and not Layout.isPortrait
  
  dS.dGap = 10
  dS.dSubPanel3Hidden = isLandscapePhone
  
  if isLandscapePhone then
    dS.btnW = 1/3
    dS.rowGap = 12
    dS.rowPadLeft = 12
    dS.rowPadRight = 12
    dS.rowJustify = nil
    dS.dSubPanel1H = 0.5
    dS.dSubPanel2H = 0.5
    dS.dSubPanel3H = 0
    
    dS.dSubPanel1Title = {"Press the buttons to trigger alerts in the default style", "Default style"}
    dS.dSubPanel2Title = {"Press the buttons to trigger alerts with dark, blurred panels", "Blurred styles"}
    dS.dSubPanel3Title = nil
    
    dS.dSubPanel1PadTop = Layout.titleBand()
    dS.dSubPanel2PadTop = Layout.titleBand()
    dS.dSubPanel3PadTop = Layout.titleBand()
    
    dS.proceedPaneIdx = 1
    dS.alertPaneIdx = 1
    dS.windowPaneIdx = 1
    dS.proceedBlurredPaneIdx = 2
    dS.alertBlurredPaneIdx = 2
    dS.blurredWindowPaneIdx = 2
    
  else
    dS.rowGap = nil
    dS.rowPadLeft = 10
    dS.rowPadRight = 10
    dS.rowJustify = "between"
    dS.dSubPanel1H = nil
    dS.dSubPanel2H = nil
    dS.dSubPanel3H = nil
    
    if Layout.isPortrait then
      dS.dSubPanel1Title = "Press the buttons to trigger alerts\nin the default style"
      dS.dSubPanel2Title = "Press the buttons to trigger alerts\nwith dark, blurred panels"
      dS.dSubPanel1PadTop = Layout.titleBand() + 20
      dS.dSubPanel2PadTop = Layout.titleBand() + 20
    else
      dS.dSubPanel1Title = "Press the buttons to trigger alerts in the default style"
      dS.dSubPanel2Title = "Press the buttons to trigger alerts with dark, blurred panels"
      dS.dSubPanel1PadTop = Layout.titleBand()
      dS.dSubPanel2PadTop = Layout.titleBand()
    end
    dS.dSubPanel3Title = "Press the buttons to see the window presets"
    dS.dSubPanel3PadTop = Layout.titleBand()
    
    if Layout.isPhone then
      dS.btnW = math.max(Layout.buttonW("Proceed dialog",110,240), Layout.buttonW("Blurred Window",110,240))
    else
      dS.btnW = 0.4
    end
    
    dS.proceedPaneIdx = 1
    dS.alertPaneIdx = 1
    dS.windowPaneIdx = 3
    dS.proceedBlurredPaneIdx = 2
    dS.alertBlurredPaneIdx = 2
    dS.blurredWindowPaneIdx = 3
  end
  
  return dS
end

function listsTabSettings(windowSettings)
  local lS = {}
  
  lS.panelTitle = Layout.isPhone
  and {"Vertically scrolling lists are another way of selecting one choice from many", "Scrolling lists"}
  or "Vertically scrolling lists are another way of selecting one choice from many"
  
  -- 9th word is "from" -- cap the list's visible height there so it
  -- demonstrates scrolling rather than just showing everything at once.
  local maxVisibleH = 11 * 40
  local availH = windowSettings.contentH - 2 * windowSettings.panelInset - Layout.titleBand() - 50
  lS.listH = math.min(maxVisibleH, availH)
  
  -- pushes the dropdown group down from the title band so the first
  -- "(no selection)" text isn't sitting right up against it.
  lS.dropdownStackPadTop = 12
  
  lS.dropdownPopupH = windowSettings.contentH
  
  local groupH = 24 + 8 + 40  -- label + gap + dropdown
  lS.dropdownStackH = lS.dropdownStackPadTop + 2*groupH + 8  -- +8 gap between the two groups
  return lS
end

function scrollTabSettings(windowSettings)
  local scS = {}
  local titleLines
  if Layout.isPhone then
    scS.panelTitle = "Text Scrolls for scrolling through\nlarge bodies of text"
    titleLines = 2
  else
    scS.panelTitle = "Text Scrolls for scrolling through large bodies of text"
    titleLines = 1
  end
  scS.innerH = -(Layout.titleBand() * titleLines + 4)
  return scS
end



