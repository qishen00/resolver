local missed = 0
local _V3_MT = {}
NULL = 0;
M_PI = 3.14159265358979323846;
M_180_PI = 0.0174533;
M_PI_180 = 57.2958;
INT_MAX = 2147483647;
INFINITE = math.huge;

local ffi = require("ffi")
ffi.cdef[[
    bool DeleteUrlCacheEntryA(const char* lpszUrlName);
    void* __stdcall URLDownloadToFileA(void* LPUNKNOWN, const char* LPCSTR, const char* LPCSTR2, int a, int LPBINDSTATUSCALLBACK);
    int VirtualFree(void* lpAddress, unsigned long dwSize, unsigned long dwFreeType);
    void* VirtualAlloc(void* lpAddress, unsigned long dwSize, unsigned long  flAllocationType, unsigned long flProtect);
    int VirtualProtect(void* lpAddress, unsigned long dwSize, unsigned long flNewProtect, unsigned long* lpflOldProtect);
    typedef void (__thiscall* UpdateCSA_t)(void*);
    typedef struct { float id; } poses_t;
    typedef uintptr_t (__thiscall* GetClientEntity_4242425_t)(void*, int);
    typedef void* (__thiscall* GetClientEntity_void)(void*, int);
    typedef uintptr_t (__thiscall* GetClientEntityHandle_4242425_t)(void*, int);

    typedef struct
    {
        float x;
        float y;
        float z;
    } Vector_t;

    typedef struct
    {
        float			flAnimationTime;		//0x00
        float			flFadeOut;				//0x04
        void*			pStudioHdr;				//0x08
        int				nDispatchedSrc;			//0x0C
        int				nDispatchedDst;			//0x10
        int				iOrder;					//0x14
        int             nSequence;				//0x18
        float			flPrevCycle;			//0x1C
        float			flWeight;				//0x20
        float			flWeightDeltaRate;		//0x24
        float			flPlaybackRate;			//0x28
        float			flCycle;				//0x2C
        void*			pOwner;					//0x30
        int				nInvalidatePhysicsBits;	//0x34
    } animlayer_t;

    typedef struct
    {
        char pad[ 3 ];
        char m_bForceWeaponUpdate; //0x4
        char pad1[ 91 ];
        void* m_pBaseEntity; //0x60
        void* m_pActiveWeapon; //0x64
        void* m_pLastActiveWeapon; //0x68
        float m_flLastClientSideAnimationUpdateTime; //0x6C
        int m_iLastClientSideAnimationUpdateFramecount; //0x70
        float m_flAnimUpdateDelta; //0x74
        float m_flEyeYaw; //0x78
        float m_flPitch; //0x7C
        float m_flGoalFeetYaw; //0x80
        float m_flCurrentFeetYaw; //0x84
        float m_flCurrentTorsoYaw; //0x88
        float m_flUnknownVelocityLean; //0x8C
        float m_flLeanAmount; //0x90
        char pad2[ 4 ];
        float m_flFeetCycle; //0x98
        float m_flFeetYawRate; //0x9C
        char pad3[ 4 ];
        float m_fDuckAmount; //0xA4
        float m_fLandingDuckAdditiveSomething; //0xA8
        char pad4[ 4 ];
        float m_vOriginX; //0xB0
        float m_vOriginY; //0xB4
        float m_vOriginZ; //0xB8
        float m_vLastOriginX; //0xBC
        float m_vLastOriginY; //0xC0
        float m_vLastOriginZ; //0xC4
        float m_vVelocityX; //0xC8
        float m_vVelocityY; //0xCC
        char pad5[ 4 ];
        float m_flUnknownFloat1; //0xD4
        char pad6[ 8 ];
        float m_flUnknownFloat2; //0xE0
        float m_flUnknownFloat3; //0xE4
        float m_flUnknown; //0xE8
        float m_flSpeed2D; //0xEC
        float m_flUpVelocity; //0xF0
        float m_flSpeedNormalized; //0xF4
        float m_flFeetSpeedForwardsOrSideWays; //0xF8
        float m_flFeetSpeedUnknownForwardOrSideways; //0xFC
        float m_flTimeSinceStartedMoving; //0x100
        float m_flTimeSinceStoppedMoving; //0x104
        bool m_bOnGround; //0x108
        bool m_bInHitGroundAnimation; //0x109
        float m_flTimeSinceInAir; //0x10A
        float m_flLastOriginZ; //0x10E
        float m_flHeadHeightOrOffsetFromHittingGroundAnimation; //0x112
        float m_flStopToFullRunningFraction; //0x116
        char pad7[ 4 ]; //0x11A
        float m_flMagicFraction; //0x11E
        char pad8[ 60 ]; //0x122
        float m_flWorldForce; //0x15E
        char pad9[ 462 ]; //0x162
        float m_flMaxYaw; //0x334
    } CCSGOPlayerAnimationState_534535_t;
]]

local entity_list_pointer = ffi.cast('void***', utils.create_interface('client.dll', 'VClientEntityList003'))
local get_client_entity_fn = ffi.cast('GetClientEntity_4242425_t', entity_list_pointer[0][3])
function get_entity_address(ent_index)
    local addr = get_client_entity_fn(entity_list_pointer, ent_index)
    return addr
end

local function get_enemies(players) -- 获取敌人列表
    local ctable = {}
    for pi = 1, #players do
        local enemy = players[pi]
        if enemy ~= entity.get_local_player() then
            if enemy:is_enemy() then
                if not enemy:is_dormant() then
                    table.insert(ctable, enemy)
                end
            end
        end
    end
    return ctable
end

local function normalize_yaw(yaw)
	while yaw > 180 do yaw = yaw - 360 end
	while yaw < -180 do yaw = yaw + 360 end
	return yaw
end

local function calc_shit(xdelta, ydelta)
	if xdelta == 0 and ydelta == 0 then
		return 0
	end

	return math.deg(math.atan2(ydelta, xdelta))
end

function get_helikopter() -- 获取离准星最近的玩家
    local players = get_enemies(entity.get_players(true))
    if not players then return end
    if not entity.get_local_player() then return end
    if not entity.get_local_player():is_alive() then return end
    local eye = entity.get_local_player():get_eye_position()
    local viewangles = render.camera_angles()

    local bestenemy = nil
    local fov = 180

    for i = 1, #players do
        local enemy = players[i];
        local cur = enemy:get_origin()
        local cur_fov = math.abs(normalize_yaw(calc_shit(eye.x - cur.x, eye.y - cur.y) - viewangles.y + 180))
        if cur_fov < fov then
            fov = cur_fov
            bestenemy = enemy
        end
    end
    return bestenemy
end

local c_rage = {
    update_misses = function(shot)
        if shot.reason == 1 then
            missed = missed + 1
        end
    end,
    check_shots = function(e)
        if e.GetName() ~= "player death" then return end

        local me = entity.get_local_player()
        local victim = entity.get(e.userid, true)
        local attacker = entity.get(e.attacker, true)

        if victim == attacker or attacker ~= me then return end
        -- reset shots if the player we missed at died
        missed = 0
    end
}

local ffi_cast = ffi.cast

local function get_eyes_pos()
	local local_player = entity.get_local_player()
	local origin = local_player.m_vecOrigin
	local view_offset = local_player.m_vecViewOffset
	return vec3_t.new(origin.x + view_offset.x, origin.y + view_offset.y, origin.z + view_offset.z)
end

function get_aim_angle(enemyplayer)
    local pos = enemyplayer:get_player_hitbox_pos(10)
    local eyes = get_eyes_pos()
    local vec = vec3_t.new(pos.x/4 - eyes.x*4, pos.y/2 + eyes.y*5+10, pos.z/4 - eyes.z*4)
    local hyp = math.sqrt(vec.x*vec.x+vec.y*vec.y+vec.z*vec.z)

    pitch = -math.asin(vec.z / hyp) * 50.2143483343
end

local vmt_hook = {hooks = {}}
local buff = {free = {}}

local hook_helpers = {
    copy = function(void, source, length)
    return ffi.copy(ffi.cast("void*", void), ffi.cast("const void*", source), length)
    end,

    virtual_protect = function(point, size, new_protect, old_protect)
    return ffi.C.VirtualProtect(ffi.cast("void*", point), size, new_protect, old_protect)
    end,

    virtual_alloc = function(point, size, allocation_type, protect)
    local alloc = ffi.C.VirtualAlloc(point, size, allocation_type, protect)
    if blFree then
        table.insert(buff.free, function()
        ffi.C.VirtualFree(alloc, 0, 0x8000)
        end)
    end
    return ffi.cast('intptr_t', alloc)
end
}

