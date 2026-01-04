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
    M.open_breadcrumb(pwd, -2)
end

function M.open_breadcrumb(path, initial_idx)
    -- Using trimempty = false to preserve structure
    local segments = vim.split(path, "/", { trimempty = false })

    if #segments == 0 then return end

    -- Normalize initial_idx using modulo math
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
        local display_segments = {}
        local highlight_start = 0
        local highlight_end = 0
        local current_pos = 0

        for i, segment in ipairs(state.segments) do
            local text = segment

            -- Only use placeholder if the segment is empty AND currently selected
            if i == state.current_idx and segment == "" then
                text = "<--"
            end

            -- Track highlight bounds for the current index
            if i == state.current_idx then
                highlight_start = current_pos
                highlight_end = current_pos + #text
            end

            table.insert(display_segments, text)

            -- Advance current_pos: length of text + 1 for the "/" separator
            current_pos = current_pos + #text + 1
        end

        local line_text = table.concat(display_segments, "/")
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { line_text })
        vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

        vim.api.nvim_buf_add_highlight(bufnr, ns_id, "IncSearch", 0, highlight_start, highlight_end)
        vim.api.nvim_win_set_cursor(win, { 1, highlight_start })
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
