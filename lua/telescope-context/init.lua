local M = {}

local has_telescope, _ = pcall(require, 'telescope')
if not has_telescope then
  error('telescope-context: telescope.nvim is required')
end

local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local conf = require('telescope.config').values
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')


-- ---------------- data ----------------

local contexts = {}

local last_context = nil

local function get_cursor_loc()
  local pos = vim.api.nvim_win_get_cursor(0)
  return {
    file = vim.api.nvim_buf_get_name(0),
    line = pos[1],
    col = pos[2] + 1,
  }
end

-- ---------------- core ----------------

function M.create_context(name)
  if contexts[name] then
    vim.notify('Context exists: ' .. name)
    return
  end
  contexts[name] = {}
  vim.notify('Created context: ' .. name)
end

function M.delete_context(name)
  contexts[name] = nil
  vim.notify('Deleted context: ' .. name)
end

function M.add_location(ctx, locname)
  if not contexts[ctx] then
    vim.notify('No such context: ' .. ctx, vim.log.levels.ERROR)
    return
  end

  local loc = get_cursor_loc()
  loc.name = locname
  table.insert(contexts[ctx], loc)

  vim.notify(string.format('Added location to %s → %s', ctx, locname))
end


-- ---------------- telescope: contexts ----------------

function M.telescope_contexts(opts)
  opts = opts or {}

  local names = {}
  for k,_ in pairs(contexts) do table.insert(names, k) end
  table.sort(names)

  pickers.new(opts, {
    prompt_title = 'Contexts',
    finder = finders.new_table { results = names },
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local sel = action_state.get_selected_entry()
        if sel then
          M.telescope_locations(sel[1])
        end
      end)

      map('i', '<C-d>', function()
        local sel = action_state.get_selected_entry()
        if sel then
          contexts[sel[1]] = nil
          actions.close(prompt_bufnr)
          vim.schedule(M.telescope_contexts)
        end
      end)

      return true
    end,
  }):find()
end


-- ---------------- telescope: locations ----------------

function M.telescope_locations(ctx, opts)
  opts = opts or {}
  local c = contexts[ctx]

  if not c then
    vim.notify('No such context: ' .. ctx, vim.log.levels.ERROR)
    return
  end

  last_context = ctx  -- track last used context

  local items = {}
  for i,loc in ipairs(c) do
    table.insert(items, {
      display = string.format('%s — %s:%d', loc.name, vim.fn.fnamemodify(loc.file, ':t'), loc.line),
      ordinal = loc.name .. ' ' .. loc.file,
      value = loc,
      idx = i,
    })
  end

  pickers.new(opts, {
    prompt_title = 'Locations: ' .. ctx,
    finder = finders.new_table {
      results = items,
      entry_maker = function(e) return e end,
    },
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local sel = action_state.get_selected_entry()
        if not sel then return end
        local loc = sel.value
        vim.cmd('edit ' .. loc.file)
        vim.api.nvim_win_set_cursor(0, {loc.line, loc.col-1})
      end)

      map('i', '<C-d>', function()
        local sel = action_state.get_selected_entry()
        if sel then
          table.remove(c, sel.idx)
          actions.close(prompt_bufnr)
          vim.schedule(function()
            M.telescope_locations(ctx)
          end)
        end
      end)

      return true
    end,
  }):find()
end


-- ---------------- commands ----------------

function M.setup()
  vim.api.nvim_create_user_command('CtxCreate', function(opts)
    M.create_context(opts.args)
  end, { nargs = 1 })

  vim.api.nvim_create_user_command('CtxDelete', function(opts)
    M.delete_context(opts.args)
  end,
  { nargs = 1 ,
    complete = function(arg_lead, cmd_line, cursor_pos)
      local t = {}
      for name,_ in pairs(contexts) do
        if name:match("^" .. arg_lead) then
          table.insert(t, name)
        end
      end
      return t
    end
  })

  vim.api.nvim_create_user_command('CtxAdd', function(opts)
    local a = vim.split(opts.args, ' ')
    if #a < 2 then
      vim.notify('Usage: CtxAdd <context> <name>', vim.log.levels.ERROR)
      return
    end
    local ctx = a[1]
    local name = table.concat(a, ' ', 2)
    M.add_location(ctx, name)
  end, {
    nargs = '+',
    complete = function(arg_lead, cmd_line, cursor_pos)
      local split_args = vim.split(cmd_line, " ")
      if #split_args <= 2 then
        -- completing the first argument (context name)
        local t = {}
        for name,_ in pairs(contexts) do
          if name:match("^" .. arg_lead) then
            table.insert(t, name)
          end
        end
        return t
      else
        return {}
      end
    end
  })

  vim.api.nvim_create_user_command('CtxLs', function(opts)
    if opts.args == nil or opts.args == "" then
      M.telescope_contexts()
    else
      M.telescope_locations(opts.args)
    end
  end,
  {
    nargs = '?',
    complete = function(arg_lead, cmd_line, cursor_pos)
      local t = {}
      for name,_ in pairs(contexts) do
        if name:match("^" .. arg_lead) then
          table.insert(t, name)
        end
      end
      return t
    end
  })

  vim.api.nvim_create_user_command("CtxLast", function()
    if last_context then
      M.telescope_locations(last_context)
    else
      vim.notify("No recently used context", vim.log.levels.WARN)
    end
  end, {})

end

return M
