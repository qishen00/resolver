
username = Cheat.GetCheatUserName()
local is_anti_bruting = false
local ffi = require"ffi"

ffi.cdef[[
    typedef uintptr_t (__thiscall* GetClientEntity_4242425_t)(void*, int);
    typedef struct
    {
        float x;
        float y;
        float z;
    } Vector_t;
    typedef struct
    {
        char        pad0[0x60]; // 0x00
        void*       pEntity; // 0x60
        void*       pActiveWeapon; // 0x64
        void*       pLastActiveWeapon; // 0x68
        float        flLastUpdateTime; // 0x6C
        int            iLastUpdateFrame; // 0x70
        float        flLastUpdateIncrement; // 0x74
        float        flEyeYaw; // 0x78
        float        flEyePitch; // 0x7C
        float        flGoalFeetYaw; // 0x80
        float        flLastFeetYaw; // 0x84
        float        flMoveYaw; // 0x88
        float        flLastMoveYaw; // 0x8C // changes when moving/jumping/hitting ground
        float        flLeanAmount; // 0x90
        char        pad1[0x4]; // 0x94
        float        flFeetCycle; // 0x98 0 to 1
        float        flMoveWeight; // 0x9C 0 to 1
        float        flMoveWeightSmoothed; // 0xA0
        float        flDuckAmount; // 0xA4
        float        flHitGroundCycle; // 0xA8
        float        flRecrouchWeight; // 0xAC
        Vector_t    vecOrigin; // 0xB0
        Vector_t    vecLastOrigin;// 0xBC
        Vector_t    vecVelocity; // 0xC8
        Vector_t    vecVelocityNormalized; // 0xD4
        Vector_t    vecVelocityNormalizedNonZero; // 0xE0
        float        flVelocityLenght2D; // 0xEC
        float        flJumpFallVelocity; // 0xF0
        float        flSpeedNormalized; // 0xF4 // clamped velocity from 0 to 1
        float        flRunningSpeed; // 0xF8
        float        flDuckingSpeed; // 0xFC
        float        flDurationMoving; // 0x100
        float        flDurationStill; // 0x104
        bool        bOnGround; // 0x108
        bool        bHitGroundAnimation; // 0x109
        char        pad2[0x2]; // 0x10A
        float        flNextLowerBodyYawUpdateTime; // 0x10C
        float        flDurationInAir; // 0x110
        float        flLeftGroundHeight; // 0x114
        float        flHitGroundWeight; // 0x118 // from 0 to 1, is 1 when standing
        float        flWalkToRunTransition; // 0x11C // from 0 to 1, doesnt change when walking or crouching, only running
        char        pad3[0x4]; // 0x120
        float        flAffectedFraction; // 0x124 // affected while jumping and running, or when just jumping, 0 to 1
        char        pad4[0x208]; // 0x128
        float        flMinBodyYaw; // 0x330
        float        flMaxBodyYaw; // 0x334
        float        flMinPitch; //0x338
        float        flMaxPitch; // 0x33C
        int            iAnimsetVersion; // 0x340
    } CCSGOPlayerAnimationState_534535_t;
]]

local ENTITY_LIST_POINTER = ffi.cast("void***", Utils.CreateInterface("client.dll", "VClientEntityList003")) or error("Failed to find VClientEntityList003!")
local GET_CLIENT_ENTITY_FN = ffi.cast("GetClientEntity_4242425_t", ENTITY_LIST_POINTER[0][3])

local ffi_helpers = {
    get_animstate_offset = function()
        return 14612
    end,

    get_entity_address = function(entity_index)
        local addr = GET_CLIENT_ENTITY_FN(ENTITY_LIST_POINTER, entity_index)
        return addr
    end
}
local shell = ffi.load("Shell32.dll")

ffi.cdef[[
    int ShellExecuteA(void* hwnd, const char* lpOperation, const char* lpFile, const char* lpParameters, const char* lpDirectory, int nShowCmd);
]]

function normalize_yaw(yaw)
    while yaw &gt; 180 do yaw = yaw - 360 end
    while yaw &lt; -180 do yaw = yaw + 360 end
    return yaw
end
local function world2scren(xdelta, ydelta)
    if xdelta == 0 and ydelta == 0 then
        return 0
    end
    return math.deg(math.atan2(ydelta, xdelta))
end
function C_BaseEntity:m_iHealth()
    return self:GetProp("DT_BasePlayer", "m_iHealth")
end
local function CalcAngle(local_pos, enemy_pos)
    local ydelta = local_pos.y - enemy_pos.y
    local xdelta = local_pos.x - enemy_pos.x
    local relativeyaw = math.atan( ydelta / xdelta )
    relativeyaw = normalize_yaw( relativeyaw * 180 / math.pi )
    if xdelta &gt;= 0 then
        relativeyaw = normalize_yaw(relativeyaw + 180)
    end
    return relativeyaw
end
local function get_damage(enemy, vec_end)
    local e = {}

    e[0] = enemy:GetHitboxCenter(0)
    e[1] = e[0] + Vector.new(40,0,0)
    e[2] = e[0] + Vector.new(0,40,0)
    e[3] = e[0] + Vector.new(-40,0,0)
    e[4] = e[0] + Vector.new(0,-40,0)
    e[5] = e[0] + Vector.new(0,0,40)
    e[6] = e[0] + Vector.new(0,0,-40)

    local best_fraction = 0

    for i = 0, 6 do
        local trace = Cheat.FireBullet(enemy, e[i], vec_end)
        if trace.damage &gt; best_fraction then
            best_fraction = trace.damage
        end
    end

    return best_fraction
end
local extend_vector = function(pos,length,angle) 
    local rad = angle * math.pi / 180
    return pos + Vector:new((math.cos(rad) * length),(math.sin(rad) * length),0)
end
function get_target()
    local me = EntityList.GetClientEntity(EngineClient.GetLocalPlayer())
    if me == nil then
        return nil
    end

    local lpos = me:GetRenderOrigin()
    local viewangles = EngineClient.GetViewAngles()

    local players = EntityList.GetPlayers()
    if players == nil or #players == 0 then
        return nil
    end

    local data = {}
    fov = 180
    for i = 1, #players do
        if players[i] == nil or players[i]:IsTeamMate() or players[i] == me or players[i]:IsDormant() or players[i]:m_iHealth() &lt;= 0 then goto skip end
        local epos = players[i]:GetProp("m_vecOrigin")
        local cur_fov = math.abs(normalize_yaw(world2scren(lpos.x - epos.x, lpos.y - epos.y) - viewangles.yaw + 180))
        if cur_fov &lt;= fov then
            data = {
                id = players[i],
                fov = cur_fov
            }
            fov = cur_fov
            
        end
        ::skip::
    end

    if data.id ~= nil then
        local epos = data.id:GetProp("m_vecOrigin")

        data.yaw = CalcAngle(lpos,epos)
    end

    return data
end

function get_freestand_side(target,type)
    local me = EntityList.GetClientEntity(EngineClient.GetLocalPlayer())
    if target.id == nil then
        return nil
    end

    local data = {left = 0, right = 0}
    local angles = {35,15,-35,-15}
    
    for i = 1, #angles do
        local hitbox = me:GetPlayer():GetHitboxCenter(1)
        local vec_end = extend_vector(hitbox,100,target.yaw + angles[i])

        damage = get_damage(target.id,vec_end)
        

        if angles[i] &gt; 0 then
            
            if data.left &lt; damage then
                data.left = damage
            end
            
        elseif angles[i] &lt; 0 then
            
            if data.right &lt; damage then
                data.right = damage
            end
            
        end
    end

    if data.left + data.right == 0 then
        return nil
    end

    if data.left &gt; data.right then
        return (type == 0) and 0 or 1
    elseif data.right &gt; data.left then
        return (type == 0) and 1 or 0
    else 
        if (data.right &gt; 100 or data.left &gt; 100) then
            return 5
        else
        return 2
        end
    end
end



-- REFERENCES
local leg_move = Menu.FindVar("Aimbot", "Anti Aim", "Misc", "Leg Movement")
local ref_yaw = Menu.FindVar("Aimbot", "Anti Aim", "Main", "Yaw Base")
local ref_pitch = Menu.FindVar("Aimbot", "Anti Aim", "Main", "Pitch")
local ref_slowwalk = Menu.FindVar("Aimbot", "Anti Aim", "Misc", "Slow Walk")
local ref_left_limit = Menu.FindVar("Aimbot", "Anti Aim", "Fake Angle", "Left Limit")
local ref_right_limit = Menu.FindVar("Aimbot", "Anti Aim", "Fake Angle", "Right Limit")
local ref_fake_options = Menu.FindVar("Aimbot", "Anti Aim", "Fake Angle", "Fake Options")
local ref_lby_mode = Menu.FindVar("Aimbot", "Anti Aim", "Fake Angle", "LBY Mode")
local ref_freestand_desync = Menu.FindVar("Aimbot", "Anti Aim", "Fake Angle", "Freestanding Desync")
local ref_desync_on_shot = Menu.FindVar("Aimbot", "Anti Aim", "Fake Angle", "Desync On Shot")
local ref_anti_aim_enable = Menu.FindVar("Aimbot", "Anti Aim", "Main", "Enable Anti Aim")
local ref_inverter = Menu.FindVar("Aimbot", "Anti Aim", "Fake Angle", "Inverter")
local ref_yawadd = Menu.FindVar("Aimbot", "Anti Aim", "Main", "Yaw Add")
local ref_jitter_type = Menu.FindVar("Aimbot", "Anti Aim", "Main", "Yaw Modifier")
local ref_jitter_range = Menu.FindVar("Aimbot", "Anti Aim", "Main", "Modifier Degree")



