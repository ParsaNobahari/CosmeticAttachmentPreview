-- CosmeticAttachmentPreview
-- Keeps the *model* of a previewed weapon attachment on the weapon without
-- actually equipping it (stats and gameplay stay untouched).

CosmeticAttachmentPreview = CosmeticAttachmentPreview or {}

local CAP = CosmeticAttachmentPreview

CAP.version = "1.0.0"
CAP.save_file = (SavePath or "mods/saves/") .. "cosmetic_attachment_preview.json"
CAP.saved = CAP.saved or {}
CAP.data_version = CAP.data_version or 1
CAP.migrated = CAP.migrated or false

-- These part types are not purely visual. Adding them to the assembled weapon
-- would change gameplay (underbarrel launchers, bipods, ammo, ...), so they are
-- deliberately ignored. Magazines are allowed: only their model is assembled,
-- while ammo capacity is still read from the original equipped blueprint.
local NON_COSMETIC_TYPES = {
	underbarrel = true,
	underbarrel_ammo = true,
	ammo = true,
	bipod = true,
	charm = true,
	deployable = true,
	armor = true,
	throwable = true,
	melee = true
}

local function debug_log(message)
	log("[CosmeticAttachmentPreview] " .. tostring(message))
end

local function get_parts_tweak()
	return tweak_data
		and tweak_data.weapon
		and tweak_data.weapon.factory
		and tweak_data.weapon.factory.parts
end

-- The default part for a type is the one the weapon ships with. It is used
-- when a saved cosmetic is the `false` "default/none" marker.
local function get_default_part_id(factory_id, part_type)
	local parts = get_parts_tweak()
	local factory = tweak_data and tweak_data.weapon and tweak_data.weapon.factory
	local factory_tweak = factory and factory[factory_id]
	local default_blueprint = factory_tweak and factory_tweak.default_blueprint

	if not parts or not default_blueprint then
		return nil
	end

	for _, part_id in ipairs(default_blueprint) do
		local part = parts[part_id]

		if part and part.type == part_type then
			return part_id
		end
	end

	return nil
end

local function remove_parts_of_type(blueprint, part_type)
	local parts = get_parts_tweak()

	if not parts then
		return false
	end

	local removed = false

	for i = #blueprint, 1, -1 do
		local part = parts[blueprint[i]]

		if part and part.type == part_type then
			table.remove(blueprint, i)

			removed = true
		end
	end

	return removed
end

function CAP:save()
	local success, contents = pcall(json.encode, self.saved)

	if not success then
		debug_log("JSON encoding failed: " .. tostring(contents))
		return false
	end

	local file, err = io.open(self.save_file, "w")

	if not file then
		debug_log("Cannot open save file: " .. tostring(err))
		return false
	end

	file:write(contents)
	file:close()

	return true
end

function CAP:load()
	local file = io.open(self.save_file, "r")

	if not file then
		self.saved = {}
		debug_log("No existing save, creating " .. self.save_file)
		return self:save()
	end

	local contents = file:read("*all")
	file:close()

	local success, data = pcall(json.decode, contents)

	if success and type(data) == "table" then
		self.saved = data
		self:migrate()
		self.data_version = self.data_version + 1
		debug_log("Loaded cosmetic configurations from " .. self.save_file)
		return true
	end

	debug_log("Save file could not be decoded, starting fresh.")
	self.saved = {}
	self.data_version = self.data_version + 1
	return false
end

-- Older builds stored saved[factory_id][slot_number] = part_id. Convert those
-- entries to the current saved[factory_id][part_type] = part_id layout.
function CAP:migrate()
	local parts = tweak_data
		and tweak_data.weapon
		and tweak_data.weapon.factory
		and tweak_data.weapon.factory.parts

	if not parts then
		return false
	end

	self.migrated = true

	for factory_id, weapon_data in pairs(self.saved) do
		if type(weapon_data) ~= "table" then
			self.saved[factory_id] = nil
		else
			local migrated = {}

			for key, part_id in pairs(weapon_data) do
				-- JSON object keys are always strings, so old numeric slot keys
				-- come back as "1", "2", ... instead of numbers.
				local slot = type(key) == "number" and key or (type(key) == "string" and tonumber(key))

				if slot then
					local part = type(part_id) == "string" and parts[part_id]

					if part and part.type then
						migrated[part.type] = part_id
					end
				else
					migrated[key] = part_id
				end
			end

			self.saved[factory_id] = migrated
		end
	end

	return true
end

function CAP:get_cosmetics(factory_id)
	-- tweak_data may not have been ready when the save was first loaded.
	if not self.migrated then
		self:migrate()
	end

	local data = factory_id and self.saved[factory_id]

	return type(data) == "table" and data or nil
