client
Functions
client.log
logs a message in the top left / in the console

client.log(msg: string, color: color, prefix: string, visible: boolean)

Argument	Type	Description
msg	string	The message that will appear in the top left / console.
color	color	The message's color (white by default)
prefix	string	The message's prefix (empty by default)
visible	boolean	If defined as true (default) the message will show in the top left otherwise it will only appear in the console
client.load_script
loads a lua script

client.load_script(file_name: string)

Argument	Type	Description
file_name	string	The file to load by name (example: "some.lua")
client.choked_commands
returns amount of currently choked commands

client.choked_commands(): number (integer)

Argument	Type	Description
-	-	-
client.is_alive
returns whether the localplayer is alive or not

client.is_alive(): boolean

Argument	Type	Description
-	-	-
client.latency
returns latency (rtt) to server

client.latency(): string

Argument	Type	Description
-	-	-
client.local_time
returns local pc time

client.local_time(format: string): string

Argument	Type	Description
format	string	time formatting
client.local_time("%r") -- will get you localized time string (including seconds)
client.local_time("%I:%M:%S") -- will get you HH:MM:SS time string (12-hour-format)
client.local_time("%H:%M:%S") -- will get you HH:MM:SS time string (24-hour-format)
client.unix_timestamp
returns unix timestamp

client.unix_timestamp(): number (integer)

Argument	Type	Description
-	-	
client.map_name
returns map name if ingame

client.map_name(): string

Argument	Type	Description
-	-	
client.camera_position
returns position of camera

client.camera_position(): vector

Argument	Type	Description
-	-	
client.camera_angles
returns camera angles

client.camera_angles(): qangle

Argument	Type	Description
-	-	
client.find_sig
returns address as integer or 0 when pattern (IDA-Style) was not found

client.find_sig(module: string, sig: string): number (integer)

Argument	Type	Description
module	string	e.g "client.dll"
sig	string	e.g "A3 ? ? ? ? 57 8B CB"
client.create_interface
returns an address to the interface or 0 when not found

client.create_interface(module: string, interface: string): number (integer)

Argument	Type	Description
module	string	e.g "client.dll"
interface	string	e.g "VClient018" (has to be interface name (e.g. "VClient") including exact version (e.g. "018"))
Members
client.username
global variable for the current user's name (displayed in watermark)

client.usernameclient
Functions
client.log
logs a message in the top left / in the console

client.log(msg: string, color: color, prefix: string, visible: boolean)

Argument	Type	Description
msg	string	The message that will appear in the top left / console.
color	color	The message's color (white by default)
prefix	string	The message's prefix (empty by default)
visible	boolean	If defined as true (default) the message will show in the top left otherwise it will only appear in the console
client.load_script
loads a lua script

client.load_script(file_name: string)

Argument	Type	Description
file_name	string	The file to load by name (example: "some.lua")
client.choked_commands
returns amount of currently choked commands

client.choked_commands(): number (integer)

Argument	Type	Description
-	-	-
client.is_alive
returns whether the localplayer is alive or not

client.is_alive(): boolean

Argument	Type	Description
-	-	-
client.latency
returns latency (rtt) to server

client.latency(): string

Argument	Type	Description
-	-	-
client.local_time
returns local pc time

client.local_time(format: string): string

Argument	Type	Description
format	string	time formatting
client.local_time("%r") -- will get you localized time string (including seconds)
client.local_time("%I:%M:%S") -- will get you HH:MM:SS time string (12-hour-format)
client.local_time("%H:%M:%S") -- will get you HH:MM:SS time string (24-hour-format)
client.unix_timestamp
returns unix timestamp

client.unix_timestamp(): number (integer)

Argument	Type	Description
-	-	
client.map_name
returns map name if ingame

client.map_name(): string

Argument	Type	Description
-	-	
client.camera_position
returns position of camera

client.camera_position(): vector

Argument	Type	Description
-	-	
client.camera_angles
returns camera angles

client.camera_angles(): qangle

Argument	Type	Description
-	-	
client.find_sig
returns address as integer or 0 when pattern (IDA-Style) was not found

client.find_sig(module: string, sig: string): number (integer)

Argument	Type	Description
module	string	e.g "client.dll"
sig	string	e.g "A3 ? ? ? ? 57 8B CB"
client.create_interface
returns an address to the interface or 0 when not found

client.create_interface(module: string, interface: string): number (integer)