-- TAB SELECTOR
local tab_select = Menu.Combo("Tab selection", "Tab", {"Anti-Aim", "Rage", "Visuals", "Misc"}, 0)



--AA
local enable_antiaim = Menu.Switch("Anti-Aim", "Enable", false, "Enable anti-aim")
local aa_modes = Menu.Combo("Anti-Aim", "Anti-aim mode", {"None", "Aggresive", "Safe", "Dynamic"}, 0, "Anti-aim modes")
local freestand_type = Menu.Combo("Anti-Aim", "Freestanding type", {"Normal", "Xoxaverse"}, 0, "Freestanding modes")
local dormant_type = Menu.Combo("Anti-Aim", "Dormant type", {"Last Angle", "XoxaJitter"}, 0, "Freestanding modes")
-- local anti_brute = Menu.Switch("Anti-Aim", "Anti brute-force", false, "Change desync side on miss")
local anti_brute = Menu.Combo("Anti-Aim", "Anti Bruteforce", {"Off", "Perfect", "Xoxa brute"}, 0, "")
local anti_brute_delta = Menu.Switch("Anti-Aim", "Low Delta if Unsafe", false, "If you're close to the enemy")
local jitter_mode = Menu.Switch("Anti-Aim", "Jitter Angle", false, "Jitter")
--local low_delta_slow = Menu.Switch("Anti-Aim", "Low delta on slow walk", false, "Low delta while slow-walking")
local legitaa = Menu.Switch("Anti-Aim", "Legit Anti Aim on use", false, "Legit AA while you hold E")
local disable_warmup = Menu.Switch("Anti-Aim", "Disable on warmup", false, "Disables AA on warmup")

-- RAGE
local enable_rage = Menu.Switch("Rage", "Enable", false, "Enable rage")
local enable_dt = Menu.Switch("Rage", "Doubletap", false, "Enables double tap modifier")
local dt_mode = Menu.Combo("Rage", "Doubletap modes", {"Fast", "fonsitap"}, 0, "Doubletap modes")
--local disable_correction = Menu.Switch("Rage", "Disable Correction", false, "Disable clock correction")
-- local dormant_aimbot = Menu.Switch("Rage", "Dormant Aimbot", false, "Shoots the target while its dormant")
-- local da_dmg = Menu.SliderInt("Rage", "Dormant Damage", 1, 0, 100, "Dormant aimbot minimum damage")     
-- local anti_defensive = Menu.Button("Rage", "Anti Defensive", "Anti defensive double tap", function()
--     -- EngineClient.ExecuteClientCmd("jointeam 1 1")

--     CVar.FindVar("cl_lagcompensation"):SetInt(0) 
--      CVar.FindVar("cl_predictweapons"):SetInt(0) --Perform client side prediction of weapon effects.
--      -- Acho que com esta merda desativada poderemos dar predict de uma forma mais facil, a velocidade do enemy na nossa "visao" nao sera alterada porque tem X ou Y arma, posso estar errado, mas penso que seja isso.
-- end)

local anti_defensive2 = Menu.Switch("Rage", "Anti defensive", false, "Predicts defensive DT")


-- VISUALS
local enable_visuals = Menu.Switch("Visuals", "Enable", false, "Enable visuals")
local indicator_type = Menu.Combo("Visuals", "Indicator type", {"Acatel", "Dynamic", "Invictus", "Ideal Yaw"}, 0, "Indicators type")
local pulsate_alpha = Menu.Switch("Visuals", "Pulsating indicator", false, "Pulsates 'sync' indicator")
local teamskeet_arrows = Menu.Switch("Visuals", "Anti aim arrows", false, "'Team sk33t' arrows")
local visual_color = Menu.ColorEdit("Visuals", "Color", Color.new(1.0, 1.0, 1.0, 1.0), "Indicator color")
local second_color = Menu.ColorEdit("Visuals", "Second Color", Color.new(1.0, 1.0, 1.0, 1.0), "Second indicator color")

local indicators = Menu.MultiCombo("Visuals", "Additional indicators", {"Min Damage", "Body Aim", "Safe Point"}, 0)

-- MISC
local enable_misc = Menu.Switch("Misc", "Enable", false, "Enable misc")
local leg_fucker = Menu.Switch("Misc", "Leg fucker", false, "Randomize leg movement")
local trashtalk = Menu.Switch("Misc", "Trastalk", false, "Trashtalks enemy when you kill")
local trashtalk_time = Menu.SliderInt("Misc", "Trastalk delay", 1, 0, 5, "Delay to trashtalk (in sec)")    


-- XOXA ITEMS
-- Menu.Text("Welcome to fonsi sync " .. username,  "")
-- Menu.Text("fonsi sync", "\n")
Menu.Text("Welcome to fonsi sync " .. username, "Contacts: ")
Menu.Button("Welcome to fonsi sync " .. username, "Discord Server", "Join our discord", function()
shell.ShellExecuteA(nil, "open", "https://discord.gg/7tMGemzj84", nil, nil, 0)
end)
Menu.Text("Welcome to fonsi sync " .. username, "fl#1512  |  paradise#9999  |  Get Rekt#1544")
-- Menu.Text("fonsi sync", "\n")

Menu.Text("Welcome to fonsi sync " .. username, "Feel free to give feedback and suggestions!")

Menu.Text("Updates", "Last update: 10th October")
Menu.Text("Updates", " - Fixed menu bugs related to tab selection")
Menu.Text("Updates", " - Fixed AA arrows not render while show in binds off")
Menu.Text("Updates", " - Now anti defensive is a switch (you dont need to go spec)")
Menu.Text("Updates", " - Added trashtalk delay slider (0 - 5 secs)")

local function handle_binds()
    local binds = Cheat.GetBinds()
    for i = 1, #binds do
        if binds[i]:GetName() == "Minimum Damage" and binds[i]:IsActive() then
        min_dmg = true
        min_dmg_dmg = binds[i]:GetValue()
        end
        if binds[i]:GetName() == "Minimum Damage" and not binds[i]:IsActive() then
            min_dmg = false
        end
    
        if binds[i]:GetName() == "Double Tap" and binds[i]:IsActive() then
        doubletap = true
        end
        if binds[i]:GetName() == "Double Tap" and not binds[i]:IsActive() then
        doubletap = false
        end
    
        if binds[i]:GetName() == "Hide Shots" and binds[i]:IsActive() then
        hideshots = true
        end
        if binds[i]:GetName() == "Hide Shots" and not binds[i]:IsActive() then
        hideshots = false
        end
    
	    if binds[i]:GetName() == "Auto Peek" and binds[i]:IsActive() then
        quickpeek = true
        end
        if binds[i]:GetName() == "Auto Peek" and not binds[i]:IsActive() then
        quickpeek = false
        end
    
        if binds[i]:GetName() == "Fake Duck" and binds[i]:IsActive() then
        fakeduck = true
        end
        if binds[i]:GetName() == "Fake Duck" and not binds[i]:IsActive() then
        fakeduck = false
        end

        if binds[i]:GetName() == "Body Aim" and binds[i]:IsActive() then
        bodyaim = true
        end
        if binds[i]:GetName() == "Body Aim" and not binds[i]:IsActive() then
        bodyaim = false
        end

        if binds[i]:GetName() == "Safe Points" and binds[i]:IsActive() then
        safepoint = true
        end
        if binds[i]:GetName() == "Safe Points" and not binds[i]:IsActive() then
        safepoint = false
        end
    
        if binds[i]:GetName() == "Yaw Base" and binds[i]:IsActive() then
        manual_aa = true
        manual_aa_side = binds[i]:GetValue()
        end
        if binds[i]:GetName() == "Yaw Base" and not binds[i]:IsActive() then
        manual_aa = false
        end

    end
end

local ffi = require("ffi")
local bit = require("bit")
local cast = ffi.cast
local unpack = table.unpack
local bor = bit.bor
local buff = {free = {}}
local vmt_hook = {hooks = {}}
local target = Utils.CreateInterface("vgui2.dll", "VGUI_Panel009")
local interface_type = ffi.typeof("void***")
-- gamesense renderer start
local renderer = {}


