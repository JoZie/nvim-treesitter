-- Binds a keybinding to smart rename definitions and usages.
-- Can be used directly using the `smart_rename` function.

local ts_utils = require'nvim-treesitter.ts_utils'
local configs = require'nvim-treesitter.configs'
local api = vim.api

local M = {}

function M.smart_rename(bufnr)
  local bufnr = bufnr or api.nvim_get_current_buf()
  local node_at_point = ts_utils.get_node_at_cursor()

  if not node_at_point then
    print('No node to rename!')
    return
  end

  local node_text = ts_utils.get_node_text(node_at_point)[1]
  local new_name = vim.fn.input('New name: ', node_text or '')

  -- Empty name cancels the interaction or ESC
  if not new_name or #new_name < 1 then return end

  local definition, scope = ts_utils.find_definition(node_at_point, bufnr)
  local nodes_to_rename = ts_utils.find_usages(node_at_point, scope)

  if not vim.tbl_contains(nodes_to_rename, node_at_point) then
    table.insert(nodes_to_rename, node_at_point)
  end

  if definition and not vim.tbl_contains(nodes_to_rename, definition) then
    table.insert(nodes_to_rename, definition)
  end

  if #nodes_to_rename < 1 then
    print('No nodes to rename!')
    return
  end

  for _, node in ipairs(nodes_to_rename) do
    local start_row, start_col, end_row, end_col = node:range() 

    local line = api.nvim_buf_get_lines(bufnr, start_row, start_row + 1, false)[1]

    if line then
      local new_line = line:sub(1, start_col) .. new_name .. line:sub(end_col + 1, -1)

      api.nvim_buf_set_lines(bufnr, start_row, start_row + 1, false, { new_line })
    end
  end
end

function M.attach(bufnr)
  local bufnr = bufnr or api.nvim_get_current_buf()

  local config = configs.get_module('refactor.smart_rename')

  for fn_name, mapping in pairs(config.keymaps) do
    local cmd = string.format([[:lua require'nvim-treesitter.refactor.smart_rename'.%s(%d)<CR>]], fn_name, bufnr)

    api.nvim_buf_set_keymap(bufnr, 'n', mapping, cmd, { silent = true })
  end
end

function M.detach(bufnr)
  local buf = bufnr or api.nvim_get_current_buf()
  local config = configs.get_module('refactor.smart_rename')

  for fn_name, mapping in pairs(config.keymaps) do
    api.nvim_buf_del_keymap(bufnr, 'n', mapping)
  end
end

return M
