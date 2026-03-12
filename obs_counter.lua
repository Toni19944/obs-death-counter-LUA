-- OBS Co-op Counter Script (Lua)
-- ================================
-- Tracks individual counters for up to 4 players.
-- Each player has their own Text source and three hotkeys:
--   [Player Name]: Increment (+1)
--   [Player Name]: Decrement (-1)
--   [Player Name]: Reset
--
-- Setup:
--   1. Create a Text (GDI+) source for each player in your scene.
--   2. Load this script via OBS → Tools → Scripts → "+".
--   3. Set player count, names, and source names in the script panel.
--   4. Bind hotkeys in OBS Settings → Hotkeys.

local obs = obslua

-- ── Constants ─────────────────────────────────────────────────────────────────
local MAX_PLAYERS     = 4
local DEFAULT_NAMES   = { "Player 1", "Player 2", "Player 3", "Player 4" }
local DEFAULT_SOURCES = { "Counter P1", "Counter P2", "Counter P3", "Counter P4" }

-- ── Global settings ────────────────────────────────────────────────────────────
local player_count = 2
local step_size    = 1
local min_value    = -9999
local max_value    = 9999
local start_value  = 0

-- ── Per-player state ───────────────────────────────────────────────────────────
local players = {}
for i = 1, MAX_PLAYERS do
    players[i] = {
        name    = DEFAULT_NAMES[i],
        source  = DEFAULT_SOURCES[i],
        prefix  = "",
        suffix  = "",
        counter = 0,
        hk_inc  = obs.OBS_INVALID_HOTKEY_ID,
        hk_dec  = obs.OBS_INVALID_HOTKEY_ID,
        hk_rst  = obs.OBS_INVALID_HOTKEY_ID,
    }
end


-- ── Helpers ────────────────────────────────────────────────────────────────────
local function clamp(val, lo, hi)
    return math.max(lo, math.min(hi, val))
end

local function update_text(idx)
    local p      = players[idx]
    local source = obs.obs_get_source_by_name(p.source)
    if source == nil then return end

    local text     = p.prefix .. tostring(p.counter) .. p.suffix
    local settings = obs.obs_data_create()
    obs.obs_data_set_string(settings, "text", text)
    obs.obs_source_update(source, settings)
    obs.obs_data_release(settings)
    obs.obs_source_release(source)
end


-- ── Hotkey callbacks ───────────────────────────────────────────────────────────
local function make_increment_cb(idx)
    return function(pressed)
        if not pressed then return end
        players[idx].counter = clamp(players[idx].counter + step_size, min_value, max_value)
        update_text(idx)
    end
end

local function make_decrement_cb(idx)
    return function(pressed)
        if not pressed then return end
        players[idx].counter = clamp(players[idx].counter - step_size, min_value, max_value)
        update_text(idx)
    end
end

local function make_reset_cb(idx)
    return function(pressed)
        if not pressed then return end
        players[idx].counter = clamp(start_value, min_value, max_value)
        update_text(idx)
    end
end

-- Keep callback references alive
local _callbacks = {}

local function register_hotkeys()
    _callbacks = {}
    for i = 1, MAX_PLAYERS do
        local p    = players[i]
        local name = (p.name ~= "" and p.name) or ("Player " .. i)

        local inc_cb = make_increment_cb(i)
        local dec_cb = make_decrement_cb(i)
        local rst_cb = make_reset_cb(i)
        table.insert(_callbacks, inc_cb)
        table.insert(_callbacks, dec_cb)
        table.insert(_callbacks, rst_cb)

        if p.hk_inc == obs.OBS_INVALID_HOTKEY_ID then
            p.hk_inc = obs.obs_hotkey_register_frontend(
                "counter_p" .. i .. "_inc",
                name .. ": Increment (+1)",
                inc_cb
            )
            p.hk_dec = obs.obs_hotkey_register_frontend(
                "counter_p" .. i .. "_dec",
                name .. ": Decrement (-1)",
                dec_cb
            )
            p.hk_rst = obs.obs_hotkey_register_frontend(
                "counter_p" .. i .. "_rst",
                name .. ": Reset",
                rst_cb
            )
        end
    end
end


-- ── OBS Script API ─────────────────────────────────────────────────────────────
function script_description()
    return [[<b>Co-op Hotkey Counter</b><br>
Individual counters for up to 4 players.<br>
Each player needs their own Text (GDI+) source.<br><br>
After configuring, bind hotkeys in <i>Settings → Hotkeys</i>.]]
end