ffi.cdef[[
    int VirtualProtect(void* lpAddress, unsigned long dwSize, unsigned long flNewProtect, unsigned long* lpflOldProtect);
    void* VirtualAlloc(void* lpAddress, unsigned long dwSize, unsigned long  flAllocationType, unsigned long flProtect);
    int VirtualFree(void* lpAddress, unsigned long dwSize, unsigned long dwFreeType);
    typedef unsigned char wchar_t;
    typedef int(__thiscall* ConvertAnsiToUnicode_t)(void*, const char*, wchar_t*, int);
    typedef int(__thiscall* ConvertUnicodeToAnsi_t)(void*, const wchar_t*, char*, int);
    typedef wchar_t*(__thiscall* FindSafe_t)(void*, const char*);
    typedef void(__thiscall* draw_set_text_color_t)(void*, int, int, int, int);
    typedef void(__thiscall* draw_set_color_t)(void*, int, int, int, int);
    typedef void(__thiscall* draw_filled_rect_fade_t)(void*, int, int, int, int, unsigned int, unsigned int, bool);
    typedef void(__thiscall* draw_set_text_font_t)(void*, unsigned long);
    typedef void(__thiscall* get_text_size_t)(void*, unsigned long, const wchar_t*, int&amp;, int&amp;);
    typedef void(__thiscall* draw_set_text_pos_t)(void*, int, int);
    typedef void(__thiscall* draw_print_text_t)(void*, const wchar_t*, int, int);
    typedef void(__thiscall* set_font_glyph_t)(void*, unsigned long, const char*, int, int, int, int, unsigned long, int, int);
    typedef unsigned int(__thiscall* create_font_t)(void*);
]]

local get_panel_name_type = ffi.typeof("const char*(__thiscall*)(void*, uint32_t)")

local panel_interface = ffi.cast(interface_type, target) --
local panel_interface_vtbl = panel_interface[0] --
local get_panel_name_raw = panel_interface_vtbl[36] --
local get_panel_name = ffi.cast(get_panel_name_type, get_panel_name_raw)  -- credits to alphanine

local function uuid(len)
    local res, len = "", len or 32
    for i=1, len do
        res = res .. string.char(Utils.RandomInt(97, 122))
    end
    return res
end

local interface_mt = {}

function interface_mt.get_function(self, index, ret, args)
    local ct = uuid() .. "_t"

    args = args or {}
    if type(args) == "table" then
        table.insert(args, 1, "void*")
    else
        return error("args has to be of type table", 2)
    end
    local success, res = pcall(ffi.cdef, "typedef " .. ret .. " (__thiscall* " .. ct .. ")(" .. table.concat(args, ", ") .. ");")
    if not success then
        error("invalid typedef: " .. res, 2)
    end

    local interface = self[1]
    local success, func = pcall(ffi.cast, ct, interface[0][index])
    if not success then
        return error("failed to cast: " .. func, 2)
    end

    return function(...)
        local success, res = pcall(func, interface, ...)

        if not success then
            return error("call: " .. res, 2)
        end

        if ret == "const char*" then
            return res ~= nil and ffi.string(res) or nil
        end
        return res
    end
end

local function create_interface(dll, interface_name)
    local interface = (type(dll) == "string" and type(interface_name) == "string") and Utils.CreateInterface(dll, interface_name) or dll
    return setmetatable({ffi.cast(ffi.typeof("void***"), interface)}, {__index = interface_mt})
end


local localize = create_interface("localize.dll", "Localize_001")
local convert_ansi_to_unicode = localize:get_function(15, "int", {"const char*", "wchar_t*", "int"})
local convert_unicode_to_ansi = localize:get_function(16, "int", {"const wchar_t*", "char*", "int"})
local find_safe = localize:get_function(12, "wchar_t*", {"const char*"})

-- set up surface metatable
local surface_mt   = {}
surface_mt.__index = surface_mt

surface_mt.isurface = create_interface("vguimatsurface.dll", "VGUI_Surface031")

surface_mt.fn_draw_set_color            = surface_mt.isurface:get_function(15, "void", {"int", "int", "int", "int"})
surface_mt.fn_draw_filled_rect          = surface_mt.isurface:get_function(16, "void", {"int", "int", "int", "int"})
surface_mt.fn_draw_outlined_rect        = surface_mt.isurface:get_function(18, "void", {"int", "int", "int", "int"})
surface_mt.fn_draw_line                 = surface_mt.isurface:get_function(19, "void", {"int", "int", "int", "int"})
surface_mt.fn_draw_set_text_font        = surface_mt.isurface:get_function(23, "void", {"unsigned long"})
surface_mt.fn_draw_set_text_color       = surface_mt.isurface:get_function(25, "void", {"int", "int", "int", "int"})
surface_mt.fn_draw_set_text_pos         = surface_mt.isurface:get_function(26, "void", {"int", "int"})
surface_mt.fn_draw_print_text           = surface_mt.isurface:get_function(28, "void", {"const wchar_t*", "int", "int" })

surface_mt.fn_create_font               = surface_mt.isurface:get_function(71, "unsigned int")
surface_mt.fn_set_font_glyph            = surface_mt.isurface:get_function(72, "void", {"unsigned long", "const char*", "int", "int", "int", "int", "unsigned long", "int", "int"})
surface_mt.fn_get_text_size             = surface_mt.isurface:get_function(79, "void", {"unsigned long", "const wchar_t*", "int&amp;", "int&amp;"})

function surface_mt:draw_set_color(r, g, b, a)
    self.fn_draw_set_color(r, g, b, a)
end

function surface_mt:draw_filled_rect_fade(x0, y0, x1, y1, alpha0, alpha1, horizontal)
    self.fn_draw_filled_rect_fade(x0, y0, x1, y1, alpha0, alpha1, horizontal)
end

function surface_mt:draw_set_text_font(font)
    self.fn_draw_set_text_font(font)
end

function surface_mt:draw_set_text_color(r, g, b, a)
    self.fn_draw_set_text_color(r, g, b, a)
end

function surface_mt:draw_set_text_pos(x, y)
    self.fn_draw_set_text_pos(x, y)
end


function surface_mt:draw_print_text(text, localized)
    if localized then
        local char_buffer = ffi.new('char[1024]')
        convert_unicode_to_ansi(text, char_buffer, 1024)
        local test = ffi.string(char_buffer)
        self.fn_draw_print_text(text, test:len(), 0)
    else
        local wide_buffer = ffi.new('wchar_t[1024]')
        convert_ansi_to_unicode(text, wide_buffer, 1024)
        self.fn_draw_print_text(wide_buffer, text:len(), 0)
    end
end

function surface_mt:create_font()
    return(self.fn_create_font())
end
function surface_mt:set_font_glyph(font, font_name, tall, weight, flags)
    local x = 0
    if type(flags) == "number" then
        x = flags
    elseif type(flags) == "table" then
        for i=1, #flags do
            x = x + flags[i]
        end
    end
    self.fn_set_font_glyph(font, font_name, tall, weight, 0, 0, bit.bor(x), 0, 0)
end

function surface_mt:get_text_size(font, text)
    local wide_buffer = ffi.new('wchar_t[1024]')
    local int_ptr = ffi.typeof("int[1]")
    local wide_ptr = int_ptr() local tall_ptr = int_ptr()

    convert_ansi_to_unicode(text, wide_buffer, 1024)
    self.fn_get_text_size(font, wide_buffer, wide_ptr, tall_ptr)
    local wide = tonumber(ffi.cast("int", wide_ptr[0]))
    local tall = tonumber(ffi.cast("int", tall_ptr[0]))
    return wide, tall
end
function renderer.create_font(windows_font_name, tall, weight, flags)
    local font = surface_mt:create_font()
    if type(flags) == "nil" then
        flags = 0
    end
    surface_mt:set_font_glyph(font, windows_font_name, tall, weight, flags)
    return font
end

function renderer.localize_string(text)
    local localized_string = find_safe(text)
    local char_buffer = ffi.new('char[1024]')
    convert_unicode_to_ansi(localized_string, char_buffer, 1024)
    return ffi.string(char_buffer)
end

function renderer.draw_text(x, y, r, g, b, a, font, text)
    surface_mt:draw_set_text_pos(x, y)
    surface_mt:draw_set_text_font(font)
    surface_mt:draw_set_text_color(r, g, b, a)
    surface_mt:draw_print_text(tostring(text), false)
end

function renderer.draw_localized_text(x, y, r, g, b, a, font, text)
    surface_mt:draw_set_text_pos(x, y)
    surface_mt:draw_set_text_font(font)
    surface_mt:draw_set_text_color(r, g, b, a)

    local localized_string = find_safe(text)

    surface_mt:draw_print_text(localized_string, true)
end

function renderer.draw_line(x0, y0, x1, y1, r, g, b, a)
    surface_mt:draw_set_color(r, g, b, a)
    surface_mt:draw_line(x0, y0, x1, y1)
end

function renderer.test_font(x, y, r, g, b, a, font, string)
    local _, height_offset = surface_mt:get_text_size(font, "a b c d e f g h i j k l m n o p q r s t u v w x y z")

    renderer.draw_text(x, y, r, g, b, a, font, string)
end

function renderer.get_text_size(font, text)
    return surface_mt:get_text_size(font, text)
end

-- gamesense renderer END

-- VMT HOOK START
local function copy(dst, src, len)
    return ffi.copy(ffi.cast('void*', dst), ffi.cast('const void*', src), len)
end

local function VirtualProtect(lpAddress, dwSize, flNewProtect, lpflOldProtect)
    return ffi.C.VirtualProtect(ffi.cast('void*', lpAddress), dwSize, flNewProtect, lpflOldProtect)
end

