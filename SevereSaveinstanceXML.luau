--!native
--!optimize 2

-- Saveinstance for Severe External
-- Can only save a few properties that can be accessed by the external without memory functions
-- Mostly made as a challege for me to make a saveinstance without stealing code from UniversalSynSaveinstance
-- Current things from UniversalSynSaveinstance I have used: AttributesSerialize generator, escapes stuff

local Base64Encode = crypt.base64.encode
local MakeAttributesSerialize = loadstring(game:HttpGet("https://raw.githubusercontent.com/Devraj2010isme/SevereSaveinstance/refs/heads/main/MakeAttributesSerialize.luau", true))()

local PropList = { -- Hardcoded because Severe can only read certain arbitrary properties 
	--[[ Classname = {
		PropertyName = {PropertyReadMode (1 = Index, 2 = PropertyFunction), ValueType, PropertyFunction (optional)}
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
		AttributesSerialize = {2, "BinaryString", MakeAttributesSerialize}
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
		ViewportSize = {1, "Vector2"},
		FieldOfView = {1, "float"},
		CFrame = {1, "CoordinateFrame"}
	},
	BasePart = {
		Size = {1, "Vector3"},
		CFrame = {1, "CoordinateFrame"},
		CanCollide = {1, "bool"},
		Transparency = {1, "float"},
		IsNetworkSleeping = {1, "bool"},
		Velocity = {1, "Vector3"},
		Shape = {
			2,
			"token",
			function(inst) 
				if inst.Description then 
					return inst.Description.Shape 
				end
			end
		},
		Color = {
			2,
			"Color3",
			function(inst) 
				if inst.Description then 
					return inst.Description.Color3 
				end
			end,
		}
	},
	MeshPart = {
		MeshId = {1, "ContentId"},
		TextureId = {1, "ContentId"}
	},
	Player = {
		Team = {1, "ref"},
		UserId = {1, "int64"},
		Character = {1, "ref"},
		DisplayName = {1, "string"},
	},
	Model = {
		PrimaryPart = {1, "ref"}
	},
	Humanoid = {
		MaxHealth = {1, "float"},
		Health = {1, "float"}
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

	--[[ DataModel = { -- Shouldn't be necessary 
		PlaceId = {function(inst) return inst.PlaceId end, "int64"},
		GameId = {function(inst) return inst.GameId end, "int64"},
		JobId = {function(inst) return inst.JobId end, "int64"}
	} ]]
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
	token = function(raw) return raw end, -- Severe returns the enum value by default
	ref = function(raw) -- Class category
		local CanRead, ClassName = pcall(function() return raw.ClassName end)
		if CanRead and ClassName ~= "" then -- CanRead usually fails when the class category property is nil (Severe returns an empty intance), but I've seen random failures in other cases
			return raw.Data
		end
		return "null"
	end,
	CoordinateFrame = function(raw) -- CFrame
		return "<X>" .. raw.Position.X .. "</X><Y>" .. raw.Position.Y .. "</Y><Z>" .. raw.Position.Z .. "</Z><R00>".. raw.RightVector.X .. "</R00><R01>" .. raw.RightVector.Y .. "</R01><R02>" .. -raw.RightVector.Z .. "</R02><R10>" .. raw.UpVector.X .. "</R10><R11>" .. raw.UpVector.Y .. "</R11><R12>" .. -raw.UpVector.Z .. "</R12><R20>" .. raw.LookVector.X .. "</R20><R21>" .. raw.LookVector.Y .. "</R21><R22>" .. -raw.LookVector.Z .. "</R22>" 
	end,
	bool = function(raw)
		return raw and "true" or "false"
	end,
	BinaryString = function(raw)
		return raw == "" and "" or Base64Encode(raw)
	end,
	Color3 = function(raw)
		return "<R>" .. raw.X/255 .. "</R><G>" .. raw.Y/255 .. "</G><B>" .. raw.Z/255 .. "</B>"
	end
}

for descriptorName, redirectName in
	{
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
	int64 = "number",
	double = "number",
	token = "number",
	Vector2 = "vector",
	Vector3 = "vector",
	CoordinateFrame = "table",
	bool = "boolean",
	Color3 = "vector"
}

local SuperclassesOfClass = { -- Hardcoded because of Severe's inconsistencies
	Part = {"BasePart", "Instance"},
	MeshPart = {"MeshPart", "BasePart", "Instance"},
	UnionOperation = {"BasePart", "Instance"},
	SpawnLocation = {"BasePart", "Instance"},
	CornerWedgePart = {"BasePart", "Instance"},
	TrussPart = {"BasePart", "Instance"},
	WedgePart = {"BasePart", "Instance"}
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
					end
					
					local TypeOfResult = typeof(raw)
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
