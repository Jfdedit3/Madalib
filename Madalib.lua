local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local Madalib = {}
Madalib.__index = Madalib

Madalib.Theme = {
    Background = Color3.fromRGB(10, 12, 18),
    Surface = Color3.fromRGB(16, 20, 28),
    Surface2 = Color3.fromRGB(23, 28, 38),
    Stroke = Color3.fromRGB(52, 60, 84),
    Accent = Color3.fromRGB(88, 101, 242),
    AccentDark = Color3.fromRGB(67, 79, 214),
    Text = Color3.fromRGB(245, 247, 255),
    TextDim = Color3.fromRGB(170, 178, 198),
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

local function tween(object, properties, duration, style, direction)
    return TweenService:Create(
        object,
        TweenInfo.new(
            duration or 0.2,
            style or Enum.EasingStyle.Quint,
            direction or Enum.EasingDirection.Out
        ),
        properties
    )
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

local function round(num, increment)
    if not increment or increment <= 0 then
        return num
    end
    return math.floor(num / increment + 0.5) * increment
end

local function getGuiParent()
    local parent = CoreGui
    local ok = pcall(function()
        local test = Instance.new("ScreenGui")
        test.Parent = CoreGui
        test:Destroy()
    end)

    if not ok and LocalPlayer then
        parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    return parent
end

local function addHover(button, normalColor, hoverColor)
    button.MouseEnter:Connect(function()
        tween(button, {BackgroundColor3 = hoverColor}, 0.12):Play()
    end)

    button.MouseLeave:Connect(function()
        tween(button, {BackgroundColor3 = normalColor}, 0.12):Play()
    end)
end

local function addPress(button, normalSize, pressedOffset)
    local pressed = UDim2.new(
        normalSize.X.Scale,
        normalSize.X.Offset,
        normalSize.Y.Scale,
        math.max(0, normalSize.Y.Offset - (pressedOffset or 2))
    )

    button.MouseButton1Down:Connect(function()
        tween(button, {Size = pressed}, 0.08, Enum.EasingStyle.Quad):Play()
    end)

    local function restore()
        tween(button, {Size = normalSize}, 0.08, Enum.EasingStyle.Quad):Play()
    end

    button.MouseButton1Up:Connect(restore)
    button.MouseLeave:Connect(restore)
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

local function attachCanvas(layout, scroll, extra)
    local function update()
        scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + (extra or 10))
    end

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(update)
    update()
end

