--# calculator
--# Demo
-- calculator demo. demo1() (the old panel/menu showcase) was dead code,
-- never called from setup() or overview() - removed rather than adapted,
-- since adapting unreachable code has no runtime effect either way.
calculator = {}
function calculator.init()
    -- landmine K fix: s (button size) drives window w/h, instead of the
    -- window being hardcoded to 350x450. on iPad s=70 => 350x450,
    -- byte-identical to before. on phone, s shrinks to fit the screen.
    local s = Layout.isPhone and math.max(30, math.floor(Layout.minDim/9)) or 70
    local winW = s*5
    local winH = s*4 + Layout.CALC_CHROME_H
    
    calculator.window = Soda.Window{
        title = "Calculator",
        x = -10, y = 10, w = winW, h = winH,
        close = true,
        blurred = true,
        shadow = true,
        hidden = true,
        doNotKill = true,
        draggable = true
    }
    local result = true
    
    local display = Soda.Frame{
        parent = calculator.window,
        x = 0, y = -50, w = 1, h = 120,
        label = {x = -5, y = 0},
        title = "0",
        shape = Soda.rect,
        style = {shape = {fill = color(200, 230, 255, 160)}, text = {fontSize = 2, font = "HelveticaNeue", fill = color(59, 240), textWrapWidth = 340, textAlign = RIGHT}}
    }
    
    local history = Soda.Frame{
        parent = display,
        x = 0, y = -0.001, w = 1, h = 30,
        label = {x = -5, y = 0},
        title = "",
        style = {shape = {}, text = {fontSize = 0.9, font = "HelveticaNeue", fill = color(59, 240), textWrapWidth = 340}}
    }
    
    -- digitPress replaces the old onPress(sender) shared handler. onPress
    -- relied on Soda's self-first callback convention (sender = the button
    -- that fired) to disambiguate which of the 14 digit/operator buttons was
    -- pressed. Now that Frame:init strips self before forwarding to user
    -- callbacks, that identity is no longer available as a parameter -- so
    -- each button gets its own tiny closure over its own key instead of
    -- asking "who called me" at runtime.
    local function digitPress(inkey)
        return function()
            if inkey:find("%d") then
                if display.title == "0" or result then
                    display.title = inkey
                    result = false
                else
                    display.title = display.title..inkey
                end
                
            elseif inkey == "." then
                if not result and display.title:find("%d$") and not display.title:find("%.%d-$") then
                    result = false
                    display.title = display.title..inkey
                end
                
            else
                if display.title ~= "0" and display.title:find("%d$") then
                    result = false
                    display.title = display.title..inkey
                end
            end
            display:setPosition()
        end
    end
    
    local buttonStyle2 = {
        shape = {fill = color(255, 180, 0, 200)},
        text = {fill = "white", fontSize = 1.5},
        highlight = {
            shape = {fill = "white", stroke = color(255, 180, 0)},
            text = {fill = color(255, 180, 0), fontSize = 1.5}
        }
    }
    
    Soda.Button{
        parent = calculator.window,
        w = s*2, h = s,
        x = 0, y = 0,
        title = "0",
        subStyle = {"icon"},
        shapeArgs = {radius = 25, corners = 1},
        callback = digitPress("0")
    }
    
    Soda.Button{
        parent = calculator.window,
        w = s, h = s,
        x = s*2, y = 0,
        title = ".",
        subStyle = {"icon"},
        shapeArgs = {corners = 0},
        callback = digitPress(".")
    }
    
    for n = 0,8 do
        local digit = tostring(n+1)
        Soda.Button{
            parent = calculator.window,
            w = s, h = s,
            x = s * (n%3), y = s * (1 + n//3),
            title = digit,
            subStyle = {"icon"},
            shapeArgs = {corners = 0},
            callback = digitPress(digit)
        }
    end
    local buttons = {"\u{00F7}", "\u{00D7}", "-", "+"}
    
    for n = 0,3 do
        local op = buttons[n+1]
        Soda.Button{
            parent = calculator.window,
            w = s, h = s,
            x = s * 3, y = s * n,
            title = op,
            style = buttonStyle2,
            shapeArgs = {corners = 0},
            callback = digitPress(op)
        }
    end
    
    --backspace
    Soda.Button{
        parent = calculator.window,
        w = s, h = s,
        x = s * 4, y = s * 3,
        title = "\u{232B}",
        shapeArgs = {corners = 0},
        callback = function()
            if display.title:find("[\u{00F7}\u{00D7}]$") then
                display.title = display.title:gsub("\u{00F7}$", ""):gsub("\u{00D7}$", "")
            else
                display.title = display.title:sub(1,-2)
            end
            if display.title == "" then display.title = "0" end
            display:setPosition()
        end
    }
    
    Soda.Button{
        parent = calculator.window,
        w = s, h = s,
        x = s * 4, y = s * 2,
        title = "AC",
        shapeArgs = {corners = 0},
        callback = function()
            display.title = "0"
            display:setPosition()
        end
    }
    
    Soda.Button{
        parent = calculator.window,
        w = s, h = s * 2,
        x = s * 4, y = 0,
        title = "=",
        style = buttonStyle2,
        shapeArgs = {radius = 25, corners = 8},
        callback = function()
            if display.title:find("%d$") then
                history.title = display.title.."="
                history:setPosition()
                local out = load("return "..display.title:gsub("\u{00D7}", "*"):gsub("\u{00F7}", "/"))()
                if out%1 == 0 then out = math.tointeger(out) end
                display.title = tostring(out)
                display:setPosition()
                result = true
            end
        end
    }
end