function vmt_hook.new(vt)
    local new_hook = {}
    local org_func = {}
    local old_prot = ffi.new('unsigned long[1]')
    local virtual_table = ffi.cast('intptr_t**', vt)[0]

    new_hook.this = virtual_table
    new_hook.hookMethod = function(cast, func, method)
        org_func[method] = virtual_table[method]
        hook_helpers.virtual_protect(virtual_table + method, 4, 0x4, old_prot)

        virtual_table[method] = ffi.cast('intptr_t', ffi.cast(cast, func))
        hook_helpers.virtual_protect(virtual_table + method, 4, old_prot[0], old_prot)

        return ffi.cast(cast, org_func[method])
    end

    new_hook.unHookMethod = function(method)
        hook_helpers.virtual_protect(virtual_table + method, 4, 0x4, old_prot)
        local alloc_addr = hook_helpers.virtual_alloc(nil, 5, 0x1000, 0x40, false)
        local trampoline_bytes = ffi.new('uint8_t[?]', 5, 0x90)

        trampoline_bytes[0] = 0xE9
        ffi.cast('int32_t*', trampoline_bytes + 1)[0] = org_func[method] - tonumber(alloc_addr) - 5

        hook_helpers.copy(alloc_addr, trampoline_bytes, 5)
        virtual_table[method] = ffi.cast('intptr_t', alloc_addr)

        hook_helpers.virtual_protect(virtual_table + method, 4, old_prot[0], old_prot)
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

events.shutdown:set(function()
    for _, reset_function in ipairs(vmt_hook.hooks) do
        reset_function()
    end
end)

function math.round(number, precision)
	local mult = 10 ^ (precision or 0)

	return math.floor(number * mult + 0.5) / mult
end

function Vector3( x, y, z )
	if (type(x) ~= "number") then
		x = 0.0;
	end

	if (type(y) ~= "number") then
		y = 0.0;
	end

	if (type(z) ~= "number") then
		z = 0.0;
	end

	x = x or 0.0
	y = y or 0.0
	z = z or 0.0
	return setmetatable({x = x, y = y, z = z}, _V3_MT)
end

function _V3_MT.__eq(a, b)
	return a.x == b.x and a.y == b.y and a.z == b.z
end

function _V3_MT.__unm(a)
	return Vector3(
		-a.x,
		-a.y,
		-a.z
	)
end

function _V3_MT.__add(a, b)
	local a_type = type(a)
	local b_type = type(b)
	if (a_type == "table" and b_type == "table") then
		return Vector3(
			a.x + b.x,
			a.y + b.y,
			a.z + b.z
		)

	elseif (a_type == "table" and b_type == "number") then
		return Vector3(
			a.x + b,
			a.y + b,
			a.z + b
		)

	elseif (a_type == "number" and b_type == "table") then
		return Vector3(
			a + b.x,
			a + b.y,
			a + b.z
		)
	end
end

function _V3_MT.__sub(a, b)
	local a_type = type(a)
	local b_type = type(b)
	if (a_type == "table" and b_type == "table") then
		return Vector3(
			a.x - b.x,
			a.y - b.y,
			a.z - b.z
		)

	elseif (a_type == "table" and b_type == "number") then
		return Vector3(
			a.x - b,
			a.y - b,
			a.z - b
		)

	elseif (a_type == "number" and b_type == "table") then
		return Vector3(
			a - b.x,
			a - b.y,
			a - b.z
		)
	end
end

function _V3_MT.__mul(a, b)
	local a_type = type(a)
	local b_type = type(b)
	if (a_type == "table" and b_type == "table") then
		return Vector3(
			a.x * b.x,
			a.y * b.y,
			a.z * b.z
		)

	elseif (a_type == "table" and b_type == "number") then
		return Vector3(
			a.x * b,
			a.y * b,
			a.z * b
		)

	elseif (a_type == "number" and b_type == "table") then
		return Vector3(
			a * b.x,
			a * b.y,
			a * b.z
		)
	end
end

function _V3_MT.__div(a, b)
	local a_type = type(a)
	local b_type = type(b)
	if (a_type == "table" and b_type == "table") then
		return Vector3(
			a.x / b.x,
			a.y / b.y,
			a.z / b.z
		)

	elseif (a_type == "table" and b_type == "number") then
		return Vector3(
			a.x / b,
			a.y / b,
			a.z / b
		)

	elseif (a_type == "number" and b_type == "table") then
		return Vector3(
			a / b.x,
			a / b.y,
			a / b.z
		)
	end
end

function _V3_MT.__tostring(a)
	return "(" .. a.x .. ", " .. a.y .. ", " .. a.z .. ")"
end

function _V3_MT:clear()
	self.x = 0.0
	self.y = 0.0
	self.z = 0.0
end

function _V3_MT:unpack()
	return self.x, self.y, self.z
end

function _V3_MT:length_2d_sqr()
	return (self.x * self.x) + (self.y * self.y)
end

function _V3_MT:length_sqr()
	return (self.x * self.x) + (self.y * self.y) + (self.z * self.z)
end

function _V3_MT:length_2d()
	return math.sqrt(self:length_2d_sqr())
end

function _V3_MT:length()
	return math.sqrt(self:length_sqr())
end

function _V3_MT:dot(other)
	return (self.x * other.x) + (self.y * other.y) + (self.z * other.z)
end

function _V3_MT:cross(other)
	return Vector3(
		(self.y * other.z) - (self.z * other.y),
		(self.z * other.x) - (self.x * other.z),
		(self.x * other.y) - (self.y * other.x)
	)
end

function _V3_MT:dist_to(other)
	return (other - self):length()
end

function _V3_MT:is_zero(tolerance)
	tolerance = tolerance or 0.001
	if (self.x < tolerance and self.x > -tolerance and self.y < tolerance and self.y > -tolerance and self.z < tolerance and self.z > -tolerance) then
		return true
	end

	return false
end

function _V3_MT:normalize()
	local l = self:length()
	if (l <= 0.0) then
		return 0.0
	end

	self.x = self.x / l
	self.y = self.y / l
	self.z = self.z / l
	return l
end

function _V3_MT:normalize_no_len()
	local l = self:length()
	if (l <= 0.0) then
		return
	end

	self.x = self.x / l
	self.y = self.y / l
	self.z = self.z / l
end

function _V3_MT:normalized()
	local l = self:length()
	if (l <= 0.0) then
		return Vector3()
	end

	return Vector3(
		self.x / l,
		self.y / l,
		self.z / l
	)
end

function clamp(cur_val, min_val, max_val)
	if (cur_val < min_val) then
		return min_val
	elseif (cur_val > max_val) then
		return max_val
	end

	return cur_val
end

function normalize_angle(angle)
	local str
	local out
	str = tostring(angle)
	if (str == "nan" or str == "inf") then
		return 0.0
	end

	if (angle >= -180.0 and angle <= 180.0) then
		return angle
	end

	out = math.fmod(math.fmod(angle + 360.0, 360.0), 360.0)
	if (out > 180.0) then
		out = out - 360.0
	end

	return out
end

function vector_to_angle(forward)
	local l
	local pitch
	local yaw
	l = forward:length()
	if(l > 0.0) then
		pitch = math.deg(math.atan(-forward.z, l))
		yaw   = math.deg(math.atan(forward.y, forward.x))
	else
		if (forward.x > 0.0) then
			pitch = 270.0
		else
			pitch = 90.0
		end

		yaw = 0.0
	end

	return Vector3(pitch, yaw, 0.0)
end

function angle_forward(angle)
	local sin_pitch = math.sin(math.rad(angle.x))
	local cos_pitch = math.cos(math.rad(angle.x))
	local sin_yaw   = math.sin(math.rad(angle.y))
	local cos_yaw   = math.cos(math.rad(angle.y))
	return Vector3(
		cos_pitch * cos_yaw,
		cos_pitch * sin_yaw,
		-sin_pitch
	)
end