local function animateObjectIn(object, props)
    props = props or {}

    if object:IsA("GuiObject") then
        local originalPosition = object.Position
        object.Position = originalPosition + UDim2.new(0, props.X or 0, 0, props.Y or 8)

        if object.BackgroundTransparency < 1 then
            local bg = object.BackgroundTransparency
            object.BackgroundTransparency = 1
            tween(object, {
                Position = originalPosition,
                BackgroundTransparency = bg
            }, props.Time or 0.18):Play()
        else
            tween(object, {
                Position = originalPosition
            }, props.Time or 0.18):Play()
        end
    end

    for _, child in ipairs(object:GetDescendants()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
            local original = child.TextTransparency
            child.TextTransparency = 1
            tween(child, {TextTransparency = original}, props.Time or 0.18):Play()
        elseif child:IsA("ImageLabel") or child:IsA("ImageButton") then
            local original = child.ImageTransparency
            child.ImageTransparency = 1
            tween(child, {ImageTransparency = original}, props.Time or 0.18):Play()
        elseif child:IsA("UIStroke") then
            local original = child.Transparency
            child.Transparency = 1
            tween(child, {Transparency = original}, props.Time or 0.18):Play()
        end
    end
end

function Madalib:MakeWindow(options)
    options = options or {}

    local window = setmetatable({}, {__index = self})
    window.Name = options.Name or options.Title or "Madalib"
    window.Subtitle = options.Subtitle or options.SubTitle or ""
    window.Theme = options.Theme or self.Theme
    window.Tabs = {}
    window.CurrentTab = nil
    window.WindowSize = options.Size or UDim2.new(0, 580, 0, 360)
    window.MinimizedSize = UDim2.new(0, window.WindowSize.X.Offset, 0, 52)

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
        Size = window.WindowSize,
        Parent = screenGui
    })
    window.Root = root

    local main = create("Frame", {
        BackgroundColor3 = window.Theme.Background,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        Parent = root
    })
    makeCorner(main, 16)
    makeStroke(main, window.Theme.Stroke)
    window.Main = main

    create("ImageLabel", {
        BackgroundTransparency = 1,
        Image = "rbxassetid://1316045217",
        ImageTransparency = 0.86,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(10, 10, 118, 118),
        Size = UDim2.new(1, 34, 1, 34),
        Position = UDim2.new(0, -17, 0, -17),
        ZIndex = 0,
        Parent = main
    })

    local topbar = create("Frame", {
        BackgroundColor3 = window.Theme.Surface,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 52),
        Parent = main
    })
    makeCorner(topbar, 16)

    create("Frame", {
        BackgroundColor3 = window.Theme.Surface,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 18),
        Position = UDim2.new(0, 0, 1, -18),
        Parent = topbar
    })

    create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 7),
        Size = UDim2.new(1, -100, 0, 18),
        Text = window.Name,
        TextColor3 = window.Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = topbar
    })

    create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 25),
        Size = UDim2.new(1, -100, 0, 14),
        Text = window.Subtitle,
        TextColor3 = window.Theme.TextDim,
        Font = Enum.Font.Gotham,
        TextSize = 11,
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
        TextSize = 16,
        Size = UDim2.new(0, 32, 0, 32),
        Position = UDim2.new(1, -74, 0, 10),
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
        TextSize = 13,
        Size = UDim2.new(0, 32, 0, 32),
        Position = UDim2.new(1, -38, 0, 10),
        Parent = topbar
    })
    makeCorner(close, 10)
    makeStroke(close)
    addHover(close, window.Theme.Surface2, window.Theme.Danger)

    local sidebar = create("Frame", {
        BackgroundColor3 = window.Theme.Surface,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 52),
        Size = UDim2.new(0, 160, 1, -52),
        Parent = main
    })

    local tabHolder = create("ScrollingFrame", {
        Active = true,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 10, 0, 10),
        Size = UDim2.new(1, -20, 1, -20),
        CanvasSize = UDim2.new(),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = window.Theme.Accent,
        Parent = sidebar
    })

    local tabLayout = create("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = tabHolder
    })

    attachCanvas(tabLayout, tabHolder, 8)

    local content = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 160, 0, 52),
        Size = UDim2.new(1, -160, 1, -52),
        ClipsDescendants = true,
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
        Size = UDim2.new(0, 250, 1, -28),
        Parent = screenGui
    })
    create("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        Parent = notifications
    })
    window.NotificationHolder = notifications

    makeDraggable(topbar, root)

    local minimized = false

    function window:Notify(opts)
        opts = opts or {}

        local card = create("Frame", {
            BackgroundColor3 = self.Theme.Surface,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Parent = self.NotificationHolder
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

        create("TextLabel", {
            BackgroundTransparency = 1,
            Text = opts.Title or "Madalib",
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = self.Theme.Text,
            Size = UDim2.new(1, -12, 0, 16),
            Position = UDim2.new(0, 10, 0, 0),
            Parent = card
        })

        create("TextLabel", {
            BackgroundTransparency = 1,
            Text = opts.Content or opts.Text or "Notification",
            Font = Enum.Font.Gotham,
            TextWrapped = true,
            AutomaticSize = Enum.AutomaticSize.Y,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextColor3 = self.Theme.TextDim,
            Size = UDim2.new(1, -12, 0, 16),
            Position = UDim2.new(0, 10, 0, 18),
            Parent = card
        })

        animateObjectIn(card, {X = 20, Y = 0, Time = 0.18})

        task.spawn(function()
            task.wait(opts.Duration or 3)
            tween(card, {
                BackgroundTransparency = 1,
                Position = card.Position + UDim2.new(0, 20, 0, 0)
            }, 0.18):Play()

            for _, child in ipairs(card:GetDescendants()) do
                if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
                    tween(child, {TextTransparency = 1}, 0.18):Play()
                elseif child:IsA("ImageLabel") or child:IsA("ImageButton") then
                    tween(child, {ImageTransparency = 1}, 0.18):Play()
                elseif child:IsA("UIStroke") then
                    tween(child, {Transparency = 1}, 0.18):Play()
                end
            end

            task.wait(0.2)
            card:Destroy()
        end)
    end

    function window:AddMinimizeButton(buttonOptions)
        buttonOptions = buttonOptions or {}
        local imageId = buttonOptions.Button and buttonOptions.Button.Image or "rbxassetid://77855434347030"
        local miniButton = create("ImageButton", {
            Name = "MadalibMinimizeButton",
            AutoButtonColor = false,
            BackgroundColor3 = self.Theme.Surface,
            BackgroundTransparency = buttonOptions.Button and buttonOptions.Button.BackgroundTransparency or 0,
            BorderSizePixel = 0,
            Image = imageId,
            Size = UDim2.new(0, 44, 0, 44),
            Position = UDim2.new(0, 16, 1, -60),
            Parent = self.ScreenGui
        })
        makeCorner(miniButton, 12)
        makeStroke(miniButton)
        addHover(miniButton, self.Theme.Surface, self.Theme.AccentDark)

        miniButton.MouseButton1Click:Connect(function()
            main.Visible = not main.Visible
            if main.Visible then
                root.Size = self.WindowSize
                animateObjectIn(main, {Y = 10, Time = 0.16})
            end
        end)

        return miniButton
    end

    function window:SelectTab(tab)
        if self.CurrentTab == tab then
            return
        end

        for _, current in ipairs(self.Tabs) do
            tween(current.Button, {BackgroundColor3 = self.Theme.Surface2}, 0.14):Play()
            if current.AccentBar then
                tween(current.AccentBar, {BackgroundTransparency = 1}, 0.14):Play()
            end
            current.Page.Visible = false
        end

        tab.Page.Position = UDim2.new(0, 14, 0, 0)
        tab.Page.Visible = true
        tab.Page.ScrollBarImageTransparency = 1

        tween(tab.Page, {Position = UDim2.new(0, 0, 0, 0)}, 0.18):Play()
        tween(tab.Button, {BackgroundColor3 = self.Theme.AccentDark}, 0.14):Play()
        if tab.AccentBar then
            tween(tab.AccentBar, {BackgroundTransparency = 0}, 0.14):Play()
        end

        self.CurrentTab = tab
    end

    function window:MakeTab(tabOptions)
        tabOptions = tabOptions or {}

        local tab = {}
        tab.Name = tabOptions.Name or "Tab"
        tab.Icon = tabOptions.Icon or ""
        tab.Window = self

        local tabButton = create("TextButton", {
            AutoButtonColor = false,
            BackgroundColor3 = self.Theme.Surface2,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 38),
            Text = "",
            Parent = tabHolder
        })
        makeCorner(tabButton, 12)
        makeStroke(tabButton)
        addHover(tabButton, self.Theme.Surface2, self.Theme.AccentDark)
        addPress(tabButton, tabButton.Size, 2)

        local accentBar = create("Frame", {
            BackgroundColor3 = self.Theme.Accent,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 4, 1, -10),
            Position = UDim2.new(0, 6, 0, 5),
            Parent = tabButton
        })
        makeCorner(accentBar, 999)

        if tab.Icon ~= "" then
            create("ImageLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 16, 0, 16),
                Position = UDim2.new(0, 14, 0.5, -8),
                Image = tab.Icon,
                Parent = tabButton
            })
        end

        create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, tab.Icon ~= "" and -48 or -24, 1, 0),
            Position = UDim2.new(0, tab.Icon ~= "" and 36 or 14, 0, 0),
            Text = tab.Name,
            Font = Enum.Font.GothamMedium,
            TextSize = 12,
            TextColor3 = self.Theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = tabButton
        })

        local page = create("ScrollingFrame", {
            Active = true,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 1, 0),
            CanvasSize = UDim2.new(),
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = self.Theme.Accent,
            Visible = false,
            Parent = pageFolder
        })
        makePadding(page, 10, 10, 10, 10)

        local pageLayout = create("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = page
        })
        attachCanvas(pageLayout, page, 8)

        tab.Button = tabButton
        tab.Page = page
        tab.Layout = pageLayout
        tab.AccentBar = accentBar

        local function registerElement(element)
            animateObjectIn(element, {Y = 8, Time = 0.16})
            return element
        end

        function tab:AddSection(text)
            return registerElement(create("TextLabel", {
                BackgroundTransparency = 1,
                Text = tostring(text or "Section"),
                Font = Enum.Font.GothamBold,
                TextSize = 14,
                TextColor3 = self.Theme.Text,
                Size = UDim2.new(1, -2, 0, 20),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = page
            }))
        end

        function tab:AddParagraph(titleText, bodyText)
            local card = create("Frame", {
                BackgroundColor3 = self.Theme.Surface,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 68),
                AutomaticSize = Enum.AutomaticSize.Y,
                Parent = page
            })
            makeCorner(card, 12)
            makeStroke(card)
            makePadding(card, 12, 12, 10, 10)

            local titleLabel = create("TextLabel", {
                BackgroundTransparency = 1,
                Text = tostring(titleText or "Paragraph"),
                Font = Enum.Font.GothamBold,
                TextSize = 13,
                TextColor3 = self.Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, 0, 0, 16),
                Parent = card
            })

            local bodyLabel = create("TextLabel", {
                BackgroundTransparency = 1,
                Text = tostring(bodyText or "Text"),
                Font = Enum.Font.Gotham,
                TextWrapped = true,
                AutomaticSize = Enum.AutomaticSize.Y,
                TextSize = 12,
                TextColor3 = self.Theme.TextDim,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                Position = UDim2.new(0, 0, 0, 18),
                Size = UDim2.new(1, 0, 0, 16),
                Parent = card
            })

            registerElement(card)

            return {
                Set = function(_, newTitle, newBody)
                    if newTitle ~= nil then
                        titleLabel.Text = tostring(newTitle)
                    end
                    if newBody ~= nil then
                        bodyLabel.Text = tostring(newBody)
                    end
                end
            }
        end

        function tab:AddButton(buttonOptions)
            buttonOptions = buttonOptions or {}

            local button = create("TextButton", {
                AutoButtonColor = false,
                BackgroundColor3 = self.Theme.Surface,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 36),
                Text = "",
                Parent = page
            })
            makeCorner(button, 12)
            makeStroke(button)
            addHover(button, self.Theme.Surface, self.Theme.AccentDark)
            addPress(button, button.Size, 2)

            create("TextLabel", {
                BackgroundTransparency = 1,
                Text = buttonOptions.Name or "Button",
                Font = Enum.Font.GothamMedium,
                TextSize = 12,
                TextColor3 = self.Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, -22, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                Parent = button
            })

            button.MouseButton1Click:Connect(function()
                if buttonOptions.Callback then
                    task.spawn(buttonOptions.Callback)
                end
            end)

            registerElement(button)
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
                BackgroundColor3 = self.Theme.Surface,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 40),
                Text = "",
                Parent = page
            })
            makeCorner(holder, 12)
            makeStroke(holder)
            addHover(holder, self.Theme.Surface, self.Theme.Surface2)

            create("TextLabel", {
                BackgroundTransparency = 1,
                Text = toggleOptions.Name or "Toggle",
                Font = Enum.Font.GothamMedium,
                TextSize = 12,
                TextColor3 = self.Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, -70, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                Parent = holder
            })

            local switch = create("Frame", {
                BackgroundColor3 = value and self.Theme.Accent or self.Theme.Surface2,
                BorderSizePixel = 0,
                Size = UDim2.new(0, 40, 0, 20),
                Position = UDim2.new(1, -52, 0.5, -10),
                Parent = holder
            })
            makeCorner(switch, 999)
            makeStroke(switch)

            local knob = create("Frame", {
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                Size = UDim2.new(0, 14, 0, 14),
                Position = value and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7),
                Parent = switch
            })
            makeCorner(knob, 999)

            local function setToggle(newValue)
                value = newValue
                if flag then
                    Madalib.Flags[flag] = value
                end

                tween(switch, {
                    BackgroundColor3 = value and self.Theme.Accent or self.Theme.Surface2
                }, 0.14):Play()

                tween(knob, {
                    Position = value and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
                }, 0.14):Play()

                if toggleOptions.Callback then
                    task.spawn(function()
                        toggleOptions.Callback(value)
                    end)
                end
            end

            holder.MouseButton1Click:Connect(function()
                setToggle(not value)
            end)

            registerElement(holder)

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
                BackgroundColor3 = self.Theme.Surface,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 58),
                Parent = page
            })
            makeCorner(holder, 12)
            makeStroke(holder)
            makePadding(holder, 12, 12, 10, 10)

            create("TextLabel", {
                BackgroundTransparency = 1,
                Text = sliderOptions.Name or "Slider",
                Font = Enum.Font.GothamMedium,
                TextSize = 12,
                TextColor3 = self.Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, -68, 0, 14),
                Parent = holder
            })

            local valueLabel = create("TextLabel", {
                BackgroundTransparency = 1,
                Text = tostring(value) .. (sliderOptions.ValueName and (" " .. sliderOptions.ValueName) or ""),
                Font = Enum.Font.Gotham,
                TextSize = 11,
                TextColor3 = self.Theme.TextDim,
                TextXAlignment = Enum.TextXAlignment.Right,
                Size = UDim2.new(0, 68, 0, 14),
                Position = UDim2.new(1, -68, 0, 0),
                Parent = holder
            })

            local bar = create("Frame", {
                BackgroundColor3 = self.Theme.Surface2,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 6),
                Position = UDim2.new(0, 0, 0, 30),
                Parent = holder
            })
            makeCorner(bar, 999)

            local fill = create("Frame", {
                BackgroundColor3 = self.Theme.Accent,
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

                fill.Size = UDim2.new((value - min) / math.max(max - min, 1), 0, 1, 0)
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

            registerElement(holder)

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
                BackgroundColor3 = self.Theme.Surface,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 48),
                Parent = page
            })
            makeCorner(holder, 12)
            makeStroke(holder)
            makePadding(holder, 12, 12, 9, 9)

            create("TextLabel", {
                BackgroundTransparency = 1,
                Text = textboxOptions.Name or "Textbox",
                Font = Enum.Font.GothamMedium,
                TextSize = 12,
                TextColor3 = self.Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, 0, 0, 14),
                Parent = holder
            })

            local box = create("TextBox", {
                BackgroundColor3 = self.Theme.Surface2,
                BorderSizePixel = 0,
                ClearTextOnFocus = textboxOptions.ClearTextOnFocus == true,
                PlaceholderText = textboxOptions.PlaceholderText or "Type here",
                PlaceholderColor3 = self.Theme.TextDim,
                Text = value,
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextColor3 = self.Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, 0, 0, 20),
                Position = UDim2.new(0, 0, 0, 18),
                Parent = holder
            })
            makeCorner(box, 9)
            makeStroke(box)
            makePadding(box, 8, 8, 0, 0)

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

            box.FocusLost:Connect(function(enterPressed)
                if textboxOptions.EnterOnly then
                    if enterPressed then
                        commit()
                    end
                else
                    commit()
                end
            end)

            registerElement(holder)

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
                BackgroundColor3 = self.Theme.Surface,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 48),
                ClipsDescendants = true,
                Parent = page
            })
            makeCorner(holder, 12)
            makeStroke(holder)
            makePadding(holder, 12, 12, 9, 9)

            create("TextLabel", {
                BackgroundTransparency = 1,
                Text = dropdownOptions.Name or "Dropdown",
                Font = Enum.Font.GothamMedium,
                TextSize = 12,
                TextColor3 = self.Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, 0, 0, 14),
                Parent = holder
            })

            local mainButton = create("TextButton", {
                AutoButtonColor = false,
                BackgroundColor3 = self.Theme.Surface2,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 20),
                Position = UDim2.new(0, 0, 0, 18),
                Text = "",
                Parent = holder
            })
            makeCorner(mainButton, 9)
            makeStroke(mainButton)

            local chosen = create("TextLabel", {
                BackgroundTransparency = 1,
                Text = tostring(value),
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextColor3 = self.Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, -20, 1, 0),
                Position = UDim2.new(0, 8, 0, 0),
                Parent = mainButton
            })

            create("TextLabel", {
                BackgroundTransparency = 1,
                Text = "∨",
                Font = Enum.Font.GothamBold,
                TextSize = 10,
                TextColor3 = self.Theme.TextDim,
                TextXAlignment = Enum.TextXAlignment.Center,
                Size = UDim2.new(0, 18, 1, 0),
                Position = UDim2.new(1, -20, 0, 0),
                Parent = mainButton
            })

            local listFrame = create("Frame", {
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 0, 42),
                Size = UDim2.new(1, 0, 0, 0),
                Parent = holder
            })

            create("UIListLayout", {
                Padding = UDim.new(0, 4),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = listFrame
            })

            local opened = false

            local function collapse()
                opened = false
                tween(holder, {Size = UDim2.new(1, 0, 0, 48)}, 0.16):Play()
                tween(listFrame, {Size = UDim2.new(1, 0, 0, 0)}, 0.16):Play()
            end

            local function refreshOptions()
                for _, child in ipairs(listFrame:GetChildren()) do
                    if child:IsA("TextButton") then
                        child:Destroy()
                    end
                end

                for _, option in ipairs(optionsList) do
                    local item = create("TextButton", {
                        AutoButtonColor = false,
                        BackgroundColor3 = self.Theme.Surface2,
                        BorderSizePixel = 0,
                        Size = UDim2.new(1, 0, 0, 20),
                        Text = tostring(option),
                        Font = Enum.Font.Gotham,
                        TextSize = 12,
                        TextColor3 = self.Theme.Text,
                        Parent = listFrame
                    })
                    makeCorner(item, 9)
                    makeStroke(item)
                    addHover(item, self.Theme.Surface2, self.Theme.AccentDark)

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

                        collapse()
                    end)
                end
            end

            refreshOptions()

            local function expandedHeight()
                return 48 + (#optionsList * 24)
            end

            mainButton.MouseButton1Click:Connect(function()
                opened = not opened

                tween(holder, {Size = UDim2.new(1, 0, 0, opened and expandedHeight() or 48)}, 0.16):Play()
                tween(listFrame, {Size = UDim2.new(1, 0, 0, opened and (#optionsList * 24) or 0)}, 0.16):Play()
            end)

            registerElement(holder)

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
                    collapse()
                end,
                Value = function()
                    return value
                end
            }
        end

        tabButton.MouseButton1Click:Connect(function()
            window:SelectTab(tab)
        end)

        table.insert(self.Tabs, tab)

        if not self.CurrentTab then
            self:SelectTab(tab)
        end

        return tab
    end

    minimize.MouseButton1Click:Connect(function()
        minimized = not minimized
        tween(root, {
            Size = minimized and window.MinimizedSize or window.WindowSize
        }, 0.2):Play()
    end)

    close.MouseButton1Click:Connect(function()
        tween(main, {
            BackgroundTransparency = 1
        }, 0.16):Play()

        for _, child in ipairs(main:GetDescendants()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
                tween(child, {TextTransparency = 1}, 0.16):Play()
            elseif child:IsA("ImageLabel") or child:IsA("ImageButton") then
                tween(child, {ImageTransparency = 1}, 0.16):Play()
            elseif child:IsA("UIStroke") then
                tween(child, {Transparency = 1}, 0.16):Play()
            end
        end

        task.wait(0.18)
        screenGui:Destroy()
    end)

    table.insert(Madalib.Windows, window)

    if options.IntroEnabled == false then
        root.Size = window.WindowSize
    else
        root.Size = UDim2.new(0, window.WindowSize.X.Offset - 40, 0, window.WindowSize.Y.Offset - 28)
        root.Position = root.Position + UDim2.new(0, 0, 0, 12)
        main.BackgroundTransparency = 1

        tween(root, {
            Size = window.WindowSize,
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }, 0.22):Play()
        tween(main, {BackgroundTransparency = 0}, 0.22):Play()

        for _, child in ipairs(main:GetDescendants()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
                local original = child.TextTransparency
                child.TextTransparency = 1
                tween(child, {TextTransparency = original}, 0.22):Play()
            elseif child:IsA("ImageLabel") or child:IsA("ImageButton") then
                local original = child.ImageTransparency
                child.ImageTransparency = 1
                tween(child, {ImageTransparency = original}, 0.22):Play()
            elseif child:IsA("UIStroke") then
                local original = child.Transparency
                child.Transparency = 1
                tween(child, {Transparency = original}, 0.22):Play()
            end
        end
    end

    return window
end

return setmetatable(Madalib, Madalib)
