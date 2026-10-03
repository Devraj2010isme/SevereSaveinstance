--!native
--!optimize 2

-- Saveinstance for Severe External
-- Can only save a few properties that can be accessed by the external without memory functions
-- Mostly made as a challege for me to make a saveinstance without stealing code from UniversalSynSaveinstance
-- Current things from UniversalSynSaveinstance I have used: AttributesSerialize generator, escapes stuff, Color3uint8 descriptor

local Base64Encode = crypt.base64.encode
local JSONDecode = crypt.json.decode
local MakeAttributesSerialize = loadstring(game:HttpGet("https://raw.githubusercontent.com/Devraj2010isme/SevereSaveinstance/refs/heads/main/MakeAttributesSerialize.luau", true))()
local Offsets = JSONDecode(readfile("Offsets.json"))
local Version = game:GetClientVersion()

local MemoryReadFunctions = {
	bool = memory.readbool,
	float = memory.readf32,
	Color3 = memory.readvector,
	--Instance = function(Data, Offset)
	--	local Pointer = memory.readu64(Data, Offset)
	--	return Pointer ~= 0 and pointer_to_userdata(Pointer) or nil 
	--end,
	token = memory.readi32,
	BrickColor = memory.readi32,
	int = memory.readu32,
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
	string = memory.readstring,
	ContentId = memory.readstring
}

