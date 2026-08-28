--# Blur
Soda.Gaussian = class() --a component for nice effects like shadows and blur
--Gaussian blur
--adapted by Yojimbo2000 from http://xissburg.com/faster-gaussian-blur-in-glsl/ 

function Soda.Gaussian:setImage()
    local p = self.parent
    
    local ww,hh = p.w * self.falloff, p.h * self.falloff
    self.ww, self.hh = ww,hh
    
    local d = math.max(ww, hh)
    local blurRad = smoothstep(d, math.max(WIDTH, HEIGHT)*1.5, 60) * 1.5
    local aspect = vec2(d/ww, d/hh) * blurRad
    
    local downSample = 0.25 
    
    local dimensions = vec2(ww, hh) * downSample
    
    local blurTex = {}
    local blurMesh = {}
    for i=1,2 do
        blurTex[i]=image(dimensions.x, dimensions.y)
        local m = mesh()
        m.texture=blurTex[i]
        m:addRect(dimensions.x/2, dimensions.y/2,dimensions.x, dimensions.y)
        m.shader=shader(Soda.Gaussian.shader.vert[i], Soda.Gaussian.shader.frag)
        m.shader.am = aspect
        blurMesh[i] = m
    end
    local imgOut = image(dimensions.x, dimensions.y)
    pushStyle()
    pushMatrix()
    setContext(blurTex[1])
    
    scale(downSample)
    
    self:drawImage()
    popMatrix()
    popStyle()   
    
    setContext(blurTex[2])
    blurMesh[1]:draw() --pass one
    setContext(imgOut)
    blurMesh[2]:draw() --pass two, to output
    setContext()
    
    return imgOut
end

function Soda.Gaussian:draw()
    local p = self.parent
    self.mesh:setRect(1, p.x + self.off, p.y - self.off, self.ww, self.hh)
    self.mesh:draw()
end

---------------------------------------------------------------------------

