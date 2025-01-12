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

-- font = love.graphics.newFont( 'georgiab.ttf', 20, 'mono' ) hAdjust = 0
-- font = love.graphics.newFont( 'DejaVuSerifCondensed-Bold.ttf', 18, 'mono' ) hAdjust = 0
font = love.graphics.newFont( 'DejaVuSerif-Bold.ttf', 18, 'mono' ) hAdjust = 0
ifont = love.graphics.newFont( 'DejaVuSerif-BoldItalic.ttf', 18, 'mono' )
-- sfont = love.graphics.newFont( 'DejaVuSerifCondensed-BoldItalic.ttf', 18, 'mono' )
sfont = love.graphics.newFont( 'NotoSerif-CondensedBoldItalic.ttf', 18, 'mono' )
-- font = love.graphics.newFont( 'NotoSans-CondensedBold.ttf', 20, 'mono' ) hAdjust = 0
-- font = love.graphics.newFont( 'mago1.ttf', 15, 'mono' )
-- font = love.graphics.newFont( 'mago1.ttf', 32, 'mono' )
-- font = love.graphics.newFont( 'mago3.ttf', 15, 'mono' )
-- font = love.graphics.newFont( 'PetitePx.ttf', 15, 'mono' )
-- font = love.graphics.newFont( 'PetitePx.ttf', 31, 'mono' ) hAdjust = -6
-- font = love.graphics.newFont( 'clover-sans.ttf', 12, 'mono' )
-- font = love.graphics.newFont( 'Lief.ttf', 14, 'mono' )
-- font:setFilter('nearest')
tfont = font

-- hfont = love.graphics.newFont( 'georgiab.ttf', 30, 'mono' )
-- hfont = love.graphics.newFont( 'RussoOne-Regular.ttf', 30, 'mono' )
-- hfont = love.graphics.newFont( 'RussoOne-Regular.ttf', 32, 'mono' )
-- hfont = love.graphics.newFont( 'NotoSans-Regular.ttf', 32, 'mono' )
hfont = love.graphics.newFont( 'NotoSans-Regular.ttf', 33, 'mono' )
-- hfont = love.graphics.newFont( 'NotoSans-Bold.ttf', 30, 'mono' )
-- hfont = love.graphics.newFont( 'NotoSans-Condensed.ttf', 32, 'mono' )
-- hfont = love.graphics.newFont( 'NotoSerif-Light.ttf', 30, 'mono' )

require 'hyphenate'

unmd = function(md)
    return md:gsub('%[([^%]]+)%]%([^%)]+%)', '%1')
        :gsub('’', "'")
end

local lang = load_patterns(readfile'hyph-en-us.pat.txt', 2, 3)
function try_hyph(line, i, words, font, x0)
    -- if true then
    --     return nil
    -- end
    local line0 = table.concat(line, ' ') .. ' '
    local strs = hyphenate(words[i], lang)
    for j = #strs-1, 1, -1 do
        local prefix = table.concat(strs, '', 1, j) .. '-'
        local w = font:getWidth(line0 .. prefix)
        if w <= 384-x0 then
            line[#line+1] = prefix
            return table.concat(strs, '', j+1)
        end
    end
    return nil
end

-- printdx prints a text and returns x plus width of printed text in given font
local function printdx(text, font, x, y)
    love.graphics.print(text, font, x, y)
    return x + font:getWidth(text) 
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
    local split_word = nil
    while i <= #words do
        local line = {split_word}
        repeat
            if words[i] == '\n' then
                i = i+1
                if #line > 0 then break end
            elseif words[i] == '*' and #line == 0 then -- itemized list / bullet point
                i = i+1
                local bullet = ' • '
                local x1 = printdx(bullet, font, x0, y0)
                local itemtext = {}
                -- while i<=#words and words[i] ~= '\n' do
                while i<=#words do
                    local s = words[i]
                    itemtext[#itemtext+1] = s
                    i = i+1
                    if s == '\n' then break end
                end
                itemtext = table.concat(itemtext, ' ')
                y0 = wrap(x1, y0, font, itemtext, hAdjust)
                goto next_line
            end
            line[#line+1] = words[i]
            i = i+1
            local w = font:getWidth(table.concat(line, ' '))
            if w > 384-x0 then
                i = i-1
                line[#line] = nil
                split_word = try_hyph(line, i, words, font, x0)
                if split_word then
                    i = i+1
                end
                break
            end
        until i > #words
        love.graphics.print(table.concat(line, ' '), font, x0, y0)
        y0 = y0 + font:getHeight() + hAdjust
        ::next_line::
    end
    return y0
end


local canvas = love.graphics.newCanvas()

function prep()
    -- local i, j = 4, 36
    local i, j = 1,1
    local y = 1
    canvas:renderTo(function()
        love.graphics.clear(1,1,1)

        love.graphics.setColor(0,0,0)

        if #assets<i or #assets[i].Assets<j then return end
        local asset = assets[i].Assets[j]
        y = 10+ wrap(0, y, hfont, unmd(asset.Name), -2)
        -- y = 10+ wrap(0, y, hfont, unmd(assets[i].Assets[j].Name:upper()), 0)
        for _, input in ipairs(asset.Inputs or {}) do
            y = 10+ wrap(5, y, sfont, input.Name..':', hAdjust)
            local yline = y-10
            love.graphics.line(5, yline, 370, yline)
        end
        if asset.Requirement then
            y = 10+ wrap(0, y, ifont, unmd(asset.Requirement), hAdjust)
        end
        y = 10+ wrap(0, y, font, unmd(asset.Abilities[1].Text), hAdjust)
        y = 10+ wrap(0, y, font, unmd(asset.Abilities[2].Text), hAdjust)
        y = 10+ wrap(0, y, font, unmd(asset.Abilities[3].Text), hAdjust)
        if asset['Condition Meter'] then
            local meter = asset['Condition Meter']
            local x = 0
            if meter.Min and meter.Max then
                for m = meter.Max, meter.Min, -1 do
                    x = printdx(('┏ %s ┓'):format(m), font, x, y)
                end
            end
            x = printdx(' ', font, x, y)
            for _, cond in ipairs(meter.Conditions or {}) do
                x = printdx(('╭ %s ╮'):format(cond:sub(1,4)), ifont, x, y)
            end
            y = y + font:getHeight() + hAdjust
        end
    end)
    local dat = canvas:newImageData(1, 1, 0, 0, 384, y)
    dat:encode('png', ('asset-%d-%d.png'):format(i,j))
end

prep()

function love.update(dt)
    reload('main.lua')

end

function love.draw()
    love.graphics.setColor(1, 1, 1);
    -- canvas:setFilter('nearest', 'nearest')
    -- love.graphics.setDefaultFilter('nearest', 'nearest')
    -- local scale = 2
    local scale = 1
    love.graphics.draw(canvas, 0, 0, 0, scale, scale);
end
