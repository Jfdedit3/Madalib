# Madalib

Madalib is a Roblox UI library inspired by OrionLib.

## Loadstring

```lua
local Madalib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Jfdedit3/Madalib/main/Madalib.lua"))()
```

## Example

```lua
local Madalib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Jfdedit3/Madalib/main/Madalib.lua"))()

local Window = Madalib:MakeWindow({
    Name = "Mada Hub",
    Subtitle = "by z4trox",
    SaveConfig = false,
    IntroEnabled = false
})

local MainTab = Window:MakeTab({
    Name = "Main",
    Icon = "rbxassetid://4483345998"
})

MainTab:AddSection("Actions")

MainTab:AddButton({
    Name = "Test button",
    Callback = function()
        print("clicked")
    end
})

MainTab:AddToggle({
    Name = "Speed",
    Default = false,
    Callback = function(Value)
        print("toggle", Value)
    end
})

MainTab:AddSlider({
    Name = "WalkSpeed",
    Min = 0,
    Max = 100,
    Default = 16,
    Increment = 1,
    ValueName = "speed",
    Callback = function(Value)
        print("slider", Value)
    end
})

MainTab:AddTextbox({
    Name = "Player",
    PlaceholderText = "Enter a name",
    ClearTextOnFocus = false,
    Callback = function(Text)
        print(Text)
    end
})

MainTab:AddDropdown({
    Name = "Target",
    Default = "Player1",
    Options = {"Player1", "Player2", "Player3"},
    Callback = function(Value)
        print(Value)
    end
})

MainTab:AddParagraph("Info", "Madalib first public version")
```
