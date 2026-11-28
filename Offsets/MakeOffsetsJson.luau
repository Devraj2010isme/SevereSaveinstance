local JSONDecode = crypt.json.decode
local JSONEncode = crypt.json.encode
local Version = game:GetClientVersion()
local PropList = { -- PropList from SevereSaveintanceXML.luau

}

local Theo_Offsets = JSONDecode(readfile("TheoTemp.json")).Offsets -- JSONDecode(game:HttpGet("https://raw.githubusercontent.com/Devraj2010isme/SevereSaveinstance/refs/heads/main/Offsets/TheoOffsets/" .. Version .. ".json")).Offsets
local Offsets = {}

local function GetOffset(ClassName, PropertyName)
	local OffsetsOfClass = Theo_Offsets[ClassName]
	if not OffsetsOfClass then
		return
	end
	local Offset = OffsetsOfClass[PropertyName]
	return Offset
end

for ClassName, Properties in PropList do -- Theo's Offsets then Jonah's Offsets
	Offsets[ClassName] = {}
	for PropertyName, PropertyTable in Properties do
		local PropertyMode = PropertyTable[1]
		if PropertyMode == 1 then
			local Namespace = PropertyTable[5]
			local Offset = GetOffset(Namespace or PropertyTable[4] or ClassName, PropertyTable[3] or PropertyName)
			
			if Namespace and not Offsets[ClassName][Namespace] then
				local NamespaceOffset = GetOffset(ClassName, Namespace)
				if NamespaceOffset then
					Offsets[ClassName][Namespace] = NamespaceOffset
				else
					warn("Offset for namespace " .. PropertyName .. " of class" .. ClassName .. " not available")
				end
			end
			
			if Namespace and not Offsets[Namespace] then
				Offsets[Namespace] = {}
			end
			
			if Offset then
				Offsets[Namespace or ClassName][PropertyName] = Offset
			else
				warn("Offset for property " .. PropertyName .. " of class" .. ClassName .. " not available")
			end
		end
	end
end

Offsets.VisualEngine = Theo_Offsets.VisualEngine
Offsets.FakeDataModel = Theo_Offsets.FakeDataModel
Offsets.DataModel = Theo_Offsets.DataModel

Offsets.Tool.Grip = Theo_Offsets.Tool.Grip - 36 -- Correct offset (Theo's "Grip" offset is actually the GripPos offset)
Offsets.Attachment.Position = Theo_Offsets.Attachment.Position
Offsets.CharacterMesh.BaseTextureId = Theo_Offsets.CharacterMesh.BaseTextureId
Offsets.CharacterMesh.MeshId = Theo_Offsets.CharacterMesh.MeshId
Offsets.CharacterMesh.OverlayTextureId = Theo_Offsets.CharacterMesh.OverlayTextureId
Offsets.Folder.IconTint = Theo_Offsets.Folder.IconTint
Offsets.Camera.FieldOfView = Theo_Offsets.Camera.FieldOfView
Offsets.ViewportFrame.CameraFieldOfView = Theo_Offsets.ViewportFrame.CameraFieldOfView
Offsets.Lighting.ClockTime = Theo_Offsets.Lighting.ClockTime
Offsets.Terrain.MaterialColors = Theo_Offsets.Terrain.MaterialColors
Offsets.Instance.DefinesCapabilities = Theo_Offsets.Instance.Sandboxed

Offsets.Instance.ChildrenStart = Theo_Offsets.Instance.ChildrenStart
Offsets.Instance.ClassDescriptor = Theo_Offsets.Instance.ClassDescriptor
Offsets.Instance.Parent = Theo_Offsets.Instance.Parent

Offsets.Font = Theo_Offsets.Font

Offsets.Primitive.Material = Theo_Offsets.Primitive.Material
Offsets.Primitive.RootPriority = Theo_Offsets.Primitive.RootPriority
Offsets.Primitive.Flags = Theo_Offsets.Primitive.Flags
Offsets.PrimitiveFlags = Theo_Offsets.PrimitiveFlags
Offsets.World.AirProperties = Theo_Offsets.World.AirProperties
Offsets.AirProperties = Theo_Offsets.AirProperties

Offsets.Bytecode = Theo_Offsets.ByteCode
Offsets.Script.Bytecode = Theo_Offsets.LocalScript.ByteCode -- LocalScript and Script have the same bytecode offset
Offsets.LocalScript = {Bytecode = Theo_Offsets.LocalScript.ByteCode}
Offsets.ModuleScript.Bytecode = Theo_Offsets.ModuleScript.ByteCode

writefile("Offsets.json", JSONEncode(Offsets))

--[[ Execute this prior to dumping Theo offsets:
sethiddenproperty(game.StarterGui.TextLabel, "LocalizationMatchIdentifier", "LocalizationMatchIdentifier_Value")
sethiddenproperty(game.StarterGui.TextLabel, "LocalizationMatchedSourceText", "LocalizationMatchedSourceText_Value")
sethiddenproperty(game.StarterGui.TextButton, "LocalizationMatchIdentifier", "LocalizationMatchIdentifier_Value")
sethiddenproperty(game.StarterGui.TextButton, "LocalizationMatchedSourceText", "LocalizationMatchedSourceText_Value")
sethiddenproperty(game.StarterGui.TextBox, "LocalizationMatchIdentifier", "LocalizationMatchIdentifier_Value")
sethiddenproperty(game.StarterGui.TextBox, "LocalizationMatchedSourceText", "LocalizationMatchedSourceText_Value")
]]