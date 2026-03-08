_addon.name     = 'dailytask'
_addon.author   = 'Fever'
_addon.version  = '1.0'
_addon.commands = {'dailytask','dtask'}

require('luau')
local config = require('config')
local texts  = require('texts')

-------------------------------------------------
-- DEFAULT SETTINGS
-------------------------------------------------
local defaults = {
    visible = true,
    debug = false,
    pos = {x = 500, y = 250},

    ui = {
        title = 'Daily Tasks',
        font = 'Consolas',
        size = 12,
        alpha = 255,
        red = 255,
        green = 255,
        blue = 255,

        stroke = {
            width = 2,
            alpha = 200,
            red = 0,
            green = 0,
            blue = 0,
        },

        background = {
            visible = true,
            alpha = 160,
            red = 0,
            green = 0,
            blue = 0,
        },

        padding = 8,
    },

    tasks = {
        chest = {area=''},
        kill  = {area='', qty='', mob=''},
        craft = {item=''},
        nm    = {area='', mob=''},
        item  = {area='', item=''},
    }
}

local settings = config.load(defaults)

-------------------------------------------------
-- FORWARD DECLARATIONS
-------------------------------------------------
local refresh

-------------------------------------------------
-- HELPERS
-------------------------------------------------
local function trim(s)
    if not s then return '' end
    return tostring(s):gsub('^%s+',''):gsub('%s+$','')
end

local function safe(v)
    return trim(v or '')
end

local function msg(text,color)
    windower.add_to_chat(color or 207,'[dailytask] '..text)
end

local function save_settings()
    config.save(settings)
end

