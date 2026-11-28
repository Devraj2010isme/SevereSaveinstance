# Severe Saveinstance
A saveinstance script for Severe External. 
# Loadstring

```lua
local saveinstance = loadstring(game:HttpGet("https://raw.githubusercontent.com/Devraj2010isme/SevereSaveinstance/refs/heads/main/SevereSaveinstanceXML.luau"))()
local options = {}
saveinstance(options)
```

# Options Documentation
- Decompile: `boolean`
  - Whether to decompile local and module scripts
  - Default: true
- DecompileIgnore `{Instance | Pointer}`
  - Table of scripts that will not be decompiled (also applies to descendants)
  - Default: {}
- SaveBytecode: `boolean`
  - Whether to include the base64-encoded bytecode of local and module scripts
  - Default: false
- DecompileFunction: `function`
  - The function used when decompiling scripts
  - Default: A function that uses the lua.expert api
- ToSave: `Instance | Pointer | {Instance | Pointer}`
  - Instance(s) that will be saved
  - Default: A table of common services (see source code)
- ReadMe: `bool`
  - Whether to include a README script which contains the GameId, PlaceId, and place version
  - Default: true
- FileName: `string`
  - File name without extension
  - Default: The place id of the place being saved
- IsModel:
  -  Whether the file is saved as a model (rbxmx) file instead of a place file (rbxlx)
  -  Default: nil (saves as a model when at least 1 of the instances in ToSave is not parented to game)
- PrintInterval: `integer`
  - The number of instances saved between prints
  - Default: 1000
- NotCreatableFixes: `{ClassName = "Redirect"}`
  - Saves instances as different classes so they can appear in studio
  - Default: {Player = "Folder", PlayerGui = "Folder", PlayerScripts = "Folder", TouchTransmitter = "Folder"}
- DebugPrints: `boolean`
  - Prints warnings about unusual scenarios
  - Default: false

# TODO
- More properties
- Speed up serialization (the serialization code is very slow right now)
- Terrain saving
  - https://github.com/checkraisefold/rbx-dom/blob/terrain/docs/smooth-grid.md
- Custom attributes reading instead of using Severe's attributes
  - Severe's attributes don't support all types and return all attributes as string type