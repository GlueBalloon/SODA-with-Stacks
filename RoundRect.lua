local __RRects = {}
function Soda.RoundedRectangle(t) 
  local s = t.radius or 8
  local c = t.corners or 15
  local w = math.max(t.w+1,2*s)+1
  local h = math.max(t.h,2*s)+2
  local hasTexture = 0
  if t.tex then hasTexture = 1 end
  local label = table.concat({w,h,s,c,hasTexture},",")
  
  if not __RRects[label] then
    local rr = mesh()
    rr.shader = shader(rrectshad.vert, rrectshad.frag)
    
    local v = {}
    local no = {}
    
    local n = math.max(3, s//2)
    local o,dx,dy
    local edge, cent = vec3(0,0,1), vec3(0,0,0)
    for j = 1,4 do
      dx = 1 - 2*(((j+1)//2)%2)
      dy = -1 + 2*((j//2)%2)
      o = vec2(dx * (w * 0.5 - s), dy * (h * 0.5 - s))
      local bit = 2^(j-1)
      if c & bit == bit then
        for i = 1,n do
          v[#v+1] = o
          v[#v+1] = o + vec2(dx * s * math.cos((i-1) * math.pi/(2*n)), dy * s * math.sin((i-1) * math.pi/(2*n)))
          v[#v+1] = o + vec2(dx * s * math.cos(i * math.pi/(2*n)), dy * s * math.sin(i * math.pi/(2*n)))
          no[#no+1] = cent
          no[#no+1] = edge
          no[#no+1] = edge
        end
      else
        v[#v+1] = o
        v[#v+1] = o + vec2(dx * s,0)
        v[#v+1] = o + vec2(dx * s,dy * s)
        v[#v+1] = o
        v[#v+1] = o + vec2(0,dy * s)
        v[#v+1] = o + vec2(dx * s,dy * s)
        local new = {cent, edge, edge, cent, edge, edge}
        for i=1,#new do
          no[#no+1] = new[i]
        end
      end
    end
    rr.vertices = v
    
    rr:addRect(0,0,w-2*s,h-2*s)
    rr:addRect(0,(h-s)/2,w-2*s,s)
    rr:addRect(0,-(h-s)/2,w-2*s,s)
    rr:addRect(-(w-s)/2, 0, s, h - 2*s)
    rr:addRect((w-s)/2, 0, s, h - 2*s)
    local new = {cent,cent,cent, cent,cent,cent,
      edge,cent,cent, edge,cent,edge,
      cent,edge,edge, cent,edge,cent,
      edge,edge,cent, edge,cent,cent,
    cent,cent,edge, cent,edge,edge}
    for i=1,#new do
      no[#no+1] = new[i]
    end
    rr.normals = no
    if t.tex then
      rr.shader.fragmentProgram = rrectshad.fragTex
    end
    local sc = 1/math.max(2, s)
    rr.shader.scale = sc
    __RRects[label] = rr
  end
  
  local rr = __RRects[label]
  
  if t.tex then
    rr.texture = t.tex
    local ww, hh = w*0.5, h*0.5
    local tex = {}
    if t.texCoord then
      local tw, th = t.tex.width, t.tex.height
      for i,vv in ipairs(rr.vertices) do
        tex[i] = vec2((vv.x + t.texCoord.x)/tw, (vv.y + t.texCoord.y)/th)
      end
    else
      for i,vv in ipairs(rr.vertices) do
        tex[i] = vec2((vv.x + ww)/w, (vv.y + hh)/h)
      end
    end
    rr.texCoords = tex
  end
  
  rr.shader.fillColor = color(fill())
  if strokeWidth() == 0 then
    rr.shader.strokeColor = color(fill())
  else
    rr.shader.strokeColor = color(stroke())
  end
  
  if t.resetTex then
    rr.texture = t.resetTex
    t.resetTex = nil
  end
  local sc = 0.25/math.max(2, s)
  rr.shader.strokeWidth = math.min( 1 - sc*3, strokeWidth() * sc)
  pushMatrix()
  translate(t.x,t.y)
  scale(t.scale or 1)
  rr:draw()
  popMatrix()
end

rrectshad ={
  vert=[[
  uniform mat4 modelViewProjection;
  
  attribute vec4 position;
  
  //attribute vec4 color;
  attribute vec2 texCoord;
  attribute vec3 normal;
  
  //varying lowp vec4 vColor;
  varying highp vec2 vTexCoord;
  varying vec3 vNormal;
  
  void main()
  {
  //  vColor = color;
  vTexCoord = texCoord;
  vNormal = normal;
  gl_Position = modelViewProjection * position;
  }
  ]],
  frag=[[
  precision highp float;
  
  uniform lowp vec4 fillColor;
  uniform lowp vec4 strokeColor;
  uniform float scale;
  uniform float strokeWidth;
  
  //varying lowp vec4 vColor;
  varying highp vec2 vTexCoord;
  varying vec3 vNormal;
  
  void main()
  {
  lowp vec4 col = mix(strokeColor, fillColor, smoothstep((1. - strokeWidth) - scale * 0.5, (1. - strokeWidth) - scale * 1.5 , vNormal.z)); //0.95, 0.92,
  col = mix(vec4(col.rgb, 0.), col, smoothstep(1., 1.-scale, vNormal.z) );
  // col *= smoothstep(1., 1.-scale, vNormal.z);
  gl_FragColor = col;
  }
  ]],
  fragTex=[[
  precision highp float;
  
  uniform lowp sampler2D texture;
  uniform lowp vec4 fillColor;
  uniform lowp vec4 strokeColor;
  uniform float scale;
  uniform float strokeWidth;
  
  //varying lowp vec4 vColor;
  varying highp vec2 vTexCoord;
  varying vec3 vNormal;
  
  void main()
  {
  vec4 pixel = texture2D(texture, vTexCoord) * fillColor;
  lowp vec4 col = mix(strokeColor, pixel, smoothstep(1. - strokeWidth - scale * 0.5, 1. - strokeWidth - scale * 1.5, vNormal.z)); //0.95, 0.92,
  // col = mix(vec4(0.), col, smoothstep(1., 1.-scale, vNormal.z) );
  col *= smoothstep(1., 1.-scale, vNormal.z);
  gl_FragColor = col;
  }
  ]]
}
