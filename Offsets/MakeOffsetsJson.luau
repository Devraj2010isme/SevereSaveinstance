local JSONDecode = crypt.json.decode
local JSONEncode = crypt.json.encode
local Version = game:GetClientVersion()
local PropList = { -- PropList from SevereSaveintanceXML.luau

}

local Theo_Offsets = JSONDecode(game:HttpGet("https://raw.githubusercontent.com/Devraj2010isme/SevereSaveinstance/refs/heads/main/Offsets/TheoOffsets/" .. Version .. ".json")).Offsets
local Jonah_Offsets = JSONDecode(game:HttpGet("https://raw.githubusercontent.com/Devraj2010isme/SevereSaveinstance/refs/heads/main/Offsets/JonahOffsets/" .. Version .. ".json")).offsets
local Offsets = {}

local function GetOffset(OffsetSet, ClassName, PropertyName)
	local OffsetsOfClass = OffsetSet[ClassName]
	if not OffsetsOfClass then
		return
	end
	local Offset = OffsetsOfClass[PropertyName]
	if Offset and Offset ~= 0 then
		return Offset
	else
		return
	end
end

for ClassName, Properties in PropList do -- Theo's Offsets then Jonah's Offsets
	Offsets[ClassName] = {}
	for PropertyName, PropertyTable in Properties do
		local PropertyMode = PropertyTable[1]
		if (PropertyMode == 3 or PropertyMode == 4) and not PropertyTable[5] then
			local Offset = GetOffset(Theo_Offsets, PropertyTable[4] or ClassName, PropertyTable[3] or PropertyName)
			
			if not Offset then
				Offset = GetOffset(Jonah_Offsets, PropertyTable[4] or ClassName, PropertyTable[3] or PropertyName)
			end
			
			if Offset then
				Offsets[ClassName][PropertyName] = Offset
			else
				warn("Offset for property " .. PropertyName .. " of class" .. ClassName .. " not available")
			end
		end
	end
end

Offsets.Tool.Grip = Jonah_Offsets.Tool.Grip -- Correct offset (Theo's "Grip" offset is actually the GripPos offset)
--Offsets.Attachment.Position = Theo_Offsets.Attachment.Position

-- Namespaces
Offsets.MaterialColors = Theo_Offsets.MaterialColors
Offsets.Primitive = Theo_Offsets.Primitive
Offsets.World = Theo_Offsets.World
Offsets.Namespaces = {}
Offsets.Namespaces.Primitive = Theo_Offsets.BasePart.Primitive
Offsets.Primitive.CFrame = Theo_Offsets.Primitive.Rotation
Offsets.Namespaces.World = Theo_Offsets.Workspace.World

writefile("Offsets.json", JSONEncode(Offsets))