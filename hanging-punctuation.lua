-- TODO(jez) Document that this overrules the --html-q-tags=true setting
--
-- TODO(jez) The typeset docs are wrong: cannot include `inline-block`.
--
-- TODO(jez) Document how to pick em values for the push/pull classes
function Quoted(elem)
  local quoteKind
  local leftQuote
  local rightQuote
  if elem.quotetype == "SingleQuote" then
    quoteKind = 'single'
    leftQuote = '‘'
    rightQuote = '’'
  else
    quoteKind = 'double'
    leftQuote = '“'
    rightQuote = '”'
  end

  local res = {
    pandoc.Span({}, {class = 'push-' .. quoteKind}),
    pandoc.Span(pandoc.Str(leftQuote), {class = 'pull-' .. quoteKind}),
    table.unpack(elem.content),
  }
  table.insert(res, pandoc.Span({}, {class = 'push-' .. quoteKind}))
  table.insert(res, pandoc.Span(pandoc.Str(rightQuote), {class = 'pull-' .. quoteKind}))
  return res
end

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

-- TODO(jez) This logic should not fire for all lists of inlines.
-- (If it did, you'd be getting things like quotes at the start of a strong not pulled.)
--
-- You're going to have to figure something else out.
-- It might help to think how you'd write this with a Sorbet TreeWalk, keeping
-- track of and resetting context as you do the traversal, so that you can track,
-- "Are we at the start of a line?" while doing the traversal.
function Inlines(elems)
  -- If the quote character is at the very start of a line, with no preceding
  -- text, then the back-to-back push/pull will negate each other, meaning that
  -- a quote at the very start of a block isn't made hanging.
  --
  -- Find these cases and delete the push span, leaving only the pull span.

  removeIfPushSpan(elems, 1)

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
end
