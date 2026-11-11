-- Loads the shared mod code once, whichever hook file runs first.
if not CosmeticAttachmentPreview then
	dofile(ModPath .. "mod.lua")
end

local CAP = CosmeticAttachmentPreview

local function get_factory_id(category, slot)
	local crafted = managers.blackmarket:get_crafted_category(category)
	local weapon = crafted and crafted[slot]

	return weapon and weapon.factory_id
end

local function get_part(part_id)
	return part_id and tweak_data.weapon.factory.parts[part_id]
end

-- Make the saved cosmetics visible in the preview UI as soon as the mod list
-- is opened, even in a fresh game session.
Hooks:PreHook(BlackMarketGui, "populate_mods", "cap_populate_mods", function(self, data)
	local prev = data and data.prev_node_data

	if prev and prev.category and prev.slot then
		managers.blackmarket:get_preview_blueprint(prev.category, prev.slot)
	end
end)

-- Previewing a mod is the action that saves it as a permanent cosmetic.
Hooks:PostHook(BlackMarketGui, "preview_weapon_with_mod_callback", "cap_preview_weapon_with_mod", function(self, data)
	if not data or not data.category or not data.slot or not data.name then
		return
	end

	local factory_id = get_factory_id(data.category, data.slot)
	local part = get_part(data.name)

	if not factory_id or not part or not part.type then
		return
	end

	if CAP:is_cosmetic_type(part.type) then
		CAP:set_cosmetic(factory_id, part.type, data.name)
	else
		log("[CosmeticAttachmentPreview] Ignoring non-cosmetic part type: " .. tostring(part.type))
	end
end)

-- "Preview without this mod" also removes the saved cosmetic for that slot.
Hooks:PreHook(BlackMarketGui, "preview_weapon_without_mod_callback", "cap_preview_weapon_without_mod", function(self, data)
	if not data or not data.category or not data.slot or not data.name then
		return
	end

	local factory_id = get_factory_id(data.category, data.slot)
	local part = get_part(data.name)

	if factory_id and part and part.type and CAP:get_cosmetic(factory_id, part.type) == data.name then
		CAP:clear_cosmetic(factory_id, part.type)
	end
end)

-- The vanilla "clear preview" button clears every cosmetic for this weapon.
Hooks:PreHook(BlackMarketGui, "clear_weapon_mod_preview_callback", "cap_clear_weapon_mod_preview", function(self, data)
	if not data or not data.category or not data.slot then
		return
	end

	local factory_id = get_factory_id(data.category, data.slot)

	if factory_id then
		CAP:clear_weapon(factory_id)
	end
end)