function script_defaults(settings)
    obs.obs_data_set_default_int(settings, "player_count", 2)
    obs.obs_data_set_default_int(settings, "start_value",  0)
    obs.obs_data_set_default_int(settings, "step_size",    1)
    obs.obs_data_set_default_int(settings, "min_value",    -9999)
    obs.obs_data_set_default_int(settings, "max_value",    9999)
    for i = 1, MAX_PLAYERS do
        obs.obs_data_set_default_string(settings, "p" .. i .. "_name",   DEFAULT_NAMES[i])
        obs.obs_data_set_default_string(settings, "p" .. i .. "_source", DEFAULT_SOURCES[i])
        obs.obs_data_set_default_string(settings, "p" .. i .. "_prefix", "")
        obs.obs_data_set_default_string(settings, "p" .. i .. "_suffix", "")
    end
end

function script_properties()
    local props = obs.obs_properties_create()

    obs.obs_properties_add_int(props, "player_count", "Number of players", 1, MAX_PLAYERS, 1)
    obs.obs_properties_add_int(props, "start_value",  "Start / Reset value", -9999, 9999, 1)
    obs.obs_properties_add_int(props, "step_size",    "Step size",           1,     999,  1)
    obs.obs_properties_add_int(props, "min_value",    "Minimum value",       -9999, 9999, 1)
    obs.obs_properties_add_int(props, "max_value",    "Maximum value",       -9999, 9999, 1)

    obs.obs_properties_add_text(props, "_sep", "──── Per-player settings ────", obs.OBS_TEXT_INFO)

    -- Collect text sources for dropdowns
    local text_source_names = {}
    local sources = obs.obs_enum_sources()
    if sources then
        for _, src in ipairs(sources) do
            local sid = obs.obs_source_get_unversioned_id(src)
            if sid == "text_gdiplus" or sid == "text_ft2_source" then
                table.insert(text_source_names, obs.obs_source_get_name(src))
            end
        end
        obs.source_list_release(sources)
    end

    for i = 1, MAX_PLAYERS do
        local n = tostring(i)
        obs.obs_properties_add_text(props, "p" .. n .. "_name",   "P" .. n .. " display name", obs.OBS_TEXT_DEFAULT)
        obs.obs_properties_add_text(props, "p" .. n .. "_prefix", "P" .. n .. " prefix",        obs.OBS_TEXT_DEFAULT)
        obs.obs_properties_add_text(props, "p" .. n .. "_suffix", "P" .. n .. " suffix",        obs.OBS_TEXT_DEFAULT)

        local sp = obs.obs_properties_add_list(
            props, "p" .. n .. "_source", "P" .. n .. " text source",
            obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING
        )
        for _, sname in ipairs(text_source_names) do
            obs.obs_property_list_add_string(sp, sname, sname)
        end
    end

    return props
end

function script_update(settings)
    player_count = obs.obs_data_get_int(settings, "player_count")
    step_size    = obs.obs_data_get_int(settings, "step_size")
    min_value    = obs.obs_data_get_int(settings, "min_value")
    max_value    = obs.obs_data_get_int(settings, "max_value")
    start_value  = obs.obs_data_get_int(settings, "start_value")

    for i = 1, MAX_PLAYERS do
        local n = tostring(i)
        players[i].name    = obs.obs_data_get_string(settings, "p" .. n .. "_name")
        players[i].source  = obs.obs_data_get_string(settings, "p" .. n .. "_source")
        players[i].prefix  = obs.obs_data_get_string(settings, "p" .. n .. "_prefix")
        players[i].suffix  = obs.obs_data_get_string(settings, "p" .. n .. "_suffix")
        players[i].counter = clamp(start_value, min_value, max_value)

        if players[i].name == "" then
            players[i].name = "Player " .. n
        end
        if i <= player_count then
            update_text(i)
        end
    end
end

function script_load(settings)
    register_hotkeys()

    for i = 1, MAX_PLAYERS do
        local p = players[i]
        for _, pair in ipairs({
            { "hk_inc", p.hk_inc },
            { "hk_dec", p.hk_dec },
            { "hk_rst", p.hk_rst },
        }) do
            local key = "p" .. i .. "_" .. pair[1]
            local arr = obs.obs_data_get_array(settings, key)
            obs.obs_hotkey_load(pair[2], arr)
            obs.obs_data_array_release(arr)
        end
    end
end

function script_save(settings)
    for i = 1, MAX_PLAYERS do
        local p = players[i]
        for _, pair in ipairs({
            { "hk_inc", p.hk_inc },
            { "hk_dec", p.hk_dec },
            { "hk_rst", p.hk_rst },
        }) do
            local key = "p" .. i .. "_" .. pair[1]
            local arr = obs.obs_hotkey_save(pair[2])
            obs.obs_data_set_array(settings, key, arr)
            obs.obs_data_array_release(arr)
        end
    end
end

function script_unload()
    for i = 1, MAX_PLAYERS do
        obs.obs_hotkey_unregister(players[i].hk_inc)
        obs.obs_hotkey_unregister(players[i].hk_dec)
        obs.obs_hotkey_unregister(players[i].hk_rst)
    end
end
