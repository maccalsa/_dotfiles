local R = {}

-- Utility to count a tail run of keys matching a predicate
local function tail_run(keys, pred)
  local n = 0
  for i = #keys, 1, -1 do
    if pred(keys[i].key) then
      n = n + 1
    else
      break
    end
  end
  return n
end

-- Check if key sequence contains a pattern
local function has_pattern(keys, pattern)
  local key_str = ''
  for _, k in ipairs(keys) do
    key_str = key_str .. k.key
  end
  return key_str:match(pattern) ~= nil
end

-- Check if we moved horizontally significantly
local function moved_horizontally(keys, threshold)
  local h_count = 0
  local l_count = 0
  for _, k in ipairs(keys) do
    if k.key == 'h' then h_count = h_count + 1 end
    if k.key == 'l' then l_count = l_count + 1 end
  end
  return math.abs(h_count - l_count) >= threshold
end

-- Rule 1: Repeated deletions with x/dl → suggest dw/daw
local function rule_x_spam(keys, before, after)
  local n = tail_run(keys, function(k)
    return k == 'x' or k == 'dl' or k == '\127' -- '\127' = backspace
  end)
  if n >= 3 then
    return {
      key = 'rule_x_spam',
      score = 10,
      text = 'Tip: Use operator + motion',
      example = 'Example: `dw` deletes to next word, `daw` deletes a word (incl. space)',
    }
  end
end

-- Rule 2: Excessive h/l walking → suggest f/t/w/b
local function rule_hl_walk(keys, before, after)
  local n = tail_run(keys, function(k)
    return k == 'h' or k == 'l' or k == '\u{001b}[D' or k == '\u{001b}[C' -- arrow keys
  end)
  if n >= 6 then
    return {
      key = 'rule_hl_walk',
      score = 8,
      text = 'Tip: Jump instead of walking',
      example = 'Try `f{char}` / `t{char}` or `w`/`b`/`e` to move faster',
    }
  end
end

