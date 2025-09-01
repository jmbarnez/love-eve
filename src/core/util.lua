
local M = {}
function M.clamp(x,a,b) return math.max(a, math.min(b, x)) end
function M.len2(x,y) return x*x + y*y end
function M.len(x,y) return math.sqrt(M.len2(x,y)) end
function M.norm(x,y) local l = M.len(x,y); if l == 0 then return 0,0 end; return x/l, y/l end
function M.lerp(a,b,t) return a + (b-a)*t end
function M.approach(a,b,delta) if a < b then return math.min(a+delta,b) else return math.max(a-delta,b) end end
function M.sign(x) return x<0 and -1 or 1 end
function M.round(x) return math.floor(x+0.5) end
function M.randf(a,b) return a + love.math.random()*(b-a) end
function M.rand2(r) return M.randf(-r,r), M.randf(-r,r) end
function M.rectContains(rx,ry,rw,rh,x,y) return x>=rx and y>=ry and x<=rx+rw and y<=ry+rh end

function M.merge(base, overlay)
  local new = {}
  for k, v in pairs(base) do
    new[k] = v
  end
  for k, v in pairs(overlay) do
    new[k] = v
  end
  return new
end

return M