end

function CAP:get_cosmetic(factory_id, part_type)
	local data = self:get_cosmetics(factory_id)

	return data and data[part_type]
end

function CAP:set_cosmetic(factory_id, part_type, part_id)
	if not factory_id or not part_type or not part_id then
		return false
	end

	self.saved[factory_id] = self.saved[factory_id] or {}

	if self.saved[factory_id][part_type] == part_id then
		return true
	end

	self.saved[factory_id][part_type] = part_id
	self.data_version = self.data_version + 1
	debug_log(string.format("Saved cosmetic %s for %s (%s)", tostring(part_id), tostring(factory_id), tostring(part_type)))

	return self:save()
end

-- `false` means "show this type's default model (or no model at all)".
-- It is used by "preview without mod" on an equipped part so the equipped
-- gadget/grip model can be hidden without unequipping it.
function CAP:set_default_cosmetic(factory_id, part_type)
	if not factory_id or not part_type then
		return false
	end

	self.saved[factory_id] = self.saved[factory_id] or {}

	if self.saved[factory_id][part_type] == false then
		return true
	end

	self.saved[factory_id][part_type] = false
	self.data_version = self.data_version + 1
	debug_log(string.format("Saved default/none cosmetic for %s (%s)", tostring(factory_id), tostring(part_type)))

	return self:save()
end

function CAP:clear_cosmetic(factory_id, part_type)
	local data = self:get_cosmetics(factory_id)

	if not data or data[part_type] == nil then
		return false
	end

	data[part_type] = nil

	if not next(data) then
		self.saved[factory_id] = nil
	end

	self.data_version = self.data_version + 1
	debug_log(string.format("Cleared cosmetic %s for %s", tostring(part_type), tostring(factory_id)))

	return self:save()
end

function CAP:clear_weapon(factory_id)
	if not self.saved[factory_id] then
		return false
	end

	self.saved[factory_id] = nil
	self.data_version = self.data_version + 1
	debug_log("Cleared all cosmetics for " .. tostring(factory_id))

	return self:save()
end

function CAP:is_part_allowed(factory_id, part_id)
	local parts = tweak_data
		and tweak_data.weapon
		and tweak_data.weapon.factory
		and tweak_data.weapon.factory.parts
	local part = parts and parts[part_id]
	local factory = managers.weapon_factory
	local parts_by_weapon = factory and factory._parts_by_weapon and factory._parts_by_weapon[factory_id]

	if not part or not part.type or not parts_by_weapon then
		return false
	end

	local allowed = parts_by_weapon[part.type]

	return allowed and table.contains(allowed, part_id) or false
end

-- Adds the saved cosmetic parts to a weapon blueprint. When in_place is false
-- the blueprint is cloned first so the caller's (stat) blueprint is untouched.
function CAP:apply_to_blueprint(factory_id, blueprint, in_place)
	if not factory_id or type(blueprint) ~= "table" then
		return blueprint
	end

	local cosmetics = self:get_cosmetics(factory_id)

	if not cosmetics or not next(cosmetics) then
		return blueprint
	end

	local factory = managers.weapon_factory

	if not factory or not factory.change_part_blueprint_only then
		return blueprint
	end

	local out = in_place and blueprint or deep_clone(blueprint)

	-- Apply in a stable order so the resulting part order (and therefore the
	-- attachment model) is identical on every call and every game session.
	local part_types = {}

	for part_type in pairs(cosmetics) do
		if type(part_type) == "string" then
			part_types[#part_types + 1] = part_type
		end
	end

	table.sort(part_types)

	for _, part_type in ipairs(part_types) do
		local part_id = cosmetics[part_type]

		if not NON_COSMETIC_TYPES[part_type] then
			if part_id == false then
				local default_part_id = get_default_part_id(factory_id, part_type)

				if default_part_id and self:is_part_allowed(factory_id, default_part_id) then
					if not factory:change_part_blueprint_only(factory_id, default_part_id, out) then
						debug_log(string.format("Could not apply default part %s to %s", tostring(default_part_id), tostring(factory_id)))
					end
				else
					remove_parts_of_type(out, part_type)
				end
			elseif self:is_part_allowed(factory_id, part_id) then
				if not factory:change_part_blueprint_only(factory_id, part_id, out) then
					debug_log(string.format("Could not apply cosmetic %s to %s", tostring(part_id), tostring(factory_id)))
				end
			end
		end
	end

	return out
end

function CAP:is_cosmetic_type(part_type)
	return part_type and not NON_COSMETIC_TYPES[part_type] or false
end

CAP:load()

debug_log("Version " .. CAP.version .. " initialized.")
