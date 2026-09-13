-- Credits: UniversalSynSaveInstance
local function string_find(s, pattern)
	return string.find(s, pattern, nil, true)
end

local function __BIT(...) -- * Credits to Friend (you know yourself)
	local Value = 0

	for i, bit in { ... } do
		if bit then
			Value += 2 ^ (i - 1)
		end
	end

	return Value
end

local function index(self, index_name)
	return self[index_name]
end

local attr_Type_IDs = {
	string = 0x02,
	boolean = 0x03,
	-- int32 = 0x04,
	-- float = 0x05,
	number = 0x06,
	-- Array = 0x07,
	-- Dictionary = 0x08,
	UDim = 0x09,
	UDim2 = 0x0A,
	Ray = 0x0B,
	Faces = 0x0C,
	Axes = 0x0D,
	BrickColor = 0x0E,
	Color3 = 0x0F,
	Vector2 = 0x10,
	Vector3 = 0x11,
	Vector2int16 = 0x12,
	Vector3int16 = 0x13,
	CFrame = 0x14,
	EnumItem = 0x15,
	NumberSequence = 0x17,
	NumberSequenceKeypoint = 0x18,
	ColorSequence = 0x19,
	ColorSequenceKeypoint = 0x1A,
	NumberRange = 0x1B,
	Rect = 0x1C,
	PhysicalProperties = 0x1D,
	Region3 = 0x1F,
	Region3int16 = 0x20,
	Font = 0x21,
}

local CFrame_Rotation_IDs = {
	["\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63"] = 0x02,
	["\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0\0\0\128\63\0\0\0\0"] = 0x03,
	["\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191"] = 0x05,
	["\0\0\128\63\0\0\0\0\0\0\0\128\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0\0\0\128\191\0\0\0\0"] = 0x06,
	["\0\0\0\0\0\0\128\63\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191"] = 0x07,
	["\0\0\0\0\0\0\0\0\0\0\128\63\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0"] = 0x09,
	["\0\0\0\0\0\0\128\191\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\128\0\0\0\0\0\0\0\0\0\0\128\63"] = 0x0a,
	["\0\0\0\0\0\0\0\0\0\0\128\191\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0"] = 0x0c,
	["\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\128\63\0\0\0\0\0\0\0\0"] = 0x0d,
	["\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0\0\0\128\63\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\0"] = 0x0e,
	["\0\0\0\0\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\128\63\0\0\0\0\0\0\0\0"] = 0x10,
	["\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0\0\0\128\191\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\128"] = 0x11,
	["\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191"] = 0x14,
	["\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0\0\0\128\63\0\0\0\128"] = 0x15,
	["\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63"] = 0x17,
	["\0\0\128\191\0\0\0\0\0\0\0\128\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0\0\0\128\191\0\0\0\128"] = 0x18,
	["\0\0\0\0\0\0\128\63\0\0\0\128\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63"] = 0x19,
	["\0\0\0\0\0\0\0\0\0\0\128\191\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0"] = 0x1b,
	["\0\0\0\0\0\0\128\191\0\0\0\128\0\0\128\191\0\0\0\0\0\0\0\128\0\0\0\0\0\0\0\0\0\0\128\191"] = 0x1c,
	["\0\0\0\0\0\0\0\0\0\0\128\63\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0"] = 0x1e,
	["\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\128\191\0\0\0\0\0\0\0\0"] = 0x1f,
	["\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0\0\0\128\63\0\0\0\128\0\0\128\191\0\0\0\0\0\0\0\0"] = 0x20,
	["\0\0\0\0\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\128\191\0\0\0\0\0\0\0\0"] = 0x22,
	["\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0\0\0\128\191\0\0\0\128\0\0\128\191\0\0\0\0\0\0\0\128"] = 0x23,
}

