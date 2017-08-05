--[[ Old mailbox.lua from kilbith's excellent X-Decor mod
     https://github.com/minetest-mods/xdecor
     GPL3 ]]

local mailbox = {}

-- Load support for intllib.
local MP = minetest.get_modpath(minetest.get_current_modname())
local S, NS = dofile(MP.."/intllib.lua")

screwdriver = screwdriver or {}


function mailbox.get_formspec(pos, owner, fs_type)
	local selected = "false"
	if minetest.get_node(pos).name == "mailbox:letterbox" then
		selected = "true"
	end
	local xbg = default.gui_bg .. default.gui_bg_img .. default.gui_slots
	local spos = pos.x .. "," ..pos.y .. "," .. pos.z

	if fs_type == 1 then
		return "size[8,9.5]" .. xbg .. default.get_hotbar_bg(0, 5.5) ..
			"checkbox[0,0;books_only;"..S("Only allow written books")..";" .. selected .. "]" ..
			"list[nodemeta:" .. spos .. ";mailbox;0,1;8,4;]" ..
			"list[current_player;main;0,5.5;8,1;]" ..
			"list[current_player;main;0,6.75;8,3;8]" ..
			"listring[nodemeta:" .. spos .. ";mailbox]" ..
			"listring[current_player;main]" ..
			"button_exit[7,0;1,1;exit;X]"
	else
		return "size[8,5.5]" .. xbg .. default.get_hotbar_bg(0, 1.5) ..
			"label[0,0;"..S("Send your goods\nto: @1", owner).."]" ..
			"list[nodemeta:" .. spos .. ";drop;3.5,0;1,1;]" ..
			"list[current_player;main;0,1.5;8,1;]" ..
			"list[current_player;main;0,2.75;8,3;8]" ..
			"listring[nodemeta:" .. spos .. ";drop]" ..
			"listring[current_player;main]"
	end
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if not formname:match("mailbox:mailbox_") then
		return
	end

	if fields.books_only then
		local pos = minetest.string_to_pos(formname:sub(17))
		local node = minetest.get_node(pos)
		if node.name == "mailbox:mailbox" then
			node.name = "mailbox:letterbox"
			minetest.swap_node(pos, node)
		else
			node.name = "mailbox:mailbox"
			minetest.swap_node(pos, node)
		end
	end
end)


mailbox.after_place_node = function(pos, placer, _)
	local meta = minetest.get_meta(pos)
	local player_name = placer:get_player_name()

	meta:set_string("owner", player_name)
	meta:set_string("infotext", S("@1's Mailbox", player_name))

	local inv = meta:get_inventory()
	inv:set_size("mailbox", 8*4)
	inv:set_size("drop", 1)
end

mailbox.on_rightclick = function(pos, _, clicker, _)
	local meta = minetest.get_meta(pos)
	local player = clicker:get_player_name()
	local owner = meta:get_string("owner")

	if player == owner then
		local spos = pos.x .. "," .. pos.y .. "," .. pos.z
		minetest.show_formspec(player, "mailbox:mailbox_" .. spos, mailbox.get_formspec(pos, owner, 1))
	else
		minetest.show_formspec(player, "mailbox:mailbox", mailbox.get_formspec(pos, owner, 0))
	end
end

mailbox.can_dig = function(pos, player)
	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")
	local player_name = player:get_player_name()
	local inv = meta:get_inventory()

	return inv:is_empty("mailbox") and player and player_name == owner
end

mailbox.on_metadata_inventory_put = function(pos, listname, index, stack, player)
	if listname == "drop" then
		local inv = minetest.get_meta(pos):get_inventory()
		if inv:room_for_item("mailbox", stack) then
			inv:remove_item("drop", stack)
			inv:add_item("mailbox", stack)
		end
	end
end

mailbox.allow_metadata_inventory_put = function(pos, listname, index, stack, player)
	if listname == "drop" then
		if minetest.get_node(pos).name == "mailbox:letterbox" and
				stack:get_name() ~= "default:book_written" then
			return 0
		end

		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		if inv:room_for_item("mailbox", stack) then
			return -1
		else
			minetest.chat_send_player(player:get_player_name(), S("Mailbox full."))
			return 0
		end
	end
	return 0
end


minetest.register_node("mailbox:mailbox", {
	description = S("Mailbox"),
	tiles = {
		"mailbox_mailbox_top.png", "mailbox_mailbox_bottom.png",
		"mailbox_mailbox_side.png", "mailbox_mailbox_side.png",
		"mailbox_mailbox.png", "mailbox_mailbox.png",
	},
	groups = {cracky = 3, oddly_breakable_by_hand = 1},
	on_rotate = screwdriver.rotate_simple,
	sounds = default.node_sound_defaults(),
	paramtype2 = "facedir",
	after_place_node = mailbox.after_place_node,
	on_rightclick = mailbox.on_rightclick,
	can_dig = mailbox.can_dig,
	on_metadata_inventory_put = mailbox.on_metadata_inventory_put,
	allow_metadata_inventory_put = mailbox.allow_metadata_inventory_put,
})

minetest.register_node("mailbox:letterbox", {
	description = S("Letterbox (you hacker you!)"),
	tiles = {
		"mailbox_letterbox_top.png", "mailbox_letterbox_bottom.png",
		"mailbox_letterbox_side.png", "mailbox_letterbox_side.png",
		"mailbox_letterbox.png", "mailbox_letterbox.png",
	},
	groups = {cracky = 3, oddly_breakable_by_hand = 1, not_in_creative_inventory = 1},
	on_rotate = screwdriver.rotate_simple,
	sounds = default.node_sound_defaults(),
	paramtype2 = "facedir",
	drop = "mailbox:mailbox",
	after_place_node = mailbox.after_place_node,
	on_rightclick = mailbox.on_rightclick,
	can_dig = mailbox.can_dig,
	on_metadata_inventory_put = mailbox.on_metadata_inventory_put,
	allow_metadata_inventory_put = mailbox.allow_metadata_inventory_put,
})

minetest.register_craft({
	output = "mailbox:mailbox",
	recipe = {
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
		{"default:book", "default:chest", "default:book"},
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"}
	}
})
