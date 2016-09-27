Pomodoro Timer for AwesomeWM
===

![Plain](docs/plain.png) | ![Hover](docs/hover.png)
![Work Hover](docs/work_hover.png) | ![Next Work](docs/next_work.png)
test1 | test2

Images: 1) timer widget sitting in the wibox, 2) hovering over the widget;
3) just after left-clicking, 4) notification at the end of a break

Also pictured is my
[alsa widget](https://github.com/rperce/dotfiles/blob/master/awesome/.config/awesome/widgets/alsa.lua),
[battery widget](https://github.com/rperce/dotfiles/blob/master/awesome/.config/awesome/widgets/battery.lua),
and
[english-word clock](https://github.com/rperce/dotfiles/blob/master/awesome/.config/awesome/widgets/clock.lua),
which uses
[this small ruby program](https://github.com/rperce/dotfiles/blob/master/path/path/wordtime).

Installation
---
```bash
$ cd ${XDG_CONFIG_HOME:-.config}/awesome
$ git clone https://github.com/rperce/pomodoro-awm.git
```

and edit your `rc.lua` to do something like
```lua
...
-- widget definitions
local pomodoro_widget = require('pomodoro-awm/pomodoro')
...
for s = 1, screen.count() do
    -- Widgets that are aligned to the right
    local right_layout = wibox.layout.fixed.horizontal()
    ...
    right_layout:add(pomodoro_widget)
    ...
end
...
-- bindings, etc.
...
```

And restart AwesomeWM (Mod4 + Ctrl + r, by default).
