local Exodus = {}
Exodus.__index = Exodus

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local Theme = {
    Background = Color3.fromRGB(8, 8, 8),
    Panel = Color3.fromRGB(13, 13, 13),
    Elevated = Color3.fromRGB(19, 19, 19),
    Stroke = Color3.fromRGB(255, 255, 255),
    StrokeDim = Color3.fromRGB(55, 55, 55),
    Text = Color3.fromRGB(240, 240, 240),
    SubText = Color3.fromRGB(145, 145, 145),
    Accent = Color3.fromRGB(255, 255, 255),
    Off = Color3.fromRGB(30, 30, 30),
}

local ASSETS = {
    ChevronCollapsed = "rbxassetid://131324733048447",
    ChevronExpanded   = "rbxassetid://81019887641527",
    SectionIcon       = "rbxassetid://113179976918783",
    TabIcon           = "rbxassetid://86512767702085",
}

local function tween(obj, props, time, style, dir)
    local t = TweenService:Create(obj, TweenInfo.new(time or 0.25, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

local function create(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then
            inst[k] = v
        end
    end
    for _, child in ipairs(children or {}) do
        child.Parent = inst
    end
    if props and props.Parent then
        inst.Parent = props.Parent
    end
    return inst
end

local function stroke(parent, color, thickness, transparency)
    return create("UIStroke", {
        Parent = parent,
        Color = color or Theme.StrokeDim,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end

local function corner(parent, radius)
    return create("UICorner", { Parent = parent, CornerRadius = UDim.new(0, radius or 10) })
end

local function pad(parent, l, r, t, b)
    return create("UIPadding", {
        Parent = parent,
        PaddingLeft = UDim.new(0, l or 0),
        PaddingRight = UDim.new(0, r or l or 0),
        PaddingTop = UDim.new(0, t or 0),
        PaddingBottom = UDim.new(0, b or t or 0),
    })
end

local function vlist(parent, gap, hAlign)
    return create("UIListLayout", {
        Parent = parent,
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, gap or 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Left,
    })
end

local function ripple(button, mouseX, mouseY)
    local abs = button.AbsoluteSize
    local pos = button.AbsolutePosition
    local circle = create("Frame", {
        Parent = button,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.85,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromOffset(mouseX - pos.X, mouseY - pos.Y),
        Size = UDim2.fromOffset(0, 0),
        ZIndex = 50,
    })
    corner(circle, 999)
    local size = math.max(abs.X, abs.Y) * 1.8
    tween(circle, { Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1 }, 0.5, Enum.EasingStyle.Quad)
    task.delay(0.5, function()
        circle:Destroy()
    end)
end

local function getAvatar(userId)
    local ok, content = pcall(function()
        return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    end)
    if ok then
        return content
    end
    return "rbxthumb://type=AvatarHeadShot&id=" .. tostring(userId) .. "&w=100&h=100"
end

local function twoColGroup(parent, gap)
    local Row = create("Frame", {
        Parent = parent,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
    })
    create("UIListLayout", {
        Parent = Row,
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, gap),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    local ColA = create("Frame", {
        Parent = Row,
        BackgroundTransparency = 1,
        Size = UDim2.new(0.5, -gap / 2, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
    })
    vlist(ColA, gap)
    local ColB = create("Frame", {
        Parent = Row,
        BackgroundTransparency = 1,
        Size = UDim2.new(0.5, -gap / 2, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
    })
    vlist(ColB, gap)
    local count = 0
    local function nextColumn()
        count += 1
        if count % 2 == 1 then
            return ColA
        else
            return ColB
        end
    end
    return Row, nextColumn
end

local function round3(c)
    return Color3.fromRGB(math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end

local function toHex(c)
    c = round3(c)
    return string.format("%02X%02X%02X", c.R * 255, c.G * 255, c.B * 255)
end

local function getContrastColor(bg)
    local lum = 0.299 * bg.R + 0.587 * bg.G + 0.114 * bg.B
    return lum > 0.5 and Color3.fromRGB(0,0,0) or Color3.fromRGB(255,255,255)
end

function Exodus:Init(config)
    config = config or {}

    local WindowName = config.Name or "EXODUS"
    local Handle = config.Handle or ("@" .. LocalPlayer.Name)
    local Keybind = config.Keybind or Enum.KeyCode.LeftAlt
    if typeof(Keybind) == "string" then
        Keybind = Enum.KeyCode[Keybind] or Enum.KeyCode.LeftAlt
    end
    local Highlight = config.Highlight or Theme.Accent
    local IconSize = config.IconSize or 34
    local LogoId = config.Logo

    local ScreenGui = create("ScreenGui", {
        Name = "ExodusUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = CoreGui,
    })

    local baseWidth, baseHeight = 700, 500
    local minWidth, minHeight = 560, 400

    local Main = create("Frame", {
        Name = "Main",
        Parent = ScreenGui,
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, -baseWidth / 2, 0.5, -baseHeight / 2),
        Size = UDim2.fromOffset(baseWidth, baseHeight),
        ClipsDescendants = true,
    })
    corner(Main, 12)
    stroke(Main, Theme.StrokeDim, 1)


    local MainScale = create("UIScale", { Parent = Main, Scale = 1 })
 
    create("UIGradient", {
        Parent = Main,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(19, 19, 19)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(6, 6, 6)),
        }),
        Rotation = 90,
    })

    local sidebarWidth = 210

    local Sidebar = create("Frame", {
        Name = "Sidebar",
        Parent = Main,
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        Size = UDim2.new(0, sidebarWidth, 1, 0),
    })

    corner(Sidebar, 12)
    
    create("Frame", {
        Parent = Sidebar,
        BackgroundColor3 = Theme.StrokeDim,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -1, 0, 0),
        Size = UDim2.new(0, 1, 1, 0),
    })

    -- Sidebar header – both text and avatar are vertically centered
    local SidebarHeader = create("Frame", {
        Parent = Sidebar,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 56),
    })

    -- Text group (window name + handle) – vertically centered using UIListLayout
    local TextGroup = create("Frame", {
        Parent = SidebarHeader,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -(IconSize + 24), 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
    })
    local textLayout = create("UIListLayout", {
        Parent = TextGroup,
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Center,
    })
    create("TextLabel", {
        Parent = TextGroup,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        Font = Enum.Font.GothamBold,
        Text = WindowName,
        TextColor3 = Theme.Text,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    create("TextLabel", {
        Parent = TextGroup,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 14),
        Font = Enum.Font.Gotham,
        Text = Handle,
        TextColor3 = Theme.SubText,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Visible = Handle ~= "",
    })

    -- Avatar on the right, vertically centered
    local Avatar = create("ImageLabel", {
        Parent = SidebarHeader,
        BackgroundColor3 = Theme.Off,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(IconSize, IconSize),
        Image = LogoId or getAvatar(LocalPlayer.UserId),
    })
    corner(Avatar, 9)
    stroke(Avatar, Theme.StrokeDim, 1)

    create("Frame", {
        Parent = Sidebar,
        BackgroundColor3 = Theme.StrokeDim,
        BorderSizePixel = 0,
        Transparency = 0.5,
        Position = UDim2.new(0, 0, 0, 56),
        Size = UDim2.new(1, 0, 0, 1),
    })

    local SearchHolder = create("Frame", {
        Parent = Sidebar,
        BackgroundColor3 = Theme.Elevated,
        Position = UDim2.new(0, 10, 0, 68),
        Size = UDim2.new(1, -20, 0, 30),
    })
    corner(SearchHolder, 8)

    local SearchIcon = create("ImageLabel", {
        Parent = SearchHolder,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 8, 0.5, 0),
        Size = UDim2.fromOffset(16, 16),
        Image = "rbxassetid://121018724060431",
        ImageColor3 = Theme.SubText,
    })
    local searchStroke = stroke(SearchHolder, Theme.StrokeDim, 1, 0.3)

    local SearchBox = create("TextBox", {
        Parent = SearchHolder,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 30, 0, 0),
        Size = UDim2.new(1, -34, 1, 0),
        Font = Enum.Font.Gotham,
        PlaceholderText = "Search...",
        PlaceholderColor3 = Theme.SubText,
        Text = "",
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
    })

    SearchBox.Focused:Connect(function()
        tween(searchStroke, { Color = Highlight, Transparency = 0 }, 0.2)
    end)
    SearchBox.FocusLost:Connect(function()
        tween(searchStroke, { Color = Theme.StrokeDim, Transparency = 0.3 }, 0.2)
    end)

    local CategoryList = create("ScrollingFrame", {
        Name = "CategoryList",
        Parent = Sidebar,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 8, 0, 108),
        Size = UDim2.new(1, -16, 1, -116),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.StrokeDim,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    })
    pad(CategoryList, 4, 12, 2, 2)
    vlist(CategoryList, 6)

    local ContentHolder = create("Frame", {
        Name = "ContentHolder",
        Parent = Main,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, sidebarWidth, 0, 0),
        Size = UDim2.new(1, -sidebarWidth, 1, 0),
    })

    local ContentHeader = create("Frame", {
        Parent = ContentHolder,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 56),
    })
    pad(ContentHeader, 18, 18, 0, 0)
    
    -- Container to vertically center the header title and description
    local HeaderTextContainer = create("Frame", {
        Parent = ContentHeader,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
    })
    local headerLayout = create("UIListLayout", {
        Parent = HeaderTextContainer,
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Center,
    })
    local HeaderTitle = create("TextLabel", {
        Parent = HeaderTextContainer,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        Font = Enum.Font.GothamBold,
        Text = "",
        TextColor3 = Theme.Text,
        TextSize = 17,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 1,
    })
    local HeaderDesc = create("TextLabel", {
        Parent = HeaderTextContainer,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 14),
        Font = Enum.Font.Gotham,
        Text = "",
        TextColor3 = Theme.SubText,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Visible = false,
        LayoutOrder = 2,
    })

    -- Game ID tag label – top-right, vertically centered, rounded, white background
    local GameIDTag = create("TextLabel", {
        Parent = ContentHeader,
        BackgroundColor3 = Highlight,
        BackgroundTransparency = 0.15,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0, 0, 0, 24),
        AutomaticSize = Enum.AutomaticSize.X,
        Font = Enum.Font.Gotham,
        Text = tostring(game.GameId),
        TextColor3 = getContrastColor(Highlight), -- black or white for readability
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        ClipsDescendants = true,
        ZIndex = 10,
    })
    corner(GameIDTag, 6)
    pad(GameIDTag, 10, 10, 4, 4)  -- left/right 10, top/bottom 4
        
    create("Frame", {
        Parent = ContentHolder,
        BackgroundColor3 = Theme.StrokeDim,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 56),
        Size = UDim2.new(1, 0, 0, 1),
    })

    local PageHolder = create("Frame", {
        Parent = ContentHolder,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 56),
        Size = UDim2.new(1, 0, 1, -56),
        ClipsDescendants = true,   -- add this
    })

    pad(PageHolder, 0, 0, 10, 10) -- bottom padding 18px, match top 18 from PageInner
    
    -- Resize handles (no cursor changes – just drag logic)
    local function makeResizeHandle(parent, anchor, position, size)
        return create("Frame", {
            Parent = parent,
            BackgroundTransparency = 1,
            AnchorPoint = anchor,
            Position = position,
            Size = size,
            ZIndex = 20,
        })
    end

    local bottomHandle = makeResizeHandle(Main, Vector2.new(0.5, 1), UDim2.new(0.5, 0, 1, 0), UDim2.new(1, -20, 0, 6))
    local rightHandle = makeResizeHandle(Main, Vector2.new(1, 0.5), UDim2.new(1, 0, 0.5, 0), UDim2.new(0, 6, 1, -20))
    local ResizeGrip = create("Frame", {
        Parent = Main,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, 0, 1, 0),
        Size = UDim2.fromOffset(18, 18),
        ZIndex = 20,
    })
    create("TextLabel", {
        Parent = ResizeGrip,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Font = Enum.Font.GothamBold,
        Text = "⌟",
        TextColor3 = Theme.SubText,
        TextTransparency = 1,
        TextSize = 16,
    })

    local dragging, dragStart, startPos = false, nil, nil
    local resizing, resizeStart, startSize, resizeType = false, nil, nil, nil

    SidebarHeader.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = Main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    local function startResize(input, type)
        resizing = true
        resizeStart = input.Position
        startSize = Main.Size
        resizeType = type
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                resizing = false
                resizeType = nil
            end
        end)
    end

    bottomHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            startResize(input, "bottom")
        end
    end)
    rightHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            startResize(input, "right")
        end
    end)
    ResizeGrip.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            startResize(input, "corner")
        end
    end)

    ContentHeader.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = Main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                local delta = input.Position - dragStart
                Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            elseif resizing then
                local delta = input.Position - resizeStart
                local newW, newH = startSize.X.Offset, startSize.Y.Offset
                if resizeType == "bottom" or resizeType == "corner" then
                    newH = math.max(minHeight, startSize.Y.Offset + delta.Y)
                end
                if resizeType == "right" or resizeType == "corner" then
                    newW = math.max(minWidth, startSize.X.Offset + delta.X)
                end
                Main.Size = UDim2.fromOffset(newW, newH)
            end
        end
    end)

    local openDropdowns = {}
    local function closeAllDropdowns(exclude)
        for _, dd in ipairs(openDropdowns) do
            if dd ~= exclude then
                dd()
            end
        end
    end

    local DropdownBlocker = create("TextButton", {
        Parent = ScreenGui,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Text = "",
        ZIndex = 50,
        Visible = false,
        AutoButtonColor = false,
    })
    DropdownBlocker.MouseButton1Click:Connect(function()
        closeAllDropdowns()
        DropdownBlocker.Visible = false
    end)

    local minimized = false

    local function setMinimized(state)
        minimized = state
        if state then
            Main.Visible = false
            closeAllDropdowns() -- Automatically closes dropdowns and color pickers on minimize
            DropdownBlocker.Visible = false
        else
            Main.Visible = true
            MainScale.Scale = 1
        end
    end

    UIS.InputBegan:Connect(function(input, processed)
        if input.KeyCode == Keybind then
            setMinimized(not minimized)
        end
    end)
    
    local Window = {}
    Window._searchIndex = {}
    Window._tabs = {}
    Window._activeTab = nil
    local firstTabEver = true

    local function applySearch(query)
        query = query:lower()
        local activePage = Window._activeTab   -- the currently visible tab's ScrollingFrame
    
        -- 1. Toggle visibility of each individual frame
        for _, entry in ipairs(Window._searchIndex) do
            local visible = true
            if query ~= "" then
                -- Only consider entries that belong to the active tab AND match the query
                if entry.tabPage == activePage then
                    visible = entry.text:lower():find(query, 1, true) ~= nil
                else
                    visible = false   -- hide entries from other tabs
                end
            else
                -- When search is cleared, show only entries from the active tab
                visible = (entry.tabPage == activePage)
            end
            entry.frame.Visible = visible
        end
    
        -- 2. Hide sections that have no visible entries (to keep layout clean)
        for _, tabData in ipairs(Window._tabs) do
            for _, sec in ipairs(tabData.sections) do
                local anyVisible = false
                for _, entry in ipairs(sec.entries) do
                    if entry.frame.Visible then
                        anyVisible = true
                        break
                    end
                end
                sec.frame.Visible = anyVisible
            end
        end
    end

    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        applySearch(SearchBox.Text)
    end)

    function Window:Category(catOpts)
        catOpts = catOpts or {}
        local catName = catOpts.Name or "Category"
        local catIcon = catOpts.Icon

        local CategoryButton = create("TextButton", {
            Parent = CategoryList,
            BackgroundTransparency = 1,
            AutoButtonColor = false,
            Size = UDim2.new(1, 0, 0, 30),
            Text = "",
        })

        local CatIcon = create("ImageLabel", {
            Parent = CategoryButton,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 4, 0.5, -8),
            Size = UDim2.fromOffset(16, 16),
            Image = catIcon or "",
            ImageColor3 = Theme.SubText,
            Visible = catIcon ~= nil,
        })

        create("TextLabel", {
            Parent = CategoryButton,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, catIcon and 26 or 4, 0, 0),
            Size = UDim2.new(1, -40, 1, 0),
            Font = Enum.Font.GothamBold,
            Text = catName,
            TextColor3 = Theme.SubText,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
        })

        local Chevron = create("ImageLabel", {
            Parent = CategoryButton,
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -4, 0.5, 0),
            Size = UDim2.fromOffset(16, 16),
            Image = ASSETS.ChevronCollapsed,
            ImageColor3 = Theme.SubText,
        })

        local SubList = create("Frame", {
            Parent = CategoryList,
            BackgroundTransparency = 1,
            ClipsDescendants = true,
            Size = UDim2.new(1, 0, 0, 0),
        })

        local SubInner = create("Frame", {
            Parent = SubList,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
        })
        pad(SubInner, 6, 0, 2, 2)
        vlist(SubInner, 3)

        local expanded = false

        local function refreshHeight()
            if expanded then
                tween(SubList, { Size = UDim2.new(1, 0, 0, SubInner.AbsoluteSize.Y) }, 0.22)
            end
        end
        SubInner:GetPropertyChangedSignal("AbsoluteSize"):Connect(refreshHeight)

        local function setExpanded(state)
            expanded = state
            Chevron.Image = state and ASSETS.ChevronExpanded or ASSETS.ChevronCollapsed
            if state then
                tween(SubList, { Size = UDim2.new(1, 0, 0, SubInner.AbsoluteSize.Y) }, 0.22)
            else
                tween(SubList, { Size = UDim2.new(1, 0, 0, 0) }, 0.22)
            end
        end

        CategoryButton.MouseButton1Click:Connect(function()
            setExpanded(not expanded)
        end)
        CategoryButton.MouseEnter:Connect(function()
            tween(CategoryButton, { BackgroundTransparency = 0.95 }, 0.15)
        end)
        CategoryButton.MouseLeave:Connect(function()
            tween(CategoryButton, { BackgroundTransparency = 1 }, 0.15)
        end)
        CategoryButton.BackgroundColor3 = Theme.Elevated

        local CategoryAPI = {}

        function CategoryAPI:Tab(tabOpts)
            tabOpts = tabOpts or {}
            local tabName = tabOpts.Name or "Tab"
            local tabDesc = tabOpts.Description or ""

            local TabButton = create("TextButton", {
                Parent = SubInner,
                BackgroundTransparency = 1,
                AutoButtonColor = false,
                Size = UDim2.new(1, 0, 0, 26),
                Text = "",
            })
            corner(TabButton, 7)

            local TabIconImage = create("ImageLabel", {
                Parent = TabButton,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 8, 0.5, -7),
                Size = UDim2.fromOffset(14, 14),
                Image = ASSETS.TabIcon,
                ImageColor3 = Theme.SubText,
            })

            local TabLabel = create("TextLabel", {
                Parent = TabButton,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 28, 0, 0),
                Size = UDim2.new(1, -34, 1, 0),
                Font = Enum.Font.GothamMedium,
                Text = tabName,
                TextColor3 = Theme.SubText,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
            })

            local Page = create("ScrollingFrame", {
                Parent = PageHolder,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.fromScale(1, 1),
                ScrollBarThickness = 3,
                ScrollBarImageColor3 = Theme.StrokeDim,
                CanvasSize = UDim2.new(0, 0, 0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                Visible = false,
            })

            local PageInner = create("Frame", {
                Parent = Page,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 18, 0, 14),
                Size = UDim2.new(1, -36, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
            })
            vlist(PageInner, 0)

            local PageRow, nextPageColumn = twoColGroup(PageInner, 14)

            create("Frame", {
                Parent = PageInner,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 6),
            })

            local tabData = { sections = {}, name = tabName, page = Page, button = TabButton, label = TabLabel, tabIcon = TabIconImage }
            table.insert(Window._tabs, tabData)

            local function selectTab()
                -- Close any open dropdowns
                closeAllDropdowns()
                DropdownBlocker.Visible = false

                --[[ Resets active layout query elements when tabs switch. Clear automatic.
                if SearchBox.Text ~= "" then
                    SearchBox.Text = ""
                end
                --]]

                -- Hide all pages (direct children of PageHolder)
                for _, child in ipairs(PageHolder:GetChildren()) do
                    if child:IsA("ScrollingFrame") then
                        child.Visible = false
                    end
                end
               
                -- Hide all pages and reset all tabs
                for _, t in ipairs(Window._tabs) do
                    if t.page then
                        t.page.Visible = false
                    end
                    if t.button then
                        t.button.BackgroundColor3 = Theme.Off
                        t.button.BackgroundTransparency = 1
                        t.label.TextColor3 = Theme.SubText
                        t.tabIcon.ImageColor3 = Theme.SubText
                    end
                end

                -- Show this page and highlight this tab
                Page.Visible = true
                Window._activeTab = Page
                applySearch(SearchBox.Text)
                tween(TabButton, { BackgroundColor3 = Highlight, BackgroundTransparency = 0 }, 0.2)
                local contrast = getContrastColor(Highlight)
                tween(TabLabel, { TextColor3 = contrast }, 0.2)
                tween(TabIconImage, { ImageColor3 = contrast }, 0.2)
                HeaderTitle.Text = tabName
                HeaderDesc.Text = tabDesc
                HeaderDesc.Visible = tabDesc ~= ""
                if not expanded then
                    setExpanded(true)
                end
            end
