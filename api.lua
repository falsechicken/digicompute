-- digiterm/api.lua

-- FORMSPECS
-- normal
function digiterm.formspec_normal(output, input)
  if not output then local output = "" end
  if not input then local input = "" end
  local formspec =
    "size[10,11]"..
    default.gui_bg_img..
    "textarea[.25,.25;10,10.5;output;Output:;"..output.."]"..
    "button[0,9.5;10,1;update;Update Output]"..
    "field[.25,10.75;9,1;input;;"..input.."]"..
    "button[8.7,10.43;1.30,1;submit;<enter>]"
  return formspec
end
-- set channel (currently unused)
function digiterm.formspec_channel(channel)
  if not channel then local channel = "" end -- use blank channel is none specified
  local formspec =
    "size[6,1.7]"..
    default.gui_bg_img..
    "field[.25,0.50;6,1;channel;Channel:;"..channel.."]"..
    "button[4.95,1;1,1;submit;Set]"
  return formspec
end
-- /FORMSPECS

-- SYSTEM FUNCTIONS
-- turn on (not functional)
function digiterm.on(pos, node)
  minetest.swap_node({x = pos.x, y = pos.y, z = pos.z}, {name = "digiterm:"..node.."_bios"}) -- set node to bios
  minetest.after(3.5, function(pos_)
    minetest.swap_node({x = pos_.x, y = pos_.y, z = pos_.z}, {name = "digiterm:"..node.."_on"}) -- set node to on after 5 seconds
  end, vector.new(pos))
  local meta = minetest.get_meta(pos) -- get meta
  meta:set_string("formspec", digiterm.formspec_operating(true))
end
-- turn off
function digiterm.off(pos, termstring)
  local meta = minetest.get_meta(pos) -- get meta
  meta:set_string("formspec", "") -- clear formspec
  meta = nil -- clear meta variable
  minetest.swap_node(pos, "digiterm:"..termstring) -- set node to off
end
-- reboot
function digiterm.reboot(pos, termstring)
  digiterm.off(pos, termstring)
  digiterm.on(pos, termstring)
end
-- /SYSTEM FUNCTIONS

function digiterm.register_terminal(termstring, desc)
  -- off
  minetest.register_node("digiterm:"..termstring, {
    description = desc.description,
    tiles = desc.off_tiles,
    paramtype2 = "facedir",
    groups = {cracky = 2},
    sounds = default.node_sound_stone_defaults(),
    digiline = {
      receptor = {},
      effector = {
        action = function(pos, node, channel, msg)
          local meta = minetest.get_meta(pos) -- get meta
          -- if channel is correct, turn on
          if channel == meta:get_string("channel") then
            if msg.system == "on" then
              digiterm.on(pos, termstring)
            end
          end
        end
      },
    },
    on_rightclick = function(pos)
      digiterm.on(pos, termstring)
    end,
  })
  -- bios
  minetest.register_node("digiterm:"..termstring.."_bios", {
    description = desc.description,
    tiles = desc.bios_tiles,
    paramtype2 = "facedir",
  	groups = {cracky = 2},
  	sounds = default.node_sound_stone_defaults(),
  })
  -- on
  minetest.register_node("digiterm:"..termstring.."_on", {
    description = desc.description,
    tiles = desc.on_tiles,
    paramtype2 = "facedir",
  	groups = {cracky = 2},
  	sounds = default.node_sound_stone_defaults(),
    digiline = {
      receptor = {},
      effector = {
        action = function(pos, node, channel, msg)
          local meta = minetest.get_meta(pos) -- get meta
          if channel ~= meta:get_string("channel") then return end -- ignore if not proper channel
          if type(msg) ~= "table" then
            meta:set_string("output", meta:get_string("output")..msg) -- set output buffer meta
          elseif type(msg) == "table" then -- process tables
            if msg.display == "clear" then meta:set_string("output", "") end -- clear display
          end
        end
      },
    },
    on_construct = function(pos) -- set meta and formspec
      local meta = minetest.get_meta(pos) -- get meta
      meta:set_string("output", "") -- output buffer
      meta:set_string("input", "") -- input buffer
      meta:set_string("formspec", "field[channel;Set Channel:;${channel}]") -- channel specification formspec
    end,
    on_receive_fields = function(pos, formname, fields, sender) -- precess formdata
      local meta = minetest.get_meta(pos) -- get meta
      -- if channel received, set meta
      if fields.channel then
        meta:set_string("channel", fields.channel) -- set channel meta
        meta:set_string("formspec", digiterm.formspec_operating(true)) -- refresh formspec
        return
      end
      -- if submit, reset field print to output and send digiline
      if fields.submit then
        digiline:receptor_send(pos, digiline.rules.default, meta:get_string("channel"), fields.input) -- send digiline data
        meta:set_string("output", meta:get_string("channel").."@minetest:~$\n "..fields.input.."\n") -- repeat input
      else meta:set_string("input", fields.input) end -- else, do nothing
      -- refresh formspec
      meta:set_string("formspec", digiterm.formspec_operating(meta:get_string("formspec"):sub(0, 1) ~= " "))
    end,
  })
end