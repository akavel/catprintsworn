-- local lastModified = os.time()
lastModified = os.time()
function reload(path)
    local result, t = pcall(love.filesystem.getLastModified, path)
    if not result or not t then print("dating error: " .. tostring(t)) return end
    if t <= lastModified then return end
    local result, chunk = pcall(love.filesystem.load, path)
    if not result then print("chunk error: " .. chunk) return end
    result, chunk = pcall(chunk,args)
    if not result then print("exec. error: " .. chunk) return end
    lastModified = os.time()
end

readfile = function(path)
    local f = assert(io.open(path))
    local text = f:read('a')
    f:close()
    return text
end

json = require 'json'
assets = json.decode(readfile('assets.json'))

-- font = love.graphics.newFont( 'mago1.ttf', 15, 'mono' )
-- font = love.graphics.newFont( 'mago3.ttf', 15, 'mono' )
-- font = love.graphics.newFont( 'PetitePx.ttf', 15, 'mono' )
-- font = love.graphics.newFont( 'clover-sans.ttf', 12, 'mono' )
font = love.graphics.newFont( 'Lief.ttf', 14, 'mono' )
font:setFilter('nearest')

unmd = function(md)
    return md:gsub('%[([^%]]+)%]%([^%)]+%)', '%1')
        :gsub('’', "'")
end

function love.update(dt)
    reload('main.lua')
end

function wrap(x0, y0, font, text, hAdjust)
    local hAdjust = hAdjust or 0
    local words = {}
    local text = text:gsub("\n\n+", "\n")
        :gsub("([^ ])\n", "%1 \n")
        :gsub("\n([^ ])", "\n %1")
    for w in text:gmatch('[^ ]+') do
        words[#words+1] = w
    end
    local i = 1
    while i <= #words do
        local line = {}
        repeat
            if words[i] == '\n' then
                i = i+1
                if #line > 0 then break end
            end
            line[#line+1] = words[i]
            i = i+1
            local w = font:getWidth(table.concat(line, ' '))
            if w > 384-x0 then
                i = i-1
                line[#line] = nil
                break
            end
        until i > #words
        local t = table.concat(line, ' ')
        love.graphics.print(t, font, x0, y0)
        y0 = y0 + font:getHeight() + hAdjust
    end
    return y0
end


function love.draw()
    -- push:start()

    local c = love.graphics.newCanvas()
    c:renderTo(function()
        local old = {love.graphics.getColor()}
        love.graphics.setColor(1,0,0)
        love.graphics.line(385,0, 385, 50)
        love.graphics.setColor(old)

        -- love.graphics.print("Hello Mateusz: " .. assets[1].Assets[1].Abilities[1].Text, font, 0, 0)
        local i, j = 2, 1
        if #assets<i or #assets[i].Assets<j then return end
        local y = 10
        y = wrap(0, y, font, unmd(assets[i].Assets[j].Abilities[1].Text))
        y = wrap(0, y, font, unmd(assets[i].Assets[j].Abilities[2].Text))
        y = wrap(0, y, font, unmd(assets[i].Assets[j].Abilities[3].Text))

    end)
    c:setFilter('nearest', 'nearest')
    -- love.graphics.scale(2,2)
    love.graphics.setDefaultFilter('nearest', 'nearest')

    love.graphics.print("Hello World 3!", 400, 300)
    -- love.graphics.draw(c)
    local scale = 2
    love.graphics.draw(c, 0, 0, 0, scale, scale)


    -- push:finish()
end