function angle_right(angle)
	local sin_pitch = math.sin(math.rad(angle.x ))
	local cos_pitch = math.cos(math.rad(angle.x ))
	local sin_yaw = math.sin(math.rad(angle.y ))
	local cos_yaw = math.cos(math.rad(angle.y))
	local sin_roll = math.sin(math.rad(angle.z))
	local cos_roll = math.cos(math.rad(angle.z))
	return Vector3(
		-1.0 * sin_roll * sin_pitch * cos_yaw + -1.0 * cos_roll * -sin_yaw,
		-1.0 * sin_roll * sin_pitch * sin_yaw + -1.0 * cos_roll * cos_yaw,
		-1.0 * sin_roll * cos_pitch
	)
end

function angle_up(angle)
	local sin_pitch = math.sin(math.rad(angle.x))
	local cos_pitch = math.cos(math.rad(angle.x))
	local sin_yaw = math.sin(math.rad(angle.y))
	local cos_yaw = math.cos(math.rad( angle.y))
	local sin_roll = math.sin(math.rad(angle.z))
	local cos_roll = math.cos(math.rad(angle.z))
	return Vector3(
		cos_roll * sin_pitch * cos_yaw + -sin_roll * -sin_yaw,
		cos_roll * sin_pitch * sin_yaw + -sin_roll * cos_yaw,
		cos_roll * cos_pitch
	)
end

function get_FOV(view_angles, start_pos, end_pos)
	local type_str
	local fwd
	local delta
	local fov
	fwd = angle_forward(view_angles)
	delta = (end_pos - start_pos):normalized()
	fov = math.acos(fwd:dot(delta) / delta:length())
	return math.max(0.0, math.deg(fov))
end

local line_goes_through_smoke
if success and match ~= nil then
	local lgts_type = ffi.typeof("bool(__thiscall*)(float, float, float, float, float, float, short);")
	line_goes_through_smoke = ffi.cast(lgts_type, match)
end

local angle_c = {}
local angle_mt = {
	__index = angle_c
}

angle_mt.__call = function(angle, p_new, y_new, r_new)
	p_new = p_new or angle.p
	y_new = y_new or angle.y
	r_new = r_new or angle.r
	angle.p = p_new
	angle.y = y_new
	angle.r = r_new
end

local function angle(p, y, r)
	return setmetatable(
		{
			p = p or 0,
			y = y or 0,
			r = r or 0
		},
		angle_mt
	)
end

function angle_c:set(p, y, r)
	p = p or self.p
	y = y or self.y
	r = r or self.r
	self.p = p
	self.y = y
	self.r = r
end

function angle_c:offset(p, y, r)
	p = self.p + p or 0
	y = self.y + y or 0
	r = self.r + r or 0
	self.p = self.p + p
	self.y = self.y + y
	self.r = self.r + r
end

function angle_c:clone()
	return setmetatable(
		{
			p = self.p,
			y = self.y,
			r = self.r
		},
		angle_mt
	)
end

function angle_c:clone_offset(p, y, r)
	p = self.p + p or 0
	y = self.y + y or 0
	r = self.r + r or 0

	return angle(
		self.p + p,
		self.y + y,
		self.r + r
	)
end

function angle_c:clone_set(p, y, r)
	p = p or self.p
	y = y or self.y
	r = r or self.r

	return angle(
		p,
		y,
		r
	)
end

function angle_c:unpack()
	return self.p, self.y, self.r
end

function angle_c:nullify()
	self.p = 0
	self.y = 0
	self.r = 0
end

function angle_mt.__tostring(operand_a)
	return string.format("%s, %s, %s", operand_a.p, operand_a.y, operand_a.r)
end

function angle_mt.__concat(operand_a)
	return string.format("%s, %s, %s", operand_a.p, operand_a.y, operand_a.r)
end

function angle_mt.__add(operand_a, operand_b)
	if (type(operand_a) == "number") then
		return angle(
			operand_a + operand_b.p,
			operand_a + operand_b.y,
			operand_a + operand_b.r
		)
	end

	if (type(operand_b) == "number") then
		return angle(
			operand_a.p + operand_b,
			operand_a.y + operand_b,
			operand_a.r + operand_b
		)
	end

	return angle(
		operand_a.p + operand_b.p,
		operand_a.y + operand_b.y,
		operand_a.r + operand_b.r
	)
end

function angle_mt.__sub(operand_a, operand_b)
	if (type(operand_a) == "number") then
		return angle(
			operand_a - operand_b.p,
			operand_a - operand_b.y,
			operand_a - operand_b.r
		)
	end

	if (type(operand_b) == "number") then
		return angle(
			operand_a.p - operand_b,
			operand_a.y - operand_b,
			operand_a.r - operand_b
		)
	end

	return angle(
		operand_a.p - operand_b.p,
		operand_a.y - operand_b.y,
		operand_a.r - operand_b.r
	)
end

function angle_mt.__mul(operand_a, operand_b)
	if (type(operand_a) == "number") then
		return angle(
			operand_a * operand_b.p,
			operand_a * operand_b.y,
			operand_a * operand_b.r
		)
	end

	if (type(operand_b) == "number") then
		return angle(
			operand_a.p * operand_b,
			operand_a.y * operand_b,
			operand_a.r * operand_b
		)
	end

	return angle(
		operand_a.p * operand_b.p,
		operand_a.y * operand_b.y,
		operand_a.r * operand_b.r
	)
end

function angle_mt.__div(operand_a, operand_b)
	if (type(operand_a) == "number") then
		return angle(
			operand_a / operand_b.p,
			operand_a / operand_b.y,
			operand_a / operand_b.r
		)
	end

	if (type(operand_b) == "number") then
		return angle(
			operand_a.p / operand_b,
			operand_a.y / operand_b,
			operand_a.r / operand_b
		)
	end

	return angle(
		operand_a.p / operand_b.p,
		operand_a.y / operand_b.y,
		operand_a.r / operand_b.r
	)
end

function angle_mt.__pow(operand_a, operand_b)
	if (type(operand_a) == "number") then
		return angle(
			math.pow(operand_a, operand_b.p),
			math.pow(operand_a, operand_b.y),
			math.pow(operand_a, operand_b.r)
		)
	end

	if (type(operand_b) == "number") then
		return angle(
			math.pow(operand_a.p, operand_b),
			math.pow(operand_a.y, operand_b),
			math.pow(operand_a.r, operand_b)
		)
	end

	return angle(
		math.pow(operand_a.p, operand_b.p),
		math.pow(operand_a.y, operand_b.y),
		math.pow(operand_a.r, operand_b.r)
	)
end

function angle_mt.__mod(operand_a, operand_b)
	if (type(operand_a) == "number") then
		return angle(
			operand_a % operand_b.p,
			operand_a % operand_b.y,
			operand_a % operand_b.r
		)
	end

	if (type(operand_b) == "number") then
		return angle(
			operand_a.p % operand_b,
			operand_a.y % operand_b,
			operand_a.r % operand_b
		)
	end

	return angle(
		operand_a.p % operand_b.p,
		operand_a.y % operand_b.y,
		operand_a.r % operand_b.r
	)
end

function angle_mt.__unm(operand_a)
	return angle(
		-operand_a.p,
		-operand_a.y,
		-operand_a.r
	)
end

function angle_c:round_zero()
	self.p = math.floor(self.p + 0.5)
	self.y = math.floor(self.y + 0.5)
	self.r = math.floor(self.r + 0.5)
end

function angle_c:round(precision)
	self.p = math.round(self.p, precision)
	self.y = math.round(self.y, precision)
	self.r = math.round(self.r, precision)
end

function angle_c:round_base(base)
	self.p = base * math.round(self.p / base)
	self.y = base * math.round(self.y / base)
	self.r = base * math.round(self.r / base)
end

function angle_c:rounded_zero()
	return angle(
		math.floor(self.p + 0.5),
		math.floor(self.y + 0.5),
		math.floor(self.r + 0.5)
	)
end

function angle_c:rounded(precision)
	return angle(
		math.round(self.p, precision),
		math.round(self.y, precision),
		math.round(self.r, precision)
	)
end

function angle_c:rounded_base(base)
	return angle(
		base * math.round(self.p / base),
		base * math.round(self.y / base),
		base * math.round(self.r / base)
	)
end

local vector_c = {}
local vector_mt = {
	__index = vector_c,
}

vector_mt.__call = function(vector, x_new, y_new, z_new)
	x_new = x_new or vector.x
	y_new = y_new or vector.y
	z_new = z_new or vector.z

	vector.x = x_new
	vector.y = y_new
	vector.z = z_new