-- TODO: BasePart PrimitiveFlags, Workspace World/AirProperties
local PropList = { -- Hardcoded because Severe can only read certain arbitrary properties 
	--[[ Classname = {
		PropertyName: {PropertyReadMode: 1 = Index, 2 = PropertyFunction, 3 = Memory)
		ValueType: String
		PropertyFunction: Function (mode 2), PropertyNameOverride: String (mode 3, only used when dumping offsets)
		ClassNameOverride: String (mode 3, only used when dumping offsets)
		Namespace: String (mode 3, reads properties from a different namespace such as Primitive)
		}
	} ]]
	Instance = {
		Name = {1, "string"},
		Tags = {
			2, 
			"BinaryString",
			function(inst)
				local tags = inst:GetTags()
				if #tags == 0 then
					return ""
				end
				return table.concat(tags, "\0")
			end,
		},
		AttributesSerialize = {
			2,
			"BinaryString",
			function(inst) -- All Severe Attributes are string type
				local Attributes = inst:GetAttributes()
				if not next(Attributes) then
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
		}
	},
	BillboardGui = {
		Adornee = {1, "ref"}
	},
	Workspace = {
		CurrentCamera = {1, "ref"}
	},
	Players = {
		LocalPlayer = {1, "ref"}
	},
	Camera = {
		ViewportSize = {3, "Vector2"},
		CFrame = {3, "CoordinateFrame", "Rotation"},
		--CameraSubject = {3, "ref"},
		CameraType = {3, "token"}
	},
	CharacterMesh = {
		BaseTextureId = {3, "int64"},
		BodyPart = {3, "token"},
		MeshId = {3, "int64"},
		OverlayTextureId = {3, "int64"}
	},
	Highlight = {
		--Adornee = {3, "ref"},
		DepthMode = {3, "token"},
		Enabled = {3, "bool"},
		FillColor = {3, "Color3"},
		FillTransparency = {3, "float"},
		OutlineColor = {3, "Color3"},
		OutlineTransparency = {3, "float"}
	},
	HopperBin = {
		BinType = {3, "token"}
	},
	--Seat = {
	--	Occupant = {3, "ref"}
	--},
	Lighting = {
		Ambient = {3, "Color3"},
		Brightness = {3, "float"},
		ClockTime = {3, "float"},
		ColorShift_Top = {3, "Color3"},
		ColorShift_Bottom = {3, "Color3"},
		EnvironmentDiffuseScale = {3, "float"},
		EnvironmentSpecularScale = {3, "float"},
		ExposureCompensation = {3, "float"},
		FogColor  = {3, "Color3"},
		FogEnd = {3, "float"},
		FogStart = {3, "float"},
		OutdoorAmbient = {3, "Color3"},
		ShadowSoftness = {3, "float"},
		GeographicLatitude = {3, "float"},
		GlobalShadows = {3, "bool"},
	},
	Sky = {
		SkyboxBk = {3, "ContentId"},
		SkyboxDn = {3, "ContentId"},
		SkyboxFt = {3, "ContentId"},
		SkyboxLf = {3, "ContentId"},
		SkyboxRt = {3, "ContentId"},
		SkyboxUp = {3, "ContentId"},
		SunAngularSize = {3, "float"},
		MoonAngularSize = {3, "float"},
		SunTextureId = {3, "ContentId"},
		MoonTextureId = {3, "ContentId"},
		SkyboxOrientation = {3, "Vector3"},
		StarCount = {3, "int"}
	},
	SpecialMesh = {
		MeshId = {3, "ContentId"},
		TextureId = {3, "ContentId"},
		Scale = {3, "Vector3"},
		Offset = {3, "Vector3"}
	},
	Team = {
		TeamColor = {3, "BrickColor", "BrickColor"}
	},
	Terrain = {
		GrassLength = {3, "float"},
		WaterColor = {3, "Color3"},
		WaterReflectance = {3, "float"},
		WaterTransparency = {3, "float"},
		WaterWaveSize = {3, "float"},
		WaterWaveSpeed = {3, "float"},
		-- TODO MaterialColors
	},
	Tool = {
		Tooltip = {3, "string"},
		TextureId = {3, "ContentId"},
		Enabled = {3, "bool"},
		CanBeDropped = {3, "bool"},
		RequiresHandle = {3, "bool"},
		Grip = {3, "CoordinateFrame"}
	},
	VehicleSeat = {
		MaxSpeed = {3, "float"},
		SteerFloat = {3, "float"},
		ThrottleFloat = {3, "float"},
		Torque = {3, "float"},
		TurnSpeed = {3, "float"},
		-- Occupant = {3, "ref"}
	},
	SurfaceAppearance = {
		AlphaMode = {3, "token"},
		Color = {3, "Color3"},
		ColorMap = {3, "ContentId"},
		EmissiveStrength = {3, "float"},
		EmissiveTint = {3, "Color3"},
		MetalnessMap = {3, "ContentId"},
		NormalMap = {3, "ContentId"},
		RoughnessMap = {3, "ContentId"}
		-- TODO EmissiveMaskContent
	},
	ParticleEmitter = {
		Brightness = {3, "float"},
		LightEmission = {3, "float"},
		LightInfluence = {3, "float"},
		Texture = {3, "ContentId"},
		ZOffset = {3, "float"},
		Rate = {3, "float"},
		SpreadAngle = {3, "Vector2"},
		Acceleration = {3, "Vector3"},
		Drag = {3, "float"},
		TimeScale = {3, "float"},
		VelocityInheritance = {3, "float"}
		-- TODO Lifetime, Rotation, RotSpeed, Speed (NumberRange)
	},
	Beam = {
		Brightness = {3, "float"},
		LightEmission = {3, "float"},
		LightInfluence = {3, "float"},
		Texture = {3, "ContentId"},
		TextureLength = {3, "float"},
		TextureSpeed = {3, "float"},
		ZOffset = {3, "float"},
		-- Attachment0 = {3, "ref"},
		-- Attachment1 = {3, "ref"},
		CurveSize0 = {3, "float"},
		CurveSize1 = {3, "float"},
		Width0 = {3, "float"},
		Width1 = {3, "float"},
	},
	Clothing = {
		Color3 = {3, "Color3"}
	},
	Shirt = {
		ShirtTemplate = {3, "ContentId", "Template", "Clothing"}
	},
	--Pants = {
	--	PantsTemplate = {3, "ContentId", "Template", "Clothing"}
	--},
	--Attachment = {
	--	CFrame = { -- Component order is strange
	--		2, 
	--		"CoordinateFrame",
	--		function(inst)
	--			if Offsets and Offsets.Attachment.Position then
	--				local Offset = Offsets.Attachment.Position 
	--			local CFrame = {}
	--				
	--				CFrame.RightVector = memory.readvector(Data, Offset - 12)
	--				CFrame.Position = memory.readvector(Data, Offset)
	--				CFrame.UpVector = memory.readvector(Data, Offset + 12)
	--				CFrame.LookVector = Vector3.new(0,0,0) -- TODO find LookVector
	--			end
	--		end
	--	}
	--},
	--Weld = {
	--	Part0 = {3, "ref"},
	--	Part1 = {3, "ref"}
	--},
	--WeldConstraint = {
	--	Part0 = {3, "ref"},
	--	Part1 = {3, "ref"}
	--},
	PartOperation = {
		AssetId = {3, "ContentId", nil, "UnionOperation"},
		InitialSize = {3, "Vector3", "MeshSize", "MeshPart"}
	},
	Decal = {
		Texture = {3, "ContentId", "Decal_Texture", "Textures"}		
	},
	BasePart = {
		Size = {3, "Vector3", nil, nil, "Primitive"},
		CFrame = {3, "CoordinateFrame", "Rotation", nil, "Primitive"},
		CanCollide = {1, "bool"},
		Transparency = {1, "float"},
		Shape = {3, "token"},
		Color = {3, "Color3uint8", "Color3"},
		CastShadow = {3, "bool"},
		Locked = {3, "bool"},
		Massless = {3, "bool"},
		TopSurface = {2, "token", function() return 0 end} -- If this value isn't provided, it defaults to studs
	},
	MeshPart = {
		MeshId = {1, "ContentId"},
		TextureId = {1, "ContentId"},
		InitialSize = {3, "Vector3", "MeshSize"}
	},
	Player = {
		Team = {1, "ref"},
		-- UserId = {1, "int64"}, Not Needed
		Character = {1, "ref"},
		-- DisplayName = {1, "string"}, Not Needed
		HealthDisplayDistance = {3, "float"},
		NameDisplayDistance = {3, "float"},
		-- Team = {3, "ref"},
		TeamColor = {3, "BrickColor"},
		-- AccountAge = {3, "int"}, Not Needed
		CameraMinZoomDistance = {3, "float", "MinZoomDistance"},
		CameraMaxZoomDistance = {3, "float", "MaxZoomDistance"},
		CameraMode = {3, "token"},
	},
	Model = {
		-- PrimaryPart = {1, "ref"},
		ScaleFactor = {3, "float", "Scale"}
	},
	Humanoid = {
		MaxHealth = {1, "float"},
		Health = {1, "float"},
		AutoJumpEnabled = {3, "bool"},
		AutoRotate = {3, "bool"},
		AutomaticScalingEnabled = {3, "bool"},
		BreakJointsOnDeath = {3, "bool"},
		EvaluateStateMachine = {3, "bool"},
		Jump = {3, "bool"},
		PlatformStand = {3, "bool"},
		RequiresNeck = {3, "bool"},
		Sit = {3, "bool"},
		UseJumpPower = {3, "bool"},
		CameraOffset = {3, "Vector3"},
		DisplayDistanceType = {3, "token"},
		DisplayName = {3, "string"},
		HealthDisplayDistance = {3, "float"},
		HealthDisplayType = {3, "token"},
		HipHeight = {3, "float"},
		JumpHeight = {3, "float"},
		JumpPower = {3, "float"},
		MaxSlopeAngle = {3, "float"},
		NameDisplayDistance = {3, "float"},
		NameOcclusion = {3, "token"},
		RigType = {3, "token"},
		--SeatPart = {3, "ref"},
		Walkspeed = {3, "float"},
		WalkToPoint = {3, "Vector3", "MoveToPoint"},
		WalkToPart = {3, "Vector3", "MoveToPart"},
		FloorMaterial = {3, "token"},
		MoveDirection = {3, "Vector3"},
		--HumanoidRootPart = {3, "ref"}
	},
	ProximityPrompt = {
		Enabled = {3, "bool"},
		RequiresLineOfSight = {3, "bool"},
		ActionText = {3, "string"},
		ObjectText = {3, "string"},
		HoldDuration = {3, "float"},
		MaxActivationDistance = {3, "float"},
		KeyboardKeyCode = {3, "token", "KeyCode"},
		GamepadKeyCode = {3, "token"}
	},
	ClickDetector = {
		MaxActivationDistance = {3, "float"},
		CursorIcon = {3, "ContentId", "MouseIcon"}
	},
	DragDetector = {
		--ReferenceInstance = {3, "ref"},
		MaxDragAngle = {3, "float"},
		MaxDragTranslation = {3, "Vector3"},
		MinDragAngle = {3, "float"},
		MinDragTranslation = {3, "Vector3"},
		ActivatedCursorIcon = {3, "ContentId"},
		MaxForce = {3, "float"},
		MaxTorque = {3, "float"},
		Responsiveness = {3, "float"}
	},
	SpawnLocation = {
		Enabled = {3, "bool"},
		Neutral = {3, "bool"},
		AllowTeamChangeOnTouch = {3, "bool"}
	},
	AnimationTrack = {
		Animation = {3, "ref"},
		Speed = {3, "float"},
		TimePosition = {3, "float"},
		Looped = {3, "bool"},
		IsPlaying = {3, "bool"},
	},
	PostEffect = {
		Enabled = {3, "bool", nil, "BloomEffect"}
	},
	BloomEffect = {
		Intensity = {3, "float"},
		Threshold = {3, "float"},
		Size = {3, "float"}
	},
	BlurEffect = {
		Size = {3, "float"}
	},
	ColorCorrectionEffect = {
		Brightness = {3, "float"},
		Contrast = {3, "float"},
		TintColor = {3, "Color3"}
	},
	ColorGradingEffect = {
		TonemapperPreset = {3, "token"}
	},
	DepthOfFieldEffect = {
		FocusDistance = {3, "float"},
		FarIntensity = {3, "float"},
		NearIntensity = {3, "float"},
		InFocusRadius = {3, "float"}
	},
	SunRaysEffect = {
		Intensity = {3, "float"},
		Spread = {3, "float"}
	},
	Sound = {
		IsPlaying = {3, "bool"},
		Looped = {3, "bool"},
		SoundId = {3, "ContentId"},
		RollOffMaxDistance = {3, "float"},
		RollOffMinDistance = {3, "float"},
		PlaybackSpeed = {3, "float"},
		Volume = {3, "float"},
		-- SoundGroup = {3, "ref"}
	},
	Atmosphere = {
		Color = {3, "Color3"},
		Decay = {3, "Color3"},
		Density = {3, "float"},
		Glare = {3, "float"},
		Haze = {3, "float"},
		Offset = {3, "float"}
	},
	UserInputService = {
		MouseBehavior = {1, "token"},
		MouseDeltaSensitivity = {1, "float"},
		MouseIconEnabled = {1, "bool"}
	},
	BoolValue = {
		Value = {1, "bool"}
	},
	IntValue = {
		Value = {1, "int64"}
	},
	NumberValue = {
		Value = {1, "double"}
	},
	ObjectValue = {
		Value = {1, "ref"}
	},
	StringValue = {
		Value = {1, "string"}
	},
	Vector3Value = {
		Value = {1, "Vector3"}
	}
	-- .Value on the other ValueBase subclasses cannot be read by Severe
}

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
		return (raw == nil or raw == "") and ""
			or string.find(raw, "]]>", 1, true) and string.gsub(raw, ESCAPES_PATTERN, ESCAPES)
			or "<![CDATA[" .. string.gsub(raw, "\0", "") .. "]]>"
	end,
	ContentId = function(raw)
		return raw == "" and "<null></null>" or "<url>" .. Descriptors.string(raw) .. "</url>"
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
		local CanRead, ClassName = pcall(function() return raw.ClassName end)
		if CanRead and ClassName ~= "" then -- CanRead usually fails when the class category property is nil (Severe returns an empty intance), but I've seen random failures in other cases
			return raw.Data
		end
		return "null"
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
	end
}