-- Soda.Blur: a translucent "frosted glass" effect showing a blurred
-- snapshot of everything below the element it's attached to.
--
-- unlike the original element-sized, bake-once version, this bakes a
-- single WIDTH x HEIGHT blur of "everything below" (same breakpoint
-- mechanism as before, via the host project's drawing() function) and
-- then crops a window out of it via RoundedRectangle's texCoord param.
-- moving the owning element (eg. a draggable Soda.Window) therefore
-- costs nothing but a crop reposition every frame - no rebake needed,
-- exactly like re-aiming a window at an already-painted wall.
--
-- a rebake IS needed whenever something belonging to the actual
-- composite below the element changes - Soda has no generic way to know
-- what that is, so (mirroring the same "simplest correct rule, per
-- KISS" used by the reference BlurLayers implementation) any show/hide/
-- orientation change invalidates every live blur, and dragging a
-- top-level element invalidates every blur stacked above it.
Soda.Blur = class()

Soda.Blur.active = {} -- registry of every live Soda.Blur, for invalidation

function Soda.Blur:init(t)
    self.parent = t.parent
    self.downSample = t.downSample or 0.25
    self.dirty = true
    table.insert(Soda.Blur.active, self)
    -- deliberately NOT baking here. rebake() draws the whole element tree,
    -- and during construction that tree has no Stack layout yet (nil x/y
    -- resolves to centred) -- plus nested ScrollShape/Gaussian setContext()
    -- calls inside the bake reset the target to the screen mid-bake, so a
    -- construction-time bake paints a centred, un-laid-out frame straight
    -- onto the framebuffer. First draw() bakes instead, by which point
    -- layout has run.
end

-- called by Soda.destroyElement (Soda.lua) when the Frame that owns this
-- Blur is killed and about to be dropped from its parent's child list --
-- removes this instance from the append-only Soda.Blur.active registry,
-- which otherwise has no way to shrink and leaks one entry per blurred
-- element ever destroyed over the app's lifetime.
function Soda.Blur:destroyed()
    for i, b in ipairs(Soda.Blur.active) do
        if b == self then
            table.remove(Soda.Blur.active, i)
            break
        end
    end
end

-- mark every live blur for a rebake on its next draw.
function Soda.Blur.markAllDirty()
    for _,b in ipairs(Soda.Blur.active) do b.dirty = true end
end

-- mark for rebake every live blur whose owner sits at or above `mover`
-- in Soda's top-level z-order (Soda.items) - ie. every blur that could
-- be showing `mover` through itself. called when a top-level element
-- (eg. a dragged window) moves. elements not found in Soda.items
-- (nested / not yet added) fall back to marking everything dirty.
function Soda.Blur.markDirtyAbove(mover)
    local moverIdx
    for i,v in ipairs(Soda.items) do
        if v == mover then moverIdx = i break end
    end
    if not moverIdx then
        Soda.Blur.markAllDirty()
        return
    end
    for _,b in ipairs(Soda.Blur.active) do
        local ownerIdx
        for i,v in ipairs(Soda.items) do
            if v == b.parent then ownerIdx = i break end
        end
        if not ownerIdx or ownerIdx > moverIdx then
            b.dirty = true
        end
    end
end

-- called every draw (Frame:draw runs mesh[i]:draw() for each mesh
-- component, shadow included - this is that same hook). cheap: rebake
-- only happens when dirty, otherwise this just repositions the crop.
function Soda.Blur:draw()
    if self.dirty then self:rebake() end
    local px, py = self:parentCenter()
    self.parent.shapeArgs.texCoord = vec2(px, py)
end

-- the owning element's centre, in the same absolute on-screen space the
-- full bake below is rendered in. correct for top-level (unparented)
-- elements, which is how every blurred element ships in Soda (windows,
-- alerts); a blurred element nested inside another Soda parent would
-- need this walked up the parent chain too.
function Soda.Blur:parentCenter()
    return self.parent.x, self.parent.y
end

-- composite "everything below me" into a full-screen image (reusing the
-- host project's own drawing() function and Soda's breakpoint mechanism,
-- exactly as the original Blur did), then blur it, and hand the result
-- straight to the parent's shapeArgs so RoundedRectangle picks it up.
function Soda.Blur:rebake()
    local target = image(WIDTH, HEIGHT)
    pushStyle()
    pushMatrix()
    resetMatrix()
    setContext(target)
    Soda.drawing(self.parent) --draws everything up to (not including) self.parent
    setContext()
    popMatrix()
    popStyle()
    
    self.image = self:blur(target)
    self.dirty = false
    
    self.parent.shapeArgs.tex = self.image
    self.parent.shapeArgs.resetTex = self.image
end

-- 2-pass gaussian blur of a full-size image, downsampled for the actual
-- blur work then upsampled back to WIDTH x HEIGHT so the result lines up
-- 1:1 with texCoord's absolute pixel coordinates. reuses Soda.Gaussian's
-- existing horizontal/vertical shader pair rather than duplicating them.
function Soda.Blur:blur(source)
    local dw = math.max(1, math.floor(WIDTH * self.downSample))
    local dh = math.max(1, math.floor(HEIGHT * self.downSample))
    local largest = math.max(WIDTH, HEIGHT)
    local aspect = vec2(largest/WIDTH, largest/HEIGHT) --keep blur radius even on non-square screens
    
    pushStyle()
    
    local down = image(dw, dh)
    setContext(down)
    sprite(source, dw*0.5, dh*0.5, dw, dh)
    setContext()
    
    local mH = mesh()
    mH.texture = down
    mH:addRect(dw*0.5, dh*0.5, dw, dh)
    mH.shader = shader(Soda.Gaussian.shader.vert[1], Soda.Gaussian.shader.frag)
    mH.shader.am = aspect
    
    local passed = image(dw, dh)
    setContext(passed)
    mH:draw()
    setContext()
    
    local mV = mesh()
    mV.texture = passed
    mV:addRect(WIDTH*0.5, HEIGHT*0.5, WIDTH, HEIGHT)
    mV.shader = shader(Soda.Gaussian.shader.vert[2], Soda.Gaussian.shader.frag)
    mV.shader.am = aspect
    
    local out = image(WIDTH, HEIGHT)
    setContext(out)
    mV:draw()
    setContext()
    
    popStyle()
    
    return out
end

-- kept for API/pattern symmetry with Soda.Shadow, and because
-- Frame:orientationChanged() calls mesh[i]:setMesh() directly on every
-- mesh component. WIDTH/HEIGHT have already changed by the time this
-- runs, so a lazy rebake (next draw) picks up the new dimensions.
function Soda.Blur:setMesh()
    self.dirty = true
end

---------------------------------------------------------------------------

Soda.Shadow = class(Soda.Gaussian)

function Soda.Shadow:init(t)
    self.parent = t.parent
    
    self.falloff = 1.3
    self.off = math.max(2, self.parent.w * 0.015, self.parent.h * 0.015)
    -- print(self.parent.title, "offset", self.off)
    self.mesh = mesh()
    self.mesh:addRect(0,0,0,0)
    self:setMesh()
end

function Soda.Shadow:setMesh()
    self.mesh.texture = self:setImage()
    -- self.mesh:setRect(1, self.parent.x + self.off,self.parent.y - self.off,self.ww, self.hh)   --nb, rect is set in draw function, for animation purposes
end

function Soda.Shadow:drawImage()
    pushStyle()
    pushMatrix()
    
    translate((self.ww-self.parent.w)*0.47, (self.hh-self.parent.h)*0.54)
    self.parent:drawShape({Soda.style.shadow})
    popMatrix()
    
    popStyle()
end

Soda.Gaussian.shader = {
    vert = { -- horizontal pass vertex shader
        [[
        uniform mat4 modelViewProjection;
        uniform vec2 am; // ammount of blur, inverse aspect ratio (so that oblong shapes still produce round blur)
        attribute vec4 position;
        attribute vec2 texCoord;
        
        varying vec2 vTexCoord;
        varying vec2 v_blurTexCoords[14];
        
        void main()
        {
        gl_Position = modelViewProjection * position;
        vTexCoord = texCoord;
        v_blurTexCoords[ 0] = vTexCoord + vec2(-0.028 * am.x, 0.0);
        v_blurTexCoords[ 1] = vTexCoord + vec2(-0.024 * am.x, 0.0);
        v_blurTexCoords[ 2] = vTexCoord + vec2(-0.020 * am.x, 0.0);
        v_blurTexCoords[ 3] = vTexCoord + vec2(-0.016 * am.x, 0.0);
        v_blurTexCoords[ 4] = vTexCoord + vec2(-0.012 * am.x, 0.0);
        v_blurTexCoords[ 5] = vTexCoord + vec2(-0.008 * am.x, 0.0);
        v_blurTexCoords[ 6] = vTexCoord + vec2(-0.004 * am.x, 0.0);
        v_blurTexCoords[ 7] = vTexCoord + vec2( 0.004 * am.x, 0.0);
        v_blurTexCoords[ 8] = vTexCoord + vec2( 0.008 * am.x, 0.0);
        v_blurTexCoords[ 9] = vTexCoord + vec2( 0.012 * am.x, 0.0);
        v_blurTexCoords[10] = vTexCoord + vec2( 0.016 * am.x, 0.0);
        v_blurTexCoords[11] = vTexCoord + vec2( 0.020 * am.x, 0.0);
        v_blurTexCoords[12] = vTexCoord + vec2( 0.024 * am.x, 0.0);
        v_blurTexCoords[13] = vTexCoord + vec2( 0.028 * am.x, 0.0);
        }]],
        -- vertical pass vertex shader
        [[
        uniform mat4 modelViewProjection;
        uniform vec2 am; // ammount of blur
        attribute vec4 position;
        attribute vec2 texCoord;
        
        varying vec2 vTexCoord;
        varying vec2 v_blurTexCoords[14];
        
        void main()
        {
        gl_Position = modelViewProjection * position;
        vTexCoord = texCoord;
        v_blurTexCoords[ 0] = vTexCoord + vec2(0.0, -0.028 * am.y);
        v_blurTexCoords[ 1] = vTexCoord + vec2(0.0, -0.024 * am.y);
        v_blurTexCoords[ 2] = vTexCoord + vec2(0.0, -0.020 * am.y);
        v_blurTexCoords[ 3] = vTexCoord + vec2(0.0, -0.016 * am.y);
        v_blurTexCoords[ 4] = vTexCoord + vec2(0.0, -0.012 * am.y);
        v_blurTexCoords[ 5] = vTexCoord + vec2(0.0, -0.008 * am.y);
        v_blurTexCoords[ 6] = vTexCoord + vec2(0.0, -0.004 * am.y);
        v_blurTexCoords[ 7] = vTexCoord + vec2(0.0,  0.004 * am.y);
        v_blurTexCoords[ 8] = vTexCoord + vec2(0.0,  0.008 * am.y);
        v_blurTexCoords[ 9] = vTexCoord + vec2(0.0,  0.012 * am.y);
        v_blurTexCoords[10] = vTexCoord + vec2(0.0,  0.016 * am.y);
        v_blurTexCoords[11] = vTexCoord + vec2(0.0,  0.020 * am.y);
        v_blurTexCoords[12] = vTexCoord + vec2(0.0,  0.024 * am.y);
        v_blurTexCoords[13] = vTexCoord + vec2(0.0,  0.028 * am.y);
        }]]},
        --fragment shader
        frag = [[precision mediump float;
        
        uniform lowp sampler2D texture;
        
        varying vec2 vTexCoord;
        varying vec2 v_blurTexCoords[14];
        
        void main()
        {
        gl_FragColor = vec4(0.0);
        gl_FragColor += texture2D(texture, v_blurTexCoords[ 0])*0.0044299121055113265;
        gl_FragColor += texture2D(texture, v_blurTexCoords[ 1])*0.00895781211794;
        gl_FragColor += texture2D(texture, v_blurTexCoords[ 2])*0.0215963866053;
        gl_FragColor += texture2D(texture, v_blurTexCoords[ 3])*0.0443683338718;
        gl_FragColor += texture2D(texture, v_blurTexCoords[ 4])*0.0776744219933;
        gl_FragColor += texture2D(texture, v_blurTexCoords[ 5])*0.115876621105;
        gl_FragColor += texture2D(texture, v_blurTexCoords[ 6])*0.147308056121;
        gl_FragColor += texture2D(texture, vTexCoord         )*0.159576912161;
        gl_FragColor += texture2D(texture, v_blurTexCoords[ 7])*0.147308056121;
        gl_FragColor += texture2D(texture, v_blurTexCoords[ 8])*0.115876621105;
        gl_FragColor += texture2D(texture, v_blurTexCoords[ 9])*0.0776744219933;
        gl_FragColor += texture2D(texture, v_blurTexCoords[10])*0.0443683338718;
        gl_FragColor += texture2D(texture, v_blurTexCoords[11])*0.0215963866053;
        gl_FragColor += texture2D(texture, v_blurTexCoords[12])*0.00895781211794;
        gl_FragColor += texture2D(texture, v_blurTexCoords[13])*0.0044299121055113265;
        }]]
    }
    