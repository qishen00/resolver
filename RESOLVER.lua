local function get_closest_point(p1, p2, p)
    local ap = p - p1
    local ab = p2 - p1
    local ab_len = vector.length(ab)
    local ab_norm = vector.normalize(ab)
    local ap_dot_ab = vector.dot(ap, ab_norm)

    if ap_dot_ab <= 0 then
        return vector.distance(p1, p)
    elseif ap_dot_ab >= ab_len then
        return vector.distance(p2, p)
    else
        local closest_point = p1 + ab_norm * ap_dot_ab
        return vector.distance(closest_point, p)
    end
end

local function aimbot_shot(weapon, target, hitbox)
    local aim_angle = engine.get_view_angles()
    local local_player = entity.get_local_player()
    local local_pos = entity.get_abs_origin(local_player)
    local target_pos = entity.hitbox_position(target, hitbox)
    local distance = vector.distance(local_pos, target_pos)
    local velocity = entity.get_prop(local_player, "m_vecVelocity")
    local speed = vector.length(vector.mul(velocity, { x=1, y=1, z=0 }))
    local hitgroup_scale = (hitbox == 1) and 4 or 1

    if distance <= 200 then
        ui_set("RAGE", "Aimbot", "Target Selection", "Distance")
        ui_set("RAGE", "Aimbot", "Hitbox", 0)
        ui_set("RAGE", "Aimbot", "Pointscale", 100)
        ui_set("RAGE", "Aimbot", "Minimum Damage", 60)
    elseif distance <= 400 then
        ui_set("RAGE", "Aimbot", "Target Selection", "Cycle")
        if hitbox == 1 then
            ui_set("RAGE", "Aimbot", "Pointscale", 100 * hitgroup_scale)
            ui_set("RAGE", "Aimbot", "Minimum Damage", 80)
        else
            ui_set("RAGE", "Aimbot", "Pointscale", 75)
            ui_set("RAGE", "Aimbot", "Minimum Damage", 50)
            ui_set("RAGE", "Aimbot", "Hitchance", 90)
        end
    else
        ui_set("RAGE", "Aimbot", "Target Selection", "Field of View")
        ui_set("RAGE", "Aimbot", "Target hitbox", hitbox)
        ui_set("RAGE", "Aimbot", "Pointscale", 50)
        ui_set("RAGE", "Aimbot", "Minimum damage", 30)
        ui_set("RAGE", "Aimbot", "Hitchance", 80)
    end
    
    aimbot.shoot_at_target(target, hitbox, aim_angle)
end

