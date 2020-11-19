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
	"listring[current_name;src]"..
	"listring[current_player;main]"..
	"listring[current_name;dst]"..
	"listring[current_player;main]"..
	default.get_hotbar_bg(0, 4.25)

-- Node callback functions
local function can_dig(pos, player) -- Do not allow node to be dug if 'src' has item
	local meta = minetest.get_meta(pos);
	local inv = meta:get_inventory()
	return inv:is_empty("src")
end

local function allow_metadata_inventory_put(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	
	if listname == "dst" then
		return stack:get_count()
	elseif listname == "src" and minetest.check_player_privs(player:get_player_name(),{give=true}) and inv:is_empty("src") then
		return 1 -- Only allow one item to be selected
	else
		return 0
	end
end

local function allow_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, player)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local stack = inv:get_stack(from_list, from_index)
	
	if from_list == "dst" and to_list == "dst" then
		return allow_metadata_inventory_put(pos, to_list, to_index, stack, player)
	elseif minetest.check_player_privs(player:get_player_name(),{give=true}) then
		return allow_metadata_inventory_put(pos, to_list, to_index, stack, player)
	else 
		return 0
	end
end

local function allow_metadata_inventory_take(pos, listname, index, stack, player)
	-- if minetest.is_protected(pos, player:get_player_name()) then return 0 end
	if listname == "dst" then
		return stack:get_count()
	elseif listname == "src" and minetest.check_player_privs(player:get_player_name(),{give=true}) then
		return stack:get_count()
	else 
		return 0
	end
end

-- Node definitions
minetest.register_node("infchest:infchest", {
	description = "Infinite Chest",
	tiles = {
		"infchest_infchest_top.png", "infchest_infchest_bottom.png",
		"infchest_infchest_side.png", "infchest_infchest_side.png",
		"infchest_infchest_side.png", "infchest_infchest_front.png"
	},
	paramtype2 = "facedir",
	groups = {choppy = 1, oddly_breakable_by_hand = 1},
	legacy_facedir_simple = true,
	is_ground_content = false,
	
	sounds = default.node_sound_wood_defaults(),
	
	can_dig = can_dig,
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_take = allow_metadata_inventory_take
})

-- Alias
minetest.register_alias("infchest", "infchest:infchest")

-- ABM -- (optimization needed)
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
		for listname, size in pairs({src = 1, dst = 9}) do
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
