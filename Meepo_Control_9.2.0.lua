-- MEEPO ATLAS 9.2.0 / Umbrella UC.Zone API v2 / Lua 5.4
-- Local syntax and mock tests only. Validate in the current client before use.
-- One script instance only. New profile avoids inheriting obsolete automation settings.
local M = { NAME = "Meepo Control", VERSION = "9.2.0", CONFIG_NAME = "Meepo_Control_9", ORDER_PREFIX = "meepo_ctl9:" }
local A, UI, Combat, Farm, Orders, HUD = {}, {}, {}, {}, {}, {}
local S = {}
local Econ = {}
local Stable, Stack = {}, {}
local Tower = {}
M.tower = Tower
M.stable, M.stack = Stable, Stack
M.economy = Econ
local Items, Heal = {}, {}
local RunesAI, Push, Mega = {}, {}, {}
local NetPlan, Emergency, World, Perf, Trace = {}, {}, {}, {}, {}
local CampMap, Preset = {}, {}
local Roles, Atlas = {}, {}
M.runes, M.push, M.mega = RunesAI, Push, Mega
M.items, M.heal = Items, Heal
M.netplan, M.emergency, M.world, M.perf, M.trace = NetPlan, Emergency, World, Perf, Trace
local D = {
    role_1=0,role_2=0,role_3=0,role_4=0,role_5=0,role_6=0,
    atlas_extent=9000,atlas_offset_x=0,atlas_offset_y=0,
    work_preset=0, camp_filter=true, camp_map_key="KEY_F7",
    enabled = true, combo_all = true, combo_net = true, combo_poof = true,
    combo_radius = 260, combo_world_radius = 550, net_overlap_ms = 120,
    poof_require_root = false, combo_blink = true,
    combo_hex = true, combo_silence = true, combo_slow = true,
    farm_enabled = false, farm_mode = 0, farm_side = 0, farm_poof = true,
    farm_min_creeps = 2, farm_mana_pct = 30, farm_retreat_hp = 30,
    farm_resume_hp = 75, farm_avoid_enemies = true, manual_pause_ms = 2500,
    save_enabled = true, save_hp = 25, save_dig = true, save_mega = true,
    save_poof = true, hud = true, world_labels = true, debug_log = false,
    combo_key = "KEY_SPACE", farm_key = "KEY_F6", poof_cursor_key = "KEY_F",
    poof_self_key = "KEY_G",
    farm_strategy = 1, lane_safe_radius = 1800, lane_memory_sec = 12,
    lane_respect_allies = true, heal_mode = 2, items_enabled = true,
    items_offensive = true, items_defensive = true, items_resources = true,
    items_detection = true, items_refresher = false,
    items_toggles = false,
    hex_mode = 0, hex_margin_ms = 180,
    runes_enabled = false, runes_radius = 600, runes_main = true,
    runes_bounty = true, runes_power = true, runes_wisdom = true,
mega_mode = 0, mega_group_hp = 40,
    mega_group_count = 2, econ_enabled = true, econ_goal = 0, econ_xp_weight = 25,
    econ_ancients = true, econ_poof = true, econ_poof_save_ms = 350,
    econ_reserve_net = true, econ_travel_poof = true, econ_travel_save = 2,
    econ_resources = true, econ_midas = true, econ_watchdog = true,
    econ_stall_sec = 8, econ_details = true, econ_switch_pct = 20,
    stack_enabled = false, stack_second = 54, stack_distance = 1000,
    stack_min_hp = 45, stable_trace = false,
    hud_scale = 100, hud_right_margin = 24,
    hud_bottom_margin = 270, hud_hide_captured = true, hud_details = false,
    escape_key="KEY_F8", resume_key="KEY_F9", escape_tp=true, manual_mode=1,
    net_plan_steps=4, target_lock=true, target_policy=0, gather_mode=1, gather_distance=800, perf_mode=0,
}
M.defaults, M.state, M.ui = D, S, UI
M.combat, M.farm, M.orders, M.api = Combat, Farm, Orders, A

