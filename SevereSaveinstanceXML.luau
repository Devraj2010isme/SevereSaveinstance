--!native
--!optimize 2

-- Saveinstance for Severe External
-- Can only save a few properties that can be accessed by the external without memory functions
-- Mostly made as a challege for me to make a saveinstance without stealing code from UniversalSynSaveinstance
-- Current things from UniversalSynSaveinstance I have used: AttributesSerialize generator, escapes stuff

local JsonDecode = loadstring(game:HttpGet("https://raw.githubusercontent.com/rxi/json.lua/refs/heads/master/json.lua", true))().decode
local Base64Encode = loadstring(game:HttpGet("https://raw.githubusercontent.com/Reselim/Base64/master/Base64.lua", true))().encode
local MakeAttributesSerialize = loadstring(game:HttpGet("https://raw.githubusercontent.com/Devraj2010isme/SevereSaveinstance/refs/heads/main/MakeAttributesSerialize.luau", true))()

local PropList = { -- Hardcoded because Severe can only read certain arbitrary properties 
	--[[ Classname = {
		PropertyName = {PropertyFunction, ValueType}
	} ]]
	Instance = {
		Name = {function(inst) return inst.Name end, "string"},
		Tags = {
			function(inst)
				local tags = inst:GetTags()
				if #tags == 0 then
					return ""
				end
				return table.concat(tags, "\0")
			end, 
			"BinaryString"
		},
		AttributesSerialize = {MakeAttributesSerialize, "BinaryString"}
	},
	BillboardGui = {
		Adornee = {function(inst) return inst.Adornee end, "ref"}
	},
	Workspace = {
		CurrentCamera = {function(inst) return inst.CurrentCamera end, "ref"}
	},
	Players = {
		LocalPlayer = {function(inst) return inst.LocalPlayer end, "ref"}
	},
	Camera = {
		ViewportSize = {function(inst) return inst.ViewportSize end, "Vector2"},
		FieldOfView = {function(inst) return inst.FieldOfView end, "float"},
		CFrame = {function(inst) return inst.CFrame end, "CoordinateFrame"}
	},
	BasePart = {
		Size = {function(inst) return inst.Size end, "Vector3"},
		CFrame = {function(inst) return inst.CFrame end, "CoordinateFrame"},
		CanCollide = {function(inst) return inst.CanCollide end, "bool"},
		Transparency = {function(inst) return inst.Transparency end, "float"},
		IsNetworkSleeping = {function(inst) return inst.IsNetworkSleeping end, "bool"},
		Velocity = {function(inst) return inst.Velocity end, "Vector3"},
		Shape = {
			function(inst) 
				if inst.Description then 
					return inst.Description.Shape 
				end
			end,
			"token"
		},
		Color = {
			function(inst) 
				if inst.Description then 
					return inst.Description.Color3 
				end
			end,
			"Color3"
		}
	},
	MeshPart = {
		MeshId = {function(inst) return inst.MeshId end, "ContentId"},
		Size = {function(inst) return inst.TextureId end, "ContentId"}
	},
	Player = {
		Team = {function(inst) return inst.Team end, "ref"},
		UserId = {function(inst) return inst.UserId end, "int64"},
		Character = {function(inst) return inst.Character end, "ref"},
		DisplayName = {function(inst) return inst.DisplayName end, "string"},
	},
	Model = {
		PrimaryPart = {function(inst) return inst.PrimaryPart end, "ref"}
	},
	Humanoid = {
		MaxHealth = {function(inst) return inst.MaxHealth end, "float"},
		Health = {function(inst) return inst.Health end, "float"}
	},
	UserInputService = {
		MouseBehavior = {function(inst) return game:GetService("UserInputService").MouseBehavior end, "token"},
		MouseDeltaSensitivity = {function(inst) return game:GetService("UserInputService").MouseDeltaSensitivity end, "float"},
		MouseIconEnabled = {function(inst) return game:GetService("UserInputService").MouseIconEnabled end, "bool"}
	},
	BoolValue = {
		Value = {function(inst) return inst.Value end, "bool"}
	},
	IntValue = {
		Value = {function(inst) return inst.Value end, "int64"}
	},
	NumberValue = {
		Value = {function(inst) return inst.Value end, "double"}
	},
	ObjectValue = {
		Value = {function(inst) return inst.Value end, "ref"}
	},
	StringValue = {
		Value = {function(inst) return inst.Value end, "string"} -- Empty strings return an instance for some reason?
	},
	Vector3Value = {
		Value = {function(inst) return inst.Value end, "Vector3"}
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
		local CanRead, _ = pcall(function() return raw.ClassName end)
		if CanRead then -- CanRead usually fails when the class category property is nil (Severe returns an empty intance), but I've seen random failures in other cases
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
		return buffer.tostring(Base64Encode(buffer.fromstring(raw)))
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
	if not Options then
		Options = {}
	end
	if not Options.ToSave then 
		Options.ToSave = game
	end
	if not Options.PrintInterval then 
		Options.PrintInterval = 1000
	end
	if not Options.FileName then 
		Options.FileName = tostring(game.PlaceId)
	end
	
	local StartingTime = os.clock()
	local SavedInstancesCount = 0
	local SavedInstancesUntilPrint = 0
	local PrintInterval = Options.PrintInterval
	local FileType
	local ToSave = Options.ToSave
	if ToSave == game then
		FileType = "rbxlx"
	else
		FileType = "rbxmx"
	end
	if ToSave == game then
		ToSave = game:GetChildren()
	end	
	if typeof(ToSave) == "Instance" then
		ToSave = {ToSave}
	end
	local FileName = Options.FileName
	local DebugPrints = Options.DebugPrints
	local FullFileName = FileName .. "." .. FileType .. ".txt" -- Severe only lets you write certain files extensions, rbxlx/rbxmx files aren't part of that list
	local SerializedData = '<roblox version="4">' -- XML header
	local CurrentSerializedData = ""
	
	local function SerializeInstances(Instances)
		for _, Instance in Instances do
			local CanRead, _ = pcall(function() return Instance.ClassName end)
			if not CanRead then
				if DebugPrints then
					warn("Broken instance found, skipping")
				end
				continue
			end
			local ClassName = Instance.ClassName
			local Referent = Instance.Data
			CurrentSerializedData ..= '<Item class="' .. ClassName .. '" referent="' .. Referent .. '"><Properties>'
			
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
					local raw = PropertyData[1](Instance)
					local ValueType = PropertyData[2]
					local TypeOfResult = typeof(raw)
					if raw == nil then
						continue
					end
					
					if TypeOfResult == ExpectedTypeOfResults[ValueType] then -- Empty strings are returned as instances for some reason, so this just checks that Severe returns the correct thing (this has been fixed but I'm keeping the code in case there are other errors like it)
						local Formatted
						local Descriptor = Descriptors[ValueType]
						if Descriptor then
							Formatted = Descriptor(raw)
							CurrentSerializedData ..= "<" .. ValueType ..' name="' .. PropertyName .. '">' .. Formatted .. "</" .. ValueType .. ">"
						elseif DebugPrints then
							warn("No descriptor for type " .. ValueType)
						end
					elseif typeof(raw) ~= ExpectedTypeOfResults[ValueType] and DebugPrints then
						warn("Typeof Result (" .. TypeOfResult .. ") did not match expected result for ValueType " .. ValueType .. ". Raw value: " .. tostring(raw) .. " Instance referent: " .. Referent)
					end
				end
			end
			
			CurrentSerializedData ..= "</Properties>"
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