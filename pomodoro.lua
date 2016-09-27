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

pomodoro.pause_after_break = false

pomodoro.colors = { work = 'red', work_pause = '#a50', rest = '#1c0', rest_pause = '#dc0',
                    off = beautiful.fg_normal }


pomodoro.widget     = wibox.widget.textbox()
pomodoro.tooltip    = awful.tooltip({ objects = {pomodoro.widget} })
pomodoro.timer      = timer({ timeout = 1 }) --seconds

function pomodoro:notify(contents)
    naughty.notify({
        title = contents.title,
        text  = contents.text
    })
end

local function switchState(state)
    pomodoro.state = state
    if state.onEnter then
        state.onEnter()
    end
end
local function set_tomato()
    pomodoro.widget:set_markup(string.format(
        '<span size="x-large" foreground="%s"><b>%s</b></span>',
        pomodoro.state.color, pomodoro.icon))

    local tooltip_text = 'Pomodoro timer'
    if pomodoro.state ~= pomodoro.states.off then
        local m = pomodoro.time_left // 60
        local s = pomodoro.time_left - m * 60
        tooltip_text = string.format('<b>%dm %ds</b> remaining', m, s)
    end
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
            return pomodoro.states.rest
        end,
        onLeftClick  = function()
            pomodoro.timer:stop()
            pomodoro.state = pomodoro.states.work_pause
            set_tomato()
        end,
        onRightClick = function() switchState(pomodoro.states.rest) end
    },
    work_pause = {
        color   = pomodoro.colors.work_pause,
        onLeftClick  = function()
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
        onEnter = function() pomodoro.time_left = pomodoro.rest_time end,
        onExit  = function()
            out = pomodoro.states.work
            if pomodoro.pause_after_break then
                pomodoro.timer:stop()
                out = pomodoro.states.work_pause
            end
            pomodoro:notify(pomodoro.rest_done)
            return out
        end,
        onLeftClick  = function()
            pomodoro.timer:stop()
            pomodoro.state = pomodoro.states.rest_pause
            set_tomato()
        end,
        onRightClick = function() switchState(pomodoro.states.work) end
    },
    rest_pause = {
        color   = pomodoro.colors.rest_pause,
        onLeftClick  = function()
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
