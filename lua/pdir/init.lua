local M = {}
local actions = require("pdir.actions")

-- Detect path separator (usually '\' on Windows, '/' on Unix)
local sep = package.config:sub(1, 1)

-- Default Configuration
M.config = {
    keys = {
        ["<left>"]  = actions.left,
        ["<m-left>"]   = actions.left,
        ["<right>"] = actions.right,
        ["<m-right>"] = actions.right,
        ["<CR>"]    = actions.confirm,
        ["<Esc>"]   = actions.close,
        ["<C-c>"]   = actions.close,
    },
    highlight = "IncSearch",
}

function M.setup(user_config)
    M.config = vim.tbl_deep_extend("force", M.config, user_config or {})
end

function M.open_breadcrumb(path, initial_idx)
    -- Use the OS-specific separator for splitting
    -- We escape the separator for the pattern match in case it's a backslash
    local segments = vim.split(path, sep, { trimempty = false })

    if #segments == 0 then return end

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
        ns_id = ns_id,
        sep = sep -- Store separator in state for actions.confirm if needed
    }

    state.render = function()
        local display_segments = {}
        local highlight_start = 0
        local current_pos = 0

        for i, segment in ipairs(state.segments) do
            local text = segment

            if i == state.current_idx and segment == "" then
                text = "<--"
            end

            if i == state.current_idx then
                highlight_start = current_pos
                state.highlight_end = current_pos + #text -- Update state for highlight tracking
            end

            table.insert(display_segments, text)
            -- Use the actual separator length for position tracking
            current_pos = current_pos + #text + #sep
        end

        local line_text = table.concat(display_segments, sep)
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { line_text })
        vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

        vim.api.nvim_buf_add_highlight(bufnr, ns_id, M.config.highlight, 0, highlight_start, state.highlight_end)
        vim.api.nvim_win_set_cursor(win, { 1, highlight_start })
    end

    for key, action_fn in pairs(M.config.keys) do
        vim.keymap.set("n", key, function()
            action_fn(state)
        end, { buffer = bufnr, silent = true })
    end

    state.render()
end

local cache = {
    prev_dir = "",
}

function M.open_parent(offset)
    offset = offset or 0
    local current_dir = vim.fn.getcwd()
    local cached_dir = cache.prev_dir

    -- Split using the detected separator
    local curr_segments = vim.split(current_dir, sep, { trimempty = false })
    local cache_segments = vim.split(cached_dir, sep, { trimempty = false })

    local update_cache = false

    -- Check if paths match (Windows paths are case-insensitive, handled by :find)
    if cached_dir == "" then
        update_cache = true
    elseif not (current_dir:find(cached_dir, 1, true) == 1 or cached_dir:find(current_dir, 1, true) == 1) then
        update_cache = true
    elseif current_dir:find(cached_dir, 1, true) == 1 and #current_dir > #cached_dir then
        update_cache = true
    end

    local initial_idx = -1
    if update_cache then
        cache.prev_dir = current_dir
        initial_idx = #curr_segments -- Default to end of path
    else
        initial_idx = math.max(math.min(#curr_segments + offset, #cache_segments), 1)
    end

    M.open_breadcrumb(cache.prev_dir, initial_idx)
end

return M
