local R = {}
local logger = require('keycoach.logger')

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
  logger.log('RULE', 'rule_x_spam evaluated', { tail_run = n, threshold = 3, matched = n >= 3 })
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
  -- Count h/l keys (including arrow keys which come as escape sequences)
  local h_count = 0
  local l_count = 0
  local consecutive_hl = 0
  local max_consecutive = 0
  
  -- Helper to check if a key is an arrow key
  local function is_arrow_key(k)
    if not k or k == '' then return false, nil end
    
    -- Direct h/l keys
    if k == 'h' then return true, 'left' end
    if k == 'l' then return true, 'right' end
    
    -- Check for escape sequences
    local first_byte = k:byte(1)
    if first_byte == 27 then
      -- Full escape sequence: \x1b[D (left) or \x1b[C (right)
      if k:find('%[D') or k:find('OD') then
        return true, 'left'
      elseif k:find('%[C') or k:find('OC') then
        return true, 'right'
      end
    end
    
    -- Check for partial sequences that might be arrow keys
    -- Left arrow often contains 'D', right arrow contains 'C'
    -- The weird characters (��,) might be partial sequences
    if k:find('D') or k:find('%,') then -- Left arrow patterns
      -- Check if it looks like an arrow key sequence
      local has_escape_chars = false
      for i = 1, math.min(#k, 3) do
        local b = k:byte(i)
        if b and (b == 27 or b > 127) then
          has_escape_chars = true
          break
        end
      end
      if has_escape_chars then
        return true, 'left'
      end
    elseif k:find('C') or k:find('%.') then -- Right arrow patterns
      local has_escape_chars = false
      for i = 1, math.min(#k, 3) do
        local b = k:byte(i)
        if b and (b == 27 or b > 127) then
          has_escape_chars = true
          break
        end
      end
      if has_escape_chars then
        return true, 'right'
      end
    end
    
    -- Check for bracket sequences
    if k:match('^%[D') then return true, 'left' end
    if k:match('^%[C') then return true, 'right' end
    
    return false, nil
  end
  
  for i, key_entry in ipairs(keys) do
    local k = key_entry.key
    local is_arrow, direction = is_arrow_key(k)
    
    if is_arrow then
      if direction == 'left' or k == 'h' then
        h_count = h_count + 1
        consecutive_hl = consecutive_hl + 1
        max_consecutive = math.max(max_consecutive, consecutive_hl)
      elseif direction == 'right' or k == 'l' then
        l_count = l_count + 1
        consecutive_hl = consecutive_hl + 1
        max_consecutive = math.max(max_consecutive, consecutive_hl)
      end
    else
      -- Reset consecutive count for non-movement keys
      -- But don't reset for command mode (:) or other navigation
      local first_byte = k:byte(1)
      if k ~= ':' and k ~= '<CR>' and not (first_byte == 27) then
        consecutive_hl = 0
      end
    end
  end
  
  -- Also check tail run as fallback (including arrow keys)
  local tail_n = tail_run(keys, function(k)
    if k == 'h' or k == 'l' then return true end
    local is_arr, _ = is_arrow_key(k)
    return is_arr
  end)
  
  local total_hl = h_count + l_count
  -- Match if: 4+ consecutive h/l (lowered threshold), 4+ tail run, or 6+ total h/l keys (lowered)
  local should_match = max_consecutive >= 4 or tail_n >= 4 or total_hl >= 6
  
  logger.log('RULE', 'rule_hl_walk evaluated', {
    h_count = h_count,
    l_count = l_count,
    total_hl = total_hl,
    max_consecutive = max_consecutive,
    tail_run = tail_n,
    threshold = 4,
    matched = should_match,
    sample_keys = vim.tbl_map(function(ke) 
      return ke.key:gsub('%c', function(c) return string.format('\\x%02x', string.byte(c)) end)
    end, {keys[#keys-2], keys[#keys-1], keys[#keys]} or {}),
  })
  
  if should_match then
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
  -- Try to detect visual+change pattern from keys (v/V followed by c)
  -- Note: Visual mode keys may not be captured, so we also check buffer changes
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
  
  -- Also detect by pattern: if we see 'v' or 'V' in keys, and then significant changes
  -- This helps when visual mode keys aren't fully captured
  if not has_visual then
    for _, k in ipairs(keys) do
      if k.key == 'v' or k.key == 'V' or k.key == '\22' then
        has_visual = true
        break
      end
    end
    -- If we saw 'v' and have changes, likely visual+change
    if has_visual and #keys >= 3 then
      has_change = true
    end
  end
  
  if has_visual and has_change then
    -- Get current cursor line (1-indexed row, 0-indexed from)
    -- lines array is 0-indexed relative to from, so row - from gives us the index
    local before_idx = before.row - before.from
    local after_idx = after.row - after.from
    local before_line = before.lines[before_idx] or ''
    local after_line = after.lines[after_idx] or ''
    
    -- Also check surrounding lines in case selection spanned multiple lines
    for i = math.max(1, before_idx - 1), math.min(#before.lines, before_idx + 1) do
      local bl = before.lines[i] or ''
      local al = after.lines[math.min(i, #after.lines)] or ''
      
      if bl:match('".-"') and al:match('".-"') then
        return {
          key = 'rule_visual_replace',
          score = 12,
          text = 'Tip: Use text-objects with change',
          example = 'Instead of `v...c`, try `ci"` (change inside quotes)',
        }
      elseif bl:match("'.-'") and al:match("'.-'") then
        return {
          key = 'rule_visual_replace',
          score = 12,
          text = 'Tip: Use text-objects with change',
          example = "Instead of `v...c`, try `ci'` (change inside single quotes)",
        }
      elseif bl:match('%b()') then
        return {
          key = 'rule_visual_replace',
          score = 12,
          text = 'Tip: Use text-objects with change',
          example = 'Instead of `v...c`, try `ci(` (change inside parentheses)',
        }
      elseif bl:match('%b[]') then
        return {
          key = 'rule_visual_replace',
          score = 12,
          text = 'Tip: Use text-objects with change',
          example = 'Instead of `v...c`, try `ci[` (change inside brackets)',
        }
      elseif bl:match('%b{}') then
        return {
          key = 'rule_visual_replace',
          score = 12,
          text = 'Tip: Use text-objects with change',
          example = 'Instead of `v...c`, try `ci{` (change inside braces)',
        }
      end
    end
    
    -- Generic visual replace suggestion
    return {
      key = 'rule_visual_replace',
      score = 11,
      text = 'Tip: Use text-objects with change',
      example = 'Instead of `v...c`, try `ciw` (change inside word)',
    }
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
    
    -- Look for patterns like deleting at end of line ($x, $d, $X)
    -- Or deleting newline with d$ or similar
    for i, k in ipairs(keys) do
      if k.key == '$' then
        -- Check if next key is delete
        if keys[i + 1] and (keys[i + 1].key == 'x' or keys[i + 1].key == 'd' or keys[i + 1].key == 'X') then
          has_newline_delete = true
        end
      elseif k.key == 'd' and keys[i + 1] and keys[i + 1].key == '$' then
        has_newline_delete = true
      elseif k.key == 'X' and i > 1 and keys[i - 1].key == '$' then
        has_newline_delete = true
      end
    end
    
    -- Also check if we see multiple delete operations that could join lines
    local delete_count = 0
    for _, k in ipairs(keys) do
      if k.key == 'x' or k.key == 'X' or k.key == 'd' then
        delete_count = delete_count + 1
      end
    end
    
    -- Trigger if: explicit newline delete pattern, or multiple deletes with enough keys
    if has_delete and (has_newline_delete or (delete_count >= 2 and #keys >= 3)) then
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
  -- Detect case changes: look for 'r' (replace) pattern followed by case changes
  local has_replace_pattern = false
  local replace_count = 0
  
  -- Check for r{char} patterns where char is uppercase/lowercase
  for i, k in ipairs(keys) do
    if k.key == 'r' and keys[i + 1] then
      local next_key = keys[i + 1].key
      -- Check if next char is a letter (case change)
      if next_key:match('^[A-Za-z]$') then
        has_replace_pattern = true
        replace_count = replace_count + 1
      end
    end
  end
  
  -- Also check buffer for case-only changes
  local before_idx = before.row - before.from
  local after_idx = after.row - after.from
  local before_line = before.lines[before_idx] or ''
  local after_line = after.lines[after_idx] or ''
  
  if before_line ~= after_line then
    local char_changes = 0
    -- Count case-only changes (same letter, different case)
    for i = 1, math.min(#before_line, #after_line) do
      local b_char = before_line:sub(i, i)
      local a_char = after_line:sub(i, i)
      if b_char:match('%a') and a_char:match('%a') and b_char:lower() == a_char:lower() and b_char ~= a_char then
        char_changes = char_changes + 1
      end
    end
    
    -- Trigger if: 3+ case changes detected AND (we see r pattern OR enough keys for manual changes)
    if char_changes >= 3 then
      -- If we see r pattern, that's a strong signal
      if has_replace_pattern and replace_count >= 2 then
        return {
          key = 'rule_case_change',
          score = 7,
          text = 'Tip: Change case with operators',
          example = 'Use `gUw` (uppercase word), `guw` (lowercase word), or `g~w` (toggle case)',
        }
      -- Or if we have many keys suggesting manual character-by-character changes
      elseif #keys >= char_changes * 2 then
        return {
          key = 'rule_case_change',
          score = 7,
          text = 'Tip: Change case with operators',
          example = 'Use `gUw` (uppercase word), `guw` (lowercase word), or `g~w` (toggle case)',
        }
      end
    end
  end
end

-- Rule 6: Manual indentation → suggest >ip/<ip/=ip
local function rule_indent_manual(keys, before, after)
  -- Check if indentation changed on current or nearby lines
  local before_idx = before.row - before.from
  local after_idx = after.row - after.from
  
  -- Check current line and a few nearby lines
  local indent_changed = false
  local indent_diff = 0
  
  for i = math.max(1, before_idx - 2), math.min(#before.lines, before_idx + 2) do
    local before_line = before.lines[i] or ''
    local after_line = after.lines[math.min(i, #after.lines)] or ''
    
    local before_indent = #(before_line:match('^%s*') or '')
    local after_indent = #(after_line:match('^%s*') or '')
    
    if math.abs(after_indent - before_indent) > 0 then
      indent_changed = true
      indent_diff = math.abs(after_indent - before_indent)
      break
    end
  end
  
  if indent_changed then
    -- Check if user manually added/removed spaces
    -- Look for: 0 (beginning), I (insert at start), ^ (start of text), or space/backspace at start
    local has_space_edit = has_pattern(keys, '[0I^]')
    
    -- Check for space/backspace keys at beginning of operations
    local has_space_keys = false
    for i, k in ipairs(keys) do
      if k.key == ' ' or k.key == '\127' then -- space or backspace
        -- Check if we're at start of line (previous key was 0, ^, or I)
        if i > 1 and (keys[i - 1].key == '0' or keys[i - 1].key == '^' or keys[i - 1].key == 'I') then
          has_space_keys = true
        end
      end
    end
    
    -- Only trigger if manual editing detected (not operator-based like >> or <<)
    local has_indent_operator = has_pattern(keys, '[<>]')
    
    if (has_space_edit or has_space_keys) and not has_indent_operator and #keys >= 2 then
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
-- Only trigger if user is doing inefficient edits (not already using text objects)
local function rule_text_object_hint(keys, before, after)
  -- Skip if user is already using text objects (ci", ci(, etc.)
  local key_str = ''
  for _, k in ipairs(keys) do
    key_str = key_str .. k.key
  end
  
  -- Check for efficient patterns - if user already used text objects, don't suggest
  if key_str:match('ci["\'%(%)%[%]{}]') or 
     key_str:match('ca["\'%(%)%[%]{}]') or
     key_str:match('di["\'%(%)%[%]{}]') or
     key_str:match('da["\'%(%)%[%]{}]') or
     key_str:match('vi["\'%(%)%[%]{}]') or
     key_str:match('va["\'%(%)%[%]{}]') then
    return nil
  end
  
  -- Skip if user used visual mode + change (rule 3 handles this)
  if key_str:match('v.*c') or key_str:match('V.*c') then
    return nil
  end
  
  local before_idx = before.row - before.from
  local after_idx = after.row - after.from
  local before_line = before.lines[before_idx] or ''
  local after_line = after.lines[after_idx] or ''
  
  if before_line == after_line then return end
  
  -- Only trigger if we see inefficient editing patterns (many single-character edits)
  -- This suggests manual character-by-character editing rather than text objects
  local is_inefficient = false
  if #keys >= 4 then
    -- Count single-character insertions/deletions
    local single_char_ops = 0
    for _, k in ipairs(keys) do
      if k.key:match('^[a-zA-Z0-9]$') or k.key == 'x' or k.key == 'X' or k.key == '\127' then
        single_char_ops = single_char_ops + 1
      end
    end
    -- If more than half the keys are single-char operations, it's inefficient
    if single_char_ops >= math.max(3, #keys * 0.4) then
      is_inefficient = true
    end
  end
  
  -- Check for edits inside quotes
  local before_quotes = before_line:match('".-"')
  local after_quotes = after_line:match('".-"')
  if before_quotes and after_quotes and before_quotes ~= after_quotes and is_inefficient then
    return {
      key = 'rule_text_object_hint',
      score = 13,
      text = 'Tip: Change inside quotes',
      example = 'Use `ci"` to change text inside double quotes',
    }
  end
  
  local before_squotes = before_line:match("'.-'")
  local after_squotes = after_line:match("'.-'")
  if before_squotes and after_squotes and before_squotes ~= after_squotes and is_inefficient then
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
  if before_parens and after_parens and before_parens ~= after_parens and is_inefficient then
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
  if before_brackets and after_brackets and before_brackets ~= after_brackets and is_inefficient then
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
  if before_braces and after_braces and before_braces ~= after_braces and is_inefficient then
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
  if not keys or #keys == 0 then
    logger.log('RULES', 'No keys to evaluate')
    return nil
  end
  if not before or not after then
    logger.log('RULES', 'Missing before/after snapshots', { has_before = before ~= nil, has_after = after ~= nil })
    return nil
  end
  
  logger.log('RULES', 'Evaluating all rules', {
    num_rules = #RULES,
    num_keys = #keys,
    before_lines = #before.lines,
    after_lines = #after.lines,
  })
  
  local best = nil
  local evaluated = {}
  for i, rule in ipairs(RULES) do
    local rule_name = RULES[i] and tostring(RULES[i]):match('function: (.+)') or ('rule_' .. i)
    local sug = rule(keys, before, after)
    evaluated[rule_name] = sug ~= nil
    if sug and (not best or sug.score > best.score) then
      best = sug
      logger.log('RULES', 'New best suggestion', { rule = rule_name, score = sug.score })
    end
  end
  
  logger.log('RULES', 'Rule evaluation complete', {
    best_rule = best and best.key or nil,
    best_score = best and best.score or nil,
    evaluated = evaluated,
  })
  
  return best
end

return R

