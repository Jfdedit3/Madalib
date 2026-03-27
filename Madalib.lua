local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local Madalib = {}
Madalib.__index = Madalib
Madalib.Theme = {
    Background = Color3.fromRGB(10, 12, 18),
    Surface = Color3.fromRGB(16, 20, 28),
    Surface2 = Color3.fromRGB(24, 29, 40),
    Stroke = Color3.fromRGB(48, 58, 82),
    Accent = Color3.fromRGB(88, 101, 242),
    AccentDark = Color3.fromRGB(65, 77, 204),
    Text = Color3.fromRGB(245, 247, 255),
    TextDim = Color3.fromRGB(176, 184, 204),
    Success = Color3.fromRGB(46, 204, 113),
    Danger = Color3.fromRGB(255, 92, 92)
}
Madalib.Flags = {}
Madalib.Windows = {}

local function protectGui(gui)
    if syn and syn.protect_gui then
        pcall(syn.protect_gui, gui)
    elseif protectgui then
        pcall(protectgui, gui)
    end
end

local function create(className, props)
    local instance = Instance.new(className)
    for key, value in next, props do
        if key ~= "Parent" then
            instance[key] = value
        end
    end
    if props.Parent then
        instance.Parent = props.Parent
    end
    return instance
end

local function round(num, increment)
    if not increment or increment <= 0 then
        return num
    end
    return math.floor(num / increment + 0.5) * increment
end

local function tween(object, properties, duration)
    return TweenService:Create(object, TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), properties)
end

local function makeCorner(parent, radius)
    return create("UICorner", {
        CornerRadius = UDim.new(0, radius or 10),
        Parent = parent
    })
end

local function makeStroke(parent, color, thickness, transparency)
    return create("UIStroke", {
        Color = color or Madalib.Theme.Stroke,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent
    })
end

local function makePadding(parent, left, right, top, bottom)
    return create("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or left or 0),
        PaddingTop = UDim.new(0, top or left or 0),
        PaddingBottom = UDim.new(0, bottom or top or left or 0),
        Parent = parent
    })
end

local function getGuiParent()
    local guiParent = CoreGui
    local success = pcall(function()
        local test = Instance.new("ScreenGui")
        test.Parent = CoreGui
        test:Destroy()
    end)
    if not success and LocalPlayer then
        guiParent = LocalPlayer:WaitForChild("PlayerGui")
    end
    return guiParent
end

local function addHover(button, normalColor, hoverColor)
    button.MouseEnter:Connect(function()
        tween(button, {BackgroundColor3 = hoverColor}, 0.12):Play()
    end)
    button.MouseLeave:Connect(function()
        tween(button, {BackgroundColor3 = normalColor}, 0.12):Play()
    end)
end

local function addPressScale(object, target)
    local base = object.Size
    object.MouseButton1Down:Connect(function()
        tween(object, {Size = UDim2.new(base.X.Scale, base.X.Offset, base.Y.Scale, math.max(0, base.Y.Offset - (target or 2)))}, 0.08):Play()
    end)
    object.MouseButton1Up:Connect(function()
        tween(object, {Size = base}, 0.08):Play()
    end)
    object.MouseLeave:Connect(function()
        tween(object, {Size = base}, 0.08):Play()
    end)
end

local function makeDraggable(handle, target)
    local dragging = false
    local dragStart
    local startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

local function fitCanvas(layout, scroll)
    local function update()
        scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 12)
    end
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(update)
    update()
end

