viewer.mode = FULLSCREEN
viewer.showWarnings = false
-- Use this as a template for your projects that have Soda as a dependency.

function setup()
    saveProjectInfo("Description", "Soda v"..Soda.version)
    profiler.init()
    parameter.watch("Soda.focus.title")
    local bgImage = readImage(asset.builtin.Cargo_Bot.Game_Area)
    -- change which of these is commented out to use standardized vs classic syntax
    Soda.setup(overview, bgImage)
    --Soda.setup(overviewClassic, bgImage)
end

function draw()
    Soda.appDraw()
    profiler.draw()
end

function touched(touch)
    if Soda.appTouched(touch) then return end
    --your touch code goes here
end

function keyboard(key)
    Soda.appKeyboard(key)
end

function sizeChanged(w, h)
    Soda.appSizeChanged(w, h)
end

--measure performance:

profiler={}

function profiler.init(quiet)
    profiler.del=0
    profiler.c=0
    profiler.fps=0
    profiler.mem=0
    if not quiet then
        parameter.watch("profiler.fps")
        parameter.watch("profiler.mem")
    end
end

function profiler.draw()
    profiler.del = profiler.del +  DeltaTime
    profiler.c = profiler.c + 1
    if profiler.c==10 then
        profiler.fps=profiler.c/profiler.del
        profiler.del=0
        profiler.c=0
        profiler.mem=collectgarbage("count", 2)
    end
end