Argument	Type	Description
module	string	e.g "client.dll"
interface	string	e.g "VClient018" (has to be interface name (e.g. "VClient") including exact version (e.g. "018"))
Members
client.username
global variable for the current user's name (displayed in watermark)

client.username

callbacks
Functions
callbacks.register
registers a callback

callbacks.register(name: string, callback: function)

Argument	Type	Description
name	string	Name of the event / callback.
callback	function	Function that will get called as soon as the event / callback happens
Example
-- function does not has to be called "on_<callback>"
function on_paint()

end

-- first argument being the callback name and second being the function
callbacks.register("paint", on_paint)
callbacks.deregister
deregister a callback

callbacks.deregister(name: string, callback: function)

Argument	Type	Description
name	string	Name of the event / callback.
callback	function	Function that should be unregistered
Made with Material for MkDocs

callback list
Game Events
Other callbacks
paint
used for drawing (or calling something) every frame (using the render functions)

Example:
function on_paint()
    -- cool, useless, rectangle!
    render.rectangle(10, 10, 10, 10, color.new(255, 255, 255))

end

callbacks.register("paint", on_paint)
pre_frame_stage
called right before FrameStageNotify and internal functions when localplayer is valid

Example:
function on_frame_stage(stage) -- stage: current frame stage

end

callbacks.register("pre_frame_stage", on_frame_stage)
post_frame_stage
called right after FrameStageNotify and internal functions when localplayer is valid

Example:
function on_frame_stage(stage) -- stage: current frame stage

end

callbacks.register("post_frame_stage", on_frame_stage)
post_move
used to modify the user command after the internal modifications using usercmd

Example:
function on_post_move(cmd) -- the first argument is the command's "pointer"
    -- let's see if we want to anti aim
    if anti_aim.should_run(cmd, false) == false then    
        return
    end

    -- up pitch (gamer moment)
    cmd.viewangles.x = -89
end

callbacks.register("post_move", on_post_move)
predicted_move
used to modify the user command inside prediction, after move related features have ran, using usercmd

Example:
function on_predicted_move(cmd) -- the first argument is the command's "pointer"
    -- do something
end

callbacks.register("predicted_move", on_predicted_move)
post_anim_update
can be used to modify animation / bones related data of the local player

Example:
-- set_float_index is undocumented, however it can be used to modify float arrays (like m_flPoseParameter)
-- there also is get_float_index(index: number(integer)): number (float)

-- "falling legs" example:
callbacks.register("post_anim_update", function(ent)
    local m_flPoseParameter = ent:get_prop("DT_BaseAnimating", "m_flPoseParameter");
    m_flPoseParameter:set_float_index(6, 1); -- first argument is the index, second the value to be set to
end)
on_hitmarker
used to get the damage and position of where the localplayer hit

Example:
function on_hitmarker(damage, position) -- damage: number (float), position: vector

end

callbacks.register("on_hitmarker", on_hitmarker)
draw_model
used to draw models using model_draw_context

Example:
-- grab a material (or create one)
local flat_mat = materials.find_material("debug/debugdrawflat")

-- let's see, if the material is valid
local flat_mat_valid = flat_mat:is_valid()

function on_draw_model(context) -- the first argument is the entity's model_draw_context
    -- let's see if the current entity is the localplayer
   if context:get_entity():index() == engine.get_local_player() then
        if flat_mat_valid then
            -- r, g, b (0.0-1.0)
            flat_mat:modulate_color(1, 1, 1)

            -- a (0.0-1.0)
            flat_mat:modulate_alpha(0.5)

            -- set flag (ignorez)
            flat_mat:set_material_var_flag((1 << 15), true) -- ignorez

            -- draw the entity with our material
            context:force_material_override(flat_mat)
        end
   end
end

callbacks.register("draw_model", on_draw_model)
Made with Material for MkDocs

entity_list
Functions
entity_list.get_client_entity
returns an entity object

entity_list.get_client_entity(entnum: number OR netvar): entity

Argument	Type	Description
entnum	number (integer) OR netvar (handle by an existing entity)	reference to the entity
entity_list.get_all
returns a table of all indices (valid entities) of the given entity/network name

entity_list.get_all(networkname: string): table (number -> entindex)

Argument	Type	Description
networkname	string	network name of the entity
entity_list.get_highest_entity_index
returns the index of the entity with the highest index

entity_list.get_highest_entity_index(): number

Argument	Type	Description
-	-	-
Made with Material for MkDocs

