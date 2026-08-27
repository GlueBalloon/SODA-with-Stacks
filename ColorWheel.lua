--# ColorWheel
-- Soda.ColorWheel: an HSB color picker - hue ring + saturation/brightness
-- disc. Ported from a standalone _IMUI-based implementation into Soda's
-- own Frame/Sensor/class conventions (Soda.Slider is the closest existing
-- analogue - see SliderKnob for the same "custom-drawn widget with a
-- draggable thumb" shape). No _IMUI globals, no name-keyed instance
-- lookup table: a Soda.Frame instance already persists its own state
-- across frames, so that indirection isn't needed here.
--
-- sized like any other Soda element via w/h - pass equal w and h, the
-- wheel is inscribed in that square. hue is stored in degrees [0,360),
-- saturation/brightness in percent [0,100], matching the source's
-- convention. NOTE: self.hue/self.sat/self.bri, not self.h - Soda.Frame
-- already owns self.h for the element's height, so the original state.h
-- naming would silently corrupt layout if reused here.

Soda.ColorWheel = class(Soda.Frame)

-- GLSL source only, not a compiled shader - compiling with shader() at
-- tab-load time (before setup() runs) isn't safe, same reason
-- Soda.Gaussian.shader stores source and compiles lazily on first use.
Soda.ColorWheel.discShaderSrc = {
  vert = [[
  uniform mat4 modelViewProjection;
  attribute vec4 position;
  varying highp vec2 vPos;
  void main() {
  vPos = position.xy;
  gl_Position = modelViewProjection * position;
  }
  ]],
  frag = [[
  precision highp float;
  uniform vec2 reso;
  uniform float hue;
  varying highp vec2 vPos;
  
  vec3 hsb2rgb(vec3 c){
  vec4 K = vec4(1.0,2.0/3.0,1.0/3.0,3.0);
  vec3 p = abs(fract(c.xxx+K.xyz)*6.0 - K.www);
  return c.z * mix(K.xxx, clamp(p-K.xxx,0.0,1.0), c.y);
  }
  
  void main(){
  vec2 d = vPos / (reso * 0.5);
  if (length(d) > 1.0) discard;
  const float SQRT2 = 1.41421356237;
  vec2 uv = clamp(d * SQRT2, -1.0, 1.0);
  float s = uv.x * 0.5 + 0.5;
  float b = uv.y * 0.5 + 0.5;
  vec3 col = hsb2rgb(vec3(hue, s, b));
  gl_FragColor = vec4(col, 1.0);
  }
  ]]
}

local __discShader -- compiled once, lazily, shared by every wheel instance
local function getDiscShader()
  if not __discShader then
    __discShader = shader(Soda.ColorWheel.discShaderSrc.vert, Soda.ColorWheel.discShaderSrc.frag)
  end
  return __discShader
end

-- plain HSB->RGB conversion, used by the ring sprite bake, the disc
-- thumb fill colors, and ColorWheel:color(). kept as a tab-local (not a
-- class method) since it's a pure function with no wheel state.
local function hsb2rgbColor(h, s, b)
  h = h % 360
  s = math.min(math.max(s, 0), 100) / 100
  b = math.min(math.max(b, 0), 100) / 100
  local c = b * s
  local x = c * (1 - math.abs((h / 60) % 2 - 1))
  local m = b - c
  local r, g, bl
  if h < 60 then r,g,bl = c,x,0
  elseif h < 120 then r,g,bl = x,c,0
  elseif h < 180 then r,g,bl = 0,c,x
  elseif h < 240 then r,g,bl = 0,x,c
  elseif h < 300 then r,g,bl = x,0,c
  else r,g,bl = c,0,x end
  return color((r+m)*255, (g+m)*255, (bl+m)*255)
end

-- hue-ring sprites and SB-disc meshes are geometry, not per-wheel state -
-- cached by radius so two same-sized wheels share one copy. same pattern
-- as RoundedRectangle's own __RRects cache.
local __ringSprites = {}
local __discMeshes = {}

local function buildRingSprite(radius)
  local sw, dia = radius/25, radius*2 + (radius/25)*2
  local img = image(dia, dia)
  pushStyle()
  setContext(img)
  if resetMatrix then resetMatrix() end
  background(0,0,0,0)
  pushMatrix()
  translate(dia/2, dia/2)
  noFill()
  strokeWidth(sw)
  lineCapMode(SQUARE)
  for i = 1, 360 do
    rotate(1)
    stroke(hsb2rgbColor(i+90, 100, 100))
    line(0, radius*(21/31), 0, radius)
  end
  popMatrix()
  setContext()
  popStyle()
  return img
end

local function buildDiscMesh(radius)
  local sides, area = 64, radius * (17/31)
  local verts = {}
  for i = 1, sides do
    local ang = math.rad(180 + 180/sides + 360/sides * (i-1))
    table.insert(verts, vec2(0,0) * area)
    table.insert(verts, vec2(-math.tan(math.pi/sides), -1):rotate(ang) * area)
    table.insert(verts, vec2( math.tan(math.pi/sides), -1):rotate(ang) * area)
  end
  local m = mesh()
  m.primitiveType = TRIANGLES
  m.vertices = verts
  m.shader = getDiscShader()
  return m
end

function Soda.ColorWheel:init(t)
  self.hue = t.hue or 0    -- degrees, 0-360
  self.sat = t.sat or 100  -- percent, 0-100
  self.bri = t.bri or 100  -- percent, 0-100
  -- thumb sizes as a ratio of radius (not absolute pixels), so they
  -- stay correct even if the wheel is ever built at a different size.
  self.hueThumbScale = 0.35
  self.sbThumbScale = 0.25
  
  Soda.Frame.init(self, t)
  
  -- default rectangular Sensor (over the full w x h square) gates
  -- which touches are "mine" at all; onDrag then does its own
  -- radius-based zone test (hue ring vs sb disc) to decide what a
  -- touch that started on me actually controls. same division of
  -- labor as Soda.SliderKnob:move, just with a circular hit area
  -- instead of a 1D track.
  self.sensor:onDrag(function(event) self:onDrag(event) end)
end

function Soda.ColorWheel:radius()
  return math.min(self.w, self.h) * 0.5
end

function Soda.ColorWheel:color()
  return hsb2rgbColor(self.hue, self.sat, self.bri)
end

-- expects Codea's own RGB->HSV conversion under _rgb2hsv, since Soda has
-- no such helper of its own - no-ops quietly if the host project hasn't
-- provided one, rather than erroring.
function Soda.ColorWheel:setFromColor(c)
  if not _rgb2hsv then return end
  local h, s, v = _rgb2hsv(c.r or 255, c.g or 255, c.b or 255)
  self.hue = (h or 0) * 360
  self.sat = (s or 0) * 100
  self.bri = (v or 0) * 100
end

function Soda.ColorWheel:onDrag(event)
  local t = event.touch
  local radius = self:radius()
  local innerR = radius * (21/31)
  local discR = radius * (17/31)
  local lp = event.tpos - vec2(self.x, self.y)
  
  if t.state == BEGAN then
    local d = lp:len()
    if d >= innerR and d <= radius then
      self.activeControl = "hue"
    elseif d <= discR then
      self.activeControl = "sb"
    else
      self.activeControl = nil
    end
  end
  
  if not self.activeControl then return end
  
  if self.activeControl == "hue" then
    self.hue = (math.deg(math.atan(lp.y, lp.x)) + 360) % 360
  else
    local rawX, rawY = lp.x, lp.y
    local dist2 = rawX*rawX + rawY*rawY
    if dist2 > discR*discR then
      local len = math.sqrt(dist2)
      rawX = rawX / len * discR
      rawY = rawY / len * discR
    end
    local SQRT2 = math.sqrt(2)
    local ux = clamp(rawX/discR * SQRT2, -1, 1)
    local uy = clamp(rawY/discR * SQRT2, -1, 1)
    self.sat = (ux * 0.5 + 0.5) * 100
    self.bri = (uy * 0.5 + 0.5) * 100
  end
  
  if t.state == ENDED or t.state == CANCELLED then
    self.activeControl = nil
  end
  
  self:callback(self:color())
end

function Soda.ColorWheel:drawContent()
  local radius = self:radius()
  
  if not __ringSprites[radius] then
    __ringSprites[radius] = buildRingSprite(radius)
  end
  if not __discMeshes[radius] then
    __discMeshes[radius] = buildDiscMesh(radius)
  end
  
  pushStyle()
  pushMatrix()
  translate(self.w*0.5, self.h*0.5)
  
  noFill()
  strokeWidth(radius/25)
  lineCapMode(SQUARE)
  sprite(__ringSprites[radius], 0, 0)
  
  local disc = __discMeshes[radius]
  local discR = radius * (17/31)
  disc.shader.reso = vec2(discR*2, discR*2)
  disc.shader.hue = (self.hue % 360) / 360.0
  disc:draw()
  
  -- thumbs
  local innerR = radius * (21/31)
  local midR = (radius + innerR) * 0.5
  local a = math.rad(self.hue)
  local hx, hy = math.cos(a)*midR, math.sin(a)*midR
  local circleStrokeW = radius * 0.039
  
  local SQRT2 = math.sqrt(2)
  local ux = (self.sat/100 * 2 - 1)
  local uy = (self.bri/100 * 2 - 1)
  local dx = (ux/SQRT2) * discR
  local dy = (uy/SQRT2) * discR
  local dlen = math.sqrt(dx*dx+dy*dy)
  if dlen > discR and dlen > 0 then
    dx = dx/dlen*discR
    dy = dy/dlen*discR
  end
  
  local targetHue = (self.activeControl == "hue") and 0.7 or 0.35
  local targetSB  = (self.activeControl == "sb")  and 0.7 or 0.25
  local f = math.min(8.0 * DeltaTime, 1)
  self.hueThumbScale = self.hueThumbScale + (targetHue - self.hueThumbScale) * f
  self.sbThumbScale  = self.sbThumbScale  + (targetSB  - self.sbThumbScale ) * f
  local hueSize = self.hueThumbScale * radius
  local sbSize  = self.sbThumbScale * radius
  
  fill(0,128); noStroke()
  ellipse(hx + radius*0.02, hy - radius*0.02, hueSize)
  fill(hsb2rgbColor(self.hue,100,100)); stroke(255); strokeWidth(circleStrokeW)
  ellipse(hx, hy, hueSize)
  
  fill(0,128); noStroke()
  ellipse(dx + radius*0.015, dy - radius*0.015, sbSize)
  fill(self:color()); stroke(255); strokeWidth(circleStrokeW)
  ellipse(dx, dy, sbSize)
  
  popMatrix()
  popStyle()
end