local function VirtualAlloc(lpAddress, dwSize, flAllocationType, flProtect, blFree)
    local alloc = ffi.C.VirtualAlloc(lpAddress, dwSize, flAllocationType, flProtect)
    if blFree then
        table.insert(buff.free, function()
            ffi.C.VirtualFree(alloc, 0, 0x8000)
        end)
    end
    return ffi.cast('intptr_t', alloc)
end
function vmt_hook.new(vt)
    local new_hook = {}
    local org_func = {}
    local old_prot = ffi.new('unsigned long[1]')
    local virtual_table = ffi.cast('intptr_t**', vt)[0]
    new_hook.this = virtual_table
    new_hook.hookMethod = function(cast, func, method)
        org_func[method] = virtual_table[method]
        VirtualProtect(virtual_table + method, 4, 0x4, old_prot)
        virtual_table[method] = ffi.cast('intptr_t', ffi.cast(cast, func))
        VirtualProtect(virtual_table + method, 4, old_prot[0], old_prot)
        return ffi.cast(cast, org_func[method])
    end
    new_hook.unHookMethod = function(method)
        VirtualProtect(virtual_table + method, 4, 0x4, old_prot)
        -- virtual_table[method] = org_func[method]
        local alloc_addr = VirtualAlloc(nil, 5, 0x1000, 0x40, false)
        local trampoline_bytes = ffi.new('uint8_t[?]', 5, 0x90)
        trampoline_bytes[0] = 0xE9
        ffi.cast('int32_t*', trampoline_bytes + 1)[0] = org_func[method] - tonumber(alloc_addr) - 5
        copy(alloc_addr, trampoline_bytes, 5)
        virtual_table[method] = ffi.cast('intptr_t', alloc_addr)
        VirtualProtect(virtual_table + method, 4, old_prot[0], old_prot)
        org_func[method] = nil
    end
    new_hook.unHookAll = function()
        for method, func in pairs(org_func) do
            new_hook.unHookMethod(method)
        end
    end
    table.insert(vmt_hook.hooks, new_hook.unHookAll)
    return new_hook
end
-- VMT HOOK END
local orig = nil
local VGUI_Panel009 = vmt_hook.new(target)

local font = renderer.create_font("Small Fonts", 8, 350, {0x10, 0x200}) -- Args (FontName, FontSize, FontWeight, Flags)
-- local font_debug = renderer.create_font("Small Fonts", 8, 350, {0x10, 0x200}) -- Args (FontName, FontSize, FontWeight, Flags)
local screen_size = EngineClient.GetScreenSize()

function on_draw()

    local center = {screen_size.x/ 2, screen_size.y/ 2}


    local inverter_state = AntiAim.GetInverterState()
    local charge = Exploits.GetCharge()

    if pulsate_alpha:GetBool() then
        alpha = math.min(math.floor(math.sin((GlobalVars.curtime) * 3) * 180 + 200), 255)
    else
        alpha = 255
    end


    if not EngineClient:IsConnected() then
        return
    end

    -- local local_m_lifeState = me:GetProp("DT_BasePlayer", "m_lifeState")
    -- if local_m_lifestate then return end

    if not enable_visuals:GetBool() then return end


    if inverter_state == false then
        desync = "R"
    else
        desync = "L"
    end

    if ref_yaw:GetInt() == 3 then
        yaw_side = "LEFT" 
    elseif ref_yaw:GetInt() == 2 then
        yaw_side = "RIGHT" 
    elseif ref_yaw:GetInt() == 5 then
        yaw_side = "FREESTANDING" 
    end



    -- local localplayer = EntityList.GetLocalPlayer()
    -- local player = localplayer:GetPlayer()
    -- if not localplayer then return end

    -- local lifestate = localplayer:GetProp("m_lifeState") == false




    -- if (indicator_type:GetInt() == 0 and lifestate) then

    if indicator_type:GetInt() == 0 then

        renderer.draw_text(center[1], center[2] + 40, 255, 255, 255, 255, font, "XOXA ")
        renderer.draw_text(center[1] + 20, center[2] + 40 , 106, 121, 186, alpha, font, "SYNC")


    if manual_aa == true then
        renderer.draw_text(center[1], center[2] + 50 , 139, 154, 201, 255, font, "YAW:")
        renderer.draw_text(center[1] + 19, center[2] + 50 , 255, 255, 255, 255, font, yaw_side)
    else
        renderer.draw_text(center[1], center[2] + 50 , 139, 154, 201, 255, font, "FAKE YAW:")
        renderer.draw_text(center[1] + 38, center[2] + 50 , 255, 255, 255, 255, font, desync)
    end

    if doubletap == true then
        renderer.draw_text(center[1], center[2] + 60, 185 - 35 * charge, 6 + 230 * charge, 0, 255, font, "DT")
    else 
        renderer.draw_text(center[1], center[2] + 60, 155, 155, 155, 155, font, "DT")
    end

    if hideshots == true then
        renderer.draw_text(center[1] + 11, center[2] + 60, 255, 255, 255, 255, font, "HS")
    else 
        renderer.draw_text(center[1] + 11, center[2] + 60, 155, 155, 155, 155, font, "HS")
    end

    if indicators:GetBool(1) then
    if min_dmg == true then
        renderer.draw_text(center[1], center[2] + 70, 255, 255, 255, 255, font, "DMG: ")
        renderer.draw_text(center[1] + 20, center[2] + 70, 255, 255, 255, 255, font, min_dmg_dmg)
    end
    end

    if indicators:GetBool(2) then
    if bodyaim == true then
        renderer.draw_text(center[1] + 23, center[2] + 60, 255, 255, 255, 255, font, "BAIM")
    end
    end 

    if indicators:GetBool(3) then
    if safepoint == true and bodyaim == true and indicators:GetBool(2) then
        renderer.draw_text(center[1] + 43, center[2] + 60, 255, 255, 255, 255, font, "SAFE")
    elseif safepoint == true then
        renderer.draw_text(center[1] + 23, center[2] + 60, 255, 255, 255, 255, font, "SAFE")
    end
    end

end

end

function painttraverse_hk(one, two, three, four)
    local panel = two -- for some reason i had to do this, no idea why tho
    local panel_name = ffi.string(get_panel_name(one, panel))
    if(panel_name == "FocusOverlayPanel") then -- You can change this
        on_draw()
    end
    orig(one, two, three, four)
end
orig = VGUI_Panel009.hookMethod("void(__thiscall*)(void*, unsigned int, bool, bool)", painttraverse_hk, 41)

Cheat.RegisterCallback("destroy", function()
    for i, unHookFunc in ipairs(vmt_hook.hooks) do
        unHookFunc() -- unload all hooks
    end
end)

-- ESOSTERIK RENDER END


local function NewColor(r, g, b, a)
    return Color.new(r / 255, g / 255, b / 255, a / 255)
end


local screen = EngineClient.GetScreenSize()
local fake_fraction = 0
local real_rotation = 0
local function delta_angle(angle)
    local angle = math.fmod(angle, 360.0)

    if angle &gt; 180.0 then
        angle = angle - 360.0
    end

    if angle &lt; -180.0 then
        angle = angle + 360.0
    end

    return angle
end
local function createmovecalc()
    if ClientState.m_choked_commands == 0 then
        real_rotation = AntiAim.GetCurrentRealRotation()
    end

    local max_delta = AntiAim.GetMaxDesyncDelta() + math.abs(AntiAim.GetMinDesyncDelta())
    local delta = math.abs(delta_angle(real_rotation - AntiAim.GetFakeRotation())) / max_delta

    if delta &gt; 1.0 then
        delta = 1.0
    end

    fake_fraction = delta
end