local function auto_adapt_aimbot()
    local me = entity.get_local_player()
    if not me then
        return
    end
    
    local target_distance = math.huge
    local target_hitbox = nil
    local target_angle = { x = 0, y = 0 } -- 目标角度信息
    local deviation = nil -- 偏转角度
    local optimal_hitbox = nil -- 最优的身体部位
    
    -- 获取当前目标所在的身体部位
    local hitbox = last_hitbox or 0
    if target and entity.is_alive(target) then
        for i=1, hitboxes.count do
            if hitboxes[i].index == hitbox then
                target_hitbox = i
                break
            end
        end
        -- 计算目标的朝向角度
        local target_origin = entity.get_prop(target, "m_vecOrigin")
        if target_origin ~= nil then
            target_angle = calculate_relative_angles(me, target_origin)
        end
    end
    
    -- 根据距离设置自动切换模式
    local distance = vector.distance(entity.get_origin(me), entity.get_origin(target))
    if distance <= 200 then
        ui_set("RAGE", "Aimbot", "Target selection", "Distance")
        ui_set("RAGE", "Aimbot", "Target hitbox", 0)
        ui_set("RAGE", "Aimbot", "Pointscale", 100)
        ui_set("RAGE", "Aimbot", "Minimum damage", 60)
        ui_set("RAGE", "Aimbot", "Hitchance", 100)
    elseif distance <= 400 then
        ui_set("RAGE", "Aimbot", "Target selection", "Cycle")
        ui_set("RAGE", "Aimbot", "Target hitbox", hitbox)
        if hitbox == 1 then -- 头部盒子
            ui_set("RAGE", "Aimbot", "Point scale", 100) -- 设置更高的权重值
            ui_set("RAGE", "Aimbot", "Minimum damage", 80) -- 对头部盒子进行更大的伤害
            ui_set("RAGE", "Aimbot", "Hitchance", 100) -- 提高命中率
        else
            ui_set("RAGE", "Aimbot", "Point scale", 75)
            ui_set("RAGE", "Aimbot", "Minimum damage", 50)
            ui_set("RAGE", "Aimbot", "Hitchance", 90)
        end
    else
        ui_set("RAGE", "Aimbot", "Target selection", "Field of View")
        ui_set("RAGE", "Aimbot", "Target hitbox", hitbox)
        ui_set("RAGE", "Aimbot", "Pointscale", 50)
        ui_set("RAGE", "Aimbot", "Minimum damage", 30)
        ui_set("RAGE", "Aimbot", "Hitchance", 80)
    end
    
    -- 如果当前目标无法攻击，寻找新目标
    if not target or not entity.is_alive(target) or distance > 3000 then
        target, target_distance = nil, math.huge
        for i=1, entity.get_players(true) do
            local enemy = entity.get_player(i)
            if enemy and enemy ~= me and entity.is_alive(enemy) then
                local enemy_distance = vector.distance(entity.get_origin(me), entity.get_origin(enemy))
                if enemy_distance < target_distance then
                    target, target_distance = enemy, enemy_distance
                end
            end
        end
        last_hitbox = 0
    end
    
    -- 如果当前目标可以攻击，则计算最优解
    if target and entity.is_alive(target) then
        local target_origin = entity.get_origin(target)
        for i=1, hitboxes.count do
            local hitbox = hitboxes[i]
            local hitbox_distance = vector.distance(hitbox.position, target_origin)
            if hitbox_distance < target_distance and hitbox.can_hit(target) then
                target_distance = hitbox_distance
                target_hitbox = i
                -- 计算偏转角度及最优的身体部位
                local hitbox_angle = calculate_relative_angles(me, hitbox.position)
                if deviation == nil or math.abs(get_delta_angle(hitbox_angle, target_angle)) < deviation then
                    deviation = math.abs(get_delta_angle(hitbox_angle, target_angle))
                    optimal_hitbox               = i
                end
            end
        end
        
        -- 如果有最优解，则进行自动调整
        if optimal_hitbox ~= nil then
            hitbox = optimal_hitbox
            last_hitbox = hitbox
            
            -- 根据距离和部位设置自动切换模式
            if distance <= 200 then
                ui_set("RAGE", "Aimbot", "Target selection", "Distance")
                ui_set("RAGE", "Aimbot", "Target hitbox", 0)
                ui_set("RAGE", "Aimbot", "Pointscale", 100)
                ui_set("RAGE", "Aimbot", "Minimum damage", 60)
                ui_set("RAGE", "Aimbot", "Hitchance", 100)
            elseif distance <= 400 then
                ui_set("RAGE", "Aimbot", "Target selection", "Cycle")
                ui_set("RAGE", "Aimbot", "Target hitbox", hitbox)
                if hitbox == 1 then -- 头部盒子
                    ui_set("RAGE", "Aimbot", "Point scale", 100) -- 设置更高的权重值
                    ui_set("RAGE", "Aimbot", "Minimum damage", 80) -- 对头部盒子进行更大的伤害
                    ui_set("RAGE", "Aimbot", "Hitchance", 100) -- 提高命中率
                else
                    ui_set("RAGE", "Aimbot", "Point scale", 75)
                    ui_set("RAGE", "Aimbot", "Minimum damage", 50)
                    ui_set("RAGE", "Aimbot", "Hitchance", 90)
                end
            else
                ui_set("RAGE", "Aimbot", "Target selection", "Field of View")
                ui_set("RAGE", "Aimbot", "Target hitbox", hitbox)
                ui_set("RAGE", "Aimbot", "Pointscale", 50)
                ui_set("RAGE", "Aimbot", "Minimum damage", 30)
                ui_set("RAGE", "Aimbot", "Hitchance", 80)
            end
            
            -- 自动瞄准射击
            aimbot_shot(weapon, target, hitbox)
        end
    end
    end
    -- 设置默认的瞄准参数
local last_hitbox = 0

