# skipinc.nvim

A tiny Neovim plugin that wraps `<C-a>` / `<C-x>` so they skip over numbers embedded in C `<cstdint>` type names.

## Disclaimer
100% vibe coded - seems to work okay

## The problem

Vim's built-in `<C-a>` finds the next number on the line and increments it. That's usually what you want — except when the "number" is the width in a type like `uint8_t`:

```cpp
const uint8_t var = 100;
//    ^ cursor here, press <C-a>
```

Default behavior turns `uint8_t` into `uint9_t`. This plugin skips past that and increments `100` → `101` instead.

## Setup
```lua
require("skipinc").setup()
```

## How it works

On `<C-a>` / `<C-x>`:

1. Scan the current line from the cursor for the next number (hex `0x…`, binary `0b…`, or decimal).
2. If that number is inside one of the configured skip patterns, skip past it and keep scanning.
3. When a non-skipped number is found, move the cursor to it and invoke the built-in `normal! <C-a>` / `<C-x>`.

Because the actual increment is delegated to Vim's built-in, everything it normally handles still works:

- `nrformats` (decimal, hex, octal, binary, alpha)
- Counts: `5<C-a>` adds 5
- Negative numbers
- Zero-padding preservation

## Configuration

Defaults:

```lua
require("skipinc").setup({
  skip_patterns = {
    "u?int%d+_t",         -- uint8_t, int16_t, uint32_t, int64_t, ...
    "u?int_fast%d+_t",    -- int_fast8_t, uint_fast32_t, ...
    "u?int_least%d+_t",   -- int_least8_t, uint_least16_t, ...
  },
})
```

`skip_patterns` is a list of Lua patterns. If the number the cursor would otherwise land on falls entirely inside a match for any of these patterns, that number is skipped.

### Adding your own patterns

Pass the full list (it replaces the default) or merge yourself:

```lua
require("skipinc").setup({
  skip_patterns = {
    "u?int%d+_t",
    "u?int_fast%d+_t",
    "u?int_least%d+_t",
    "float%d+",   -- e.g. skip "float32", "float64"
    "v%d+i%d+",   -- SIMD-style "v4i32", etc.
  },
})
```

Patterns use Lua pattern syntax, not Vim regex. See `:help lua-patterns`.

## Keymaps

`setup()` installs normal-mode mappings for `<C-a>` and `<C-x>`. If you'd rather map them yourself, skip `setup()` and call the module functions directly:

```lua
vim.keymap.set("n", "<C-a>", require("skipinc").increment)
vim.keymap.set("n", "<C-x>", require("skipinc").decrement)
```

Visual-mode `<C-a>` / `<C-x>` (bulk increment) is left alone.

## API

| Function | Description |
|---|---|
| `require("skipinc").setup(opts)` | Merge `opts` over defaults and install keymaps. |
| `require("skipinc").increment()` | Increment the next non-skipped number on the line. |
| `require("skipinc").decrement()` | Decrement the next non-skipped number on the line. |
