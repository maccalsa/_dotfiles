local nvim_java_min_version = { major = 0, minor = 11, patch = 5 }

local function version_at_least(min_version)
  local version = vim.version()

  if version.major ~= min_version.major then
    return version.major > min_version.major
  end

  if version.minor ~= min_version.minor then
    return version.minor > min_version.minor
  end

  return version.patch >= min_version.patch
end

local function warn_nvim_java_version()
  local version = vim.version()
  local current_version = string.format('%d.%d.%d', version.major, version.minor, version.patch)

  vim.notify(
    'nvim-java requires Neovim 0.11.5+. Current version is ' .. current_version .. '. Upgrade Neovim to enable Java/Spring Boot IDE support.',
    vim.log.levels.WARN,
    { title = 'nvim-java' }
  )
end

local function has_nvim_java_version()
  return version_at_least(nvim_java_min_version)
end

return {
  {
    'nvim-java/nvim-java',
    ft = 'java',
    cond = has_nvim_java_version,
    dependencies = {
      'JavaHello/spring-boot.nvim',
      'MunifTanjim/nui.nvim',
      'mfussenegger/nvim-dap',
    },
    init = function()
      if has_nvim_java_version() then
        return
      end

      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'java',
        once = true,
        callback = warn_nvim_java_version,
      })
    end,
    config = function()
      require('java').setup {
        jdk = {
          auto_install = false,
        },
        spring_boot_tools = {
          enable = true,
        },
        java_test = {
          enable = true,
        },
        java_debug_adapter = {
          enable = true,
        },
      }

      vim.lsp.enable 'jdtls'

      vim.keymap.set('n', '<leader>Jb', '<cmd>JavaBuildBuildWorkspace<cr>', { desc = 'Java: Build workspace' })
      vim.keymap.set('n', '<leader>JB', '<cmd>JavaBuildCleanWorkspace<cr>', { desc = 'Java: Clean workspace' })
      vim.keymap.set('n', '<leader>Jr', '<cmd>JavaRunnerRunMain<cr>', { desc = 'Java: Run main/Spring app' })
      vim.keymap.set('n', '<leader>JR', '<cmd>JavaRunnerStopMain<cr>', { desc = 'Java: Stop running app' })
      vim.keymap.set('n', '<leader>Jl', '<cmd>JavaRunnerToggleLogs<cr>', { desc = 'Java: Toggle app logs' })
      vim.keymap.set('n', '<leader>Jp', '<cmd>JavaProfile<cr>', { desc = 'Java: Profiles UI' })
      vim.keymap.set('n', '<leader>Jd', '<cmd>JavaDapConfig<cr>', { desc = 'Java: Configure debugger' })
      vim.keymap.set('n', '<leader>Jt', '<cmd>JavaTestRunCurrentMethod<cr>', { desc = 'Java: Test method' })
      vim.keymap.set('n', '<leader>JT', '<cmd>JavaTestRunCurrentClass<cr>', { desc = 'Java: Test class' })
      vim.keymap.set('n', '<leader>Ja', '<cmd>JavaTestRunAllTests<cr>', { desc = 'Java: Test all' })
      vim.keymap.set('n', '<leader>Jv', '<cmd>JavaTestViewLastReport<cr>', { desc = 'Java: View test report' })
      vim.keymap.set('n', '<leader>JC', '<cmd>JavaSettingsChangeRuntime<cr>', { desc = 'Java: Change runtime' })
      vim.keymap.set({ 'n', 'v' }, '<leader>Jre', '<cmd>JavaRefactorExtractVariable<cr>', { desc = 'Java: Extract variable' })
      vim.keymap.set({ 'n', 'v' }, '<leader>Jrc', '<cmd>JavaRefactorExtractConstant<cr>', { desc = 'Java: Extract constant' })
      vim.keymap.set({ 'n', 'v' }, '<leader>Jrm', '<cmd>JavaRefactorExtractMethod<cr>', { desc = 'Java: Extract method' })
    end,
  },
}
