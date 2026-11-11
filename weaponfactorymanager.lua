-- Loads the shared mod code once, whichever hook file runs first.
if not CosmeticAttachmentPreview then
	dofile(ModPath .. "mod.lua")
end

local CAP = CosmeticAttachmentPreview

-- The real (equipped) blueprint is what the game uses for stats. We only give
-- the expanded blueprint to the assembly code, then hand the original blueprint
-- back to the weapon so damage, accuracy, concealment, perks, etc. do not change.
local function assemble_with_cosmetics(manager, original_assemble, factory_id, p_unit, blueprint, third_person, npc, done_cb, skip_queue, ...)
	if npc or type(blueprint) ~= "table" then
		return original_assemble(manager, factory_id, p_unit, blueprint, third_person, npc, done_cb, skip_queue, ...)
	end

	local cosmetic_blueprint = CAP:apply_to_blueprint(factory_id, blueprint, false)

	if cosmetic_blueprint == blueprint then
		return original_assemble(manager, factory_id, p_unit, blueprint, third_person, npc, done_cb, skip_queue, ...)
	end

	local wrapped_done_cb = done_cb and function(parts)
		return done_cb(parts, blueprint)
	end

	local parts = original_assemble(manager, factory_id, p_unit, cosmetic_blueprint, third_person, npc, wrapped_done_cb, skip_queue, ...)

	return parts, blueprint
end

local original_assemble_from_blueprint = WeaponFactoryManager.assemble_from_blueprint

function WeaponFactoryManager:assemble_from_blueprint(factory_id, p_unit, blueprint, third_person, npc, done_cb, skip_queue)
	return assemble_with_cosmetics(self, original_assemble_from_blueprint, factory_id, p_unit, blueprint, third_person, npc, done_cb, skip_queue)
end

local original_assemble_default = WeaponFactoryManager.assemble_default

function WeaponFactoryManager:assemble_default(factory_id, p_unit, third_person, npc, done_cb, skip_queue)
	local factory = tweak_data.weapon.factory[factory_id]

	if npc or not factory or not factory.default_blueprint then
		return original_assemble_default(self, factory_id, p_unit, third_person, npc, done_cb, skip_queue)
	end

	if not CAP:get_cosmetics(factory_id) then
		return original_assemble_default(self, factory_id, p_unit, third_person, npc, done_cb, skip_queue)
	end

	-- Vanilla clones the default blueprint; do the same so the weapon never
	-- holds (or mutates) the shared tweak_data table.
	local default_blueprint = deep_clone(factory.default_blueprint)

	return assemble_with_cosmetics(self, original_assemble_from_blueprint, factory_id, p_unit, default_blueprint, third_person, npc, done_cb, skip_queue)
end