-- Rule 3: Visual select + change → suggest ciw/ci(/ci" etc.
local function rule_visual_replace(keys, before, after)
  -- Look for visual mode entry (v/V) followed by change (c)
  local has_visual = false
  local has_change = false
  local visual_mode = nil
  
  for i, k in ipairs(keys) do
    if k.key == 'v' or k.key == 'V' or k.key == '\22' then -- \22 = Ctrl-V
      has_visual = true
      visual_mode = k.key
    end
    if has_visual and k.key == 'c' then
      has_change = true
    end
  end
  
  if has_visual and has_change then
    -- Check if we changed text inside delimiters
    local before_line = before.lines[before.row - before.from] or ''
    local after_line = after.lines[after.row - after.from] or ''
    
    if before_line:match('".-"') and after_line:match('".-"') then
      return {
        key = 'rule_visual_replace',
        score = 12,
        text = 'Tip: Use text-objects with change',
        example = 'Instead of `v...c`, try `ci"` (change inside quotes)',
      }
    elseif before_line:match("'.-'") and after_line:match("'.-'") then
      return {
        key = 'rule_visual_replace',
        score = 12,
        text = 'Tip: Use text-objects with change',
        example = "Instead of `v...c`, try `ci'` (change inside single quotes)",
      }
    elseif before_line:match('%(%(.-%)%)') or before_line:match('%b()') then
      return {
        key = 'rule_visual_replace',
        score = 12,
        text = 'Tip: Use text-objects with change',
        example = 'Instead of `v...c`, try `ci(` (change inside parentheses)',
      }
    elseif before_line:match('%[%[.-%]%]') or before_line:match('%b[]') then
      return {
        key = 'rule_visual_replace',
        score = 12,
        text = 'Tip: Use text-objects with change',
        example = 'Instead of `v...c`, try `ci[` (change inside brackets)',
      }
    elseif before_line:match('%b{}') then
      return {
        key = 'rule_visual_replace',
        score = 12,
        text = 'Tip: Use text-objects with change',
        example = 'Instead of `v...c`, try `ci{` (change inside braces)',
      }
    else
      return {
        key = 'rule_visual_replace',
        score = 11,
        text = 'Tip: Use text-objects with change',
        example = 'Instead of `v...c`, try `ciw` (change inside word)',
      }
    end
  end
end

-- Rule 4: Manual line joining → suggest J/gJ
local function rule_manual_join(keys, before, after)
  -- Check if lines were joined (fewer lines in after)
  local before_lines = #before.lines
  local after_lines = #after.lines
  
  if after_lines < before_lines then
    -- Check if user deleted newlines manually
    local has_delete = has_pattern(keys, '[xd]')
    local has_newline_delete = false
    
    -- Look for patterns like deleting at end of line
    for i, k in ipairs(keys) do
      if k.key == '$' then
        -- Check if next key is delete
        if keys[i + 1] and (keys[i + 1].key == 'x' or keys[i + 1].key == 'd') then
          has_newline_delete = true
        end
      end
    end
    
    if has_delete and (has_newline_delete or #keys >= 4) then
      return {
        key = 'rule_manual_join',
        score = 9,
        text = 'Tip: Join lines efficiently',
        example = 'Use `J` to join lines (or `gJ` to join without spaces)',
      }
    end
  end
end

-- Rule 5: Manual case changes → suggest gUw/guw/g~w
local function rule_case_change(keys, before, after)
  -- This is tricky - we'd need to detect case changes in the buffer
  -- For now, check if user manually changed case character by character
  local before_line = before.lines[before.row - before.from] or ''
  local after_line = after.lines[after.row - after.from] or ''
  
  if before_line ~= after_line then
    -- Simple heuristic: if we see many single-character changes
    local char_changes = 0
    for i = 1, math.min(#before_line, #after_line) do
      local b_char = before_line:sub(i, i)
      local a_char = after_line:sub(i, i)
      if b_char:lower() == a_char:lower() and b_char ~= a_char then
        char_changes = char_changes + 1
      end
    end
    
    if char_changes >= 3 and #keys >= char_changes then
      return {
        key = 'rule_case_change',
        score = 7,
        text = 'Tip: Change case with operators',
        example = 'Use `gUw` (uppercase word), `guw` (lowercase word), or `g~w` (toggle case)',
      }
    end
  end
end

-- Rule 6: Manual indentation → suggest >ip/<ip/=ip
local function rule_indent_manual(keys, before, after)
  -- Check if indentation changed
  local before_line = before.lines[before.row - before.from] or ''
  local after_line = after.lines[after.row - after.from] or ''
  
  local before_indent = #before_line:match('^%s*') or 0
  local after_indent = #after_line:match('^%s*') or 0
  
  if math.abs(after_indent - before_indent) > 0 then
    -- Check if user manually added/removed spaces
    local has_space_edit = has_pattern(keys, '[0I^]') -- beginning of line operations
    if has_space_edit or (#keys >= 3 and moved_horizontally(keys, 2)) then
      return {
        key = 'rule_indent_manual',
        score = 8,
        text = 'Tip: Use indent operators',
        example = 'Use `>ip` (indent paragraph), `<ip` (unindent), or `=ip` (auto-indent)',
      }
    end
  end
end

-- Rule 7: Repeat opportunity → suggest . repeat
local function rule_repeat_opportunity(keys, before, after)
  -- If user made the same change multiple times
  if #keys >= 6 then
    -- Simple heuristic: check if we see repeated patterns
    local key_str = ''
    for _, k in ipairs(keys) do
      key_str = key_str .. k.key
    end
    
    -- Look for repeated 2-3 key sequences
    for len = 2, 3 do
      for i = 1, #key_str - len * 2 do
        local pattern = key_str:sub(i, i + len - 1)
        if key_str:sub(i + len, i + len * 2 - 1) == pattern then
          return {
            key = 'rule_repeat_opportunity',
            score = 6,
            text = 'Tip: Use repeat operator',
            example = 'After making a change, use `.` to repeat it instead of typing again',
          }
        end
      end
    end
  end
end

-- Rule 8: Text object hint → detect edits inside delimiters
local function rule_text_object_hint(keys, before, after)
  local before_line = before.lines[before.row - before.from] or ''
  local after_line = after.lines[after.row - after.from] or ''
  
  if before_line == after_line then return end
  
  -- Check for edits inside quotes
  local before_quotes = before_line:match('".-"')
  local after_quotes = after_line:match('".-"')
  if before_quotes and after_quotes and before_quotes ~= after_quotes then
    return {
      key = 'rule_text_object_hint',
      score = 13,
      text = 'Tip: Change inside quotes',
      example = 'Use `ci"` to change text inside double quotes',
    }
  end
  
  local before_squotes = before_line:match("'.-'")
  local after_squotes = after_line:match("'.-'")
  if before_squotes and after_squotes and before_squotes ~= after_squotes then
    return {
      key = 'rule_text_object_hint',
      score = 13,
      text = 'Tip: Change inside quotes',
      example = "Use `ci'` to change text inside single quotes",
    }
  end
  
  -- Check for edits inside parentheses
  local before_parens = before_line:match('%b()')
  local after_parens = after_line:match('%b()')
  if before_parens and after_parens and before_parens ~= after_parens then
    return {
      key = 'rule_text_object_hint',
      score = 13,
      text = 'Tip: Change inside parentheses',
      example = 'Use `ci(` or `ci)` to change text inside parentheses',
    }
  end
  
  -- Check for edits inside brackets
  local before_brackets = before_line:match('%b[]')
  local after_brackets = after_line:match('%b[]')
  if before_brackets and after_brackets and before_brackets ~= after_brackets then
    return {
      key = 'rule_text_object_hint',
      score = 13,
      text = 'Tip: Change inside brackets',
      example = 'Use `ci[` or `ci]` to change text inside brackets',
    }
  end
  
  -- Check for edits inside braces
  local before_braces = before_line:match('%b{}')
  local after_braces = after_line:match('%b{}')
  if before_braces and after_braces and before_braces ~= after_braces then
    return {
      key = 'rule_text_object_hint',
      score = 13,
      text = 'Tip: Change inside braces',
      example = 'Use `ci{` or `ci}` to change text inside braces',
    }
  end
end

-- All rules in priority order (higher score = higher priority)
local RULES = {
  rule_text_object_hint,
  rule_visual_replace,
  rule_x_spam,
  rule_hl_walk,
  rule_indent_manual,
  rule_manual_join,
  rule_case_change,
  rule_repeat_opportunity,
}

function R.suggest(keys, before, after)
  if not keys or #keys == 0 then return nil end
  if not before or not after then return nil end
  
  local best = nil
  for _, rule in ipairs(RULES) do
    local sug = rule(keys, before, after)
    if sug and (not best or sug.score > best.score) then
      best = sug
    end
  end
  
  return best
end

return R

