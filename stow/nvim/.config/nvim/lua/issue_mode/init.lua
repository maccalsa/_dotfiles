-- Issue mode helpers: modified tracked files, grep modified, telescope picker
local M = {}

function M.git_root()
  local handle = io.popen("git rev-parse --show-toplevel 2>/dev/null")
  if not handle then
    return nil
  end
  local result = handle:read("*a")
  handle:close()
  result = result:gsub("%s+$", "")
  if result == "" then
    return nil
  end
  return result
end

function M.read_command_lines(cmd)
  local handle = io.popen(cmd)
  if not handle then
    return {}
  end
  local output = handle:read("*a")
  handle:close()
  local lines = {}
  for line in output:gmatch("[^\r\n]+") do
    table.insert(lines, line)
  end
  return lines
end

function M.tracked_changed_and_staged_files()
  local root = M.git_root()
  if not root then
    vim.notify("Not inside a git repository", vim.log.levels.WARN)
    return {}
  end
  local unstaged = M.read_command_lines("git -C " .. vim.fn.shellescape(root) .. " diff --name-only")
  local staged = M.read_command_lines("git -C " .. vim.fn.shellescape(root) .. " diff --cached --name-only")
  local seen = {}
  local merged = {}
  for _, file in ipairs(unstaged) do
    if not seen[file] then
      seen[file] = true
      table.insert(merged, file)
    end
  end
  for _, file in ipairs(staged) do
    if not seen[file] then
      seen[file] = true
      table.insert(merged, file)
    end
  end
  return merged
end

function M.open_modified_files()
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local previewers = require("telescope.previewers")
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  local items = M.tracked_changed_and_staged_files()
  if #items == 0 then
    vim.notify("No tracked changed/staged files", vim.log.levels.INFO)
    return
  end

  pickers.new({}, {
    prompt_title = "Modified Tracked Files",
    finder = finders.new_table({ results = items }),
    sorter = conf.file_sorter({}),
    previewer = previewers.cat.new({}),
    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if not selection then
          return
        end
        vim.cmd("edit " .. vim.fn.fnameescape(selection[1]))
      end)
      return true
    end,
  }):find()
end

function M.grep_modified_files()
  local builtin = require("telescope.builtin")
  local files = M.tracked_changed_and_staged_files()
  if #files == 0 then
    vim.notify("No tracked changed/staged files", vim.log.levels.INFO)
    return
  end
  builtin.live_grep({
    prompt_title = "Live Grep Modified Files",
    grep_open_files = false,
    search_dirs = files,
  })
end

return M