function idealyaw_indicators()
    
    --If we are connected
    if not EngineClient.IsConnected() then
        return
    end

    -- if we are not ingame.
    if not EngineClient.IsInGame() then
        return
    end

    --localplayer check
    local localplayer = EntityList.GetLocalPlayer()
    local player = localplayer:GetPlayer()

    if not localplayer then return end

   	local lifestate = localplayer:GetProp("m_lifeState") == false

    local manual_aa = Menu.FindVar("Aimbot", "Anti Aim", "Main", "Yaw Base")
	local yOffset = 0
	local charge = Exploits.GetCharge()

	ideal_txt = "XOXA YAW"
    if is_anti_bruting == false then
	ideal_color = NewColor(215, 114, 44, 255)
    else
       
        if is_anti_bruting == true and should_be_low_delta == true then
            ideal_color = NewColor(255, 0, 0, 255)
        else
            ideal_color = NewColor(0, 117, 0, 255)
        end
    end

	if lifestate then

	if indicator_type:GetInt() == 3 then
		
		if manual_aa:GetInt() == 2 or manual_aa:GetInt() == 3 then
			ideal_txt = "XOXA YAW"
			ideal_color = NewColor(177, 151, 255, 255)
		end


        local arrow_size = Render.CalcTextSize("&gt;", 25)

        if manual_aa:GetInt() == 2 then
			Render.Text("&gt;", Vector2.new(screen.x / 2 - 1 + 45, screen.y / 2 - 1 - arrow_size.y / 2), ideal_color, 30)
            Render.Text("&lt;", Vector2.new(screen.x / 2 - arrow_size.x - 45, screen.y / 2 - 1 - arrow_size.y / 2), Color.new(1, 1, 1), 30)
		end

        if manual_aa:GetInt() == 3 then
			Render.Text("&lt;", Vector2.new(screen.x / 2 - arrow_size.x - 45, screen.y / 2 - 1 - arrow_size.y / 2), ideal_color, 30)
            Render.Text("&gt;", Vector2.new(screen.x / 2 - 1 + 45, screen.y / 2 - 1 - arrow_size.y / 2), Color.new(1, 1, 1), 30)
		end

        local spacement = 15

		Render.Text(ideal_txt, Vector2.new(screen.x / 2, screen.y / 2 + spacement + yOffset), ideal_color, 12, false)

    --    g_Render:Text("                    v2", Vector2.new(screen.x / 2, screen.y / 2 + spacement - 1 + yOffset), NewColor(152,152,152,255), 12, true)

	 	yOffset = yOffset + 12

		local pitch = Menu.FindVar("Aimbot", "Anti Aim", "Main", "Yaw Base"):GetInt()

		if pitch == 4 then
			pitch_txt = "DYNAMIC"
			pitch_color =  NewColor(196, 132, 215, 255)
		else
			pitch_txt = "DEFAULT"
			pitch_color =  NewColor(215, 0, 0, 255)
		end

        Render.Text(pitch_txt, Vector2.new(screen.x / 2, screen.y / 2 + spacement + yOffset), pitch_color, 12, false)

	if doubletap == true then
		if charge == 1 then
			dtcolor = Color.new(0, 1, 0, 1)
		else
			dtcolor = Color.new(1, 0, 0, 1)
		end
	
		yOffset = yOffset + 12
        Render.Text("DT", Vector2.new(screen.x / 2, screen.y / 2 + spacement + yOffset), dtcolor, 12, false)
	end

	if hideshots == true then
		yOffset = yOffset + 12
        Render.Text("AA", Vector2.new(screen.x / 2, screen.y / 2 + spacement + yOffset), NewColor(196, 132, 215, 255), 12, false)
	end
end
end
end


local player_state = "none"
local function in_air(player)
    local local_idx = EngineClient.GetLocalPlayer()
  local local_entity = EntityList.GetClientEntity(local_idx)

  if local_entity == nil then
    return
  end
  
  local localplayer = local_entity:GetPlayer();
    local flags = localplayer:GetProp("DT_BasePlayer", "m_fFlags")
      if bit.band(flags, 1) == 0 then
        return true
      end
      return false
  end
  
function player_states()
    local me = EntityList.GetLocalPlayer()
    local velocity = Vector.new(me:GetProp("m_vecVelocity[0]"), me:GetProp("m_vecVelocity[1]"), me:GetProp("m_vecVelocity[2]")) 
    local velo = velocity:Length2D()
    local speed = math.floor(velo)

    if in_air(player) then
        player_state = "air"
    else

        if speed &lt;= 1 then
            player_state = "standing"
        else
            if ref_slowwalk:GetBool() then
            player_state = "slow"
            else
                player_state = "moving"
            end

        end

    end
  end



local last_pitch = ref_pitch:GetInt()
local last_yaw = ref_yaw:GetInt()

local was_in_use = false

local function legit_aa(cmd)
    if bit.band(cmd.buttons, bit.lshift(1,5)) ~= 0 and legitaa:GetBool() then
        cmd.buttons = bit.band(cmd.buttons, bit.bnot(bit.lshift(1,5)))
        was_in_use = true
    else
        was_in_use = false
    end
end



local function vec_distance(vec_one, vec_two)

    local delta_x, delta_y, delta_z = vec_one.x - vec_two.x, vec_one.y - vec_two.y

    return math.sqrt(delta_x * delta_x + delta_y * delta_y)

end

local function get_closest_enemy()
    local best_dist = 380.0
    local best_enemy = nil
    local me = EntityList.GetLocalPlayer()
    local local_origin = me:GetProp("DT_BaseEntity", "m_vecOrigin")
    local local_screen_orig = Render.ScreenPosition(local_origin)
    local screen = EngineClient.GetScreenSize()

    for idx = 1, GlobalVars.maxClients + 1 do
        local ent = EntityList.GetClientEntity(idx)
        if ent and ent:IsPlayer() then
            local player = ent:GetPlayer()
            local health = player:GetProp("DT_BasePlayer", "m_iHealth")

            if not player:IsTeamMate() and health &gt; 0 and not player:IsDormant() then
                local origin = ent:GetProp("DT_BaseEntity", "m_vecOrigin")
                local screen_orig = Render.ScreenPosition(origin)
                local temp_dist = vec_distance(Vector2.new(screen.x / 2, screen.y / 2), screen_orig)

                if(temp_dist &lt; best_dist) then
                    best_dist = temp_dist
                    best_enemy = ent
                end
            end
        end
    end

    return best_enemy
end


local lines = {}
local results = {}

-- local function impacts_events(event)
--     if event:GetName() == "bullet_impact" and event:GetInt("userid") == EntityList.GetLocalPlayer():GetPlayerInfo().userId then
--         local me = EntityList.GetLocalPlayer()
--         if me then me = me:GetPlayer() else return end
--         local position = me:GetEyePosition()
--         local destination = Vector.new(event:GetFloat("x"), event:GetFloat("y"), event:GetFloat("z"))
--         table.insert(lines, {pos = position, destination = destination, time = 250, curtime = GlobalVars.curtime})
--     end

--     if event:GetName() == "player_hurt" then
--         if event:GetInt("attacker") == EntityList.GetLocalPlayer():GetPlayerInfo().userId then
--             for k,v in pairs(lines) do
--                 if v.curtime == GlobalVars.curtime then
--                     table.insert(results, lines[k])
--                     table.remove(lines, k)
--                 end
--             end
--         end
--     end
-- end


local miss_counter = 0
local shot_time = 0
local should_be_low_delta = false
local function antibrute(event)

      if event:GetName() == "weapon_fire" then 
        local user_id = event:GetInt("userid", -1)
        local user = EntityList.GetPlayerForUserID(user_id) 
        local me = EntityList.GetLocalPlayer() 
        local player = me:GetPlayer()
        local health = player:GetProp("DT_BasePlayer", "m_iHealth")

        if(health &gt; 0) then 
            local user_x = event:GetInt("x", -1)
            local user_y = event:GetInt("y", -1)
            local user_z = event:GetInt("z", -1)
            local me = EntityList.GetLocalPlayer()
            local shooter = user
            if(shooter == nil)then return end
            local closest_enemy = get_closest_enemy() 
            if (closest_enemy == nil) then return end
            if (not shooter:EntIndex() == closest_enemy:EntIndex()) then return end

            local shooterpos = shooter:GetPlayer():GetProp("DT_BaseEntity", "m_vecOrigin")
            local hitbox = shooter:GetPlayer():GetHitboxCenter(0)
            local pos = me:GetProp("DT_BaseEntity", "m_vecOrigin")
            local distance = pos:DistTo(shooterpos)
           
           

            if(closest_enemy ~= nil and user:EntIndex() == closest_enemy:EntIndex() and math.abs(distance) &lt;= 1000) then
                --print(math.abs(distance)) 
                if (math.abs(distance)) &lt;= 250 then
                    should_be_low_delta = true
                else
                    should_be_low_delta = false
                end              
              miss_counter = miss_counter + 1 
        shot_time = GlobalVars.curtime
            end
        end
    end
end


local is_dormant = false
local antiaim_state = ""
local function on_createmove(cmd)
    player_states()
    local me = EntityList.GetLocalPlayer()
    createmovecalc()

-- RAGE

--note
-- tas todo quebrado companheiro, mas sem problema! ta aqui o mestre!!!
-- index: https://developer.valvesoftware.com/wiki/List_of_CS:GO_Cvars
local tickbase_manager = 0


if enable_rage:GetBool() then 
    if enable_dt:GetBool() then
if dt_mode:GetBool(1) then
    tickbase_manager = 15
elseif dt_mode:GetBool(2) then
    Exploits.ForceTeleport()
    tickbase_manager = 16
end


CVar.FindVar("cl_clock_correction_adjustment_max_amount"):SetInt(15) -- Sets the maximum number of milliseconds per second it is allowed to correct the client clock. It will only correct this amount
local x = math.random(0,100000000000000000000000)
if x &gt; 50000000000000000000000 then
    CVar.FindVar("cl_clock_correction"):SetInt(1) -- neverlose ja faz isto, mas para evitar 3rd script's, vamos forcar isto :D
    CVar.FindVar("cl_clock_correction_adjustment_max_offset"):SetInt(17)
else
    CVar.FindVar("cl_clock_correction"):SetInt(0)
    CVar.FindVar("cl_clock_correction_adjustment_max_offset"):SetInt(7)
end

CVar.FindVar("cl_clock_correction_force_server_tick"):SetInt(0) -- Force clock correction to match the server tick + this offset (-999 disables it). | Em resumo, uma "forma" de dar bypass a cl_lagcompensation
CVar.FindVar("cl_clock_correction_adjustment_min_offset"):SetInt(0)
else
    tickbase_manager = 15 -- valor normal do neverlose (acho eu)
