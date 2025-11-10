local C = {}

-- Default configuration
local defaults = {
  enabled = true, -- KeyCoach enabled by default
  logging_enabled = true, -- Logging disabled by default (to avoid interrupting editing)
  logging_notify = false, -- Don't show notifications for logs (only store in buffer)
  hint_cooldown = 2000, -- 2 seconds between hints
}

-- User configuration (can be overridden)
local config = vim.deepcopy(defaults)

-- Setup function to allow users to configure KeyCoach
function C.setup(user_config)
  user_config = user_config or {}
  config = vim.tbl_deep_extend('force', defaults, user_config)
end

-- Get current config
function C.get()
  return config
end

-- Get a specific config value
function C.get_value(key)
  return config[key]
end

return C

