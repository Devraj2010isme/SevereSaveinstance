--!native
--!optimize 2

-- Saveinstance for Severe External

local Base64Encode = crypt.base64.encode
local JSONDecode = crypt.json.decode
local Version = game:GetClientVersion()
local Offsets = JSONDecode(game:HttpGet("https://raw.githubusercontent.com/Devraj2010isme/SevereSaveinstance/refs/heads/main/Offsets/" .. Version .. ".json"))
if not Offsets then -- JSONDecode returns nil for invalid JSON
	warn("Failed to get offets for version " .. Version)
	return
end
local ZSTDDecompress = loadstring(game:HttpGet("https://raw.githubusercontent.com/kingdudely/roblox-ts-scripts/refs/heads/main/fzstd/index.luau"))().decompress

local DataModel
do -- DataModel
	local VisualEngine = memory.readu64(memory.base, Offsets.VisualEngine.Pointer)
	local FakeDataModel = memory.readu64(VisualEngine, Offsets.VisualEngine.FakeDataModel)
	local RealDataModel = memory.readu64(FakeDataModel, Offsets.FakeDataModel.RealDataModel)
	if not RealDataModel or RealDataModel == 0 then
		error("Failed to find the datamodel")
	end
	DataModel = RealDataModel
end

local ChildrenStartOffset = Offsets.Instance.ChildrenStart
local ClassDescriptorOffset = Offsets.Instance.ClassDescriptor
local ParentOffset = Offsets.Instance.Parent
local NameContainerOffset = Offsets.Instance.NameContainer

local function GetChildren(Instance) -- Because Severe's GetChildren is slow
	local ChildrenListPointer = memory.readu64(Instance, ChildrenStartOffset)
	
	if ChildrenListPointer ~= 0 then
		local CurrentChildPointer = memory.readu64(ChildrenListPointer)
		local ChildrenEndPointer = memory.readu64(ChildrenListPointer, 8)
		
		local Children = {}
		
		repeat
			table.insert(Children, memory.readu64(CurrentChildPointer))
			CurrentChildPointer += 16
		until CurrentChildPointer >= ChildrenEndPointer
		
		return Children
	end
end

local function ReadString(Data, Offset, IncludeNullStrings) -- Because memory.readstring cuts off after 512 characters
	local Pointer = memory.readu64(Data, Offset)
	local Length = memory.readu64(Data, Offset + 16)
	
	if Pointer == 0 or Length == 0 or Length >= 200000 then
		return ""
	end
	
	local StringData
	local StringData2
	
	local Success = pcall(function()
		StringData = buffer.tostring(memory.readbuffer(Pointer, Length))
	end)
	
	if Length <= 15 and not Success then
		StringData2 = buffer.tostring(memory.readbuffer(Data + Offset, Length))
		if IncludeNullStrings or not string.find(StringData2, "\0", 1, true) then
			return StringData2
		end
	end
	
	if not Success or (not IncludeNullStrings and string.find(StringData, "\0", 1, true)) then
		return ""
	end
	
	return StringData
end

local function GetClassName(Instance)
	local ClassDescriptor = memory.readu64(Instance, ClassDescriptorOffset)
	local ClassNameHolder = memory.readu64(ClassDescriptor, 8)
	
	if ClassNameHolder == 0 then
		return "Instance"
	end
	
	return ReadString(ClassNameHolder, 0)
end

local function GetName(Instance)
	local NameHolder = memory.readu64(Instance, NameContainerOffset)
	return ReadString(NameHolder, 0)
end

local function GetParent(Instance)
	return memory.readu64(Instance, ParentOffset)
end

local function GetService(ServiceName)
	local Children = GetChildren(game)
	for _, Child in Children do
		if GetClassName(Child) == ServiceName then
			return Child
		end
	end
	return 0
end

local FontFamilyOffset = Offsets.Font.Family
local FontWeightOffset = Offsets.Font.Weight
local FontStyleOffset = Offsets.Font.Style
local FontCachedFaceIdOffset = Offsets.Font.CachedFaceId

local MemoryReadFunctions = {
	bool = memory.readbool,
	float = memory.readf32,
	double = memory.readf64,
	Color3 = memory.readvector,
	ref = memory.readu64,
	token = memory.readi32,
	BrickColor = memory.readi32,
	int = memory.readi32,
	int64 = memory.readu64,
	Vector3 = memory.readvector,
	Vector2 = memory.readvector,
	CoordinateFrame = function(Data, Offset)
		local CFrame = {}
		CFrame.RightVector = memory.readvector(Data, Offset)
		CFrame.UpVector = memory.readvector(Data, Offset + 12)
		CFrame.LookVector = memory.readvector(Data, Offset + 24)
		CFrame.Position = memory.readvector(Data, Offset + 36)
		return CFrame
	end,
	Color3uint8 = function(Data, Offset)
		local Color = {}
		Color.R = memory.readu8(Data, Offset)
		Color.G = memory.readu8(Data, Offset + 1)
		Color.B = memory.readu8(Data, Offset + 2)
		return Color
	end,
	string = ReadString,
	ContentId = ReadString,
	Content = ReadString,
	BinaryString = function(Data, Offset)
		return ReadString(Data, Offset, true)
	end,
	NumberRange = function(Data, Offset)
		return {memory.readf32(Data, Offset), memory.readf32(Data, Offset + 4)}
	end,
	UDim2 = function(Data, Offset)
		local UDim2 = {}
		UDim2.XS = memory.readf32(Data, Offset)
		UDim2.XO = memory.readi32(Data, Offset + 4)
		UDim2.YS = memory.readf32(Data, Offset + 8)
		UDim2.YO = memory.readi32(Data, Offset + 12)
		return UDim2
	end,
	Ray = function(Data, Offset)
		local Ray = {}
		Ray.Origin = memory.readvector(Data, Offset)
		Ray.Direction = memory.readvector(Data, Offset + 12)
		return Ray
	end,
	Font = function(Data, Offset)
		local Font = {}
		local FontHolder = memory.readu64(Data, Offset)
		Font.Family = ReadString(FontHolder, FontFamilyOffset)
		Font.Weight = memory.readi32(FontHolder, FontWeightOffset)
		Font.Style = memory.readbool(FontHolder, FontStyleOffset)
		Font.CachedFaceId = ReadString(FontHolder, FontCachedFaceIdOffset)
		return Font
	end,
	Rect2D = function(Data, Offset)
		local Rect = {}
		Rect.MinX = memory.readf32(Data, Offset)
		Rect.MinY = memory.readf32(Data, Offset + 4) 
		Rect.MaxX = memory.readf32(Data, Offset + 8) 
		Rect.MaxY = memory.readf32(Data, Offset + 12)
		return Rect
	end
}

local PrimitiveOffset = Offsets.BasePart.Primitive
local PrimitiveFlagsOffset = Offsets.Primitive.Flags
local MaterialOffset = Offsets.Primitive.Material
local RootPriorityOffset = Offsets.Primitive.RootPriority
local RunContextOffset = Offsets.BaseScript.RunContext

local function ReadPrimitiveFlag(inst, PropertyName)
	local Prim = memory.readu64(inst, PrimitiveOffset)
	return bit32.band(memory.readu8(Prim, PrimitiveFlagsOffset), Offsets.PrimitiveFlags[PropertyName]) ~= 0