end
Exploits.OverrideDoubleTapSpeed(tickbase_manager)
end
-- end rage


-- MISC

if enable_misc:GetBool() then 


--note
-- Totalmente uma maneira "melhor" de fazer um leg breaker, nao vou usar poseparameter pois o neverlose em si ja usa.
	local localplayer = EntityList.GetClientEntity(EngineClient.GetLocalPlayer())
	if not localplayer then return end
    if leg_fucker:GetBool() then
    ffi.cast("float*", ffi_helpers.get_entity_address(localplayer:EntIndex()) + 10100)[math.random(-1,2)] = math.random(-1,2)
    local test_1 = math.random(0,5)
    local menu_leg_movement = Menu.FindVar("Aimbot", "Anti Aim", "Misc", "Leg Movement")
    if test_1 == 1 then
        menu_leg_movement:SetInt(1)
    else if test_1 == 2 then
        menu_leg_movement:SetInt(2)
    else if test_1 == 3 then
        menu_leg_movement:SetInt(0)
    else if test_1 == 4 then
        menu_leg_movement:SetInt(2)
    end
    end
    end
    end
end

if anti_defensive2:GetBool() then
    CVar.FindVar("cl_lagcompensation"):SetInt(0) 
    -- CVar.FindVar("cl_predictweapons"):SetInt(0) --Perform client side prediction of weapon effects.
else
    CVar.FindVar("cl_lagcompensation"):SetInt(1) 
    -- CVar.FindVar("cl_predictweapons"):SetInt(1)
end




end
-- end misc

-- AA


if enable_antiaim:GetBool() then  
    if disable_warmup:GetBool() then
    if (EntityList.GetGameRules():GetProp("m_bHasMatchStarted") == false) then
        ref_anti_aim_enable:SetBool(false)
    else
        ref_anti_aim_enable:SetBool(true)
    end
end

if was_in_use then
    if not FakeLag.Choking() then
        ref_yaw:SetInt(0)
        ref_pitch:SetInt(0)
        ref_left_limit:SetInt(Utils.RandomInt(25, 60))
        ref_right_limit:SetInt(Utils.RandomInt(25, 60))
    end

    return
end


--note
-- NAO FAÇAS ISTO ZE RIC, a chance de levares HS no ar com esta merda é tipo 90%
-- para evitar levares headshots nao des override a nada, mete simplesmente static com talvez um mini yaw change com logica atras
-- como por exemplo, last hurt yaw.
-- talvez faça depois,sem paciencia agora.

--if Cheat.IsKeyDown(0x20) then
  --  local lby_int = Utils.RandomInt(0, 10)
    --    if lby_int &lt; 5 then
   --         ref_inverter:SetBool(true)
  --          AntiAim.OverrideLBYOffset(58)
   --     end
  --      if lby_int &gt; 5 then
  --          AntiAim.OverrideLBYOffset(-58)
  --          ref_inverter:SetBool(false)
  --      end
--return
--end 

data = get_target()

if data.id == nil then
    is_dormant = true
    ref_right_limit:SetInt(60)
    ref_left_limit:SetInt(60)   
    ref_jitter_range:SetInt(0)  
    ref_yawadd:SetInt(0)  
    if (dormant_type:GetInt() == 0) then
       -- Nada muda
    end
    if (dormant_type:GetInt() == 1) then
        ref_fake_options:SetInt(2)
     end
return
    else
        is_dormant = false
    end

ref_fake_options:SetInt(1)
local maybe_invert = 0
if AntiAim.GetInverterState() == true then
    maybe_invert = 1
else
    maybe_invert = -1
end


    ref_jitter_type:SetInt(1)        
  
      

if (aa_modes:GetInt() == 3) then
    if player_state == "standing" then
   ref_yawadd:SetInt(Utils.RandomInt(-10,20) * maybe_invert)
   if is_anti_bruting == false then
   ref_right_limit:SetInt(21)
    ref_left_limit:SetInt(17) 
   end
    ref_jitter_range:SetInt(11)   
     end

     if player_state == "moving" or player_state == "air" then
        ref_yawadd:SetInt(Utils.RandomInt(-5,10) * maybe_invert)
        ref_jitter_range:SetInt(math.random(-2,2))  
     end

     if player_state == "slow" then
        if is_anti_bruting == false then      
        ref_right_limit:SetInt(Utils.RandomInt(11,24))
    ref_left_limit:SetInt(Utils.RandomInt(35,20)) 
        end
     end

else if (aa_modes:GetInt() == 1) then
   

if player_state == "standing" then
    if is_anti_bruting == false then
    ref_right_limit:SetInt(21)
    ref_left_limit:SetInt(21) 
    end
    
end

if player_state == "slow" then
    if is_anti_bruting == false then
    ref_right_limit:SetInt(24)
    ref_left_limit:SetInt(4)   
    end
    if AntiAim.GetInverterState() == true then
        ref_yawadd:SetInt(math.random(0, -3))
    else
        ref_yawadd:SetInt(math.random(0, 5))
    end
    
end

if player_state == "moving" or player_state == "air" then
    if is_anti_bruting == false then
    ref_right_limit:SetInt(18)
    ref_left_limit:SetInt(35)   
    end
    if AntiAim.GetInverterState() == true then
        ref_yawadd:SetInt(-1)
    else
        ref_yawadd:SetInt(-3)
    end
                   
end

if (jitter_mode:GetBool()) then
if player_state == "standing" then
    ref_jitter_range:SetInt(8 * maybe_invert)         
end
if player_state == "moving" then
    ref_jitter_range:SetInt(0 * maybe_invert)  
end
if player_state == "slow" then
    ref_jitter_range:SetInt(4 * maybe_invert)         
end
if player_state == "air" then
    ref_jitter_range:SetInt(0 * maybe_invert)         
end
end

elseif (aa_modes:GetInt() == 2) then
    if is_anti_bruting == false then
    if player_state == "moving" or player_state == "air" then
        ref_left_limit:SetInt(Utils.RandomInt(25,60))
    ref_right_limit:SetInt(Utils.RandomInt(35,math.random(40,50)))
     end

     if player_state == "standing" then
        ref_left_limit:SetInt(Utils.RandomInt(15,35))
    ref_right_limit:SetInt(Utils.RandomInt(math.random(20,30),45))
     end

     if player_state == "slow" then
        ref_left_limit:SetInt(Utils.RandomInt(25,45))
    ref_right_limit:SetInt(Utils.RandomInt(math.random(40,50),45))
     end
    end
   

   
        if player_state == "standing" then
            ref_jitter_range:SetInt(Utils.RandomInt(2,13) * maybe_invert)     
            ref_yawadd:SetInt(5 * maybe_invert)    
        end
        if player_state == "moving" then
            ref_jitter_range:SetInt(2 * maybe_invert)  
            ref_yawadd:SetInt(math.random(0,8) * maybe_invert)  
        end
        if player_state == "slow" then
            ref_jitter_range:SetInt(4 * maybe_invert)    
            ref_yawadd:SetInt(Utils.RandomInt(3,9) * maybe_invert)       
        end
        if player_state == "air" then
            ref_yawadd:SetInt(Utils.RandomInt(3,12) * maybe_invert) 
            ref_jitter_range:SetInt(1 * maybe_invert)         
        end
        

end

end




local info = {
    side = nil,
}

local local_player = EntityList.GetClientEntity(EngineClient.GetLocalPlayer())

target = {
    id = (data == nil) and nil or data.id,
    yaw = (data == nil) and nil or data.yaw,

}

info.side = get_freestand_side(target,0)

if info.side == 0 or info.side == 1 then
    antiaim_state = "normal"
else
    antiaim_state = "extended"
end

    ref_freestand_desync:SetInt(0) -- com todo o respeito, vai po caralho. obrigado

   if info.side == 0 or info.side == 2  then
    if (freestand_type:GetInt() == 0) then
        ref_inverter:SetBool(true)
    else
        ref_inverter:SetBool(false)
    end
   end

   if info.side == 1 or info.side == nil then
    if (freestand_type:GetInt() == 0) then
        ref_inverter:SetBool(false)
    else
        ref_inverter:SetBool(true)
    end
   end

   if info.side == 5  then
    if (freestand_type:GetInt() == 0) then
        ref_inverter:SetBool(true)
    else
        ref_inverter:SetBool(false)
    end
   end




if me == nil then return end
if shot_time + 2 &gt; GlobalVars.curtime  then
    is_anti_bruting = true
else
    is_anti_bruting = false
end
-- fix delta bug xd
if is_anti_bruting == false and should_be_low_delta == true then
    should_be_low_delta = false