for descriptorName, redirectName in
	{
		int = "Number",
		int64 = "Number",
		float = "Number",
		double = "Number"
	}
do
	Descriptors[descriptorName] = Descriptors[redirectName]
end

local ExpectedTypeOfResults = {
	string = "string",
	ContentId = "string",
	BinaryString = "string",
	ref = "Instance",
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
	Color3uint8 = "table"
}

local SuperclassesOfClass = { -- Hardcoded because of Severe's inconsistencies
	Part = {"BasePart", "Instance"},
	MeshPart = {"MeshPart", "BasePart", "Instance"},
	UnionOperation = {"PartOperation", "BasePart", "Instance"},
	NegateOperation = {"PartOperation", "Instance"}, -- TODO (requires reading all the BasePart properties with memory functions)
	IntersectOperation = {"PartOperation", "Instance"}, -- TODO (requires reading all the BasePart properties with memory functions)
	SpawnLocation = {"SpawnLocation", "BasePart", "Instance"},
	CornerWedgePart = {"BasePart", "Instance"},
	TrussPart = {"BasePart", "Instance"},
	WedgePart = {"BasePart", "Instance"},
	Tool = {"Tool", "Model", "Instance"},
	BloomEffect = {"BloomEffect", "PostEffect", "Instance"},
	BlurEffect = {"BlurEffect", "PostEffect", "Instance"},
	ColorCorrectionEffect = {"ColorCorrectionEffect", "PostEffect", "Instance"},
	ColorGradingEffect = {"ColorGradingEffect", "PostEffect", "Instance"},
	DepthOfFieldEffect = {"DepthOfFieldEffect", "PostEffect", "Instance"},
	SunRaysEffect = {"SunRaysEffect", "PostEffect", "Instance"},
	DragDetector = {"DragDetector", "ClickDetector", "Instance"},
	Shirt = {"Shirt", "Clothing", "Instance"}
}

