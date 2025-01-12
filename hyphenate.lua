-- based on cc0 https://github.com/speedata/hyphenation/blob/master/hyphenation.go

local function asdigit(c)
  local c = (c:byte()) - ('0'):byte()
  return c >= 0 and c <= 9 and c
end

function load_patterns(raw_patterns, leftmin, rightmin)
  local lang = {
    leftmin=leftmin or 0,
    rightmin=rightmin or 0,
    str_breaks={},
    max_len=0,
  }
  for word in raw_patterns:gmatch'[%w%.]+' do
    local letters, breaks = {}, {}
    local prev = '0'
    for c in word:gmatch'.' do
      if not asdigit(c) then
        letters[#letters+1] = c
        if c ~= '.' then
          breaks[#breaks+1] = asdigit(prev) or 0
        end
      end
      prev = c
    end
    breaks[#breaks+1] = asdigit(prev) or 0
    lang.str_breaks[table.concat(letters)] = breaks
    if #letters > lang.max_len then
      lang.max_len = #letters
    end
  end
  return lang
end

local function max(a, b)
  return a > b and a or b
end

local function bump_breaks(breaks, i, str, patterns)
  local str_breaks = patterns.str_breaks[str] or {}
  for j, prio in ipairs(str_breaks) do
    local k = i+j-1
    breaks[k] = max(prio, breaks[k] or 0)
  end
end

-- hyphenate splits the word based on loaded patterns
function hyphenate(word, patterns)
  local word, suffix = assert(word:match'^(%w+)(.*)$')
  local rword = ('.'..word..'.'):lower()
  local breaks = {}
  for i = 1, #rword-1 do
    for j = i+1, #rword do
      if j-i <= patterns.max_len then
        local str = rword:sub(i,j)
        bump_breaks(breaks, i, str, patterns)
      end
    end
  end
  local left = 2 + patterns.leftmin
  local right = #rword - patterns.rightmin
  local offs = {}
  for i = left, right do
    if (breaks[i] or 0) % 2 ~= 0 then
      offs[#offs+1] = i - 2
    end
  end
  offs[#offs+1] = #word
  local strs = {}
  local prev = 1
  for i = 1, #offs do
    strs[#strs+1] = word:sub(prev, offs[i])
    prev = offs[i]+1
  end
  strs[#strs] = strs[#strs] .. suffix
  return strs
end

local function readfile(fname)
  local f = assert(io.open(fname))
  local d = f:read'a'
  f:close()
  return d
end

if arg then
  print 'hello!'
  local lang = load_patterns(readfile'hyph-en-us.pat.txt', 2, 3)
  -- for _, i in ipairs(lang.str_breaks.septemb) do print('_', i) end
  -- for s, v in pairs(lang.str_breaks) do
  --   print(s, #v)
  --   break
  -- end
  -- print(#lang.str_breaks, lang.max_len)
  -- for _, i in ipairs(hyphenate('developers', lang)) do
  --   print(i)
  -- end
  local tests = {
    'developers',
    'developer',
    'developer,',
    'September',
    'discovery,',
    'Descriptor/Focus.',
    'Action/Theme',
    'Descriptor',
  }
  for _, t in ipairs(tests) do
    print(table.concat(hyphenate(t, lang), '-'))
  end
end