end

local function vector(x, y, z)
	return setmetatable(
		{
			x = x or 0,
			y = y or 0,
			z = z or 0
		},

		vector_mt
	)
end

function vector_c:set(x_new, y_new, z_new)
	x_new = x_new or self.x
	y_new = y_new or self.y
	z_new = z_new or self.z

	self.x = x_new
	self.y = y_new
	self.z = z_new
end

function vector_c:offset(x_offset, y_offset, z_offset)
	x_offset = x_offset or 0
	y_offset = y_offset or 0
	z_offset = z_offset or 0

	self.x = self.x + x_offset
	self.y = self.y + y_offset
	self.z = self.z + z_offset
end

function vector_c:clone()
	return setmetatable(
		{
			x = self.x,
			y = self.y,
			z = self.z
		},
		vector_mt
	)
end

function vector_c:clone_offset(x_offset, y_offset, z_offset)
	x_offset = x_offset or 0
	y_offset = y_offset or 0
	z_offset = z_offset or 0

	return setmetatable(
		{
			x = self.x + x_offset,
			y = self.y + y_offset,
			z = self.z + z_offset
		},
		vector_mt
	)
end

function vector_c:clone_set(x_new, y_new, z_new)
	x_new = x_new or self.x
	y_new = y_new or self.y
	z_new = z_new or self.z

	return vector(
		x_new,
		y_new,
		z_new
	)
end

function vector_c:unpack()
	return self.x, self.y, self.z
end

function vector_c:nullify()
	self.x = 0
	self.y = 0
	self.z = 0
end

function vector_mt.__tostring(operand_a)
	return string.format("%s, %s, %s", operand_a.x, operand_a.y, operand_a.z)
end

function vector_mt.__concat(operand_a)
	return string.format("%s, %s, %s", operand_a.x, operand_a.y, operand_a.z)
end

function vector_mt.__eq(operand_a, operand_b)
	return (operand_a.x == operand_b.x) and (operand_a.y == operand_b.y) and (operand_a.z == operand_b.z)
end

function vector_mt.__lt(operand_a, operand_b)
	if (type(operand_a) == "number") then
		return (operand_a < operand_b.x) or (operand_a < operand_b.y) or (operand_a < operand_b.z)
	end

	if (type(operand_b) == "number") then
		return (operand_a.x < operand_b) or (operand_a.y < operand_b) or (operand_a.z < operand_b)
	end

	return (operand_a.x < operand_b.x) or (operand_a.y < operand_b.y) or (operand_a.z < operand_b.z)
end

function vector_mt.__le(operand_a, operand_b)
	if (type(operand_a) == "number") then
		return (operand_a <= operand_b.x) or (operand_a <= operand_b.y) or (operand_a <= operand_b.z)
	end

	if (type(operand_b) == "number") then
		return (operand_a.x <= operand_b) or (operand_a.y <= operand_b) or (operand_a.z <= operand_b)
	end

	return (operand_a.x <= operand_b.x) or (operand_a.y <= operand_b.y) or (operand_a.z <= operand_b.z)
end

function vector_mt.__add(operand_a, operand_b)
	if (type(operand_a) == "number") then
		return vector(
			operand_a + operand_b.x,
			operand_a + operand_b.y,
			operand_a + operand_b.z
		)
	end

	if (type(operand_b) == "number") then
		return vector(
			operand_a.x + operand_b,
			operand_a.y + operand_b,
			operand_a.z + operand_b
		)
	end

	return vector(
		operand_a.x + operand_b.x,
		operand_a.y + operand_b.y,
		operand_a.z + operand_b.z
	)
end

function vector_mt.__sub(operand_a, operand_b)
	if (type(operand_a) == "number") then
		return vector(
			operand_a - operand_b.x,
			operand_a - operand_b.y,
			operand_a - operand_b.z
		)
	end

	if (type(operand_b) == "number") then
		return vector(
			operand_a.x - operand_b,
			operand_a.y - operand_b,
			operand_a.z - operand_b
		)
	end

	return vector(
		operand_a.x - operand_b.x,
		operand_a.y - operand_b.y,
		operand_a.z - operand_b.z
	)
end

function vector_mt.__mul(operand_a, operand_b)
	if (type(operand_a) == "number") then
		return vector(
			operand_a * operand_b.x,
			operand_a * operand_b.y,
			operand_a * operand_b.z
		)
	end

	if (type(operand_b) == "number") then
		return vector(
			operand_a.x * operand_b,
			operand_a.y * operand_b,
			operand_a.z * operand_b
		)
	end

	return vector(
		operand_a.x * operand_b.x,
		operand_a.y * operand_b.y,
		operand_a.z * operand_b.z
	)
end

function vector_mt.__div(operand_a, operand_b)
	if (type(operand_a) == "number") then
		return vector(
			operand_a / operand_b.x,
			operand_a / operand_b.y,
			operand_a / operand_b.z
		)
	end

	if (type(operand_b) == "number") then
		return vector(
			operand_a.x / operand_b,
			operand_a.y / operand_b,
			operand_a.z / operand_b
		)
	end

	return vector(
		operand_a.x / operand_b.x,
		operand_a.y / operand_b.y,
		operand_a.z / operand_b.z
	)
end

function vector_mt.__pow(operand_a, operand_b)
	if (type(operand_a) == "number") then
		return vector(
			math.pow(operand_a, operand_b.x),
			math.pow(operand_a, operand_b.y),
			math.pow(operand_a, operand_b.z)
		)
	end

	if (type(operand_b) == "number") then
		return vector(
			math.pow(operand_a.x, operand_b),
			math.pow(operand_a.y, operand_b),
			math.pow(operand_a.z, operand_b)
		)
	end

	return vector(
		math.pow(operand_a.x, operand_b.x),
		math.pow(operand_a.y, operand_b.y),
		math.pow(operand_a.z, operand_b.z)
	)
end

function vector_mt.__mod(operand_a, operand_b)
	if (type(operand_a) == "number") then
		return vector(
			operand_a % operand_b.x,
			operand_a % operand_b.y,
			operand_a % operand_b.z
		)
	end

	if (type(operand_b) == "number") then
		return vector(
			operand_a.x % operand_b,
			operand_a.y % operand_b,
			operand_a.z % operand_b
		)
	end

	return vector(
		operand_a.x % operand_b.x,
		operand_a.y % operand_b.y,
		operand_a.z % operand_b.z
	)
end

function vector_mt.__unm(operand_a)
	return vector(
		-operand_a.x,
		-operand_a.y,
		-operand_a.z
	)
end

function vector_c:length2_squared()
	return (self.x * self.x) + (self.y * self.y);
end

function vector_c:length2()
	return math.sqrt(self:length2_squared())
end

function vector_c:length_squared()
	return (self.x * self.x) + (self.y * self.y) + (self.z * self.z);
end

function vector_c:length()
	return math.sqrt(self:length_squared())
end

function vector_c:dot_product(b)
	return (self.x * b.x) + (self.y * b.y) + (self.z * b.z)
end

function vector_c:cross_product(b)
	return vector(
		(self.y * b.z) - (self.z * b.y),
		(self.z * b.x) - (self.x * b.z),
		(self.x * b.y) - (self.y * b.x)
	)
end

function vector_c:distance2(destination)
	return (destination - self):length2()
end

function vector_c:distance(destination)
	return (destination - self):length()
end

function vector_c:distance_x(destination)
	return math.abs(self.x - destination.x)
end

function vector_c:distance_y(destination)
	return math.abs(self.y - destination.y)
end

function vector_c:distance_z(destination)
	return math.abs(self.z - destination.z)
end

function vector_c:in_range(destination, distance)
	return self:distance(destination) <= distance
end

function vector_c:round_zero()
	self.x = math.floor(self.x + 0.5)
	self.y = math.floor(self.y + 0.5)
	self.z = math.floor(self.z + 0.5)
end

function vector_c:round(precision)
	self.x = math.round(self.x, precision)
	self.y = math.round(self.y, precision)
	self.z = math.round(self.z, precision)
end

function vector_c:round_base(base)
	self.x = base * math.round(self.x / base)
	self.y = base * math.round(self.y / base)
	self.z = base * math.round(self.z / base)
end

function vector_c:rounded_zero()
	return vector(
		math.floor(self.x + 0.5),
		math.floor(self.y + 0.5),
		math.floor(self.z + 0.5)
	)