-- 获取当前射击武器
local function get_current_weapon(me)
    local active_weapon_id = entity.get_prop(me, "m_hActiveWeapon")
    if active_weapon_id == nil then
        return nil
    end
    return entity.get_prop(active_weapon_id, "m_hOwnerEntity") == me and entity.get_classname(active_weapon_id) or nil
end

-- 获取当前武器的射击扩散值
local function get_weapon_spread(weapon)
    if weapon == "CKnife" or weapon == "CHEGrenade" or weapon == "CDecoyGrenade" or weapon == "CFlashbang" or weapon == "CSmokeGrenade" then
        return 0
    end
    local spread = entity.get_prop(weapon, "m_fAccuracyPenalty")
    local recoil = entity.get_prop(weapon, "m_flRecoilIndex")
    if spread ~= nil and recoil ~= nil then
        return math.rad(spread * recoil)
    end
    return nil
end

-- 计算瞄准时需要偏转的角度
local function calculate_deviation(target_angle, spread, recoil_scale)
    local deviation = { x = 0, y = 0 }
    local factors = { 1 - recoil_scale, 1 - recoil_scale, 1 - recoil_scale }
    deviation.x = factors[1] * target_angle.x + spread * factors[2]
    deviation.y = factors[1] * target_angle.y + spread * factors[2]
    return vector.normalize(deviation)
end

-- 计算相对于自己的角度
local function calculate_relative_angles(me, enemy_pos)
    local view_angles = engine.get_view_angles()
    local enemy_rel_pos = vector.sub(enemy_pos, entity.get_eye_position(me))
    local enemy_yaw = math.deg(math.atan2(enemy_rel_pos.y, enemy_rel_pos.x))
    local enemy_pitch = math.deg(math.atan2(enemy_rel_pos.z, vector.length({ x = enemy_rel_pos.x, y = enemy_rel_pos.y })))
    local angle_to_target = { x = enemy_pitch - view_angles.x, y = enemy_yaw - view_angles.y }
    angle_to_target = vector.normalize(vector.clamp(angle_to_target, -180, 180))
    return angle_to_target
end

-- 获取最优的身体部位
local function get_optimal_hitbox(enemy)
    local hitbox_priorities = {"Pelvis", "Stomach", "Lower chest", "Upper chest", "Neck", "Head"}
    local hitbox_priority = nil
    for i=1, #hitbox_priorities do
        if entity.get_hitbox_pos(enemy, hitboxes[hitbox_priorities[i]]) ~= nil then
            hitbox_priority = hitboxes[hitbox_priorities[i]]
            break
        end
    end
    return hitbox_priority or hitboxes["Body"]
end

-- 计算射线散布角度
local function calculate_shoot_angle(spread, recoil_scale)
    local aim_punch = entity.get_prop(entity.get_local_player(), "m_aimPunchAngle") or {x=0, y=0, z=0}
    local punch_angle = vector.mul(aim_punch, { x=recoil_scale, y=recoil_scale, z=0 })
    local deviation = vector.normalize({ x = punch_angle.x + spread, y = punch_angle.y + spread, z = 0 })
    return { x = math.deg(math.atan(deviation.y / deviation.x)), y = math.deg(math.atan(deviation.z / vector.length({ x = deviation.x, y = deviation.y }))), z = math.deg(math.atan(vector.length(deviation))) }
end

-- 获取玩家的后坐力缩放比例
local function get_recoil_scale()
    local weapon = get_current_weapon(entity.get_local_player()) -- 获取当前武器
    if weapon ~= nil then
        local item_definition_index = entity.get_prop(entity.get_prop(weapon, "m_hItemDefinitionIndex"), "m_nFallbackStatTrak")
        if item_definition_index ~= nil and item_definition_index > 0 then -- 如果装备了 StatTrak 武器，使用后坐力缩放
            local recoil_scale = entity.get_prop(entity.get_player_resource(), "m_iCompetitiveWins", entity.get_local_player()) / item_definition_index
            return math.max(0.1, recoil_scale) -- 后坐力缩放最小值为 0.1
        end
    end
    return 1.0 -- 如果没有获取到后坐力缩放比例，则默认为 1.0
end