--[[
            tabData.page = Page
            tabData.button = TabButton
            tabData.label = TabLabel
            tabData.tabIcon = TabIconImage
--]]
            TabButton.MouseButton1Click:Connect(selectTab)
            TabButton.MouseEnter:Connect(function()
                if Page.Visible then return end
                tween(TabButton, { BackgroundTransparency = 0.9 }, 0.15)
            end)
            TabButton.MouseLeave:Connect(function()
                if Page.Visible then return end
                tween(TabButton, { BackgroundTransparency = 1 }, 0.15)
            end)

            if firstTabEver then
                firstTabEver = false
                setExpanded(true)
                selectTab()
            end

            local TabAPI = {}

            function TabAPI:Section(sectionOpts)
                sectionOpts = sectionOpts or {}
                local sectionName = sectionOpts.Name or "Section"
                local sectionIcon = sectionOpts.Icon or ASSETS.SectionIcon

                local parentColumn = nextPageColumn()

                local SectionFrame = create("Frame", {
                    Parent = parentColumn,
                    BackgroundColor3 = Theme.Panel,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                })
                corner(SectionFrame, 10)
                stroke(SectionFrame, Theme.StrokeDim, 1, 0.2)
                pad(SectionFrame, 14, 14, 12, 14)
                vlist(SectionFrame, 12)

                local TitleRow = create("Frame", {
                    Parent = SectionFrame,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 16),
                    LayoutOrder = 1,
                })

                create("ImageLabel", {
                    Parent = TitleRow,
                    BackgroundTransparency = 1,
                    Size = UDim2.fromOffset(14, 14),
                    Image = sectionIcon,
                    ImageColor3 = Theme.SubText,
                })

                create("TextLabel", {
                    Parent = TitleRow,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 20, 0, 0),
                    Size = UDim2.new(1, -20, 1, 0),
                    Font = Enum.Font.GothamBold,
                    Text = sectionName,
                    TextColor3 = Theme.Text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })

                create("Frame", {
                    Parent = SectionFrame,
                    BackgroundColor3 = Theme.StrokeDim,
                    BackgroundTransparency = 0.5,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 1),
                    LayoutOrder = 2,
                })

                local RowHolder = create("Frame", {
                    Parent = SectionFrame,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    LayoutOrder = 3,
                })
                vlist(RowHolder, 10)

                local sectionData = { frame = SectionFrame, entries = {} }
                table.insert(tabData.sections, sectionData)

                local SectionAPI = {}

                local function registerSearch(frame, text)
                    table.insert(Window._searchIndex, { 
                        frame = frame, 
                        text = text, 
                        originalParent = frame.Parent,
                        tabPage = Page   -- ← add this line
                    })
                    table.insert(sectionData.entries, { frame = frame, text = text })
                end

                local function newRow(height)
                    return create("Frame", {
                        Parent = RowHolder,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, height or 26),
                    })
                end

                -- Dropdown with persistent highlighting and better visibility
                local function styledDropdownList(Row, options, isMulti, callback)
                    local Selector = create("TextButton", {
                        Parent = Row,
                        BackgroundColor3 = Theme.Off,
                        BackgroundTransparency = 0.15,
                        AutoButtonColor = false,
                        Size = UDim2.new(1, 0, 0, 22),   -- full width, height 22
                        Font = Enum.Font.Gotham,
                        Text = isMulti and "None" or "Select",
                        TextColor3 = Theme.Text,
                        TextSize = 11,
                        ClipsDescendants = true,
                    })
                    local DropdownIcon = create("ImageLabel", {
                        Parent = Selector,
                        BackgroundTransparency = 1,
                        AnchorPoint = Vector2.new(1, 0.5),
                        Position = UDim2.new(1, 2, 0.5, 0),
                        Size = UDim2.fromOffset(14, 14),
                        Image = "rbxassetid://131833120209646",
                        ImageColor3 = Theme.SubText,
                    })
                    corner(Selector, 6)
                    stroke(Selector, Theme.StrokeDim, 1, 0.4)
                    Selector.TextXAlignment = Enum.TextXAlignment.Left
                    pad(Selector, 8, 8, 0, 0)

                    local ListFrame = create("ScrollingFrame", {
                        Parent = ScreenGui,
                        BackgroundColor3 = Theme.Elevated,
                        BorderSizePixel = 0,
                        Size = UDim2.new(0, 140, 0, 0),
                        ClipsDescendants = true,
                        ZIndex = 100,
                        Visible = false,
                        ScrollBarThickness = 3,
                        ScrollBarImageColor3 = Theme.StrokeDim,
                        CanvasSize = UDim2.new(0, 0, 0, 0),
                        AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    })
                    corner(ListFrame, 6)
                    stroke(ListFrame, Theme.StrokeDim, 1)
                    vlist(ListFrame, 2)
                    pad(ListFrame, 4, 4, 4, 4)

                    local open = false
                    local optionButtons = {}
                    local selected = {}
                    local selectedSingle = nil

                    local function close()
                        open = false
                        ListFrame.Visible = false
                        DropdownBlocker.Visible = false
                        for i, dd in ipairs(openDropdowns) do
                            if dd == close then
                                table.remove(openDropdowns, i)
                                break
                            end
                        end
                    end

                    local function openList()
                        closeAllDropdowns(close)
                        open = true
                        ListFrame.Visible = true
                        DropdownBlocker.Visible = true
                        
                        local selPos = Selector.AbsolutePosition
                        local selSize = Selector.AbsoluteSize
                        local screenSize = ScreenGui.AbsoluteSize
                        
                        local maxHeight = 200
                        local itemHeight = 24  -- each option: button height 22 + padding 2
                        local listWidth = selSize.X
                        local actualHeight = math.min(#options * itemHeight + 8, maxHeight)  -- +8 for padding
                        
                        ListFrame.Size = UDim2.new(0, listWidth, 0, actualHeight)
                                        
                        local x = math.clamp(selPos.X, 4, screenSize.X - listWidth - 4)
                        local y = math.clamp(selPos.Y + selSize.Y + 2, 4, screenSize.Y - actualHeight - 4)
                        
                        ListFrame.Position = UDim2.fromOffset(x, y)
                        table.insert(openDropdowns, close)
                    
                        -- Refresh highlight states on open
                        for i, optName in ipairs(options) do
                            local btn = optionButtons[optName]
                            local isSelected = isMulti and selected[optName] or (optName == selectedSingle)
                            if isSelected then
                                btn.BackgroundTransparency = 0.5
                                btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
                                btn.TextColor3 = Theme.Text
                            else
                                btn.BackgroundTransparency = 1
                                btn.BackgroundColor3 = Highlight
                                btn.TextColor3 = Theme.SubText
                            end
                        end
                    end

                    local function refreshLabel()
                        if isMulti then
                            local count = 0
                            for _, v in pairs(selected) do
                                if v then count += 1 end
                            end
                            Selector.Text = count == 0 and "None" or (count .. " selected")
                        end
                    end

                    for i, optName in ipairs(options) do
                        local OptBtn = create("TextButton", {
                            Parent = ListFrame,
                            BackgroundColor3 = Highlight,
                            BackgroundTransparency = 1,
                            AutoButtonColor = false,
                            Size = UDim2.new(1, 0, 0, 22),
                            Font = Enum.Font.Gotham,
                            Text = "  " .. optName,
                            TextColor3 = Theme.SubText,
                            TextSize = 12,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            LayoutOrder = i,
                        })
                        corner(OptBtn, 5)
                        optionButtons[optName] = OptBtn

                        OptBtn.MouseEnter:Connect(function()
                            if not (isMulti and selected[optName]) and optName ~= selectedSingle then
                                tween(OptBtn, { BackgroundTransparency = 0.85 }, 0.15)
                            end
                        end)
                        OptBtn.MouseLeave:Connect(function()
                            if not (isMulti and selected[optName]) and optName ~= selectedSingle then
                                tween(OptBtn, { BackgroundTransparency = 1 }, 0.15)
                            end
                        end)

                        OptBtn.MouseButton1Click:Connect(function()
                            if isMulti then
                                if selected[optName] then
                                    selected[optName] = nil
                                    tween(OptBtn, { BackgroundTransparency = 1, BackgroundColor3 = Highlight, TextColor3 = Theme.SubText }, 0.15)
                                else
                                    selected[optName] = true
                                    tween(OptBtn, { BackgroundTransparency = 0.5, BackgroundColor3 = Color3.fromRGB(60,60,60), TextColor3 = Theme.Text }, 0.15)
                                end
                                refreshLabel()
                                local list = {}
                                for _, n in ipairs(options) do
                                    if selected[n] then
                                        table.insert(list, n)
                                    end
                                end
                                task.spawn(callback, list)
                            else
                                -- Single select
                                if selectedSingle then
                                    local old = optionButtons[selectedSingle]
                                    if old then
                                        tween(old, { BackgroundTransparency = 1, BackgroundColor3 = Highlight, TextColor3 = Theme.SubText }, 0.15)
                                    end
                                end
                                selectedSingle = optName
                                tween(OptBtn, { BackgroundTransparency = 0.5, BackgroundColor3 = Color3.fromRGB(60,60,60), TextColor3 = Theme.Text }, 0.15)
                                Selector.Text = optName
                                close()
                                task.spawn(callback, optName)
                            end
                        end)
                    end

                    Selector.MouseButton1Click:Connect(function()
                        if open then
                            close()
                        else
                            openList()
                        end
                    end)

                    return Selector, close
                end

                function SectionAPI:Button(o)
                    o = o or {}
                    local label = o.Name or "Button"
                    local callback = o.Callback or function() end
                    local align = o.Alignment or "Center"   -- "Center" by default, can be "Left"
                
                    local Row = newRow(30)
                    local Btn = create("TextButton", {
                        Parent = Row,
                        BackgroundTransparency = 1,
                        AutoButtonColor = false,
                        Size = UDim2.fromScale(1, 1),
                        Text = "",
                        ClipsDescendants = true,
                    })
                    corner(Btn, 8)
                    local btnStroke = stroke(Btn, Theme.StrokeDim, 1, 0.55)
                
                    -- Choose alignment settings
                    local textAlign = (align == "Left") and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center
                    local labelPosition = (align == "Left") and UDim2.new(0, 10, 0, 0) or UDim2.new(0, 0, 0, 0)
                    local labelSize = (align == "Left") and UDim2.new(1, -20, 1, 0) or UDim2.new(1, 0, 1, 0)
                
                    create("TextLabel", {
                        Parent = Btn,
                        BackgroundTransparency = 1,
                        Position = labelPosition,
                        Size = labelSize,
                        Font = Enum.Font.GothamMedium,
                        Text = label,
                        TextColor3 = Theme.Text,
                        TextSize = 13,
                        TextXAlignment = textAlign,
                    })
                
                    Btn.MouseEnter:Connect(function()
                        tween(Btn, { BackgroundTransparency = 0.92 }, 0.15)
                        tween(btnStroke, { Transparency = 0.1 }, 0.15)
                    end)
                    Btn.MouseLeave:Connect(function()
                        tween(Btn, { BackgroundTransparency = 1 }, 0.15)
                        tween(btnStroke, { Transparency = 0.55 }, 0.15)
                    end)
                    Btn.MouseButton1Down:Connect(function(x, y)
                        ripple(Btn, x, y)
                    end)
                    Btn.MouseButton1Click:Connect(function()
                        task.spawn(callback)
                    end)
                
                    registerSearch(Row, label)
                    return { Row = Row }
                end

                function SectionAPI:Toggle(o)
                    o = o or {}
                    local label = o.Name or "Toggle"
                    local default = o.Default or false
                    local callback = o.Callback or function() end
                    local state = default

                    local Row = newRow(24)
                    local Label = create("TextLabel", {
                        Parent = Row,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, -50, 1, 0),
                        Font = Enum.Font.GothamMedium,
                        Text = label,
                        TextColor3 = state and Theme.Text or Theme.SubText,
                        TextSize = 13,
                        TextXAlignment = Enum.TextXAlignment.Left,
                    })

                    local SwitchBG = create("Frame", {
                        Parent = Row,
                        BackgroundColor3 = state and Highlight or Theme.Off,
                        AnchorPoint = Vector2.new(1, 0.5),
                        Position = UDim2.new(1, 0, 0.5, 0),
                        Size = UDim2.fromOffset(30, 16),
                    })
                    corner(SwitchBG, 999)
                    stroke(SwitchBG, Theme.StrokeDim, 1, 0.3)

                    local Knob = create("Frame", {
                        Parent = SwitchBG,
                        BackgroundColor3 = Color3.fromRGB(15, 15, 15),
                        Position = state and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6),
                        Size = UDim2.fromOffset(12, 12),
                    })
                    corner(Knob, 999)

                    local Click = create("TextButton", {
                        Parent = Row,
                        BackgroundTransparency = 1,
                        Size = UDim2.fromScale(1, 1),
                        Text = "",
                    })

                    local function render()
                        tween(SwitchBG, { BackgroundColor3 = state and Highlight or Theme.Off }, 0.2)
                        tween(Knob, { Position = state and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6) }, 0.2, Enum.EasingStyle.Back)
                        tween(Label, { TextColor3 = state and Theme.Text or Theme.SubText }, 0.2)
                    end

                    Click.MouseButton1Click:Connect(function()
                        state = not state
                        render()
                        task.spawn(callback, state)
                    end)

                    registerSearch(Row, label)
                    return {
                        Row = Row,
                        Set = function(v)
                            state = v
                            render()
                        end,
                    }
                end

                function SectionAPI:Input(o)
                    o = o or {}
                    local label = o.Name or "Input"
                    local placeholder = o.Placeholder or "..."
                    local callback = o.Callback or function() end
                
                    local Row = create("Frame", {
                        Parent = RowHolder,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 0),
                        AutomaticSize = Enum.AutomaticSize.Y,
                    })
                    vlist(Row, 8)  -- vertical layout with 4px gap
                
                    create("TextLabel", {
                        Parent = Row,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 14),
                        Font = Enum.Font.GothamMedium,
                        Text = label,
                        TextColor3 = Theme.SubText,
                        TextSize = 11,
                        TextXAlignment = Enum.TextXAlignment.Left,
                    })
                
                    local InputBG = create("Frame", {
                        Parent = Row,
                        BackgroundColor3 = Theme.Off,
                        BackgroundTransparency = 0.2,
                        Size = UDim2.new(1, 0, 0, 22),
                    })
                    corner(InputBG, 6)
                    local inputStroke = stroke(InputBG, Theme.StrokeDim, 1, 0.4)
                
                    local Box = create("TextBox", {
                        Parent = InputBG,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 1, 0),
                        Font = Enum.Font.Gotham,
                        PlaceholderText = placeholder,
                        PlaceholderColor3 = Theme.SubText,
                        Text = "",
                        TextColor3 = Theme.Text,
                        TextSize = 12,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        TextYAlignment = Enum.TextYAlignment.Center,
                        ClearTextOnFocus = false,
                        ClipsDescendants = true,
                    })

                    Box.Focused:Connect(function()
                        tween(inputStroke, { Color = Highlight, Transparency = 0 }, 0.2)
                    end)
                    Box.FocusLost:Connect(function()
                        tween(inputStroke, { Color = Theme.StrokeDim, Transparency = 0.4 }, 0.2)
                        task.spawn(callback, Box.Text)
                    end)

                    registerSearch(Row, label)
                    return { Row = Row, Box = Box }
                end

                function SectionAPI:Slider(o)
                    o = o or {}
                    local label = o.Name or "Slider"
                    local min = o.Min or 0
                    local max = o.Max or 100
                    local decimals = o.Decimals or 0 -- Number of decimal points allowed
                    local default = math.clamp(o.Default or min, min, max)
                    local callback = o.Callback or function() end
                    local value = default
                
                    local Row = newRow(34)
                    create("TextLabel", {
                        Parent = Row,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(0.6, 0, 0, 13),
                        Font = Enum.Font.GothamMedium,
                        Text = label,
                        TextColor3 = Theme.SubText,
                        TextSize = 11,
                        TextXAlignment = Enum.TextXAlignment.Left,
                    })
                    
                    local ValueLabel = create("TextLabel", {
                        Parent = Row,
                        BackgroundTransparency = 1,
                        AnchorPoint = Vector2.new(1, 0),
                        Position = UDim2.new(1, 0, 0, 0),
                        Size = UDim2.new(0, 70, 0, 13),
                        Font = Enum.Font.GothamBold,
                        Text = string.format("%." .. decimals .. "f", value) .. " / " .. max,
                        TextColor3 = Theme.Text,
                        TextSize = 11,
                        TextXAlignment = Enum.TextXAlignment.Right,
                    })
                
                    local Track = create("Frame", {
                        Parent = Row,
                        BackgroundColor3 = Theme.Off,
                        Position = UDim2.new(0, 0, 0, 21),
                        Size = UDim2.new(1, 0, 0, 8),
                    })
                    corner(Track, 999)
                
                    local Fill = create("Frame", {
                        Parent = Track,
                        BackgroundColor3 = Highlight,
                        Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
                    })
                    corner(Fill, 999)
                
                    local Knob = create("Frame", {
                        Parent = Track,
                        BackgroundColor3 = Color3.fromRGB(240, 240, 240),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0),
                        Size = UDim2.fromOffset(14, 14),
                        ZIndex = 5,
                    })
                    corner(Knob, 999)
                    stroke(Knob, Theme.StrokeDim, 1)
                
                    local dragSlider = false
                
                    local function setFromAlpha(alpha)
                        alpha = math.clamp(alpha, 0, 1)
                        local rawValue = min + (max - min) * alpha
                        local factor = 10 ^ decimals
                        value = math.floor(rawValue * factor + 0.5) / factor
                        
                        Fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
                        Knob.Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0)
                        ValueLabel.Text = string.format("%." .. decimals .. "f", value) .. " / " .. max
                    end
                
                    Track.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            dragSlider = true
                            local alpha = (input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X
                            setFromAlpha(alpha)
                            task.spawn(callback, value)
                        end
                    end)
                    UIS.InputChanged:Connect(function(input)
                        if dragSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                            local alpha = (input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X
                            setFromAlpha(alpha)
                            task.spawn(callback, value)
                        end
                    end)
                    UIS.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            dragSlider = false
                        end
                    end)
                
                    registerSearch(Row, label)
                    return {
                        Row = Row,
                        Set = function(v)
                            setFromAlpha((v - min) / (max - min))
                        end,
                    }
                end
                function SectionAPI:Paragraph(o)
                    o = o or {}
                    local title = o.Name or "Paragraph"
                    local text = o.Text or ""
                
                    local Row = create("Frame", {
                        Parent = RowHolder,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 0),
                        AutomaticSize = Enum.AutomaticSize.Y,
                    })
                    -- Use a vertical layout for the whole row: header row + text
                    vlist(Row, 4)
                
                    -- Header row: accent bar + title side by side
                    local HeaderRow = create("Frame", {
                        Parent = Row,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 14),
                    })
                    create("UIListLayout", {
                        Parent = HeaderRow,
                        FillDirection = Enum.FillDirection.Horizontal,
                        Padding = UDim.new(0, 6),
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                    })
                
                    -- Accent bar (left)
                    create("Frame", {
                        Parent = HeaderRow,
                        BackgroundColor3 = Highlight,
                        Size = UDim2.fromOffset(2, 14),
                    })
                
                    -- Title (right of bar)
                    create("TextLabel", {
                        Parent = HeaderRow,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, -8, 0, 14),  -- take remaining width
                        Font = Enum.Font.GothamBold,
                        Text = title,
                        TextColor3 = Theme.Text,
                        TextSize = 12,
                        TextXAlignment = Enum.TextXAlignment.Left,
                    })
                
                    -- Description text below
                    create("TextLabel", {
                        Parent = Row,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 0),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        Font = Enum.Font.Gotham,
                        Text = text,
                        TextColor3 = Theme.SubText,
                        TextSize = 11,
                        TextWrapped = true,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextYAlignment = Enum.TextYAlignment.Top,
                        LayoutOrder = 2,
                    })
                
                    registerSearch(Row, title)
                    return { Row = Row }
                end

                function SectionAPI:Keybind(o)
                    o = o or {}
                    local label = o.Name or "Keybind"
                    local default = o.Default or Enum.KeyCode.F
                    local callback = o.Callback or function() end
                    local currentKey = default
                    local currentInputType = Enum.UserInputType.Keyboard
                    local listening = false

                    local function getInputName(input)
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            return input.KeyCode.Name
                        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                            return "Mouse1"
                        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                            return "Mouse2"
                        else
                            return "Unknown"
                        end
                    end

                    local Row = newRow(24)
                    create("TextLabel", {
                        Parent = Row,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, -100, 1, 0),
                        Font = Enum.Font.GothamMedium,
                        Text = label,
                        TextColor3 = Theme.Text,
                        TextSize = 13,
                        TextXAlignment = Enum.TextXAlignment.Left,
                    })

                    local KeyBox = create("TextButton", {
                        Parent = Row,
                        BackgroundColor3 = Theme.Off,
                        BackgroundTransparency = 0.15,
                        AutoButtonColor = false,
                        AnchorPoint = Vector2.new(1, 0.5),
                        Position = UDim2.new(1, 0, 0.5, 0),
                        Size = UDim2.fromOffset(90, 22),
                        Font = Enum.Font.Gotham,
                        Text = default.Name,
                        TextColor3 = Theme.Text,
                        TextSize = 11,
                        ClipsDescendants = true,
                    })
                    corner(KeyBox, 6)
                    stroke(KeyBox, Theme.StrokeDim, 1, 0.4)

                    KeyBox.MouseButton1Click:Connect(function()
                        listening = true
                        KeyBox.Text = "..."
                    end)

                    UIS.InputBegan:Connect(function(input, processed)
                        if listening then
                            if input.UserInputType == Enum.UserInputType.Keyboard or
                               input.UserInputType == Enum.UserInputType.MouseButton1 or
                               input.UserInputType == Enum.UserInputType.MouseButton2 then
                                currentKey = input.KeyCode
                                currentInputType = input.UserInputType
                                KeyBox.Text = getInputName(input)
                                listening = false
                            end
                        elseif not processed and not listening then
                            if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == currentKey then
                                task.spawn(callback, currentKey)
                            elseif input.UserInputType == currentInputType and
                                   (input.UserInputType == Enum.UserInputType.MouseButton1 or
                                    input.UserInputType == Enum.UserInputType.MouseButton2) then
                                task.spawn(callback, input.UserInputType)
                            end
                        end
                    end)

                    registerSearch(Row, label)
                    return { Row = Row }
                end

                function SectionAPI:ColorPicker(o)
                    o = o or {}
                    local label = o.Name or "Color"
                    local default = o.Default or Color3.fromRGB(255, 255, 255)
                    local callback = o.Callback or function() end
                    local current = default
                
                    local Row = newRow(24)
                    create("TextLabel", {
                        Parent = Row,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, -60, 1, 0),
                        Font = Enum.Font.GothamMedium,
                        Text = label,
                        TextColor3 = Theme.Text,
                        TextSize = 13,
                        TextXAlignment = Enum.TextXAlignment.Left,
                    })
                
                    local Swatch = create("TextButton", {
                        Parent = Row,
                        BackgroundColor3 = current,
                        AutoButtonColor = false,
                        AnchorPoint = Vector2.new(1, 0.5),
                        Position = UDim2.new(1, 0, 0.5, 0),
                        Size = UDim2.fromOffset(22, 22),
                        Text = "",
                    })
                    corner(Swatch, 6)
                    stroke(Swatch, Theme.StrokeDim, 1, 0.2)
                
                    local Popup = create("Frame", {
                        Parent = ScreenGui,
                        BackgroundColor3 = Theme.Panel,
                        BorderSizePixel = 0,
                        Size = UDim2.fromOffset(210, 0), -- Base width, height determined automatically
                        AutomaticSize = Enum.AutomaticSize.Y, -- FIXES: Extra space below inputs
                        Visible = false,
                        ZIndex = 200,
                        Active = true, -- FIXES: Keeps gradient clicks from shutting down the popup
                    })
                    corner(Popup, 10)
                    stroke(Popup, Theme.StrokeDim, 1)
                    pad(Popup, 14, 14, 14, 14)
                    vlist(Popup, 10)
                
                    local hue, sat, val = 0, 0, 1
                    do
                        local h, s, v = Color3.toHSV(current)
                        hue, sat, val = h, s, v
                    end
                
                    local Square = create("Frame", {
                        Parent = Popup,
                        BackgroundColor3 = Color3.fromHSV(hue, 1, 1),
                        Size = UDim2.new(1, 0, 0, 150),
                        LayoutOrder = 1,
                        ClipsDescendants = true,
                    })
                    corner(Square, 8)
                    stroke(Square, Theme.StrokeDim, 1, 0.2)
                
                    local WhiteOverlay = create("Frame", {
                        Parent = Square,
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        BorderSizePixel = 0,
                        Size = UDim2.fromScale(1, 1),
                    })
                    create("UIGradient", {
                        Parent = WhiteOverlay,
                        Color = ColorSequence.new(Color3.fromRGB(255, 255, 255)),
                        Transparency = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 0),
                            NumberSequenceKeypoint.new(1, 1),
                            }),
                    })
                
                    local BlackOverlay = create("Frame", {
                        Parent = Square,
                        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                        BorderSizePixel = 0,
                        Size = UDim2.fromScale(1, 1),
                    })
                    create("UIGradient", {
                        Parent = BlackOverlay,
                        Rotation = 90,
                        Color = ColorSequence.new(Color3.fromRGB(0, 0, 0)),
                        Transparency = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 1),
                            NumberSequenceKeypoint.new(1, 0),
                            }),
                    })
                
                    local SquareKnob = create("Frame", {
                        Parent = Square,
                        BackgroundTransparency = 1,
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.new(sat, 0, 1 - val, 0),
                        Size = UDim2.fromOffset(14, 14),
                        ZIndex = 5,
                    })
                    corner(SquareKnob, 999)
                    stroke(SquareKnob, Color3.fromRGB(255, 255, 255), 2)
                
                    local HueBar = create("Frame", {
                        Parent = Popup,
                        BorderSizePixel = 0,
                        Size = UDim2.new(1, 0, 0, 12),
                        LayoutOrder = 2,
                    })
                    corner(HueBar, 999)
                    stroke(HueBar, Theme.StrokeDim, 1, 0.2)
                    create("UIGradient", {
                        Parent = HueBar,
                        Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
                            ColorSequenceKeypoint.new(1 / 6, Color3.fromHSV(1 / 6, 1, 1)),
                            ColorSequenceKeypoint.new(2 / 6, Color3.fromHSV(2 / 6, 1, 1)),
                            ColorSequenceKeypoint.new(3 / 6, Color3.fromHSV(3 / 6, 1, 1)),
                            ColorSequenceKeypoint.new(4 / 6, Color3.fromHSV(4 / 6, 1, 1)),
                            ColorSequenceKeypoint.new(5 / 6, Color3.fromHSV(5 / 6, 1, 1)),
                            ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
                            }),
                    })
                
                    local HueKnob = create("Frame", {
                        Parent = HueBar,
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.new(hue, 0, 0.5, 0),
                        Size = UDim2.fromOffset(14, 14),
                        ZIndex = 5,
                    })
                    corner(HueKnob, 999)
                    stroke(HueKnob, Theme.StrokeDim, 1)
                
                    local InfoRow = create("Frame", {
                        Parent = Popup,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 30),
                        LayoutOrder = 3,
                    })
                    create("UIListLayout", {
                        Parent = InfoRow,
                        FillDirection = Enum.FillDirection.Horizontal,
                        Padding = UDim.new(0, 6),
                        SortOrder = Enum.SortOrder.LayoutOrder,
                    })
                
                    local Preview = create("Frame", {
                        Parent = InfoRow,
                        BackgroundColor3 = current,
                        Size = UDim2.new(0, 30, 1, 0),
                    })
                    corner(Preview, 6)
                    stroke(Preview, Theme.StrokeDim, 1, 0.2)
                
                    local HexBG = create("Frame", {
                        Parent = InfoRow,
                        BackgroundColor3 = Theme.Off,
                        BackgroundTransparency = 0.2,
                        Size = UDim2.new(1, -36, 1, 0),
                    })
                    corner(HexBG, 6)
                    stroke(HexBG, Theme.StrokeDim, 1, 0.4)
                
                    local HexBox = create("TextBox", {
                        Parent = HexBG,
                        Position = UDim2.new(0, 8, 0, 0),
                        Size = UDim2.new(1, -16, 1, 0),
                        BackgroundTransparency = 1,
                        Font = Enum.Font.GothamMedium,
                        Text = "#" .. toHex(current),
                        TextColor3 = Theme.Text,
                        TextSize = 12,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ClearTextOnFocus = false,
                    })
                
                    local RGBRow = create("Frame", {
                        Parent = Popup,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 30),
                        LayoutOrder = 4,
                    })
                    create("UIListLayout", {
                        Parent = RGBRow,
                        FillDirection = Enum.FillDirection.Horizontal,
                        Padding = UDim.new(0, 6),
                        SortOrder = Enum.SortOrder.LayoutOrder,
                    })
                
                    local function rgbField(placeholderText)
                        local Holder = create("Frame", {
                            Parent = RGBRow,
                            BackgroundColor3 = Theme.Off,
                            BackgroundTransparency = 0.2,
                            Size = UDim2.new(1 / 3, -4, 1, 0),
                        })
                        corner(Holder, 6)
                        stroke(Holder, Theme.StrokeDim, 1, 0.4)
                        local Box = create("TextBox", {
                            Parent = Holder,
                            BackgroundTransparency = 1,
                            Size = UDim2.fromScale(1, 1),
                            Font = Enum.Font.Gotham,
                            Text = "",
                            PlaceholderText = placeholderText,
                            PlaceholderColor3 = Theme.SubText,
                            TextColor3 = Theme.Text,
                            TextSize = 12,
                            ClearTextOnFocus = false,
                            TextXAlignment = Enum.TextXAlignment.Center,
                        })
                        return Box
                    end
                
                    local RBox = rgbField("R")
                    local GBox = rgbField("G")
                    local BBox = rgbField("B")
                
                    local updating = false
                
                    local function pushColor(skipFields)
                        current = Color3.fromHSV(hue, sat, val)
                        Swatch.BackgroundColor3 = current
                        Preview.BackgroundColor3 = current
                        Square.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
                        if not skipFields then
                            updating = true
                            HexBox.Text = "#" .. toHex(current)
                            RBox.Text = tostring(math.floor(current.R * 255 + 0.5))
                            GBox.Text = tostring(math.floor(current.G * 255 + 0.5))
                            BBox.Text = tostring(math.floor(current.B * 255 + 0.5))
                            updating = false
                        end
                        task.spawn(callback, current)
                    end
                
                    local dragSquare, dragHue = false, false
                
                    Square.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            dragSquare = true
                        end
                    end)
                    HueBar.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            dragHue = true
                        end
                    end)
                    UIS.InputChanged:Connect(function(input)
                        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
                            return
                        end
                        if dragSquare then
                            local sx = math.clamp((input.Position.X - Square.AbsolutePosition.X) / Square.AbsoluteSize.X, 0, 1)
                            local sy = math.clamp((input.Position.Y - Square.AbsolutePosition.Y) / Square.AbsoluteSize.Y, 0, 1)
                            sat = sx
                            val = 1 - sy
                            SquareKnob.Position = UDim2.new(sat, 0, 1 - val, 0)
                            pushColor()
                        elseif dragHue then
                            local hx = math.clamp((input.Position.X - HueBar.AbsolutePosition.X) / HueBar.AbsoluteSize.X, 0, 1)
                            hue = hx
                            HueKnob.Position = UDim2.new(hue, 0, 0.5, 0)
                            pushColor()
                        end
                    end)
                    UIS.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            dragSquare = false
                            dragHue = false
                        end
                    end)
                
                    local function applyHex()
                        if updating then return end
                        local hexStr = HexBox.Text:gsub("#", "")
                        if #hexStr == 6 and hexStr:match("^%x+$") then
                            local c = Color3.fromHex(hexStr)
                            local h, s, v = Color3.toHSV(c)
                            hue, sat, val = h, s, v
                            SquareKnob.Position = UDim2.new(sat, 0, 1 - val, 0)
                            HueKnob.Position = UDim2.new(hue, 0, 0.5, 0)
                            pushColor(true)
                        end
                    end
                    HexBox.FocusLost:Connect(applyHex)
                
                    local function applyRGB()
                        if updating then return end
                        local r = tonumber(RBox.Text) or 0
                        local g = tonumber(GBox.Text) or 0
                        local b = tonumber(BBox.Text) or 0
                        r, g, b = math.clamp(r, 0, 255), math.clamp(g, 0, 255), math.clamp(b, 0, 255)
                        local c = Color3.fromRGB(r, g, b)
                        local h, s, v = Color3.toHSV(c)
                        hue, sat, val = h, s, v
                        SquareKnob.Position = UDim2.new(sat, 0, 1 - val, 0)
                        HueKnob.Position = UDim2.new(hue, 0, 0.5, 0)
                        pushColor(true)
                    end
                    RBox.FocusLost:Connect(applyRGB)
                    GBox.FocusLost:Connect(applyRGB)
                    BBox.FocusLost:Connect(applyRGB)
                
                    local Blocker = nil
                    local function closePopup()
                        Popup.Visible = false
                        if Blocker then
                            Blocker:Destroy()
                            Blocker = nil
                        end
                        for i, dd in ipairs(openDropdowns) do
                            if dd == closePopup then
                                table.remove(openDropdowns, i)
                                break
                            end
                        end
                    end
                
                    Swatch.MouseButton1Click:Connect(function()
                        if Popup.Visible then
                            return
                        end
                        closeAllDropdowns() -- Close anything else active
                        local pos = Swatch.AbsolutePosition
                        local screenSize = ScreenGui.AbsoluteSize
                        local px = math.clamp(pos.X - 220, 4, screenSize.X - 214)
                        local py = math.clamp(pos.Y - 40, 4, screenSize.Y - 304)
                        Popup.Position = UDim2.fromOffset(px, py)
                        Popup.Visible = true
                        
                        table.insert(openDropdowns, closePopup) -- Tracks popup within the dynamic UI group
                        
                        Blocker = create("TextButton", {
                            Parent = ScreenGui,
                            BackgroundTransparency = 1,
                            Size = UDim2.fromScale(1, 1),
                            Text = "",
                            ZIndex = 190,
                            AutoButtonColor = false,
                        })
                        Blocker.MouseButton1Click:Connect(closePopup)
                    end)
                
                    registerSearch(Row, label)
                    return { Row = Row }
                end

                function SectionAPI:Dropdown(o)
                    o = o or {}
                    local label = o.Name or "Dropdown"
                    local options = o.Options or {}
                    local callback = o.Callback or function() end
                
                    local Row = create("Frame", {
                        Parent = RowHolder,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 0),
                        AutomaticSize = Enum.AutomaticSize.Y,
                    })
                    vlist(Row, 8) -- was 4
                
                    create("TextLabel", {
                        Parent = Row,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 14),
                        Font = Enum.Font.GothamMedium,
                        Text = label,
                        TextColor3 = Theme.SubText,
                        TextSize = 11,
                        TextXAlignment = Enum.TextXAlignment.Left,
                    })

                    styledDropdownList(Row, options, false, callback)

                    registerSearch(Row, label)
                    return { Row = Row }
                end

                function SectionAPI:MultiDropdown(o)
                    o = o or {}
                    local label = o.Name or "MultiDropdown"
                    local options = o.Options or {}
                    local callback = o.Callback or function() end
                
                    local Row = create("Frame", {
                        Parent = RowHolder,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 0),
                        AutomaticSize = Enum.AutomaticSize.Y,
                    })
                    vlist(Row, 8)
                
                    create("TextLabel", {
                        Parent = Row,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 14),
                        Font = Enum.Font.GothamMedium,
                        Text = label,
                        TextColor3 = Theme.SubText,
                        TextSize = 11,
                        TextXAlignment = Enum.TextXAlignment.Left,
                    })

                    styledDropdownList(Row, options, true, callback)

                    registerSearch(Row, label)
                    return { Row = Row }
                end

                return SectionAPI
            end

            return TabAPI
        end

        return CategoryAPI
    end

    Window.Root = ScreenGui
    Window.Main = Main
    Window.SetMinimized = setMinimized

    return Window
end

return Exodus
