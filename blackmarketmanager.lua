-- Loads the shared mod code once, whichever hook file runs first.
if not CosmeticAttachmentPreview then
	dofile(ModPath .. "mod.lua")
end

local CAP = CosmeticAttachmentPreview

local function get_crafted_weapon(manager, category, slot)
	local crafted = manager._global and manager._global.crafted_items

	return crafted and crafted[category] and crafted[category][slot]
end

-- The game builds the preview blueprint from the equipped weapon. We inject the
-- saved cosmetic parts into that same table so the preview UI keeps showing
-- them as previewed (and keeps showing the right model) between sessions.
local original_get_preview_blueprint = BlackMarketManager.get_preview_blueprint

function BlackMarketManager:get_preview_blueprint(category, slot)
	local blueprint = original_get_preview_blueprint(self, category, slot)
	local weapon = get_crafted_weapon(self, category, slot)

	if not blueprint or not weapon or not weapon.factory_id then
		return blueprint
	end

	-- The game calls this several times per frame/action. Only inject once per
	-- blueprint table and saved-data revision; otherwise a fresh preview (or a
	-- vanilla preview of another mod) would be overwritten by the old cosmetic.
	if self._cap_preview_blueprint == blueprint and self._cap_preview_version == CAP.data_version then
		return blueprint
	end

	self._cap_preview_blueprint = blueprint
	self._cap_preview_version = CAP.data_version

	CAP:apply_to_blueprint(weapon.factory_id, blueprint, true)

	return blueprint
end