function A.call(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c = pcall(fn, ...)
    if ok then return a, b, c end
    S.api_errors=S.api_errors or {}
    local text=tostring(a)
    local last=S.api_errors[#S.api_errors]
    if last and last.fn==tostring(fn) and last.text==text then
        last.count=last.count+1;last.time=S.now or 0
    else
        if #S.api_errors>=64 then table.remove(S.api_errors,1) end
        S.api_errors[#S.api_errors+1]={fn=tostring(fn),text=text,count=1,time=S.now or 0}
    end
    S.last_api_error=text
    return nil
end
function A.method(obj, name, ...)
    if not obj then return nil end
    local ok,fn=pcall(function() return obj[name] end)
    if not ok then S.last_api_error=tostring(fn);return nil end
    return A.call(fn,obj,...)
end
function A.number(v, fallback)
    local n = tonumber(v)
    if n and n == n and n ~= math.huge and n ~= -math.huge then return n end
    return fallback or 0
end
function A.now() return A.number(A.call(GameRules and GameRules.GetGameTime), 0) end
function A.enum(group, name)
    return Enum and Enum[group] and Enum[group][name] or nil
end
function A.vec(x, y, z) return Vector(x or 0, y or 0, z or 0) end
function A.copy(p) return p and A.vec(p.x, p.y, p.z) or nil end
function A.valid_position(p)
    if p==nil then return false end
    local ok,x,y,z=pcall(function() return p.x,p.y,p.z end)
    return ok and type(x)=="number" and type(y)=="number" and type(z)=="number"
        and x==x and y==y and z==z and math.abs(x)<50000 and math.abs(y)<50000 and math.abs(z)<50000
end
function A.manual(u,now)
    local id=A.id(u)
    return id~=nil and (now or S.now or A.now())<(S.manual_until[id] or -math.huge)
end
function A.distance2(a, b)
    if not a or not b then return math.huge end
    local x, y = a.x - b.x, a.y - b.y
    return x*x + y*y
end
function A.distance(a, b) return math.sqrt(A.distance2(a, b)) end
function A.pos(u) return u and A.call(Entity and Entity.GetAbsOrigin, u) or nil end
function A.id(u) return u and (A.call(Entity and Entity.GetIndex, u) or u) or nil end
function A.alive(u) return u ~= nil and A.call(Entity and Entity.IsAlive, u) == true end
function A.visible(u) return A.alive(u) and A.call(Entity.IsDormant, u) ~= true end
function A.team(u) return A.call(Entity and Entity.GetTeamNum, u) end
function A.name(u) return A.call(NPC and NPC.GetUnitName, u) or "" end
function A.hp(u)
    local max = A.number(A.call(Entity.GetMaxHealth, u), 0)
    return max > 0 and math.max(0, A.number(A.call(Entity.GetHealth, u), 0) / max * 100) or 0
end
function A.mana(u) return A.number(A.call(NPC.GetMana, u), 0) end
function A.mana_pct(u)
    local max = A.number(A.call(NPC.GetMaxMana, u), 0)
    return max > 0 and A.mana(u)/max*100 or 0
end
function A.has(u, name) return A.call(NPC.HasModifier, u, name) == true end
function A.state(u, name)
    local e = A.enum("ModifierState", name)
    return e ~= nil and A.call(NPC.HasState, u, e) == true
end
function A.disabled(u, item)
    if A.state(u,"MODIFIER_STATE_STUNNED") or A.state(u,"MODIFIER_STATE_HEXED")
        or A.state(u,"MODIFIER_STATE_COMMAND_RESTRICTED") then return true end
    if item then return A.state(u,"MODIFIER_STATE_MUTED") end
    return A.state(u,"MODIFIER_STATE_SILENCED") or A.call(NPC.IsSilenced,u) == true
end
function A.spell(u, name) return A.call(NPC.GetAbility, u, name) end
function A.item(u, name) return A.call(NPC.GetItem, u, name, true) end
function A.special(ab, names, fallback)
    for _, name in ipairs(names) do
        local v = A.number(A.call(Ability.GetSpecialValueFor, ab, name), 0)
        if v <= 0 then v = A.number(A.call(Ability.GetLevelSpecialValueFor, ab, name, -1), 0) end
        if v > 0 then return v end
    end
    return fallback
end
function A.ready(u, ab, item)
    if not A.alive(u) then return false, "Мипо мёртв" end
    if not ab then return false, "Способность не найдена" end
    if A.disabled(u, item) then return false, "Оглушение / безмолвие" end
    if A.call(Ability.IsHidden, ab) == true then return false, "Способность скрыта" end
    if A.call(Ability.IsActivated, ab) == false then return false, "Способность недоступна" end
    local level = A.call(Ability.GetLevel, ab)
    if not item and type(level)~="number" then return false,"API: неизвестен уровень способности" end
    if not item and level < 1 then return false, "Способность не изучена" end
    if A.call(Ability.IsInAbilityPhase, ab) == true or A.call(Ability.IsChannelling, ab) == true then
        return false, "Уже применяется"
    end
    local cooldown=A.call(Ability.GetCooldown,ab)
    local mana=A.call(NPC.GetMana,u)
    local cost=A.call(Ability.GetManaCost,ab)
    if type(cooldown)~="number" or cooldown~=cooldown or math.abs(cooldown)==math.huge
        or type(mana)~="number" or mana~=mana or math.abs(mana)==math.huge
        or type(cost)~="number" or cost~=cost or cost<0 or cost==math.huge then
        return false,"API: нет достоверных данных о готовности"
    end
    if cooldown > 0.04 then return false, "Перезарядка" end
    if mana < cost then return false, "Не хватает маны" end
    if type(Ability.IsCastable)~="function" then return false,"API: IsCastable недоступен" end
    local castable=A.call(Ability.IsCastable,ab,mana)
    if castable~=true then return false,"Система: применение недоступно" end
    return true
end
function A.range(u, ab, fallback)
    local r = A.number(A.call(Ability.GetCastRange, ab), fallback)
    if r <= 0 then r = fallback end
    return r + math.max(0, A.number(A.call(NPC.GetCastRangeBonus, u), 0))
end
function A.poof_time(ab)
    return A.special(ab, {"poof_cast_duration", "cast_duration"}, 1.5)
end
function A.poof_radius(ab) return A.special(ab, {"radius", "poof_radius"}, 375) end
function A.net_speed(ab) return A.special(ab, {"speed", "projectile_speed"}, 900) end
function A.mod_remaining(mod, now)
    if not mod then return 0 end
    local die = A.call(Modifier and Modifier.GetDieTime, mod)
    if type(die) == "number" and die >= now and die - now < 30 then return die - now end
    local duration = A.number(A.call(Modifier and Modifier.GetDuration, mod), 0)
    local applied = A.call(Modifier and Modifier.GetLastAppliedTime, mod)
        or A.call(Modifier and Modifier.GetCreationTime, mod)
    if type(applied) == "number" and duration > 0 then return math.max(0, applied + duration - now) end
    return 0
end
function A.root_remaining(target, now)
    local max = 0
    for _, name in ipairs({"modifier_meepo_earthbind", "modifier_meepo_earthbind_debuff", "modifier_meepo_earthbind_root"}) do
        local mod = A.call(NPC.GetModifier, target, name)
        if mod then max = math.max(max, A.mod_remaining(mod, now)) end
    end
    return max
end
function A.control_remaining(target, now)
    local max = A.root_remaining(target, now)
    for _, name in ipairs({"modifier_sheepstick_debuff", "modifier_abyssal_blade_stun", "modifier_rod_of_atos_debuff", "modifier_gleipnir_root"}) do
        max = math.max(max, A.mod_remaining(A.call(NPC.GetModifier,target,name),now))
    end
    return max
end
function A.enemy(u)
    return A.visible(u) and A.call(NPC.IsVisible,u) ~= false and A.team(u) ~= S.team and A.team(u) ~= nil
        and A.call(Entity.IsHero,u) == true and A.call(NPC.IsIllusion,u) ~= true
end
function A.enemy_count_at(pos, radius)
    if not pos then return math.huge end
    if not S.heroes_valid then return math.huge end
    local count, r2 = 0, radius*radius
    for _, u in ipairs(S.heroes or {}) do
        if A.enemy(u) and A.distance2(pos,A.pos(u)) <= r2 then count = count + 1 end
    end
    return count
end
function A.log(text, force)
    if not force and not UI.get("debug_log") then return end
    local now = A.now()
    if force and text == S.last_log and now < (S.next_log or -math.huge) then return end
    S.last_log, S.next_log = text, now + 3
    if type(print) == "function" then print("["..M.NAME.."] " .. tostring(text)) end
end
function M.reset()
    for k in pairs(S) do S[k] = nil end
    S.units, S.unit_ids, S.heroes, S.acted, S.locks = {}, {}, {}, {}, {}
    S.spell_next, S.orders, S.manual_until, S.hp_samples = {}, {}, {}, {}
    S.camps, S.camp_empty, S.assignment, S.healing, S.failures = {}, {}, {}, {}, {}
    S.camp_knowledge = {}
    S.combo_status, S.farm_status = "Ожидание клавиши комбо", "Ожидание клонов"
    S.metrics = {orders=0, nets=0, poofs=0, failures=0, hero_scans=0, npc_scans=0}
    S.key_prev, S.key_pending = {}, {}
    S.enemy_memory, S.heal_records, S.tango_until, S.item_diagnostics = {}, {}, {}, {}
    S.metrics.items = 0
    S.parking, S.rune_claims, S.rune_busy, S.push_escape, S.rune_retry = {}, {}, {}, {}, {}
    S.echo_casts, S.echo_seen, S.attack_commit = {}, {}, {}
    S.econ_cache, S.econ_profiles, S.econ_info, S.econ_watch = {}, {}, {}, {}
    S.econ_blacklist, S.econ_retries, S.econ_route_cache = {}, {}, {}
    S.econ_plan, S.econ_metrics = {}, {evaluations=0,plans=0,nodes=0,stalls=0,travel_poofs=0,midas=0}
    S.econ_cycle=0
    S.creep_owner,S.farm_retreat,S.stack_units,S.stack_camps,S.stack_attempts={},{},{},{},{}
    S.stack_results,S.farm_trace={},{}
    S.stack_claims,S.ally_camp,S.poof_watch,S.poof_block={},{},{},{}
    S.tower_shots,S.tower_evade,S.tower_seq,S.tower_hits={},{},0,{}
    S.finance,S.finance_buffer={},{}
    S.motion,S.order_next,S.inventory_cache,S.item_next={},{},{},{}
    S.econ_retry_time,S.net_misses,S.net_retry_until={},{},{}
    S.api_errors={}
    S.combo_blocked=false
    S.net_plan=nil;S.net_plan_next=-math.huge
    S.escape={active=false,latched=false,status={},next_attempt={}}
    S.history={};S.world_valid=false;S.gather=nil
    HUD.cache,HUD.fit_cache,HUD.fit_count=nil,nil,0
    S.camp_map=nil;S.camp_cancel={}
    S.role_slots,S.role_units,S.role_status=nil,{},{}
    S.camp_types,S.camp_type_next={},{}
    S.camp_epoch=A.number(A.call(Config and Config.ReadInt,M.CONFIG_NAME,"camp_mask_generation",0),0)
end
M.reset()

-- Настройки: новое имя профиля не подхватывает ошибочные значения MeepoV2.
function UI.default(key)
    local d = D[key]
    if type(d) == "string" and key:find("_key$",1) then
        return A.enum("ButtonCode", d) or A.enum("ButtonCode", "KEY_NONE")
            or A.enum("ButtonCode", "BUTTON_CODE_INVALID")
    end
    return d
end
function UI.load(key)
    local d = UI.default(key)
    if type(d) == "boolean" then
        local v = A.call(Config and Config.ReadInt,M.CONFIG_NAME,key,d and 1 or 0)
        if v == nil then return d end
        return v ~= 0
    elseif type(d) == "number" then
        return A.number(A.call(Config and Config.ReadInt,M.CONFIG_NAME,key,d),d)
    end
    return d
end
function UI.get(key)
    local w = UI[key]
    local v = w and A.method(w,"Get")
    if v ~= nil then return v end
    if UI.values and UI.values[key] ~= nil then return UI.values[key] end
    return UI.default(key)
end
function UI.save(key)
    local v = UI.get(key)
    if type(v) == "boolean" then v = v and 1 or 0 end
    if type(v) == "number" then A.call(Config and Config.WriteInt,M.CONFIG_NAME,key,v) end
end
-- Одна точка записи: виджет, резервное значение, профиль и индикатор клавиши.
function UI.sync_farm_bind()
    local value=UI.get("farm_enabled")==true
    A.method(UI.farm_key,"SetToggled",value)
    A.method(UI.farm_key,"Properties","Автофарм",value and "Включён" or "Выключен",true)
end
function UI.changed(key)
    UI.values[key]=UI.get(key)
    if key:match("^role_[1-6]$") then
        Roles.changed(tonumber(key:match("(%d+)$")))
    elseif key:match("^atlas_") then
        CampMap.state().layout=nil
    elseif key=="work_preset" then
        if UI.get(key)==1 then Preset.apply() else Preset.restore() end
    elseif key=="camp_filter" or key=="farm_side" or key=="farm_strategy" then
        CampMap.invalidate()
    elseif key=="farm_enabled" then
        S.farm_next=-math.huge
        S.farm_status=UI.values[key] and "Автофарм включён" or "Автофарм выключен"
        UI.sync_farm_bind()
    elseif key=="farm_key" then
        S.key_prev[key]=UI.down(key);S.key_pending[key]=nil
        UI.sync_farm_bind()
    end
    UI.save(key)
end
function UI.set(key,value)
    if UI.get(key)==value then return false end
    UI.values[key]=value
    UI.setting=true
    A.method(UI[key],"Set",value)
    UI.setting=false
    UI.changed(key)
    return true
end
-- Отключается только главный переключатель сплитпуша, не его настройки.
function UI.push_active() return false end

-- Локализация вывода: внутренние фазы и имена сущностей остаются прежними.
UI.phase_names = {
    idle="Ожидание", approach="Подход", combat="Атака", search="Поиск",
    confirm_empty="Проверка лагеря", done="Завершено", lane="Линия", push="Сплитпуш",
    stack_pull="Отвод", stack_verify="Проверка стака", tower_exit="Отход от башни",
    tag="Агро", pull="Отвод", verify="Проверка", root_wait="Ожидание сетки",
    gather="Сбор", fight="Бой",
}
function UI.phase_name(phase)
    return UI.phase_names[phase] or "Ожидание"
end
UI.hero_names = {
    abaddon="Абаддон", abyssal_underlord="Андерлорд", alchemist="Алхимик", ancient_apparition="Древний призрак",
    antimage="Антимаг", arc_warden="Арк Варден", axe="Акс", bane="Бэйн", batrider="Бэтрайдер",
    beastmaster="Повелитель зверей", bloodseeker="Бладсикер", bounty_hunter="Охотник за головами",
    brewmaster="Пивовар", bristleback="Бристлбек", broodmother="Праматерь", centaur="Кентавр",
    chaos_knight="Рыцарь хаоса", chen="Чен", clinkz="Клинкз", crystal_maiden="Кристал Мэйден",
    dark_seer="Дарк Сир", dark_willow="Тёмная ива", dawnbreaker="Заря", dazzle="Даззл",
    death_prophet="Пророк смерти", disruptor="Дизраптор", doom_bringer="Дум", dragon_knight="Драконий рыцарь",
    drow_ranger="Дроу Рейнджер", earth_spirit="Дух земли", earthshaker="Шейкер", elder_titan="Древний титан",
    ember_spirit="Дух огня", enchantress="Чаровница", enigma="Энигма", faceless_void="Безликий",
    furion="Лесной пророк", grimstroke="Гримстроук", gyrocopter="Гирокоптер", hoodwink="Худвинк",
    huskar="Хускар", invoker="Инвокер", jakiro="Джакиро", juggernaut="Джаггернаут",
    keeper_of_the_light="Хранитель света", kez="Кез", kunkka="Кункка", legion_commander="Командир легиона",
    leshrac="Лешрак", lich="Лич", life_stealer="Лайфстилер", lina="Лина", lion="Лион",
    lone_druid="Одинокий друид", luna="Луна", lycan="Ликан", magnataur="Магнус", marci="Марси",
    mars="Марс", medusa="Медуза", meepo="Мипо", mirana="Мирана", monkey_king="Король обезьян",
    morphling="Морфлинг", muerta="Муэрта", naga_siren="Нага", necrolyte="Некрофос",
    nevermore="Шэдоу Финд", night_stalker="Ночной охотник", nyx_assassin="Никс", obsidian_destroyer="Астральный разрушитель",
    ogre_magi="Огр-маг", omniknight="Омникнайт", oracle="Оракул", pangolier="Пангольер",
    phantom_assassin="Фантомная убийца", phantom_lancer="Фантомный копейщик", phoenix="Феникс",
    primal_beast="Первобытный зверь", puck="Пак", pudge="Пудж", pugna="Пугна", queenofpain="Королева боли",
    rattletrap="Клокверк", razor="Разор", riki="Рики", ringmaster="Рингмастер", rubick="Рубик",
    sand_king="Песчаный король", shadow_demon="Теневой демон", shadow_shaman="Теневой шаман",
    shredder="Лесоруб", silencer="Сайленсер", skeleton_king="Король-призрак", skywrath_mage="Небесный маг",
    slardar="Слардар", slark="Сларк", snapfire="Снэпфайр", sniper="Снайпер", spectre="Спектра",
    spirit_breaker="Баратрум", storm_spirit="Дух бури", sven="Свен", techies="Минёры", templar_assassin="Храмовница",
    terrorblade="Террорблейд", tidehunter="Тайдхантер", tinker="Тинкер", tiny="Тини", treant="Энт",
    troll_warlord="Полководец троллей", tusk="Туск", undying="Андаинг", ursa="Урса", vengefulspirit="Мстительный дух",
    venomancer="Веномансер", viper="Вайпер", visage="Визаж", void_spirit="Дух пустоты", warlock="Чернокнижник",
    weaver="Ткач", windrunner="Виндрейнджер", winter_wyvern="Зимняя виверна", wisp="Ио",
    witch_doctor="Знахарь", zuus="Зевс",
}
function UI.hero_name(unit)
    local name=A.name(unit):gsub("npc_dota_hero_","")
    return UI.hero_names[name] or ("Герой №"..tostring(A.id(unit) or "—"))
end

function UI.group(name, section)
    -- Скрипты → секция Meepo → Meepo Extended → самостоятельная категория → группа.
    local page=section or "ОБЩИЕ"
    return A.call(Menu and Menu.Create,"Scripts","Meepo",M.NAME,page,name)
end
function UI.add(group, kind, key, label, a, b)
    local v, w = UI.load(key), nil
    UI.values[key] = v
    if kind == "Switch" then w = A.method(group,kind,label,v)
    elseif kind == "Slider" then
        v = math.max(a,math.min(b,A.number(v,UI.default(key))))
        UI.values[key] = v; w = A.method(group,kind,label,a,b,v,"%d")
    elseif kind == "Combo" then
        v = math.max(0,math.min(#a-1,A.number(v,0)));UI.values[key] = v
        w = A.method(group,kind,label,a,v)
    elseif kind == "Bind" then w = A.method(group,kind,label,v) end
    UI[key] = w
    if w then A.method(w,"SetCallback",function()
        if not UI.setting then UI.changed(key) end
    end) end
    return w
end
function UI.reset_defaults()
    UI.setting=true
    for key in pairs(D) do
        local v = UI.default(key)
        UI.values[key] = v
        A.method(UI[key],"Set",v)
        UI.save(key)
    end
    UI.setting=false
    CampMap.reset_selection()
    M.reset()
    for _,kind in ipairs({"preferred","ignored"}) do
        A.method(UI["target_"..kind],"Set",{})
        if UI.target_sets then UI.target_sets[kind]={} end
        for _,key in pairs(UI.target_keys or {}) do A.call(Config and Config.WriteInt,M.CONFIG_NAME,kind..":"..key,0) end
    end
    Preset.backup=nil;A.call(Config and Config.WriteInt,M.CONFIG_NAME,"rage_backup_valid",0)
    UI.sync_farm_bind()
    A.log("Профиль сброшен: сетка и Poof включены; фарм запускается вручную.",true)
end
function UI.init()
    UI.values={}
    local g=UI.group("Профиль и управление","01 · УПРАВЛЕНИЕ")
    A.method(g,"Label","MEEPO / ATLAS 9.2 · карта и роли вместо лишней автоматики")
    UI.add(g,"Switch","enabled","Основная автоматика")
    UI.add(g,"Combo","work_preset","Профиль работы",{"Пользовательский / восстановить","RAGE · быстрый и демонстративный"})
    A.method(g,"Label","RAGE: общий Poof, быстрый Hex, широкий выбор цели. Без маскировки под человека.")
    A.method(g,"Label","Ручной приказ, F8/F9 и реальные применения не отменяются профилем.")
    UI.add(g,"Bind","combo_key","Комбо — удерживать [Пробел]")
    UI.add(g,"Bind","farm_key","Фарм — переключить [F6]")
    UI.add(g,"Bind","escape_key","Аварийный отход [F8]")
    UI.add(g,"Bind","resume_key","Завершить отход / разблокировать [F9]")
    UI.add(g,"Bind","poof_cursor_key","Poof к Мипо у курсора [F]")
    UI.add(g,"Bind","poof_self_key","Poof на месте [G]")
    UI.add(g,"Combo","manual_mode","Ручной приказ",{"Остановить всё комбо","Исключить только затронутых Мипо"})
    UI.add(g,"Slider","manual_pause_ms","Пауза затронутого Мипо, мс",500,6000)
    UI.add(g,"Switch","escape_tp","Разрешить TP в безопасном окне")
    A.method(g,"Button","Вернуть управление после отхода",function() Emergency.resume() end)
    A.method(g,"Button","Сбросить профиль",UI.reset_defaults)

    g=UI.group("Цель и участники","02 · КОМБО")
    UI.add(g,"Switch","combo_all","Участвуют все Мипо")
    UI.add(g,"Switch","target_lock","Удерживать доступную цель до отпускания")
    UI.add(g,"Combo","target_policy","Выбор в радиусе курсора",{"Предпочтительные, затем ближайший","Только ближайший к курсору"})
    UI.add(g,"Slider","combo_radius","Радиус выбора на экране, пикс.",60,600)
    UI.add(g,"Slider","combo_world_radius","Резервный мировой радиус",200,1200)
    UI.target_sets_init(g)
    g=UI.group("Сетка и резерв кастеров","02 · КОМБО")
    UI.add(g,"Switch","combo_net","Цепочка Earthbind")
    UI.add(g,"Slider","net_plan_steps","Планировать применений вперёд",2,6)
    UI.add(g,"Slider","net_overlap_ms","Запас перекрытия контроля, мс",50,350)
    A.method(g,"Label","Сетка — обездвиживание. План пересчитывается; контроль не гарантируется.")
    g=UI.group("Две стадии Poof","02 · КОМБО")
    UI.add(g,"Switch","combo_poof","Poof в комбо и стартовый сбор")
    UI.add(g,"Combo","gather_mode","Стартовый сбор к главному",{"Групповой с резервом сетки","Экономный: только дальние","Без стартового сбора"})
    UI.add(g,"Slider","gather_distance","Экономный сбор: дистанция",350,1800)
    UI.add(g,"Switch","poof_require_root","Очередь Poof только под контроль")
    UI.add(g,"Switch","combo_blink","Blink для сближения")
    UI.add(g,"Switch","combo_hex","Hex")
    UI.add(g,"Switch","combo_silence","Orchid / Bloodthorn")
    UI.add(g,"Switch","combo_slow","Diffusal / Disperser / Atos")
    UI.add(g,"Combo","hex_mode","Момент Hex",{"Угроза / конец контроля","При первой возможности","К концу контроля"})
    UI.add(g,"Slider","hex_margin_ms","Запас передачи контроля, мс",80,350)

    g=UI.group("Безопасный фарм","03 · ФАРМ")
    UI.add(g,"Switch","farm_enabled","Автофарм · отключается при комбо")
    UI.add(g,"Combo","farm_mode","Участники фарма",{"Только клоны","Все Мипо","Только невыбранные"})
    UI.add(g,"Combo","farm_strategy","Маршруты",{"Нейтралы","Адаптивный","Безопасные линии"})
    UI.add(g,"Combo","farm_side","Без фильтра карты: область",{"Своя половина карты","Вся карта"})
    UI.add(g,"Switch","camp_filter","Фармить только разрешённые на карте кемпы")
    UI.add(g,"Bind","camp_map_key","Карта выбора кемпов [F7]")
    A.method(g,"Button","Открыть / закрыть карту кемпов",function() CampMap.toggle() end)
    A.method(g,"Label","F7: каждый кемп отдельно, все / снять все / своя половина. Линии — отдельный маршрут.")
    UI.add(g,"Switch","farm_avoid_enemies","Избегать врагов")
    UI.add(g,"Slider","lane_safe_radius","Безопасность линии: радиус",900,3000)
    UI.add(g,"Slider","lane_memory_sec","Память о замеченном враге, с",3,30)
    UI.add(g,"Switch","lane_respect_allies","Не мешать союзникам")
    UI.add(g,"Switch","farm_poof","Poof по нейтралам")
    UI.add(g,"Slider","farm_min_creeps","Минимум нейтралов для Poof",1,6)
    UI.add(g,"Slider","farm_mana_pct","Минимальный остаток маны, %",0,80)
    g=UI.group("ATLAS · роли клонов","03 · ФАРМ")
    for slot=1,6 do UI.add(g,"Combo","role_"..slot,"Клон "..slot,Roles.names) end
    A.method(g,"Label","Мирные роли работают при F6. Комбо выше роли, кроме Ручного. F8 управляет всеми.")
    A.method(g,"Label","Древние: только подтверждённые лагеря. Стаки: без обычной зачистки вне окна.")
    g=UI.group("ATLAS · фон и привязка карты","05 · ИНТЕРФЕЙС")
    A.method(g,"Label","Фон Dota 7.41 загружается один раз с Liquipedia; игровых данных запрос не отправляет.")
    A.method(g,"Button","Загрузить фон Dota повторно",function() Atlas.checked=true;Atlas.fetch() end)
    UI.add(g,"Slider","atlas_extent","Полуразмер карты для привязки",7000,12000)
    UI.add(g,"Slider","atlas_offset_x","Смещение карты X",-2000,2000)
    UI.add(g,"Slider","atlas_offset_y","Смещение карты Y",-2000,2000)
    g=UI.group("Экономика маршрутов","03 · ФАРМ")
    UI.add(g,"Switch","econ_enabled","Планировщик новых заданий")
    UI.add(g,"Combo","econ_goal","Цель",{"Баланс золота и опыта","Золото","Опыт"})
    UI.add(g,"Slider","econ_xp_weight","Вес опыта, %",0,100)
    UI.add(g,"Switch","econ_ancients","Допуск к древним по оценке силы")
    UI.add(g,"Switch","econ_poof","Оценивать полезность Poof")
    UI.add(g,"Slider","econ_poof_save_ms","Минимальная экономия Poof, мс",100,1500)
    UI.add(g,"Switch","econ_reserve_net","Резерв маны на аварийную сетку")
    UI.add(g,"Slider","econ_switch_pct","Порог смены нового маршрута, %",10,50)
    UI.add(g,"Switch","econ_travel_poof","Poof для перехода")
    UI.add(g,"Slider","econ_travel_save","Минимальная экономия перехода, с",1,8)
    UI.add(g,"Switch","econ_watchdog","Восстановление зависшего задания")
    UI.add(g,"Slider","econ_stall_sec","Окно отсутствия прогресса, с",5,15)
    g=UI.group("Лечение, руны, стаки","03 · ФАРМ")
    UI.add(g,"Combo","heal_mode","Лечение",{"Фонтан","Танго, иначе фонтан","По оценке выгоды"})
    UI.add(g,"Slider","farm_retreat_hp","Уходить лечиться при ОЗ, %",10,60)
    UI.add(g,"Slider","farm_resume_hp","Возобновлять при ОЗ, %",50,100)
    UI.add(g,"Switch","econ_resources","Ресурсные предметы во время фарма")
    UI.add(g,"Switch","econ_midas","Поддерживаемый Midas")
    UI.add(g,"Switch","runes_enabled","Безопасный подбор рун")
    UI.add(g,"Slider","runes_radius","Максимальный крюк к руне",150,1000)
    UI.add(g,"Switch","runes_main","Главный Мипо подбирает руны")
    UI.add(g,"Switch","runes_bounty","Руны богатства")
    UI.add(g,"Switch","runes_power","Боевые руны и вода")
    UI.add(g,"Switch","runes_wisdom","Руны мудрости")
    UI.add(g,"Switch","stack_enabled","Стак текущего лагеря")
    UI.add(g,"Slider","stack_second","Секунда начала агро",50,57)
    UI.add(g,"Slider","stack_distance","Дистанция отвода",800,1500)
    UI.add(g,"Slider","stack_min_hp","Минимум ОЗ для стака, %",30,75)

    g=UI.group("Явные правила предметов","04 · ЗАЩИТА")
    UI.add(g,"Switch","items_enabled","Поддерживаемые активные предметы")
    UI.add(g,"Switch","items_offensive","Боевые предметы")
    UI.add(g,"Switch","items_defensive","Защитные предметы")
    UI.add(g,"Switch","items_resources","Предметы здоровья / маны")
    UI.add(g,"Switch","items_detection","Dust по видимой невидимой цели")
    UI.add(g,"Switch","items_refresher","Refresher по описанному правилу")
    UI.add(g,"Switch","items_toggles","Armlet / Radiance по описанному правилу")
    g=UI.group("Автоспасение вне аварийного режима","04 · ЗАЩИТА")
    UI.add(g,"Switch","save_enabled","Автоспасение раненого Мипо")
    UI.add(g,"Slider","save_hp","Порог спасения, %",5,45)
    UI.add(g,"Switch","save_dig","Dig")
    UI.add(g,"Switch","save_mega","MegaMeepo")
    UI.add(g,"Combo","mega_mode","Приоритет",{"Групповой Mega / одиночный Dig","Dig, затем Mega","Mega, затем Dig"})
    UI.add(g,"Slider","mega_group_hp","Раненый участник группы, %",25,60)
    UI.add(g,"Slider","mega_group_count","Раненых для группового Mega",2,4)
    UI.add(g,"Switch","save_poof","Poof к безопасному участнику")
    A.method(g,"Label","Автоохота, неизвестные предметы, Echo-додж и переагр башен удалены.")

    g=UI.group("Панель клиента","05 · ИНТЕРФЕЙС")
    UI.add(g,"Switch","hud","Панель MEEPO CONTROL")
    UI.add(g,"Switch","hud_details","Последние приказы и отказы")
    UI.add(g,"Switch","world_labels","Краткие статусы над Мипо")
    UI.add(g,"Switch","hud_hide_captured","Скрывать при занятом вводе")
    UI.add(g,"Slider","hud_scale","Масштаб, %",80,150)
    UI.add(g,"Slider","hud_right_margin","Отступ справа, пикс.",8,600)
    UI.add(g,"Slider","hud_bottom_margin","Отступ снизу, пикс.",120,500)
    UI.add(g,"Combo","perf_mode","Частота обновлений",{"Баланс","Быстрый отклик","Экономия CPU","RAGE · повышенная частота"})
    UI.add(g,"Switch","debug_log","Диагностика в консоль")
    UI.add(g,"Switch","stable_trace","Трассировка фарма")
    local tips={camp_filter="При включении карта определяет допуск кемпа вместо геометрической области. Угрозы, мана, древние и занятость союзником проверяются отдельно.",
        work_preset="Сохраняет прежние настройки. Возврат в пользовательский профиль восстанавливает их. Фарм и комбо сами не запускаются; выбор кемпов и списки героев не меняются.",escape_key="Запускает отход всех Мипо. Обычная автоматика заблокирована до F9; выживание не гарантируется.",
        resume_key="Отменяет дальнейшие автоматические действия отхода. Уже начатый TP / Dig не прерывается. Фарм включается отдельно.",
        combo_poof="Управляет и стартовым сбором, и дальнейшей очередью Poof.",
        manual_mode="При индивидуальном режиме затронутый Мипо временно исключён; остальные продолжают бой.",
        net_plan_steps="Прогноз по текущей позиции, мане и перезарядке. Резерв запрещает Poof и несвоевременные предметы.",
        target_lock="Цель не меняется, пока доступна; игнорируемые герои исключены из выбора.",
        gather_mode="Сбор выполняется после выбора цели, уважает участников и ручную паузу. Приоритет следующей сетки выше сбора.",
        perf_mode="Ограничивает частоту сканирования, планирования и HUD, но не является гарантией FPS."}
    for key,text in pairs(tips) do A.method(UI[key],"ToolTip",text) end
end

function UI.down(key)
    local w=UI[key]
    local first,second=A.method(w,"Buttons")
    if first==nil then first=UI.get(key) end
    local none=A.enum("ButtonCode","KEY_NONE")
    local invalid=A.enum("ButtonCode","BUTTON_CODE_INVALID")
    if type(first)=="number" and first~=none and first~=invalid and Input and type(Input.IsKeyDown)=="function" then
        local a=A.call(Input.IsKeyDown,first,true)
        if a~=nil then
            if type(second)=="number" and second~=none and second~=invalid then
                return a==true and A.call(Input.IsKeyDown,second,true)==true
            end
            return a==true
        end
    end
    return A.method(w,"IsDown")==true
end
function UI.input_captured()
    return A.call(Input and Input.IsInputCaptured)==true or A.call(Input and Input.IsPopupOpen)==true
        or A.call(Menu and Menu.Opened)==true
end
function UI.poll_keys(captured)
    -- До кадрового/логического ограничителя: отпускание нельзя пропустить на паузе.
    -- Захваченные клавиши отслеживаются физически, но не запускают действия после закрытия чата.
    for _,key in ipairs({"farm_key","poof_cursor_key","poof_self_key","escape_key","resume_key","camp_map_key"}) do
        local down=UI.down(key)
        local was=S.key_prev[key]==true
        S.key_prev[key]=down
        if captured then S.key_pending[key]=nil
        elseif down and not was then S.key_pending[key]=true end
    end
end
function UI.pressed(key)
    local pressed=S.key_pending[key]==true
    S.key_pending[key]=nil
    return pressed
end
function M.collect(now)
    if now<(S.next_collect or -math.huge) then return end
    S.next_collect=now+Perf.interval("collect")
    local list = A.call(Heroes and Heroes.GetAll)
    S.heroes_valid = type(list) == "table"
    S.heroes = S.heroes_valid and list or {}
    S.metrics.hero_scans = S.metrics.hero_scans + 1
    local units, ids = {}, {}
    local pid = S.player and A.call(Player and Player.GetPlayerID,S.player)
    local function add(u)
        if not A.alive(u) or A.name(u) ~= "npc_dota_hero_meepo" or A.team(u) ~= S.team
            or A.call(NPC.IsIllusion,u) == true then return end
        if u ~= S.hero then
            local owner = A.call(NPC.GetOwnerNPC,u)
            local controllable = pid and pid >= 0 and A.call(NPC.IsControllableByPlayer,u,pid)
            if controllable == false then return end
            -- Missing controllability metadata is not permission to command an allied Meepo.
            if controllable~=true and (not owner or A.id(owner)~=A.id(S.hero)) then return end
            if owner and A.name(owner) == "npc_dota_hero_meepo" and A.id(owner) ~= A.id(S.hero) then return end
        end
        local id = A.id(u)
        if id and not ids[id] then units[#units+1] = u; ids[id] = true end
    end
    add(S.hero)
    for _, u in ipairs(S.heroes) do add(u) end
    table.sort(units,function(a,b)
        if a == S.hero then return b ~= S.hero end
        if b == S.hero then return false end
        return tostring(A.id(a)) < tostring(A.id(b))
    end)
    S.units, S.unit_ids = units, ids
    Roles.refresh()
    for id in pairs(S.locks) do if not ids[id] then S.locks[id] = nil end end
    for _, name in ipairs({"assignment","healing","manual_until","orders","hp_samples"}) do
        for id in pairs(S[name]) do if not ids[id] then S[name][id] = nil end end
    end
    for _,enemy in ipairs(S.heroes) do

        if A.enemy(enemy) then
            local id,pos=A.id(enemy),A.pos(enemy)
            if A.valid_position(pos) then
                S.enemy_memory[id]={pos=A.copy(pos),time=now}
                local old=S.motion[id];local rec={unit=enemy,pos=A.copy(pos),time=now}
                local dt=old and now-old.time or 0
                if old and old.unit==enemy and dt>=.025 and dt<=.4 then
                    local dx,dy=pos.x-old.pos.x,pos.y-old.pos.y
                    local speed=math.max(1,A.number(A.call(NPC.GetMoveSpeed,enemy),300))
                    if dx*dx+dy*dy<=(speed*dt*1.8+24)^2 then
                        local vx,vy=dx/dt,dy/dt
                        local length=math.sqrt(vx*vx+vy*vy)
                        if length>speed and length>0 then vx,vy=vx*speed/length,vy*speed/length end
                        rec.vx,rec.vy=vx,vy
                    end
                end
                S.motion[id]=rec
            end
        end
    end

    for id,rec in pairs(S.enemy_memory) do if now-rec.time>35 then S.enemy_memory[id]=nil end end
    for id,rec in pairs(S.motion) do if now-rec.time>.5 then S.motion[id]=nil end end
    if now>=(S.next_prune or -math.huge) then
        S.next_prune=now+5
        for key,t in pairs(S.econ_blacklist) do if now>=t then S.econ_blacklist[key]=nil end end
        for key,t in pairs(S.rune_retry) do if now>=t then S.rune_retry[key]=nil end end
        for key,t in pairs(S.spell_next) do if now>t+10 then S.spell_next[key]=nil end end
        for key,t in pairs(S.econ_retry_time) do
            if now-t>90 then S.econ_retry_time[key],S.econ_retries[key]=nil,nil end
        end
        for _,name in ipairs({"order_next","inventory_cache","item_next"}) do
            for id in pairs(S[name]) do if not ids[id] then S[name][id]=nil end end
        end
    end
    S.selected = {}
    for _,u in ipairs(A.call(Player and Player.GetSelectedUnits,S.player) or {}) do S.selected[A.id(u)] = true end
end
function Orders.busy(u,priority,now)
    local id=A.id(u)
    if S.acted[id] or A.manual(u,now) then return true end
    if priority<100 and priority~=80 and now<(S.order_next[id] or -math.huge) then return true end
    local lock=S.locks[id]
    if lock then
        local phase=A.call(Ability.IsInAbilityPhase,lock.ability)==true or A.call(Ability.IsChannelling,lock.ability)==true
        if phase then lock.observed=true;return true end
        local name=A.call(Ability.GetName,lock.ability)
        if (name=="item_tpscroll" or name=="meepo_petrify") and now<(lock.ack_until or lock.until_time) then return true end
        local cooldown=A.call(Ability.GetCooldown,lock.ability)
        local spent=type(cooldown)=="number" and cooldown>.05
        local unconfirmed=not spent and not lock.observed and now>=(lock.ack_until or lock.until_time)
        if unconfirmed or now>=lock.until_time or (lock.observed and now>lock.sent+.12) then
            S.locks[id]=nil
            if unconfirmed then Trace.add(u,"Нет подтверждения",lock.tag,true);S.metrics.unconfirmed_casts=(S.metrics.unconfirmed_casts or 0)+1 end
        elseif priority<=lock.priority then return true end
    end
    local channel=A.call(NPC.GetChannellingAbility,u)
    if channel and A.call(Ability.IsChannelling,channel)==true then return true end
    for _,name in ipairs({"meepo_poof","meepo_petrify","item_tpscroll"}) do
        local ab=name=="item_tpscroll" and A.call(NPC.GetItem,u,name,false) or A.spell(u,name)
        if ab and (A.call(Ability.IsInAbilityPhase,ab)==true or A.call(Ability.IsChannelling,ab)==true) then return true end
    end
    return A.has(u,"modifier_meepo_petrify") or A.state(u,"MODIFIER_STATE_OUT_OF_GAME")
end

function Orders.issue(u, kind, target, pos, ability, priority, tag, duration, item)
    local now, id = S.now or A.now(), A.id(u)
    if (not UI.get("enabled") and not (priority>=120 and S.escape.active)) or not S.player or not A.alive(u) or not S.unit_ids[id] then return false end
    if S.escape.latched and priority<120 then return false end
    if Roles.get(u)==5 and priority<120 and tag~="карта-отмена-задания" then return false end
    if CampMap.state().open and priority<100 then return false end
    if S.camp_cancel and S.camp_cancel[id] and priority<100 then return false end
    if pos and not A.valid_position(pos) then S.last_error="Некорректная позиция приказа";return false end
    if Orders.busy(u,priority,now) then
        if ability then Trace.add(u,tag,"Ручная пауза / применение / лимит приказов",true) end
        return false
    end
    if ability then
        local ready, reason = A.ready(u,ability,item)
        if not ready then S.failures[id]=reason;Trace.add(u,tag,reason,true);return false end
        local owner = A.call(Ability.GetOwner,ability)
        if owner and A.id(owner) ~= id then S.failures[id] = "Чужая способность"; return false end
        local key = tostring(id)..":"..tostring(A.call(Ability.GetName,ability) or ability)
        if now < (S.spell_next[key] or -math.huge) then return false end
    end
    local tree_target = target and item and
        (A.call(Ability.GetName,ability)=="item_tango" or A.call(Ability.GetName,ability)=="item_tango_single")
        and A.call(Tree and Tree.IsActive,target)==true
    local rune_target = target and kind=="DOTA_UNIT_ORDER_PICKUP_RUNE"
        and A.call(Runes and Runes.Contains,target)==true
    if target and not tree_target and not rune_target and not A.alive(target) then return false end
    local order = A.enum("UnitOrder",kind)
    local issuer = A.enum("PlayerOrderIssuer","DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY")
    if not order or issuer == nil or not Player or type(Player.PrepareUnitOrders) ~= "function" then
        S.last_error = "Отправка одиночных приказов недоступна"; return false
    end
    -- The documented identifier distinguishes this script from human orders.
    -- The issuing flag is only a synchronous re-entrancy guard.
    S.issuing=(S.issuing or 0)+1
    local ok,result = pcall(Player.PrepareUnitOrders,S.player,order,target,pos or A.pos(u) or A.vec(),
        ability,issuer,u,false,false,true,false,M.ORDER_PREFIX..tag,false)
    S.issuing=S.issuing-1
    if not ok or result == false then
        S.metrics.failures = S.metrics.failures+1
        S.last_error = not ok and ("Ошибка приказа: "..tostring(result)) or "Игровой интерфейс отклонил приказ"
        A.log(S.last_error,true)
        return false
    end
    -- Любой принятый приказ заменяет предыдущий, не только способность.
    -- Иначе, например, подбор руны оставляет фиктивную «атаку» в кеше.
    S.orders[id],S.attack_commit[id] = nil,nil
    S.acted[id] = true
    S.order_next[id]=now+(Preset.rage() and .055 or .10)
    S.metrics.orders = S.metrics.orders+1
    Trace.add(u,tag,"Приказ отправлен")
    S.failures[id] = nil
    if priority<=45 then Stable.trace(u,tag,target,pos) end
    if ability then
        local key = tostring(id)..":"..tostring(A.call(Ability.GetName,ability) or ability)
        -- Failed/unacknowledged casts must not be retried every few frames.
        S.spell_next[key] = now + (A.call(Ability.GetName,ability)=="meepo_earthbind" and .75 or .45)
        local turn=math.max(0,math.min(.65,A.number(A.call(NPC.GetTimeToFacePosition,u,
            pos or (target and A.pos(target)) or A.pos(u)),0)))
        local hold=math.max(.12,duration or .15)
        S.locks[id] = {ability=ability,priority=priority,sent=now,target=target,pos=pos,
            ack_until=now+math.min(hold,turn+.38),until_time=now+hold,tag=tag}
    end
    return true
end
function Orders.cast(u, ab, target, pos, priority, tag, duration, item)
    local kind = pos and "DOTA_UNIT_ORDER_CAST_POSITION"
        or target and "DOTA_UNIT_ORDER_CAST_TARGET" or "DOTA_UNIT_ORDER_CAST_NO_TARGET"
    return Orders.issue(u,kind,target,pos,ab,priority,tag,duration,item)
end
function Orders.walk(u,pos,priority,tag)
    if not pos then return false end
    local now,id=S.now,A.id(u);local last=S.orders[id]
    if last and last.kind=="move" and A.distance2(last.pos,pos)<120*120 then
        local distance=A.distance(A.pos(u),pos)
        if distance<85 then return false end
        if now-last.time<.7 then return false end
        if A.call(NPC.IsRunning,u)==true and now-last.time<3 then return false end
    end
    if Orders.issue(u,"DOTA_UNIT_ORDER_MOVE_TO_POSITION",nil,pos,nil,priority,tag) then
        S.orders[id]={kind="move",time=now,pos=A.copy(pos),tag=tag};return true
    end
    return false
end
function Orders.attack(u,target,priority,tag)
    if not A.alive(target) or A.state(target,"MODIFIER_STATE_ATTACK_IMMUNE")
        or A.state(target,"MODIFIER_STATE_INVULNERABLE") or A.state(target,"MODIFIER_STATE_OUT_OF_GAME") then return false end
    local now,id=S.now,A.id(u);local last=S.orders[id]
    local attack_time=math.max(.15,A.number(A.call(NPC.GetAttackTime,u),1.1))
    local distance=A.distance(A.pos(u),A.pos(target))
    local hit=A.number(A.call(NPC.GetLastAttackTime,u),-math.huge)
    if last and last.kind=="attack" and last.target==target then
        -- IsRunning/IsAttacking can remain true for a blocked or replaced order.
        -- Only our approach or an own attack advances this watchdog; ally damage does not.
        if (last.distance and distance<last.distance-32) or hit>(last.last_hit or -math.huge) then
            last.progress,last.distance,last.last_hit=now,distance,hit
        end
        if now-last.time<math.max(.65,attack_time+.1)
            or now-(last.progress or last.time)<math.max(1.5,attack_time*1.75) then return false end
    end
    if Orders.issue(u,"DOTA_UNIT_ORDER_ATTACK_TARGET",target,A.pos(target),nil,priority,tag) then
        S.orders[id]={kind="attack",time=now,target=target,progress=now,distance=distance,last_hit=hit}
        S.attack_commit[id]=now+math.min(.9,math.max(.22,A.number(A.call(NPC.GetAttackAnimPoint,u),.35)+.08))
        return true
    end
    return false
end

function Combat.units()
    local result={}
    for _,u in ipairs(S.units) do
        if (UI.get("combo_all") or S.selected[A.id(u)]) and A.alive(u) and not A.manual(u) and Roles.get(u)~=5 then result[#result+1]=u end
    end
    return result
end

function Combat.release(reason)
    S.target,S.net_pending,S.hex_pending,S.last_net=nil,nil,nil,nil
    S.net_status,S.poof_status=nil,nil
    S.net_plan=nil;S.net_plan_next=-math.huge
    if reason then S.combo_status=reason end
end

function Combat.target_valid(u)
    if not A.enemy(u) or UI.target_rank(u)==0 or A.state(u,"MODIFIER_STATE_INVULNERABLE")
        or A.state(u,"MODIFIER_STATE_OUT_OF_GAME") then return false end
    for _,meepo in ipairs(S.units) do
        if not A.manual(meepo) and (UI.get("combo_all") or (S.selected or {})[A.id(meepo)])
            and A.distance2(A.pos(u),A.pos(meepo))<4000*4000 then return true end
    end
    return false
end

function Combat.pick_target()
    if UI.get("target_lock") and Combat.target_valid(S.target) then return S.target end
    local cx,cy=A.call(Input and Input.GetCursorPos)
    local world=A.call(Input and Input.GetWorldCursorPos)
    local best,rank,distance=nil,-1,math.huge
    for _,u in ipairs(S.heroes) do
        if Combat.target_valid(u) then
            local pos=A.pos(u);local d=nil
            if A.valid_position(pos) then
                local screen,on_screen=A.call(Render and Render.WorldToScreen,pos)
                if type(cx)=="number" and type(cy)=="number" and screen and on_screen then
                    local squared=(screen.x-cx)^2+(screen.y-cy)^2
                    if squared<=UI.get("combo_radius")^2 then d=squared/math.max(1,UI.get("combo_radius")^2) end
                elseif A.valid_position(world) then
                    local squared=A.distance2(world,pos)
                    if squared<=UI.get("combo_world_radius")^2 then d=squared/math.max(1,UI.get("combo_world_radius")^2) end
                end
            end
            local r=UI.get("target_policy")==0 and UI.target_rank(u) or 1
            if d and (r>rank or (r==rank and (d<distance or (d==distance and tostring(A.id(u))<tostring(A.id(best)))))) then
                best,rank,distance=u,r,d
            end
        end
    end
    return best
end

function Combat.predict(target,horizon)
    local pos=A.pos(target)
    if not A.valid_position(pos) then return nil end
    horizon=math.max(0,math.min(1.6,A.number(horizon,0)))
    local controlled=A.control_remaining(target,S.now)
    local moving_time=math.max(0,horizon-controlled)
    if moving_time<=0 then return pos end
    local running=A.call(NPC.IsRunning,target)==true
    if not running and controlled<=.05 then return pos end
    local speed=math.max(0,A.number(A.call(NPC.GetMoveSpeed,target),0))
    local vx,vy=nil,nil
    local motion=S.motion[A.id(target)]
    if running and motion and motion.unit==target and S.now-motion.time<=.25
        and motion.vx and motion.vx^2+motion.vy^2>speed^2*.04 then vx,vy=motion.vx,motion.vy end
    if not vx then
        local rot=A.call(Entity.GetRotation,target)
        local forward=rot and A.method(rot,"GetForward")
        if not forward then return pos end
        local length=math.sqrt(forward.x^2+forward.y^2)
        if length<.01 then return pos end
        vx,vy=forward.x/length*speed,forward.y/length*speed
    end
    local dx,dy=vx*moving_time,vy*moving_time
    local length=math.sqrt(dx*dx+dy*dy)
    if length>600 then dx,dy=dx*600/length,dy*600/length end
    return A.vec(pos.x+dx,pos.y+dy,pos.z)
end
function Combat.net_candidate(units,target,exclude)
    if not Combat.target_valid(target) then return nil,"Цель недоступна" end
    local best,score,reason=nil,math.huge,"Сетки не готовы"
    for _,u in ipairs(units) do
        if u~=exclude and not Orders.busy(u,60,S.now) then
            local net=A.spell(u,"meepo_earthbind")
            local ready,why=A.ready(u,net,false)
            if ready then
                local origin=A.pos(u)
                local speed=math.max(1,A.net_speed(net))
                local cast=math.max(0,A.number(A.call(Ability.GetCastPoint,net,true),.3))
                local eta=cast+A.distance(origin,A.pos(target))/speed
                local point,turn
                for _=1,3 do
                    point=Combat.predict(target,eta)
                    if not A.valid_position(point) then break end
                    turn=math.max(0,math.min(.65,A.number(A.call(NPC.GetTimeToFacePosition,u,point),0)))
                    eta=turn+cast+A.distance(origin,point)/speed
                end
                if A.valid_position(point) and A.distance(origin,point)<=A.range(u,net,700) then
                    local penalty=S.last_net and S.last_net.unit==u and .30 or 0
                    if eta+penalty<score then
                        best={unit=u,ability=net,pos=point,eta=eta,cast=cast,turn=turn or 0};score=eta+penalty
                    end
                else reason="Прогноз вне дальности сетки" end
            else reason=why end
        end
    end
    return best,reason
end
function Combat.pending_net(target)
    local p = S.net_pending
    if not p then return false end
    if not A.alive(p.unit) or not Combat.target_valid(p.target) then S.net_pending=nil;return false end
    local remaining=A.root_remaining(p.target,S.now)
    local observed_until=S.now+remaining
    -- Clock advancement alone is not a root. Require a positive modifier and an extension.
    if remaining>.025 and observed_until>(p.baseline_until or S.now)+0.10 and S.now>=p.arrival-0.10 then
        S.net_misses[A.id(p.target)]=nil;S.net_retry_until[A.id(p.target)]=nil
        S.net_pending=nil;return false
    end
    if S.now > p.arrival+0.45 then
        local id=A.id(p.target)
        S.net_misses[id]=math.min(4,(S.net_misses[id] or 0)+1)
        S.net_retry_until[id]=S.now+math.min(.8,.2*S.net_misses[id])
        S.net_pending=nil
        S.combo_status="Попадание сетки не подтверждено — повторный выбор"
        return false
    end
    return p.target == target
end
function Combat.net(units,target)
    if not UI.get("combo_net") then S.net_status="Выключено";return false end
    if not Combat.target_valid(target) then S.net_status="Нет допустимой цели";return false end
    if S.now<(S.net_retry_until[A.id(target)] or -math.huge) then S.net_status="Пауза после неподтверждённой сетки";return false end
    if S.hex_pending and S.hex_pending.target==target and S.now<S.hex_pending.until_time then S.net_status="Ожидаем Hex";return false end
    if Combat.pending_net(target) then S.net_status="Сетка в полёте · ожидаем модификатор";return false end
    local plan=NetPlan.update(units,target)
    local step=plan.steps[1]
    if not step then S.net_status=plan.status;return false end
    if S.now+.02<step.launch then S.net_status=string.format("Мипо %s: сетка через %.1f с",A.id(step.unit),step.launch-S.now);return false end
    local candidate,why=Combat.net_candidate({step.unit},target)
    if not candidate then S.net_status=why;NetPlan.invalidate();return false end
    local remaining=A.control_remaining(target,S.now)
    if remaining>candidate.eta+UI.get("net_overlap_ms")/1000+.04 then NetPlan.invalidate();return false end
    if Orders.cast(candidate.unit,candidate.ability,nil,candidate.pos,65,"сетка",candidate.turn+candidate.cast+.16,false) then
        S.last_net={unit=candidate.unit,target=target,sent=S.now}
        S.net_pending={unit=candidate.unit,ability=candidate.ability,target=target,sent=S.now,arrival=S.now+candidate.eta,
            baseline_until=S.now+A.root_remaining(target,S.now)}
        S.metrics.nets=S.metrics.nets+1;NetPlan.invalidate()
        S.net_status=string.format("Мипо %s: сетка отправлена",A.id(candidate.unit));return true
    end
    Trace.add(step.unit,"Сетка",S.failures[A.id(step.unit)] or "Кастер занят",true)
    S.net_status="Сетка отложена: кастер занят";NetPlan.invalidate();return false
end

function Combat.poof_anchor(units,target)
    local best,dist=nil,math.huge
    local point=A.pos(target)
    for _,u in ipairs(units) do
        if A.visible(u) and not A.has(u,"modifier_meepo_petrify") and not A.state(u,"MODIFIER_STATE_OUT_OF_GAME") then
            local d=A.distance(A.pos(u),point)
            if d<dist then best,dist=u,d end
        end
    end
    return best,dist
end
function Combat.blink(units,target)
    if not UI.get("combo_blink") then return false end
    local hero=S.hero
    local included=false
    for _,u in ipairs(units) do if u==hero then included=true end end
    if not included or Orders.busy(hero,60,S.now) then return false end
    local target_pos,origin=A.pos(target),A.pos(hero)
    local distance=A.distance(origin,target_pos)
    if distance<460 then return false end
    for _,name in ipairs({"item_blink","item_overwhelming_blink","item_arcane_blink","item_swift_blink"}) do
        local item=A.item(hero,name)
        if item and A.ready(hero,item,true) then
            local range=A.range(hero,item,1200)
            if distance<=range+160 then
                local ratio=math.max(0,math.min(range,distance-150)/distance)
                local point=A.vec(origin.x+(target_pos.x-origin.x)*ratio,origin.y+(target_pos.y-origin.y)*ratio,target_pos.z)
                return Orders.cast(hero,item,nil,point,60,"блинк",0.18,true)
            end
        end
    end
    return false
end
function Combat.tick(provided_units,provided_target)
    local units=provided_units or Combat.units()
    if #units==0 then S.combo_status="Все участники под ручным управлением";return end
    local target=provided_target or Combat.pick_target()
    if not Combat.target_valid(target) then Combat.release("Нет цели в радиусе курсора");return end
    if S.target~=target then Combat.release();S.target=target end
    NetPlan.update(units,target)
    -- Attempt order is deliberate; this is a feedback-driven scheduler, not fixed sleeps.
    Items.tick(units,target,"survival")
    local hex=Combat.hex(units,target)
    local blink=Combat.blink(units,target)
    local net=Combat.net(units,target)
    local gather=Combat.opening_gather(units,target)
    local poof=Combat.poof(units,target)
    Items.tick(units,target,"regular")
    for _,u in ipairs(units) do if not Orders.busy(u,60,S.now) then Orders.attack(u,target,60,"атака-комбо") end end
    S.combo_status=gather and "Сбор группы" or poof and "Последовательный Poof" or net and "Цепочка сеток"
        or blink and "Сближение" or hex and "Hex · продолжение по наблюдениям" or "Цель зафиксирована · атака"
end

function M.utility()
    local cursor=UI.pressed("poof_cursor_key")
    local self_cast=UI.pressed("poof_self_key")
    if not cursor and not self_cast then return false end
    local anchor=nil
    if cursor then
        local point=A.call(Input.GetWorldCursorPos)
        local best=math.huge
        for _,u in ipairs(S.units) do
            local d=A.distance2(A.pos(u),point)
            if d<best then anchor,best=u,d end
        end
    end
    local sent=false
    for _,u in ipairs(Combat.units()) do
        local destination=self_cast and u or anchor
        if destination then
            local ab=A.spell(u,"meepo_poof")
            if ab and A.ready(u,ab,false) and Orders.cast(u,ab,destination,nil,80,"пуф-клавиша",A.poof_time(ab)+0.2,false) then
                S.metrics.poofs=S.metrics.poofs+1;sent=true
            end
        end
    end
    return sent
end

-- Автофарм: один снимок нейтралов, распределение лагерей, лечение и ручной приоритет.
function Farm.clock()
    local start=A.number(A.call(GameRules.GetGameStartTime),0)
    return S.now-start
end
function Farm.spawn_deadline()
    local clock=Farm.clock()
    local wait=clock<0 and 60-clock or 60-clock%60
    return S.now+wait+0.4
end
function Farm.refresh_camps()
    if S.now<(S.camps_next or -math.huge) then return end
    local list=A.call(Camps and Camps.GetAll)
    if type(list)~="table" or #list==0 then
        S.camps_next=S.now+1 -- transient API failure is not an empty map or permission reset.
        return
    end
    local camps,seen={},{}
    for _,raw in ipairs(list) do
        local box=A.call(Camp and Camp.GetCampBox,raw)
        local pos
        if box and A.valid_position(box.min) and A.valid_position(box.max) then
            pos=A.vec((box.min.x+box.max.x)/2,(box.min.y+box.max.y)/2,(box.min.z+box.max.z)/2)
        end
        if A.valid_position(pos) then
            local key=CampMap.key(pos,box)
            if not seen[key] then
                seen[key]=true;camps[#camps+1]={id="camp:"..key,map_key=key,raw=raw,pos=pos,box=box}
            end
        end
    end
    if #camps==0 then S.camps_next=S.now+1;return end
    table.sort(camps,function(a,b)return a.pos.y==b.pos.y and a.pos.x<b.pos.x or a.pos.y>b.pos.y end)
    S.camps_next=S.now+8
    S.camps=camps;S.camps_version=(S.camps_version or 0)+1
    CampMap.invalidate()
end
function Farm.nearby(pos,radius)
    local out={}
    if not pos then return out end
    local cell=760
    for x=math.floor((pos.x-radius)/cell),math.floor((pos.x+radius)/cell) do
        for y=math.floor((pos.y-radius)/cell),math.floor((pos.y+radius)/cell) do
            for _,rec in ipairs((S.neutral_bins or {})[x..":"..y] or {}) do
                if A.visible(rec.unit) and A.distance2(rec.pos,pos)<=radius*radius then out[#out+1]=rec.unit end
            end
        end
    end
    return out
end
function Farm.own_side(camp)
    if camp and not camp.map_key then return UI.get("farm_side")==1 or CampMap.own(camp) end
    return CampMap.allowed(camp)
end
function Farm.available(camp,unit)
    if not camp or not Farm.own_side(camp) or not Roles.camp_allowed(unit,camp) then return false end
    local stack=S.stack_camps[camp.id]
    if stack and stack.unit~=unit then return false end
    -- Заявка после подтверждённого стака принадлежит одному Мипо; остальные этот кемп не берут.
    local claim=S.stack_claims[camp.id]
    local claimed=claim~=nil and unit~=nil and claim.id==A.id(unit)
    if claim and not claimed then return false end
    -- Кемп, который уже фармит союзник, не выбираем (если мы сами уже не в бою на нём).
    if Farm.ally_busy(camp) and not Farm.engaged_here(unit,camp) then return false end
    if unit and not claimed and S.now<(S.econ_blacklist[tostring(A.id(unit))..":лагерь:"..tostring(camp.id)] or 0) then return false end
    local neutrals=Farm.nearby(camp.pos,760)
    if #neutrals>0 then S.camp_empty[camp.id]=nil end
    -- Для заявки старые флаги «пусто» устарели: после стака в кемпе новая пачка, даже если она в тумане.
    if not claimed and S.now<(S.camp_empty[camp.id] or -math.huge) then return false end
    if UI.get("farm_avoid_enemies") and A.enemy_count_at(camp.pos,1300)>0 then return false end
    local known=not claimed and A.call(Camp and Camp.IsKnownClear,camp.raw)
    if known==true and #neutrals==0 then
        local learned=S.camp_knowledge[camp.id]
        if not learned then
            learned={until_time=Farm.spawn_deadline()};S.camp_knowledge[camp.id]=learned
        end
        if S.now<learned.until_time then
            S.camp_empty[camp.id]=learned.until_time;return false
        end
        -- После нового спавна старый флаг IsKnownClear в тумане не доказывает пустоту.
    else S.camp_knowledge[camp.id]=nil end
    for _,n in ipairs(neutrals) do
        if A.call(NPC.IsAncient,n)==true and (not UI.get("econ_enabled") or not UI.get("econ_ancients") or not Econ.ancient_safe(unit,neutrals)) then return false end
    end
    return true
end
function Farm.fountain()
    return A.valid_position(S.fountain) and S.fountain or nil
end

-- ===== Кемпы союзников =====
function Farm.in_camp(pos,camp,margin)
    local box=camp.box
    if box and box.min and box.max then
        return pos.x>=box.min.x-margin and pos.x<=box.max.x+margin and pos.y>=box.min.y-margin and pos.y<=box.max.y+margin
    end
    return A.distance(pos,camp.pos)<=500+margin
end
-- Союзник фармит кемп: стоит/бьёт внутри кемпа и рядом есть видимые нейтралы. Пробегающий мимо (бежит, не бьёт) не считается.
function Farm.scan_allies()
    if not S.heroes_valid then return end
    local mode=UI.get("farm_mode")
    for _,hero in ipairs(S.heroes) do
        local id=A.id(hero)
        local foreign=not S.unit_ids[id] or (hero==S.hero and mode==0) or (mode==2 and S.selected[id])
        if foreign and A.visible(hero) and A.team(hero)==S.team and A.call(NPC.IsIllusion,hero)~=true
            and A.call(Entity.IsHero,hero)==true then
            local pos=A.pos(hero)
            local attacking=A.call(NPC.IsAttacking,hero)==true
            if pos and (attacking or A.call(NPC.IsRunning,hero)~=true) then
                for _,camp in ipairs(S.camps) do
                    if Farm.in_camp(pos,camp,120) and #Farm.nearby(pos,600)>0 then
                        S.ally_camp[camp.id]={time=S.now,id=id};break
                    end
                end
            end
        end
    end
end
function Farm.ally_busy(camp)
    local rec=camp and S.ally_camp[camp.id]
    return rec~=nil and S.now-rec.time<2.5
end
-- Наш Мипо уже в контакте с нейтралами этого кемпа: союзник, пришедший позже, его не вытесняет.
function Farm.engaged_here(u,camp)
    local rec=u and S.assignment[A.id(u)]
    return rec~=nil and rec.kind=="neutral" and rec.camp==camp.id and rec.contact_at~=nil and S.now-rec.contact_at<8
end

-- ===== Возврат на кемп после стака =====
function Farm.claim_task(u)
    local claim=Stack.claim_for(u)
    if not claim then return nil end
    local camp=Farm.find_camp(claim.camp)
    if not camp or not Farm.own_side(camp) or not Roles.camp_allowed(u,camp) or Farm.under_tower(camp.pos)
        or (UI.get("farm_avoid_enemies") and A.enemy_count_at(camp.pos,1300)>0) then return nil end
    if Farm.ally_busy(camp) then S.stack_claims[claim.camp]=nil;return nil end
    return {kind="neutral",key="лагерь:"..tostring(camp.id),camp=camp,pos=camp.pos}
end

-- ===== Poof в фарме: только с реальной пользой =====
function Farm.poof_targets(u,creeps,poof,record)
    local id=A.id(u)
    local block=S.poof_block[id]
    if block and S.now<block.until_time then return nil end
    if S.stack_units[id] then return nil end
    local result=S.stack_results[id]
    if result and S.now-result.time<10 and record and record.kind=="neutral" then
        local camp=Farm.find_camp(record.camp)
        if not camp or A.distance(A.pos(u),camp.pos)>500 then return nil end
    end
    local radius=A.poof_radius(poof)-35
    local mine=A.pos(u);local list={}
    for _,c in ipairs(creeps) do
        if A.visible(c) then
            local d=A.distance(mine,A.pos(c))
            -- Бегущие дальше от нас нейтралы (отвод после стака) к моменту урона из радиуса уйдут.
            if d<=radius and (d<=radius*.6 or A.call(NPC.IsRunning,c)~=true) then list[#list+1]=c end
        end
    end
    return list
end
function Farm.poof_watch(u,list,poof)
    local hp=0
    for _,c in ipairs(list) do hp=hp+A.number(A.call(Entity.GetHealth,c),0) end
    S.poof_watch[A.id(u)]={check=S.now+A.poof_time(poof)+.12,list=list,hp=hp,ability=poof}
end
-- Если после Poof здоровье тех же нейтралов не изменилось, Poof ушёл «в пустоту»: временно запрещаем фарм-Poof.
function Farm.poof_audit()
    for id,w in pairs(S.poof_watch) do
        if S.now>=w.check then
            S.poof_watch[id]=nil
            local hp,known=0,true
            for _,c in ipairs(w.list) do
                if A.alive(c) then
                    if not A.visible(c) then known=false end
                    hp=hp+A.number(A.call(Entity.GetHealth,c),0)
                end
            end
            local spent=w.ability and A.number(A.call(Ability.GetCooldown,w.ability),0)>.1
            if known and spent and hp>=w.hp-1 then
                local strikes=(S.poof_block[id] and S.poof_block[id].strikes or 0)+1
                S.poof_block[id]={until_time=S.now+(strikes>=3 and 6 or 0),strikes=math.min(3,strikes)}
            elseif known and hp<w.hp-1 then S.poof_block[id]=nil end
        end
    end
end
function M.context()
    if A.call(Engine and Engine.IsInGame)~=true then
        if S.session then M.reset() end
        return false
    end
    local hero=A.call(Heroes and Heroes.GetLocal)
    if not hero or A.name(hero)~="npc_dota_hero_meepo" then
        if S.session then M.reset() end
        return false
    end
    local now=A.now()
    local match=A.call(GameRules and GameRules.GetMatchID)
    if not S.session or S.hero~=hero or (S.last_now and now<S.last_now-0.1)
        or (match and match>0 and S.match and S.match>0 and match~=S.match) then M.reset() end
    S.session,S.hero,S.player,S.team,S.now,S.last_now,S.match=true,hero,A.call(Players and Players.GetLocal),A.team(hero),now,now,match
    return true
end
function M.logic()
    if not M.context() then return end
    local captured=UI.input_captured()
    UI.poll_keys(captured)
    if UI.pressed("camp_map_key") then CampMap.toggle() end
    if UI.pressed("escape_key") then Emergency.begin() end
    if UI.pressed("resume_key") then Emergency.resume() end
    local down=UI.down("combo_key")
    if CampMap.state().open then
        S.combo_blocked=down;S.combo_edge_pending=nil
    end
    local edge=down and not S.combo_was_down
    if edge then S.combo_edge_pending=true end
    local released=not down and S.combo_was_down
    S.combo_was_down=down
    if released then Combat.release();S.combo_edge_pending=nil;S.combo_blocked=false;S.combo_active=false end
    local frame=A.call(GlobalVars and GlobalVars.GetFrameCount)
    if frame and frame==S.last_frame then return end
    S.last_frame=frame
    if S.now<(S.next_logic or -math.huge) then return end
    S.next_logic=S.now+Perf.interval("logic")
    S.acted={};S.safety_status=nil
    M.collect(S.now);World.scan()
    if CampMap.state().open then Farm.refresh_camps() end
    if S.escape.latched then
        S.key_pending.farm_key,S.key_pending.poof_cursor_key,S.key_pending.poof_self_key=nil,nil,nil
        S.combo_edge_pending=nil
        S.combo_active=false
        if S.escape.active and A.call(GameRules and GameRules.IsPaused)~=true then Emergency.tick() end
        return
    end
    if CampMap.state().open then
        S.key_pending.farm_key,S.key_pending.poof_cursor_key,S.key_pending.poof_self_key=nil,nil,nil
        S.combo_active=false;S.combo_edge_pending=nil
        if UI.get("enabled") and not captured and A.call(GameRules and GameRules.IsPaused)~=true then
            M.safety();CampMap.cancel_tick()
        end
        S.combo_status="Выбор кемпов · обычная автоматика на паузе"
        return
    end
    if not UI.get("enabled") or captured or A.call(GameRules and GameRules.IsPaused)==true then
        S.combo_active=false;S.combo_blocked=down;S.combo_edge_pending=nil
        S.key_pending.farm_key,S.key_pending.poof_cursor_key,S.key_pending.poof_self_key=nil,nil,nil
        S.combo_status=not UI.get("enabled") and "Выключен" or captured and "Ввод занят" or "Игра на паузе"
        return
    end
    if UI.pressed("farm_key") then UI.set("farm_enabled",not UI.get("farm_enabled")) end
    edge=S.combo_edge_pending==true;S.combo_edge_pending=nil
    if edge then
        S.combo_press=(S.combo_press or 0)+1;S.combo_blocked=false;S.gather=nil
        Combat.release()
        -- New Space press must NOT erase an individual manual override.
        S.camp_cancel={}
    end
    S.combo_active=down and not S.combo_blocked
    if S.combo_active then
        UI.set("farm_enabled",false)
        if edge then
            S.assignment,S.parking,S.rune_claims,S.rune_busy,S.econ_plan={},{},{},{},{}
            Stack.cancel_all("Комбо")
            for _,u in ipairs(Combat.units()) do local id=A.id(u);S.orders[id],S.order_next[id],S.attack_commit[id]=nil,nil,nil end
        end
    end
    if S.combo_blocked and down then S.combo_status="Отпустите комбо и нажмите снова";return end
    M.safety()
    CampMap.cancel_tick()
    local utility=M.utility()
    if S.combo_active or utility or not UI.get("farm_enabled") then Stack.cancel_all("Комбо / фарм выключен") end
    if S.combo_active then if not utility then Combat.tick() end
    elseif not utility then S.target=nil;S.net_plan=nil;S.combo_status="Готов к комбо" end
    if not utility and not S.combo_active then RunesAI.tick();Farm.tick() end
end

function M.run()
    local ok,err=xpcall(M.logic,function(e)
        return debug and debug.traceback and debug.traceback(tostring(e),2) or tostring(e)
    end)
    if not ok then S.last_error=tostring(err);A.log(S.last_error,true) end
end
-- Logic only on game updates, not both rendering and update callbacks.
M.OnUpdate=M.run
function M.OnPrepareUnitOrders(data)
    if type(data)~="table" or not S.session then return true end
    if tostring(data.identifier or ""):sub(1,#M.ORDER_PREFIX)==M.ORDER_PREFIX or (S.issuing or 0)>0 then return true end
    if data.player and data.player~=S.player then return true end
    if CampMap.state().open and not UI.input_captured() then return false end
    local units={}
    if data.npc then
        if type(data.npc)=="table" and data.npc[1]~=nil then units=data.npc else units={data.npc} end
    elseif data.orderIssuer==A.enum("PlayerOrderIssuer","DOTA_ORDER_ISSUER_HERO_ONLY") then units={S.hero}
    else units=A.call(Player and Player.GetSelectedUnits,S.player) or {} end
    local touched=false
    for _,u in ipairs(units) do
        local id=A.id(u)
        if id and S.unit_ids[id] then
            if S.camp_cancel then S.camp_cancel[id]=nil end
            touched=true;S.manual_until[id]=A.now()+UI.get("manual_pause_ms")/1000
            S.orders[id],S.locks[id],S.attack_commit[id],S.order_next[id]=nil,nil,nil,nil
            S.assignment[id],S.parking[id],S.healing[id]=nil,nil,nil
            if S.gather then S.gather.skipped[id]=true end
            Stack.cancel(id,"Ручное управление");NetPlan.invalidate()
            Trace.add(u,"Ручное управление",string.format("Пауза %.1f с",UI.get("manual_pause_ms")/1000))
        end
    end
    if touched and UI.get("manual_mode")==0 and not S.escape.latched then
        S.combo_blocked=S.combo_was_down or S.combo_active or UI.down("combo_key")
        S.combo_active=false;Combat.release("Ручной приказ: комбо остановлено")
    end
    return true
end

function M.OnEntityDestroy(entity)
    Roles.forget(entity)
    local dead_id=A.id(entity)
    local relevant=entity==S.target or (dead_id and S.unit_ids[dead_id])
    if dead_id then
        S.econ_cache[dead_id],S.creep_owner[dead_id]=nil,nil
        S.motion[dead_id],S.net_misses[dead_id],S.net_retry_until[dead_id]=nil,nil,nil
        S.order_next[dead_id],S.inventory_cache[dead_id],S.item_next[dead_id]=nil,nil,nil
        if S.unit_ids[dead_id] then
            Stack.cancel(dead_id,"Мипо недоступен")
            for _,name in ipairs({"econ_watch","econ_info","parking","farm_retreat","poof_watch","poof_block","attack_commit","tower_evade","tower_hits","heal_records","tango_until"}) do S[name][dead_id]=nil end
            for camp_id,claim in pairs(S.stack_claims) do if claim.id==dead_id then S.stack_claims[camp_id]=nil end end
        end
    end
    for id,order in pairs(S.orders) do
        if order.target==entity then S.orders[id]=nil;S.attack_commit[id]=nil;relevant=true end
    end
    for _,rec in pairs(S.assignment) do
        if rec.target==entity then rec.target=nil;relevant=true end
        for _,member in ipairs(rec.members or {}) do if member==entity then relevant=true;break end end
    end
    if relevant then S.npcs_next=-math.huge;S.econ_next=-math.huge;NetPlan.invalidate() end -- события одной группы сводятся к следующему проходу
    if entity==S.target then S.target=nil end
    for _,name in ipairs({"locks","orders","assignment","healing","manual_until","hp_samples"}) do
        local id=A.id(entity);if id then S[name][id]=nil end
    end
    if S.net_pending and (S.net_pending.unit==entity or S.net_pending.target==entity) then S.net_pending=nil end
end

-- Fixed semantic palette; content is sampled, geometry is cached between frames.
function HUD.prepare()
    if not HUD.colors then HUD.colors={text=Color(239,243,248,255),muted=Color(167,180,197,255),
        blue=Color(117,183,248,255),gold=Color(237,199,121,255),warning=Color(237,170,105,255),
        error=Color(244,131,131,255),green=Color(128,205,167,255),bg=Color(19,25,35,242),
        surface=Color(30,39,53,245),line=Color(52,66,85,255)} end
    if not HUD.font then HUD.font=A.call(Render and Render.LoadFont,"Arial",0,500) end
    return HUD.font~=nil
end
function HUD.text(x,y,text,color,size)
    A.call(Render.Text,HUD.font,size or 14,tostring(text),Vec2(x,y),color or HUD.colors.text)
end
function HUD.rect(x,y,w,h,color,radius)
    if w>0 and h>0 then A.call(Render.FilledRect,Vec2(x,y),Vec2(x+w,y+h),color,radius or 0) end
end
function HUD.fit(text,size,width)
    text=tostring(text)
    HUD.fit_cache=HUD.fit_cache or {}
    local key=size..":"..width..":"..text
    if HUD.fit_cache[key] then return HUD.fit_cache[key] end
    if (HUD.fit_count or 0)>256 then HUD.fit_cache={};HUD.fit_count=0 end
    local function remember(value)
        HUD.fit_cache[key]=value;HUD.fit_count=(HUD.fit_count or 0)+1;return value
    end
    local measured=A.call(Render.TextSize,HUD.font,size,text)
    if measured and measured.x<=width then return remember(text) end
    local chars={};for _,cp in utf8.codes(text) do chars[#chars+1]=utf8.char(cp) end
    while #chars>0 do
        local candidate=table.concat(chars).."…"
        local box=A.call(Render.TextSize,HUD.font,size,candidate)
        if box and box.x<=width then return remember(candidate) end
        if not box and #chars<=math.floor(width/(size*.65)) then return remember(candidate) end
        chars[#chars]=nil
    end
    return "…"
end
function HUD.unit_status(u)
    local id=A.id(u);local c=HUD.colors
    if A.manual(u) then return "Ручное управление",c.warning end
    if S.escape.latched then return S.escape.status[id] or "Ожидает отхода",c.warning end
    local poof=A.spell(u,"meepo_poof")
    if poof and (A.call(Ability.IsInAbilityPhase,poof)==true or A.call(Ability.IsChannelling,poof)==true) then return "Пуфует",c.blue end
    local at=S.net_plan and S.net_plan.reserved[id]
    if S.combo_active and at then return string.format("Сетка через %.1f с",math.max(0,at-S.now)),c.gold end
    local net=A.spell(u,"meepo_earthbind")
    if net and A.mana(u)<A.number(A.call(Ability.GetManaCost,net),0) then return "Нет маны на сетку",c.error end
    if S.healing[id] then return "Лечение",c.green end
    if not S.combo_active and Roles.get(u)>0 then return S.role_status[id] or Roles.names[Roles.get(u)+1],c.muted end
    if S.combo_active then return "Комбо · атака",c.text end
    if S.assignment[id] then return "Фарм · "..UI.phase_name(S.assignment[id].phase),c.muted end
    return "Готов",c.muted
end
function HUD.sample()
    if HUD.cache and S.now<(S.hud_next or -math.huge) then return HUD.cache end
    S.hud_next=S.now+Perf.interval("hud")
    local c=HUD.colors;local data={units={},history={}}
    data.mode=S.escape.latched and "ОТХОД" or CampMap.state().open and "КАРТА" or Preset.rage() and "RAGE" or not UI.get("enabled") and "ВЫКЛЮЧЕН" or S.combo_active and "КОМБО" or UI.get("farm_enabled") and "ФАРМ" or "ГОТОВ"
    data.accent=S.escape.latched and c.warning or Preset.rage() and c.error or S.combo_active and c.blue or c.green
    data.status=S.combo_status or "Готов к комбо"
    data.target=S.target and UI.hero_name(S.target) or "Не выбрана"
    data.plan=S.net_plan and S.net_plan.status or "Сетка ждёт выбора цели"
    data.timeline={}
    for i,step in ipairs(S.net_plan and S.net_plan.steps or {}) do
        if i<=3 then data.timeline[#data.timeline+1]=string.format("%s · %.1fс",A.id(step.unit),math.max(0,step.launch-S.now)) end
    end
    for i,u in ipairs(S.units) do
        local status,color=HUD.unit_status(u)
        data.units[#data.units+1]={label=Roles.label(u),status=status,color=color,hp=A.hp(u),unit=u}
    end
    if UI.get("hud_details") then
        for i=#S.history,math.max(1,#S.history-2),-1 do local h=S.history[i]
            data.history[#data.history+1]={text=tostring(h.id).." · "..h.action..(h.reason~="" and " / "..h.reason or ""),color=h.failed and c.warning or c.muted}
        end
    end
    HUD.cache=data;return data
end
function HUD.draw()
    if not S.session or (UI.get("hud_hide_captured") and UI.input_captured()) or not HUD.prepare() then return end
    local screen=A.call(Render and Render.ScreenSize)
    if not screen or type(screen.x)~="number" or type(screen.y)~="number" then return end
    local data=HUD.sample();local c=HUD.colors
    local scale=math.max(.75,math.min(1.5,UI.get("hud_scale")/100,screen.y/900))
    local width=math.min(360*scale,screen.x-24);local pad=16*scale
    local font=math.max(12,math.floor(14*scale));local small=math.max(12,math.floor(12*scale))
    local height=(170+#data.units*44+#data.history*24)*scale
    local x=math.max(12,screen.x-width-UI.get("hud_right_margin"))
    local y=math.max(12,screen.y-UI.get("hud_bottom_margin")-height)
    if UI.get("hud") then
        HUD.rect(x,y,width,height,c.bg,8)
        HUD.rect(x,y,3,height,data.accent,1)
        HUD.text(x+pad,y+pad,"MEEPO / CONTROL",c.text,font+3)
        HUD.text(x+width-90*scale,y+pad+2*scale,data.mode,data.accent,small)
        HUD.text(x+pad,y+42*scale,HUD.fit(data.status,small,width-pad*2),c.muted,small)
        HUD.rect(x+pad,y+66*scale,width-pad*2,1,c.line)
        HUD.text(x+pad,y+78*scale,"ЦЕЛЬ",c.muted,small)
        HUD.text(x+pad+58*scale,y+77*scale,HUD.fit(data.target,font,width-pad*2-58*scale),c.text,font)
        HUD.text(x+pad,y+104*scale,HUD.fit(data.plan,small,width-pad*2),data.accent,small)
        HUD.text(x+pad,y+125*scale,HUD.fit(table.concat(data.timeline,"   →   "),small,width-pad*2),c.muted,small)
        local row_y=y+154*scale
        for _,row in ipairs(data.units) do
            HUD.text(x+pad,row_y,row.label,c.muted,small)
            HUD.text(x+pad+94*scale,row_y,HUD.fit(row.status,small,width-pad*2-94*scale),row.color,small)
            HUD.rect(x+pad,row_y+22*scale,width-pad*2,3*scale,c.surface,1)
            HUD.rect(x+pad,row_y+22*scale,(width-pad*2)*math.min(1,math.max(0,row.hp/100)),3*scale,row.hp<30 and c.error or c.green,1)
            row_y=row_y+44*scale
        end
        for _,h in ipairs(data.history) do HUD.text(x+pad,row_y-3*scale,HUD.fit(h.text,small,width-pad*2),h.color,small);row_y=row_y+24*scale end
    end
    if UI.get("world_labels") then
        for _,row in ipairs(data.units) do
            local pos=A.pos(row.unit)
            if A.valid_position(pos) then
                local p,visible=A.call(Render.WorldToScreen,A.vec(pos.x,pos.y,pos.z+145))
                if p and visible then HUD.text(p.x-70,p.y,row.status,row.color,13) end
            end
        end
    end
end
function M.OnDraw()
    local ok,err=pcall(function() if CampMap.state().open then CampMap.draw() else HUD.draw() end end)
    if not ok then A.log("HUD: "..tostring(err),true) end
end

-- RU4: последовательный урон, автонападение, адаптивные задания, предметы и лечение.
function A.flag(value, group, name)
    local flag=A.enum(group,name)
    local n,f=math.tointeger(value or 0),math.tointeger(flag or 0)
    return n~=nil and f~=nil and f~=0 and (n & f)~=0
end
function Combat.poof_in_progress()
    for _,u in ipairs(S.units) do
        if A.alive(u) then
            local ab=A.spell(u,"meepo_poof")
            local phase=ab and (A.call(Ability.IsChannelling,ab)==true or A.call(Ability.IsInAbilityPhase,ab)==true)
            local lock=S.locks[A.id(u)]
            if phase then
                S.poof_last_caster=A.id(u)
                if lock and lock.ability==ab then lock.observed=true end
                return true
            end
            if lock and lock.ability==ab and not lock.observed
                and S.now<(lock.ack_until or lock.until_time) then return true end
        end
    end
    return false
end
function Combat.net_keeper(units,target)
    local plan=NetPlan.update(units,target)
    return plan.steps[1] and plan.steps[1].unit or nil
end

function Combat.opening_gather(units,target)
    if not S.combo_active or not S.combo_press or not UI.get("combo_poof") or UI.get("gather_mode")==2
        or not Combat.target_valid(target) then return false end
    local anchor=S.hero;local included=false
    for _,u in ipairs(units) do if u==anchor then included=true end end
    if not included or not A.alive(anchor) or A.manual(anchor) or A.has(anchor,"modifier_meepo_petrify")
        or A.state(anchor,"MODIFIER_STATE_OUT_OF_GAME") then S.gather_status="Сбор: главный вне группы";return false end
    if not S.gather or S.gather.press~=S.combo_press then
        S.gather={press=S.combo_press,until_time=S.now+2.4,sent={},skipped={}}
    end
    local g=S.gather
    if S.now>g.until_time then return false end
    local sent,total=0,0
    for _,u in ipairs(units) do
        if u~=anchor and not A.manual(u) then
            local id=A.id(u);total=total+1
            if UI.get("gather_mode")==1 and A.distance(A.pos(u),A.pos(anchor))<=UI.get("gather_distance") then g.skipped[id]=true end
            if not g.sent[id] and not g.skipped[id] then
                local ab=A.spell(u,"meepo_poof")
                local duration=ab and A.poof_time(ab) or 1.5
                if NetPlan.blocks(u,duration+.15) then
                    Trace.add(u,"Сбор","Зарезервирован для сетки",true)
                elseif A.ready(u,ab,false) and not Orders.busy(u,70,S.now)
                    and Orders.cast(u,ab,anchor,nil,70,"стартовый-сбор",duration+.12,false) then
                    g.sent[id]=true;S.metrics.poofs=S.metrics.poofs+1;sent=sent+1
                end
            end
        end
    end
    local done=0;for _ in pairs(g.sent) do done=done+1 end
    S.gather_status=string.format("Сбор: %d/%d · резерв сетки сохранён",done,total)
    return sent>0
end

-- After the one-shot opening gather: one Poof at a time, rotating across eligible Meepos.
function Combat.poof(units,target)
    if not UI.get("combo_poof") then S.poof_status="Выключено в настройках";return false end
    if not Combat.target_valid(target) then S.poof_status="Нет допустимой цели";return false end
    if Combat.poof_in_progress() and not Preset.rage() then
        S.poof_status="Очередь Пуфа: ждём завершения текущего применения / сбора";return false
    end
    local anchor,dist=Combat.poof_anchor(units,target)
    if not anchor then S.poof_status="Нет доступного Мипо для Пуфа";return false end
    local root=A.control_remaining(target,S.now)
    local reserved=nil
    local can_root=UI.get("combo_net") and not A.state(target,"MODIFIER_STATE_DEBUFF_IMMUNE")
        and not A.state(target,"MODIFIER_STATE_MAGIC_IMMUNE")
    if can_root and #units>1 and (root>.05 or Combat.pending_net(target)) then reserved=Combat.net_keeper(units,target) end
    local start=1
    for i,u in ipairs(units) do if A.id(u)==S.poof_last_caster then start=i%#units+1;break end end
    local volleys=0
    local busy,why=0,"Нужен Мипо в зоне урона Пуфа"
    for offset=0,#units-1 do
        local u=units[(start+offset-1)%#units+1]
        if u==reserved then why="Один Мипо держит следующую сетку"
        elseif NetPlan.blocks(u,(A.spell(u,"meepo_poof") and A.poof_time(A.spell(u,"meepo_poof")) or 1.5)+.12) then why="Держит запланированную сетку"
        elseif Orders.busy(u,60,S.now) then busy=busy+1
        else
            local ab=A.spell(u,"meepo_poof")
            local ready,reason=A.ready(u,ab,false)
            if not ready then why=reason
            else
                local duration=A.poof_time(ab)
                local radius=math.max(50,A.poof_radius(ab)-45)
                local predicted=root>=duration and A.pos(target) or Combat.predict(target,duration)
                local destination=nil
                if A.valid_position(predicted) then
                    if A.distance(A.pos(u),A.pos(target))<=radius and A.distance(A.pos(u),predicted)<=radius then destination=u
                    elseif dist<=radius and A.distance(A.pos(anchor),predicted)<=radius then destination=anchor end
                end
                if not destination then why="Сближение: цель вне зоны урона Пуфа"
                elseif UI.get("poof_require_root") and root<duration+.08 then why="Включён Пуф только под контроль"
                elseif Orders.cast(u,ab,destination,nil,60,"пуф-комбо-очередь",duration+.12,false) then
                    S.poof_last_caster=A.id(u);S.metrics.poofs=S.metrics.poofs+1
                    S.poof_status="По очереди: Пуфует Мипо №"..tostring(A.id(u))
                        ..(reserved and "; следующий контроль сохранён" or "")
                    volleys=volleys+1
                    if not Preset.rage() then return true end
                else why=S.failures[A.id(u)] or "Пуф: приказ пока недоступен" end
            end
        end
    end
    if volleys>0 then S.poof_status="RAGE · одновременный Poof: "..volleys;return true end
    if busy==#units then S.poof_status="Мипо применяют способности / заняты приказом" else S.poof_status=why end
    return false
end

-- Сканируются все индексы; GetItem(...,true) отсеивает рюкзак и склад.
Items.rules={}
function Items.rule(names,mode,range,category,condition)
    for name in names:gmatch("%S+") do Items.rules[name]={mode=mode,range=range,category=category,condition=condition} end
end
Items.rule("item_sheepstick item_abyssal_blade","enemy",700,"items_offensive","control")
Items.rule("item_orchid item_bloodthorn","enemy",900,"items_offensive","silence")
Items.rule("item_diffusal_blade item_disperser item_rod_of_atos item_nullifier item_ethereal_blade item_heavens_halberd item_harpoon","enemy",600,"items_offensive")
Items.rule("item_dagon item_dagon_2 item_dagon_3 item_dagon_4 item_dagon_5 item_urn_of_shadows item_spirit_vessel","enemy",700,"items_offensive")
Items.rule("item_gleipnir","point",1100,"items_offensive","control")
Items.rule("item_shivas_guard","none",850,"items_offensive")
Items.rule("item_manta item_mask_of_madness item_phase_boots","none",650,"items_offensive","attack_buff")
Items.rule("item_mjollnir item_solar_crest","self",900,"items_offensive","attack_buff")
Items.rule("item_black_king_bar","none",1000,"items_defensive","bkb")
Items.rule("item_blade_mail","none",650,"items_defensive","blade_mail")
Items.rule("item_satanic","none",650,"items_defensive","low_hp")
Items.rule("item_ghost item_ethereal_ghost","none",600,"items_defensive","critical_hp")
Items.rule("item_glimmer_cape item_lotus_orb","self",900,"items_defensive","low_hp")
Items.rule("item_force_staff","self",1000,"items_defensive","safe_force")
Items.rule("item_hurricane_pike","enemy",450,"items_defensive","critical_hp")
Items.rule("item_shadow_blade item_silver_edge item_invis_sword","none",1200,"items_defensive","invisibility")
Items.rule("item_magic_wand item_magic_stick item_holy_locket","self_or_none",900,"items_resources","wand")
Items.rule("item_mekansm item_guardian_greaves","none",900,"items_resources","team_heal")
Items.rule("item_arcane_boots","none",900,"items_resources","low_mana")
Items.rule("item_soul_ring","none",900,"items_resources","soul_ring")
Items.rule("item_dust","none",1000,"items_detection","dust")
Items.rule("item_refresher item_refresher_shard","none",1200,"items_refresher","refresh")
Items.rule("item_armlet item_radiance","none",800,"items_toggles","toggle_on")
Items.blocked={item_tpscroll=true,item_travel_boots=true,item_travel_boots_2=true,
    item_smoke_of_deceit=true,item_ward_observer=true,item_ward_sentry=true,item_ward_dispenser=true,
    item_tango=true,item_tango_single=true,item_flask=true,item_clarity=true,item_bottle=true,
    item_enchanted_mango=true,item_faerie_fire=true,item_tome_of_knowledge=true,
    item_cheese=true,item_aghanims_shard=true,item_ultimate_scepter_2=true,item_moon_shard=true,
    item_branches=true,item_quelling_blade=true,item_bfury=true}
function Items.inventory(u)
    local id=A.id(u);local cached=S.inventory_cache[id]
    if cached and cached.unit==u and S.now<cached.until_time then return cached.list end
    local out,seen={},{}
    if NPC.GetItemByIndex then
        for index=0,20 do
            local item=A.call(NPC.GetItemByIndex,u,index)
            local name=item and A.call(Ability.GetName,item)
            if item and name and not seen[item] and A.item(u,name)==item then
                seen[item]=true;out[#out+1]={ability=item,name=name,index=index}
            end
        end
    else
        for name in pairs(Items.rules) do
            local item=A.item(u,name)
            if item and not seen[item] then seen[item]=true;out[#out+1]={ability=item,name=name,index=-1} end
        end
    end
    S.inventory_cache[id]={unit=u,list=out,until_time=S.now+.20}
    return out
end
function Items.usable(u,item,name)
    if A.item(u,name)~=item then return false,"Предмет больше не в активном слоте" end
    if Items.blocked[name] or name:find("item_recipe_",1,true)==1 then return false,"Утилитарный предмет" end
    if name:find("blink",1,true) then return false,"Прыжок используется для сближения" end
    if A.call(Ability.IsPassive,item)==true then return false,"Пассивный предмет" end
    if A.call(Item and Item.IsItemEnabled,item)==false then return false,"Временная блокировка слота" end
    if A.call(Item and Item.IsMarkedForSell,item)==true then return false,"Отмечен для продажи" end
    if A.call(Item and Item.RequiresCharges,item)==true and A.number(A.call(Item and Item.GetCurrentCharges,item),0)<=0 then return false,"Нет зарядов" end
    return A.ready(u,item,true)
end
function Items.condition(rule,u,item,target)
    local condition=rule.condition
    if not condition then return true end
    local hp,mana,dist=A.hp(u),A.mana_pct(u),A.distance(A.pos(u),A.pos(target))
    if condition=="control" then
        if A.call(Ability.GetName,item)=="item_sheepstick" then return Combat.hex_wanted(u,item,target) end
        return A.control_remaining(target,S.now)<0.25 and not Combat.pending_net(target)
    end
    if condition=="silence" then return not A.has(target,"modifier_orchid_malevolence_debuff") and not A.has(target,"modifier_bloodthorn_debuff") end
    if condition=="attack_buff" then
        if A.call(Ability.GetName,item)=="item_mask_of_madness" then
            for _,name in ipairs({"meepo_poof","meepo_earthbind"}) do
                local ab=A.spell(u,name)
                if ab and A.number(A.call(Ability.GetCooldown,ab),0)<3 then return false end
            end
        end
        return dist<=rule.range
    end
    if condition=="bkb" then return A.enemy_count_at(A.pos(u),1000)>0 and not A.has(u,"modifier_black_king_bar_immune") end
    if condition=="blade_mail" then return hp<85 and dist<=650 end
    if condition=="low_hp" then return hp<55 end
    if condition=="critical_hp" then return hp<38 end
    if condition=="wand" then return (hp<65 or mana<35) and A.number(A.call(Item and Item.GetCurrentCharges,item),0)>0 end
    if condition=="low_mana" then
        for _,ally in ipairs(S.units) do if A.distance(A.pos(u),A.pos(ally))<900 and A.mana_pct(ally)<55 then return true end end
        return false
    end
    if condition=="team_heal" then
        for _,ally in ipairs(S.units) do if A.distance(A.pos(u),A.pos(ally))<900 and A.hp(ally)<70 and not A.has(ally,"modifier_item_mekansm_noheal") then return true end end
        return false
    end
    if condition=="soul_ring" then return mana<40 and hp>65 end
    if condition=="dust" then return A.state(target,"MODIFIER_STATE_INVISIBLE") or A.has(target,"modifier_item_shadow_amulet_fade") end
    if condition=="invisibility" then return (dist>500 or hp<35) and not A.state(u,"MODIFIER_STATE_INVISIBLE") end
    if condition=="toggle_on" then return A.call(Ability.GetToggleState,item)==false and hp>40 end
    if condition=="safe_force" then
        if hp>35 then return false end
        local base=Farm.fountain();local pos=A.pos(u)
        local rotation=A.call(Entity.GetRotation,u);local forward=rotation and A.method(rotation,"GetForward")
        if not base or not pos or not forward then return false end
        local dx,dy=base.x-pos.x,base.y-pos.y;local len=math.sqrt(dx*dx+dy*dy)
        return len>0 and (forward.x*dx+forward.y*dy)/len>0.5
    end
    if condition=="refresh" then
        local spent=0
        for _,name in ipairs({"meepo_poof","meepo_earthbind"}) do
            local ab=A.spell(u,name);if ab and A.number(A.call(Ability.GetCooldown,ab),0)>2 then spent=spent+1 end
        end
        return spent>=2
    end
    return false
end
function Items.generic() return nil end

function Items.apply(u,rec,target)
    local item,name=rec.ability,rec.name
    local ready,why=Items.usable(u,item,name)
    if not ready then S.item_diagnostics[name]=why;return false end
    local rule=Items.rules[name]
    if not rule then S.item_diagnostics[name]="Нет безопасной политики / метаданных";return false end
    if not UI.get(rule.category) then return false end
    if name=="item_sheepstick" and not UI.get("combo_hex") then return false end
    if (name=="item_orchid" or name=="item_bloodthorn") and not UI.get("combo_silence") then return false end
    if (name=="item_diffusal_blade" or name=="item_disperser" or name=="item_rod_of_atos") and not UI.get("combo_slow") then return false end
    if not Items.condition(rule,u,item,target) then return false end
    local mode=rule.mode
    if mode=="self_or_none" then
        local behavior=A.call(Ability.GetBehavior,item)
        mode=A.flag(behavior,"AbilityBehavior","DOTA_ABILITY_BEHAVIOR_UNIT_TARGET") and "self" or "none"
    end
    local victim,point=nil,nil
    if mode=="enemy" or mode=="point" then
        if A.state(target,"MODIFIER_STATE_INVULNERABLE") or A.state(target,"MODIFIER_STATE_OUT_OF_GAME") then return false end
        if A.state(target,"MODIFIER_STATE_MAGIC_IMMUNE") or A.state(target,"MODIFIER_STATE_DEBUFF_IMMUNE") then return false end
        if mode=="enemy" and (A.has(target,"modifier_item_sphere_target") or A.has(target,"modifier_item_sphere")) then return false end
        if A.distance(A.pos(u),A.pos(target))>A.range(u,item,rule.range) then return false end
        victim=mode=="enemy" and target or nil;point=mode=="point" and A.pos(target) or nil
    elseif mode=="self" then victim=u
    elseif A.distance(A.pos(u),A.pos(target))>rule.range then return false end
    local cast=math.max(0,A.number(A.call(Ability.GetCastPoint,item,true),0))
    if S.combo_active and rule.category~="items_defensive" and NetPlan.blocks(u,cast+.25) then
        Trace.add(u,"Предмет отложен","Резерв следующей сетки",true);return false
    end
    if Orders.cast(u,item,victim,point,60,"предмет:"..name,cast+0.15,true) then
        S.metrics.items=S.metrics.items+1;S.item_diagnostics[name]="Применён";return true
    end
    return false
end
function Items.tick(units,target,stage)
    if not UI.get("items_enabled") then return end
    for _,u in ipairs(units) do
        local id=A.id(u)
        if not Orders.busy(u,60,S.now) and S.now>=(S.item_next[id] or -math.huge) then
            local inventory=Items.inventory(u)
            table.sort(inventory,function(a,b)
                local ra,rb=Items.rules[a.name],Items.rules[b.name]
                local pa=ra and ra.category=="items_defensive" and 0 or ra and ra.category=="items_resources" and 1 or 2
                local pb=rb and rb.category=="items_defensive" and 0 or rb and rb.category=="items_resources" and 1 or 2
                return pa==pb and a.index<b.index or pa<pb
            end)
            local sent=false
            for _,rec in ipairs(inventory) do
                local rule=Items.rules[rec.name]
                local defensive=rule and rule.category=="items_defensive"
                local allowed=not stage or (stage=="survival" and defensive)
                    or (stage=="regular" and not defensive)
                if allowed and Items.apply(u,rec,target) then sent=true;break end
            end
            -- An empty survival pass must NOT hide regular items for another .1 seconds.
            if sent or stage~="survival" then S.item_next[id]=S.now+.10 end
        end
    end
end
local old_blink=Combat.blink
function Combat.blink(units,target)
    if not UI.get("items_enabled") then return false end
    return old_blink(units,target)
end

-- Единый снимок фарма: нейтралы, вражеские волны и известные башни.
function Farm.snapshot()
    if S.now<(S.npcs_next or -math.huge) then return end
    S.npcs_next=S.now+Perf.interval("snapshot");S.snapshot_time=S.now;S.metrics.npc_scans=S.metrics.npc_scans+1
    S.snapshot_version=(S.snapshot_version or 0)+1
    local list=A.call(NPCs and NPCs.GetAll)
    S.neutrals_valid=type(list)=="table";S.snapshot_valid=S.neutrals_valid
    S.neutral_bins,S.lane_creeps,S.towers,S.ally_creeps,S.buildings={},{},{},{},{}
    for _,u in ipairs(list or {}) do
        if A.alive(u) then
            local pos,team=A.pos(u),A.team(u)
            if pos then
                local allied=team==S.team
                local name=A.name(u)
                local tower=not allied and A.call(NPC.IsTower,u)==true
                local visible=A.call(Entity.IsDormant,u)~=true
                local lane=visible and A.call(NPC.IsLaneCreep,u)==true
                if allied and name:find("fountain",1,true) then S.fountain=A.copy(pos) end
                if tower then S.towers[#S.towers+1]=u end
                if not allied and (tower or name:find("barracks",1,true)) then S.buildings[#S.buildings+1]=u end
                if allied and lane then S.ally_creeps[#S.ally_creeps+1]=u end
                if visible and A.call(NPC.IsWaitingToSpawn,u)~=true then
                    if A.call(NPC.IsNeutral,u)==true then
                        local key=math.floor(pos.x/760)..":"..math.floor(pos.y/760)
                        local bin=S.neutral_bins[key] or {};S.neutral_bins[key]=bin;bin[#bin+1]={unit=u,pos=pos}
                    elseif lane and not allied then S.lane_creeps[#S.lane_creeps+1]=u end
                end
            end
        end
    end
end
function Farm.under_tower(pos)
    if not A.valid_position(pos) or not World.fresh() then return true end
    for _,tower in ipairs(S.towers or {}) do
        if A.alive(tower) and A.distance(pos,A.pos(tower))<A.number(A.call(NPC.GetAttackRange,tower),700)+350 then return true end
    end
    return false
end

function Farm.safe_position(pos,radius,allies)
    if A.enemy_count_at(pos,radius)>0 or Farm.under_tower(pos) then return false end
    for _,rec in pairs(S.enemy_memory) do
        if S.now-rec.time<UI.get("lane_memory_sec") and A.distance(pos,rec.pos)<radius then return false end
    end
    if allies and UI.get("lane_respect_allies") then
        for _,hero in ipairs(S.heroes) do
            if A.visible(hero) and A.team(hero)==S.team and not S.unit_ids[A.id(hero)] and A.distance(pos,A.pos(hero))<1200 then return false end
        end
    end
    return true
end
function Farm.eligible(u,ignore_busy)
    local id,mode=A.id(u),UI.get("farm_mode")
    local include=(mode==0 and u~=S.hero) or mode==1 or (mode==2 and not S.selected[id])
    return include and Roles.get(u)~=5 and A.alive(u) and S.now>=(S.manual_until[id] or -math.huge)
        and S.now>=(S.rune_busy[id] or -math.huge)
        and (ignore_busy or not Orders.busy(u,20,S.now))
end
function Farm.waves()
    local waves={}
    for _,creep in ipairs(S.lane_creeps or {}) do
        local pos=A.pos(creep)
        if A.visible(creep) and (Farm.own_side({pos=pos}) or UI.push_active())
            and (Farm.safe_position(pos,UI.get("lane_safe_radius"),true)
                or (UI.push_active() and Push.position_safe(pos) and Push.covered(pos))) then
            local wave=nil
            for _,w in ipairs(waves) do if A.distance(w.pos,pos)<650 then wave=w;break end end
            if not wave then wave={id="волна:"..tostring(A.id(creep)),pos=A.copy(pos),creeps={}};waves[#waves+1]=wave end
            wave.creeps[#wave.creeps+1]=creep
        end
    end
    return waves
end

function Heal.tango(u)
    local item=A.item(u,"item_tango") or A.item(u,"item_tango_single")
    if not item or not A.ready(u,item,true) or A.call(Item and Item.IsItemEnabled,item)==false then return nil end
    local charges=A.call(Item and Item.GetCurrentCharges,item)
    if charges~=nil and charges<=0 then return nil end
    local owner=A.call(Ability.GetOwner,item)
    if owner and A.id(owner)~=A.id(u) then return nil end
    return item,A.number(charges,1)
end
function Heal.regen_active(u)
    for _,name in ipairs({"modifier_tango_heal","modifier_item_tango_heal"}) do
        local mod=A.call(NPC.GetModifier,u,name)
        if mod then
            S.tango_until[A.id(u)]=S.now+math.max(0.2,A.mod_remaining(mod,S.now));return true
        end
    end
    local record=S.heal_records[A.id(u)]
    -- После отправки ждём короткое подтверждение, а не выдумываем 16 секунд лечения.
    return record and record.await_until and S.now<record.await_until or false
end
function Heal.cheaper_tango(u,item,charges,base)
    local maxhp=A.number(A.call(Entity.GetMaxHealth,u),0)
    local need=math.max(0,maxhp*UI.get("farm_resume_hp")/100-A.number(A.call(Entity.GetHealth,u),0))
    local regen=A.special(item,{"health_regen","health_regen_per_second"},7)
    local duration=A.special(item,{"buff_duration","duration"},16)
    local uses=math.ceil(need/math.max(1,regen*duration))
    if uses>charges then return false end
    if not base then return true end
    local speed=math.max(200,A.number(A.call(NPC.GetMoveSpeed,u),300))
    local base_seconds=2*A.distance(A.pos(u),base)/speed+need/math.max(1,maxhp*0.13)
    return uses*duration<base_seconds
end
function Heal.wait_point(u,base)
    local record=S.heal_records[A.id(u)] or {};S.heal_records[A.id(u)]=record
    if record.wait then return record.wait end
    local pos=A.pos(u)
    if base and pos then
        local distance=A.distance(pos,base)
        local ratio=math.min(1,650/math.max(1,distance))
        record.wait=A.vec(pos.x+(base.x-pos.x)*ratio,pos.y+(base.y-pos.y)*ratio,pos.z)
    else record.wait=A.copy(pos) end
    return record.wait
end
function Heal.handle(u)
    local id,hp=A.id(u),A.hp(u)
    if hp<=UI.get("farm_retreat_hp") then S.healing[id]=true end
    if not S.healing[id] then return false end
    if hp>=math.max(UI.get("farm_resume_hp"),UI.get("farm_retreat_hp")+10) then
        S.healing[id],S.heal_records[id],S.tango_until[id]=nil,nil,nil;return false
    end
    S.assignment[id]=nil
    local mode,base=UI.get("heal_mode"),Farm.fountain()
    local safe=hp>12 and A.enemy_count_at(A.pos(u),1200)==0 and not Farm.under_tower(A.pos(u))
    if mode~=0 and safe then
        if Heal.regen_active(u) then
            S.heal_status="Мипо №"..id..": восстанавливается от танго"
            Orders.walk(u,Heal.wait_point(u,base),25,"отойти-для-танго");return true
        end
        local item,charges=Heal.tango(u)
        local record=S.heal_records[id]
        local retry=not record or S.now>=(record.next_attempt or -math.huge)
        if item and retry and (mode==1 or Heal.cheaper_tango(u,item,charges,base)) then
            local range=A.range(u,item,165)
            local best,dist=nil,math.huge
            for _,tree in ipairs(A.call(Trees and Trees.InRadius,A.pos(u),range+12,true) or {}) do
                local d=A.distance(A.pos(u),A.pos(tree))
                if A.call(Tree and Tree.IsActive,tree)==true and d<=range+12 and d<dist then best,dist=tree,d end
            end
            if best and Orders.cast(u,item,best,nil,30,"лечение-танго",0.3,true) then
                S.metrics.items=S.metrics.items+1
                S.heal_records[id]={await_until=S.now+0.6,next_attempt=S.now+1.5,wait=record and record.wait}
                S.heal_status="Мипо №"..id..": танго на дерево";return true
            end
        end
    end
    S.heal_status="Мипо №"..id..": фонтан"..(mode~=0 and " (танго недоступно / невыгодно / опасно)" or "")
    if base then Orders.walk(u,base,25,"лечение-фонтан") else S.heal_status="Не найдена своя база для лечения" end
    return true
end

-- Autonomous hunting removed: no unsolicited hero engagements.
-- RU5: постоянные задания и цели вместо повторного выбора каждые 200 мс.
function Farm.record_creeps(camp,record)
    local list,seen={},{}
    for _,u in ipairs(Farm.nearby(camp.pos,760)) do
        local owner=S.creep_owner[A.id(u)]
        if A.alive(u) and (not owner or owner.unit~=u or owner.camp==camp.id) then list[#list+1]=u;seen[A.id(u)]=true end
    end
    for _,u in ipairs(record and record.members or {}) do
        if A.alive(u) and not seen[A.id(u)] and A.distance(A.pos(u),camp.pos)<2400 then list[#list+1]=u;seen[A.id(u)]=true end
    end
    -- Доп. юниты (осколки големов, скелеты и т.п.) появляются там, где стоял/погиб основной крип:
    -- берём нейтралов рядом с последними позициями членов пачки, даже если они числятся за соседним лагерем.
    for _,p in pairs(record and record.trail or {}) do
        if S.now-p.time<12 then
            for _,u in ipairs(Farm.nearby(p.pos,520)) do
                if A.alive(u) and not seen[A.id(u)] then list[#list+1]=u;seen[A.id(u)]=true end
            end
        end
    end
    return list
end
-- Зачистка засчитывается, только если после гибели последнего видимого крипа прошёл свежий снимок NPC:
-- доп. юниты рождаются в момент смерти основного, а старый снимок их ещё не содержит.
function Farm.confirmed_clear(rec)
    if not rec.clear_since then
        rec.clear_since=S.now;rec.clear_snapshot=S.snapshot_version or 0
    end
    -- Подтверждение — новый успешный снимок после наблюдения пустоты, не произвольный таймер.
    return S.snapshot_valid==true and (S.snapshot_version or 0)>(rec.clear_snapshot or 0)
        and (S.snapshot_time or -math.huge)>rec.clear_since
end

function Farm.find_camp(id)
    for _,c in ipairs(S.camps) do if c.id==id then return c end end
end
function Farm.legacy_choose(u,taken,waves)
    local previous=S.assignment[A.id(u)]
    local strategy=UI.get("farm_strategy")
    if previous and previous.kind=="neutral" and strategy~=2 then
        local camp=Farm.find_camp(previous.camp)
        local key="лагерь:"..tostring(previous.camp)
        if camp and not taken[key] and Farm.own_side(camp) and not Farm.under_tower(camp.pos)
            and (not S.stack_claims[camp.id] or S.stack_claims[camp.id].id==A.id(u))
            and (not Farm.ally_busy(camp) or Farm.engaged_here(u,camp))
            and (not UI.get("farm_avoid_enemies") or A.enemy_count_at(camp.pos,1300)==0) then
            local members=Farm.record_creeps(camp,previous)
            local uncleared=#members>0 or S.now<(previous.hold_until or 0)
                or (previous.empty_since and S.now-previous.empty_since<1.3)
            if uncleared then return {kind="neutral",key=key,camp=camp,pos=camp.pos} end
        end
    end
    if previous and previous.kind=="push" and UI.push_active() and strategy~=0 then
        local b=previous.building
        if Push.valid(u,b) and not taken["строение:"..tostring(A.id(b))] then
            return {kind="push",key="строение:"..tostring(A.id(b)),building=b,pos=A.pos(b)}
        end
    end
    if previous and previous.kind=="lane" and strategy~=0 and Roles.get(u)==0 then
        local live={}
        for _,c in ipairs(previous.members or {}) do
            if A.visible(c) and A.distance(A.pos(u),A.pos(c))<1500
                and Push.lane_safe(A.pos(c)) then live[#live+1]=c end
        end
        if #live>0 and not taken[previous.wave] then
            return {kind="lane",key=previous.wave,wave={id=previous.wave,pos=A.pos(live[1]),creeps=live},pos=A.pos(live[1])}
        end
    end
    local best,score=nil,math.huge
    if strategy~=2 then
        for _,camp in ipairs(S.camps) do
            local key="лагерь:"..tostring(camp.id)
            if not taken[key] and Farm.available(camp,u) and not Farm.under_tower(camp.pos) then
                local value=A.distance(A.pos(u),camp.pos)+250-math.min(#Farm.nearby(camp.pos,760),6)*80
                if previous and previous.camp==camp.id then value=value-550 end
                if value<score then best,score={kind="neutral",key=key,camp=camp,pos=camp.pos},value end
            end
        end
    end
    if strategy~=0 and Roles.get(u)==0 then
        for _,wave in ipairs(waves) do
            if not taken[wave.id] then
                local value=A.distance(A.pos(u),wave.pos)+200-math.min(#wave.creeps,7)*180
                if previous and previous.wave==wave.id then value=value-550 end
                if value<score then best,score={kind="lane",key=wave.id,wave=wave,pos=wave.pos},value end
            end
        end
        if UI.push_active() then
            for _,b in ipairs(S.buildings or {}) do
                local key="строение:"..tostring(A.id(b))
                local distance=A.distance(A.pos(u),A.pos(b))
                if not taken[key] and Push.valid(u,b) then
                    local value=distance+150
                    if previous and previous.kind=="lane" then value=value-450 end
                    if value<score then best,score={kind="push",key=key,building=b,pos=A.pos(b)},value end
                end
            end
        end
    end
    return best
end
function Farm.target_valid(c)
    return A.visible(c) and A.team(c)~=nil and A.team(c)~=S.team
        and not A.state(c,"MODIFIER_STATE_ATTACK_IMMUNE")
        and not A.state(c,"MODIFIER_STATE_INVULNERABLE")
        and not A.state(c,"MODIFIER_STATE_OUT_OF_GAME")
end
function Farm.damage_creeps(u,creeps,tag)
    local id=A.id(u);local record=S.assignment[id] or {}
    local target,score=nil,math.huge
    for _,c in ipairs(creeps) do
        if Farm.target_valid(c) then
            if c==record.target then target=c;break end
            local value=A.distance(A.pos(u),A.pos(c))+A.number(A.call(Entity.GetHealth,c),1000)*0.1
            if value<score then target,score=c,value end
        end
    end
    if UI.get("econ_enabled") then target=Econ.target(u,creeps,record,target) end
    if not target then return false end
    record.target=target;record.members=record.members or creeps
    -- Окно «замаха» защищает только живую цель последнего приказа атаки; после её смерти следующий приказ уходит сразу.
    local last=S.orders[id]
    if S.now<(S.attack_commit[id] or 0) and last and last.kind=="attack" and last.target~=nil and Farm.target_valid(last.target) then return false end
    if Econ.midas(u,creeps) then return true end
    local poof=A.spell(u,"meepo_poof")
    if UI.get("farm_poof") and poof and A.ready(u,poof,false) then
        local list=Farm.poof_targets(u,creeps,poof,record)
        local cost=A.number(A.call(Ability.GetManaCost,poof),0)
        local maxmana=A.number(A.call(NPC.GetMaxMana,u),0)
        if list and #list>=UI.get("farm_min_creeps") and maxmana>0 and (A.mana(u)-cost)/maxmana*100>=UI.get("farm_mana_pct")
            and Econ.poof_worth(u,list,poof) then
            if Orders.cast(u,poof,u,nil,20,"пуф-фарм",A.poof_time(poof)+0.12,false) then
                S.metrics.poofs=S.metrics.poofs+1;Farm.poof_watch(u,list,poof);return true
            end
        end
    end
    return Orders.attack(u,target,20,tag)
end
function Farm.outside_boxes(pos)
    for _,camp in ipairs(S.camps) do
        local box=camp.box
        if box then
            if pos.x>=box.min.x-250 and pos.x<=box.max.x+250 and pos.y>=box.min.y-250 and pos.y<=box.max.y+250 then return false end
        elseif A.distance(pos,camp.pos)<800 then return false end
    end
    return true
end
function Farm.unblock(u)
    local id,pos=A.id(u),A.pos(u)
    local park=S.parking[id]
    if park and S.now<park.until_time then
        if A.distance(pos,park.pos)>100 then Orders.walk(u,park.pos,20,"ожидать-вне-лагерей") end
        return
    end
    local nearest,distance=nil,math.huge
    for _,camp in ipairs(S.camps) do
        local d=A.distance(pos,camp.pos)
        if d<distance then nearest,distance=camp,d end
    end
    if not nearest or distance>900 then return end
    local best,score=nil,math.huge
    -- Однократный выбор точки вне ВСЕХ спавн-боксов. Не перевычисляем вектор от движущегося клона.
    for ring=1,3 do
        for i=0,15 do
            local angle=i*math.pi/8
            local point=A.vec(nearest.pos.x+math.cos(angle)*(800+ring*250),nearest.pos.y+math.sin(angle)*(800+ring*250),pos.z)
            local d=A.distance(pos,point)
            if d<score and Farm.outside_boxes(point) and Farm.safe_position(point,1200,false) then best,score=point,d end
        end
        if best then break end
    end
    if best then
        S.parking[id]={pos=best,until_time=Farm.spawn_deadline()}
        Orders.walk(u,best,20,"ожидать-вне-лагерей")
    end
end
function Farm.neutral_step(u,task,rec)
    if not Roles.task_allowed(u,task) then
        local id=A.id(u);S.assignment[id],S.econ_watch[id]=nil,nil;S.camp_cancel[id]=true;return
    end
    local camp=task.camp;local previous=rec.members or {}
    local creeps=Farm.record_creeps(camp,rec);rec.members=creeps
    local all_dead=#previous>0
    for _,c in ipairs(previous) do if A.call(Entity.IsAlive,c)~=false then all_dead=false;break end end
    if all_dead then rec.deaths_confirmed=true end
    -- Заявка после стака: пока Мипо далеко от кемпа, «пусто» не засчитывается (новая пачка может быть в тумане).
    local claim=S.stack_claims[camp.id]
    if claim and claim.id~=A.id(u) then claim=nil end
    local returning=claim~=nil and A.distance(A.pos(u),camp.pos)>350
    if S.snapshot_valid and rec.engaged and #creeps==0 and rec.deaths_confirmed and not S.stack_units[A.id(u)] and not returning then
        -- Смерть всех членов пачки подтверждена через IsAlive; ждём один свежий снимок, чтобы не пропустить доп. юнитов.
        if Farm.confirmed_clear(rec) then
            rec.phase="done";S.camp_empty[camp.id]=Farm.spawn_deadline()
            if claim then S.stack_claims[camp.id]=nil end
            S.assignment[A.id(u)],S.econ_watch[A.id(u)]=nil,nil
            S.farm_next=-math.huge
        else rec.phase="confirm_empty" end
        return
    end
    local visible={}
    for _,c in ipairs(creeps) do if A.visible(c) then visible[#visible+1]=c end end
    -- Последние позиции членов пачки: основа для поиска доп. юнитов после гибели.
    rec.trail=rec.trail or {}
    for _,c in ipairs(visible) do rec.trail[A.id(c)]={pos=A.copy(A.pos(c)),time=S.now} end
    for id,p in pairs(rec.trail) do if S.now-p.time>12 then rec.trail[id]=nil end end
    if #creeps>0 then rec.clear_since,rec.clear_snapshot=nil,nil end
    if #visible>0 then
        rec.empty_since,rec.unseen_since,rec.deaths_confirmed=nil,nil,nil
        if not rec.target or not A.visible(rec.target) then
            local best,distance=nil,math.huge
            for _,c in ipairs(visible) do local d=A.distance(A.pos(u),A.pos(c));if d<distance then best,distance=c,d end end
            rec.target=best
        end
        rec.last_target_pos=A.copy(A.pos(rec.target))
        local range=A.number(A.call(NPC.GetAttackRange,u),150)
        local contact=A.distance(A.pos(u),rec.last_target_pos)<=range+90
        if contact then
            rec.engaged=true;rec.contact_at=S.now
            if claim then S.stack_claims[camp.id]=nil end -- дальше кемп удерживает обычное задание
        end
        rec.phase=contact and "combat" or "approach"
        if Stack.tick(u,task,rec) then return end
        -- The same ATTACK command owns approach and combat. No MOVE-to-centre is inserted between them.
        Farm.damage_creeps(u,visible,"атака-нейтрала")
        return
    end
    if S.stack_units[A.id(u)] then Stack.tick(u,task,rec);return end
    if not S.snapshot_valid then return end
    if returning then
        rec.phase="approach";rec.unseen_since,rec.search_pos=nil,nil
        Orders.walk(u,camp.pos,20,"возврат-на-стак");return
    end
    if #creeps>0 then
        rec.phase="search";rec.unseen_since=rec.unseen_since or S.now
        rec.search_pos=rec.search_pos or A.copy(rec.last_target_pos or camp.pos)
        if S.now-rec.unseen_since<4 then
            if A.distance(A.pos(u),rec.search_pos)>100 then Orders.walk(u,rec.search_pos,20,"проверить-последнюю-позицию") end
        else
            -- Unknown is NOT empty. Exclude just this unit/task briefly instead of dragging it backwards.
            S.econ_blacklist[tostring(A.id(u))..":"..task.key]=S.now+8
            S.assignment[A.id(u)]=nil
        end
        return
    end
    if A.distance(A.pos(u),camp.pos)>350 then
        rec.phase="approach";Orders.walk(u,camp.pos,20,"переход-к-лагерю");return
    end
    rec.phase="confirm_empty";rec.empty_since=rec.empty_since or S.now
    -- Нужен один новый успешный снимок NPC; парковка — только если следующего задания нет.
    if Farm.confirmed_clear(rec) then
        rec.phase="done";S.camp_empty[camp.id]=Farm.spawn_deadline()
        if claim then S.stack_claims[camp.id]=nil end
        S.assignment[A.id(u)],S.econ_watch[A.id(u)]=nil,nil
        S.farm_next=-math.huge
    end
end
function Farm.tick()
    if not UI.get("farm_enabled") then Stack.cancel_all("Фарм выключен");S.farm_status="Автофарм выключен; F6 — включить";return end
    if S.combo_active then Stack.cancel_all("Бой");S.farm_status="Пауза фарма: идёт бой";return end
    if S.now<(S.farm_next or -math.huge) then return end
    S.farm_next=S.now+Perf.interval("farm")
    Farm.refresh_camps();Farm.snapshot();Stable.ownership();Econ.observe()
    Stack.prune_claims();Farm.scan_allies();Farm.poof_audit()
    local waves,taken,active=Farm.waves(),{},0
    for id,rec in pairs(S.assignment) do
        if S.unit_ids[id] then local key=Econ.key(rec);if key then taken[key]=id end
        else S.assignment[id]=nil;Stack.cancel(id,"Мипо недоступен") end
    end
    Econ.plan(waves,taken)
    for camp_id,claim in pairs(S.stack_claims) do
        local key="лагерь:"..tostring(camp_id);if not taken[key] then taken[key]=claim.id end
    end
    for _,u in ipairs(S.units) do
        local id=A.id(u)
        if Farm.eligible(u,true) then
            if S.stack_units[id] and (A.hp(u)<UI.get("stack_min_hp") or (not UI.get("stack_enabled") and Roles.get(u)~=3)) then Stack.cancel(id,"Мало здоровья / выключено") end
            if Heal.handle(u) then Stack.cancel(id,"Лечение");S.parking[id]=nil
            elseif Push.danger(u) then Stack.cancel(id,"Опасность линии")
            elseif S.tower_evade[id] then
                -- Tower exit/wait owns this unit; farm orders cannot pull it back in.
            elseif Stable.retreat(u) then Stack.cancel(id,"Опасность")
            elseif Roles.step(u) then
                -- Dedicated stack/escort policy owns this pass.
            elseif S.stack_units[id] then
                local task=Stable.current(u)
                if task then Stack.tick(u,task,S.assignment[id]) else Stack.cancel(id,"Потеря задания") end
            elseif Orders.busy(u,20,S.now) then
                -- No economic reevaluation, movement recovery, or empty-camp move during a real channel.
            elseif Econ.resources(u) then
                -- The resource active owns this pass.
            elseif Econ.watchdog(u) then
                -- Retry only the same order. Never add a speculative sideways move into an ongoing attack.
            else
                local reservations={}
                for key,owner in pairs(taken) do if owner~=id then reservations[key]=true end end
                local task=Farm.choose(u,reservations,waves)
                if task then
                    taken[task.key]=id;S.parking[id]=nil;active=active+1
                    local rec=Stable.bind(u,task)
                    if task.kind=="neutral" then
                        if not rec.engaged and Econ.travel(u,task) then
                            -- Economic travel preserves this same assignment.
                        else Farm.neutral_step(u,task,rec) end
                    elseif task.kind=="lane" then
                        rec.members=task.wave.creeps;rec.phase="lane";Farm.damage_creeps(u,rec.members,"атака-линии")
                    else rec.phase="push";Orders.attack(u,task.building,20,"сплитпуш-строение") end
                else
                    S.assignment[id]=nil
                    Stable.idle(u)
                end
            end
        end
    end
    S.farm_status=string.format("Фарм: занято %d; стадия фиксируется до конца задания",active)
end

-- Руны: один ближайший свободный Мипо на одну реальную видимую руну.
function RunesAI.allowed(rune)
    if A.call(Runes and Runes.Contains,rune)~=true or A.call(Entity.IsDormant,rune)==true then return false end
    local t=A.call(Rune and Rune.GetRuneType,rune)
    if t==nil then return false end
    if t==A.enum("RuneType","DOTA_RUNE_BOUNTY") then return UI.get("runes_bounty") end
    if t==A.enum("RuneType","DOTA_RUNE_XP") then return UI.get("runes_wisdom") end
    return UI.get("runes_power")
end
function RunesAI.tick()
    if not UI.get("runes_enabled") or not UI.get("farm_enabled") or S.combo_active then return end
    if S.now<(S.runes_next or -math.huge) then return end
    S.runes_next=S.now+.12;Farm.snapshot()
    local used={}
    for _,rune in ipairs(A.call(Runes and Runes.GetAll) or {}) do
        local safety_radius=UI.push_active() and math.max(1300,UI.get("push_danger_radius")) or 1300
        if RunesAI.allowed(rune) and Farm.safe_position(A.pos(rune),safety_radius,false) and S.now>=(S.rune_retry[A.id(rune)] or 0) then
            local rid=A.id(rune);local claim=S.rune_claims[rid]
            if claim and S.now-(claim.started or S.now)>4 then
                S.rune_retry[rid]=S.now+8;S.rune_claims[rid]=nil;claim=nil
            end
            local best,dist=nil,math.huge
            for _,u in ipairs(S.units) do
                local id=A.id(u);local record=S.assignment[id]
                local finishing=record and record.kind=="neutral" and #Farm.record_creeps(Farm.find_camp(record.camp) or {pos=A.pos(u)},record)>0
                if Roles.get(u)==0 and S.now>=(S.rune_retry[rid] or 0) and not used[id] and (u~=S.hero or UI.get("runes_main")) and not finishing
                    and not S.tower_evade[id] and not S.stack_units[id] and not S.push_escape[id] and not (record and record.kind=="push")
                    and (not UI.push_active() or Push.position_safe(A.pos(u)))
                    and not S.healing[id] and A.hp(u)>UI.get("farm_retreat_hp")
                    and S.now>=(S.manual_until[id] or 0) and not Orders.busy(u,15,S.now) then
                    local distance=A.distance(A.pos(u),A.pos(rune))
                    if distance<=UI.get("runes_radius") then
                        if claim and claim.unit==u and S.now<claim.until_time then best,dist=u,distance;break end
                        if distance<dist then best,dist=u,distance end
                    end
                end
            end
            if best then
                local id=A.id(best);used[id]=true;S.rune_busy[id]=S.now+.35
                if not claim or claim.unit~=best or S.now>=(claim.next_order or 0) then
                    if Orders.issue(best,"DOTA_UNIT_ORDER_PICKUP_RUNE",rune,A.pos(rune),nil,15,"подобрать-руну") then
                        S.rune_claims[rid]={unit=best,next_order=S.now+.8,until_time=S.now+4,started=claim and claim.started or S.now}
                    end
                end
            end
        end
    end
    for id,rec in pairs(S.rune_claims) do if S.now>rec.until_time then S.rune_claims[id]=nil end end
end

-- Hex не ждёт летящую сетку, когда надо запретить эскейп/защитный предмет или сбить канал.
function Combat.hex_wanted(u,item,target)
    if not Combat.target_valid(target) then return false end
    if S.hex_pending and S.hex_pending.target==target and S.now<S.hex_pending.until_time then return false end
    local cast=A.number(A.call(Ability.GetCastPoint,item,true),0)
    local margin=cast+UI.get("hex_margin_ms")/1000
    local remaining=A.control_remaining(target,S.now)
    local hard=math.max(A.mod_remaining(A.call(NPC.GetModifier,target,"modifier_sheepstick_debuff"),S.now),
        A.mod_remaining(A.call(NPC.GetModifier,target,"modifier_abyssal_blade_stun"),S.now),
        A.mod_remaining(A.call(NPC.GetModifier,target,"modifier_stunned"),S.now))
    if hard>margin then return false end
    local mode=UI.get("hex_mode")
    if mode==1 then return true end
    if mode==2 then return remaining<=margin and not Combat.pending_net(target) end
    local channel=A.call(NPC.GetChannellingAbility,target)
    if channel and A.call(Ability.IsChannelling,channel)==true then return true end
    if remaining<=margin then return true end
    for _,name in ipairs({"item_black_king_bar","item_manta","item_cyclone","item_wind_waker"}) do
        local escape=A.item(target,name)
        if escape and A.ready(target,escape,true) then return true end
    end
    for _,name in ipairs({"antimage_blink","queenofpain_blink","puck_phase_shift","slark_dark_pact","juggernaut_blade_fury","life_stealer_rage","morphling_waveform"}) do
        local escape=A.spell(target,name)
        if escape and (A.call(Ability.IsInAbilityPhase,escape)==true or A.ready(target,escape,false)) then return true end
    end
    return false
end
function Combat.hex(units,target)
    if not UI.get("items_enabled") or not UI.get("items_offensive") or not UI.get("combo_hex") then return false end
    for _,u in ipairs(units) do
        local item=A.item(u,"item_sheepstick")
        if item and not Orders.busy(u,60,S.now) and Combat.hex_wanted(u,item,target)
            and Items.apply(u,{ability=item,name="item_sheepstick"},target) then
            S.hex_pending={target=target,until_time=S.now+.35};return true
        end
    end
    return false
end

-- Only safe lane farming remains; no tower diving/reaggro controller.
function Push.position_safe(pos) return Farm.safe_position(pos,1300,false) end
function Push.lane_safe(pos) return Farm.safe_position(pos,UI.get("lane_safe_radius"),true) end
function Push.valid() return false end
function Push.danger() return false end

-- MegaMeepo: несколько раненых спасаются одним сбором; одиночный раненый сначала использует Dig.
function Mega.find(victim)
    if not UI.get("save_mega") or S.now<(S.mega_pending or 0) then return nil end
    local best,score=nil,-math.huge
    for _,caster in ipairs(S.units) do
        for _,name in ipairs({"meepo_megameepo","meepo_mega_meepo"}) do
            local ab=A.spell(caster,name)
            if ab and A.ready(caster,ab,false) and not Orders.busy(caster,100,S.now)
                and not A.has(caster,"modifier_meepo_megameepo") and not A.has(caster,"modifier_meepo_mega_meepo") then
                local radius=A.special(ab,{"radius","pull_radius"},600)
                local count,wounded,healthy=0,0,0
                for _,ally in ipairs(S.units) do
                    if ally~=caster and A.distance(A.pos(caster),A.pos(ally))<=radius and not A.has(ally,"modifier_meepo_petrify")
                        and not A.state(ally,"MODIFIER_STATE_OUT_OF_GAME") then
                        count=count+1;if A.hp(ally)<UI.get("mega_group_hp") then wounded=wounded+1 else healthy=healthy+1 end
                    end
                end
                if A.hp(caster)<UI.get("mega_group_hp") then wounded=wounded+1 end
                local in_range=not victim or A.distance(A.pos(caster),A.pos(victim))<=radius
                local can_save=count>0 and (A.hp(caster)>=30 or healthy>=2)
                local value=wounded*100+count*15+A.hp(caster)
                if in_range and can_save and value>score then best,score={unit=caster,ability=ab,radius=radius,wounded=wounded},value end
            end
        end
    end
    return best
end
function Mega.cast(rec,tag)
    if not rec then return false end
    if Orders.cast(rec.unit,rec.ability,nil,nil,100,tag,.65,false) then
        S.mega_pending=S.now+.8
        for _,ally in ipairs(S.units) do
            if ally~=rec.unit and A.distance(A.pos(rec.unit),A.pos(ally))<=rec.radius then
                S.locks[A.id(ally)]={ability=rec.ability,priority=100,sent=S.now,until_time=S.now+.65,tag="сборка-Mega"}
            end
        end
        S.safety_status="Мегамипо: сбор группы для спасения";return true
    end
    return false
end
function M.safety()
    if not UI.get("save_enabled") then return end
    local danger={}
    for _,u in ipairs(S.units) do
        local id,hp=A.id(u),A.hp(u);local previous=S.hp_samples[id]
        local drop=previous and previous.drop_until or 0
        if previous and previous.hp-hp>=4 then drop=S.now+1.2 end
        S.hp_samples[id]={hp=hp,drop_until=drop}
        if hp<=UI.get("save_hp") and not A.has(u,"modifier_meepo_petrify")
            and (hp<=12 or drop>S.now or A.enemy_count_at(A.pos(u),1000)>0) then danger[#danger+1]=u end
    end
    if UI.get("mega_mode")==0 then
        local group=Mega.find()
        if group and group.wounded>=UI.get("mega_group_count") and A.enemy_count_at(A.pos(group.unit),1000)>0 then
            if Mega.cast(group,"спасение-Mega-группа") then return end
        end
    end
    table.sort(danger,function(a,b)return A.hp(a)<A.hp(b) end)
    for _,u in ipairs(danger) do
        if not Orders.busy(u,100,S.now) then
            local saved=false
            if UI.get("mega_mode")==2 then saved=Mega.cast(Mega.find(u),"спасение-Mega") end
            local dig=A.spell(u,"meepo_petrify")
            if not saved and UI.get("save_dig") and dig and A.ready(u,dig,false) then
                saved=Orders.cast(u,dig,nil,nil,100,"спасение-Dig",math.max(.5,A.number(A.call(Ability.GetCastPoint,dig,true),0)+.15),false)
            end
            if not saved then saved=Mega.cast(Mega.find(u),"спасение-Mega") end
            if not saved and UI.get("save_poof") then
                local best,score=nil,-math.huge
                for _,other in ipairs(S.units) do
                    local d=A.distance(A.pos(u),A.pos(other))
                    if other~=u and d>800 and A.hp(other)>50 and A.enemy_count_at(A.pos(other),1200)==0
                        and not Orders.busy(other,100,S.now) and not Farm.under_tower(A.pos(other)) and d>score then best,score=other,d end
                end
                local poof=A.spell(u,"meepo_poof")
                if best and poof and A.ready(u,poof,false) then
                    saved=Orders.cast(u,poof,best,nil,100,"спасение-пуф",A.poof_time(poof)+.25,false)
                    if saved then S.metrics.poofs=S.metrics.poofs+1 end
                end
            end
            if saved then S.safety_status="Спасение Мипо №"..tostring(A.id(u)) end
        end
    end
end

-- Heuristic Echo reactions removed.
-- RU6: bounded economic allocation. All income/rates below are estimates, never measured GPM.
function Econ.stat(u)
    local id=A.id(u);local cached=S.econ_cache[id]
    if cached and cached.unit==u and S.now<cached.until_time then
        if cached.sampled_at~=S.now then
            cached.hp=math.max(1,A.number(A.call(Entity.GetHealth,u),cached.hp))
            cached.maxhp=math.max(1,A.number(A.call(Entity.GetMaxHealth,u),cached.maxhp))
            cached.pos=A.copy(A.pos(u));cached.sampled_at=S.now
        end
        return cached
    end
    local hero=A.call(Entity.IsHero,u)==true
    local min=A.call(NPC.GetTrueDamage,u);local max=A.call(NPC.GetTrueMaximumDamage,u)
    local attack=A.call(NPC.GetAttackTime,u)
    local armour=A.call(NPC.GetArmorDamageMultiplier,u)
    if type(armour)~="number" or armour<0 or armour>3 then
        local value=A.number(A.call(NPC.GetPhysicalArmorValue,u,false),0)
        armour=1-0.06*value/(1+0.06*math.abs(value))
    end
    local magic=A.number(A.call(NPC.GetMagicalArmorDamageMultiplier,u),.75)
    local lo,hi=A.call(NPC.GetGoldBountyMin,u),A.call(NPC.GetGoldBountyMax,u)
    local xp=A.call(NPC.GetBountyXP,u);local ancient=A.call(NPC.IsAncient,u)==true
    local lane=A.call(NPC.IsLaneCreep,u)==true
    local gold_known=type(lo)=="number" and type(hi)=="number"
    local gold=gold_known and math.max(0,(lo+hi)/2) or (ancient and 80 or lane and 45 or 40)
    local result={unit=u,until_time=S.now+.35,sampled_at=S.now,pos=A.copy(A.pos(u)),
        hp=math.max(1,A.number(A.call(Entity.GetHealth,u),1000)),maxhp=math.max(1,A.number(A.call(Entity.GetMaxHealth,u),1000)),
        damage=math.max(1,type(min)=="number" and (min+A.number(max,min))/2 or hero and 75 or 20),
        attack=math.max(.15,A.number(attack,1.5)),armour=math.max(.05,math.min(3,armour)),magic=math.max(0,math.min(2,magic)),
        regen=math.max(0,A.number(A.call(NPC.GetHealthRegen,u),0)),mana_regen=math.max(0,A.number(A.call(NPC.GetManaRegen,u),0)),
        speed=math.max(180,A.number(A.call(NPC.GetMoveSpeed,u),300)),gold=gold,xp=math.max(0,A.number(xp,ancient and 125 or 70)),
        ancient=ancient,lane=lane,trusted=type(min)=="number" and type(attack)=="number",
        confidence=gold_known and type(xp)=="number" and 1 or .72}
    S.econ_cache[id]=result;return result
end
function Econ.entries(creeps)
    local out={}
    for _,c in ipairs(creeps or {}) do if A.visible(c) then out[#out+1]=Econ.stat(c) end end
    return out
end
function Econ.observe()
    if not UI.get("econ_enabled") then return end
    S.econ_cycle=S.econ_cycle+1;S.econ_entries={}
    if S.econ_observed_snapshot==S.snapshot_version and S.econ_observed_camps==S.camps_version then return end
    S.econ_observed_snapshot,S.econ_observed_camps=S.snapshot_version,S.camps_version
    for _,camp in ipairs(S.camps) do
        local entries=Econ.entries(Farm.nearby(camp.pos,760))
        if #entries>0 then
            local memory={entries={},time=S.now}
            for _,e in ipairs(entries) do
                local copy={}
                for k,v in pairs(e) do if k~="unit" and k~="pos" then copy[k]=v end end
                copy.hp=copy.maxhp;copy.confidence=copy.confidence*.6
                memory.entries[#memory.entries+1]=copy
            end
            S.econ_profiles[camp.id]=memory
        end
    end
    -- Destroyed entities must not accumulate forever in long matches.
    for id,rec in pairs(S.econ_cache) do if S.now-rec.until_time>30 then S.econ_cache[id]=nil end end
end
function Econ.task_entries(task)
    local cache=S.econ_entries or {};S.econ_entries=cache
    if cache[task.key] then return cache[task.key] end
    local list=task.kind=="neutral" and Farm.record_creeps(task.camp,nil)
        or task.kind=="lane" and task.wave.creeps or {task.building}
    local entries=Econ.entries(list)
    if #entries==0 and task.kind=="neutral" then
        local previous=S.econ_profiles[task.camp.id]
        if previous and S.now-previous.time<180 then entries=previous.entries
        else entries={{hp=1400,maxhp=1400,damage=20,attack=1.5,armour=.85,magic=.75,
            regen=0,gold=85,xp=140,confidence=.4,trusted=false,ancient=false}} end
    end
    cache[task.key]=entries;return entries
end
function Econ.damage(ab,entry)
    if not ab then return 0 end
    local raw=A.special(ab,{"poof_damage","damage"},0)
    if raw<=0 then raw=A.number(A.call(Ability.GetDamage,ab),0) end
    if raw<=0 then return 0 end
    local dtype=A.call(Ability.GetDamageType,ab)
    local pure=A.enum("DamageTypes","DAMAGE_TYPE_PURE")
    local physical=A.enum("DamageTypes","DAMAGE_TYPE_PHYSICAL")
    local multiplier=pure and dtype==pure and 1 or physical and dtype==physical and entry.armour or entry.magic
    if entry.unit and A.state(entry.unit,"MODIFIER_STATE_INVULNERABLE") then return 0 end
    if entry.unit and not (pure and dtype==pure) and not (physical and dtype==physical)
        and A.state(entry.unit,"MODIFIER_STATE_MAGIC_IMMUNE") then return 0 end
    return raw*2*multiplier -- Self-Poof: departure and arrival at the same point.
end
function Econ.mana_reserve(u,ab)
    local percent=A.number(A.call(NPC.GetMaxMana,u),0)*UI.get("farm_mana_pct")/100
    local net=A.spell(u,"meepo_earthbind")
    local emergency=UI.get("econ_reserve_net") and net and A.number(A.call(Ability.GetLevel,net),0)>0
        and A.number(A.call(Ability.GetManaCost,net),0) or 0
    return math.max(percent,emergency)
end
function Econ.forecast(u,entries,allow_poof)
    local us=Econ.stat(u);local plain,after,incoming,gold,xp,confidence=0,0,0,0,0,1
    local ab=A.spell(u,"meepo_poof");local cost=ab and A.number(A.call(Ability.GetManaCost,ab),0) or 0
    local ready=allow_poof and UI.get("farm_poof") and ab and A.ready(u,ab,false)
        and A.mana(u)-cost>=Econ.mana_reserve(u,ab) and #entries>=UI.get("farm_min_creeps")
    local known,ancient,trusted=false,false,us.trusted
    for _,e in ipairs(entries) do
        local hit=math.max(1,us.damage*e.armour)
        local regen=math.min(hit/us.attack*.8,e.regen or 0)
        local health=e.hp*(1+regen/math.max(1,hit/us.attack-regen))
        plain=plain+math.ceil(health/hit)*us.attack
        local poof=ready and Econ.damage(ab,e) or 0
        if poof>0 then known=true end
        after=after+math.ceil(math.max(0,health-poof)/hit)*us.attack
        incoming=incoming+(e.trusted and e.damage/e.attack or 0)
        gold=gold+e.gold;xp=xp+e.xp;confidence=math.min(confidence,e.confidence or .5)
        ancient=ancient or e.ancient;trusted=trusted and e.trusted
    end
    local channel=ab and A.poof_time(ab) or 1.5
    local mana_cost_time=cost/math.max(1.5,us.mana_regen)*.03
    local saving=plain-(channel+after)
    local use=ready and known and saving>UI.get("econ_poof_save_ms")/1000+mana_cost_time
    local clear=use and channel+after or plain
    clear=math.max(.3,clear)
    local loss=math.max(0,(incoming*.55*us.armour-us.regen)*clear)
    local health=A.number(A.call(Entity.GetHealth,u),us.hp)
    local after_hp=(health-loss)/us.maxhp*100
    local heal_time=loss/math.max(10,us.maxhp*.025+us.regen)*.25
    if after_hp<UI.get("farm_retreat_hp")+8 then
        local base=Farm.fountain()
        heal_time=heal_time+(base and A.distance(A.pos(u),base)/us.speed*1.5 or 25)
    end
    return {clear=clear,plain=plain,poof=use,poof_gain=use and math.max(0,saving-mana_cost_time) or 0,
        mana_time=use and mana_cost_time or 0,heal_time=heal_time,loss=loss,after_hp=after_hp,
        gold=gold,xp=xp,confidence=confidence,ancient=ancient,trusted=trusted}
end
function Econ.ancient_safe(u,creeps)
    if not u or not UI.get("econ_ancients") then return false end
    local f=Econ.forecast(u,Econ.entries(creeps),true)
    return f.trusted and f.after_hp>=math.max(45,UI.get("farm_retreat_hp")+12) and f.clear<35
end
function Econ.route(u,task)
    local from,to=A.pos(u),task.pos
    if not from or not to or not S.heroes_valid then return nil end
    local risk=0
    for i=0,4 do
        local f=i/4;local p=A.vec(from.x+(to.x-from.x)*f,from.y+(to.y-from.y)*f,from.z)
        if UI.get("farm_avoid_enemies") and A.enemy_count_at(p,1100)>0 then return nil end
        if task.kind~="push" and Farm.under_tower(p) then
            if not (task.kind=="lane" and UI.push_active() and Push.covered(p)) then return nil end
        end
        for _,m in pairs(S.enemy_memory) do
            local age=S.now-m.time;local d=A.distance(p,m.pos)
            if age<UI.get("lane_memory_sec") and d<1200 then return nil end
            if age<30 and d<2400 then risk=math.max(risk,(1-age/30)*(1-d/2400)*18) end
        end
    end
    -- Straight-line distance + detour allowance, NOT a claim of a NavMesh shortest path.
    return A.distance(from,to)/Econ.stat(u).speed*1.15,risk
end
function Econ.evaluate(u,task)
    if Roles.get(u)>=3 or not Roles.task_allowed(u,task) then return nil end
    S.econ_metrics.evaluations=S.econ_metrics.evaluations+1
    if S.now<(S.econ_blacklist[tostring(A.id(u))..":"..task.key] or 0) then return nil end
    if task.kind=="neutral" and not Farm.available(task.camp,u) then return nil end
    if task.kind=="push" and not Push.valid(u,task.building) then return nil end
    local travel,risk=Econ.route(u,task);if not travel then return nil end
    local entries=Econ.task_entries(task);if #entries==0 then return nil end
    local forecast=Econ.forecast(u,entries,true)
    if forecast.ancient and (not UI.get("econ_ancients") or not forecast.trusted
        or forecast.after_hp<math.max(45,UI.get("farm_retreat_hp")+12)) then return nil end
    local gold,xp=forecast.gold,forecast.xp
    local expiry=1
    if task.kind=="lane" then
        -- A contested wave loses reward while we walk: approximate allied-creep pressure.
        local pressure=0
        for _,c in ipairs(S.ally_creeps or {}) do if A.visible(c) and A.distance(A.pos(c),task.pos)<800 then pressure=pressure+1 end end
        expiry=math.max(.15,1-travel*pressure*.016)
    elseif task.kind=="push" then
        -- Building rewards are shared; do not credit the whole team bounty to this caster.
        gold=gold*.25;xp=xp*.25
    end
    local goal=UI.get("econ_goal")
    local reward=goal==1 and gold or goal==2 and xp or gold+xp*UI.get("econ_xp_weight")/100
    local total=math.max(.8,travel+forecast.clear+forecast.heal_time+forecast.mana_time+(risk or 0))
    local score=reward*forecast.confidence*expiry/total
    local previous=S.assignment[A.id(u)]
    local oldkey=Econ.key(previous)
    if oldkey and oldkey~=task.key then score=score/(1+UI.get("econ_switch_pct")/100) end
    local lookahead=Econ.next_distance(task)
    if lookahead then score=score/(1+math.min(.18,lookahead/Econ.stat(u).speed/(total+5)*.18)) end
    forecast.total,forecast.travel,forecast.risk=total,travel,risk or 0
    forecast.score,forecast.gold_rate,forecast.xp_rate=score,gold*forecast.confidence*expiry/total*60,xp*forecast.confidence*expiry/total*60
    forecast.reason=forecast.confidence<.7 and "разведка / оценка" or forecast.poof and "выгоден Пуф" or "атаки выгоднее"
    forecast.expiry=expiry
    return forecast
end
function Econ.next_distance(task)
    if task.nearest_known then return task.nearest_distance end
    local best=math.huge
    for _,other in ipairs(S.econ_catalogue or {}) do
        if other.key~=task.key then best=math.min(best,A.distance(task.pos,other.pos)) end
    end
    task.nearest_known=true;task.nearest_distance=best<math.huge and best or nil
    return task.nearest_distance
end
function Econ.key(record)
    if not record then return nil end
    return record.kind=="neutral" and "лагерь:"..tostring(record.camp)
        or record.kind=="lane" and record.wave or record.kind=="push" and "строение:"..tostring(A.id(record.building)) or nil
end
function Econ.catalogue(waves)
    local all={}
    if UI.get("farm_strategy")~=2 then
        for _,c in ipairs(S.camps) do
            if Farm.own_side(c) and not Farm.under_tower(c.pos) then all[#all+1]={kind="neutral",key="лагерь:"..tostring(c.id),camp=c,pos=c.pos} end
        end
    end
    if UI.get("farm_strategy")~=0 then
        for _,w in ipairs(waves) do all[#all+1]={kind="lane",key=w.id,wave=w,pos=w.pos} end
        if UI.push_active() then
            for _,b in ipairs(S.buildings or {}) do all[#all+1]={kind="push",key="строение:"..tostring(A.id(b)),building=b,pos=A.pos(b)} end
        end
    end
    S.econ_catalogue=all;return all
end
function Econ.hold(u) return Stable.current(u) end

-- Small bounded maximum-weight matching; exact only inside the retained candidate shortlist.
function Econ.search(jobs,index,used,current,total,context)
    context.nodes=context.nodes+1;if context.nodes>6000 then return end
    if index>#jobs then
        if total>context.best_score then
            context.best_score=total;context.best={}
            for id,rec in pairs(current) do context.best[id]=rec end
        end
        return
    end
    if total+(context.upper[index] or 0)<=context.best_score then return end
    local job=jobs[index]
    for _,rec in ipairs(job.options) do
        if not used[rec.task.key] then
            used[rec.task.key]=true;current[job.id]=rec
            Econ.search(jobs,index+1,used,current,total+rec.eval.score,context)
            used[rec.task.key],current[job.id]=nil,nil
        end
    end
    Econ.search(jobs,index+1,used,current,total,context)
end
function Econ.match(jobs)
    table.sort(jobs,function(a,b)return #a.options==#b.options and tostring(a.id)<tostring(b.id) or #a.options<#b.options end)
    local context={nodes=0,best_score=-1,best={},upper={}}
    local upper=0
    for i=#jobs,1,-1 do upper=upper+(jobs[i].options[1] and jobs[i].options[1].eval.score or 0);context.upper[i]=upper end
    Econ.search(jobs,1,{},{},0,context)
    return context.best,context.best_score,context.nodes
end
function Econ.plan(waves,taken)
    if S.now<(S.econ_next or -math.huge) then return end
    S.econ_next=S.now+Perf.interval("economy")
    S.econ_plan={};S.econ_planned_at=S.now
    if not UI.get("econ_enabled") then return end
    S.econ_metrics.plans=S.econ_metrics.plans+1
    local catalogue=Econ.catalogue(waves);local free,reserved,jobs={},{},{}
    for _,u in ipairs(S.units) do
        local id=A.id(u)
        if Roles.get(u)<3 and Farm.eligible(u,false) and not S.healing[id] and A.hp(u)>UI.get("farm_retreat_hp") and not S.push_escape[id] and not S.tower_evade[id] then free[id]=u end
    end
    for id,rec in pairs(S.assignment) do if not free[id] then local key=Econ.key(rec);if key then reserved[key]=id end end end
    for camp_id,claim in pairs(S.stack_claims) do
        local key="лагерь:"..tostring(camp_id);if not reserved[key] then reserved[key]=claim.id end
    end
    -- Мипо с заявкой возвращается на свой кемп (Farm.choose), в общий подбор не попадает.
    for id,u in pairs(free) do if Farm.claim_task(u) then free[id]=nil end end
    for id,u in pairs(free) do
        local task=Econ.hold(u)
        local eval=task and not reserved[task.key] and Stable.held_eval(u,task)
        if eval then
            S.econ_plan[id]={task=task,eval=eval};reserved[task.key]=id;free[id]=nil
        end
    end
    for id,u in pairs(free) do
        local options={}
        for _,task in ipairs(catalogue) do
            if not reserved[task.key] then
                local eval=Econ.evaluate(u,task)
                if eval and eval.score>0 then options[#options+1]={task=task,eval=eval} end
            end
        end
        table.sort(options,function(a,b)return a.eval.score==b.eval.score and a.task.key<b.task.key or a.eval.score>b.eval.score end)
        while #options>4 do table.remove(options) end
        jobs[#jobs+1]={id=id,options=options}
    end
    local assigned,score,nodes=Econ.match(jobs)
    S.econ_metrics.nodes=S.econ_metrics.nodes+nodes;S.econ_last_score=score
    for id,rec in pairs(assigned) do S.econ_plan[id]=rec;reserved[rec.task.key]=id end
    for key in pairs(taken) do taken[key]=nil end
    for key,id in pairs(reserved) do taken[key]=id end
end
function Farm.choose(u,taken,waves)
    if Roles.get(u)>=3 then return nil end
    local claimed=Farm.claim_task(u)
    if claimed then
        local current=Stable.current(u)
        local rec=S.assignment[A.id(u)]
        local fighting=current and current.key~=claimed.key and rec and rec.contact_at and S.now-rec.contact_at<8
        if fighting then return current end
        if not taken[claimed.key] then return claimed end
    end
    local opportunity=Tower.opportunity(u,taken)
    if opportunity then return opportunity end
    local task=Stable.current(u)
    if task and not taken[task.key] then return task end
    if not UI.get("econ_enabled") then return Farm.legacy_choose(u,taken,waves) end
    local id=A.id(u);local planned=S.econ_plan[id]
    if planned and not taken[planned.task.key] then
        local task=planned.task
        local valid=task.kind=="neutral" and Farm.available(task.camp,u)
            or task.kind=="lane" and Push.lane_safe(task.pos)
        if valid and Roles.task_allowed(u,task) then S.econ_info[id]=planned.eval;return task end
    end
    return nil
end

function Econ.poof_worth(u,creeps,ab)
    if not UI.get("econ_enabled") then return true end
    if A.mana(u)-A.number(A.call(Ability.GetManaCost,ab),0)<Econ.mana_reserve(u,ab) then return false end
    if not UI.get("econ_poof") then return true end
    local in_range={}
    for _,c in ipairs(creeps) do if A.visible(c) and A.distance(A.pos(u),A.pos(c))<=A.poof_radius(ab)-35 then in_range[#in_range+1]=c end end
    local entries=Econ.entries(in_range)
    local raw=A.special(ab,{"poof_damage","damage"},0)
    if raw<=0 then raw=A.number(A.call(Ability.GetDamage,ab),0) end
    if raw<=0 then return true end -- Unknown damage metadata: preserve the established min-creeps/mana policy.
    local forecast=Econ.forecast(u,entries,true)
    S.econ_info[A.id(u)]=S.econ_info[A.id(u)] or {}
    S.econ_info[A.id(u)].reason=forecast.poof and "выгоден Пуф" or "берегу ману / атаки быстрее"
    return forecast.poof
end
function Econ.target(u,creeps,record,fallback)
    local last=S.orders[A.id(u)]
    if fallback and Farm.target_valid(fallback) and (record.kind~="lane"
        or (last and last.kind=="attack" and last.target==fallback)
        or A.call(NPC.IsAttacking,u)==true or S.now<(S.attack_commit[A.id(u)] or 0)) then return fallback end
    local us=Econ.stat(u);local best,score=nil,-math.huge
    for _,c in ipairs(creeps) do
        if Farm.target_valid(c) then
            local e=Econ.stat(c);local hp=A.number(A.call(Entity.GetHealth,c),e.hp)
            local hit=us.damage*e.armour;local walk=math.max(0,A.distance(A.pos(u),A.pos(c))-150)/us.speed
            local finish=math.ceil(hp/math.max(1,hit))*us.attack+walk
            local value=(e.gold+e.xp*.15)/math.max(.2,finish)
            if hp<=hit and walk<.5 then value=value*3 end
            if c==record.target then value=value*1.12 end
            if value>score then best,score=c,value end
        end
    end
    return best or fallback
end
function Econ.midas(u,creeps)
    if not UI.get("econ_enabled") or not UI.get("econ_midas") or not UI.get("items_enabled") then return false end
    local item=A.item(u,"item_hand_of_midas")
    if not item or not A.ready(u,item,true) or A.call(Item and Item.IsItemEnabled,item)==false then return false end
    local best,score=nil,-math.huge
    for _,c in ipairs(creeps) do
        if A.visible(c) and A.call(NPC.IsAncient,c)~=true and not A.state(c,"MODIFIER_STATE_MAGIC_IMMUNE")
            and A.distance(A.pos(u),A.pos(c))<=A.range(u,item,600) then
            local e=Econ.stat(c);local value=e.xp+math.min(400,e.hp)*.08
            if value>score then best,score=c,value end
        end
    end
    if best and Orders.cast(u,item,best,nil,24,"фарм-Midas",.25,true) then
        S.metrics.items=S.metrics.items+1;S.econ_metrics.midas=S.econ_metrics.midas+1;return true
    end
    return false
end
function Econ.resources(u)
    if not UI.get("econ_enabled") or not UI.get("econ_resources") or not UI.get("items_enabled") or not UI.get("items_resources")
        or Orders.busy(u,26,S.now) then return false end
    for _,name in ipairs({"item_magic_wand","item_magic_stick","item_guardian_greaves","item_mekansm","item_arcane_boots","item_soul_ring"}) do
        local item=A.item(u,name);local rule=Items.rules[name]
        if item and rule and A.ready(u,item,true) and A.call(Item and Item.IsItemEnabled,item)~=false then
            local need=(name=="item_arcane_boots" or name=="item_soul_ring") and A.mana_pct(u)<45
                or (name~="item_arcane_boots" and name~="item_soul_ring" and (A.hp(u)<60 or A.mana_pct(u)<30))
            if name=="item_soul_ring" then need=need and A.hp(u)>75 end
            if need and Items.condition(rule,u,item,u) then
                local behavior=A.call(Ability.GetBehavior,item)
                local target=(rule.mode=="self" or (rule.mode=="self_or_none" and A.flag(behavior,"AbilityBehavior","DOTA_ABILITY_BEHAVIOR_UNIT_TARGET"))) and u or nil
                if Orders.cast(u,item,target,nil,26,"фарм-ресурсы:"..name,.2,true) then S.metrics.items=S.metrics.items+1;return true end
            end
        end
    end
    return false
end
function Econ.travel(u,task)
    if not UI.get("econ_enabled") or not UI.get("econ_travel_poof") or A.distance(A.pos(u),task.pos)<1600 then return false end
    local ab=A.spell(u,"meepo_poof")
    if not ab or not A.ready(u,ab,false) or A.mana(u)-A.number(A.call(Ability.GetManaCost,ab),0)<Econ.mana_reserve(u,ab) then return false end
    -- Пуф к кемпу без видимых нейтралов (после стака / пустой кемп) — в пустоту: идём пешком.
    if task.kind=="neutral" and (S.stack_claims[task.camp.id] or #Farm.nearby(task.pos,760)==0) then return false end
    local us=Econ.stat(u);local walking=A.distance(A.pos(u),task.pos)/us.speed
    local best,saving=nil,UI.get("econ_travel_save")
    local info=S.econ_info[A.id(u)] or {};local lost_clear=info.poof_gain or 0
    local mana_time=A.number(A.call(Ability.GetManaCost,ab),0)/math.max(1.5,us.mana_regen)*.03
    for _,ally in ipairs(S.units) do
        if ally~=u and A.hp(ally)>55 and not S.healing[A.id(ally)] and not S.push_escape[A.id(ally)]
            and not A.state(ally,"MODIFIER_STATE_OUT_OF_GAME") and A.call(NPC.IsRunning,ally)~=true
            and not S.stack_units[A.id(ally)] and not S.poof_watch[A.id(ally)]
            and A.call(Ability.IsChannelling,A.spell(ally,"meepo_poof"))~=true
            and A.distance(A.pos(ally),task.pos)<850 and Farm.safe_position(A.pos(ally),1300,false) then
            local gain=walking-A.poof_time(ab)-A.distance(A.pos(ally),task.pos)/us.speed-lost_clear-mana_time
            if gain>saving then best,saving=ally,gain end
        end
    end
    if best and Orders.cast(u,ab,best,nil,22,"пуф-переход-фарм",A.poof_time(ab)+.15,false) then
        local id=A.id(u);local old=S.assignment[id]
        local record=task.kind=="neutral" and {kind="neutral",camp=task.camp.id,hold_until=S.now+A.poof_time(ab)+1}
            or task.kind=="lane" and {kind="lane",wave=task.wave.id,members=task.wave.creeps}
            or {kind="push",building=task.building}
        if Econ.key(old)==task.key then record=old end
        S.assignment[id]=record;S.metrics.poofs=S.metrics.poofs+1;S.econ_metrics.travel_poofs=S.econ_metrics.travel_poofs+1
        S.econ_info[id]=info;info.reason=string.format("Пуф экономит ≈%.1f с",saving);return true
    end
    return false
end
function Econ.watchdog(u)
    local assignment=S.assignment[A.id(u)]
    if assignment and not Roles.task_allowed(u,{kind=assignment.kind,camp=assignment.camp and Farm.find_camp(assignment.camp)}) then
        S.assignment[A.id(u)],S.econ_watch[A.id(u)]=nil,nil;S.camp_cancel[A.id(u)]=true;return true
    end
    if not UI.get("econ_enabled") or not UI.get("econ_watchdog") or Orders.busy(u,20,S.now)
        or S.stack_units[A.id(u)] or not S.snapshot_valid then return false end
    local id=A.id(u);local rec=S.assignment[id];local key=Econ.key(rec)
    if not rec or not key then S.econ_watch[id]=nil;return false end
    if rec.phase=="search" or rec.phase=="confirm_empty" then return false end
    local target=rec.kind=="push" and rec.building or rec.target
    -- Недоступную цель заменит обычный выбор фарма; не повторяем приказ в иммунитет.
    if target and rec.kind~="push" and not Farm.target_valid(target) then return false end
    local pos=target and A.visible(target) and A.pos(target)
        or rec.kind=="neutral" and Farm.find_camp(rec.camp) and Farm.find_camp(rec.camp).pos
    if not pos then return false end
    local health=0
    if rec.kind=="push" then health=A.number(A.call(Entity.GetHealth,target),0)
    else for _,c in ipairs(rec.members or {}) do if A.visible(c) then health=health+A.number(A.call(Entity.GetHealth,c),0) end end end
    local distance=A.distance(A.pos(u),pos);local watch=S.econ_watch[id]
    local last_hit=A.number(A.call(NPC.GetLastAttackTime,u),-math.huge)
    if not watch or watch.key~=key then
        S.econ_watch[id]={key=key,health=health,distance=distance,progress=S.now,last_hit=last_hit};return false
    end
    -- Только изменение наблюдений: застывший IsAttacking больше не маскирует зависание.
    local new_hit=last_hit>(watch.last_hit or -math.huge)
    watch.last_hit=last_hit
    if distance<watch.distance-70 or new_hit then
        if new_hit then S.econ_retries[tostring(id)..":"..key]=nil end
        watch.progress=S.now;watch.health=health;watch.distance=distance;return false
    end
    if S.now-watch.progress<UI.get("econ_stall_sec") then return false end
    local retry_key=tostring(id)..":"..key;local attempts=S.econ_retries[retry_key] or 0
    S.econ_retries[retry_key]=attempts+1;S.econ_retry_time[retry_key]=S.now
    watch.progress=S.now;S.econ_metrics.stalls=S.econ_metrics.stalls+1
    if attempts==0 then
        S.orders[id]=nil
        if target and A.visible(target) then return Orders.attack(u,target,23,"фарм-повтор-атаки") end
        return Orders.walk(u,pos,23,"фарм-повтор-подхода")
    end
    S.econ_blacklist[retry_key]=S.now+12
    S.assignment[id],S.econ_watch[id],S.econ_info[id]=nil,nil,nil
    return true
end

-- Stable execution owns an assignment; the economist only selects a NEW one.
function Stable.trace(u,tag,target,pos)
    local rec=S.assignment[A.id(u)];local line={time=S.now,unit=A.id(u),tag=tag,phase=rec and rec.phase or "idle",
        key=Econ.key(rec),target=target and A.id(target),x=pos and pos.x,y=pos and pos.y}
    S.farm_trace[#S.farm_trace+1]=line;if #S.farm_trace>128 then table.remove(S.farm_trace,1) end
    if UI.get("stable_trace") then
        A.log(string.format("%0.2f | Мипо %s | %s | %s | %s",S.now,tostring(line.unit),UI.phase_name(line.phase),tostring(line.key or "—"),tag),true)
    end
end
function Stable.ownership()
    if not S.snapshot_valid then return end
    if S.ownership_snapshot==S.snapshot_version and S.ownership_camps==S.camps_version then return end
    S.ownership_snapshot,S.ownership_camps=S.snapshot_version,S.camps_version
    for id,rec in pairs(S.creep_owner) do if not A.alive(rec.unit) then S.creep_owner[id]=nil end end
    for _,camp in ipairs(S.camps) do
        for _,u in ipairs(Farm.nearby(camp.pos,760)) do
            local id=A.id(u);local old=S.creep_owner[id]
            if not old or old.unit~=u then
                local best,distance=camp,A.distance(A.pos(u),camp.pos)
                for _,other in ipairs(S.camps) do local d=A.distance(A.pos(u),other.pos);if d<distance then best,distance=other,d end end
                S.creep_owner[id]={unit=u,camp=best.id}
            end
        end
    end
end
function Stable.bind(u,task)
    local id=A.id(u);local rec=S.assignment[id]
    if rec and Econ.key(rec)==task.key then return rec end
    rec={kind=task.kind,phase="approach",started=S.now,lease_until=S.now+math.min(120,10+A.distance(A.pos(u),task.pos)/math.max(180,A.number(A.call(NPC.GetMoveSpeed,u),300))*1.6)}
    if task.kind=="neutral" then rec.camp=task.camp.id
    elseif task.kind=="lane" then rec.wave=task.wave.id;rec.members=task.wave.creeps
    else rec.building=task.building end
    S.assignment[id]=rec;S.econ_watch[id]=nil;return rec
end
function Stable.current(u)
    local id=A.id(u);local rec=S.assignment[id];if not rec then return nil end
    if not Roles.task_allowed(u,{kind=rec.kind,camp=rec.camp and Farm.find_camp(rec.camp)}) then
        S.assignment[id],S.econ_watch[id]=nil,nil;S.camp_cancel[id]=true;Stack.cancel(id,"Задание не соответствует роли");return nil
    end
    if rec.kind=="neutral" and UI.get("farm_strategy")~=2 then
        local camp=Farm.find_camp(rec.camp)
        if not camp or not Farm.own_side(camp) then
            S.assignment[id],S.econ_watch[id]=nil,nil
            S.camp_cancel[id]=true;Stack.cancel(id,"Кемп недоступен")
            return nil
        end
        if Farm.ally_busy(camp) and not Farm.engaged_here(u,camp) and not S.stack_units[id] then
            -- Союзник начал фармить этот кемп раньше нас: отпускаем задание, выбор другого — в этом же тике.
            S.econ_blacklist[tostring(id)..":"..Econ.key(rec)]=S.now+6
            S.assignment[id],S.econ_watch[id]=nil,nil;return nil
        end
        if not rec.engaged and rec.lease_until and S.now>rec.lease_until and not S.stack_units[id] then
            S.econ_blacklist[tostring(id)..":"..Econ.key(rec)]=S.now+6;S.assignment[id]=nil;return nil
        end
        -- Admission forecasts, mana changes, stale IsKnownClear and a short score drop cannot revoke this command.
        return {kind="neutral",key=Econ.key(rec),camp=camp,pos=camp.pos}
    elseif rec.kind=="lane" and UI.get("farm_strategy")~=0 then
        local live={}
        for _,c in ipairs(rec.members or {}) do
            if A.visible(c) and A.distance(A.pos(u),A.pos(c))<1800 and Push.lane_safe(A.pos(c)) then live[#live+1]=c end
        end
        if #live>0 then return {kind="lane",key=rec.wave,wave={id=rec.wave,pos=A.pos(live[1]),creeps=live},pos=A.pos(live[1])} end
    elseif rec.kind=="push" and UI.get("farm_strategy")~=0 and Push.valid(u,rec.building) then
        return {kind="push",key=Econ.key(rec),building=rec.building,pos=A.pos(rec.building)}
    end
end
function Stable.held_eval(u,task)
    local old=S.econ_info[A.id(u)]
    if old then old.reason=S.stack_units[A.id(u)] and "стак: отдельный владелец" or "удерживаю начатое задание";return old end
    return {score=.01,gold_rate=0,xp_rate=0,total=0,reason="удерживаю начатое задание"}
end
function Stable.retreat(u)
    local id=A.id(u);local rec=S.assignment[id];local existing=S.farm_retreat[id]
    local danger=false
    if UI.get("farm_avoid_enemies") then
        local point=rec and rec.kind=="neutral" and Farm.find_camp(rec.camp)
        danger=A.enemy_count_at(A.pos(u),1000)>0 or (point and A.enemy_count_at(point.pos,1300)>0)
            or (Farm.under_tower(A.pos(u)) and not (UI.push_active() and (Push.covered(A.pos(u)) or Tower.covered_position(u)) and Push.position_safe(A.pos(u))))
    end
    if danger then
        existing=existing or {};existing.until_time=S.now+4;S.farm_retreat[id]=existing
        S.assignment[id],S.econ_watch[id],S.parking[id]=nil,nil,nil
    end
    if existing and S.now<existing.until_time then
        local base=Farm.fountain();if base then Orders.walk(u,base,30,"отход-фарм") end
        return true
    end
    S.farm_retreat[id]=nil;return false
end
function Stable.idle(u)
    -- A missing plan/temporary low score is NOT an instruction to reverse away from a living camp.
    for _,camp in ipairs(S.camps) do
        if A.distance(A.pos(u),camp.pos)<900 then
            local stack=S.stack_camps[camp.id]
            local empty=S.now<(S.camp_empty[camp.id] or 0)
            if empty or (stack and stack.unit~=u) then Farm.unblock(u);return end
        end
    end
end

-- A stack attempt is a separate owner, not a periodic farm MOVE override.
function Stack.cancel(id,reason)
    local state=S.stack_units[id];if not state then return end
    S.stack_camps[state.camp]=nil;S.stack_units[id]=nil
    S.stack_results[id]={camp=state.camp,time=S.now,success=false,reason=reason or "Отменено"}
end
function Stack.cancel_all(reason)
    local ids={};for id in pairs(S.stack_units or {}) do ids[#ids+1]=id end
    for _,id in ipairs(ids) do Stack.cancel(id,reason) end
end
function Stack.claim(u,state,confirmed)
    if not u or not state or not state.camp or Roles.get(u)==3 then return nil end
    local camp=Farm.find_camp(state.camp)
    if not camp or not CampMap.allowed(camp) then return nil end
    local id=A.id(u)
    for camp_id,old in pairs(S.stack_claims) do if old.id==id then S.stack_claims[camp_id]=nil end end
    local claim={unit=u,id=id,camp=state.camp,minute=state.minute,initial_ids=state.initial_ids or {},
        confirmed=confirmed==true,created=S.now,expires=S.now+(confirmed and 75 or 30)}
    S.stack_claims[state.camp]=claim
    S.camp_empty[state.camp],S.camp_knowledge[state.camp]=nil,nil
    return claim
end
function Stack.claim_for(u)
    local id=A.id(u)
    for _,claim in pairs(S.stack_claims) do if claim.id==id then return claim end end
end
function Stack.prune_claims()
    for camp_id,claim in pairs(S.stack_claims) do
        if S.now>=claim.expires or not S.unit_ids[claim.id] or not A.alive(claim.unit) then S.stack_claims[camp_id]=nil end
    end
end
function Stack.point(u,camp)
    if not camp.box then return nil end
    local center,pos=camp.pos,A.pos(u);local dx,dy=pos.x-center.x,pos.y-center.y
    local preferred=math.atan(dy,dx);local best,score=nil,math.huge
    local width=math.max(math.abs(camp.box.max.x-camp.box.min.x),math.abs(camp.box.max.y-camp.box.min.y))*.5
    local radius=math.max(UI.get("stack_distance"),width+550)
    for i=0,15 do
        local angle=preferred+i*math.pi/8
        local candidate=A.vec(center.x+math.cos(angle)*radius,center.y+math.sin(angle)*radius,center.z)
        if Farm.outside_boxes(candidate) and Farm.safe_position(candidate,1300,false) and not Farm.under_tower(candidate) then
            local value=A.distance(pos,candidate)
            if value<score then best,score=candidate,value end
        end
    end
    return best
end
function Stack.begin(u,task,rec)
    if (not UI.get("stack_enabled") and Roles.get(u)~=3) or task.kind~="neutral" or not S.snapshot_valid or A.hp(u)<UI.get("stack_min_hp")
        or Orders.busy(u,35,S.now) then return nil end
    local clock=A.number(A.call(GameRules.GetGameTime),S.now)-A.number(A.call(GameRules.GetGameStartTime),0)
    if clock<0 then return nil end
    local minute=math.floor(clock/60);local second=clock-minute*60
    if second<UI.get("stack_second") or second>=57.8 or S.stack_attempts[task.camp.id]==minute then return nil end
    if A.distance(A.pos(u),task.pos)>650 then return nil end
    local visible={};for _,c in ipairs(rec.members or {}) do if A.visible(c) then visible[#visible+1]=c end end
    if #visible==0 then return nil end
    local point=Stack.point(u,task.camp);if not point then return nil end
    local target=rec.target or visible[1];if not A.visible(target) then target=visible[1] end
    local ids={};for _,c in ipairs(visible) do ids[A.id(c)]=true end
    local state={unit=u,camp=task.camp.id,minute=minute,phase="tag",point=A.copy(point),target=target,
        started=S.now,spawn=S.now+(60-second),initial_ids=ids,initial_hp=A.number(A.call(Entity.GetHealth,target),0),
        initial_hit=A.number(A.call(NPC.GetLastAttackTime,u),-math.huge),
        baseline=A.number(A.call(Camp and Camp.GetKnownStackCount,task.camp.raw or task.camp.handle or task.camp.data),0)}
    S.stack_units[A.id(u)],S.stack_camps[state.camp],S.stack_attempts[state.camp]=state,state,minute
    Stable.trace(u,"стак-начало",target,point);return state
end
function Stack.tick(u,task,rec)
    local id=A.id(u);local state=S.stack_units[id] or Stack.begin(u,task,rec)
    if not state then return false end
    if task.kind~="neutral" or state.camp~=task.camp.id or (not UI.get("stack_enabled") and Roles.get(u)~=3) then Stack.cancel(id,"Смена задания");return false end
    if A.hp(u)<UI.get("stack_min_hp") then Stack.cancel(id,"Мало здоровья");return false end
    if Orders.busy(u,35,S.now) then return true end
    if state.phase=="tag" then
        local last_hit=A.number(A.call(NPC.GetLastAttackTime,u),-math.huge)
        local hp=A.number(A.call(Entity.GetHealth,state.target),state.initial_hp)
        local recent=last_hit>state.initial_hit or (state.initial_hit>state.started-.65 and A.distance(A.pos(u),A.pos(state.target))<250)
        if hp<state.initial_hp or recent then
            state.phase="pull";state.tag_confirmed=S.now
        elseif S.now-state.started>2 or S.now>state.spawn-1.3 then
            Stack.cancel(id,"Агро не подтверждено; отвод не запускался");return true
        else
            Orders.attack(u,state.target,35,"стак-агро");return true
        end
    end
    if state.phase=="pull" then
        -- The point is captured ONCE. Do not recompute a vector from the moving clone.
        rec.phase="stack_pull";Orders.walk(u,state.point,35,"стак-фиксированный-отвод")
        if S.now>=state.spawn+1.0 then state.phase="verify" end
        return true
    end
    if state.phase=="verify" then
        rec.phase="stack_verify"
        local known=A.number(A.call(Camp and Camp.GetKnownStackCount,task.camp.raw or task.camp.handle or task.camp.data),0)
        local old_alive,new_visible=0,0
        for _,c in ipairs(Farm.record_creeps(task.camp,rec)) do
            if A.visible(c) then
                if state.initial_ids[A.id(c)] then old_alive=old_alive+1
                elseif A.distance(A.pos(c),task.pos)<650 then new_visible=new_visible+1 end
            end
        end
        local confirmed=known>state.baseline or (old_alive>0 and new_visible>0)
        if confirmed or S.now>=state.spawn+3 then
            S.stack_results[id]={camp=state.camp,time=S.now,success=confirmed,
                reason=confirmed and "Новый спавн подтверждён" or "Новый спавн не подтверждён"}
            Stable.trace(u,confirmed and "стак-подтверждён" or "стак-не-подтверждён",nil,state.point)
            S.stack_units[id],S.stack_camps[state.camp]=nil,nil
            rec.phase="combat";rec.engaged=true;rec.target=nil;rec.empty_since=nil
            rec.contact_at,rec.deaths_confirmed,rec.unseen_since,rec.search_pos=nil,nil,nil,nil
            Stack.claim(u,state,confirmed) -- вернуться на этот кемп и зачистить новую пачку
            return true
        end
        return true
    end
    return true
end



-- Tower observations are independent from farming; there is no tower-order automation.
function Tower.cancel(id) S.tower_evade[id]=nil end
function Tower.opportunity() return nil end
function Tower.covered_position() return false end

-- V9: bounded net planning, diagnostics, independent observations and explicit escape.
Perf.presets={
        [0]={logic=.033,collect=.10,farm=.10,snapshot=.35,plan=.12,economy=.40,hud=.12,world=.50},
        [1]={logic=.020,collect=.075,farm=.08,snapshot=.25,plan=.08,economy=.30,hud=.10,world=.40},
        [2]={logic=.050,collect=.15,farm=.18,snapshot=.50,plan=.18,economy=.65,hud=.20,world=.75},
        [3]={logic=.0167,collect=.05,farm=.067,snapshot=.22,plan=.05,economy=.25,hud=.10,world=.35},
    }
function Perf.interval(kind)
    local mode=UI.get("perf_mode") or 0
    return (Perf.presets[mode] or Perf.presets[0])[kind] or .10
end

function Trace.add(u,action,reason,failed)
    if not S.history then S.history={} end
    local id=u and A.id(u) or "—"
    local last=S.history[#S.history]
    if last and last.id==id and last.action==action and last.reason==reason and S.now-last.time<1 then return end
    S.history[#S.history+1]={time=S.now or 0,id=id,action=action,reason=reason or "",failed=failed==true}
    if #S.history>32 then table.remove(S.history,1) end
end
function World.scan(force)
    if not force and S.now<(S.world_next or -math.huge) then return end
    S.world_next=S.now+Perf.interval("world")
    local flags=A.enum("UnitTypeFlags","TYPE_STRUCTURE")
    local list=A.call(NPCs and NPCs.GetAll,flags)
    if type(list)~="table" then S.world_valid=false;return end
    local towers={}
    for _,u in ipairs(list) do
        if A.alive(u) then
            if A.team(u)~=S.team and A.call(NPC.IsTower,u)==true then towers[#towers+1]=u end
            if A.team(u)==S.team and A.name(u):find("fountain",1,true) then S.fountain=A.copy(A.pos(u)) end
        end
    end
    S.towers,S.world_valid,S.world_time=towers,true,S.now
end
function World.fresh()
    return S.world_valid==true and S.now-(S.world_time or -math.huge)<=Perf.interval("world")+1
end
function UI.target_sets_init(group)
    UI.target_names,UI.target_keys={},{}
    for key,label in pairs(UI.hero_names) do
        local display=label.." ["..key.."]"
        UI.target_names[#UI.target_names+1]=display;UI.target_keys[display]=key
    end
    table.sort(UI.target_names)
    UI.target_sets={preferred={},ignored={}}
    for _,kind in ipairs({"preferred","ignored"}) do
        local enabled={}
        for _,display in ipairs(UI.target_names) do
            local key=UI.target_keys[display]
            if A.call(Config and Config.ReadInt,M.CONFIG_NAME,kind..":"..key,0)==1 then
                enabled[#enabled+1]=display;UI.target_sets[kind][key]=true
            end
        end
        local field="target_"..kind
        UI[field]=A.method(group,"MultiCombo",kind=="preferred" and "Предпочтительные герои" or "Игнорируемые герои",UI.target_names,enabled)
        A.method(UI[field],"SetCallback",function()
            local list=A.method(UI[field],"ListEnabled")
            if type(list)~="table" then return end
            local set={}
            for _,display in ipairs(list) do local key=UI.target_keys[display];if key then set[key]=true end end
            UI.target_sets[kind]=set
            for _,display in ipairs(UI.target_names) do
                local key=UI.target_keys[display]
                A.call(Config and Config.WriteInt,M.CONFIG_NAME,kind..":"..key,set[key] and 1 or 0)
            end
            S.net_plan_next=-math.huge;S.hud_next=-math.huge
        end,false)
    end
end
function UI.target_rank(u)
    local key=A.name(u):gsub("npc_dota_hero_","")
    local sets=UI.target_sets or {}
    if sets.ignored and sets.ignored[key] then return 0 end
    return sets.preferred and sets.preferred[key] and 2 or 1
end
function NetPlan.duration(ab,target)
    local duration=A.special(ab,{"duration","net_duration","root_duration"},2)
    local property=A.enum("ModifierFunction","MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING")
    local resistance=property and A.call(NPC.GetModifierProperty,target,property)
    if type(resistance)=="number" then duration=duration*(1-math.max(0,math.min(.95,resistance/100))) end
    return math.max(.15,math.min(10,duration))
end
function NetPlan.invalidate() S.net_plan_next=-math.huge end
function NetPlan.update(units,target,force)
    if not force and S.net_plan and S.net_plan.target==target and S.now<(S.net_plan_next or -math.huge) then return S.net_plan end
    S.net_plan_next=S.now+Perf.interval("plan")
    local plan={target=target,steps={},reserved={},status="Сетки выключены",created=S.now}
    S.net_plan=plan
    if not UI.get("combo_net") or not Combat.target_valid(target) then return plan end
    if A.state(target,"MODIFIER_STATE_DEBUFF_IMMUNE") or A.state(target,"MODIFIER_STATE_MAGIC_IMMUNE") then
        plan.status="Цель невосприимчива к сетке";return plan
    end
    local pool={}
    local cover=S.now+A.control_remaining(target,S.now)
    local pending=S.net_pending
    if pending and pending.target==target and S.now<=pending.arrival+.45 then
        cover=math.max(cover,pending.arrival+NetPlan.duration(pending.ability,target))
        plan.pending=true
    end
    for _,u in ipairs(units) do
        local ab=A.spell(u,"meepo_earthbind")
        local cd=ab and A.call(Ability.GetCooldown,ab)
        local cost=ab and A.call(Ability.GetManaCost,ab)
        local mana=A.call(NPC.GetMana,u)
        local lvl=ab and A.call(Ability.GetLevel,ab)
        if A.alive(u) and not A.manual(u) and type(cd)=="number" and cd==cd and cd>=0
            and type(cost)=="number" and cost==cost and cost>=0 and type(mana)=="number" and mana>=cost
            and type(lvl)=="number" and lvl>=1 and not A.disabled(u,false)
            and A.call(Ability.IsHidden,ab)~=true and A.call(Ability.IsActivated,ab)~=false then
            local owner=A.call(Ability.GetOwner,ab)
            if not owner or A.id(owner)==A.id(u) then
                local busy_until=S.now
                local lock=S.locks[A.id(u)]
                if lock then busy_until=math.max(busy_until,lock.until_time or S.now) end
                local current=A.call(NPC.GetChannellingAbility,u)
                if current and A.call(Ability.IsChannelling,current)==true then busy_until=S.now+8 end
                local poof=A.spell(u,"meepo_poof")
                if poof and A.call(Ability.IsInAbilityPhase,poof)==true then
                    local finish=A.call(Ability.GetCastStartTime,poof)
                    busy_until=math.max(busy_until,type(finish)=="number" and finish>S.now and finish+.1 or S.now+A.poof_time(poof)+.1)
                end
                pool[#pool+1]={unit=u,ability=ab,ready=math.max(S.now+cd,busy_until),mana=mana,cost=cost,
                    cooldown=A.number(A.call(Ability.GetCooldownLength,ab),0)}
            end
        end
    end
    local first_gap=nil
    for index=1,UI.get("net_plan_steps") do
        local best=nil
        for _,entry in ipairs(pool) do
            if entry.mana>=entry.cost and entry.ready<S.now+18 then
                local point=Combat.predict(target,math.max(0,cover-S.now))
                local origin=A.pos(entry.unit)
                if A.valid_position(point) and A.distance(origin,point)<=A.range(entry.unit,entry.ability,700) then
                    local cast=math.max(0,A.number(A.call(Ability.GetCastPoint,entry.ability,true),.3))
                    local turn=math.max(0,math.min(.65,A.number(A.call(NPC.GetTimeToFacePosition,entry.unit,point),0)))
                    local eta=turn+cast+A.distance(origin,point)/math.max(1,A.net_speed(entry.ability))
                    local launch=math.max(S.now,entry.ready,cover-UI.get("net_overlap_ms")/1000-eta-.04)
                    local arrival=launch+eta
                    if not best or arrival<best.arrival-.001 or (math.abs(arrival-best.arrival)<=.001 and tostring(A.id(entry.unit))<tostring(A.id(best.unit))) then
                        best={unit=entry.unit,ability=entry.ability,launch=launch,arrival=arrival,eta=eta,cast=cast,entry=entry,pos=point}
                    end
                end
            end
        end
        if not best then break end
        local gap=math.max(0,best.arrival-cover)
        if (index>1 or cover>S.now+.05) and gap>.18 and not first_gap then first_gap={at=cover,duration=gap} end
        best.duration=NetPlan.duration(best.ability,target)
        plan.steps[#plan.steps+1]=best
        local id=A.id(best.unit)
        if not plan.reserved[id] then plan.reserved[id]=best.launch end
        cover=best.arrival+best.duration
        best.entry.mana=best.entry.mana-best.entry.cost
        best.entry.ready=best.entry.cooldown>.05 and best.launch+best.cast+best.entry.cooldown or math.huge
    end
    plan.gap=first_gap
    if #plan.steps==0 then plan.status="Нет продолжения: мана / дальность / готовность"
    elseif first_gap then plan.status=string.format("Прогноз: разрыв %.1f с через %.1f с",first_gap.duration,math.max(0,first_gap.at-S.now))
    else plan.status=string.format("План: %d сетки · прогноз, не гарантия",#plan.steps) end
    if #plan.steps<UI.get("net_plan_steps") and #plan.steps>0 then
        plan.limited=true
        if not plan.gap then plan.status=string.format("Прогноз: после %d сеток нет продолжения",#plan.steps) end
    end
    return plan
end
function NetPlan.blocks(u,duration)
    local plan=S.net_plan
    if not plan or plan.target~=S.target or not UI.get("combo_net") then return false end
    local at=plan.reserved[A.id(u)]
    return at~=nil and at<=S.now+math.max(0,duration)+.20
end
function Emergency.begin()
    CampMap.state().open=false;S.camp_cancel={}
    if S.escape and S.escape.active then return end
    S.escape={active=true,latched=true,started=S.now,status={},next_attempt={},needs_stop={}}
    for _,u in ipairs(S.units) do S.escape.needs_stop[A.id(u)]=true end
    UI.set("farm_enabled",false)
    S.combo_active=false;S.combo_blocked=true;S.assignment,S.parking,S.rune_claims,S.rune_busy={},{},{},{}
    S.orders,S.order_next,S.attack_commit={},{},{}
    S.manual_until={}
    Stack.cancel_all("Аварийный отход")
    Combat.release("Аварийный отход · F9 — вернуть управление")
    Trace.add(nil,"ОТХОД","Обычная автоматика заблокирована")
end
function Emergency.resume()
    S.key_pending.farm_key,S.key_pending.poof_cursor_key,S.key_pending.poof_self_key=nil,nil,nil
    S.combo_edge_pending=nil
    S.escape={active=false,latched=false,status={},next_attempt={}}
    S.combo_blocked=UI.down("combo_key");S.combo_was_down=S.combo_blocked
    S.orders,S.order_next={},{}
    Combat.release("Готов · фарм включается отдельно F6")
    Trace.add(nil,"ГОТОВ","Выход из аварийного режима; фарм не включён")
end
function Emergency.safe(pos,radius)
    return A.valid_position(pos) and World.fresh() and A.enemy_count_at(pos,radius or 1200)==0
        and not Farm.under_tower(pos) and Farm.safe_position(pos,radius or 1200,false)
end
function Emergency.point(u)
    local base=Farm.fountain()
    if A.valid_position(base) then return base end
    local from=A.pos(u);if not A.valid_position(from) then return nil end
    local enemy,dist=nil,math.huge
    for _,h in ipairs(S.heroes or {}) do
        if A.enemy(h) then local d=A.distance(from,A.pos(h));if d<dist then enemy,dist=h,d end end
    end
    if enemy then
        local p=A.pos(enemy);local dx,dy=from.x-p.x,from.y-p.y;local length=math.max(1,math.sqrt(dx*dx+dy*dy))
        return A.vec(from.x+dx/length*1800,from.y+dy/length*1800,from.z)
    end
    return nil
end
function Emergency.cast(u,ab,target,pos,tag,hold,item)
    if not ab or not A.ready(u,ab,item) then return false end
    if item and A.call(Item and Item.IsItemEnabled,ab)==false then return false end
    if item and A.call(Item and Item.RequiresCharges,ab)==true and A.number(A.call(Item.GetCurrentCharges,ab),0)<=0 then return false end
    if Orders.cast(u,ab,target,pos,120,"отход:"..tag,hold or .35,item) then
        S.escape.status[A.id(u)]=tag
        return true
    end
    return false
end
function Emergency.unit(u)
    local id=A.id(u);local state=S.escape
    if A.manual(u) then state.status[id]="Ручное управление";return false end
    if Orders.busy(u,120,S.now) then state.status[id]="Применение / защищённый канал";return false end
    if state.needs_stop and state.needs_stop[id] then
        if Orders.issue(u,"DOTA_UNIT_ORDER_STOP",nil,nil,nil,120,"отход-отменить-старый-приказ") then
            state.needs_stop[id]=nil;state.status[id]="Прежний приказ отменён"
        end
        return false
    end
    local point=Emergency.point(u);local origin=A.pos(u)
    if not point then state.status[id]="Нет достоверной точки отхода";return false end
    local enemies=A.enemy_count_at(origin,1000)
    if A.distance(origin,point)<900 and enemies==0 then state.status[id]="У базы";return true end
    local dig=A.spell(u,"meepo_petrify")
    if A.hp(u)<45 and enemies>0 and Emergency.cast(u,dig,nil,nil,"Dig — переждать урон",1.1,false) then return false end
    for _,name in ipairs({"item_black_king_bar","item_manta","item_glimmer_cape","item_shadow_blade","item_silver_edge","item_invis_sword"}) do
        local useful=enemies>0 and (name~="item_manta" or A.hp(u)<65 or A.state(u,"MODIFIER_STATE_ROOTED") or A.state(u,"MODIFIER_STATE_SILENCED"))
        local ab=useful and A.item(u,name)
        local self_target=name=="item_glimmer_cape" and u or nil
        if ab and not A.state(u,"MODIFIER_STATE_INVISIBLE") and not (name=="item_black_king_bar" and A.state(u,"MODIFIER_STATE_DEBUFF_IMMUNE"))
            and Emergency.cast(u,ab,self_target,nil,"Защита: "..name,.3,true) then return false end
    end
    for _,name in ipairs({"item_blink","item_overwhelming_blink","item_arcane_blink","item_swift_blink"}) do
        local ab=A.item(u,name)
        if ab and A.ready(u,ab,true) then
            local distance=A.distance(origin,point);local length=math.min(A.range(u,ab,1200)-40,distance)
            local p=A.vec(origin.x+(point.x-origin.x)*length/math.max(1,distance),origin.y+(point.y-origin.y)*length/math.max(1,distance),origin.z)
            if length>300 and Emergency.safe(p,1000) and Emergency.cast(u,ab,nil,p,"Blink к безопасности",.25,true) then return false end
        end
    end
    local safe,score=nil,-math.huge
    for _,other in ipairs(S.units) do
        if other~=u and not A.manual(other) and not A.has(other,"modifier_meepo_petrify")
            and not A.state(other,"MODIFIER_STATE_OUT_OF_GAME") and A.hp(other)>45 and A.distance(origin,A.pos(other))>1100
            and Emergency.safe(A.pos(other),1300) then
            local gain=A.distance(origin,point)-A.distance(A.pos(other),point)
            if gain>700 and gain>score then safe,score=other,gain end
        end
    end
    if safe and Emergency.cast(u,A.spell(u,"meepo_poof"),safe,nil,"Poof к безопасному Мипо",A.poof_time(A.spell(u,"meepo_poof"))+.2,false) then return false end
    if UI.get("escape_tp") and A.valid_position(S.fountain) and Emergency.safe(origin,1100)
        and S.now>=(state.next_attempt[id] or -math.huge) then
        local tp=A.call(NPC.GetItem,u,"item_tpscroll",false)
        if tp and Emergency.cast(u,tp,nil,S.fountain,"TP на базу",4.0,true) then
            state.next_attempt[id]=S.now+1;return false
        end
    end
    if enemies>0 and S.now>=(state.net_next or -math.huge) then
        local pursuer,distance=nil,900
        for _,h in ipairs(S.heroes) do
            if A.enemy(h) and not A.state(h,"MODIFIER_STATE_DEBUFF_IMMUNE") and not A.state(h,"MODIFIER_STATE_MAGIC_IMMUNE") and A.root_remaining(h,S.now)<.25 then
                local d=A.distance(origin,A.pos(h));if d<distance then pursuer,distance=h,d end
            end
        end
        local net=A.spell(u,"meepo_earthbind")
        if pursuer and net and distance<=A.range(u,net,700) then
            local p=Combat.predict(pursuer,.3+distance/math.max(1,A.net_speed(net)))
            if A.valid_position(p) and A.distance(origin,p)<=A.range(u,net,700)
                and Emergency.cast(u,net,nil,p,"Сетка преследователю",.6,false) then state.net_next=S.now+.7;return false end
        end
    end
    local force=A.item(u,"item_force_staff")
    local rotation=A.call(Entity.GetRotation,u);local forward=rotation and A.method(rotation,"GetForward")
    if force and forward then
        local dist=A.distance(origin,point)
        if dist>0 and (forward.x*(point.x-origin.x)+forward.y*(point.y-origin.y))/dist>.7
            and Emergency.safe(A.vec(origin.x+forward.x*600,origin.y+forward.y*600,origin.z),1000)
            and Emergency.cast(u,force,u,nil,"Force Staff к базе",.3,true) then return false end
    end
    Orders.walk(u,point,120,"отход-пешком")
    state.status[id]="Отход пешком";return false
end
function Emergency.tick()
    local all_safe=#S.units>0
    for _,u in ipairs(S.units) do if not Emergency.unit(u) then all_safe=false end end
    if all_safe then S.escape.active=false;Trace.add(nil,"ОТХОД","Группа у базы; автоматика остаётся заблокирована") end
    S.combo_status=S.escape.active and "АВАРИЙНЫЙ ОТХОД · F9 — отмена" or "ОТХОД ЗАВЕРШЁН · F9 — готовность"
end

function M.Diagnostics()
    return {version=M.VERSION,last_error=S.last_error,last_api_error=S.last_api_error,
        api_errors=S.api_errors,metrics=S.metrics,combo_blocked=S.combo_blocked}
end

-- V9.1: camp mask / modal map / explicit, reversible RAGE preset.
function CampMap.state()
    if not S.camp_map then S.camp_map={open=false,enabled={},consumed={},revision=0} end
    S.camp_cancel=S.camp_cancel or {}
    return S.camp_map
end
function CampMap.key(pos,box)
    local function q(n)return math.floor(n/32+.5) end
    local w=box and math.abs(box.max.x-box.min.x) or 0
    local h=box and math.abs(box.max.y-box.min.y) or 0
    return q(pos.x)..":"..q(pos.y)..":"..q(w)..":"..q(h)
end
function CampMap.config_key(camp)
    return "campmask_v1:"..tostring(S.camp_epoch or 0)..":"..tostring(S.team or 0)..":"..camp.map_key
end
function CampMap.own(camp)
    if not camp or not A.valid_position(camp.pos) then return false end
    local radiant=A.enum("TeamNum","TEAM_RADIANT") or 2
    local lower=camp.pos.x+camp.pos.y<0
    return S.team==radiant and lower or S.team~=radiant and not lower
end
function CampMap.selected(camp)
    if not camp or not camp.map_key then return false end
    local st=CampMap.state();local key=CampMap.config_key(camp)
    if st.enabled[key]==nil then
        local v=A.call(Config and Config.ReadInt,M.CONFIG_NAME,key,-1)
        st.enabled[key]=v==1 or (v~=0 and v~=1 and (UI.get("farm_side")==1 or CampMap.own(camp)))
    end
    return st.enabled[key]
end
function CampMap.allowed(camp)
    if UI.get("camp_filter") then return CampMap.selected(camp) end
    return UI.get("farm_side")==1 or CampMap.own(camp)
end
function CampMap.invalidate()
    local st=CampMap.state();st.revision=st.revision+1;st.layout=nil
    S.econ_next,S.farm_next,S.hud_next=-math.huge,-math.huge,-math.huge
    S.econ_plan,S.econ_route_cache={},{}
    for id,rec in pairs(S.assignment) do
        local invalid_route=rec.kind=="neutral" and UI.get("farm_strategy")==2
            or rec.kind=="lane" and UI.get("farm_strategy")==0 or rec.kind=="push"
        if invalid_route then
            S.camp_cancel[id]=true;Stack.cancel(id,"Изменён маршрут")
            S.assignment[id],S.econ_watch[id],S.parking[id]=nil,nil,nil
        elseif rec.kind=="neutral" then
            local camp=Farm.find_camp(rec.camp)
            if not camp or not CampMap.allowed(camp) then
                S.camp_cancel[id]=true
                Stack.cancel(id,"Кемп исключён на карте")
                S.assignment[id],S.econ_watch[id],S.parking[id]=nil,nil,nil
            end
        end
    end
    for id,state in pairs(S.stack_units) do
        local camp=Farm.find_camp(state.camp)
        if not camp or not CampMap.allowed(camp) then Stack.cancel(id,"Кемп исключён на карте");S.camp_cancel[id]=true end
    end
    for id,claim in pairs(S.stack_claims) do
        local camp=Farm.find_camp(id)
        if not camp or not CampMap.allowed(camp) then S.stack_claims[id]=nil end
    end
end
function CampMap.set(camp,value,defer)
    if not camp or not camp.map_key then return false end
    local st=CampMap.state();local key=CampMap.config_key(camp)
    value=value==true
    if CampMap.selected(camp)==value then return false end
    st.enabled[key]=value;A.call(Config and Config.WriteInt,M.CONFIG_NAME,key,value and 1 or 0)
    if not defer then CampMap.invalidate() end
    return true
end
function CampMap.batch(mode)
    local changed=false
    for _,camp in ipairs(S.camps) do
        local value=mode=="all" or (mode=="own" and CampMap.own(camp))
        if CampMap.set(camp,value,true) then changed=true end
    end
    if changed then CampMap.invalidate() end
end
function CampMap.toggle(value)
    if not S.session then return false end
    local st=CampMap.state()
    st.open=value==nil and not st.open or value==true
    S.combo_active=false;S.combo_edge_pending=nil
    S.combo_blocked=UI.down("combo_key");S.combo_was_down=S.combo_blocked
    S.key_pending.farm_key,S.key_pending.poof_cursor_key,S.key_pending.poof_self_key=nil,nil,nil
    Combat.release(st.open and "Выбор кемпов · автоматика на паузе" or "Карта закрыта · комбо — новым нажатием")
    S.hud_next=-math.huge
    if st.open then
        Farm.refresh_camps()
        for id in pairs(S.orders) do S.camp_cancel[id]=true end
    end
end
function CampMap.cancel_tick()
    for _,u in ipairs(S.units) do
        local id=A.id(u)
        if S.camp_cancel and S.camp_cancel[id] then
            if A.manual(u) then S.camp_cancel[id]=nil
            elseif not Orders.busy(u,110,S.now) and not S.locks[id]
                and Orders.issue(u,"DOTA_UNIT_ORDER_STOP",nil,nil,nil,110,"карта-отмена-задания") then
                S.camp_cancel[id]=nil;S.orders[id]=nil
            end
        end
    end
end
function CampMap.reset_selection()
    S.camp_epoch=(S.camp_epoch or 0)+1
    A.call(Config and Config.WriteInt,M.CONFIG_NAME,"camp_mask_generation",S.camp_epoch)
    local st=CampMap.state();st.enabled={};CampMap.invalidate()
end
function CampMap.layout()
    local st=CampMap.state();local screen=A.call(Render and Render.ScreenSize)
    if not screen or not screen.x or not screen.y or screen.x<720 or screen.y<540 then return nil end
    local signature=screen.x..":"..screen.y..":"..(S.camps_version or 0)..":"..st.revision
    if st.layout and st.layout.signature==signature then return st.layout end
    local side=math.min(650,screen.y-210,screen.x-390)
    local w,h=side+310,side+160
    local l={signature=signature,x=(screen.x-w)/2,y=(screen.y-h)/2,w=w,h=h,side=side,points={},buttons={}}
    l.mx,l.my=l.x+20,l.y+86;l.rx=l.mx+side+24;l.rw=246
    local bound=8500
    for _,camp in ipairs(S.camps) do bound=math.max(bound,math.abs(camp.pos.x)+700,math.abs(camp.pos.y)+700) end
    l.bound=bound
    for i,camp in ipairs(S.camps) do
        l.points[#l.points+1]={camp=camp,n=i,x=l.mx+side*(camp.pos.x+bound)/(2*bound),y=l.my+side*(bound-camp.pos.y)/(2*bound)}
    end
    -- Declutter hit targets, but retain anchors to the actual world coordinates.
    -- Computed only when the cached geometry changes, never per mouse event.
    local placed={}
    for _,point in ipairs(l.points) do
        point.ax,point.ay=point.x,point.y
        local found=false
        for ring=0,12 do
            local count=ring==0 and 1 or ring*8
            for j=0,count-1 do
                local angle=j*math.pi*2/count
                local x=math.max(l.mx+14,math.min(l.mx+side-14,point.ax+math.cos(angle)*ring*16))
                local y=math.max(l.my+14,math.min(l.my+side-14,point.ay+math.sin(angle)*ring*16))
                local free=true
                for _,old in ipairs(placed) do if (old.x-x)^2+(old.y-y)^2<30*30 then free=false;break end end
                if free then point.x,point.y=x,y;found=true;break end
            end
            if found then break end
        end
        placed[#placed+1]=point
    end
    local names={{"all","Все кемпы"},{"none","Снять все"},{"own","Своя половина"},{"neutral","Только нейтралы"}}
    for i,v in ipairs(names) do l.buttons[#l.buttons+1]={id=v[1],text=v[2],x=l.rx,y=l.my+90+(i-1)*48,w=l.rw,h=40} end
    l.buttons[#l.buttons+1]={id="close",text="Закрыть",x=l.x+l.w-114,y=l.y+20,w=94,h=40}
    st.layout=l;return l
end
function CampMap.inside(x,y,b)return x>=b.x and x<=b.x+b.w and y>=b.y and y<=b.y+b.h end
function CampMap.hit(x,y,l)
    l=l or CampMap.layout();if not l then return nil end
    for _,b in ipairs(l.buttons) do if CampMap.inside(x,y,b) then return b.id end end
    local best,dist=nil,22*22
    for _,p in ipairs(l.points) do local d=(p.x-x)^2+(p.y-y)^2;if d<dist then best,dist=p,d end end
    return best and "camp" or nil,best
end
function CampMap.key_event(data)
    if type(data)~="table" then return true end
    local st=CampMap.state();local down=A.enum("EKeyEvent","EKeyEvent_KEY_DOWN");local up=A.enum("EKeyEvent","EKeyEvent_KEY_UP")
    if data.event==up and st.consumed[data.key] then st.consumed[data.key]=nil;return false end
    if not S.session or not st.open or UI.input_captured() then return true end
    local left=A.enum("ButtonCode","KEY_MOUSE1");local right=A.enum("ButtonCode","KEY_MOUSE2")
    local esc=A.enum("ButtonCode","KEY_ESCAPE")
    if data.key==esc then
        if data.event==down then CampMap.toggle(false);st.consumed[data.key]=true end
        return false
    end
    if data.key~=left and data.key~=right then return true end
    if data.event==down then
        if st.consumed[data.key] then return false end
        st.consumed[data.key]=true
        if data.key==left then
            local x,y=A.call(Input and Input.GetCursorPos)
            if type(x)=="number" and type(y)=="number" then
                local action,p=CampMap.hit(x,y)
                if action=="camp" then
                    if not UI.get("camp_filter") then UI.set("camp_filter",true) end
                    CampMap.set(p.camp,not CampMap.selected(p.camp))
                elseif action=="close" then CampMap.toggle(false)
                elseif action and action:match("^slot:") then
                    CampMap.state().role_slot=tonumber(action:match("(%d+)$"));CampMap.state().layout=nil
                elseif action and action:match("^role:") then
                    UI.set("role_"..(CampMap.state().role_slot or 1),tonumber(action:match("(%d+)$")))
                elseif action=="texture" then Atlas.fetch()
                elseif action=="neutral" then UI.set("farm_strategy",0)
                elseif action then
                    if not UI.get("camp_filter") then UI.set("camp_filter",true) end
                    CampMap.batch(action)
                end
            end
        end
    end
    return false -- modal: no left/right click may leak to the game, even outside the panel.
end
function CampMap.draw()
    local st=CampMap.state()
    if not st.open or not S.session or not HUD.prepare() then return end
    local l=CampMap.layout();if not l then return end
    local c=HUD.colors;local screen=A.call(Render.ScreenSize)
    HUD.rect(0,0,screen.x,screen.y,Color(7,12,20,180))
    HUD.rect(l.x,l.y,l.w,l.h,c.bg,10)
    HUD.text(l.x+20,l.y+22,HUD.fit("КАРТА ФАРМА  /  СЕВЕР ↑",24,l.w-154),c.text,24)
    HUD.text(l.x+20,l.y+55,"F7 / Esc — закрыть  ·  ЛКМ — разрешить или исключить кемп",c.muted,14)
    HUD.rect(l.mx,l.my,l.side,l.side,Color(25,40,48,255),6)
    local function project(x,y)return Vec2(l.mx+l.side*(x+l.bound)/(2*l.bound),l.my+l.side*(l.bound-y)/(2*l.bound))end
    local function line(a,b,color,width)A.call(Render.Line,project(a[1],a[2]),project(b[1],b[2]),color,width or 1)end
    for i=1,7 do
        local v=-l.bound+2*l.bound*i/8
        line({v,-l.bound},{v,l.bound},Color(45,60,68,255));line({-l.bound,v},{l.bound,v},Color(45,60,68,255))
    end
    local edge=l.bound*(1-28/l.side)
    line({-edge,edge},{edge,-edge},Color(48,85,104,255),12)
    local mx,my=A.call(Input and Input.GetCursorPos);local action,hover
    if type(mx)=="number" and type(my)=="number" then action,hover=CampMap.hit(mx,my,l) end
    local selected=0
    for _,p in ipairs(l.points) do
        local on=CampMap.selected(p.camp);if on then selected=selected+1 end
        local hovered=hover==p
        if math.abs(p.x-p.ax)+math.abs(p.y-p.ay)>3 then
            A.call(Render.Line,Vec2(p.ax,p.ay),Vec2(p.x,p.y),c.line,1)
            HUD.rect(p.ax-2,p.ay-2,4,4,c.muted,1)
        end
        HUD.rect(p.x-12,p.y-12,24,24,hovered and c.text or on and c.blue or c.line,5)
        HUD.rect(p.x-10,p.y-10,20,20,on and Color(45,106,155,255) or Color(30,39,53,255),4)
        local label=tostring(p.n);local tw=A.call(Render.TextSize,HUD.font,12,label)
        HUD.text(p.x-(tw and tw.x or #label*7)/2,p.y-7,label,on and c.text or c.muted,12)
    end
    HUD.text(l.rx,l.my,"ВЫБРАНО КЕМПОВ",c.muted,13)
    HUD.text(l.rx,l.my+25,selected.." / "..#l.points,c.blue,30)
    HUD.text(l.rx,l.my+65,UI.get("camp_filter") and "Фильтр карты включён" or "Фильтр карты выключен",UI.get("camp_filter") and c.green or c.warning,13)
    for _,b in ipairs(l.buttons) do
        HUD.rect(b.x,b.y,b.w,b.h,action==b.id and c.line or c.surface,5)
        HUD.text(b.x+12,b.y+11,b.text,c.text,14)
    end
    local y=l.my+294
    local lines={"Клик по номеру меняет выбор.","Синий — разрешён; серый — нет.","Разрешённый ≠ безопасный:","проверки угроз остаются.","Линии настраиваются отдельно.","F8 — аварийный отход."}
    if hover then
        lines={"Кемп №"..hover.n..(CampMap.selected(hover.camp) and " · РАЗРЕШЁН" or " · ИСКЛЮЧЁН"),
            string.format("X: %.0f   Y: %.0f",hover.camp.pos.x,hover.camp.pos.y),
            CampMap.own(hover.camp) and "Своя половина (геометрия)" or "Другая половина (геометрия)",
            "ЛКМ — переключить", "Данные спавнеров из API.","Наличие крипов не гарантируется."}
    end
    local max_lines=math.max(1,math.floor((l.side-294)/22))
    for i,text in ipairs(lines) do if i<=max_lines then HUD.text(l.rx,y+(i-1)*22,HUD.fit(text,13,l.rw),i==1 and c.text or c.muted,13) end end
    local footer=UI.input_captured() and "Закройте меню / чат, чтобы выбирать кемпы." or #l.points==0 and "Кемпы ещё не получены от API. Повторная попытка автоматически." or "Схема по реальным координатам. Это не текстура миникарты Dota."
    HUD.text(l.mx,l.my+l.side+18,HUD.fit(footer,14,l.w-40),#l.points==0 and c.warning or c.muted,14)
end
M.campmap=CampMap
M.OnKeyEvent=CampMap.key_event

Preset.values={combo_all=true,combo_net=true,combo_poof=true,combo_blink=true,combo_hex=true,
    combo_silence=true,combo_slow=true,combo_radius=600,combo_world_radius=1200,
    net_plan_steps=6,net_overlap_ms=180,gather_mode=0,poof_require_root=false,hex_mode=1,
    manual_mode=1,manual_pause_ms=500,perf_mode=3,farm_mode=1,farm_strategy=0,
    farm_poof=true,farm_min_creeps=1,farm_mana_pct=10,econ_enabled=true,econ_poof=true,
    econ_poof_save_ms=100,econ_travel_poof=true,econ_travel_save=1,
    items_enabled=true,items_offensive=true,items_defensive=true,hud_details=true}
function Preset.rage()return UI.get("work_preset")==1 end
function Preset.apply()
    local saved=A.call(Config and Config.ReadInt,M.CONFIG_NAME,"rage_backup_valid",0)==1
    Preset.backup=Preset.backup or {}
    for key,value in pairs(Preset.values) do
        if not saved and Preset.backup[key]==nil then
            local old=UI.get(key);Preset.backup[key]=old
            A.call(Config and Config.WriteInt,M.CONFIG_NAME,"rage_backup:"..key,type(old)=="boolean" and (old and 1 or 0) or old)
        end
        UI.set(key,value)
    end
    A.call(Config and Config.WriteInt,M.CONFIG_NAME,"rage_backup_valid",1)
    S.key_pending.farm_key,S.key_pending.poof_cursor_key,S.key_pending.poof_self_key=nil,nil,nil
    UI.set("farm_enabled",false)
    S.combo_active=false;S.combo_blocked=UI.down("combo_key");S.combo_edge_pending=nil
    S.next_logic,S.next_collect,S.net_plan_next,S.hud_next=-math.huge,-math.huge,-math.huge,-math.huge
    Combat.release("RAGE готов · комбо — удерживать; фарм — F6")
end
function Preset.restore()
    local saved=A.call(Config and Config.ReadInt,M.CONFIG_NAME,"rage_backup_valid",0)==1
    for key in pairs(Preset.values) do
        local old=Preset.backup and Preset.backup[key]
        if old==nil and saved then
            local v=A.call(Config and Config.ReadInt,M.CONFIG_NAME,"rage_backup:"..key,nil)
            if v~=nil then old=type(D[key])=="boolean" and v~=0 or type(D[key])~="boolean" and v or false end
        end
        if old~=nil then UI.set(key,old) end
    end
    Preset.backup=nil;A.call(Config and Config.WriteInt,M.CONFIG_NAME,"rage_backup_valid",0)
    S.key_pending.farm_key,S.key_pending.poof_cursor_key,S.key_pending.poof_self_key=nil,nil,nil
    UI.set("farm_enabled",false);S.combo_active=false;S.combo_blocked=UI.down("combo_key");S.combo_edge_pending=nil
    S.next_logic,S.next_collect,S.net_plan_next,S.hud_next=-math.huge,-math.huge,-math.huge,-math.huge
    Combat.release("Пользовательские настройки восстановлены · фарм выключен")
end
M.preset=Preset

-- ATLAS: roles are policy, not a second competing order controller.
Roles.names={"Авто","Кемпы","Древние","Стаки","Рядом с главным","Ручной"}
Roles.short={"AUTO","FARM","ANCIENT","STACK","ESCORT","MANUAL"}
function Roles.refresh()
    S.role_slots=S.role_slots or {};S.role_units=S.role_units or {}
    for _,u in ipairs(S.units) do
        local id=A.id(u)
        if u==S.hero then S.role_slots[id]=0
        elseif not S.role_slots[id] then
            for slot=1,6 do
                if not S.role_units[slot] then S.role_slots[id]=slot;S.role_units[slot]=u;break end
            end
        end
    end
end
function Roles.slot(u)
    if u==S.hero then return 0 end
    if not S.role_slots then Roles.refresh() end
    return S.role_slots[A.id(u)]
end
function Roles.get(u)
    local slot=Roles.slot(u)
    return slot and slot>0 and UI.get("role_"..slot) or 0
end
function Roles.label(u)
    return u==S.hero and "ГЛАВНЫЙ" or "КЛОН "..tostring(Roles.slot(u) or "?")
end
function Roles.forget(u)
    local id=A.id(u);local slot=S.role_slots and S.role_slots[id]
    if slot and slot>0 and S.role_units[slot]==u then S.role_units[slot]=nil end
    if S.role_slots then S.role_slots[id]=nil end
end
function Roles.changed(slot)
    if not S.session then return end
    local u=S.role_units and S.role_units[slot];local id=u and A.id(u)
    if id then
        local owned=S.orders[id]~=nil or S.assignment[id]~=nil or S.stack_units[id]~=nil
        Stack.cancel(id,"Изменена роль")
        S.assignment[id],S.econ_watch[id],S.parking[id],S.role_status[id]=nil,nil,nil,nil
        for cid,claim in pairs(S.stack_claims) do if claim.id==id then S.stack_claims[cid]=nil end end
        if owned then S.camp_cancel[id]=true end
    end
    S.econ_plan={};S.econ_next,S.farm_next,S.hud_next=-math.huge,-math.huge,-math.huge
    CampMap.state().layout=nil;NetPlan.invalidate()
end
function Roles.kind(camp)
    if not camp then return nil end
    S.camp_types=S.camp_types or {};S.camp_type_next=S.camp_type_next or {}
    if S.now<(S.camp_type_next[camp.id] or -math.huge) then return S.camp_types[camp.id] end
    S.camp_type_next[camp.id]=S.now+.25
    local visible=false;local ancient=false
    for _,u in ipairs(Farm.nearby(camp.pos,760)) do
        if A.visible(u) then visible=true;if A.call(NPC.IsAncient,u)==true then ancient=true end end
    end
    if visible then S.camp_types[camp.id]=ancient and "ancient" or "normal" end
    return S.camp_types[camp.id]
end
function Roles.camp_allowed(u,camp)
    local role=u and Roles.get(u) or 0
    if role==4 or role==5 then return false end
    if role==0 then return true end
    local kind=Roles.kind(camp)
    if role==2 then return kind=="ancient" end
    return kind~="ancient"
end
function Roles.task_allowed(u,task)
    local role=Roles.get(u)
    if role==0 then return true end
    if role==4 or role==5 then return false end
    return task and task.kind=="neutral" and Roles.camp_allowed(u,task.camp)
end
function Roles.wait_point(camp)
    if not camp.box then return nil end
    local box=camp.box
    local radius=math.max(math.abs(box.max.x-box.min.x),math.abs(box.max.y-box.min.y))*.5+140
    if radius>640 then return nil end
    for i=0,7 do
        local angle=i*math.pi/4
        local pos=A.vec(camp.pos.x+math.cos(angle)*radius,camp.pos.y+math.sin(angle)*radius,camp.pos.z)
        if Farm.outside_boxes(pos) and Farm.safe_position(pos,1200,false) then return pos end
    end
end
function Roles.step(u)
    local role=Roles.get(u);if role~=3 and role~=4 then return false end
    local id=A.id(u)
    if Orders.busy(u,35,S.now) then return true end
    if role==4 then
        S.role_status[id]="Рядом с главным"
        local main=S.hero
        if not A.alive(main) or main==u or A.manual(u) or A.state(main,"MODIFIER_STATE_OUT_OF_GAME") then return true end
        local target=A.pos(main)
        if not Farm.safe_position(target,1200,false) then S.role_status[id]="У главного опасно";return true end
        local dist=A.distance(A.pos(u),target)
        if dist>550 then Orders.walk(u,target,25,"роль-сопровождение")
        elseif dist<330 and S.orders[id] and S.orders[id].tag=="роль-сопровождение" then
            Orders.issue(u,"DOTA_UNIT_ORDER_STOP",nil,nil,nil,25,"роль-рядом")
        end
        return true
    end
    S.role_status[id]="Стаки · ожидание окна"
    if A.hp(u)<UI.get("stack_min_hp") then S.role_status[id]="Стаки · мало здоровья";return true end
    local rec=S.assignment[id];local camp=rec and rec.kind=="neutral" and Farm.find_camp(rec.camp)
    if camp and not Farm.available(camp,u) then
        Stack.cancel(id,"Кемп не соответствует роли");S.assignment[id],S.econ_watch[id]=nil,nil;camp=nil
    end
    if not camp then
        local best=math.huge
        for _,candidate in ipairs(S.camps) do
            local used=false
            for other,assignment in pairs(S.assignment) do if other~=id and assignment.camp==candidate.id then used=true;break end end
            if not used and Farm.available(candidate,u) and not Farm.under_tower(candidate.pos) then
                local distance=A.distance(A.pos(u),candidate.pos)
                if distance<best then camp,best=candidate,distance end
            end
        end
        if not camp then S.role_status[id]="Стаки · нет допустимого кемпа";return true end
        rec=Stable.bind(u,{kind="neutral",key="лагерь:"..camp.id,camp=camp,pos=camp.pos})
    end
    local task={kind="neutral",key="лагерь:"..camp.id,camp=camp,pos=camp.pos}
    rec.members=Farm.record_creeps(camp,rec)
    if Stack.tick(u,task,rec) then S.role_status[id]="Стаки · "..UI.phase_name(rec.phase);return true end
    -- No ordinary clearing/auto-attack outside the stacking window.
    local current=S.orders[id]
    if current and current.kind=="attack" then Orders.issue(u,"DOTA_UNIT_ORDER_STOP",nil,nil,nil,35,"роль-стак-пауза");return true end
    rec.role_wait=rec.role_wait or Roles.wait_point(camp)
    if rec.role_wait and A.distance(A.pos(u),rec.role_wait)>110 then Orders.walk(u,rec.role_wait,25,"роль-ожидание-стака") end
    if not rec.role_wait then S.role_status[id]="Стаки · нет безопасной точки" end
    return true
end
M.roles=Roles

-- Background resource: a real Valve map image, never a drawn imitation.
Atlas.MAP_URL="https://liquipedia.net/commons/images/9/9e/Gamemap_7.41_minimap_dota2_gameasset.png"
local info=debug and debug.getinfo and debug.getinfo(1,"S")
local path=info and info.source and info.source:match("^@(.+[/\\])") or ""
Atlas.map_path=path.."MeepoAtlas_map741.png"
Atlas.image_status="Фон Dota 7.41 · ещё не загружен"
function Atlas.valid_png(data)
    if type(data)~="string" or #data<64 or #data>4194304 or data:sub(1,8)~="\137PNG\r\n\26\n" or data:sub(13,16)~="IHDR" then return false end
    local ok,w,h=pcall(string.unpack,">I4I4",data,17)
    return ok and w>=64 and h>=64 and w<=4096 and h<=4096 and w==h
end
function Atlas.load_cached()
    if not Render or type(Render.LoadImage)~="function" or type(Render.ImageSize)~="function" then return false end
    local ok,handle=pcall(Render.LoadImage,Atlas.map_path)
    if not ok or type(handle)~="number" or handle<=0 then return false end
    local good,size=pcall(Render.ImageSize,handle)
    if good and size and size.x and size.y and size.x>=64 and size.y>=64 and math.abs(size.x-size.y)<2 then
        Atlas.image=handle;Atlas.image_status="Dota 7.41 · локальный фон";return true
    end
    return false
end
function Atlas.fetch()
    if Atlas.pending then return end
    Atlas.attempted=true
    if not HTTP or type(HTTP.Request)~="function" or not io or type(io.open)~="function" then
        Atlas.image_status="Нет HTTP / записи PNG. Добавьте фон вручную.";return
    end
    Atlas.pending=true;Atlas.image_status="Загрузка фона Dota…"
    local ok,sent=pcall(HTTP.Request,"GET",Atlas.MAP_URL,{timeout=15},function(response)
        Atlas.pending=false
        if type(response)~="table" or tonumber(response.code)~=200 or (response.error_code and response.error_code~=0)
            or not Atlas.valid_png(response.response) then
            Atlas.image_status="Фон не получен. Повторить или добавить PNG.";return
        end
        local opened,file=pcall(io.open,Atlas.map_path,"wb")
        if not opened or not file then Atlas.image_status="Не удалось сохранить фон рядом с Lua";return end
        local wrote,result=pcall(file.write,file,response.response);pcall(file.close,file)
        if not wrote or not result then Atlas.image_status="Ошибка записи PNG";return end
        Atlas.need_load=true
    end,"MeepoAtlas.static-map")
    if not ok or sent~=true then Atlas.pending=false;Atlas.image_status="HTTP-запрос фона недоступен" end
end
function Atlas.image_tick()
    if Atlas.need_load then Atlas.need_load=false;Atlas.load_cached() end
    if not Atlas.checked then
        Atlas.checked=true
        if not Atlas.load_cached() then Atlas.fetch() end
    end
end
function Atlas.colors()
    if not Atlas.palette then Atlas.palette={bg=Color(19,20,27,252),surface=Color(28,30,40,255),
        raised=Color(37,40,54,255),line=Color(57,61,80,255),text=Color(239,240,247,255),
        muted=Color(169,175,196,255),blue=Color(126,165,255,255),bluebg=Color(49,64,100,255),
        gold=Color(236,198,115,255),green=Color(130,204,169,255),warning=Color(242,175,118,255)} end
    return Atlas.palette
end
function Atlas.button(l,id,text,x,y,w,h,active)
    local c=Atlas.colors();HUD.rect(x,y,w,h,active and c.bluebg or c.surface,6)
    HUD.text(x+12,y+(h-14)/2,HUD.fit(text,14,w-24),active and c.blue or c.text,14)
    l.buttons[#l.buttons+1]={id=id,text=text,x=x,y=y,w=w,h=h}
end
function CampMap.layout()
    local st=CampMap.state();local screen=A.call(Render and Render.ScreenSize)
    if not screen or screen.x<960 or screen.y<720 then return nil end
    local side=math.min(650,screen.y-220,screen.x-470)
    local w,h=side+424,side+192
    local signature=screen.x..":"..screen.y..":"..(S.camps_version or 0)..":"..st.revision..":"..UI.get("atlas_extent")..":"..UI.get("atlas_offset_x")..":"..UI.get("atlas_offset_y")..":"..(st.role_slot or 1)
    if st.layout and st.layout.signature==signature then return st.layout end
    local l={signature=signature,x=(screen.x-w)/2,y=(screen.y-h)/2,w=w,h=h,side=side,points={},buttons={}}
    l.mx,l.my=l.x+20,l.y+104;l.rx=l.mx+side+24;l.rw=340;l.bound=UI.get("atlas_extent")
    local ox,oy=UI.get("atlas_offset_x"),UI.get("atlas_offset_y")
    for i,camp in ipairs(S.camps) do
        local x=l.mx+side*(camp.pos.x-ox+l.bound)/(2*l.bound)
        local y=l.my+side*(l.bound-(camp.pos.y-oy))/(2*l.bound)
        local p={camp=camp,n=i,ax=x,ay=y,x=math.max(l.mx+14,math.min(l.mx+side-14,x)),y=math.max(l.my+14,math.min(l.my+side-14,y))}
        p.clipped=x<l.mx or x>l.mx+side or y<l.my or y>l.my+side
        local ax,ay=p.x,p.y
        for ring=0,12 do
            local found=false;local count=ring==0 and 1 or ring*8
            for j=0,count-1 do
                local angle=j*math.pi*2/count
                local cx=math.max(l.mx+14,math.min(l.mx+side-14,ax+math.cos(angle)*ring*16))
                local cy=math.max(l.my+14,math.min(l.my+side-14,ay+math.sin(angle)*ring*16))
                local free=true;for _,old in ipairs(l.points) do if (old.x-cx)^2+(old.y-cy)^2<30*30 then free=false;break end end
                if free then p.x,p.y=cx,cy;found=true;break end
            end
            if found then break end
        end
        l.points[#l.points+1]=p
    end
    local bw=(side-16)/3
    for i,v in ipairs({{"all","Все кемпы"},{"none","Снять все"},{"own","Своя половина"}}) do l.buttons[#l.buttons+1]={id=v[1],text=v[2],x=l.mx+(i-1)*(bw+8),y=l.my+side+12,w=bw,h=38} end
    l.buttons[#l.buttons+1]={id="close",text="Закрыть",x=l.x+w-116,y=l.y+20,w=96,h=40}
    l.buttons[#l.buttons+1]={id="neutral",text="Только нейтралы",x=l.rx,y=l.my+side-42,w=162,h=36}
    l.buttons[#l.buttons+1]={id="texture",text="Загрузить фон",x=l.rx+170,y=l.my+side-42,w=170,h=36}
    for slot=1,6 do l.buttons[#l.buttons+1]={id="slot:"..slot,x=l.rx,y=l.my+28+(slot-1)*40,w=l.rw,h=36} end
    for role=0,5 do l.buttons[#l.buttons+1]={id="role:"..role,text=Roles.names[role+1],x=l.rx+(role%2)*174,y=l.my+296+math.floor(role/2)*40,w=166,h=36} end
    st.layout=l;return l
end
function CampMap.draw()
    local st=CampMap.state();if not st.open or not S.session or not HUD.prepare() then return end
    Atlas.image_tick();Roles.refresh()
    local l=CampMap.layout();local c=Atlas.colors();local screen=A.call(Render.ScreenSize)
    HUD.rect(0,0,screen.x,screen.y,Color(7,9,15,190))
    if not l then HUD.text(30,30,"ATLAS · нужен экран от 960 × 720. F7 / Esc — закрыть.",c.text,18);return end
    HUD.rect(l.x,l.y,l.w,l.h,c.bg,10)
    HUD.rect(l.x,l.y,3,l.h,c.blue,2)
    HUD.text(l.x+22,l.y+22,"MEEPO / ATLAS",c.text,24)
    HUD.text(l.x+22,l.y+57,"КАРТА КЕМПОВ  /  РОЛИ КЛОНОВ",c.muted,13)
    HUD.text(l.mx,l.my-23,"DOTA MAP",c.muted,13)
    HUD.text(l.rx,l.my,"КЛОНЫ / НАЗНАЧЕНИЯ",c.muted,13)
    HUD.rect(l.mx-1,l.my-1,l.side+2,l.side+2,c.line,6)
    if Atlas.image then
        A.call(Render.Image,Atlas.image,Vec2(l.mx,l.my),Vec2(l.side,l.side),Color(220,225,234,255),5)
    else
        HUD.rect(l.mx,l.my,l.side,l.side,c.surface,5)

    end
    local mx,my=A.call(Input and Input.GetCursorPos);local action,hover
    if type(mx)=="number" and type(my)=="number" then action,hover=CampMap.hit(mx,my,l) end
    local count=0
    for _,p in ipairs(l.points) do
        local on=CampMap.selected(p.camp);if on then count=count+1 end
        if not p.clipped and math.abs(p.x-p.ax)+math.abs(p.y-p.ay)>3 then A.call(Render.Line,Vec2(p.ax,p.ay),Vec2(p.x,p.y),c.blue,1) end
        HUD.rect(p.x-13,p.y-13,26,26,hover==p and c.text or on and c.gold or c.line,5)
        HUD.rect(p.x-11,p.y-11,22,22,on and Color(66,58,38,255) or Color(22,25,33,255),4)
        local text=tostring(p.n);local size=A.call(Render.TextSize,HUD.font,12,text)
        HUD.text(p.x-(size and size.x or #text*7)/2,p.y-7,text,on and c.gold or c.muted,12)
    end
    HUD.text(l.mx+l.side-130,l.my-23,"ВЫБРАНО "..count.." / "..#l.points,c.gold,13)
    local slot=st.role_slot or 1
    for _,b in ipairs(l.buttons) do
        local n=b.id:match("^slot:(%d+)$")
        if n then
            n=tonumber(n);local unit=S.role_units and S.role_units[n]
            HUD.rect(b.x,b.y,b.w,b.h,n==slot and c.bluebg or c.surface,5)
            HUD.text(b.x+12,b.y+9,"КЛОН "..n,n==slot and c.blue or c.text,14)
            local role=UI.get("role_"..n)
            HUD.text(b.x+94,b.y+9,HUD.fit(Roles.names[role+1]..(unit and "" or " · ожидается"),14,b.w-106),c.muted,14)
        else
            local r=b.id:match("^role:(%d+)$")
            HUD.rect(b.x,b.y,b.w,b.h,r and tonumber(r)==UI.get("role_"..slot) and c.bluebg or action==b.id and c.raised or c.surface,5)
            HUD.text(b.x+12,b.y+(b.h-14)/2,HUD.fit(b.text,14,b.w-24),r and tonumber(r)==UI.get("role_"..slot) and c.blue or c.text,14)
        end
    end
    HUD.text(l.rx,l.my+278,"РОЛЬ ВЫБРАННОГО КЛОНА",c.muted,13)
    local desc=not Atlas.image and Atlas.image_status or UI.input_captured() and "Закройте штатное меню для выбора." or hover and string.format("Кемп %d · X %.0f / Y %.0f",hover.n,hover.camp.pos.x,hover.camp.pos.y) or "ЛКМ — кемп · справа — роль клона"
    HUD.text(l.mx,l.my+l.side+63,HUD.fit(desc,13,l.w-40),c.muted,13)
    HUD.text(l.rx,l.my+426,"Ручной — без комбо; F8 — все.",c.muted,13)
end
M.atlas=Atlas

UI.init()
if Preset.rage() then Preset.apply() end
UI.sync_farm_bind()
A.log("MEEPO ATLAS 9.2 · F7: карта и роли · Space: комбо · F8: отход · F9: разблокировать · F6: фарм",true)
return M