function Madalib:Notify(options)
    options = options or {}
    local title = options.Title or "Madalib"
    local content = options.Content or options.Text or "Notification"
    local time = options.Duration or 3

    local holder = self.NotificationHolder
    if not holder then
        return
    end

    local card = create("Frame", {
        BackgroundColor3 = self.Theme.Surface,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = holder
    })
    makeCorner(card, 12)
    makeStroke(card)
    makePadding(card, 12, 12, 10, 10)

    local accent = create("Frame", {
        BackgroundColor3 = self.Theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 4, 1, 0),
        Parent = card
    })
    makeCorner(accent, 999)

    local titleLabel = create("TextLabel", {
        BackgroundTransparency = 1,
        Text = title,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = self.Theme.Text,
        Size = UDim2.new(1, -12, 0, 18),
        Position = UDim2.new(0, 10, 0, 0),
        Parent = card
    })

    local bodyLabel = create("TextLabel", {
        BackgroundTransparency = 1,
        Text = content,
        Font = Enum.Font.Gotham,
        TextWrapped = true,
        AutomaticSize = Enum.AutomaticSize.Y,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextColor3 = self.Theme.TextDim,
        Size = UDim2.new(1, -12, 0, 18),
        Position = UDim2.new(0, 10, 0, 20),
        Parent = card
    })

    create("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = holder
    })

    card.BackgroundTransparency = 1
    tween(card, {BackgroundTransparency = 0}, 0.18):Play()

    task.spawn(function()
        task.wait(time)
        local hide = tween(card, {BackgroundTransparency = 1}, 0.2)
        hide:Play()
        hide.Completed:Wait()
        card:Destroy()
    end)
end