local function pad_right(str,width)
    str = tostring(str or '')
    if #str >= width then return str end
    return str..string.rep(' ',width-#str)
end

-------------------------------------------------
-- TITLE CASE
-------------------------------------------------
local function title_case_words(s)

    s = trim(s)
    if s == '' then return '' end

    local small_words = {
        ['a']=true,['an']=true,['and']=true,['as']=true,['at']=true,
        ['but']=true,['by']=true,['for']=true,['from']=true,['in']=true,
        ['nor']=true,['of']=true,['on']=true,['or']=true,['the']=true,
        ['to']=true,['up']=true,['with']=true,
    }

    local out={}
    local index=0

    for word in s:lower():gmatch('%S+') do
        index=index+1

        local prefix,core,suffix = word:match("^([^%a']*)([%a']+)([^%a']*)$")

        if not core then
            out[#out+1]=word
        else

            local lowered=core:lower()

            if index>1 and small_words[lowered] then
                out[#out+1]=(prefix or '')..lowered..(suffix or '')
            else
                out[#out+1]=(prefix or '')..
                    lowered:gsub("^%l",string.upper)..
                    (suffix or '')
            end
        end
    end

    return table.concat(out,' ')
end

-------------------------------------------------
-- ENSURE TASK STRUCTURE
-------------------------------------------------
local function ensure_tasks()

    settings.tasks = settings.tasks or {}

    settings.tasks.chest = settings.tasks.chest or {}
    settings.tasks.kill  = settings.tasks.kill  or {}
    settings.tasks.craft = settings.tasks.craft or {}
    settings.tasks.nm    = settings.tasks.nm    or {}
    settings.tasks.item  = settings.tasks.item  or {}

    settings.tasks.chest.area = settings.tasks.chest.area or ''

    settings.tasks.kill.area = settings.tasks.kill.area or ''
    settings.tasks.kill.qty  = settings.tasks.kill.qty or ''
    settings.tasks.kill.mob  = settings.tasks.kill.mob or ''

    settings.tasks.craft.item = settings.tasks.craft.item or ''

    settings.tasks.nm.area = settings.tasks.nm.area or ''
    settings.tasks.nm.mob  = settings.tasks.nm.mob or ''

    settings.tasks.item.area = settings.tasks.item.area or ''
    settings.tasks.item.item = settings.tasks.item.item or ''

end

-------------------------------------------------
-- DISPLAY
-------------------------------------------------
local function build_display()

    ensure_tasks()

    local t = settings.tasks
    local out = {}

    local chest_value = safe(t.chest.area)
    local kill_area   = safe(t.kill.area)
    local kill_qty    = safe(t.kill.qty)
    local kill_mob    = safe(t.kill.mob)
    local craft_item  = safe(t.craft.item)
    local nm_area     = safe(t.nm.area)
    local nm_mob      = safe(t.nm.mob)
    local item_area   = safe(t.item.area)
    local item_name   = safe(t.item.item)

    local kill_value = trim((kill_qty ~= '' and (kill_qty .. " ") or "") .. kill_mob)

    -- Dynamic zone column width
    local zone_width = 4  -- minimum to fit "Zone"
    local zone_values = {
        chest_value,
        kill_area,
        "--",
        nm_area,
        item_area,
    }

    for i = 1, #zone_values do
        local len = #tostring(zone_values[i] or '')
        if len > zone_width then
            zone_width = len
        end
    end

    -- Add a little extra spacing between Zone and Objective columns
    zone_width = zone_width + 4

    table.insert(out, settings.ui.title)
    table.insert(out, "")

    table.insert(out,
        pad_right("", 8) ..
        pad_right("Zone", zone_width) ..
        "Objective"
    )

    table.insert(out,
        pad_right("", 8) ..
        pad_right("----", zone_width) ..
        "---------"
    )

    table.insert(out,
        pad_right("Chest:", 8) ..
        chest_value
    )

    table.insert(out,
        pad_right("Kill:", 8) ..
        pad_right(kill_area, zone_width) ..
        kill_value
    )

    table.insert(out,
        pad_right("Craft:", 8) ..
        pad_right("--", zone_width) ..
        craft_item
    )

    table.insert(out,
        pad_right("NM:", 8) ..
        pad_right(nm_area, zone_width) ..
        nm_mob
    )

    table.insert(out,
        pad_right("Item:", 8) ..
        pad_right(item_area, zone_width) ..
        item_name
    )

    return table.concat(out, "\n")
end

-------------------------------------------------
-- REFRESH
-------------------------------------------------
refresh = function()

    task_box:text(build_display())

    if settings.visible then
        task_box:show()
    else
        task_box:hide()
    end

end

-------------------------------------------------
-- CLEAR
-------------------------------------------------
local function clear_all_tasks()

    ensure_tasks()

    settings.tasks.chest.area=''

    settings.tasks.kill.area=''
    settings.tasks.kill.qty=''
    settings.tasks.kill.mob=''

    settings.tasks.craft.item=''

    settings.tasks.nm.area=''
    settings.tasks.nm.mob=''

    settings.tasks.item.area=''
    settings.tasks.item.item=''

    save_settings()
    refresh()

end

-------------------------------------------------
-- TEXT NORMALIZATION
-------------------------------------------------
local function normalize_text(line)

    if not line then return '' end
    line=tostring(line)

    line=line:gsub('：',':')
    line=line:gsub('%s+',' ')

    return trim(line)

end

local function strip_speaker(line)

    local speaker,text=line:match('^([^:]+)%s*:%s*(.+)$')

    if speaker and text then
        return trim(speaker),trim(text)
    end

    return nil,line

end

-------------------------------------------------
-- PARSERS
-------------------------------------------------
local function parse_fishstix(text)

    local area=text:match('Go to (.-), find and open my Secret Treasure Chest')

    if area then
        settings.tasks.chest.area=trim(area)
        return true,'Chest updated: '..area
    end

end

local function parse_murdox(text)

    local area,qty,mob=text:match('Go to (.-) and kill (%d+) (.-)!')

    if area then
        settings.tasks.kill.area=trim(area)
        settings.tasks.kill.qty=trim(qty)
        settings.tasks.kill.mob=trim(mob)
        return true
    end

end

local function parse_mistrix(text)

    local item=text:match('Craft me up a signed (.-) and trade it')

    if item then
        settings.tasks.craft.item=title_case_words(item)
        return true
    end

end

local function parse_saltlix(text)

    local area,mob=text:match('Go to (.-) and kill (.-)!')

    if area then
        settings.tasks.nm.area=trim(area)
        settings.tasks.nm.mob=title_case_words(mob)
        return true
    end

end

local function parse_beetrix(text)

    local area,item=text:match('Go to (.-), get a (.-) and trade')

    if area then
        settings.tasks.item.area=trim(area)
        settings.tasks.item.item=title_case_words(item)
        return true
    end

end

-------------------------------------------------
-- TEXT OBJECT
-------------------------------------------------
task_box=texts.new('',{
    pos=settings.pos,
    text={
        font=settings.ui.font,
        size=settings.ui.size,
        alpha=settings.ui.alpha,
        red=settings.ui.red,
        green=settings.ui.green,
        blue=settings.ui.blue,
        stroke=settings.ui.stroke
    },
    bg=settings.ui.background,
    flags={draggable=true},
    padding=settings.ui.padding
})

-------------------------------------------------
-- EVENTS
-------------------------------------------------
windower.register_event('load',function()
    refresh()
end)

windower.register_event('login',function()
    refresh()
end)

windower.register_event('unload',function()
    save_settings()
end)

windower.register_event('incoming text',function(original,modified)

    local line=modified or original
    if not line then return end

    local clean=normalize_text(line)

    local speaker,text=strip_speaker(clean)
    if not speaker then return end

    local s=speaker:lower()

    local updated=false

    if s:find('fishstix') then
        updated=parse_fishstix(text)
    elseif s:find('murdox') then
        updated=parse_murdox(text)
    elseif s:find('mistrix') then
        updated=parse_mistrix(text)
    elseif s:find('saltlix') then
        updated=parse_saltlix(text)
    elseif s:find('beetrix') then
        updated=parse_beetrix(text)
    end

    if updated then
        save_settings()
        refresh()
    end

end)

-------------------------------------------------
-- COMMANDS
-------------------------------------------------
windower.register_event('addon command',function(cmd,...)

    cmd=cmd and cmd:lower() or 'help'
    local args={...}

    if cmd=='show' then
        settings.visible=true
        save_settings()
        refresh()

    elseif cmd=='hide' then
        settings.visible=false
        save_settings()
        refresh()

    elseif cmd=='toggle' then
        settings.visible=not settings.visible
        save_settings()
        refresh()

    elseif cmd=='clear' or cmd=='reset' then
        clear_all_tasks()
        msg("Tasks cleared.")

    elseif cmd=='test' then

        ensure_tasks()

        settings.tasks.chest.area="Gustav Tunnel"
        settings.tasks.kill.area="The Shrine of Ru'Avitau"
        settings.tasks.kill.qty="15"
        settings.tasks.kill.mob="Evil Weapons"
        settings.tasks.craft.item="Inferno Axe"
        settings.tasks.nm.area="Bostaunieux Oubliette"
        settings.tasks.nm.mob="Shii"
        settings.tasks.item.area="Castle Zvahl Baileys"
        settings.tasks.item.item="Demon Pen"

        save_settings()
        refresh()

    elseif cmd=='pos' then

        local x=tonumber(args[1])
        local y=tonumber(args[2])

        if not x or not y then
            msg("Usage: //dailytask pos <x> <y>",123)
            return
        end

        settings.pos.x=x
        settings.pos.y=y
        task_box:pos(x,y)

        save_settings()
        refresh()

    elseif cmd=='font' then

        local size=tonumber(args[1])
        if not size then return end

        settings.ui.size=size
        task_box:size(size)

        save_settings()
        refresh()

    else

        msg("Commands:")
        msg("//dailytask show")
        msg("//dailytask hide")
        msg("//dailytask toggle")
        msg("//dailytask clear")
        msg("//dailytask test")
        msg("//dailytask pos x y")
        msg("//dailytask font size")

    end

end)