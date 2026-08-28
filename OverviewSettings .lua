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
  -- dropdown isn't sitting right up against it.
  lS.dropdownStackPadTop = 12
  
  lS.dropdownPopupH = windowSettings.contentH
  
  local groupH = 40 -- just the dropdown itself, no label above it anymore
  lS.dropdownStackH = lS.dropdownStackPadTop + 2*groupH + 8  -- +8 gap between the two dropdowns
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