function Madalib:MakeWindow(options)
    options = options or {}

    local window = setmetatable({}, {__index = self})
    window.Name = options.Name or options.Title or "Madalib"
    window.Subtitle = options.Subtitle or options.SubTitle or ""
    window.Theme = options.Theme or self.Theme
    window.Tabs = {}
    window.CurrentTab = nil

    local screenGui = create("ScreenGui", {
        Name = "Madalib_" .. HttpService:GenerateGUID(false),
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        Parent = getGuiParent()
    })
    protectGui(screenGui)
    window.ScreenGui = screenGui

    local root = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 700, 0, 430),
        Parent = screenGui
    })
    window.Root = root

    local main = create("Frame", {
        BackgroundColor3 = window.Theme.Background,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        Parent = root
    })
    makeCorner(main, 18)
    makeStroke(main, window.Theme.Stroke, 1, 0)
    window.Main = main

    local shadow = create("ImageLabel", {
        BackgroundTransparency = 1,
        Image = "rbxassetid://1316045217",
        ImageTransparency = 0.82,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(10, 10, 118, 118),
        Size = UDim2.new(1, 38, 1, 38),
        Position = UDim2.new(0, -19, 0, -19),
        ZIndex = 0,
        Parent = main
    })

    local topbar = create("Frame", {
        BackgroundColor3 = window.Theme.Surface,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 58),
        Parent = main
    })
    makeCorner(topbar, 18)

    local topbarFix = create("Frame", {
        BackgroundColor3 = window.Theme.Surface,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.new(0, 0, 1, -20),
        Parent = topbar
    })

    local title = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 18, 0, 8),
        Size = UDim2.new(1, -110, 0, 20),
        Text = window.Name,
        TextColor3 = window.Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = topbar
    })

    local subtitle = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 18, 0, 28),
        Size = UDim2.new(1, -110, 0, 16),
        Text = window.Subtitle,
        TextColor3 = window.Theme.TextDim,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = topbar
    })

    local minimize = create("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = window.Theme.Surface2,
        BorderSizePixel = 0,
        Text = "—",
        Font = Enum.Font.GothamBold,
        TextColor3 = window.Theme.Text,
        TextSize = 18,
        Size = UDim2.new(0, 36, 0, 36),
        Position = UDim2.new(1, -84, 0, 11),
        Parent = topbar
    })
    makeCorner(minimize, 10)
    makeStroke(minimize)
    addHover(minimize, window.Theme.Surface2, window.Theme.AccentDark)

    local close = create("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = window.Theme.Surface2,
        BorderSizePixel = 0,
        Text = "✕",
        Font = Enum.Font.GothamBold,
        TextColor3 = window.Theme.Text,
        TextSize = 14,
        Size = UDim2.new(0, 36, 0, 36),
        Position = UDim2.new(1, -42, 0, 11),
        Parent = topbar
    })
    makeCorner(close, 10)
    makeStroke(close)
    addHover(close, window.Theme.Surface2, window.Theme.Danger)

    local sidebar = create("Frame", {
        BackgroundColor3 = window.Theme.Surface,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 58),
        Size = UDim2.new(0, 190, 1, -58),
        Parent = main
    })

    local tabHolder = create("ScrollingFrame", {
        Active = true,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 10, 0, 10),
        Size = UDim2.new(1, -20, 1, -20),
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = window.Theme.Accent,
        Parent = sidebar
    })
    local tabLayout = create("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = tabHolder
    })

    local content = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 190, 0, 58),
        Size = UDim2.new(1, -190, 1, -58),
        Parent = main
    })

    local pageFolder = create("Folder", {
        Name = "Pages",
        Parent = content
    })

    local notifications = create("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -14, 0, 14),
        Size = UDim2.new(0, 280, 1, -28),
        Parent = screenGui
    })
    local notifLayout = create("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        Parent = notifications
    })
    window.NotificationHolder = notifications

    makeDraggable(topbar, root)

    local minimized = false
    minimize.MouseButton1Click:Connect(function()
        minimized = not minimized
        tween(root, {Size = minimized and UDim2.new(0, 700, 0, 58) or UDim2.new(0, 700, 0, 430)}, 0.22):Play()
    end)

    close.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)

    function window:AddMinimizeButton(options2)
        options2 = options2 or {}
        local imageId = options2.Button and options2.Button.Image or "rbxassetid://77855434347030"
        local button = create("ImageButton", {
            Name = "MadalibMinimizeButton",
            AutoButtonColor = false,
            BackgroundColor3 = window.Theme.Surface,
            BackgroundTransparency = options2.Button and options2.Button.BackgroundTransparency or 0,
            BorderSizePixel = 0,
            Image = imageId,
            Size = UDim2.new(0, 48, 0, 48),
            Position = UDim2.new(0, 18, 1, -66),
            Parent = screenGui
        })
        makeCorner(button, 12)
        makeStroke(button)
        addHover(button, window.Theme.Surface, window.Theme.AccentDark)
        button.MouseButton1Click:Connect(function()
            main.Visible = not main.Visible
        end)
        return button
    end

    function window:SelectTab(tab)
        for _, current in ipairs(window.Tabs) do
            current.Page.Visible = false
            tween(current.Button, {BackgroundColor3 = window.Theme.Surface2}, 0.15):Play()
            if current.AccentBar then
                tween(current.AccentBar, {BackgroundTransparency = 1}, 0.15):Play()
            end
        end
        tab.Page.Visible = true
        window.CurrentTab = tab
        tween(tab.Button, {BackgroundColor3 = window.Theme.AccentDark}, 0.15):Play()
        if tab.AccentBar then
            tween(tab.AccentBar, {BackgroundTransparency = 0}, 0.15):Play()
        end
    end

    function window:MakeTab(tabOptions)
        tabOptions = tabOptions or {}
        local tab = {}
        tab.Name = tabOptions.Name or "Tab"
        tab.Icon = tabOptions.Icon or ""
        tab.Window = window

        local tabButton = create("TextButton", {
            AutoButtonColor = false,
            BackgroundColor3 = window.Theme.Surface2,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 44),
            Text = "",
            Parent = tabHolder
        })
        makeCorner(tabButton, 12)
        makeStroke(tabButton)
        addHover(tabButton, window.Theme.Surface2, window.Theme.AccentDark)

        local accentBar = create("Frame", {
            BackgroundColor3 = window.Theme.Accent,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 4, 1, -12),
            Position = UDim2.new(0, 6, 0, 6),
            Parent = tabButton
        })
        makeCorner(accentBar, 999)

        if tab.Icon ~= "" then
            create("ImageLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 18, 0, 18),
                Position = UDim2.new(0, 14, 0.5, -9),
                Image = tab.Icon,
                Parent = tabButton
            })
        end

        create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, tab.Icon ~= "" and -52 or -28, 1, 0),
            Position = UDim2.new(0, tab.Icon ~= "" and 38 or 16, 0, 0),
            Text = tab.Name,
            Font = Enum.Font.GothamMedium,
            TextSize = 13,
            TextColor3 = window.Theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = tabButton
        })

        local page = create("ScrollingFrame", {
            Active = true,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            CanvasSize = UDim2.new(),
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = window.Theme.Accent,
            Visible = false,
            Parent = pageFolder
        })
        makePadding(page, 12, 12, 12, 12)
        local pageLayout = create("UIListLayout", {
            Padding = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = page
        })
        fitCanvas(pageLayout, page)

        tab.Button = tabButton
        tab.Page = page
        tab.Layout = pageLayout
        tab.AccentBar = accentBar

        function tab:AddSection(text)
            local section = create("TextLabel", {
                BackgroundTransparency = 1,
                Text = tostring(text or "Section"),
                Font = Enum.Font.GothamBold,
                TextSize = 15,
                TextColor3 = window.Theme.Text,
                Size = UDim2.new(1, -4, 0, 22),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = page
            })
            return section
        end

        function tab:AddParagraph(titleText, bodyText)
            local card = create("Frame", {
                BackgroundColor3 = window.Theme.Surface,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 78),
                AutomaticSize = Enum.AutomaticSize.Y,
                Parent = page
            })
            makeCorner(card, 14)
            makeStroke(card)
            makePadding(card, 14, 14, 12, 12)

            create("TextLabel", {
                BackgroundTransparency = 1,
                Text = tostring(titleText or "Paragraph"),
                Font = Enum.Font.GothamBold,
                TextSize = 14,
                TextColor3 = window.Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, 0, 0, 18),
                Parent = card
            })

            local body = create("TextLabel", {
                BackgroundTransparency = 1,
                Text = tostring(bodyText or "Text"),
                Font = Enum.Font.Gotham,
                TextWrapped = true,
                AutomaticSize = Enum.AutomaticSize.Y,
                TextSize = 13,
                TextColor3 = window.Theme.TextDim,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                Position = UDim2.new(0, 0, 0, 22),
                Size = UDim2.new(1, 0, 0, 18),
                Parent = card
            })

            return {
                Set = function(_, newTitle, newBody)
                    if newTitle then
                        card:FindFirstChildOfClass("TextLabel").Text = tostring(newTitle)
                    end
                    if newBody then
                        body.Text = tostring(newBody)
                    end
                end
            }
        end

        function tab:AddButton(buttonOptions)
            buttonOptions = buttonOptions or {}
            local button = create("TextButton", {
                AutoButtonColor = false,
                BackgroundColor3 = window.Theme.Surface,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 42),
                Text = "",
                Parent = page
            })
            makeCorner(button, 14)
            makeStroke(button)
            addHover(button, window.Theme.Surface, window.Theme.AccentDark)
            addPressScale(button, 2)

            create("TextLabel", {
                BackgroundTransparency = 1,
                Text = buttonOptions.Name or "Button",
                Font = Enum.Font.GothamMedium,
                TextSize = 13,
                TextColor3 = window.Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, -28, 1, 0),
                Position = UDim2.new(0, 14, 0, 0),
                Parent = button
            })

            button.MouseButton1Click:Connect(function()
                if buttonOptions.Callback then
                    task.spawn(buttonOptions.Callback)
                end
            end)

            return button
        end

        function tab:AddToggle(toggleOptions)
            toggleOptions = toggleOptions or {}
            local value = toggleOptions.Default or false
            local flag = toggleOptions.Flag
            if flag then
                Madalib.Flags[flag] = value
            end

            local holder = create("TextButton", {
                AutoButtonColor = false,
                BackgroundColor3 = window.Theme.Surface,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 48),
                Text = "",
                Parent = page
            })
            makeCorner(holder, 14)
            makeStroke(holder)
            addHover(holder, window.Theme.Surface, window.Theme.Surface2)

            create("TextLabel", {
                BackgroundTransparency = 1,
                Text = toggleOptions.Name or "Toggle",
                Font = Enum.Font.GothamMedium,
                TextSize = 13,
                TextColor3 = window.Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, -80, 1, 0),
                Position = UDim2.new(0, 14, 0, 0),
                Parent = holder
            })

            local switch = create("Frame", {
                BackgroundColor3 = value and window.Theme.Accent or window.Theme.Surface2,
                BorderSizePixel = 0,
                Size = UDim2.new(0, 46, 0, 24),
                Position = UDim2.new(1, -60, 0.5, -12),
                Parent = holder
            })
            makeCorner(switch, 999)
            makeStroke(switch)

            local knob = create("Frame", {
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                Size = UDim2.new(0, 18, 0, 18),
                Position = value and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9),
                Parent = switch
            })
            makeCorner(knob, 999)

            local function setToggle(newValue)
                value = newValue
                if flag then
                    Madalib.Flags[flag] = value
                end
                tween(switch, {BackgroundColor3 = value and window.Theme.Accent or window.Theme.Surface2}, 0.15):Play()
                tween(knob, {Position = value and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)}, 0.15):Play()
                if toggleOptions.Callback then
                    task.spawn(function()
                        toggleOptions.Callback(value)
                    end)
                end
            end

            holder.MouseButton1Click:Connect(function()
                setToggle(not value)
            end)

            return {
                Set = function(_, newValue)
                    setToggle(newValue)
                end,
                Value = function()
                    return value
                end
            }
        end

        function tab:AddSlider(sliderOptions)
            sliderOptions = sliderOptions or {}
            local min = sliderOptions.Min or 0
            local max = sliderOptions.Max or 100
            local increment = sliderOptions.Increment or 1
            local value = sliderOptions.Default or min
            local flag = sliderOptions.Flag
            if flag then
                Madalib.Flags[flag] = value
            end

            local holder = create("Frame", {
                BackgroundColor3 = window.Theme.Surface,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 66),
                Parent = page
            })
            makeCorner(holder, 14)
            makeStroke(holder)
            makePadding(holder, 14, 14, 12, 12)

            create("TextLabel", {
                BackgroundTransparency = 1,
                Text = sliderOptions.Name or "Slider",
                Font = Enum.Font.GothamMedium,
                TextSize = 13,
                TextColor3 = window.Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, -70, 0, 16),
                Parent = holder
            })

            local valueLabel = create("TextLabel", {
                BackgroundTransparency = 1,
                Text = tostring(value) .. (sliderOptions.ValueName and (" " .. sliderOptions.ValueName) or ""),
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextColor3 = window.Theme.TextDim,
                TextXAlignment = Enum.TextXAlignment.Right,
                Size = UDim2.new(0, 70, 0, 16),
                Position = UDim2.new(1, -70, 0, 0),
                Parent = holder
            })

            local bar = create("Frame", {
                BackgroundColor3 = window.Theme.Surface2,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 8),
                Position = UDim2.new(0, 0, 0, 34),
                Parent = holder
            })
            makeCorner(bar, 999)

            local fill = create("Frame", {
                BackgroundColor3 = window.Theme.Accent,
                BorderSizePixel = 0,
                Size = UDim2.new((value - min) / math.max(max - min, 1), 0, 1, 0),
                Parent = bar
            })
            makeCorner(fill, 999)

            local dragging = false

            local function setSlider(newValue)
                newValue = math.clamp(round(newValue, increment), min, max)
                value = newValue
                if flag then
                    Madalib.Flags[flag] = value
                end
                local alpha = (value - min) / math.max(max - min, 1)
                fill.Size = UDim2.new(alpha, 0, 1, 0)
                valueLabel.Text = tostring(value) .. (sliderOptions.ValueName and (" " .. sliderOptions.ValueName) or "")
                if sliderOptions.Callback then
                    task.spawn(function()
                        sliderOptions.Callback(value)
                    end)
                end
            end

            local function updateSlider(input)
                local alpha = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                local calc = min + ((max - min) * alpha)
                setSlider(calc)
            end

            bar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    updateSlider(input)
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    updateSlider(input)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)

            return {
                Set = function(_, newValue)
                    setSlider(newValue)
                end,
                Value = function()
                    return value
                end
            }
        end

        function tab:AddTextbox(textboxOptions)
            textboxOptions = textboxOptions or {}
            local flag = textboxOptions.Flag
            local value = textboxOptions.Default or ""
            if flag then
                Madalib.Flags[flag] = value
            end

            local holder = create("Frame", {
                BackgroundColor3 = window.Theme.Surface,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 56),
                Parent = page
            })
            makeCorner(holder, 14)
            makeStroke(holder)
            makePadding(holder, 14, 14, 10, 10)

            create("TextLabel", {
                BackgroundTransparency = 1,
                Text = textboxOptions.Name or "Textbox",
                Font = Enum.Font.GothamMedium,
                TextSize = 13,
                TextColor3 = window.Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, 0, 0, 16),
                Parent = holder
            })

            local box = create("TextBox", {
                BackgroundColor3 = window.Theme.Surface2,
                BorderSizePixel = 0,
                ClearTextOnFocus = textboxOptions.ClearTextOnFocus == true,
                PlaceholderText = textboxOptions.PlaceholderText or "Type here",
                PlaceholderColor3 = window.Theme.TextDim,
                Text = value,
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextColor3 = window.Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, 0, 0, 24),
                Position = UDim2.new(0, 0, 0, 22),
                Parent = holder
            })
            makeCorner(box, 10)
            makeStroke(box)
            makePadding(box, 10, 10, 0, 0)

            local function commit()
                value = box.Text
                if flag then
                    Madalib.Flags[flag] = value
                end
                if textboxOptions.Callback then
                    task.spawn(function()
                        textboxOptions.Callback(value)
                    end)
                end
            end

            if textboxOptions.Callback then
                box.FocusLost:Connect(function(enterPressed)
                    if textboxOptions.EnterOnly then
                        if enterPressed then
                            commit()
                        end
                    else
                        commit()
                    end
                end)
            end

            return {
                Set = function(_, newText)
                    box.Text = tostring(newText)
                    commit()
                end,
                Value = function()
                    return value
                end
            }
        end

        function tab:AddDropdown(dropdownOptions)
            dropdownOptions = dropdownOptions or {}
            local optionsList = dropdownOptions.Options or dropdownOptions.Values or {}
            local value = dropdownOptions.Default or optionsList[1] or ""
            local flag = dropdownOptions.Flag
            if flag then
                Madalib.Flags[flag] = value
            end

            local holder = create("Frame", {
                BackgroundColor3 = window.Theme.Surface,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 56),
                ClipsDescendants = true,
                Parent = page
            })
            makeCorner(holder, 14)
            makeStroke(holder)
            makePadding(holder, 14, 14, 10, 10)

            create("TextLabel", {
                BackgroundTransparency = 1,
                Text = dropdownOptions.Name or "Dropdown",
                Font = Enum.Font.GothamMedium,
                TextSize = 13,
                TextColor3 = window.Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, 0, 0, 16),
                Parent = holder
            })

            local mainButton = create("TextButton", {
                AutoButtonColor = false,
                BackgroundColor3 = window.Theme.Surface2,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 24),
                Position = UDim2.new(0, 0, 0, 22),
                Text = "",
                Parent = holder
            })
            makeCorner(mainButton, 10)
            makeStroke(mainButton)

            local chosen = create("TextLabel", {
                BackgroundTransparency = 1,
                Text = tostring(value),
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextColor3 = window.Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, -24, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                Parent = mainButton
            })

            create("TextLabel", {
                BackgroundTransparency = 1,
                Text = "∨",
                Font = Enum.Font.GothamBold,
                TextSize = 12,
                TextColor3 = window.Theme.TextDim,
                TextXAlignment = Enum.TextXAlignment.Center,
                Size = UDim2.new(0, 20, 1, 0),
                Position = UDim2.new(1, -24, 0, 0),
                Parent = mainButton
            })

            local listFrame = create("Frame", {
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 0, 52),
                Size = UDim2.new(1, 0, 0, 0),
                Parent = holder
            })

            local listLayout = create("UIListLayout", {
                Padding = UDim.new(0, 6),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = listFrame
            })

            local opened = false

            local function refreshOptions()
                for _, child in ipairs(listFrame:GetChildren()) do
                    if child:IsA("TextButton") then
                        child:Destroy()
                    end
                end
                for _, option in ipairs(optionsList) do
                    local item = create("TextButton", {
                        AutoButtonColor = false,
                        BackgroundColor3 = window.Theme.Surface2,
                        BorderSizePixel = 0,
                        Size = UDim2.new(1, 0, 0, 24),
                        Text = tostring(option),
                        Font = Enum.Font.Gotham,
                        TextSize = 13,
                        TextColor3 = window.Theme.Text,
                        Parent = listFrame
                    })
                    makeCorner(item, 9)
                    makeStroke(item)
                    addHover(item, window.Theme.Surface2, window.Theme.AccentDark)
                    item.MouseButton1Click:Connect(function()
                        value = option
                        chosen.Text = tostring(option)
                        if flag then
                            Madalib.Flags[flag] = value
                        end
                        if dropdownOptions.Callback then
                            task.spawn(function()
                                dropdownOptions.Callback(value)
                            end)
                        end
                        opened = false
                        tween(holder, {Size = UDim2.new(1, 0, 0, 56)}, 0.18):Play()
                        tween(listFrame, {Size = UDim2.new(1, 0, 0, 0)}, 0.18):Play()
                    end)
                end
            end

            refreshOptions()

            local function getExpandedHeight()
                return 56 + (#optionsList * 30)
            end

            mainButton.MouseButton1Click:Connect(function()
                opened = not opened
                tween(holder, {Size = UDim2.new(1, 0, 0, opened and getExpandedHeight() or 56)}, 0.18):Play()
                tween(listFrame, {Size = UDim2.new(1, 0, 0, opened and (#optionsList * 30) or 0)}, 0.18):Play()
            end)

            return {
                Set = function(_, newValue)
                    value = newValue
                    chosen.Text = tostring(newValue)
                    if flag then
                        Madalib.Flags[flag] = value
                    end
                    if dropdownOptions.Callback then
                        task.spawn(function()
                            dropdownOptions.Callback(value)
                        end)
                    end
                end,
                Refresh = function(_, newOptions)
                    optionsList = newOptions or {}
                    refreshOptions()
                end,
                Value = function()
                    return value
                end
            }
        end

        tabButton.MouseButton1Click:Connect(function()
            window:SelectTab(tab)
        end)

        table.insert(window.Tabs, tab)
        if not window.CurrentTab then
            window:SelectTab(tab)
        end

        return tab
    end

    table.insert(self.Windows, window)

    if options.IntroEnabled then
        root.Size = UDim2.new(0, 0, 0, 0)
        tween(root, {Size = UDim2.new(0, 700, 0, 430)}, 0.3):Play()
    end

    return window
end

return setmetatable(Madalib, Madalib)