end

function vector_c:rounded(precision)
	return vector(
		math.round(self.x, precision),
		math.round(self.y, precision),
		math.round(self.z, precision)
	)
end

function vector_c:rounded_base(base)
	return vector(
		base * math.round(self.x / base),
		base * math.round(self.y / base),
		base * math.round(self.z / base)
	)
end

function vector_c:normalize()
	local length = self:length()
	if (length ~= 0) then
		self.x = self.x / length
		self.y = self.y / length
		self.z = self.z / length
	else
		self.x = 0
		self.y = 0
		self.z = 1
	end
end

function vector_c:normalized_length()
	return self:length()
end

function vector_c:normalized()
	local length = self:length()
	if (length ~= 0) then
		return vector(
			self.x / length,
			self.y / length,
			self.z / length
		)
	else
		return vector(0, 0, 1)
	end
end

function vector_c:magnitude()
	return math.sqrt(
		math.pow(self.x, 2) +
			math.pow(self.y, 2) +
			math.pow(self.z, 2)
	)
end

function vector_c:angle_to(destination)
	local delta_vector = vector(destination.x - self.x, destination.y - self.y, destination.z - self.z)
	local yaw = math.deg(math.atan2(delta_vector.y, delta_vector.x))
	local hyp = math.sqrt(delta_vector.x * delta_vector.x + delta_vector.y * delta_vector.y)
	local pitch = math.deg(math.atan2(-delta_vector.z, hyp))
	return angle(pitch, yaw)
end

function vector_c:lerp(destination, percentage)
	return self + (destination - self) * percentage
end

local function vector_internal_division(source, destination, m, n)
	return vector((source.x * n + destination.x * m) / (m + n),
		(source.y * n + destination.y * m) / (m + n),
		(source.z * n + destination.z * m) / (m + n))
end

function vector_c:closest_ray_point(ray_start, ray_end)
	local to = self - ray_start
	local direction = ray_end - ray_start
	local length = direction:length()
	direction:normalize()
	local ray_along = to:dot_product(direction)
	if (ray_along < 0) then
		return ray_start
	elseif (ray_along > length) then
		return ray_end
	end

	return ray_start + direction * ray_along
end

function vector_c:ray_divided(ray_end, ratio)
	return (self * ratio + ray_end) / (1 + ratio)
end

function vector_c:ray_segmented(ray_end, segments)
	local points = {}

	for i = 0, segments do
		points[i] = vector_internal_division(self, ray_end, i, segments - i)
	end

	return points
end

function vector_c:ray(ray_end, total_segments)
	total_segments = total_segments or 128
	local segments = {}
	local step = self:distance(ray_end) / total_segments
	local angle = self:angle_to(ray_end)
	local direction = angle:to_forward_vector()

	for i = 1, total_segments do
		table.insert(segments, self + (direction * (step * i)))
	end

	local src_screen_position = vector(0, 0, 0)
	local dst_screen_position = vector(0, 0, 0)
	local src_in_screen = false
	local dst_in_screen = false

	for i = 1, #segments do
		src_screen_position = segments[i]:to_screen()
		if src_screen_position ~= nil then
			src_in_screen = true
			break
		end
	end

	for i = #segments, 1, -1 do
		dst_screen_position = segments[i]:to_screen()
		if dst_screen_position ~= nil then
			dst_in_screen = true
			break
		end
	end

	if src_in_screen and dst_in_screen then
		return src_screen_position, dst_screen_position
	end

	return nil
end

function vector_c:ray_intersects_smoke(ray_end)
	if (line_goes_through_smoke == nil) then
		error("Unsafe scripts must be allowed in order to use vector_c:ray_intersects_smoke")
	end

	return line_goes_through_smoke(self.x, self.y, self.z, ray_end.x, ray_end.y, ray_end.z, 1)
end

function vector_c:inside_polygon2(polygon)
	local odd_nodes = false
	local polygon_vertices = #polygon
	local j = polygon_vertices

	for i = 1, polygon_vertices do
		if (polygon[i].y < self.y and polygon[j].y >= self.y or polygon[j].y < self.y and polygon[i].y >= self.y) then
			if (polygon[i].x + (self.y - polygon[i].y) / (polygon[j].y - polygon[i].y) * (polygon[j].x - polygon[i].x) < self.x) then
				odd_nodes = not odd_nodes
			end
		end

		j = i
	end

	return odd_nodes
end

function vector_c:min(value)
	self.x = math.min(value, self.x)
	self.y = math.min(value, self.y)
	self.z = math.min(value, self.z)
end

function vector_c:max(value)
	self.x = math.max(value, self.x)
	self.y = math.max(value, self.y)
	self.z = math.max(value, self.z)
end

function vector_c:minned(value)
	return vector(
		math.min(value, self.x),
		math.min(value, self.y),
		math.min(value, self.z)
	)
end

function vector_c:maxed(value)
	return vector(
		math.max(value, self.x),
		math.max(value, self.y),
		math.max(value, self.z)
	)
end

function angle_c:to_forward_vector()
	local degrees_to_radians = function(degrees)
		return degrees * math.pi / 180
	end

	local sp = math.sin(degrees_to_radians(self.p))
	local cp = math.cos(degrees_to_radians(self.p))
	local sy = math.sin(degrees_to_radians(self.y))
	local cy = math.cos(degrees_to_radians(self.y))
	return vector(cp * cy, cp * sy, -sp)
end

function angle_c:to_up_vector()
	local degrees_to_radians = function(degrees)
		return degrees * math.pi / 180
	end

	local sp = math.sin(degrees_to_radians(self.p))
	local cp = math.cos(degrees_to_radians(self.p))
	local sy = math.sin(degrees_to_radians(self.y))
	local cy = math.cos(degrees_to_radians(self.y))
	local sr = math.sin(degrees_to_radians(self.r))
	local cr = math.cos(degrees_to_radians(self.r))
	return vector(cr * sp * cy + sr * sy, cr * sp * sy + sr * cy * -1, cr * cp)
end

function angle_c:to_right_vector()
	local degrees_to_radians = function(degrees)
		return degrees * math.pi / 180
	end

	local sp = math.sin(degrees_to_radians(self.p))
	local cp = math.cos(degrees_to_radians(self.p))
	local sy = math.sin(degrees_to_radians(self.y))
	local cy = math.cos(degrees_to_radians(self.y))
	local sr = math.sin(degrees_to_radians(self.r))
	local cr = math.cos(degrees_to_radians(self.r))
	return vector(sr * sp * cy * -1 + cr * sy, sr * sp * sy * -1 + -1 * cr * cy, -1 * sr * cp)
end

function angle_c:to_backward_vector()
	local degrees_to_radians = function(degrees)
		return degrees * math.pi / 180
	end

	local sp = math.sin(degrees_to_radians(self.p))
	local cp = math.cos(degrees_to_radians(self.p))
	local sy = math.sin(degrees_to_radians(self.y))
	local cy = math.cos(degrees_to_radians(self.y))
	return -vector(cp * cy, cp * sy, -sp)
end

function angle_c:to_left_vector()
	local degrees_to_radians = function(degrees)
		return degrees * math.pi / 180
	end

	local sp = math.sin(degrees_to_radians(self.p))
	local cp = math.cos(degrees_to_radians(self.p))
	local sy = math.sin(degrees_to_radians(self.y))
	local cy = math.cos(degrees_to_radians(self.y))
	local sr = math.sin(degrees_to_radians(self.r))
	local cr = math.cos(degrees_to_radians(self.r))
	return -vector(sr * sp * cy * -1 + cr * sy, sr * sp * sy * -1 + -1 * cr * cy, -1 * sr * cp)
end

function angle_c:to_down_vector()
	local degrees_to_radians = function(degrees)
		return degrees * math.pi / 180
	end

	local sp = math.sin(degrees_to_radians(self.p))
	local cp = math.cos(degrees_to_radians(self.p))
	local sy = math.sin(degrees_to_radians(self.y))
	local cy = math.cos(degrees_to_radians(self.y))
	local sr = math.sin(degrees_to_radians(self.r))
	local cr = math.cos(degrees_to_radians(self.r))
	return -vector(cr * sp * cy + sr * sy, cr * sp * sy + sr * cy * -1, cr * cp)
end