end

local function ContentIdToU64(inst, PropertyName, Class)
	local Offset = Offsets[Class][PropertyName]
	local raw = ReadString(inst, Offset)
	
	if not string.find(raw, "rbxassetid", 1, true) then
		return 0
	end
	
	return tonumber(string.sub(raw, 14))
end

local function Color3uint8ToColor3(inst, PropertyName, Class)
	local Offset = Offsets[Class][PropertyName]
	local Color = {}
	Color.X = memory.readu8(inst, Offset) / 255
	Color.Y = memory.readu8(inst, Offset + 1) / 255
	Color.Z = memory.readu8(inst, Offset + 2) / 255
	return Color
end

local function RadiansToDegrees(inst, PropertyName, Class)
	local Offset = Offsets[Class][PropertyName]
	return memory.readf32(inst, Offset) * 180/math.pi
end

local PropList = { -- Hardcoded because Severe can only read certain arbitrary properties 
	--[[ Classname = {
		PropertyName: {PropertyReadMode: 1 = Memory, 2 = PropertyFunction, 3 = Decompile}
		ValueType: String
		PropertyFunction: Function (mode 2), PropertyNameOverride: String (mode 1, only used when dumping offsets)
		ClassNameOverride: String (mode 1, only used when dumping offsets)
		Namespace: String (mode 1, reads properties from a different namespace such as Primitive)
		}
	} ]]
	Instance = {
		Tags = {
			2, "BinaryString",
			function(inst)
				local InstanceUserdata = pointer_to_userdata(inst)
				local tags = InstanceUserdata:GetTags()
				if #tags == 0 then
					return ""
				end
				return table.concat(tags, "\0")
			end
		},
		AttributesSerialize = {
			2, "BinaryString",
			function(inst) -- All Severe Attributes are string type
				local InstanceUserdata = pointer_to_userdata(inst)
				local Success, Attributes = pcall(function() return InstanceUserdata:GetAttributes() end) -- GetAttributes sometimes fails with the message "invalid string position"
				
				if not Success or not next(Attributes) then
					return ""
				end
				
				local AttributesCount = 0
				local Size = 4
				
				for AttributeName, AttributeData in Attributes do
					AttributesCount += 1
					Size += (#AttributeName + #AttributeData + 9)
				end
				
				local b = buffer.create(Size)
				buffer.writeu32(b, 0, AttributesCount)
				local Offset = 4
				
				for AttributeName, AttributeData in Attributes do
					buffer.writeu32(b, Offset, #AttributeName)
					Offset += 4
					buffer.writestring(b, Offset, AttributeName)
					Offset += #AttributeName
					buffer.writeu8(b, Offset, 2) -- String Type Id
					Offset += 1
					buffer.writeu32(b, Offset, #AttributeData)
					Offset += 4
					buffer.writestring(b, Offset, AttributeData)
					Offset += #AttributeData
				end
				
				return buffer.tostring(b)
			end
		},
		Name = {1, "string", nil, nil, "NameContainer"}
	},
	Workspace = {
		CurrentCamera = {1, "ref"},
		Gravity = {1, "float", "ReadOnlyGravity"},
		FallenPartsDestroyHeight = {1, "float", nil, nil, "World"},
		AirDensity = {
			2, "float",
			function(inst)
				local World = memory.readu64(inst, Offsets.Workspace.World)
				local AirProperties = memory.readu64(World, Offsets.World.AirProperties)
				return memory.readf32(AirProperties, Offsets.AirProperties.AirDensity)
			end
		},
		GlobalWind = {
			2, "Vector3",
			function(inst)
				local World = memory.readu64(inst, Offsets.Workspace.World)
				local AirProperties = memory.readu64(World, Offsets.World.AirProperties)
				return memory.readvector(AirProperties, Offsets.AirProperties.GlobalWind)
			end
		}
	},
	Camera = {
		CFrame = {1, "CoordinateFrame", "Rotation"},
		CameraSubject = {1, "ref"},
		CameraType = {1, "token"},
		FieldOfView = {2, "float", RadiansToDegrees},
		FieldOfViewMode = {1, "token"},
		Focus = {1, "CoordinateFrame"},
		HeadLocked = {1, "bool"},
		HeadScale = {1, "float"},
		OrthographicSize = {1, "float"},
		VRTiltAndRollEnabled = {1, "bool"}
		-- TODO OrthographicMode, ProjectionType, ViewStretch
	},
	CharacterMesh = {
		BaseTextureId = {2, "int64", ContentIdToU64},
		BodyPart = {1, "token"},
		MeshId = {2, "int64", ContentIdToU64},
		OverlayTextureId = {2, "int64", ContentIdToU64}
	},
	Highlight = {
		Adornee = {1, "ref"},
		DepthMode = {1, "token"},
		Enabled = {1, "bool"},
		FillColor = {1, "Color3"},
		FillTransparency = {1, "float"},
		OutlineColor = {1, "Color3"},
		OutlineTransparency = {1, "float"}
	},
	HopperBin = {
		BinType = {1, "token"},
		Active = {1, "bool"}
	},
	Seat = {
		Occupant = {1, "ref"},
		Disabled = {1, "bool"}
	},
	Lighting = {
		Ambient = {1, "Color3"},
		Brightness = {1, "float"},
		ColorShift_Top = {1, "Color3"},
		ColorShift_Bottom = {1, "Color3"},
		EnvironmentDiffuseScale = {1, "float"},
		EnvironmentSpecularScale = {1, "float"},
		ExposureCompensation = {1, "float"},
		FogColor  = {1, "Color3"},
		FogEnd = {1, "float"},
		FogStart = {1, "float"},
		OutdoorAmbient = {1, "Color3"},
		ShadowSoftness = {1, "float"},
		GeographicLatitude = {1, "float"},
		GlobalShadows = {1, "bool"},
		ClockTime = {
			2, "float",
			function(inst)
				return memory.readu64(inst, Offsets.Lighting.ClockTime) / 3.6e+9 -- ClockTime is stored as microseconds in memory
			end
		}
	},
	Sky = {
		SkyboxBk = {1, "ContentId"},
		SkyboxDn = {1, "ContentId"},
		SkyboxFt = {1, "ContentId"},
		SkyboxLf = {1, "ContentId"},
		SkyboxRt = {1, "ContentId"},
		SkyboxUp = {1, "ContentId"},
		SunAngularSize = {1, "float"},
		MoonAngularSize = {1, "float"},
		SunTextureId = {1, "ContentId"},
		MoonTextureId = {1, "ContentId"},
		SkyboxOrientation = {1, "Vector3"},
		StarCount = {1, "int"},
		CelestialBodiesShown = {1, "bool"}
	},
	DataModelMesh = {
		Scale = {1, "Vector3"},
		Offset = {1, "Vector3"},
		VertexColor = {1, "Vector3"}
	},
	FileMesh = {
		MeshId = {1, "ContentId"},
		TextureId = {1, "ContentId"}
	},
	SpecialMesh = {
		MeshType = {1, "token"}
	},
	BevelMesh = {
		Bevel = {1, "float"},
		["Bevel Roundness"] = {1, "float"},
		Bulge = {1, "float"}
	},
	Team = {
		TeamColor = {1, "BrickColor", "BrickColor"}
	},
	Terrain = {
		GrassLength = {1, "float"},
		WaterColor = {1, "Color3"},
		WaterReflectance = {1, "float"},
		WaterTransparency = {1, "float"},
		WaterWaveSize = {1, "float"},
		WaterWaveSpeed = {1, "float"},
		MaterialColors = {
			2, "BinaryString",
			function(inst)
				local MaterialColorsPointer = memory.readu64(inst, Offsets.Terrain.MaterialColors)
				return buffer.tostring(memory.readbuffer(MaterialColorsPointer, 69))
			end
		}
	},
	BackpackItem = {
		TextureId = {1, "ContentId", nil, "Tool"},
	},
	Tool = {
		Tooltip = {1, "string"},
		Enabled = {1, "bool"},
		CanBeDropped = {1, "bool"},
		ManualActivationOnly = {1, "bool"},
		RequiresHandle = {1, "bool"},
		Grip = {1, "CoordinateFrame"}
	},
	Flag = {
		TeamColor = {1, "BrickColor"}
	},
	VehicleSeat = {
		MaxSpeed = {1, "float"},
		SteerFloat = {1, "float"},
		ThrottleFloat = {1, "float"},
		Torque = {1, "float"},
		TurnSpeed = {1, "float"},
		Occupant = {1, "ref"}
	},
	SurfaceAppearance = {
		AlphaMode = {1, "token"},
		Color = {1, "Color3"},
		ColorMap = {1, "ContentId"},
		EmissiveStrength = {1, "float"},
		EmissiveTint = {1, "Color3"},
		MetalnessMap = {1, "ContentId"},
		NormalMap = {1, "ContentId"},
		RoughnessMap = {1, "ContentId"},
		EmissiveMaskContent = {1, "Content"}
	},
	ParticleEmitter = {
		Brightness = {1, "float"},
		LightEmission = {1, "float"},
		LightInfluence = {1, "float"},
		Texture = {1, "ContentId"},
		ZOffset = {1, "float"},
		Rate = {1, "float"},
		SpreadAngle = {1, "Vector2"},
		Acceleration = {1, "Vector3"},
		Drag = {1, "float"},
		TimeScale = {1, "float"},
		VelocityInheritance = {1, "float"},
		Lifetime = {1, "NumberRange"},
		Rotation = {1, "NumberRange"},
		RotSpeed = {1, "NumberRange"},
		Speed = {1, "NumberRange"}
	},
	Beam = {
		Brightness = {1, "float"},
		LightEmission = {1, "float"},
		LightInfluence = {1, "float"},
		Texture = {1, "ContentId"},
		TextureLength = {1, "float"},
		TextureSpeed = {1, "float"},
		ZOffset = {1, "float"},
		Attachment0 = {1, "ref"},
		Attachment1 = {1, "ref"},
		CurveSize0 = {1, "float"},
		CurveSize1 = {1, "float"},
		Width0 = {1, "float"},
		Width1 = {1, "float"},
	},
	Clothing = {
		Color3 = {1, "Color3"}
	},
	Shirt = {
		ShirtTemplate = {1, "ContentId"}
	},
	Pants = {
		PantsTemplate = {1, "ContentId"}
	},
	ShirtGraphic = {
		Color3 = {1, "Color3"},
		Graphic = {1, "ContentId"}
	},
	Skin = {
		SkinColor = {1, "BrickColor"}
	},
	LocalizationTable = {
		SourceLocaleId = {1, "string"}
	},
	--Attachment = {
	--	CFrame = { -- Component order is strange
	--		2, "CoordinateFrame",
	--		function(inst)
	--			if Offsets and Offsets.Attachment.Position then
	--				local Offset = Offsets.Attachment.Position 
	--				local CFrame = {}
	--				
	--				CFrame.RightVector = memory.readvector(Data, Offset - 12)
	--				CFrame.Position = memory.readvector(Data, Offset)
	--				CFrame.UpVector = memory.readvector(Data, Offset + 12)
	--				CFrame.LookVector = Vector3.new(0,0,0) -- TODO find LookVector
	--			end
	--		end
	--	}
	--},
	WeldConstraint = {
		Part0Internal = {1, "ref", "Part0"},
		Part1Internal = {1, "ref", "Part1"},
		Enabled = {1, "bool"},
		CFrame0 = {1, "CoordinateFrame", nil, nil, "ExplicitWeldJoint"}
	},
	JointInstance = {
		Part0 = {1, "ref"},
		Part1 = {1, "ref"},
		C0 = {1, "CoordinateFrame", nil, nil, "Joint"},
		C1 = {1, "CoordinateFrame", nil, nil, "Joint"},
		Enabled = {1, "bool"}
	},
	DynamicRotate = {
		BaseAngle = {1, "float", nil, nil, "Joint"}
	},
	Glue = {
		F0 = {1, "Vector3"},
		F1 = {1, "Vector3"},
		F2 = {1, "Vector3"},
		F3 = {1, "Vector3"}
	},
	Motor = {
		CurrentAngle = {1, "float", nil, nil, "Joint"},
		DesiredAngle = {1, "float", nil, nil, "Joint"},
		MaxVelocity = {1, "float", nil, nil, "Joint"},
	},
	VelocityMotor = {
		CurrentAngle = {1, "float", nil, nil, "Joint"},
		DesiredAngle = {1, "float", nil, nil, "Joint"},
		MaxVelocity = {1, "float", nil, nil, "Joint"},
		Hole = {1, "ref"}
	},
	Feature = {
		FaceId = {1, "token"},
		InOut = {1, "token"},
		LeftRight = {1, "token"},
		TopBottom = {1, "token"}
	},
	PartOperation = {
		AssetId = {1, "ContentId", nil, "UnionOperation"}
	},
	Decal = {
		Texture = {1, "ContentId", "Decal_Texture", "Textures"}		
	},
	LuaSourceContainer = {
		ScriptGuid = {1, "string", "GUID", "Script"},
	},
	BaseScript = {
		Disabled = {1, "bool"},
		RunContext = {1, "token"}
	},
	Script = {
		Source = {3, "ProtectedString"}
	},
	ModuleScript = {
		Source = {3, "ProtectedString"}
	},
	GuiBase2d = {
		AutoLocalize = {1, "bool"},
		RootLocalizationTable = {1, "ref"},
		SelectionGroup = {1, "bool"},
		SelectionBehaviorDown = {1, "token"},
		SelectionBehaviorLeft = {1, "token"},
		SelectionBehaviorRight = {1, "token"},
		SelectionBehaviorUp = {1, "token"}
	},
	LayerCollector = {
		Enabled = {1, "bool"},
		ResetOnSpawn = {1, "bool"},
		ZIndexBehavior = {1, "token"}
	},
	ScreenGui = {
		ClipToDeviceSafeArea = {1, "bool"},
		DisplayOrder = {1, "int"},
		SafeAreaCompatibility = {1, "token"},
		ScreenInsets = {1, "token"}
	},
	SurfaceGuiBase = {
		Active = {1, "bool"},
		Adornee = {1, "ref"},
		Face = {1, "token"}
	},
	SurfaceGui = {
		AlwaysOnTop = {1, "bool"},
		Brightness = {1, "float"},
		CanvasSize = {1, "Vector2"},
		ClipsDescendants = {1, "bool"},
		LightInfluence = {1, "float"},
		MaxDistance = {1, "float"},
		PixelsPerStud = {1, "float"},
		SizingMode = {1, "token"},
		ToolPunchThroughDistance = {1, "float"},
		ZOffset = {1, "float"}
	},
	AdGui = {
		FallbackImage = {1, "ContentId"},
		EnableVideoAds = {1, "bool"}
	},
	BillboardGui = {
		Active = {1, "bool"},
		Adornee = {1, "ref"},
		AlwaysOnTop = {1, "bool"},
		Brightness = {1, "float"},
		ClipsDescendants = {1, "bool"},
		DistanceLowerLimit = {1, "float"},
		DistanceUpperLimit = {1, "float"},
		ExtentsOffset = {1, "Vector3"},
		ExtentsOffsetWorldSpace = {1, "Vector3"},
		LightInfluence = {1, "float"},
		MaxDistance = {1, "float"},
		Size = {1, "UDim2"},
		SizeOffset = {1, "Vector2"},
		StudsOffset = {1, "Vector3"},
		StudsOffsetWorldSpace = {1, "Vector3"},
	},
	GuiObject = {
		Position = {1, "UDim2"},
		Size = {1, "UDim2"},
		Visible = {1, "bool"},
		BackgroundColor3 = {1, "Color3"},
		BorderColor3 = {1, "Color3"},
		LayoutOrder = {1, "int"},
		ZIndex = {1, "int"},
		BackgroundTransparency = {1, "float"},
		Rotation = {1, "float"},
		Active = {1, "bool"},
		AnchorPoint = {1, "Vector2"},
		AutomaticSize = {1, "token"},
		BorderMode = {1, "token"},
		BorderSizePixel = {1, "int"},
		ClipsDescendants = {1, "bool"},
		Interactable = {1, "bool"},
		Selectable = {1, "bool"},
		SelectionOrder = {1, "int"},
		SizeConstraint = {1, "token"},
		Draggable = {1, "bool"},
		NextSelectionDown = {1, "ref"},
		NextSelectionLeft = {1, "ref"},
		NextSelectionRight = {1, "ref"},
		NextSelectionUp = {1, "ref"},
		SelectionImageObject = {1, "ref"},
		Sink = {1, "token", "InputSink"}
	},
	Frame = {
		Style = {1, "token"}
	},
	CanvasGroup = {
		GroupColor3 = {1, "Color3"},
		GroupTransparency = {1, "float"}
	},
	ImageLabel = {
		Image = {1, "ContentId"},
		ImageColor3 = {1, "Color3"},
		ImageRectOffset = {1, "Vector2"},
		ImageRectSize = {1, "Vector2"},
		ImageTransparency = {1, "float"},
		ResampleMode = {1, "token"},
		ScaleType = {1, "token"},
		SliceCenter = {1, "Rect2D"},
		SliceScale = {1, "float"},
		TileSize = {1, "UDim2"}
	},
	ImageButton = {
		Image = {1, "ContentId"},
		ImageColor3 = {1, "Color3"},
		ImageRectOffset = {1, "Vector2"},
		ImageRectSize = {1, "Vector2"},
		ImageTransparency = {1, "float"},
		ResampleMode = {1, "token"},
		ScaleType = {1, "token"},
		SliceCenter = {1, "Rect2D"},
		SliceScale = {1, "float"},
		TileSize = {1, "UDim2"},
		PressedImage = {1, "ContentId"},
		HoverImage = {1, "ContentId"}
	},
	TextLabel = {
		Text = {1, "string"},
		TextColor3 = {1, "Color3"},
		MaxVisibleGraphemes = {1, "int"},
		RichText = {1, "bool"},
		LineHeight = {1, "float"},
		TextDirection = {1, "token"},
		TextScaled = {1, "bool"},
		TextSize = {1, "float"},
		TextStrokeColor3 = {1, "Color3"},
		TextStrokeTransparency = {1, "float"},
		TextTransparency = {1, "float"},
		TextTruncate = {1, "token"},
		TextWrapped = {1, "bool"},
		TextXAlignment = {1, "token"},
		TextYAlignment = {1, "token"},
		LocalizationMatchIdentifier = {1, "string"},
		LocalizationMatchedSourceText = {1, "string"},
		FontFace = {1, "Font"},
		OpenTypeFeatures = {1, "string", nil, nil, "OpenTypeFeatures"}
	},
	GuiButton = {
		AutoButtonColor = {1, "bool"},
		Modal = {1, "bool"},
		Selected = {1, "bool"},
		Style = {1, "token"},
		HoverHapticEffect = {1, "ref"},
		PressHapticEffect = {1, "ref"}
	},
	TextButton = {
		Text = {1, "string"},
		TextColor3 = {1, "Color3"},
		MaxVisibleGraphemes = {1, "int"},
		RichText = {1, "bool"},
		LineHeight = {1, "float"},
		TextDirection = {1, "token"},
		TextScaled = {1, "bool"},
		TextSize = {1, "float"},
		TextStrokeColor3 = {1, "Color3"},
		TextStrokeTransparency = {1, "float"},
		TextTransparency = {1, "float"},
		TextTruncate = {1, "token"},
		TextWrapped = {1, "bool"},
		TextXAlignment = {1, "token"},
		TextYAlignment = {1, "token"},
		LocalizationMatchIdentifier = {1, "string"},
		LocalizationMatchedSourceText = {1, "string"},
		FontFace = {1, "Font"},
		OpenTypeFeatures = {1, "string", nil, nil, "OpenTypeFeatures"}
	},
	TextBox = {
		ClearTextOnFocus = {1, "bool"},
		MultiLine = {1, "bool"},
		ShowNativeInput = {1, "bool"},
		TextEditable = {1, "bool"},
		PlaceholderText = {1, "string"},
		PlaceholderColor3 = {1, "Color3"},
		Text = {1, "string"},
		TextColor3 = {1, "Color3"},
		MaxVisibleGraphemes = {1, "int"},
		RichText = {1, "bool"},
		LineHeight = {1, "float"},
		TextDirection = {1, "token"},
		TextScaled = {1, "bool"},
		TextSize = {1, "float"},
		TextStrokeColor3 = {1, "Color3"},
		TextStrokeTransparency = {1, "float"},
		TextTransparency = {1, "float"},
		TextTruncate = {1, "token"},
		TextWrapped = {1, "bool"},
		TextXAlignment = {1, "token"},
		TextYAlignment = {1, "token"},
		LocalizationMatchIdentifier = {1, "string"},
		LocalizationMatchedSourceText = {1, "string"},
		FontFace = {1, "Font"},
		OpenTypeFeatures = {1, "string", nil, nil, "OpenTypeFeatures"}
	},
	ScrollingFrame = {
		AutomaticCanvasSize = {1, "token"},
		BottomImage = {1, "ContentId"},
		CanvasPosition = {1, "Vector2"},
		CanvasSize = {1, "UDim2"},
		ElasticBehavior = {1, "token"},
		HorizontalScrollBarInset = {1, "token"},
		MidImage = {1, "ContentId"},
		ScrollBarImageColor3 = {1, "Color3"},
		ScrollBarImageTransparency = {1, "float"},
		ScrollBarThickness = {1, "int"},
		ScrollingDirection = {1, "token"},
		ScrollingEnabled = {1, "bool"},
		TopImage = {1, "ContentId"},
		VerticalScrollBarInset = {1, "token"},
		VerticalScrollBarPosition = {1, "token"}
	},
	InputActionLabel = {
		ImageColor3 = {1, "Color3"},
		ImageTransparency = {1, "float"},
		InputAction = {1, "ref"},
		TextColor3 = {1, "Color3"},
		TextSize = {1, "float"},
		TextTransparency = {1, "float"},
		TextWrapped = {1, "bool"},
		TextXAlignment = {1, "token"},
		TextYAlignment = {1, "token"},
		FontFace = {1, "Font"}
	},
	VideoDisplay = {
		ResampleMode = {1, "token"},
		ScaleType = {1, "token"},
		TileSize = {1, "UDim2"},
		VideoColor3 = {1, "Color3"},
		VideoRectOffset = {1, "Vector2"},
		VideoRectSize = {1, "Vector2"},
		VideoTransparency = {1, "float"}
	},
	VideoPlayer = {
		InternalVideoUsage = {1, "token"},
		Looping = {1, "bool"},
		MaximumResolution = {1, "token"},
		PlaybackSpeed = {1, "float"},
		TimePosition = {1, "double"},
		Volume = {1, "float"}
	},
	VideoFrame = {
		InternalVideoUsage = {1, "token"},
		Looped = {1, "bool"},
		MaximumResolution = {1, "token"},
		Playing = {1, "bool"},
		RollOffMaxDistance = {1, "float"},
		RollOffMinDistance = {1, "float"},
		RollOffMode = {1, "token"},
		TimePosition = {1, "double"},
		Video = {1, "ContentId"},
		Volume = {1, "float"}
	},
	ViewportFrame = {
		Ambient = {1, "Color3"},
		CameraCFrame = {1, "CoordinateFrame"},
		CameraFieldOfView = {2, "float", RadiansToDegrees},
		ImageColor3 = {1, "Color3"},
		ImageTransparency = {1, "float"},
		LightColor = {1, "Color3"},
		LightDirection = {1, "Vector3"}
	},
	TextChannelWindow = {
		Target = {1, "ref"},
		UseDefaultFont = {1, "bool"},
		FontFace = {1, "Font"}
	},
	TextChannel = {
		AddPlayersOnJoin = {1, "bool"}
	},
	Message = {
		Text = {1, "string"}
	},
	Folder = {
		IconTint = {2, "Color3", Color3uint8ToColor3}
	},
	PVAdornment = {
		Adornee = {1, "ref", nil, "Misc"}
	},
	HandleAdornment = {
		CFrame = {1, "CoordinateFrame"}
	},
	BasePart = {
		size = {1, "Vector3", "Size", nil, "Primitive"},
		CFrame = {1, "CoordinateFrame", "Rotation", nil, "Primitive"},
		Velocity = {1, "Vector3", "AssemblyLinearVelocity", nil, "Primitive"},
		RotVelocity = {1, "Vector3", "AssemblyAngularVelocity", nil, "Primitive"},
		Material = {
			2, "token", 
			function(inst)
				return memory.readu16(memory.readu64(inst, PrimitiveOffset), MaterialOffset)
			end
		},
		RootPriority = {
			2, "int",
			function(inst)
				return memory.readi8(memory.readu64(inst, PrimitiveOffset), RootPriorityOffset)
			end
		},
		EnableFluidForces = {1, "bool", nil, nil, "Primitive"},
		Anchored = {2, "bool", ReadPrimitiveFlag},
		CanCollide = {2, "bool", ReadPrimitiveFlag},
		CanTouch = {2, "bool", ReadPrimitiveFlag},
		CanQuery = {2, "bool", ReadPrimitiveFlag},
		Reflectance = {1, "float"},
		Transparency = {1, "float"},
		LocalTransparencyModifier = {1, "float"},
		Color3uint8 = {1, "Color3uint8", "Color3"},
		AudioCanCollide = {1, "bool"},
		CastShadow = {1, "bool"},
		Locked = {1, "bool"},
		Massless = {1, "bool"},
		BackParamA = {1, "float"},
		BackParamB = {1, "float"},
		BackSurface = {1, "token"},
		BackSurfaceInput = {1, "token"},
		BottomParamA = {1, "float"},
		BottomParamB = {1, "float"},
		BottomSurface = {1, "token"},
		BottomSurfaceInput = {1, "token"},
		FrontParamA = {1, "float"},
		FrontParamB = {1, "float"},
		FrontSurface = {1, "token"},
		FrontSurfaceInput = {1, "token"},
		LeftParamA = {1, "float"},
		LeftParamB = {1, "float"},
		LeftSurface = {1, "token"},
		LeftSurfaceInput = {1, "token"},
		RightParamA = {1, "float"},
		RightParamB = {1, "float"},
		RightSurface = {1, "token"},
		RightSurfaceInput = {1, "token"},
		TopParamA = {1, "float"},
		TopParamB = {1, "float"},
		TopSurface = {1, "token"},
		TopSurfaceInput = {1, "token"}
	},
	Part = {
		shape = {1, "token", "Shape", "BasePart"},
	},
	FlagStand = {
		TeamColor = {1, "BrickColor"}
	},
	TrussPart = {
		style = {1, "token", "Style"}
	},
	SkateboardPlatform = {
		StickyWheels = {1, "bool"}
	},
	TriangleMeshPart = {
		InitialSize = {1, "Vector3", "MeshSize", "MeshPart"}
	},
	MeshPart = {
		MeshId = {1, "ContentId"},
		TextureID = {1, "ContentId", "Texture"}
	},
	Model = {
		PrimaryPart = {1, "ref"},
		ScaleFactor = {1, "float", "Scale"},
		LevelOfDetail = {1, "token"},
		ModelStreamingMode = {1, "token"}
	},
	ProceduralModel = {
		Size = {1, "Vector3"},
		Generator = {1, "ref"}
	},
	Humanoid = {
		MaxHealth = {1, "float"},
		Health = {1, "float"},
		AutoJumpEnabled = {1, "bool"},
		AutoRotate = {1, "bool"},
		AutomaticScalingEnabled = {1, "bool"},
		BreakJointsOnDeath = {1, "bool"},
		EvaluateStateMachine = {1, "bool"},
		Jump = {1, "bool"},
		PlatformStand = {1, "bool"},
		RequiresNeck = {1, "bool"},
		Sit = {1, "bool"},
		UseJumpPower = {1, "bool"},
		CameraOffset = {1, "Vector3"},
		DisplayDistanceType = {1, "token"},
		DisplayName = {1, "string"},
		HealthDisplayDistance = {1, "float"},
		HealthDisplayType = {1, "token"},
		HipHeight = {1, "float"},
		JumpHeight = {1, "float"},
		JumpPower = {1, "float"},
		MaxSlopeAngle = {1, "float"},
		NameDisplayDistance = {1, "float"},
		NameOcclusion = {1, "token"},
		RigType = {1, "token"},
		SeatPart = {1, "ref"},
		Walkspeed = {1, "float"},
		WalkToPoint = {1, "Vector3", "MoveToPoint"},
		WalkToPart = {1, "Vector3", "MoveToPart"},
		FloorMaterial = {1, "token"},
		MoveDirection = {1, "Vector3"},
		HumanoidRootPart = {1, "ref"}
	},
	ForceField = {
		Visible = {1, "bool"}
	},
	ProximityPrompt = {
		Enabled = {1, "bool"},
		RequiresLineOfSight = {1, "bool"},
		ActionText = {1, "string"},
		ObjectText = {1, "string"},
		HoldDuration = {1, "float"},
		MaxActivationDistance = {1, "float"},
		KeyboardKeyCode = {1, "token", "KeyCode"},
		GamepadKeyCode = {1, "token"}
	},
	ClickDetector = {
		MaxActivationDistance = {1, "float"},
		CursorIcon = {1, "ContentId", "MouseIcon"}
	},
	DragDetector = {
		ReferenceInstance = {1, "ref"},
		MaxDragAngle = {1, "float"},
		MaxDragTranslation = {1, "Vector3"},
		MinDragAngle = {1, "float"},
		MinDragTranslation = {1, "Vector3"},
		ActivatedCursorIcon = {1, "ContentId"},
		MaxForce = {1, "float"},
		MaxTorque = {1, "float"},
		Responsiveness = {1, "float"},
		ApplyAtCenterOfMass = {1, "bool"},
		Enabled = {1, "bool"},
		RunLocally = {1, "bool"},
		GamepadModeSwitchKeyCode = {1, "token"},
		KeyboardModeSwitchKeyCode = {1, "token"},
		VRSwitchKeyCode = {1, "token"},
		PermissionPolicy = {1, "token"},
		ResponseStyle = {1, "token"},
		DragStyle = {1, "token"},
		TrackballRadialPullFactor = {1, "float"},
		TrackballRollFactor = {1, "float"}
	},
	SpawnLocation = {
		Enabled = {1, "bool"},
		Neutral = {1, "bool"},
		AllowTeamChangeOnTouch = {1, "bool"},
		TeamColor = {1, "BrickColor"},
		Duration = {1, "int", "ForcefieldDuration"}
	},
	AnimationTrack = {
		Animation = {1, "ref"},
		Speed = {1, "float"},
		TimePosition = {1, "float"},
		Looped = {1, "bool"},
	},
	PostEffect = {
		Enabled = {1, "bool", nil, "BloomEffect"}
	},
	BloomEffect = {
		Intensity = {1, "float"},
		Threshold = {1, "float"},
		Size = {1, "float"},
	},
	BlurEffect = {
		Size = {1, "float"}
	},
	ColorCorrectionEffect = {
		Brightness = {1, "float"},
		Contrast = {1, "float"},
		TintColor = {1, "Color3"},
		Saturation = {1, "float"},
		ColorLutContent = {1, "string"},
		ColorLutIntensity = {1, "float"}
	},
	ColorGradingEffect = {
		TonemapperPreset = {1, "token"}
	},
	DepthOfFieldEffect = {
		FocusDistance = {1, "float"},
		FarIntensity = {1, "float"},
		NearIntensity = {1, "float"},
		InFocusRadius = {1, "float"}
	},
	SunRaysEffect = {
		Intensity = {1, "float"},
		Spread = {1, "float"}
	},
	Sound = {
		Looped = {1, "bool"},
		SoundId = {1, "ContentId"},
		RollOffMaxDistance = {1, "float"},
		RollOffMinDistance = {1, "float"},
		PlaybackSpeed = {1, "float"},
		Volume = {1, "float"},
		SoundGroup = {1, "ref"}
	},
	Atmosphere = {
		Color = {1, "Color3"},
		Decay = {1, "Color3"},
		Density = {1, "float"},
		Glare = {1, "float"},
		Haze = {1, "float"},
		Offset = {1, "float"}
	},
	BoolValue = {
		Value = {1, "bool", nil, "Misc"}
	},
	IntValue = {
		Value = {1, "int64", nil, "Misc"}
	},
	IntConstrainedValue = {
		MinValue = {1, "int64"},
		MaxValue = {1, "int64"},
		Value = {1, "int64"}
	},
	NumberValue = {
		Value = {1, "double", nil, "Misc"}
	},
	DoubleConstrainedValue = {
		MinValue = {1, "double"},
		MaxValue = {1, "double"},
		Value = {1, "double"}
	},
	ObjectValue = {
		Value = {1, "ref", nil, "Misc"}
	},
	StringValue = {
		Value = {1, "string", nil, "Misc"}
	},
	Vector3Value = {
		Value = {1, "Vector3", nil, "Misc"}
	},
	BrickColorValue = {
		Value = {1, "BrickColor", nil, "Misc"}
	},
	Color3Value = {
		Value = {1, "Color3", nil, "Misc"}
	},
	CFrameValue = {
		Value = {1, "CoordinateFrame", nil, "Misc"}
	},
	RayValue = {
		Value = {1, "Ray", nil, "Misc"}
	},
	BinaryStringValue = {
		Value = {1, "BinaryString", nil, "Misc"}
	}
}

local ScriptCache = {}

local function DecompressBytecode(OriginalData)
	local OriginalLength = buffer.len(OriginalData)
	local RSB1 = buffer.fromstring("RSB1")
	local Hash = buffer.create(4)
	buffer.copy(Hash, 0, OriginalData, 0, 4)
	local DecodedData = buffer.create(OriginalLength)
	
	for i = 0, 3 do
		local Byte = buffer.readu8(Hash, i)
		local XORed = bit32.bxor(Byte, buffer.readu8(RSB1, i))
		local Transformed = (XORed - i * 41)
		buffer.writeu8(Hash, i, Transformed)
	end
	
	for i = 0, OriginalLength - 1 do
		local Byte = buffer.readu8(OriginalData, i)
		buffer.writeu8(DecodedData, i, bit32.bxor(Byte, buffer.readu8(Hash, i % 4) + i * 41))
	end
	
	local CompressedData = buffer.create(OriginalLength - 8)
	buffer.copy(CompressedData, 0, DecodedData, 8)
	return ZSTDDecompress(CompressedData)
end

local function GetScriptSource(Instance, Decompile, SaveBytecode, DecompileFunction)
	local ClassName = GetClassName(Instance)
	local BytecodeOffset = Offsets[ClassName].Bytecode
	if not BytecodeOffset then
		return "Failed to get bytecode: unable to find bytecode offset"
	end
	
	if ClassName == "Script" and memory.readi32(Instance, RunContextOffset) ~= 2 then
		return "-- [FilteringEnabled] Server Scripts are IMPOSSIBLE to save"
	end
	
	local Bytecode
	do
		local BytecodeInfo = memory.readu64(Instance, BytecodeOffset)
		local Pointer = memory.readu64(BytecodeInfo, Offsets.Bytecode.Pointer)
		local Size = memory.readu64(BytecodeInfo, Offsets.Bytecode.Size)
		local CompressedBytecode = memory.readbuffer(Pointer, Size)
		
		Bytecode = buffer.tostring(DecompressBytecode(CompressedBytecode))
	end
	
	local Source = ""
	if SaveBytecode then
		Source ..= "\n\n-- Bytecode (Base64):\n-- " .. Base64Encode(Bytecode) .. "\n\n" -- Newlines at the start are for compatability with UniversalSynSaveInstance bytecode postproccessors
	end
	
	if Decompile then
		print("Decompiling Script: " .. GetName(Instance))
		local DecompiledScript
		local CachedScript = ScriptCache[Bytecode]
		if CachedScript then
			DecompiledScript = CachedScript
		else
			task.wait(0.75) -- Prevent script timeout
			DecompiledScript = DecompileFunction(Bytecode)
			ScriptCache[Bytecode] = DecompiledScript
		end
		Source ..= DecompiledScript
	end
	
	return Source
end

-- Escapes (credit: UniversalSynSaveInstance)
local ESCAPES_PATTERN = "[&<>\"'\0\1-\9\11-\12\14-\31\127-\255]"
local ESCAPES = {
	["&"] = "&amp;", -- 38
	["<"] = "&lt;", -- 60
	[">"] = "&gt;", -- 62
	['"'] = "&#34;", --  quot
	["'"] = "&#39;", -- apos
	["\0"] = "",
}

for rangeStart, rangeEnd in string.gmatch(ESCAPES_PATTERN, "(.)%-(.)") do
	for charCode = string.byte(rangeStart), string.byte(rangeEnd) do
		ESCAPES[string.char(charCode)] = "&#" .. charCode .. ";"
	end
end

local Descriptors
Descriptors = {
	Number = function(raw)
		if raw == math.huge then
			return "INF"
		elseif raw == -math.huge then
			return "-INF"
		elseif raw ~= raw then
			return "NAN"
		end
		return raw
	end,
	string = function(raw)
		return (raw == nil or raw == "" or string.find(raw, "\0", 1, true)) and ""
			or string.find(raw, "]]>", 1, true) and string.gsub(raw, ESCAPES_PATTERN, ESCAPES)
			or "<![CDATA[" .. raw.. "]]>"
	end,
	ProtectedString = function(raw)
		return string.find(raw, "]]>", 1, true) and string.gsub(raw, ESCAPES_PATTERN, ESCAPES) or "<![CDATA[" .. raw .. "]]>"
	end,
	ContentId = function(raw)
		return raw == "" and "<null></null>" or "<url>" .. Descriptors.string(raw) .. "</url>"
	end,
	Content= function(raw)
		return raw == "" and "<null></null>" or "<uri>" .. Descriptors.string(raw) .. "</uri>"
	end,
	Vector2 = function(raw)
		return "<X>" .. raw.X .. "</X><Y>" .. raw.Y .. "</Y>"
	end,
	Vector3 = function(raw)
		return "<X>" .. raw.X .. "</X><Y>" .. raw.Y .. "</Y><Z>" .. raw.Z .. "</Z>"
	end,
	token = function(raw) return raw end, -- Enum
	BrickColor = function(raw) return raw end,
	ref = function(raw) -- Class category
		return raw == 0 and "null" or raw
	end,
	CoordinateFrame = function(raw) -- CFrame
		return "<X>" .. raw.Position.X .. "</X><Y>" .. raw.Position.Y .. "</Y><Z>" .. raw.Position.Z .. "</Z><R00>".. raw.RightVector.X .. "</R00><R01>" .. raw.RightVector.Y .. "</R01><R02>" .. raw.RightVector.Z .. "</R02><R10>" .. raw.UpVector.X .. "</R10><R11>" .. raw.UpVector.Y .. "</R11><R12>" .. raw.UpVector.Z .. "</R12><R20>" .. raw.LookVector.X .. "</R20><R21>" .. raw.LookVector.Y .. "</R21><R22>" .. raw.LookVector.Z .. "</R22>"
	end,
	bool = function(raw)
		return raw and "true" or "false"
	end,
	BinaryString = function(raw)
		return raw == "" and "" or Base64Encode(raw)
	end,
	Color3 = function(raw)
		return "<R>" .. raw.X .. "</R><G>" .. raw.Y .. "</G><B>" .. raw.Z .. "</B>"
	end,
	Color3uint8 = function(raw)
		return 0xFF000000
			+ (math.floor(raw.R) * 0x10000)
			+ (math.floor(raw.G) * 0x100)
			+ math.floor(raw.B)
	end,
	NumberRange = function(raw)
		return table.concat(raw, " ")
	end,
	UDim2 = function(raw)
		return "<XS>" .. raw.XS .. "</XS><XO>" .. raw.XO .. "</XO><YS>" .. raw.YS .. "</YS><YO>" .. raw.YO .. "</YO>"
	end,
	Ray = function(raw)
		return "<origin><X>" .. raw.Origin.X .. "</X><Y>" .. raw.Origin.Y .. "</Y><Z>" .. raw.Origin.Z .. "</Z></origin><direction><X>" .. raw.Direction.X .. "</X><Y>" .. raw.Direction.Y .. "</Y><Z>" .. raw.Direction.Z .. "</Z></direction>"
	end,
	Font = function(raw)
		local Style = raw.Style and "Italic" or "Normal"
		return "<Family>" .. Descriptors.ContentId(raw.Family) .. "</Family><Weight>" .. raw.Weight .. "</Weight><Style>" .. Style .. "</Style><CachedFaceId>" .. Descriptors.ContentId(raw.CachedFaceId) .. "</CachedFaceId>"
	end,
	Rect2D = function(raw)
		return "<min><X>" .. raw.MinX .. "</X><Y>" .. raw.MinY .. "</Y></min><max><X>" .. raw.MaxX .. "</X><Y>" .. raw.MaxY .. "</Y></max>"
	end
}

for DescriptorName, RedirectName in
	{
		int = "Number",
		int64 = "Number",
		float = "Number",
		double = "Number"
	}
do
	Descriptors[DescriptorName] = Descriptors[RedirectName]
end

--[[ local ExpectedTypeOfResults = {
	string = "string",
	ContentId = "string",
	Content = "string",
	BinaryString = "string",
	ref = "number",
	float = "number",
	int = "number",
	int64 = "number",
	double = "number",
	token = "number",
	BrickColor = "number",
	Vector2 = "vector",
	Vector3 = "vector",
	CoordinateFrame = "table",
	bool = "boolean",
	Color3 = "vector",
	Color3uint8 = "table",
	NumberRange = "table",
	ProtectedString = "string",
	UDim2 = "table",
	Ray = "table",
	Font = "table",
	Rect2D = "table"
} ]]

local ApiDump = JSONDecode(game:HttpGet("https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/Mini-API-Dump.json"))

local SuperclassList = {}
local SuperclassesOfClass = {}

for _, Class in ApiDump.Classes do
	SuperclassList[Class.Name] = Class.Superclass
end

local function GetAllSuperclasses(Class)
	local Superclasses = {}
	local layer = Class
	while layer ~= "Object" do
		table.insert(Superclasses, layer)
		layer = SuperclassList[layer]
	end
	return Superclasses
end

print("SaveInstance initialized")

local function saveinstance(CustomOptions)
	-- Options: IsModel (bool), ToSave (Pointer, Instance, or table of pointers/instances), PrintInterval (int), FileName (string), DebugPrints (bool), Decompile (bool), SaveBytecode (bool), DecompileFunction (function)
	
	local Options = {
		IsModel = nil,
		ToSave = {
			GetService("Workspace"),
			GetService("Players"),
			GetService("Lighting"),
			GetService("MaterialService"),
			GetService("ReplicatedFirst"),
			GetService("ReplicatedStorage"),
			GetService("StarterGui"),
			GetService("StarterPack"),
			GetService("StarterPlayer"),
			GetService("Teams"),
			GetService("SoundService"),
			GetService("JointsService")
		},
		PrintInterval = 1000,
		FileName = memory.readu64(DataModel, Offsets.DataModel.PlaceId),
		DebugPrints = false,
		Decompile = true,
		SaveBytecode = false,
		DecompileFunction = function(Bytecode)
			local Body = crypt.json.encode({script = crypt.base64.encode(Bytecode)})
			return game:HttpPost("https://api.lua.expert/decompile", Body, "application/json", "application/json")
		end,
		NotCreatableFixes = {Player = "Folder", PlayerGui = "Folder", PlayerScripts = "Folder", TouchTransmitter = "Folder"},
		ReadMe = true
	}
	
	if CustomOptions then
		for Option, Value in CustomOptions do
			Options[Option] = Value
		end
	end
	
	local IsModel = Options.IsModel
	local ToSave = Options.ToSave
	local PrintInterval = Options.PrintInterval
	local FileName = Options.FileName
	local DebugPrints = Options.DebugPrints
	local Decompile = Options.Decompile
	local SaveBytecode = Options.SaveBytecode
	local DecompileFunction = Options.DecompileFunction
	local NotCreatableFixes = Options.NotCreatableFixes or {}
	
	if ToSave == game or ToSave == DataModel then
		ToSave = GetChildren(DataModel)
	end

	if type(ToSave) == "table" then
		for i, v in ToSave do
			if typeof(v) == "Instance" then
				ToSave[i] = tonumber(v.Data)
			end
			
			if IsModel == nil and GetParent(v) ~= DataModel then
				IsModel = true
			end
		end
	end
	if type(ToSave) == "number" then
		ToSave = {ToSave}
	end
	
	if typeof(ToSave) == "Instance" then
		ToSave = {tonumber(ToSave.Data)}
	end
	
	local StartingTime = os.clock()
	local SavedInstancesCount = 0
	local SavedInstancesUntilPrint = 0
	local FileType
	
	if IsModel then
		FileType = "rbxmx"
	else
		FileType = "rbxlx"
	end
	
	local FullFileName = FileName .. "." .. FileType .. ".txt" -- Severe only lets you write certain files extensions, rbxlx/rbxmx files aren't part of that list
	local SerializedData = '<roblox version="4">' -- XML header
	local CurrentSerializedData = ""
	local InstanceData = ""
	
	local function SerializeInstances(Instances)
		for _, Instance in Instances do
			--local CanRead, _ = pcall(function() return Instance.ClassName end)
			--if not CanRead then
			--	if DebugPrints then
			--		warn("Broken instance found, skipping")
			--	end
			--	continue
			--end

			if Instance == 0 then
				continue
			end
			local ClassName = GetClassName(Instance)
			local NotCreateableFix = NotCreatableFixes[ClassName]
			local ClassNameOverride = NotCreateableFix or ClassName
			
			local InstanceStart = '<Item class="' .. ClassNameOverride .. '" referent="' .. Instance .. '"><Properties>'
			InstanceData ..= InstanceStart
			
			local Superclasses = SuperclassesOfClass[ClassName]
			if not Superclasses then
				Superclasses = GetAllSuperclasses(ClassName)
				SuperclassesOfClass[ClassName] = Superclasses
			end
			
			for _, Class in Superclasses do
				local Properties = PropList[Class]
				if not Properties then
					continue
				end
				for PropertyName, PropertyData in Properties do
					local PropertyMode = PropertyData[1]
					local ValueType = PropertyData[2]
					local raw
					
					if PropertyMode == 1 then -- Memory
						local ReadFunction = MemoryReadFunctions[ValueType]
						local ReadClass = Class
						local ReadInstance = Instance
						local Namespace = PropertyData[5]
						if Namespace then
							ReadClass = Namespace
							ReadInstance = memory.readu64(Instance, Offsets[Class][Namespace])
						end
						
						local ClassOffsets = Offsets[ReadClass]
						Offset = ClassOffsets[PropertyName]
						if Offset == nil then
							if DebugPrints then
								warn("Nil offset for " .. PropertyName .. " of class " .. Class)
							end
							continue
						end
						raw = ReadFunction(ReadInstance, Offset)
					elseif PropertyMode == 2 then -- PropertyFunction
						raw = PropertyData[3](Instance, PropertyName, Class)
					elseif PropertyMode == 3 then -- Decompile
						if Decompile or SaveBytecode then
							raw = GetScriptSource(Instance, Decompile, SaveBytecode, DecompileFunction)
						else
							raw = "-- Decompiling is Disabled"
						end
					end
					local TypeOfResult = typeof(raw)
					if ValueType == "string" and TypeOfResult == "Instance" then -- Severe returns empty strings of certain properies (EX: Name) as strings
						raw = ""
					end
					if raw == nil then
						continue
					end
					local Formatted
					local Descriptor = Descriptors[ValueType]
					if Descriptor then
						Formatted = Descriptor(raw)
						InstanceData ..= "<" .. ValueType ..' name="' .. PropertyName .. '">' .. Formatted .. "</" .. ValueType .. ">"
					elseif DebugPrints then
						warn("No descriptor for type " .. ValueType)
					end
				end
			end
			InstanceData ..= "</Properties>"
			CurrentSerializedData ..= InstanceData
			InstanceData = ""
			SavedInstancesCount += 1
			SavedInstancesUntilPrint += 1
			if SavedInstancesUntilPrint == PrintInterval then
				task.wait(0.7)
				SerializedData ..= CurrentSerializedData
				CurrentSerializedData = ""
				SavedInstancesUntilPrint = 0
				print("Instances Saved: " .. SavedInstancesCount)
			end
			
			local Children = GetChildren(Instance)
			if Children then
				SerializeInstances(Children)
			end
			CurrentSerializedData ..= "</Item>"
		end
	end
	print("Saving...")
	
	SerializeInstances(ToSave)
	SerializedData ..= CurrentSerializedData
	if Options.ReadMe then
		SerializedData ..= '<Item class="Script" referent="1"><Properties><string name="Name">README</string><ProtectedString name="Source">--[[\nSaved using: https://github.com/Devraj2010isme/SevereSaveinstance\nGameId: ' .. memory.readu64(DataModel, Offsets.DataModel.GameId) .. "\nPlaceId: " .. memory.readu64(DataModel, Offsets.DataModel.PlaceId) .. "\nPlaceVersion: " .. memory.readu32(DataModel, Offsets.DataModel.PlaceVersion) .. "\nOptions used when saving: " .. crypt.json.encode(Options) .. "\n]]</ProtectedString></Properties></Item>"
	end
	SerializedData ..= "</roblox>"
	
	print("Writing to file...")
	writefile(FullFileName, SerializedData)
	print("Successfully saved as " .. FullFileName .. " (Remove the .txt at the end)")
	print("Time Taken: " .. os.clock() - StartingTime .. " Seconds")
end

return saveinstance