print("SaveInstance initialized")

local function saveinstance(Options)
	-- Options: ToSave (Instance or table), IsModel (bool), PrintInterval (int), FileName (string), DebugPrints (bool)
	
	if not Options then
		Options = {}
	end
	local IsModel = Options.IsModel
	if not IsModel then
		IsModel = true
	end
	local ToSave = Options.ToSave
	if not ToSave then 
		ToSave = {
			game:GetService("Workspace"),
			game:GetService("Players"),
			game:GetService("Lighting"),
			game:GetService("MaterialService"),
			game:GetService("ReplicatedFirst"),
			game:GetService("ReplicatedStorage"),
			game:GetService("StarterGui"),
			game:GetService("StarterPack"),
			game:GetService("StarterPlayer"),
			game:GetService("Teams"),
			game:GetService("SoundService")
		}
		if IsModel == nil then
			IsModel = false
		end
	end
	local PrintInterval = Options.PrintInterval
	if not PrintInterval then 
		PrintInterval = 1000
	end
	local FileName = Options.FileName
	if not FileName then 
		FileName = tostring(game.PlaceId)
	end
	
	if ToSave == game then
		ToSave = game:GetChildren()
		if IsModel == nil then
			IsModel = false
		end
	end	
	
	local StartingTime = os.clock()
	local SavedInstancesCount = 0
	local SavedInstancesUntilPrint = 0
	local FileType
	
	if Options.IsModel then
		FileType = "rbxmx"
	else
		FileType = "rbxlx"
	end
	
	if typeof(ToSave) == "Instance" then
		ToSave = {ToSave}
	end
	
	local DebugPrints = Options.DebugPrints
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
			
			local ClassName = Instance.ClassName
			local Referent = Instance.Data
			InstanceData ..= '<Item class="' .. ClassName .. '" referent="' .. Referent .. '"><Properties>'
			
			local Superclasses = SuperclassesOfClass[ClassName]
			if not Superclasses then
				Superclasses = {ClassName, "Instance"}
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
					
					if PropertyMode == 1 then -- Index
						raw = Instance[PropertyName]
					elseif PropertyMode == 2 then -- PropertyFunction
						raw = PropertyData[3](Instance)
					elseif PropertyMode == 3 and Offsets then -- Memory
						local ReadFunction = MemoryReadFunctions[ValueType]
						local ReadClass = Class
						local ReadInstance = Instance
						local Namespace = PropertyData[5]
						if Namespace and Offsets.Namespaces then
							ReadClass = Namespace
							ReadInstance = memory.readu64(Instance, Offsets.Namespaces[Namespace])
						end
						
						local ClassOffsets = Offsets[ReadClass]
						Offset = ClassOffsets[PropertyName]
						if Offset == nil then
							if DebugPrints then
								warn("Nil offset for " .. PropertyName .. " of class " .. class)
							end
							continue
						end
						if not ReadFunction then
							print(ValueType)
						end
						raw = ReadFunction(ReadInstance, Offset)
					end
					
					local TypeOfResult = typeof(raw)
					if ValueType == "string" and TypeOfResult == "Instance" then -- Severe returns empty strings of certain properies (EX: Name) as strings
						raw = ""
					end
					if raw == nil then
						continue
					end
					
					if TypeOfResult == ExpectedTypeOfResults[ValueType] then -- Empty strings are returned as instances for some reason, so this just checks that Severe returns the correct thing (this has been fixed but I'm keeping the code in case there are other errors like it)
						local Formatted
						local Descriptor = Descriptors[ValueType]
						if Descriptor then
							Formatted = Descriptor(raw)
							InstanceData ..= "<" .. ValueType ..' name="' .. PropertyName .. '">' .. Formatted .. "</" .. ValueType .. ">"
						elseif DebugPrints then
							warn("No descriptor for type " .. ValueType)
						end
					elseif typeof(raw) ~= ExpectedTypeOfResults[ValueType] and DebugPrints then
						warn("Typeof Result (" .. TypeOfResult .. ") did not match expected result for ValueType " .. ValueType .. ". Raw value: " .. tostring(raw) .. " Instance referent: " .. Referent)
					end
				end
			end
			
			InstanceData ..= "</Properties>"
			CurrentSerializedData ..= InstanceData
			InstanceData = ""
			SavedInstancesCount += 1
			SavedInstancesUntilPrint += 1
			if SavedInstancesUntilPrint == PrintInterval then
				task.wait()
				SerializedData ..= CurrentSerializedData
				CurrentSerializedData = ""
				SavedInstancesUntilPrint = 0
				print("Instances Saved: " .. SavedInstancesCount)
			end
			
			local Children = Instance:GetChildren()
			if #Children ~= 0 then
				SerializeInstances(Children)
			end
			CurrentSerializedData ..= "</Item>"
		end
	end
	print("Saving...")
	
	SerializeInstances(ToSave)
	SerializedData ..= CurrentSerializedData
	SerializedData ..= "</roblox>"
	
	print("Writing to file...")
	writefile(FullFileName, SerializedData)
	print("Successfully saved as " .. FullFileName .. " (Remove the .txt at the end)")
	print("Time Taken: " .. os.clock() - StartingTime .. " Seconds")
end

return saveinstance
