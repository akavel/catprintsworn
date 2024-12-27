-- local lastModified = os.time()
lastModified = os.time()

function reload(path)
    local result, t = pcall(love.filesystem.getLastModified, path)
    if not result or not t then print("dating error: " .. t) return end
    if t <= lastModified then return end
    local result, chunk = pcall(love.filesystem.load, path)
    if not result then print("chunk error: " .. chunk) return end
    result, chunk = pcall(chunk,args)
    if not result then print("exec. error: " .. chunk) return end
    lastModified = os.time()
end

function love.update(dt)
    reload('main.lua')
end

function love.draw()
    love.graphics.print("Hello World 3!", 400, 300)
end
