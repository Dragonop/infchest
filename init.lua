-- Formspec
local infchest_formspec =
	"size[8,8.5]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"list[current_name;src;1,1.5;1,1;]"..
	"list[current_name;dst;4,0.5;3,3;]"..
	"list[current_player;main;0,4.25;8,1;]"..
	"list[current_player;main;0,5.5;8,3;8]"..
	"listring[current_name;dst]"..
	"listring[current_player;main]"..
	"listring[current_name;src]"..
	"listring[current_player;main]"..
	"listring[current_player;main]"..
	default.get_hotbar_bg(0, 4.25)

-- Node definitions

minetest.register_node("infchest:infchest", {
	description = "Infinite Chest",
	tiles = {"infchest_infchest"},
	paramtype2 = "facedir",
	groups = {choppy = 1, oddly_breakable_by_hand = 1},
	legacy_facedir_simple = true,
	is_ground_content = false,
	
	sounds = default.node_sound_wood_defaults(),
	
	can_dig = can_dig,
})

local function can_dig(pos, player)
	local meta = minetest.get_meta(pos);
	local inv = meta:get_inventory()
	return inv:is_empty("src")
end

-- ABM
minetest.register_abm({
    label = "infchest generating",
	nodenames = {"infchest:infchest"},
	interval = 1.0,
	chance = 1,
	action = function(pos, node)
		-- Inizialize metadata
		local meta = minetest.get_meta(pos)
		
		-- Inizialize inventory
		local inv = meta:get_inventory()
		for listname, size in pairs({
				src = 1,
				dst = 9
		}) do
			if inv:get_size(listname) ~= size then
				inv:set_size(listname, size)
			end
		end
		
		-- Generate more items
		local srclist = inv:get_list("src")
		local dstlist = inv:get_list("dst")
		if inv:room_for_item("dst", ItemStack( {inv:get_stack("src", 1):get_name()} ) )
					then
						inv:add_item("dst", inv:get_stack("src", 1):get_name() )
		end
	
		-- Update formspec, infotext and node
		
		local formspec = infchest_formspec -- In case I want to add active formspecs in the future
		local item_state = ""
		if srclist[1]:is_empty() then
			item_state = "not generating"
		else
			item_state = "generating " .. inv:get_stack("src", 1):get_name()
		end

		local infotext =  "Chest " .. item_state

		-- Set meta values
		meta:set_string("formspec", formspec) 
		meta:set_string("infotext", infotext)
	end
})
