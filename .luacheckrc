std = "lua51"
color = true
codes = true

globals = { "tempTimer", "killTimer" }

ignore = {
    "631", -- ignore 'line is too long'
}

exclude_files = {
    "lua",
    "luarocks",
    ".luarocks/",
    "lua_modules/"
}

files = {
}

files["tests/**/*_spec.lua"].ignore = {
    "212",   -- ignore 'unused argument'
}