function angle_c:fov_to(source, destination)
	local fwd = self:to_forward_vector()
	local delta = (destination - source):normalized()
	local fov = math.acos(fwd:dot_product(delta) / delta:length())
	return math.max(0.0, math.deg(fov))
end

function angle_c:bearing(precision)
	local yaw = 180 - self.y + 90
	local degrees = (yaw % 360 + 360) % 360
	degrees = degrees > 180 and degrees - 360 or degrees
	return math.round(degrees + 180, precision)
end

function angle_c:start_degrees()
	local yaw = self.y
	local degrees = (yaw % 360 + 360) % 360
	degrees = degrees > 180 and degrees - 360 or degrees
	return degrees + 180
end

function angle_c:normalize()
	local pitch = self.p
	if (pitch < -89) then
		pitch = -89
	elseif (pitch > 89) then
		pitch = 89
	end

	local yaw = self.y
	while yaw > 180 do
		yaw = yaw - 360
	end

	while yaw < -180 do
		yaw = yaw + 360
	end

	return angle(pitch, yaw, 0)
end

function angle_c:normalized()
	if (self.p < -89) then
		self.p = -89
	elseif (self.p > 89) then
		self.p = 89
	end

	local yaw = self.y
	while yaw > 180 do
		yaw = yaw - 360
	end

	while yaw < -180 do
		yaw = yaw + 360
	end

	self.y = yaw
	self.r = 0
end

function IsInfinite(x)
return x == INFINITE or x == -INFINITE;
end

function IsNaN(x)
return x ~= x;
end

function NormalizePitch(pitch)
	if (pitch > 89) then
		return 89;
	elseif (pitch < -89) then
		return -89;
	end

	return pitch;
end

function NormalizeYaw(yaw)
	if (yaw > 180) then
		return yaw - (round(yaw / 360) * 360.0);
	elseif (yaw < -180) then
		return yaw + (round(yaw / 360) * -360.0);
	end

	return yaw;
end

function NormalizeRoll(roll)
	if ((roll > 50) or (roll < 50)) then
		roll = 0;
	end

	return roll;
end

function NormalizeAngle(vAngle)
	vAngle.pitch = NormalizePitch(vAngle.pitch);
	vAngle.yaw = NormalizeYaw(vAngle.yaw);
	vAngle.roll = NormalizeRoll(vAngle.roll);
	return vAngle;
end

function NormalizeVector(vAngle)
	vAngle.x = NormalizePitch(vAngle.x);
	vAngle.y = NormalizeYaw(vAngle.y);
	vAngle.z = NormalizeRoll(vAngle.z);
	return vAngle;
end

function VectorSubtraction(vFirst, vSecond)
	return vec3_t.new(vFirst.x - vSecond.x, vFirst.y - vSecond.y, vFirst.z - vSecond.z);
end

function VectorAddition(vFirst, vSecond)
	return vec3_t.new(vFirst.x + vSecond.x, vFirst.y + vSecond.y, vFirst.z + vSecond.z);
end

function VectorDivision(vFirst, vSecond)
	return vec3_t.new(vFirst.x / vSecond.x, vFirst.y / vSecond.y, vFirst.z / vSecond.z);
end

function VectorMultiplication(vFirst, vSecond)
	return vec3_t.new(vFirst.x * vSecond.x, vFirst.y * vSecond.y, vFirst.z * vSecond.z);
end

function VectorNumberSubtraction(Vector, Number)
	return vec3_t.new(Vector.x - Number, Vector.y - Number, Vector.z - Number);
end

function VectorNumberAddition(Vector, Number)
	return vec3_t.new(Vector.x + Number, Vector.y + Number, Vector.z + Number);
end

function VectorNumberDivision(Vector, Number)
	return vec3_t.new(Vector.x / Number, Vector.y / Number, Vector.z / Number);
end

function VectorNumberMultiplication(Vector, Number)
	return vec3_t.new(Vector.x * Number, Vector.y * Number, Vector.z * Number);
end

function GetMiddlePoint(vFirst, vSecond)
	return VectorAddition(VectorNumberDivision(VectorSubtraction(vSecond, vFirst), 2), vFirst);
end

function calc_angle(x_src, y_src, z_src, x_dst, y_dst, z_dst)
	local x_delta = x_src - x_dst
	local y_delta = y_src - y_dst
	local z_delta = z_src - z_dst
	local hyp = math.sqrt(x_delta^2 + y_delta^2)
	local x = math.atan2(z_delta, hyp) * 57.295779513082
	local y = math.atan2(y_delta , x_delta) * 180 / 3.14159265358979323846

	if y > 180 then
		y = y - 180
	end
	if y < -180 then
		y = y + 180
	end
	return y
end

function CalcAngle(vecSource, vecDestination)
	if (vecSource.x == nil or vecSource.y == nil or vecSource.z == nil) then
		vecSource = vec3_t.new(vecSource.pitch, vecSource.yaw, vecSource.roll);
	end

	if (vecDestination.x == nil or vecDestination.y == nil or vecDestination.z == nil) then
		vecDestination = vec3_t.new(vecDestination.pitch, vecDestination.yaw, vecDestination.roll);
	end

	local vAngle = vec3_t.new(0, 0, 0);
	local vDelta = vec3_t.new(vecSource.x - vecDestination.x, vecSource.y - vecDestination.y, vecSource.z - vecDestination.z);
	local hyp = math.sqrt(vDelta.x * vDelta.x + vDelta.y * vDelta.y);
	vAngle.x = math.atan(vDelta.z / hyp) * M_PI_180;
	vAngle.y = math.atan(vDelta.y / vDelta.x) * M_PI_180;
	vAngle.z = 0;

	if (vDelta.x >= 0) then
		vAngle.y = vAngle.y + 180;
	end

	vAngle = NormalizeVector(vAngle);

	return vAngle;
end

-- Converts a QAngle into either one or three normalised Vectors
function AngleVectors(vAngles)
	if (vAngles.x == nil or vAngles.y == nil or vAngles.z == nil) then
		vAngles = vec3_t.new(vAngles.pitch, vAngles.yaw, vAngles.roll);
	end

	local sy = math.sin(DEG2RAD(vAngles.y));
	local cy = math.cos(DEG2RAD(vAngles.y));

	local sp = math.sin(DEG2RAD(vAngles.x));
	local cp = math.cos(DEG2RAD(vAngles.x));

	return vec3_t.new(cp * cy, cp * sy, -sp);
end

-- Converts a single Vector into a QAngle.
function VectorAngles(vAngles)
	if (vAngles.x == nil or vAngles.y == nil or vAngles.z == nil) then
		vAngles = vec3_t.new(vAngles.pitch, vAngles.yaw, vAngles.roll);
	end

	local tmp, yaw, pitch;

	if (vAngles.y == 0 and vAngles.x == 0) then
		yaw = 0;
		if (vAngles.z > 0) then
			pitch = 270;
		else
			pitch = 90;
		end
	else
		yaw = math.atan2(vAngles.y, vAngles.x) * 180.0 / M_PI;
		if (yaw < 0) then
			yaw = yaw + 360;
		end

		tmp = math.sqrt(vAngles.x * vAngles.x + vAngles.y * vAngles.y);
		pitch = math.atan2(-vAngles.z, tmp) * 180.0 / M_PI;
		if (pitch < 0) then
			pitch = pitch + 360;
		end
	end

	return vec3_t.new(pitch, yaw, 0);
end

function GetMaxDesyncDelta(enemyplayer)
	local player_ptr = ffi_cast("void***", get_client_entity_fn(entity_list_pointer, enemyplayer))
	local animstate_ptr = ffi_cast("char*", player_ptr) + 0x9960
	local animstate = ffi_cast("struct CCSGOPlayerAnimationState_534535_t", animstate_ptr)[0]
	if (not animstate) then
		return 0;
	end

	local m_fDuckAmount = ffi.cast("float*", animstate + 0xA4)[0]; -- 0xA4 - m_fDuckAmount

	local speedfraction = math.max(0, math.min( ffi.cast("float*", animstate + 0xF8)[0] , 1)); -- 0xF8 -- m_flFeetSpeedForwardsOrSideWays
	local speedfactor = math.max(0, math.min( 1, ffi.cast("float*", animstate + 0xFC)[0])); -- 0xFC - m_flFeetSpeedUnknownForwardOrSideways;

	local m_fUnknown = ((ffi.cast("float*", animstate + 0x11C)[0] * -0.30000001) - 0.19999999) * speedfraction; -- 0x11C - m_flStopToFullRunningFraction
	local m_fUnknown2 = m_fUnknown + 1.0;

	if (m_fDuckAmount > 0) then
		m_fUnknown2 = m_fUnknown2 + (( m_fDuckAmount * speedfactor) * (0.5 - m_fUnknown2))
	end

	local m_flUnknown3 = ffi.cast("float*", animstate + 0x334)[0] * m_fUnknown2; -- 0x334 - m_flUnknown3

	return m_flUnknown3;
