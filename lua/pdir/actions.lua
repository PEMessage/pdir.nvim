local actions = {}

function actions.left(state)
    state.current_idx = math.max(1, state.current_idx - 1)
    state.render()
end

function actions.right(state)
    state.current_idx = math.min(#state.segments, state.current_idx + 1)
    state.render()
end

function actions.confirm(state)
    local target_path = table.concat(state.segments, state.sep, 1, state.current_idx)
    vim.api.nvim_win_close(state.win, true)
    vim.cmd("cd " .. target_path)
    print("Changed directory to: " .. target_path)
end

function actions.close(state)
    if vim.api.nvim_win_is_valid(state.win) then
        vim.api.nvim_win_close(state.win, true)
    end
end

return actions