engine
Functions
engine.get_player_for_user_id
returns an entity index (used for converting userid's of game events to entity indices)

engine.get_player_for_user_id(userid: number): number (integer)

Argument	Type	Description
userid	number (integer)	user id
engine.in_game
returns true if you are in a game or false if not

engine.in_game(): boolean

Argument	Type	Description
-	-	-
engine.is_connected
returns true if you are connected to a server or false if not‌

engine.is_connected(): boolean

Argument	Type	Description
-	-	-
engine.execute_client_cmd
executes a console command

engine.execute_client_cmd(cmd: string)

Argument	Type	Description
cmd	string	the commands name
engine.set_view_angles
sets the engine view angles

engine.set_view_angles(viewangle: qangle)

Argument	Type	Description
viewangle	qangle	the viewangles to be set
engine.get_view_angles
returns the engine view angles as a qangle object

engine.get_view_angles(): qangle

Argument	Type	Description
-	-	-
engine.get_local_player
returns the entity index of the local player

engine.get_local_player(): number

Argument	Type	Description
-	-	-
engine.get_player_info
returns a player_info object

engine.get_player_info(entnum: number): player_info

Argument	Type	Description
entnum	number (integer)	an entity's index


esp
Functions
esp.set_thirdperson_animation
enable / disable thirdperson animation

esp.set_thirdperson_animation(value: boolean)

Argument	Type	Description
value	boolean	state (true by default)
esp.set_fading_chams
enable / disable chams animation

esp.set_fading_chams(value: boolean)

Argument	Type	Description
value	boolean	state (true by default)
esp.add_player_flag
adds a flag to the esp (right side of the box) NOTE: should be called inside paint callback

esp.add_player_flag(flag: string, color: color, entindex: number)

Argument	Type	Description
flag	string	the text to display
color	color	color of the text
entindex	number (integer)	the index of the player this flag should be displayed on
Made with Material for MkDocs



global_vars
Members
global_vars.curtime
global variable for the engines current time

global_vars.curtime: number (float)

global_vars.frametime
global variable for the engines frame time

global_vars.frametime: number (float)

global_vars.absoluteframetime
global variable for the engines absolute frame time

global_vars.absoluteframetime: number (float)

global_vars.framecount
global variable for the engines frame count

global_vars.framecount: number (integer)

global_vars.tickcount
global variable for the engines tick count

global_vars.tickcount: number (integer)

global_vars.realtime
global variable for the engines real time

global_vars.realtime: number (float)

global_vars.max_clients
global variable for the engines max clients

global_vars.max_clients: number (integer)

global_vars.interval_per_tick
global variable for the engines interval per tick

global_vars.interval_per_tick: number (integer)

Made with Material for MkDocs


cvar
Functions
cvar.find_var
returns a convar object

cvar.find_var(var_name: string): convar

Argument	Type	Description
var_name	string	console command's name



engine_trace
Functions
engine_trace.trace_ray
returns a game_trace object

engine_trace.trace_ray(start: vector, end: vector, skip: entity, mask: number): game_trace

Argument	Type	Description
start	vector	trace starting position
end	vector	trace ending position
skip	entity	entity to be skipped (filter)
mask	number (integer)	trace mask


render
Functions
render.rectangle
draws a rectangle

render.rectangle(x: number, y: number, w: number, h: number, color: color)

Argument	Type	Description
x	number (integer)	x coordinate
y	number (integer)	y coordinate
w	number (integer)	render width
h	number (integer)	render height
color	color	color the drawing renders with
render.rectangle_filled
draws a filled rectangle

render.rectangle_filled(x: number, y: number, w: number, h: number, color: color)

Argument	Type	Description
x	number (integer)	x coordinate
y	number (integer)	y coordinate
w	number (integer)	render width
h	number (integer)	render height
color	color	color the drawing renders with
render.gradient
draws a filled fade rectangle

render.gradient(x: number, y: number, w: number, h: number, color: color, color2: color, horizontal: boolean)

Argument	Type	Description
x	number (integer)	x coordinate
y	number (integer)	y coordinate
w	number (integer)	render width
h	number (integer)	render height
color	color	color of the first half the drawing renders with
color2	color	color of the second half the drawing renders with
horizontal	boolean	fading direction (vertical by default)
render.triangle_filled
draws a filled triangle

render.triangle_filled(pos1: vector2d, pos2: vector2d, pos3: vector2d, color: color)

Argument	Type	Description
pos1	vector2d	coordinate of first corner
pos2	vector2d	coordinate of second corner
pos3	vector2d	coordinate of third corner
color	color	color the drawing renders with
render.circle_world
draws a (filled) circle in world space (no world to screen required)

render.circle_world(origin: vector, radius: number, color: color, colorFill: color)

Argument	Type	Description
origin	vector	the circles origin/position in world space
radius	number (float)	the circles radius
color	color	color the drawing renders with (outer circle, "outline")
colorFill	color	color the drawing renders with (inner circle, "filling")
render.circle_filled
draws a filled circle

render.circle_filled(x: number, y: number, radius: number, segments: number, color: color)

Argument	Type	Description
x	number (integer)	x coordinate
y	number (integer)	y coordinate
radius	number (float)	circle radius
segments	number (integer)	circle segments
color	color	color the drawing renders with
render.line
draws a line

render.line(x: number, y: number, x2: number, y2: number, color: color)

Argument	Type	Description
x	number (integer)	(from) x coordinate
y	number (integer)	(from) y coordinate
x2	number (integer)	(to) x coordinate
y2	number (integer)	(to) y coordinate
color	color	color the drawing renders with
render.text
draws a text

render.text(x: number, y: number, text: string, color: color)

Argument	Type	Description
x	number (integer)	x coordinate
y	number (integer)	y coordinate
text	string	text to draw
color	color	color the drawing renders with
render.get_text_size
returns width and height of the text given (font used in render.text)

render.get_text_size(text: string): number, number

Argument	Type	Description
text	string	text you want to get the width/height of
render.create_font
returns a Font object (avoid calling this in a callback function, setup before doing anything)

render.create_font(fontname: string, size: number, weight: number, flags: font_flags): Font

Argument	Type	Description
fontname	string	font name (Arial, ...)
size	number (integer)	font size in pixels
weight	number (integer)	font weight
flags	font_flags	font flags
render.get_screen
returns the width and height of the screen

render.get_screen(): number, number

Argument	Type	Description
-	-	
render.world_to_screen
transforms the coordinates from world space to screen and returns true when successfully transformed or false when not

render.world_to_screen(input: vector, output: vector2d): boolean

Argument	Type	Description
input	vector	-
output	vector2d	output (screen coordinates)
Made with Material for MkDocs

font_flags
Members
font_flags.none
no font flag

font_flags.antialias
adds anti-aliasing to the font

font_flags.dropshadow
adds a dropshadow to the font

font_flags.outline
adds an outline to the font

Example usage
-- multiple flags example
local arial_drop_outline = render.create_font("Arial", 12, 500, bit.bor(font_flags.dropshadow, font_flags.outline))

-- single flag example
local arial_drop = render.create_font("Arial", 12, 500, font_flags.dropshadow)
Made with Material for MkDocs

ui
Functions
ui.is_open
returns true if the ui is currently open or false when it is closed

ui.is_open(): boolean

ui.get
gets a reference to a menu item and returns specified item as object

supported tabs:
Rage (Aimbot, Exploits, Anti-aim)
Visuals (General, Models)
Misc (General)
Profile (General)

ui.get(tab: string, sub_tab: string, group: string, option: string): UI

Argument	Type	Description
tab	string	menu tab (example: "Visuals")
sub_tab	string	sub tab (example: "ESP")
group	string	group box (example: "Other ESP")
option	string	option (example: "Preserve killfeed")
Example:
local menu_item = ui.get("Visuals", "ESP", "Other ESP", "Preserve killfeed") -- returns a checkbox object
local menu_item_state = menu_item:get() -- returns true/false
ui.get
gets a reference to a menu item and returns specified item as object

supported tabs: Rage (Aimbot)

ui.get(tab: string, sub_tab: string, group: string, option: string, weapon_group: string): UI

Argument	Type	Description
tab	string	menu tab (example: "Rage")
sub_tab	string	sub tab (example: "Aimbot")
group	string	group box (example: "General")
option	string	option (example: "Override default configuration")
weapon_group	string	option (example: "Pistols")
Example:
local menu_item = ui.get("Rage", "Aimbot", "General", "Override default configuration", "Pistols") -- returns a checkbox object
local menu_item_state = menu_item:get() -- returns true/false
ui.get_rage
gets a reference to a menu item and returns specified item as object (for active weapon configuration)

NOTE: should be called inside a paint or post_move callback, as otherwise you will receive the object of the weapon configuration that was active at the time of loading the script

supported tabs:
Rage (Aimbot)

ui.get_rage(group: string, option: string): UI

Argument	Type	Description
group	string	group box (example: "General")
option	string	option (example: "Override default configuration")
Example:
local menu_item = ui.get_rage("General", "Override default configuration") -- returns a checkbox object
local menu_item_state = menu_item:get() -- returns true/false
ui.add_checkbox
adds a Checkbox to the "Items" group box of the LUA tab (script specific) and returns a checkbox object

ui.add_checkbox(name: string): checkbox

Argument	Type	Description
name	string	item display name (this should be unique in-script -> avoid adding 2 or more items with the same name)
Example
local checkbox_item = ui.add_checkbox("Epic checkbox")
ui.add_dropdown
adds a Dropdown to the "Items" group box of the LUA tab (script specific) and returns a dropdown object

ui.add_dropdown(name: string, [items: string]): dropdown

Argument	Type	Description
name	string	item display name (this should be unique in-script -> avoid adding 2 or more items with the same name)
items	string table	items (names)
Example
local dropdown_item = ui.add_dropdown("Epic dropdown", { "Option 1", "Option 2" })
ui.add_multi_dropdown
adds a Multi-dropdown to the "Items" group box of the LUA tab (script specific) and returns a multidropdown object

ui.add_multi_dropdown(name: string, [items: string]): multidropdown

Argument	Type	Description
name	string	item display name (this should be unique in-script -> avoid adding 2 or more items with the same name)
items	string table	items (names)
Example
local multi_dropdown_item = ui.add_multi_dropdown("Epic multi dropdown", { "Option 1", "Option 2" })
ui.add_button
adds a button to the "Items" group box of the LUA tab (script specific) and returns a button object

ui.add_button(text: string): button

Argument	Type	Description
text	string	displayed text
Example
local button = ui.add_button("My epic button")
button:add_callback(function()
    print("test!") -- will print text to the game's console
end)
ui.add_textbox
adds a textbox to the "Items" group box of the LUA tab (script specific) and returns a textbox object

ui.add_textbox(name: string): textbox

Argument	Type	Description
name	string	item display name (this should be unique in-script -> avoid adding 2 or more items with the same name)
Example
local textbox = ui.add_textbox("My epic textbox")
ui.add_label
adds a label (text) to the "Items" group box of the LUA tab (script specific)

ui.add_label(text: string)

Argument	Type	Description
text	string	displayed text
Example
ui.add_label("My epic label") -- this does not return anything
ui.add_hotkey
adds a Hotkey to the "Items" group box of the LUA tab (script specific) and returns a hotkey object

ui.add_hotkey(name: string): hotkey

Argument	Type	Description
name	string	Hotkey label name (this should be unique in-script as it is used for the configuration system -> avoid adding 2 or more items with the same Tooltip)
Example
local hotkey_item = ui.add_hotkey("My epic hotkey")
ui.add_colorpicker
adds a colorpicker to the "Items" group box of the LUA tab (script specific) and returns a colorpicker object

ui.add_colorpicker(name: string): colorpicker

Argument	Type	Description
name	string	Colorpicker label name (this should be unique in-script as it is used for the configuration system -> avoid adding 2 or more items with the same Tooltip)
Example
local colorpicker_item = ui.add_colorpicker("My epic colorpicker")
ui.add_slider
adds a Slider to the "Items" group box of the LUA tab (script specific) and returns a slider object

ui.add_slider(name: string, min: number, max: number): slider

Argument	Type	Description
name	string	item display name (this should be unique in-script -> avoid adding 2 or more items with the same name)
min	number (integer)	minimum value of the slider
max	number (integer)	maximum value of the slider
Example
local slider_item = ui.add_slider("My epic slider", 0, 1337)
ui.add_slider_float
adds a Slider to the "Items" group box of the LUA tab (script specific) and returns a slider object

ui.add_slider_float(name: string, min: number, max: number): slider

Argument	Type	Description
name	string	item display name (this should be unique in-script -> avoid adding 2 or more items with the same name)
min	number (float)	minimum value of the slider
max	number (float)	maximum value of the slider
Example
local slider_item = ui.add_slider_float("My epic slider", 0.1, 69.69)
Made with Material for MkDocs


anti_aim
Functions
anti_aim.inverted
returns true when inverted or false when not

anti_aim.inverted(): boolean

Argument	Type	Description
-	-	-
anti_aim.should_run
returns true when cheat should anti-aim on the command or false when not

anti_aim.should_run(cmd: usercmd, skip_firing_check: boolean): boolean

Argument	Type	Description
cmd	usercmd	-
skip_firing_check	boolean	when defined as true, the function will not account for firing (you ideally don't want to modify viewangles when firing)


    exploits
Functions
exploits.process_ticks
returns current amount of process ticks

exploits.process_ticks(): number (integer)

Argument	Type	Description
-	-	-
exploits.max_process_ticks
returns maximum amount of process ticks

exploits.max_process_ticks(): number (integer)

Argument	Type	Description
-	-	-
exploits.charging
returns true if you are currently charging process ticks

exploits.charging(): boolean

Argument	Type	Description
-	-	-
exploits.ready
returns true if exploits are ready

exploits.ready(): boolean

Argument	Type	Description
-	-	-
exploits.force_recharge
forces exploits to be recharged

exploits.force_recharge()

Argument	Type	Description
-	-	-
Made with Material for MkDocs


penetration
Functions
penetration.damage
returns penetration damage of first penetrated wall

penetration.damage(): number (integer)

Argument	Type	Description
-	-	-
penetration.simulate_bullet
simulates a bullet and returns damage, penetration count (amount of penetrations), hitgroup (the hitgroup that was hit)

penetration.simulate_bullet(attacker: entity, start: vector, end: vector): number (integer), number (integer), number (integer)

Argument	Type	Description
attacker	entity	the desired attacker (the data will be based on this entity)
start	vector	starting position
end	vector	ending position
Made with Material for MkDocs


materials
Functions
materials.create_material
returns a material, make sure to check whether it is valid

materials.create_material(name: string, vmt: string, type: string): material

Argument	Type	Description
name	string	the materials name (can be found using materials.find_material)
materials.find_material
returns a material, make sure to check whether it is valid

materials.find_material(name: string, group: string): material

Argument	Type	Description
name	string	the materials name
group	string	!OPTIONAL! the materials texture group

command
Members
.in_attack
attack

command.in_attack

.in_jump
jump

command.in_jump

.in_duck
duck

command.in_duck

.in_forward
forward

command.in_forward

.in_back
back

command.in_back

.in_use
use

command.in_use

.in_cancel
cancel

command.in_cancel

.in_left
left

command.in_left

.in_right
right

command.in_right

.in_moveleft
move moveleft

command.in_moveleft

.in_moveright
move moveright

command.in_moveright

.in_attack2
attack2

command.in_attack2

.in_reload
reload

command.in_reload

.in_speed
speed

command.in_speed

.in_bullrush
bull bullrush

command.in_bullrush

Made with Material for MkDocs

input
Functions
input.key_down
returns true if the key is currently being held or false if not

input.key_down(key: number): boolean

Argument	Type	Description
key	number (integer)	virtual key code
input.key_pressed
returns true if the key was pressed (key was pressed and is still being held down) or false if not

input.key_pressed(key: number): boolean

Argument	Type	Description
key	number (integer)	virtual key code
input.mouse_position
returns x and y coordinate of mouse position

input.mouse_position(): number, number

Argument	Type	Description
-	-	-
input.force_cursor
force enable / disable cursor(and input)

input.force_cursor(state: boolean)

Argument	Type	Description
state	boolean	enabled/disabled (true/false)


usercmd
Members
.command_number
cmd.command_number

.tick_count
cmd.tick_count

.viewangles
cmd.viewangles: qangle

.aimdirection
cmd.aimdirection: vector

.forwardmove
cmd.forwardmove

.sidemove
cmd.sidemove

.upmove
cmd.upmove

.buttons
cmd.buttons

.impulse
cmd.impulse

.weaponselect
cmd.weaponselect

.weaponsubtype
cmd.weaponsubtype

.random_seed
cmd.random_seed

.mousedx
cmd.mousedx

.mousedy
cmd.mousedy

.hasbeenpredicted
cmd.hasbeenpredicted

Functions
further information about all the possible flags can be found here command

:has_flag
returns true if the current usercommand's buttons have THA flag

cmd:has_flag(flag: number): boolean

Argument	Type	Description
flag	number (integer)	button flag
:set_flag
sets the given flag in the current usercommand's buttons

cmd:set_flag(flag: number)

Argument	Type	Description
flag	number (integer)	button flag
:remove_flag
removes the given flag in the current usercommand's buttons

cmd:remove_flag(flag: number)

Argument	Type	Description
flag	number (integer)	button flag
Made with Material for MkDocs

convar
Get-Functions
:get_int
returns the value as a number (integer)

cvar_object:get_int()

Argument	Type	Description
-	-	
:get_bool
returns the value as boolean

cvar_object:get_bool()

Argument	Type	Description
-	-	
:get_float
returns the value as a number (float)

cvar_object:get_float()

Argument	Type	Description
-	-	
:get_string
returns the value as a string

cvar_object:get_string()

Argument	Type	Description
-	-	
Set-Functions
Make sure to use the right function to avoid crashes or such.
:set_value_int
sets the value as a number (integer)

cvar_object:set_value_int(input: number)

Argument	Type	Description
input	number (integer)	-
:set_value_float
sets the value as a number (float)

cvar_object:set_value_float(input: number)

Argument	Type	Description
input	number (float)	-
:set_value_string
sets the value as a string

cvar_object:set_value_string(input: string)

Argument	Type	Description
input	string	-
Made with Material for MkDocs

player_info
Members
.name
the player's name

player_info_object.name: string

.fakeplayer
this is set to true if the player is a BOT

player_info_object.fakeplayer: boolean

.steamID64
the player's steamid64

player_info_object.steamID64: number (integer)

.szSteamID
the player's steamid as string (STEAM_X:Y:Z)

player_info_object.szSteamID: string

Made with Material for MkDocs

game_event
:get_int
returns the value as a number (integer)

event_object:get_int(keyName: string): number (integer)

Argument	Type	Description
keyName	string	event key name
:get_uint64
returns the value as a number (integer)

event_object:get_uint64(keyName: string): number (integer)

Argument	Type	Description
keyName	string	event key name
:get_bool
returns the value as boolean

event_object:get_bool(keyName: string): boolean

Argument	Type	Description
keyName	string	event key name
:get_float
returns the value as a number (float)

event_object:get_float(keyName: string): number (float)

Argument	Type	Description
keyName	string	event key name
:get_string
returns the value as a string

event_object:get_string(keyName: string): string

Argument	Type	Description
keyName	string	event key name
:get_wstring
returns the value as a wide string

event_object:get_wstring(keyName: string): string

Argument	Type	Description
keyName	string	event key name
Example
function on_player_hurt(event) -- the first argument is the event's pointer (object)
 local userid = event:get_int("userid") -- grab userid
end

callbacks.register("player_hurt", on_player_hurt)
Made with Material for MkDocs


game_trace
Members
.allsolid
game_trace.allsolid

.endpos
game_trace.endpos: vector

.fraction
game_trace.fraction

.hitbox
game_trace.hitbox

.hitgroup
game_trace.hitgroup

.startsolid
game_trace.startsolid

Made with Material for MkDocs


entity
:index
returns the entity's index

entity_object:index(): number (integer)

Argument	Type	Description
-	-	
:dormant
returns if the entity is dormant or not

entity_object:dormant(): boolean

Argument	Type	Description
-	-	
:class_id
returns the entity's class id

entity_object:class_id(): number (integer)

Argument	Type	Description
-	-	
:origin
returns the entity's interpolated origin

entity_object:origin(): vector

Argument	Type	Description
-	-	
:eye_position
returns the entity's interpolated eyeposition

entity_object:eye_position(): vector

Argument	Type	Description
-	-	
:hitbox_position
returns the entity's hitbox position

entity_object:hitbox_position(hitbox: number): vector

Argument	Type	Description
hitbox	number (integer)	hitbox index
:get_prop
returns a netvar object

entity_object:get_prop(table: string, prop: string): netvar

Argument	Type	Description
table	string	Data Table (example: "DT_BaseEntity")
prop	string	var name (example: "m_iTeamNum")
Made with Material for MkDocs


netvar
Get-Functions
:get_int
returns the value as a number (integer)‌

netvar_object:get_int(): number (integer)

Argument	Type	Description
-	-	​Content
:get_bool
returns the value as boolean‌

netvar_object:get_bool(): boolean

Argument	Type	Description
-	-	​Content
:get_float
returns the value as a number (float)‌

netvar_object:get_float(): number (float)

Argument	Type	Description
-	-	​Content
:get_string
returns the value as a string‌

netvar_object:get_string(): string

Argument	Type	Description
-	-	​Content
:get_vector
returns the value as a vector

netvar_object:get_vector(): vector

Argument	Type	Description
-	-	​Content
Set-Functions
Make sure to use the right function to avoid crashes or such.
:set_int
sets the value as a number (integer)‌

netvar_object:set_int(input: number)

Argument	Type	Description
input	number (integer)	-
:set_bool
sets the value as a boolean

netvar_object:set_bool(input: boolean)

Argument	Type	Description
input	boolean	-
:set_float
sets the value as a number (float)‌

netvar_object:set_float(input: number)

Argument	Type	Description
input	number (float)	-
:set_vector
sets the value as a string‌

netvar_object:set_vector(input: vector)

Argument	Type	Description
input	vector	-
Made with Material for MkDocs


model_draw_context
Functions
:get_entity
returns an entity

model_draw_context_object:get_entity(): entity

Argument	Type	Description
-	-	-
:get_model
returns a string (the model's name)

model_draw_context_object:get_model(): string

Argument	Type	Description
-	-	-
:draw_model
draws an instance of the current entity

model_draw_context_object:draw_model()

Argument	Type	Description
-	-	-
:force_material_override
overrides the material the entity will be drawn with

model_draw_context_object:force_material_override(mat: material)

Argument	Type	Description
material	material	the material that will be forced
Made with Material for MkDocs


material
Functions
:is_valid
returns true if the material is ready or false if it is not ready to be used

material_object:is_valid(): boolean

Argument	Type	Description
-	-	-
:modulate_alpha
sets the alpha modulation of the material

material_object:modulate_alpha(alpha: number)

Argument	Type	Description
alpha	number (float)	-
:modulate_color
sets the color modulation of the material

material_object:modulate_color(red: number, green: number, blue: number)

Argument	Type	Description
red	number (float)	-
green	number (float)	-
blue	number (float)	-
:set_material_var_flag
sets material flags (MaterialVarFlags_t)

material_object:set_material_var_flag(flag: number, on: boolean)

Argument	Type	Description
flag	number (integer)	the materialvarflag
on	boolean	the state of the flag (true (enabled) / false (disabled))
:find_var
finds and returns a material_var of the material (functions will do nothing, if the given variable could not be found in the material)

material_object:find_var(var: string): material_var

Argument	Type	Description
var	string	the material variable
Made with Material for MkDocs
material_var
Functions
:set_int_value
sets the integer value of the material variable

material_var_object:set_int_value(value: number)

Argument	Type	Description
value	number (integer)	-
:set_float_value
sets the float value of the material variable

material_var_object:set_float_value(value: number)

Argument	Type	Description
value	number (float)	-
:set_string_value
sets the string value of the material variable

material_var_object:set_string_value(value: string)

Argument	Type	Description
value	string	-
:set_vec_value
sets the vec value of the material variable

material_var_object:set_vec_value(value1: number, value2: number, value3: number)

Argument	Type	Description
value1	number (integer)	-
value2	number (integer)	-
value3	number (integer)	-
Made with Material for MkDocs

vector
Object
Type	Name
number (float)	x
number (float)	y
number (float)	z
Functions
new (constructor)
vector.new(x: number, y: number, z: number)

Argument	Type	Description
x	number (float)	x value
y	number (float)	y value
z	number (float)	z value
Example
local some_vector = vector.new(69, 420, 1337)
Made with Material for MkDocs


vector2d
Object
Type	Name
number (float)	x
number (float)	y
Functions
new (constructor)
vector2d.new(x: number, y: number)

Argument	Type	Description
x	number (float)	x value
y	number (float)	y value
Example
local some_vector2d = vector2d.new(69, 420)

vertex
Object
Type	Name
vector2d	position
vector2d	texCoord
Functions
new (constructor)
vertex.new(position: vector2d, texCoord: vector2d)

Argument	Type	Description
position	vector2d	position
texCoord	vector2d	texture coordinate
Example
local some_vertex = vertex.new(vector2d.new(69, 420), vector2d.new(1337, 0))
Made with Material for MkDocs


qangle
Object
Type	Name
number (float)	x
number (float)	y
number (float)	z
Functions
new (constructor)
qangle.new(x: number, y: number, z: number)

Argument	Type	Description
x	number (float)	x value
y	number (float)	y value
z	number (float)	z value
Example
local some_qangle = qangle.new(69, 420, 1337)
Made with Material for MkDocs