end

function DEG2RAD(x)
	return (x * M_180_PI);
end

function VectorDot(vFirst, vSecond)
	return (vFirst.x * vSecond.x + vFirst.y * vSecond.y + vFirst.z * vSecond.z);
end

function VectorLengthSqr(Vector)
	return (Vector.x*Vector.x + Vector.y*Vector.y);
end

function VectorNormalize(Vector)
	local Length = Vector:length();
	if (Length ~= 0) then
		Vector.x = Vector.x / Length;
		Vector.y = Vector.y / Length;
		Vector.z = Vector.z / Length;
	else
		Vector.x = 0;
		Vector.y = 0;
		Vector.z = 1;
	end
	return Vector;
end

function Distance3D(vFirst, vSecond)
	return (((vFirst.x - vSecond.x) ^ 2) + ((vFirst.y - vSecond.y) ^ 2) + ((vFirst.z - vSecond.z) ^ 2) * 0.5);
end

function Distance2D(vFirst, vSecond)
	return ((vFirst.x - vSecond.x) ^ 2) + ((vFirst.y - vSecond.y) ^ 2);
end

function GetCurtime(Player)
	return Player.m_nTickBase * globals.tickinterval;
end

function GetTickrate()
	return (1.0 / globals.tickinterval);
end

function TIME_TO_TICKS(dt)
	return (0.5 + dt / globals.tickinterval);
end

function TICKS_TO_TIME(t)
	return (globals.tickinterval * t);
end

function GetLerpTime()
	local cl_updaterate = cvar.cl_updaterate:int();
	local sv_minupdaterate = cvar.sv_minupdaterate;
	local sv_maxupdaterate = cvar.sv_maxupdaterate;

	if (sv_minupdaterate and sv_maxupdaterate) then
		cl_updaterate = sv_maxupdaterate:int();
	end

	local cl_interp_ratio = cvar.cl_interp_ratio:float();

	if (cl_interp_ratio == 0) then
		cl_interp_ratio = 1;
	end

	local cl_interp = cvar.cl_interp:float();
	local sv_client_min_interp_ratio = cvar.sv_client_min_interp_ratio;
	local sv_client_max_interp_ratio = cvar.sv_client_max_interp_ratio;

	if (sv_client_min_interp_ratio and sv_client_max_interp_ratio and sv_client_min_interp_ratio:float() ~= 1) then
		cl_interp_ratio = clamp(cl_interp_ratio, sv_client_min_interp_ratiofloat(), sv_client_max_interp_ratio:float());
	end

	return math.max(cl_interp, (cl_interp_ratio / cl_updaterate));
end

function RotateMovement(pCmd, vAngles)
	if (vAngles.x == nil or vAngles.y == nil or vAngles.z == nil) then
		vAngles = vec3_t.new(vAngles.pitch, vAngles.yaw, vAngles.roll);
	end

	local viewangles = render.camera_angles();
	local rotation = DEG2RAD(viewangles.yaw - vAngles.y);

	local cos_rot = math.cos(rotation);
	local sin_rot = math.sin(rotation);

	local new_forwardmove = (cos_rot * pCmd.forwardmove) - (sin_rot * pCmd.sidemove);
	local new_sidemove = (sin_rot *  pCmd.forwardmove) + (cos_rot * pCmd.sidemove);

	pCmd.forwardmove = new_forwardmove;
	pCmd.sidemove = new_sidemove;
end

local function anglemod(a)
	a = (360 / 65536) * bit.band((a * (65536 / 360)), 65535)
	return a
end

function approach_angle(target, value, speed)
	target = anglemod(target)
	value = anglemod(value)

	delta = target - value

	if speed < 0 then
		speed = -speed
	end

	if delta < -180 then
		delta = delta + 360
	elseif delta > 180 then
		delta = delta - 360
	end

	if delta > speed then
		value = value + speed
	elseif delta < -speed then
		value = value - speed
	else
		value = target
	end

	return value;
end

function angle_diff(destAngle, srcAngle)
	local delta = math.fmod(destAngle - srcAngle, 360.0)
	if destAngle > srcAngle then
		if delta >= 180 then
			delta = delta - 360
		end
	else
		if delta <= -180 then
			delta = delta + 360
		end
	end

	return delta
end

local function get_time()
	return math.floor(globals.curtime() * 1000)
end

Timer = {}
Timer.timers = {}

local function add_timer(is_interval, callback, ms)
	table.insert(Timer.timers, {
		time = get_time() + ms,
		ms = ms,
		is_interval = is_interval,
		callback = callback
	})

	return #Timer.timers
end

Timer.new_timeout = function (callback, ms)
	local index = add_timer(false, callback, ms)

	return index
end

Timer.new_interval = function(callback, ms)
	local index = add_timer(true, callback, ms)

	return index
end

Timer.listener = function()
	for i = 1, #Timer.timers do
		local timer = Timer.timers[i]
		local current_time = get_time()

		if current_time >= timer.time then
			timer.callback()

			if timer.is_interval then
				timer.time = get_time() + timer.ms
			else
				table.remove(Timer.timers, i)
			end
		end
	end
end

Timer.remove = function(index)
	table.remove(Timer.timers, index)
end

function fix_angle(angle)
	while angle.pitch < -180.0 do
		angle.pitch = angle.pitch + 360.0
	end
	while angle.pitch > 180.0 do
		angle.pitch = angle.pitch - 360.0
	end

	while angle.yaw < -180.0 do
		angle.yaw = angle.yaw + 360.0
	end
	while angle.yaw > 180.0 do
		angle.yaw = angle.yaw - 360.0
	end

	if angle.pitch > 89.0 then
		angle.pitch = 89.0
	elseif angle.pitch < -89.0 then
		angle.pitch = -89.0
	end
	if angle.yaw > 180.0 then
		angle.yaw = 180.0
	elseif angle.pitch < -180.0 then
		angle.pitch = -180.0
	end

	return angle
end

VectorAngles = function(resolver, src, dist)
	local forward = dist - src

	local tmp, yaw, pitch

	if forward.x == 0 and forward.y == 0 then
		yaw = 0

		if forward.z > 0 then
			pitch = 270
		else
			pitch = 90
		end

	else
		yaw = (math.atan2(forward.y, forward.x) * 180 / math.pi)
		if yaw < 0 then
			yaw = yaw + 360
		end

		tmp = math.sqrt(forward.x * forward.x + forward.y * forward.y)
		pitch = (math.atan2(-forward.z, tmp) * 180 / math.pi)

		if pitch < 0 then
			pitch = pitch + 360
		end

	end

	return resolver:fix_angle(QAngle.new(pitch, yaw, 0))
end

function kalkulator(local_x, local_y, enemy_x, enemy_y)
	local ydelta = local_y - enemy_y
	local xdelta = local_x - enemy_x
	local relativeyaw = math.atan( ydelta / xdelta )
	relativeyaw = normalize_yaw( relativeyaw * 180 / math.pi )
	if xdelta >= 0 then
		relativeyaw = normalize_yaw(relativeyaw + 180)
	end
	return relativeyaw
end

function switch_value(value, state, add_value)
	return state and (value - add_value) or - (value - add_value)
end

local function ent_speed_2d(index)
	local x, y, z = index.m_vecVelocity
	return math.sqrt(x * x + y * y)
end

function jumping(ent)
	return bit.band(ent.m_fFlags, 1) == 1
end

function setMath(int, max, declspec)
	local int = (int > max and max or int)
	local tmp = max / int;
	local i = (declspec / tmp)
	i = (i >= 0 and math.floor(i + 0.5) or math.ceil(i - 0.5))
	return i
end

function extrapolate(player, x, y, z)
	local xv, yv, zv = player.m_vecVelocity
	local new_x = x + globals.tickinterval * xv
	local new_y = y + globals.tickinterval * yv
	local new_z = z + globals.tickinterval * zv
	return new_x, new_y, new_z
