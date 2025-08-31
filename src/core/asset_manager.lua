local M = {}

-- Asset management system for loading and caching assets
local assets = {
  images = {},
  fonts = {},
  sounds = {},
  shaders = {}
}

-- Load an image
function M.loadImage(path)
  if not assets.images[path] then
    local success, image = pcall(love.graphics.newImage, path)
    if success then
      assets.images[path] = image
    else
      print("Failed to load image: " .. path)
      return nil
    end
  end
  return assets.images[path]
end

-- Load a font
function M.loadFont(path, size)
  local key = path .. "_" .. size
  if not assets.fonts[key] then
    local success, font = pcall(love.graphics.newFont, path, size)
    if success then
      assets.fonts[key] = font
    else
      print("Failed to load font: " .. path)
      return nil
    end
  end
  return assets.fonts[key]
end

-- Load a sound
function M.loadSound(path, type)
  type = type or "static"
  local key = path .. "_" .. type
  if not assets.sounds[key] then
    local success, sound
    if type == "stream" then
      success, sound = pcall(love.audio.newSource, path, "stream")
    else
      success, sound = pcall(love.audio.newSource, path, "static")
    end
    if success then
      assets.sounds[key] = sound
    else
      print("Failed to load sound: " .. path)
      return nil
    end
  end
  return assets.sounds[key]
end

-- Load a shader
function M.loadShader(vertex, fragment)
  local key = (vertex or "") .. "_" .. (fragment or "")
  if not assets.shaders[key] then
    local success, shader = pcall(love.graphics.newShader, fragment, vertex)
    if success then
      assets.shaders[key] = shader
    else
      print("Failed to load shader: " .. key)
      return nil
    end
  end
  return assets.shaders[key]
end

-- Get cached asset
function M.get(path, type, size)
  if type == "image" then
    return assets.images[path]
  elseif type == "font" then
    return assets.fonts[path .. "_" .. size]
  elseif type == "sound" then
    return assets.sounds[path .. "_" .. (size or "static")]
  elseif type == "shader" then
    return assets.shaders[path]
  end
  return nil
end

-- Clear all assets
function M.clear()
  for _, asset in pairs(assets.images) do
    if asset.release then asset:release() end
  end
  for _, asset in pairs(assets.fonts) do
    if asset.release then asset:release() end
  end
  for _, asset in pairs(assets.sounds) do
    if asset.release then asset:release() end
  end
  for _, asset in pairs(assets.shaders) do
    if asset.release then asset:release() end
  end
  assets = {
    images = {},
    fonts = {},
    sounds = {},
    shaders = {}
  }
end

-- Get memory usage info
function M.getMemoryUsage()
  local count = 0
  for _, category in pairs(assets) do
    for _ in pairs(category) do
      count = count + 1
    end
  end
  return count
end

return M