local Binary_Descriptors
Binary_Descriptors = {
	__SEQUENCE = function(raw, valueFormatter, keypointSize, Envelope)
		local Keypoints = raw.Keypoints
		local Keypoints_n = #Keypoints

		local len = 4 + (keypointSize or 12) * Keypoints_n
		local b = buffer.create(len)
		local offset = 0

		buffer.writeu32(b, offset, Keypoints_n)
		offset += 4

		for _, keypoint in Keypoints do
			buffer.writef32(b, offset, Envelope or keypoint.Envelope)
			offset += 4
			buffer.writef32(b, offset, keypoint.Time)
			offset += 4

			local Value = keypoint.Value
			if valueFormatter then
				offset += valueFormatter(Value, b, offset)
			else
				buffer.writef32(b, offset, Value)
				offset += 4
			end
		end

		return b, len
	end,
	--------------------------------------------------------------
	--------------------------------------------------------------
	--------------------------------------------------------------
	["string"] = function(raw)
		local raw_len = #raw
		local len = 4 + raw_len

		local b = buffer.create(len)

		buffer.writeu32(b, 0, raw_len)
		buffer.writestring(b, 4, raw)

		return b, len
	end,
	["boolean"] = function(raw)
		local b = buffer.create(1)

		buffer.writeu8(b, 0, raw and 1 or 0)

		return b, 1
	end,
	["number"] = function(raw) -- double
		local b = buffer.create(8)

		buffer.writef64(b, 0, raw)

		return b, 8
	end,
	["UDim"] = function(raw)
		local b = buffer.create(8)

		buffer.writef32(b, 0, raw.Scale)
		buffer.writei32(b, 4, raw.Offset)

		return b, 8
	end,
	["UDim2"] = function(raw)
		local b = buffer.create(16)

		local UDim__descriptor = Binary_Descriptors.UDim
		local X = UDim__descriptor(raw.X)
		buffer.copy(b, 0, X)
		local Y = UDim__descriptor(raw.Y)
		buffer.copy(b, 8, Y)

		return b, 16
	end,
	["Ray"] = function(raw)
		local b = buffer.create(24)

		local Vector3__descriptor = Binary_Descriptors.Vector3
		local Origin = Vector3__descriptor(raw.Origin)
		buffer.copy(b, 0, Origin)
		local Direction = Vector3__descriptor(raw.Direction)
		buffer.copy(b, 12, Direction)

		return b, 24
	end,
	["Faces"] = function(raw)
		local b = buffer.create(4)

		buffer.writeu32(b, 0, __BIT(raw.Right, raw.Top, raw.Back, raw.Left, raw.Bottom, raw.Front))

		return b, 4
	end,
	["Axes"] = function(raw)
		local b = buffer.create(4)

		buffer.writeu32(b, 0, __BIT(raw.X, raw.Y, raw.Z))

		return b, 4
	end,
	["BrickColor"] = function(raw)
		local b = buffer.create(4)

		buffer.writeu32(b, 0, raw.Number)

		return b, 4
	end,
	["Color3"] = function(raw)
		local b = buffer.create(12)

		buffer.writef32(b, 0, raw.R)
		buffer.writef32(b, 4, raw.G)
		buffer.writef32(b, 8, raw.B)

		return b, 12
	end,
	["Vector2"] = function(raw)
		local b = buffer.create(8)

		buffer.writef32(b, 0, raw.X)
		buffer.writef32(b, 4, raw.Y)

		return b, 8
	end,
	["Vector3"] = function(raw)
		local b = buffer.create(12)

		buffer.writef32(b, 0, raw.X)
		buffer.writef32(b, 4, raw.Y)
		buffer.writef32(b, 8, raw.Z)

		return b, 12
	end,
	["Vector2int16"] = function(raw)
		local b = buffer.create(4)

		buffer.writei16(b, 0, raw.X)
		buffer.writei16(b, 2, raw.Y)

		return b, 4
	end,
	["Vector3int16"] = function(raw)
		local b = buffer.create(6)

		buffer.writei16(b, 0, raw.X)
		buffer.writei16(b, 2, raw.Y)
		buffer.writei16(b, 4, raw.Z)

		return b, 6
	end,
	["CFrame"] = function(raw)
		local X, Y, Z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = raw:GetComponents()

		local rotation_ID = CFrame_Rotation_IDs[string.pack("<fffffffff", R00, R01, R02, R10, R11, R12, R20, R21, R22)]

		local len = rotation_ID and 13 or 49
		local b = buffer.create(len)

		-- ? TODO cleaner but slower ?
		-- local write_vector3 = Descriptors.Vector3
		-- local pos = write_vector3(raw.Position)
		-- buffer.copy(b, 0, pos)

		buffer.writef32(b, 0, X)
		buffer.writef32(b, 4, Y)
		buffer.writef32(b, 8, Z)

		if rotation_ID then
			buffer.writeu8(b, 12, rotation_ID)
		else
			buffer.writeu8(b, 12, 0x0)

			-- ? TODO cleaner but slower ?
			-- buffer.copy(b, 13, write_vector3(raw.XVector)) -- R00, R10, R20
			-- buffer.copy(b, 13 + 12, write_vector3(raw.YVector)) -- R01, R11, R21
			-- buffer.copy(b, 13 + 24, write_vector3(raw.ZVector)) -- R02, R12, R22

			buffer.writef32(b, 13, R00)
			buffer.writef32(b, 17, R01)
			buffer.writef32(b, 21, R02)

			buffer.writef32(b, 25, R10)
			buffer.writef32(b, 29, R11)
			buffer.writef32(b, 33, R12)

			buffer.writef32(b, 37, R20)
			buffer.writef32(b, 41, R21)
			buffer.writef32(b, 45, R22)
		end

		return b, len
	end,
	["EnumItem"] = function(raw)
		local b_Name, Name_size = Binary_Descriptors.string(tostring(raw.EnumType))

		local len = Name_size + 4
		local b = buffer.create(len)

		buffer.copy(b, 0, b_Name)
		buffer.writeu32(b, Name_size, raw.Value)

		return b, len
	end,
	["NumberSequence"] = nil,
	-- ["NumberSequenceKeypoint"] = nil, -- TODO Only impl. if necessary because NumberSequence will reference this therefore slowing down itself
	["ColorSequence"] = function(raw)
		return Binary_Descriptors.__SEQUENCE(raw, function(color3, b, offset)
			buffer.copy(b, offset, Binary_Descriptors.Color3(color3))
			return 12
		end, 20, 0)
	end,
	-- ["ColorSequenceKeypoint"] = nil, -- TODO Only impl. if necessary because ColorSequence will reference this therefore slowing down itself
	["NumberRange"] = function(raw)
		local b = buffer.create(8)

		buffer.writef32(b, 0, raw.Min)
		buffer.writef32(b, 4, raw.Max)

		return b, 8
	end,
	["Rect"] = function(raw)
		local b = buffer.create(16)

		local Vector2__descriptor = Binary_Descriptors.Vector2
		local Min = Vector2__descriptor(raw.Min)
		buffer.copy(b, 0, Min)
		local Max = Vector2__descriptor(raw.Max)
		buffer.copy(b, 8, Max)

		return b, 16
	end,
	["PhysicalProperties"] = function(raw) -- ? Not sure yet (https://github.com/RobloxAPI/spec/blob/master/properties/drafts/AttributesSerializeFull.md#physicalproperties)
		local len = 1
		if raw then
			len += 24
		end
		local b = buffer.create(len)

		buffer.writeu8(b, 0, raw and 3 or 0) -- 3 means it has set CustomPhysicalProperties & has set AcousticAbsorption

		if raw then
			buffer.writef32(b, 1, raw.Density)
			buffer.writef32(b, 5, raw.Friction)
			buffer.writef32(b, 9, raw.Elasticity)
			buffer.writef32(b, 13, raw.FrictionWeight)
			buffer.writef32(b, 17, raw.ElasticityWeight)
			buffer.writef32(b, 21, raw.AcousticAbsorption)
		end

		return b, len
	end,
	["Region3"] = function(raw)
		local b = buffer.create(24)

		local Vector3__descriptor = Binary_Descriptors.Vector3
		local Min = Vector3__descriptor(raw.Min)
		buffer.copy(b, 0, Min)
		local Max = Vector3__descriptor(raw.Max)
		buffer.copy(b, 12, Max)

		return b, 24
	end,
	["Region3int16"] = function(raw)
		local b = buffer.create(12)

		local Vector3int16__descriptor = Binary_Descriptors.Vector3int16
		local Min = Vector3int16__descriptor(raw.Min)
		buffer.copy(b, 0, Min)
		local Max = Vector3int16__descriptor(raw.Max)
		buffer.copy(b, 6, Max)

		return b, 12
	end,
	["Font"] = function(raw)
		local string__descriptor = Binary_Descriptors.string

		local b_Family, Family_size = string__descriptor(raw.Family)
		local b_CachedFaceId, CachedFaceId_size = string__descriptor("")

		local len = 3 + Family_size + CachedFaceId_size
		local b = buffer.create(len)

		local ok_w, weight = pcall(index, raw, "Weight")
		local ok_s, style = pcall(index, raw, "Style")

		buffer.writeu16(b, 0, ok_w and weight.Value or 0)
		buffer.writeu8(b, 2, ok_s and style.Value or 0)

		buffer.copy(b, 3, b_Family)
		buffer.copy(b, 3 + Family_size, b_CachedFaceId)

		return b, len
	end or function(raw)
		local string__descriptor = Binary_Descriptors.string

		local b_Family, Family_size = string__descriptor(raw.Family)
		local b_CachedFaceId, CachedFaceId_size = string__descriptor("")

		local len = 3 + Family_size + CachedFaceId_size
		local b = buffer.create(len)

		local FontString = tostring(raw)

		local EmptyWeight = string_find(FontString, "Weight = ,")
		local EmptyStyle = string_find(FontString, "Style =  }")

		buffer.writeu16(b, 0, EmptyWeight and 0 or raw.Weight.Value)
		buffer.writeu8(b, 2, EmptyStyle and 0 or raw.Style.Value)

		buffer.copy(b, 3, b_Family)
		buffer.copy(b, 3 + Family_size, b_CachedFaceId)

		return b, len
	end,
}
do
	Binary_Descriptors.NumberSequence = Binary_Descriptors.__SEQUENCE
end

local function MakeAttributesSerialize(instance)
	-- * There are certain restrictions for names of attributes
	-- https://create.roblox.com/docs/reference/engine/classes/Instance#SetAttribute
	-- But it seems like even if those are present, Studio still opens the file just fine
	-- So there is no need to check for them currently

	-- TODO: merge sequence Descriptors and some other descriptors where possible (check xml descriptors)
	-- ? Return early for empty tags (this proved equally as fast when done using counter/next)

	local attrs = instance:GetAttributes()

	if not next(attrs) then
		return ""
	end

	local attrs_n = 0
	local buffer_size = 4
	local attrs_sorted = {}
	local attrs_formatted = table.clone(attrs)
	for attr, val in attrs do
		attrs_n += 1
		attrs_sorted[attrs_n] = attr

		local Type = typeof(val)

		local Descriptor = Binary_Descriptors[Type]
		local attr_size

		attrs_formatted[attr], attr_size = Descriptor(val)

		buffer_size += 5 + #attr + attr_size
	end

	table.sort(attrs_sorted)

	local b = buffer.create(buffer_size)

	local offset = 0

	buffer.writeu32(b, offset, attrs_n)
	offset += 4

	local string__descriptor = Binary_Descriptors.string
	for _, attr in attrs_sorted do
		local b_Name, Name_size = string__descriptor(attr)

		buffer.copy(b, offset, b_Name)
		offset += Name_size

		buffer.writeu8(b, offset, attr_Type_IDs[typeof(attrs[attr])])
		offset += 1

		local bb = attrs_formatted[attr]

		buffer.copy(b, offset, bb)
		offset += buffer.len(bb)
	end

	return buffer.tostring(b)
end

return MakeAttributesSerialize