end

function sideways_data(enemy, lx, ly, lz)
	local dx, dy, dz = (vector(lx, ly, lz):angle_to(vector(entity.get_entities(enemy))) - angle(enemy.m_angEyeAngles):unpack())
	local yaw_delta = math.abs(dy)
	if ((yaw_delta >= 80 and yaw_delta <= 100) or (yaw_delta >= 250 and yaw_delta <= 270) or (yaw_delta >= 430 and yaw_delta <= 460)) then
		return true
	end

	return false
end

function get_sideways_yaw(enemy)
	local local_player = entity.get_local_player()
	local lox, loy, loz = entity.get_entities(local_player)
	local lpx, lpy, lpz = extrapolate(local_player, lox, loy, loz)
	local dx, dy, dz = (vector(lx, ly, lz):angle_to(vector(entity.get_entities(enemy))) - angle(enemy.m_angEyeAngles)):unpack()
	local yaw_delta = math.abs(dy)
	if sideways_data(enemy, lpx, lpy, lpz) then
		return math.floor(yaw_delta)
	end

	return 0
end

function sideways_player(enemy, enemy_yaw)
	local local_player = entity.get_local_player()
	local lox, loy, loz = entity.get_entities(local_player)
	local lpx, lpy, lpz = extrapolate(local_player, lox, loy, loz)
	local sideways_change = ui.get(sideways_resolver_change) and (enemy_yaw > - 20 and enemy_yaw < 20)
	if sideways_data(enemy, lpx, lpy, lpz) and ((enemy_yaw > - 180 and enemy_yaw < - 140) or (enemy_yaw > 140 and enemy_yaw < 180)) then
		return true
	end

	return false
end

function max_desync(entityindex)
	local spd = math.min(260, ent_speed_2d(entityindex))
	local walkfrac = math.max(0, math.min(1, spd / 135))
	local mult = 1 - 0.5 * walkfrac
	local duckamnt = entityindex.m_fDuckAmount
	if duckamnt > 0 then
		local duckfrac = math.max(0, math.min(1, spd / 88))
		mult = mult + ((duckamnt * duckfrac) * (0.5 - mult))
	end

	return math.floor((58 * mult))
end

function is_update_value(check, speed, max, min)
	if check and update_value <= (1 + speed) then
		update_value = update_value + speed
		if update_value >= max then
			update_value = 1
		end

	elseif not check and update_value > (0 - speed) then
		update_value = update_value - speed
		if update_value <= min then
			update_value = min
		end
	end

	return update_value
end

function GetFov(viewAngle, aimAngle)
	if (viewAngle.x == nil or viewAngle.y == nil or viewAngle.z == nil) then
		viewAngle = vec3_t.new(viewAngle.pitch, viewAngle.yaw, viewAngle.roll);
	end

	if (aimAngle.x == nil or aimAngle.y == nil or aimAngle.z == nil) then
		aimAngle = vec3_t.new(aimAngle.pitch, aimAngle.yaw, aimAngle.roll);
	end

	local Aim = AngleVectors(viewAngle);
	local Ang = AngleVectors(aimAngle);

	return RAD2DEG(math.acos(VectorDot(Aim, Ang) / VectorLengthSqr(Aim)));
end


local function GetAnimationState1(enemyplayer)
	if not (enemyplayer) then
		return
	end
	local player_ptr = ffi_cast("void***", get_client_entity_fn(entity_list_pointer, enemyplayer))
	local animstate_ptr = ffi_cast("char*", player_ptr) + 0x9960 + 0x3914
	local animstate = ffi_cast("struct CCSGOPlayerAnimationState_534535_t", animstate_ptr)[0]

	return animstate
 end

 function GetPlayerMaxFeetYaw(enemyplayer)
	 local S_animationState_t = GetAnimationState1(enemyplayer)
	 local nDuckAmount = S_animationState_t.m_fDuckAmount
	 local nFeetSpeedForwardsOrSideWays = math.max(0, math.min(1, S_animationState_t.m_flFeetSpeedForwardsOrSideWays))
	 local nFeetSpeedUnknownForwardOrSideways = math.max(1, S_animationState_t.m_flFeetSpeedUnknownForwardOrSideways)
	 local nValue =
		 (S_animationState_t.m_flStopToFullRunningFraction * -0.30000001 - 0.19999999) * nFeetSpeedForwardsOrSideWays +
		 1
	 if nDuckAmount > 0 then
		 nValue = nValue + nDuckAmount * nFeetSpeedUnknownForwardOrSideways * (0.5 - nValue)
	 end
	 local nDeltaYaw = S_animationState_t.m_flMaxYaw * nValue
	 return nDeltaYaw < 58 and nDeltaYaw >= 0 and nDeltaYaw or 0
 end

 function get_max_feet_yaw(enemyplayer)
	 local player_ptr = ffi_cast("void***", get_client_entity_fn(entity_list_pointer, enemyplayer))
	 local animstate_ptr = ffi_cast("char*", player_ptr) + 0x9960 + 0x3914
	 local animstate = ffi_cast("struct CCSGOPlayerAnimationState_534535_t", animstate_ptr)[0]
	 eye_angles = player.m_angEyeAngles

	 local duckammount = animstat.m_fDuckAmount
	 local speedfraction = math.max(0, math.min(animstate.m_flFeetSpeedForwardsOrSideWays, 1))
	 local speedfactor = math.max(0, math.max(1, animstat.m_flFeetSpeedUnknownForwardOrSideways ))
	 local unk1 = ((animstate.m_flStopToFullRunningFraction * -0.30000001) - 0.19999999) * speedfraction
	 local unk2 = unk1 + 1

	 if duckammount > 0 then
		 unk2 = unk2 + ( ( duckammount * speedfactor) * ( 0.5 - unk2 ) )
	 end

	 return (animstate.m_flMaxYaw) *  unk2;
 end

 function GetMaxDesyncDelta(enemyplayer)
	local player_ptr = ffi_cast("void***", get_client_entity_fn(entity_list_pointer, enemyplayer))
	local animstate_ptr = ffi_cast("char*", player_ptr) + 0x9960 + 0x3914
	local animstate = ffi_cast("struct CCSGOPlayerAnimationState_534535_t", animstate_ptr)[0]

    local animstate = ffi.cast("int*", EntityAddress + 0x3914)[0];
    if (not animstate) then
		return 0;
	end

    local m_fDuckAmount = ffi.cast("float*", animstate + 0xA4)[0]; -- 0xA4 - m_fDuckAmount

    local speedfraction = math.max(0, math.min( ffi.cast("float*", animstate + 0xF8)[0] , 1)); -- 0xF8 -- m_flFeetSpeedForwardsOrSideWays
    local speedfactor = math.max(0, math.min( 1, ffi.cast("float*", animstate + 0xFC)[0])) ; -- 0xFC - m_flFeetSpeedUnknownForwardOrSideways;

    local m_fUnknown = ( ( ffi.cast("float*", animstate + 0x11C)[0] * -0.30000001 ) - 0.19999999 ) * speedfraction; -- 0x11C - m_flStopToFullRunningFraction
    local m_fUnknown2 = m_fUnknown + 1.0;

    if (m_fDuckAmount > 0) then
        m_fUnknown2 = m_fUnknown2 + ((m_fDuckAmount * speedfactor) * (0.5 - m_fUnknown2))
    end

    local m_flUnknown3 = ffi.cast("float*", animstate + 0x334)[0] * m_fUnknown2; -- 0x334 - m_flUnknown3

    return m_flUnknown3;
end

function vector_c.eye_position(eid)
	local origin = vector(entity.get_entities(eid))
	local duck_amount = eid.m_flDuckAmount or 0
	origin.z = origin.z + 46 + (1 - duck_amount) * 18
	return origin
end

function angle_vector(angle_x, angle_y)
	local sy = math.sin(math.rad(angle_y))
	local cy = math.cos(math.rad(angle_y))
	local sp = math.sin(math.rad(angle_x))
	local cp = math.cos(math.rad(angle_x))
	return cp * cy, cp * sy, -sp
end

events.aim_ack:set(function(shot)
	c_rage.update_misses(shot)
	local reason = shot.reason
end)
events.check_shots:set(function(e)
	if missed ~= 0 then
		reset = true
		reset2 = true
		reset3 = true
	end
end)
events.render:set(function()
    get_helikopter()
end)