-- 进行瞄准射击
local function aimbot_shot(weapon, target, hitbox, spread, recoil_scale)
    if not target then
        return false
    end

    local aim_angle = engine.get_view_angles()
    local local_player = entity.get_local_player()
    local local_pos = entity.get_abs_origin(local_player)
    local target_pos = entity.hitbox_position(target, hitbox)
    local distance = vector.distance(local_pos, target_pos)
    local velocity = entity.get_prop(local_player, "m_vecVelocity")
    local speed = vector.length(vector.mul(velocity, { x=1, y=1, z=0 }))
    local hitgroup_scale = (hitbox == 1) and 4 or 1
    local client_state = se.get_clientstate()

    -- 射击扩散计算
    local shot_angle = calculate_shoot_angle(spread, recoil_scale)
    local view_forward = angle_forward(aim_angle)
    local right = vector.cross({ x = 0, y = 0, z = 1 }, view_forward)
    local up = vector.cross(view_forward, right)
    local spread_direction = vector.normalize(view_forward + right * shot_angle.x + up * shot_angle.y)
    local spread_offset = spread_direction * distance * math.tan(math.rad(shot_angle.z))

    target_pos = target_pos + spread_offset

    if distance <= 200 then
        ui_set("RAGE", "Aimbot", "Target selection", "Distance")
        ui_set("RAGE", "Aimbot", "Target hitbox", 0)
        ui_set("RAGE", "Aimbot", "Pointscale", 100)
        ui_set("RAGE", "Aimbot", "Minimum damage", 60)
    elseif distance <= 400 then
        ui_set("RAGE", "Aimbot", "Target selection", "Cycle")
        if hitbox == 1 then
            ui_set("RAGE", "Aimbot", "Pointscale", 100 * hitgroup_scale)
            ui_set("RAGE", "Aimbot", "Minimum damage", 80)
        else
            ui_set("RAGE", "Aimbot", "Pointscale", 75)
            ui_set("RAGE", "Aimbot", "Minimum damage", 50)
            ui_set("RAGE", "Aimbot", "Hitchance", 90)
        end
    else
        ui_set("RAGE", "Aimbot", "Target selection", "Field of View")
        ui_set("RAGE", "Aimbot", "Target hitbox", hitbox)
        ui_set("RAGE", "Aimbot", "Pointscale", 50)
        ui_set("RAGE", "Aimbot", "Minimum damage", 30)
        ui_set("RAGE", "Aimbot", "Hitchance", 80)
    end
    
    aimbot.shoot_at_target(target, hitbox, aim_angle, client_state, weapon, target_pos)
end

-- 自动适应瞄准主函数
local function auto_adapt_aimbot()
    local me = entity.get_local_player()
    if not me then
        return
    end
    
    local target_distance = math.huge
    local target_hitbox = nil
    local target_angle = { x = 0, y = 0 } -- 目标角度信息
    local deviation = nil -- 偏转角度
    local optimal_hitbox = nil -- 最优的身体部位
    local weapon = get_current_weapon(me) -- 获取当前武器
    local spread = get_weapon_spread(weapon) -- 获取当前武器的射击扩散值
    local recoil_scale = get_recoil_scale() -- 获取玩家的后坐力缩放比例
    
    -- 获取当前目标所在的身体部位
    local hitbox = last_hitbox or 0
    local enemies = entity.get_players(true) -- 获取敌方玩家列表
for i=1, #enemies do
    local enemy = enemies[i]
    if entity.is_alive(enemy) and entity.is_enemy(enemy) then -- 如果目标是敌对方且还活着
        local hitbox_pos = entity.hitbox_position(enemy, hitbox)
        local distance = vector.distance(entity.get_abs_origin(me), hitbox_pos)
        if distance < target_distance then -- 如果该目标更近
            target_distance = distance
            target_angle = calculate_relative_angles(me, hitbox_pos)
            optimal_hitbox = get_optimal_hitbox(enemy)
            deviation = calculate_deviation(target_angle, spread, recoil_scale)
            target_hitbox = hitbox
        end
    end
end

if target_hitbox ~= nil then -- 如果有可攻击的目标
    aimbot_shot(weapon, entity.get_entity_from_userid(aimbot.get_target()), target_hitbox, spread, recoil_scale)
else -- 如果没有可攻击的目标，则重置 aimbot
    aimbot.reset()
end

last_hitbox = target_hitbox -- 保存最后一次成功攻击的身体部位
end