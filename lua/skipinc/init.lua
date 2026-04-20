local M = {}

local default_opts = {
    skip_patterns = {
        "u?int%d+_t",
        "u?int_fast%d+_t",
        "u?int_least%d+_t",
    },
}

M.opts = default_opts

local function find_next_number(line, from_col)
    local patterns = { "0[xX]%x+", "0[bB][01]+", "%d+" }
    local best_s, best_e = nil, nil
    for _, pat in ipairs(patterns) do
        local s, e = line:find(pat, from_col)
        if s and (best_s == nil or s < best_s) then
            best_s, best_e = s, e
        end
    end
    return best_s, best_e
end

local function in_skip_range(line, s, e)
    for _, pat in ipairs(M.opts.skip_patterns) do
        local pos = 1
        while true do
            local ps, pe = line:find(pat, pos)
            if not ps then break end
            if ps <= s and e <= pe then
                return true
            end
            pos = pe + 1
        end
    end
    return false
end

local function adjust(key)
    local count = vim.v.count1
    local line = vim.fn.getline(".")
    local lnum = vim.fn.line(".")
    local keycode = vim.api.nvim_replace_termcodes(key, true, false, true)

    local search_col = vim.fn.col(".")
    while true do
        local s, e = find_next_number(line, search_col)
        if not s then
            vim.cmd("normal! " .. count .. keycode)
            return
        end
        if not in_skip_range(line, s, e) then
            vim.fn.cursor(lnum, s)
            vim.cmd("normal! " .. count .. keycode)
            return
        end
        search_col = e + 1
    end
end

function M.increment()
    adjust("<C-a>")
end

function M.decrement()
    adjust("<C-x>")
end

function M.setup(opts)
    M.opts = vim.tbl_deep_extend("force", default_opts, opts or {})
    vim.keymap.set("n", "<C-a>", M.increment, { desc = "Increment, skip cstdint types" })
    vim.keymap.set("n", "<C-x>", M.decrement, { desc = "Decrement, skip cstdint types" })
end

return M
