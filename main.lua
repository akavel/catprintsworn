--  catprintsworn
--  Copyright (C) 2025  Mateusz Czapliński akavel.pl
--
--  This program is free software: you can redistribute it and/or modify
--  it under the terms of the GNU Affero General Public License as published
--  by the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU Affero General Public License for more details.
--
--  You should have received a copy of the GNU Affero General Public License
--  along with this program.  If not, see <https://www.gnu.org/licenses/>.

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
assets = json.decode(readfile('dat-starforged/assets.json'))

font = love.graphics.newFont( 'fonts-djvu/DejaVuSerif-Bold.ttf', 18, 'mono' ) hAdjust = 0
ifont = love.graphics.newFont( 'fonts-djvu/DejaVuSerif-BoldItalic.ttf', 18, 'mono' )
sfont = love.graphics.newFont( 'fonts-noto/NotoSerif-CondensedBoldItalic.ttf', 18, 'mono' )
hfont = love.graphics.newFont( 'fonts-noto/NotoSans-Regular.ttf', 33, 'mono' )

require 'hyphenate'

unmd = function(md)
    return md:gsub('%[([^%]]+)%]%([^%)]+%)', '%1')
        :gsub('’', "'")
end

local lang = load_patterns(readfile'dat-hyphenation/hyph-en-us.pat.txt', 2, 3)
function try_hyph(line, i, words, font, x0)
    -- if true then
    --     return nil
    -- end
    local line0 = table.concat(line, ' ') .. ' '
    local strs = hyphenate(words[i], lang)
    local start = #strs-1
    if i==#words or words[i+1] == '\n' then
        -- if final word of paragraph, make sure we don't split it on last syllable.
        start = start-1
    end
    for j = start, 1, -1 do
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
    while i <= #words or split_word ~= nil do
        local line = {split_word}
        split_word = nil
        repeat
            if words[i] == '\n' then
                i = i+1
                if #line > 0 then break end
            elseif words[i] == '*' and #line == 0 then -- itemized list / bullet point
                i = i+1
                -- local bullet = ' • '
                -- local bullet = ' ▸ '
                -- local bullet = '   ▸ '
                local bullet = '   ▹ '
                -- local bullet = '  - '
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

        local function ability(i)
            local ab = asset.Abilities[i]
            -- local prefix = ab.Enabled and '■ ' or '□ '
            local prefix = ab.Enabled and '● ' or '○ '
            y = 10+ wrap(0, y, font, prefix..unmd(ab.Text), hAdjust)
        end
        for i in ipairs(asset.Abilities) do
            ability(i)
        end

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
