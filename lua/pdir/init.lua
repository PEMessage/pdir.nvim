local M = {}
local actions = require("pdir.actions")

-- Default Configuration
M.config = {
    keys = {
        ["<Left>"]  = actions.left,
        ["<Right>"] = actions.right,
        ["<CR>"]    = actions.confirm,
        ["<Esc>"]   = actions.close,
        ["<C-c>"]   = actions.close,
    }
}

function M.setup(user_config)
    if user_config and user_config.keys then
        M.config.keys = vim.tbl_extend("force", M.config.keys, user_config.keys)
    end
end

function M.open_parent()
    local pwd = vim.fn.getcwd()
    M.open_breadcrumb(pwd, -1)
end

function M.open_breadcrumb(path, initial_idx)
    local segments = {}
    for segment in path:gmatch("[^/]+") do
        table.insert(segments, segment)
    end

    if #segments == 0 then return end

    -- Normalize initial_idx using modulo math
    -- Lua is 1-indexed, so we use (idx - 1) % len + 1
    local current_idx = ((initial_idx - 1) % #segments) + 1

    local bufnr = vim.api.nvim_create_buf(false, true)
    local win_width = math.min(#path + 10, vim.o.columns - 4)
    local win = vim.api.nvim_open_win(bufnr, true, {
        relative = "editor",
        width = win_width,
        height = 1,
        row = math.floor(vim.o.lines / 2),
        col = math.floor((vim.o.columns - win_width) / 2),
        style = "minimal",
        border = "rounded",
        title = " Select Directory ",
        title_pos = "center"
    })

    local ns_id = vim.api.nvim_create_namespace("pdir_path")

    local state = {
        segments = segments,
        current_idx = current_idx,
        bufnr = bufnr,
        win = win,
        ns_id = ns_id
    }

    state.render = function()
        local line_text = "/" .. table.concat(state.segments, "/")
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { line_text })
        vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

        -- Calculate highlight bounds
        local start_col = 0
        for i = 1, state.current_idx - 1 do
            start_col = start_col + #state.segments[i] + 1
        end
        local end_col = start_col + #state.segments[state.current_idx] + 1

        vim.api.nvim_buf_add_highlight(bufnr, ns_id, "IncSearch", 0, start_col, end_col)
    end

    -- Bind keys
    for key, action_fn in pairs(M.config.keys) do
        vim.keymap.set("n", key, function()
            action_fn(state)
        end, { buffer = bufnr, silent = true })
    end

    state.render()
end

return M