end

		local aa_type = aa_modes:GetInt()

		local local_m_lifeState = me:GetProp("DT_BasePlayer", "m_lifeState")
		if local_m_lifestate then return end
			local inverter = AntiAim.GetInverterState()
            if shot_time + 2 &gt; GlobalVars.curtime and should_be_low_delta == true and anti_brute_delta:GetBool() then
                
                if (miss_counter % 3 == 0) then
                    ref_left_limit:SetInt(math.random(20,25))
                    ref_right_limit:SetInt(math.random(20,25))
                end
                if (miss_counter % 3 == 1) then
                    ref_left_limit:SetInt(17)
                    ref_right_limit:SetInt(17)
                    end

                else

			if shot_time + 2 &gt; GlobalVars.curtime  then
				if anti_brute:GetInt() == 1 then
                    local is_reversed = ref_inverter:GetBool()
                    local inverter = false
                    local inverter_2 = true
                    if (miss_counter % 3 == 0) then
                        inverter = true
                        inverter_2 = false
                        ref_left_limit:SetInt(Utils.RandomInt(35,math.random(40,50)))
                            ref_right_limit:SetInt(Utils.RandomInt(35,math.random(40,50)))
                    else if (miss_counter % 3 == 1) then
                        inverter = false
                        inverter_2 = true
                        ref_left_limit:SetInt(60)
                            ref_right_limit:SetInt(60)
                    end
                    end
                    
                           -- print("ANTI-BRUTE | 1" )
                           if (is_reversed == true) then  
                            AntiAim.OverrideInverter(inverter_2)
                           end
                           if (is_reversed == false) then
                            AntiAim.OverrideInverter(inverter)
                        end   
				end
				if anti_brute:GetInt() == 2 then
					 if (miss_counter % 3 == 0) then --Logic 1
						AntiAim.OverrideInverter(false)

					else if (miss_counter % 3 == 1) then --Logic 2
						AntiAim.OverrideInverter(false)

					else if (miss_counter % 3 == 2) then --Logic 3
						AntiAim.OverrideInverter(true)
						end
					end
				end
			
            end
			-- else

            

	end



end
end
-- end aa

end







Cheat.RegisterCallback("createmove", function(cmd)
    local me = EntityList:GetLocalPlayer()
    local weap = me:GetPlayer():GetActiveWeapon()
    if not weap then return end
    if was_in_use then
        if not in_bomb_site then
            cmd.buttons = bit.bor(cmd.buttons, bit.lshift(1,5))
        end
        was_in_use = false
        ref_yaw:SetInt(last_yaw)
        ref_pitch:SetInt(last_pitch)
    end
end)



local hstable = {
    "1 H$"
}

