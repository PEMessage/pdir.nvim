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

function M.open_breadcrumb()
    local cwd = vim.fn.getcwd()
    local segments = {}
    for segment in cwd:gmatch("[^/]+") do
        table.insert(segments, segment)
    end

    -- Create floating window buffer
    local bufnr = vim.api.nvim_create_buf(false, true)
    local win_width = math.min(#cwd + 10, vim.o.columns - 4)
    local win = vim.api.nvim_open_win(bufnr, true, {
        relative = "editor",
        width = win_width,
        height = 1,
        row = math.floor(vim.o.lines / 2),
        col = math.floor((vim.o.columns - win_width) / 2),
        style = "minimal",
        border = "rounded",
        title = " Select Parent Directory ",
        title_pos = "center"
    })

    local ns_id = vim.api.nvim_create_namespace("pdir_path")

    local state = {
        segments = segments,
        current_idx = #segments,
        bufnr = bufnr,
        win = win,
        ns_id = ns_id
    }

    state.render = function()
        -- 1. Assemble the full path string
        local line_text = "/" .. table.concat(state.segments, "/")
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { line_text })
        vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

        -- 2. Calculate the start column of the current segment
        local start_col = 0
        for i = 1, state.current_idx - 1 do
            -- Length of segment + 1 for the "/"
            start_col = start_col + #state.segments[i] + 1
        end

        -- 3. Calculate end column (start + separator + segment length)
        local end_col = start_col + #state.segments[state.current_idx] + 1

        -- 4. Apply highlight only to the calculated range
        vim.api.nvim_buf_add_highlight(bufnr, ns_id, "IncSearch", 0, start_col, end_col)
    end

    -- Apply keybindings from config
    for key, action_fn in pairs(M.config.keys) do
        vim.keymap.set("n", key, function()
            action_fn(state)
        end, { buffer = bufnr, silent = true })
    end

    state.render()
end

return M
