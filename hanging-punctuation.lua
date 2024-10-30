-- TODO(jez) Document that this overrules the --html-q-tags=true setting
-- TODO(jez) Document that this requires the `smart` extension (enabled by default for `markdown` filetype)
-- TODO(jez) Document how to pick em values for the push/pull classes
--
-- TODO(jez) The typeset docs are wrong: cannot include `inline-block`.
--
-- TODO(jez) You can probably write exp tests with `-t json` output after applying the filter
-- On second thought, `-t html --wrap=preserve` seems to be basically good enough
--
-- TODO(jez) pandoc filter that reimplements markdoc-style tables

-- Make the spans which push and pull quotes around ----------------------- {{{
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

local LEFT_SINGLE_QUOTATION_MARK = 0x2018
local LEFT_DOUBLE_QUOTATION_MARK = 0x201C

local replaceQuotes = {
  Str = function (elem)
    if #elem.text == 0 then
      return elem
    end

    -- lua patterns basically don't work on utf8 characters, so we have to use
    -- the utf8 library functions directly to do what we're trying to do.
    firstChar = utf8.codepoint(elem.text, 1, 1)
    if firstChar == LEFT_SINGLE_QUOTATION_MARK then
      local quote = '‘'
    elseif firstChar == LEFT_DOUBLE_QUOTATION_MARK then
      local quote = '“'
    else
      return elem
    end

    local res = makePushPull(quote)
    res[#res + 1] = pandoc.Str(elem.text:sub(utf8.offset(elem.text, 2)))

    return res
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
-- }}}

-- Remove any push span at the start of a line. --------------------------- {{{
--
-- If a quote character is at the very start of a line, with no preceding text,
-- then the back-to-back push/pull will negate each other, meaning that a quote
-- at the very start of a block isn't made to hang.

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

local function recurseInlines(inlines, idx)
  if idx > #inlines then
    return
  end

  if not removeIfPushSpan(inlines, idx) then
    local tag = inlines[idx].tag
    if (tag == 'Emph' or
        tag == 'Underline' or
        tag == 'Strong' or
        tag == 'Strikeout' or
        tag == 'SmallCaps' or
        tag == 'Link' or
        tag == 'Span') then
      recurseInlines(inlines[idx].content, 1)
    end
    -- Other cases:
    --
    -- Do not contain Inline elements, don't need to recurse
    --
    --     Str(Text)
    --     Space
    --     SoftBreak
    --     LineBreak
    --     Math(MathType Text)
    --     RawInline(Format Text)
    --     Code(Attr Text)
    --
    -- Do not need to handle this, because it will be handled by the walk.
    --
    --     Note([Block])
    --
    -- Don't need to handle because these will have already been removed.
    --
    --     Quoted(QuoteType [Inline])
    --
    -- Choosing to ignore these for now. Might not even want to have the first
    -- walk transform inside these elements. If this ever comes up in practice,
    -- we'll probably just want to disable the hanging via CSS.
    --
    --     Superscript([Inline])
    --     Subscript([Inline])
    --
    -- TODO(jez) Consider handling these? Maybe it doesn't matter?
    --
    --     Cite([Citation] [Inline])
    --     Image(Attr [Inline] Target)
  end

  idx = idx + 1
  -- while loop so that we compute #inlines on every loop in case it shrinks
  while idx <= #inlines do
    if inlines[idx].tag == 'LineBreak' then
      recurseInlines(inlines, idx + 1)
    end
    idx = idx + 1
  end
end

local removeLeadingPushSpans = {
  traverse = 'topdown',

  Plain = function(elem)
    recurseInlines(elem.content, 1)
    return elem
  end,
  Para = function(elem)
    recurseInlines(elem.content, 1)
    return elem
  end,
  Header = function(elem)
    recurseInlines(elem.content, 1)
    return elem
  end,

  -- Support for Panodc's `line_blocks` extension, which is conceptually a
  -- bunch of Inlines with `LineBreaks` between each one
  --
  -- <https://pandoc.org/MANUAL.html#line-blocks>
  LineBlock = function(elem)
    for i = 1, #elem.content do
      recurseInlines(elem.content[i], 1)
    end
    return elem
  end,

  DefinitionList = function(elem)
    for i = 1, #elem.content do
      -- Only have to recurse over the DefinitionList's Inlines.
      -- The nested Block elements will get handled by recursion.
      recurseInlines(elem.content[i][1], 1)
    end
    return elem
  end,

  -- Other cases:
  --
  -- Don't need to handle these, because they don't contain Blocks or Inlines:
  --
  --     CodeBlock
  --     RawBlock
  --     HorizonalRule
  --
  -- Don't need to handle these, because they are handled by the recursion:
  --
  --     BlockQuote
  --     Figure
  --     Div
  --
  -- Don't handle these, because we leave them to be handled in CSS.
  --
  --     OrderedList
  --     BulletList
  --     Table
}
-- }}}

return {
  replaceQuotes,
  removeLeadingPushSpans,
}
-- vim:fdm=marker