local function get_hstable()
    return hstable[Utils.RandomInt(1, #hstable)]:gsub('\"', '')
end

local baimtable = {
    "iq", 
    -- "f12", 
    "morre"
}

local function get_baimtable()
    return baimtable[Utils.RandomInt(1, #baimtable)]:gsub('\"', '')
end

local other = { 
    knife = '2 facadas 1 pulseira', 
    hegrenade = 'Senta', 
    inferno = 'queima judeu', 
    taser = 'eletrocutado',
}

buybot_delay2 = GlobalVars.curtime + 100000 --1 mill sec to make sure it only triggers 1 time

local function trashtalk_event(event)

    -- TRASHTALK
    if event:GetName() ~= "player_death" then return end

    me = EntityList.GetLocalPlayer()
    victim = EntityList.GetPlayerForUserID(event:GetInt("userid"))
    attacker = EntityList.GetPlayerForUserID(event:GetInt("attacker"))

    weapon_used = event:GetString("weapon", "unknown")

    is_headshot = event:GetBool("headshot", false)


    if victim == attacker or attacker ~= me then return end


    buybot_delay2 = GlobalVars.curtime + trashtalk_time:GetInt() --delay time (in sec)
    -- if trashtalk:GetBool() then 

	-- 	if is_headshot then
	-- 		EngineClient.ExecuteClientCmd('say "' .. get_hstable() .. '"')
    --     elseif not is_headshot and not other[weapon_used] then
    --         EngineClient.ExecuteClientCmd('say "' .. get_baimtable() .. '"')
    --     else
    --         EngineClient.ExecuteClientCmd('say "' .. other[weapon_used] .. '"')
	-- 	end
	
    -- end
  

-- TRASHTALK

end



function buybot_draw2()

    

    if trashtalk:GetBool() and enable_misc:GetBool() then -- check if its active

    if buybot_delay2 &lt; GlobalVars.curtime then
    	if is_headshot then
			EngineClient.ExecuteClientCmd('say "' .. get_hstable() .. '"')
        elseif not is_headshot and not other[weapon_used] then
            EngineClient.ExecuteClientCmd('say "' .. get_baimtable() .. '"')
        else
            EngineClient.ExecuteClientCmd('say "' .. other[weapon_used] .. '"')
		end
  
      buybot_delay2 = GlobalVars.curtime + 1000000 --1 mill sec to make sure it only triggers 1 time
    end

end  
end  

verdana = Render.InitFont("Verdana", 12, {'b'})

local function indicators_draw()

    local indicator_color = visual_color:GetColor()
    local inverter_state = AntiAim.GetInverterState()
    local screen = EngineClient:GetScreenSize()

    if not EngineClient:IsConnected() then
        return
    end

    if (indicator_type:GetInt() == 1) then

       
    if inverter_state == true then
    Render.Text("XOXA", Vector2.new(screen.x / 2 - 17, screen.y / 2 + 20), indicator_color, 12, verdana, false, true)
    Render.Text("SYNC", Vector2.new(screen.x / 2 + 17, screen.y / 2 + 20), Color.new(1, 1, 1, 1), 12, verdana, false, true)
    else
    Render.Text("XOXA", Vector2.new(screen.x / 2 - 17, screen.y / 2 + 20), Color.new(1, 1, 1, 1), 12, verdana, false, true)
    Render.Text("SYNC", Vector2.new(screen.x / 2 + 17, screen.y / 2 + 20), indicator_color, 12, verdana, false, true)
    end


    if doubletap then
        Render.Text("double tap", Vector2.new(screen.x / 2, screen.y / 2 + 30), indicator_color, 11, verdana, false, true)
    else
        Render.Text("double tap", Vector2.new(screen.x / 2, screen.y / 2 + 30), Color.new(0.6, 0.6, 0.6, 0.6), 11, verdana, false, true)
    end

    if hideshots then
        Render.Text("hide shots", Vector2.new(screen.x / 2, screen.y / 2 + 40), indicator_color, 11, verdana, false, true)
    else
        Render.Text("hide shots", Vector2.new(screen.x / 2, screen.y / 2 + 40), Color.new(0.6, 0.6, 0.6, 0.6), 11, verdana, false, true)
    end



    if indicators:GetBool(1) then 
        body_size = 60
    else
        body_size = 50
    end

    if indicators:GetBool(1) and indicators:GetBool(2) then 
        sp_size = 70
    elseif indicators:GetBool(1) or indicators:GetBool(2) then
        sp_size = 60
    else 
        sp_size = 50
    end

    if indicators:GetBool(1) then
        if min_dmg then
            Render.Text("min dmg", Vector2.new(screen.x / 2, screen.y / 2 + 50), indicator_color, 11, verdana, false, true)
        else
            Render.Text("min dmg", Vector2.new(screen.x / 2, screen.y / 2 + 50), Color.new(0.6, 0.6, 0.6, 0.6), 11, verdana, false, true)
        end
    end

    if indicators:GetBool(2) then
        if bodyaim then
            Render.Text("body aim", Vector2.new(screen.x / 2, screen.y / 2 + body_size), indicator_color, 11, verdana, false, true)
        else
            Render.Text("body aim", Vector2.new(screen.x / 2, screen.y / 2 + body_size), Color.new(0.6, 0.6, 0.6, 0.6), 11, verdana, false, true)
        end
    end 


    if indicators:GetBool(3) then
        if safepoint then
            Render.Text("safe point", Vector2.new(screen.x / 2, screen.y / 2 + sp_size), indicator_color, 11, verdana, false, true)
        else
            Render.Text("safe point", Vector2.new(screen.x / 2, screen.y / 2 + sp_size), Color.new(0.6, 0.6, 0.6, 0.6), 11, verdana, false, true)
        end
    end 

    end


    local lpx = Vector2.new(screen.x / 2 - 42, screen.y / 2 + 9)
    local lpy = Vector2.new(screen.x / 2 - 42, screen.y / 2 - 9)
    local lpz = Vector2.new(screen.x / 2 - 54, screen.y / 2)

    local rpx = Vector2.new(screen.x / 2 + 42, screen.y / 2 + 9)
    local rpy = Vector2.new(screen.x / 2 + 42, screen.y / 2 - 9)
    local rpz = Vector2.new(screen.x / 2 + 55, screen.y / 2)

    local inactive = Color.new(20 / 255, 20 / 255, 20 / 255, 0.5) -- RGB: 20, 20, 20, 128

    local localplayer = EntityList.GetLocalPlayer()
    if not localplayer then return end

    local lifestate = localplayer:GetProp("m_lifeState") == false


    if (teamskeet_arrows:GetBool() and enable_visuals:GetBool()) and lifestate then

        if ref_yaw:GetInt() == 3 then
            Render.PolyFilled(second_color:GetColor(), lpx, lpy, lpz)
        else
            Render.PolyFilled(inactive, lpx, lpy, lpz)
        end
        
        if ref_yaw:GetInt() == 2 then
            Render.PolyFilled(second_color:GetColor(), rpx, rpy, rpz)
        else
            Render.PolyFilled(inactive, rpx, rpy, rpz)
        end

        if inverter_state == true then
            Render.BoxFilled(Vector2.new(screen.x / 2 - 40, screen.y / 2 - 9), Vector2.new(screen.x / 2 - 38 , screen.y / 2 + 9), visual_color:GetColor())
        else
            Render.BoxFilled(Vector2.new(screen.x / 2 - 40, screen.y / 2 - 9), Vector2.new(screen.x / 2 - 38, screen.y / 2 + 9), inactive)
        end

        if inverter_state == false then
            Render.BoxFilled(Vector2.new(screen.x / 2 + 40, screen.y / 2 - 9), Vector2.new(screen.x / 2 + 38, screen.y / 2 + 9), visual_color:GetColor())
        else
            Render.BoxFilled(Vector2.new(screen.x / 2 + 40, screen.y / 2 - 9), Vector2.new(screen.x / 2 + 38, screen.y / 2 + 9), inactive)
        end

    end

end


function invictus_indicators()
  --If we are connected
  if not EngineClient.IsConnected() then
    return
end

-- if we are not ingame.
if not EngineClient.IsInGame() then
    return
end

--localplayer check
local localplayer = EntityList.GetLocalPlayer()
local player = localplayer:GetPlayer()

if not localplayer then return end

local lifestate = localplayer:GetProp("m_lifeState") == false


if lifestate then
local fake = math.ceil(fake_fraction * 58)


local color_dsy = visual_color:GetColor()
local inverterr = Menu.FindVar("Aimbot", "Anti Aim", "Fake Angle", "Inverter") --Check for inverter
local arrow_size = Render.CalcTextSize("&gt;", 30)


if indicator_type:GetInt() == 2 then
    local center = {screen_size.x/ 2, screen_size.y/ 2}
    
    Render.Text("fonsi.lua", Vector2.new(screen.x / 2, screen.y / 2 + 30), NewColor(255,255,255,255), 12, false, true)
    -- fake
    Render.Text(tostring(fake) .. "°", Vector2.new(screen.x / 2 + 2 - Render.CalcTextSize(tostring(fake) .. "°", 11).x / 2, screen.y / 2 +8), Color.new(1, 1, 1, 1), 11)
 

if is_dormant == false then
    if inverterr:GetBool() then
        
        Render.Text("&gt;", Vector2.new(screen.x / 2 - 1 + 45, screen.y / 2 - 1 - arrow_size.y / 2), Color.new(1, 1, 1), 30) --0.1,0.5,0.8
        Render.Text("&lt;", Vector2.new(screen.x / 2 - arrow_size.x - 45, screen.y / 2 - 1 - arrow_size.y / 2), Color.new(color_dsy.r, color_dsy.g, color_dsy.b), 30)

    else 
        
        Render.Text("&gt;", Vector2.new(screen.x / 2 - 1 + 45, screen.y / 2 - 1 - arrow_size.y / 2), Color.new(color_dsy.r, color_dsy.g, color_dsy.b), 30)
        Render.Text("&lt;", Vector2.new(screen.x / 2 - arrow_size.x - 45, screen.y / 2 - 1 - arrow_size.y / 2), Color.new(1, 1, 1), 30)

    end

end
    -- desync bar
    Render.GradientBoxFilled(Vector2.new(screen.x/2, screen.y/2+21), Vector2.new(screen.x/2+(math.abs(fake) - 15), screen.y/2+23), Color.new(color_dsy.r, color_dsy.g, color_dsy.b), Color.new(color_dsy.r, color_dsy.g, color_dsy.b, 0), Color.new(color_dsy.r, color_dsy.g, color_dsy.b), Color.new(color_dsy.r, color_dsy.g, color_dsy.b,0))
    Render.GradientBoxFilled(Vector2.new(screen.x/2, screen.y/2+21), Vector2.new(screen.x/2+(-math.abs(fake) + 15), screen.y/2+23), Color.new(color_dsy.r, color_dsy.g, color_dsy.b), Color.new(color_dsy.r, color_dsy.g, color_dsy.b, 0), Color.new(color_dsy.r, color_dsy.g, color_dsy.b), Color.new(color_dsy.r, color_dsy.g, color_dsy.b,0))
end
end
end

MenuVisibility = function()

	local switch_antiaim = enable_antiaim:GetBool()
    local switch_rage = enable_rage:GetBool()
    local switch_visuals = enable_visuals:GetBool()
    local switch_misc = enable_misc:GetBool()
    local switch_brute = anti_brute:GetInt()
    local switch_ind = indicator_type:GetInt()
    local switch_cona = aa_modes:GetInt()
	local dt_switch = enable_dt:GetBool()
    local arrow_switch = teamskeet_arrows:GetBool()
    local switch_tt = trashtalk:GetBool()



    -- AA TAB
    local aa_bool = false

    local aa_tab = false
    local aa_tab_enable = false

    if tab_select:GetInt() == 0 then
	aa_bool = true
	aa_tab = true
    end

    if switch_antiaim and aa_tab == true then
	aa_tab_enable = true
    else
	aa_tab_enable = false
    end

	
    enable_antiaim:SetVisible(aa_bool);
	legitaa:SetVisible(aa_tab_enable);
    aa_modes:SetVisible(aa_tab_enable);
    freestand_type:SetVisible(aa_tab_enable);
    dormant_type:SetVisible(aa_tab_enable);
    anti_brute:SetVisible(aa_tab_enable);
    --low_delta_slow:SetVisible(aa_tab_enable);
    jitter_mode:SetVisible(aa_tab_enable);
    anti_brute_delta:SetVisible(aa_tab_enable and (switch_brute == 1 or switch_brute == 2));
    jitter_mode:SetVisible(aa_tab_enable and switch_cona == 1);
    disable_warmup:SetVisible(aa_tab_enable)
	-- AA TAB END



	-- RAGE TAB 
    local rage_bool = false

    local rage_tab = false
    local rage_tab_enable = false

    if tab_select:GetInt() == 1 then
    rage_bool = true
	rage_tab = true
    end

    if switch_rage and rage_tab == true then
	rage_tab_enable = true
    else
	rage_tab_enable = false
    end
 
    enable_rage:SetVisible(rage_bool);
    enable_dt:SetVisible(rage_tab_enable);
    dt_mode:SetVisible(dt_switch and rage_tab_enable);
    --disable_correction:SetVisible(dt_switch and switch_rage);
    -- anti_defensive:SetVisible(rage_tab_enable)
    anti_defensive2:SetVisible(rage_tab_enable)
    -- RAGE TAB END
   


    -- VISUALS TAB
    local visual_bool = false

    local visual_tab = false
    local visual_tab_enable = false

    if tab_select:GetInt() == 2 then
    visual_bool = true
    visual_tab = true
    end

    if switch_visuals and visual_tab == true then
    visual_tab_enable = true
    else
    visual_tab_enable = false
    end

    enable_visuals:SetVisible(visual_bool);
    indicators:SetVisible(visual_tab_enable);
    indicator_type:SetVisible(visual_tab_enable);
    visual_color:SetVisible(visual_tab_enable);
    teamskeet_arrows:SetVisible(visual_tab_enable);
    second_color:SetVisible(visual_tab_enable and arrow_switch);
    pulsate_alpha:SetVisible(visual_tab_enable)
	-- VISUALS TAB END



    -- MISC
    local misc_bool = false
    
    local misc_tab = false
    local misc_tab_enable = false

    if tab_select:GetInt() == 3 then
    misc_bool = true
    misc_tab = true
    end

    if switch_misc and misc_tab == true then
    misc_tab_enable = true
    else
    misc_tab_enable = false
    end
   
    enable_misc:SetVisible(misc_bool);
    leg_fucker:SetVisible(misc_tab_enable);
    trashtalk:SetVisible(misc_tab_enable);
    trashtalk_time:SetVisible(misc_tab_enable and switch_tt)


	-- MISC TAB END

end

enable_antiaim:RegisterCallback(MenuVisibility);
enable_rage:RegisterCallback(MenuVisibility);
enable_visuals:RegisterCallback(MenuVisibility);
enable_misc:RegisterCallback(MenuVisibility);
tab_select:RegisterCallback(MenuVisibility);

-- custom
-- dormant_aimbot:RegisterCallback(MenuVisibility);

enable_dt:RegisterCallback(MenuVisibility);
anti_brute:RegisterCallback(MenuVisibility);
teamskeet_arrows:RegisterCallback(MenuVisibility);
trashtalk:RegisterCallback(MenuVisibility)

MenuVisibility();

Cheat.AddNotify("fonsi.lua", "Welcome, " .. username .. " ")


local function events(event)

    trashtalk_event(event)
	antibrute(event)
    -- impacts_events(event)

end

Cheat.RegisterCallback("events", events)


Cheat.RegisterCallback("prediction", function()
on_createmove()
end)

Cheat.RegisterCallback("pre_prediction", function(cmd)
	legit_aa(cmd)
end)

Cheat.RegisterCallback("draw", function()
	handle_binds()
    indicators_draw()
    idealyaw_indicators()
    invictus_indicators()
end)

Cheat.RegisterCallback("frame_stage", function()
    buybot_draw2()
  end)
