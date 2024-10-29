-- logging {{{
--[[
    logging.lua: pandoc-aware logging functions (can also be used standalone)
    Copyright:   (c) 2022 William Lupton
    License:     MIT - see LICENSE file for details
    Usage:       See README.md for details
]]

-- if running standalone, create a 'pandoc' global
if not pandoc then
    _G.pandoc = {utils = {}}
end

-- if there's no pandoc.utils, create a local one
if not pcall(require, 'pandoc.utils') then
    pandoc.utils = {}
end

-- if there's no pandoc.utils.type, create a local one
if not pandoc.utils.type then
    pandoc.utils.type = function(value)
        local typ = type(value)
        if not ({table=1, userdata=1})[typ] then
            -- unchanged
        elseif value.__name then
            typ = value.__name
        elseif value.tag and value.t then
            typ = value.tag
            if typ:match('^Meta.') then
                typ = typ:sub(5)
            end
            if typ == 'Map' then
                typ = 'table'
            end
        end
        return typ
    end
end

-- namespace
local logging = {}

-- helper function to return a sensible typename
logging.type = function(value)
    -- this can return 'Inlines', 'Blocks', 'Inline', 'Block' etc., or
    -- anything that built-in type() can return, namely 'nil', 'number',
    -- 'string', 'boolean', 'table', 'function', 'thread', or 'userdata'
    local typ = pandoc.utils.type(value)

    -- it seems that it can also return strings like 'pandoc Row'; replace
    -- spaces with periods
    -- XXX I'm not sure that this is done consistently, e.g. I don't think
    --     it's done for pandoc.Attr or pandoc.List?
    typ = typ:gsub(' ', '.')

    -- map Inline and Block to the tag name
    -- XXX I guess it's intentional that it doesn't already do this?
    return ({Inline=1, Block=1})[typ] and value.tag or typ
end

-- derived from https://www.lua.org/pil/19.3.html pairsByKeys()
logging.spairs = function(list, comp)
    local keys = {}
    for key, _ in pairs(list) do
        table.insert(keys, tostring(key))
    end
    table.sort(keys, comp)
    local i = 0
    local iter = function()
        i = i + 1
        return keys[i] and keys[i], list[keys[i]] or nil
    end
    return iter
end

-- helper function to dump a value with a prefix (recursive)
-- XXX should detect repetition/recursion
-- XXX would like maxlen logic to apply at all levels? but not trivial
local function dump_(prefix, value, maxlen, level, add)
    local buffer = {}
    if prefix == nil then prefix = '' end
    if level == nil then level = 0 end
    if add == nil then add = function(item) table.insert(buffer, item) end end
    local indent = maxlen and '' or ('  '):rep(level)

    -- get typename, mapping to pandoc tag names where possible
    local typename = logging.type(value)

    -- don't explicitly indicate 'obvious' typenames
    local typ = (({boolean=1, number=1, string=1, table=1, userdata=1})
                 [typename] and '' or typename)

    -- light userdata is just a pointer (can't iterate over it)
    -- XXX is there a better way of checking for light userdata?
    if type(value) == 'userdata' and not pcall(pairs(value)) then
        value = tostring(value):gsub('userdata:%s*', '')

    -- modify the value heuristically
    elseif ({table=1, userdata=1})[type(value)] then
        local valueCopy, numKeys, lastKey = {}, 0, nil
        for key, val in pairs(value) do
            -- pandoc >= 2.15 includes 'tag', nil values and functions
            if key ~= 'tag' and val and type(val) ~= 'function' then
                valueCopy[key] = val
                numKeys = numKeys + 1
                lastKey = key
            end
        end
        if numKeys == 0 then
            -- this allows empty tables to be formatted on a single line
            -- XXX experimental: render Doc objects
            value = typename == 'Doc' and '|' .. value:render() .. '|' or
            typename == 'Space' and '' or '{}'
        elseif numKeys == 1 and lastKey == 'text' then
            -- this allows text-only types to be formatted on a single line
            typ = typename
            value = value[lastKey]
            typename = 'string'
        else
            value = valueCopy
            -- XXX experimental: indicate array sizes
            if #value > 0 then
                typ = typ .. '[' .. #value .. ']'
            end
        end
    end

    -- output the possibly-modified value
    local presep = #prefix > 0 and ' ' or ''
    local typsep = #typ > 0 and ' ' or ''
    local valtyp = type(value)
    if valtyp == 'nil' then
        add('nil')
    elseif ({boolean=1, number=1, string=1})[valtyp] then
        typsep = #typ > 0 and valtyp == 'string' and #value > 0 and ' ' or ''
        -- don't use the %q format specifier; doesn't work with multi-bytes
        local quo = typename == 'string' and '"' or ''
        add(string.format('%s%s%s%s%s%s%s%s', indent, prefix, presep, typ,
                          typsep, quo, value, quo))
    -- light userdata is just a pointer (can't iterate over it)
    -- XXX is there a better way of checking for light userdata?
    elseif valtyp == 'userdata' and not pcall(pairs(value)) then
        add(string.format('%s%s%s%s %s', indent, prefix, presep, typ,
                          tostring(value):gsub('userdata:%s*', '')))
    elseif ({table=1, userdata=1})[valtyp] then
        add(string.format('%s%s%s%s%s{', indent, prefix, presep, typ, typsep))
        -- Attr and Attr.attributes have both numeric and string keys, so
        -- ignore the numeric ones
        -- XXX this is no longer the case for pandoc >= 2.15, so could remove
        --     the special case?
        local first = true
        if prefix ~= 'attributes:' and typ ~= 'Attr' then
            for i, val in ipairs(value) do
                local pre = maxlen and not first and ', ' or ''
                dump_(string.format('%s[%s]', pre, i), val, maxlen,
                      level + 1, add)
                first = false
            end
        end
        -- report keys in alphabetical order to ensure repeatability
        for key, val in logging.spairs(value) do
            local pre = maxlen and not first and ', ' or ''
            -- this check can avoid an infinite loop, e.g. with metatables
            -- XXX should have more general and robust infinite loop avoidance
            if key:match('^__') and type(val) ~= 'string' then
                add(string.format('%s%s: %s', pre, key, tostring(val)))

            -- pandoc >= 2.15 includes 'tag'
            elseif not tonumber(key) and key ~= 'tag' then
                dump_(string.format('%s%s:', pre, key), val, maxlen,
                      level + 1, add)
            end
            first = false
        end
        add(string.format('%s}', indent))
    end
    return table.concat(buffer, maxlen and '' or '\n')
end

logging.dump = function(value, maxlen)
    if maxlen == nil then maxlen = 70 end
    local text = dump_(nil, value, maxlen)
    if #text > maxlen then
        text = dump_(nil, value, nil)
    end
    return text
end

logging.output = function(...)
    local need_newline = false
    for i, item in ipairs({...}) do
        -- XXX space logic could be cleverer, e.g. no space after newline
        local maybe_space = i > 1 and ' ' or ''
        local text = ({table=1, userdata=1})[type(item)] and
            logging.dump(item) or tostring(item)
        io.stderr:write(maybe_space, text)
        need_newline = text:sub(-1) ~= '\n'
    end
    if need_newline then
        io.stderr:write('\n')
    end
end

-- basic logging support (-1=errors, 0=warnings, 1=info, 2=debug, 3=debug2)
-- XXX should support string levels?
logging.loglevel = 0

-- set log level and return the previous level
logging.setloglevel = function(loglevel)
    local oldlevel = logging.loglevel
    logging.loglevel = loglevel
    return oldlevel
end

-- verbosity default is WARNING; --quiet -> ERROR and --verbose -> INFO
-- --trace sets TRACE or DEBUG (depending on --verbose)
if type(PANDOC_STATE) == 'nil' then
    -- use the default level
elseif PANDOC_STATE.trace then
    logging.loglevel = PANDOC_STATE.verbosity == 'INFO' and 3 or 2
elseif PANDOC_STATE.verbosity == 'INFO' then
    logging.loglevel = 1
elseif PANDOC_STATE.verbosity == 'WARNING' then
    logging.loglevel = 0
elseif PANDOC_STATE.verbosity == 'ERROR' then
    logging.loglevel = -1
end

logging.error = function(...)
    if logging.loglevel >= -1 then
        logging.output('(E)', ...)
    end
end

logging.warning = function(...)
    if logging.loglevel >= 0 then
        logging.output('(W)', ...)
    end
end

logging.info = function(...)
    if logging.loglevel >= 1 then
        logging.output('(I)', ...)
    end
end

logging.debug = function(...)
    if logging.loglevel >= 2 then
        logging.output('(D)', ...)
    end
end

logging.debug2 = function(...)
    if logging.loglevel >= 3 then
        logging.warning('debug2() is deprecated; use trace()')
        logging.output('(D2)', ...)
    end
end

logging.trace = function(...)
    if logging.loglevel >= 3 then
        logging.output('(T)', ...)
    end
end

-- for temporary unconditional debug output
logging.temp = function(...)
    logging.output('(#)', ...)
end
-- }}}

-- TODO(jez) Document that this overrules the --html-q-tags=true setting
-- TODO(jez) Document that this requires the `smart` extension (enabled by default for `markdown` filetype)
--
-- TODO(jez) The typeset docs are wrong: cannot include `inline-block`.
--
-- TODO(jez) Document how to pick em values for the push/pull classes
--
-- TODO(jez) You can probably write exp tests with `-t json` output after applying the filter
-- TODO(jez) Delete the logging helpers before release

-- TODO(jez) This doesn't work: you probably need two traversals:
-- One to replace all the Quoted (bottom up) then another to remove the extra
-- Spans (top down)

local function makePushPull(quote)
  local quoteKind
  if quote == '‘' then
    quoteKind = 'single'
  else
    quoteKind = 'double'
  end

  return {
    pandoc.Span({}, {class = 'push-' .. quoteKind}),
    pandoc.Span(pandoc.Str(quote), {class = 'pull-' .. quoteKind})
  }
end

local replaceQuotes = {
  Str = function (elem)
    local quote, rest = (elem.text):match('^([‘“])(.*)')
    if quote then
      local res = makePushPull(quote)
      res[#res + 1] = pandoc.Str(rest)
      return res
    else
      return elem
    end
  end,

  Quoted = function (elem)
    local leftQuote, rightQuote
    if elem.quotetype == "SingleQuote" then
      leftQuote, rightQuote = '‘', '’'
    else
      leftQuote, rightQuote = '“', '”'
    end

    local res = makePushPull(leftQuote)
    for i = 1, #elem.content do
      res[#res + 1] = elem.content[i]
    end
    res[#res + 1] = pandoc.Str(rightQuote)

    return res
  end,
}

local function removeIfPushSpan(elems, idx)
  local elem = elems[idx]
  if elem == nil or elem.tag ~= 'Span' or elem.classes == nil then
    return false
  end

  local found = false
  for _, class in ipairs(elem.classes) do
    if class == 'push-single' or class == 'push-double' then
      elems:remove(idx)
      return true
    end
  end

  return false
end

startOfLine = false
local removeLeadingPushSpans = {
  traverse = 'topdown',

  Block = function(elem)
    -- TODO(jez) Support LineBlock and DefinitionList properly.
    -- These should have `startOfLine=true`, for *every* list of inlines in
    -- them, not just the very first.
    startOfLine = true
    return elem
  end,

  -- If the quote character is at the very start of a line, with no preceding
  -- text, then the back-to-back push/pull will negate each other, meaning that
  -- a quote at the very start of a block isn't made hanging.
  --
  -- Find these cases and delete the push span, leaving only the pull span.
  Inlines = function(elems)
    if startOfLine then
      if removeIfPushSpan(elems, 1) then
        startOfLine = false
      elseif elems[1] and (
          elems[1].tag == 'Str' or
          elems[1].tag == 'Code' or
          elems[1].tag == 'Space' or
          elems[1].tag == 'Math' or
          elems[1].tag == 'RawInline' or
          elems[1].tag == 'Image') then
        startOfLine = false
      end
    end

    local idx = 1
    while idx <= #elems do
      local elem = elems[idx]
      if elem.tag == 'LineBreak' and removeIfPushSpan(elems, idx + 1) then
        -- do not increment: we removed one
      else
        idx = idx + 1
      end
    end

    return elems
  end,

  -- Image caption is a list of inlines that behaves like it were a paragraph.
  Image = function(elem)
    startOfLine = true
    return elem
  end,
}

return {
  replaceQuotes,
  removeLeadingPushSpans,
}
