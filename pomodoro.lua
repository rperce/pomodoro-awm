local beautiful = require('beautiful')
local wibox     = require('wibox')
local awful     = require('awful')
local naughty   = require('naughty')

local pomodoro      = {}
pomodoro.rest_time  = 5  * 60
pomodoro.work_time  = 25 * 60

pomodoro.rest_done  = {title = 'Break finished.', text = 'Get back to work!'}
pomodoro.work_done  = {title = 'Work complete.',  text = 'Time for a break!'}

pomodoro.icon       = '&#x1f345;' --unicode tomato

-- set long_break_after to -1 to disable long breaks
pomodoro.long_break_after = 4
pomodoro.long_break_time = 30 * 60

pomodoro.pause_after_break = false

-- set to nil to disable ding
pomodoro.ding = debug.getinfo(1).source:sub(2):match('(.*/)') .. 'resources/ding.wav'

pomodoro.colors = { work       = 'red',
                    work_pause = '#a50',
                    rest       = '#1c0',
                    rest_pause = '#dc0',
                    off        = beautiful.fg_normal }

pomodoro.display_time_in_widget = true

pomodoro.widget     = wibox.widget.textbox()
pomodoro.tooltip    = awful.tooltip({ objects = {pomodoro.widget} })
pomodoro.timer      = timer({ timeout = 1 }) --seconds
pomodoro.completed  = 0

function pomodoro:notify(contents)
    naughty.notify({
        title = contents.title,
        text  = contents.text
    })
end
function pomodoro:play_ding()
    if pomodoro.ding ~= nil then
        awful.util.spawn('aplay ' .. pomodoro.ding)
    end
end

local function switchState(state)
    pomodoro.state = state
    if state.onEnter then
        state.onEnter()
    end
end
local function set_tomato()
    local widget_text = '<span size="x-large" foreground="%s"><b>%s</b></span>';
    local tooltip_text = 'Pomodoro timer'
    if pomodoro.state ~= pomodoro.states.off then
        local m = pomodoro.time_left // 60
        local s = pomodoro.time_left - m * 60
        if pomodoro.display_time_in_widget then
            widget_text = widget_text .. string.format('<span> %d:%02d</span>', m, s)
        end
        tooltip_text = string.format('<b>%dm %02ds</b> remaining', m, s)
        if pomodoro.state == pomodoro.states.work and pomodoro.long_break_after ~= -1 then
            tooltip_text = tooltip_text .. string.format(' (#%d of %d)', pomodoro.completed + 1, pomodoro.long_break_after)
        end
    end

    pomodoro.widget:set_markup(string.format(widget_text, pomodoro.state.color, pomodoro.icon))

    pomodoro.tooltip:set_markup(string.format(
        '<span size="xx-large" foreground="%s"><b>%s </b></span><span size="x-large">%s</span>',
        pomodoro.state.color, pomodoro.icon, tooltip_text))
end
pomodoro.states = {
    work = {
        color   = pomodoro.colors.work,
        onEnter = function() pomodoro.time_left = pomodoro.work_time end,
        onExit  = function()
            pomodoro:notify(pomodoro.work_done)
            pomodoro:play_ding()
            return pomodoro.states.rest
        end,
        onLeftClick = function()
            pomodoro.timer:stop()
            pomodoro.state = pomodoro.states.work_pause
            set_tomato()
        end,
        onRightClick = function() switchState(pomodoro.states.rest) end
    },
    work_pause = {
        color   = pomodoro.colors.work_pause,
        onLeftClick = function()
            pomodoro.timer:start()
            pomodoro.state = pomodoro.states.work
        end,
        onRightClick = function()
            pomodoro.timer:start()
            switchState(pomodoro.states.rest)
        end
    },
    rest = {
        color   = pomodoro.colors.rest,
        onEnter = function()
            if pomodoro.long_break_after ~= -1 then
                pomodoro.completed = pomodoro.completed + 1
            end
            if pomodoro.completed == pomodoro.long_break_after then
                pomodoro.time_left = pomodoro.long_break_time
                pomodoro.completed = 0
            else
                pomodoro.time_left = pomodoro.rest_time
            end
        end,
        onExit  = function()
            out = pomodoro.states.work
            if pomodoro.pause_after_break then
                pomodoro.timer:stop()
                out = pomodoro.states.work_pause
            end
            pomodoro:notify(pomodoro.rest_done)
            pomodoro:play_ding()
            return out
        end,
        onLeftClick = function()
            pomodoro.timer:stop()
            pomodoro.state = pomodoro.states.rest_pause
            set_tomato()
        end,
        onRightClick = function() switchState(pomodoro.states.work) end
    },
    rest_pause = {
        color   = pomodoro.colors.rest_pause,
        onLeftClick = function()
            pomodoro.timer:start()
            pomodoro.state = pomodoro.states.rest
        end,
        onRightClick = function()
            pomodoro.timer:start()
            switchState(pomodoro.states.work)
        end
    },
    off = {
        color = pomodoro.colors.off,
        onLeftClick = function()
            switchState(pomodoro.states.work)
            pomodoro.timer:start()
        end,
        onRightClick = function() end
    }
}

pomodoro.timer:connect_signal('timeout', function()
    pomodoro.time_left = pomodoro.time_left - 1
    if pomodoro.time_left == 0 then
        switchState(pomodoro.state.onExit())
    end
    set_tomato()
end)

pomodoro.widget:buttons(
    awful.util.table.join(
        awful.button({ }, 1, function() -- left click
            pomodoro.state.onLeftClick()
        end),
        awful.button({ }, 3, function() -- right click
            pomodoro.state.onRightClick()
        end),
        awful.button({ }, 2, function() -- middle click
            pomodoro.timer:stop()
            switchState(pomodoro.states.off)
            set_tomato()
        end)
    )
)

pomodoro.state = pomodoro.states.off
set_tomato()

return pomodoro.widget
