local Exodus = {}
Exodus.__index = Exodus

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local Theme = {
	Background = Color3.fromRGB(8, 8, 8),
	Panel = Color3.fromRGB(12, 12, 12),
	Elevated = Color3.fromRGB(18, 18, 18),
	Stroke = Color3.fromRGB(255, 255, 255),
	StrokeDim = Color3.fromRGB(60, 60, 60),
	Text = Color3.fromRGB(240, 240, 240),
	SubText = Color3.fromRGB(150, 150, 150),
	Accent = Color3.fromRGB(255, 255, 255),
	Off = Color3.fromRGB(35, 35, 35),
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
		LayoutOrder = 2,
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

function Exodus:Init(config)
	config = config or {}

	local WindowName = config.Name or "EXODUS"
	local Keybind = config.Keybind or Enum.KeyCode.LeftAlt
	if typeof(Keybind) == "string" then
		Keybind = Enum.KeyCode[Keybind] or Enum.KeyCode.LeftAlt
	end
	local Highlight = config.Highlight or Theme.Accent
	local IconSize = config.IconSize or 30
	local LogoId = config.Logo

	local ScreenGui = create("ScreenGui", {
		Name = "ExodusUI",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = CoreGui,
	})

	local baseWidth, baseHeight = 680, 440
	local minWidth, minHeight = 520, 340

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
			ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 20)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(6, 6, 6)),
		}),
		Rotation = 90,
	})

	local TopBar = create("Frame", {
		Name = "TopBar",
		Parent = Main,
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 42),
	})
	corner(TopBar, 12)
	create("Frame", {
		Parent = TopBar,
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 1, -12),
		Size = UDim2.new(1, 0, 0, 12),
	})
	create("Frame", {
		Parent = TopBar,
		BackgroundColor3 = Theme.StrokeDim,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 1, -1),
		Size = UDim2.new(1, 0, 0, 1),
	})

	local Avatar = create("ImageLabel", {
		Parent = TopBar,
		BackgroundColor3 = Theme.Off,
		Position = UDim2.new(0, 10, 0.5, -IconSize / 2),
		Size = UDim2.fromOffset(IconSize, IconSize),
		Image = LogoId or getAvatar(LocalPlayer.UserId),
	})
	corner(Avatar, 8)
	stroke(Avatar, Theme.StrokeDim, 1)

	create("TextLabel", {
		Parent = TopBar,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 18 + IconSize, 0, 0),
		Size = UDim2.new(1, -(60 + IconSize), 1, 0),
		Font = Enum.Font.GothamBold,
		Text = WindowName,
		TextColor3 = Theme.Text,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	local MinimizeBtn = create("TextButton", {
		Parent = TopBar,
		BackgroundColor3 = Theme.Elevated,
		AutoButtonColor = false,
		Position = UDim2.new(1, -32, 0.5, -12),
		Size = UDim2.fromOffset(24, 24),
		Text = "-",
		Font = Enum.Font.GothamBold,
		TextColor3 = Theme.Text,
		TextSize = 16,
	})
	corner(MinimizeBtn, 6)
	stroke(MinimizeBtn, Theme.StrokeDim, 1)

	local Body = create("Frame", {
		Name = "Body",
		Parent = Main,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 42),
		Size = UDim2.new(1, 0, 1, -42),
	})

	local sidebarWidth = 190

	local Sidebar = create("Frame", {
		Name = "Sidebar",
		Parent = Body,
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
		Size = UDim2.new(0, sidebarWidth, 1, 0),
	})
	create("Frame", {
		Parent = Sidebar,
		BackgroundColor3 = Theme.StrokeDim,
		BorderSizePixel = 0,
		Position = UDim2.new(1, -1, 0, 0),
		Size = UDim2.new(0, 1, 1, 0),
	})

	local SearchHolder = create("Frame", {
		Parent = Sidebar,
		BackgroundColor3 = Theme.Elevated,
		Position = UDim2.new(0, 10, 0, 10),
		Size = UDim2.new(1, -20, 0, 30),
	})
	corner(SearchHolder, 8)
	local searchStroke = stroke(SearchHolder, Theme.StrokeDim, 1)

	local SearchBox = create("TextBox", {
		Parent = SearchHolder,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(1, -20, 1, 0),
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
		tween(searchStroke, { Color = Highlight }, 0.2)
	end)
	SearchBox.FocusLost:Connect(function()
		tween(searchStroke, { Color = Theme.StrokeDim }, 0.2)
	end)

	local TabList = create("ScrollingFrame", {
		Name = "TabList",
		Parent = Sidebar,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 8, 0, 50),
		Size = UDim2.new(1, -16, 1, -58),
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Theme.StrokeDim,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	})
	pad(TabList, 4, 4, 2, 2)
	vlist(TabList, 4)

	local ContentHolder = create("Frame", {
		Name = "ContentHolder",
		Parent = Body,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, sidebarWidth, 0, 0),
		Size = UDim2.new(1, -sidebarWidth, 1, 0),
	})

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
		TextSize = 16,
	})

	local dragging, dragStart, startPos = false, nil, nil
	local resizing, resizeStart, startSize = false, nil, nil

	TopBar.InputBegan:Connect(function(input)
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

	ResizeGrip.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			resizing = true
			resizeStart = input.Position
			startSize = Main.Size
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					resizing = false
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
				local newW = math.max(minWidth, startSize.X.Offset + delta.X)
				local newH = math.max(minHeight, startSize.Y.Offset + delta.Y)
				Main.Size = UDim2.fromOffset(newW, newH)
			end
		end
	end)

	local minimized = false

	local function setMinimized(state)
		minimized = state
		if state then
			local t = tween(MainScale, { Scale = 0.001 }, 0.22, Enum.EasingStyle.Quint)
			t.Completed:Connect(function()
				if minimized then
					Main.Visible = false
				end
			end)
		else
			Main.Visible = true
			MainScale.Scale = 0.001
			tween(MainScale, { Scale = 1 }, 0.28, Enum.EasingStyle.Back)
		end
	end

	MinimizeBtn.MouseButton1Click:Connect(function()
		setMinimized(not minimized)
	end)

	UIS.InputBegan:Connect(function(input, processed)
		if input.KeyCode == Keybind then
			setMinimized(not minimized)
		end
	end)

	local Window = {}
	Window._tabs = {}
	Window._searchIndex = {}
	Window._activeTab = nil

	local SectionRow, nextSectionColumn = twoColGroup(nil, 12)

	local function applySearch(query)
		query = query:lower()
		for _, entry in ipairs(Window._searchIndex) do
			local visible = query == "" or entry.text:lower():find(query, 1, true) ~= nil
			entry.frame.Visible = visible
		end
		for _, tabData in pairs(Window._tabs) do
			for _, sec in ipairs(tabData.sections) do
				if query ~= "" then
					local sectionHasVisible = false
					for _, entry in ipairs(sec.entries) do
						if entry.frame.Visible then
							sectionHasVisible = true
						end
					end
					sec.frame.Visible = sectionHasVisible
				else
					sec.frame.Visible = true
				end
			end
		end
	end

	SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		applySearch(SearchBox.Text)
	end)

	function Window:Tab(opts)
		opts = opts or {}
		local tabName = opts.Name or "Tab"
		local tabIcon = opts.Icon
		local order = #Window._tabs + 1

		local TabButton = create("TextButton", {
			Parent = TabList,
			BackgroundColor3 = Theme.Elevated,
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Size = UDim2.new(1, 0, 0, 34),
			Text = "",
			LayoutOrder = order * 2 - 1,
		})
		corner(TabButton, 8)
		local tabButtonStroke = stroke(TabButton, Theme.StrokeDim, 1, 1)

		local IconLabel = create("ImageLabel", {
			Parent = TabButton,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 10, 0.5, -9),
			Size = UDim2.fromOffset(18, 18),
			Image = tabIcon or "",
			ImageColor3 = Theme.SubText,
			Visible = tabIcon ~= nil,
		})

		local NameLabel = create("TextLabel", {
			Parent = TabButton,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, tabIcon and 36 or 14, 0, 0),
			Size = UDim2.new(1, -(tabIcon and 60 or 40), 1, 0),
			Font = Enum.Font.GothamMedium,
			Text = tabName,
			TextColor3 = Theme.SubText,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
		})

		local Chevron = create("TextButton", {
			Parent = TabButton,
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Position = UDim2.new(1, -26, 0, 0),
			Size = UDim2.new(0, 26, 1, 0),
			Font = Enum.Font.GothamBold,
			Text = "+",
			TextColor3 = Theme.SubText,
			TextSize = 14,
		})

		local SubList = create("Frame", {
			Parent = TabList,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			Size = UDim2.new(1, 0, 0, 0),
			LayoutOrder = order * 2,
		})

		local SubInner = create("Frame", {
			Parent = SubList,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
		})
		pad(SubInner, 16, 4, 4, 0)
		vlist(SubInner, 2)

		local Page = create("ScrollingFrame", {
			Parent = ContentHolder,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Theme.StrokeDim,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Visible = false,
		})
		pad(Page, 14, 14, 14, 14)

		local PageRow, nextPageColumn = twoColGroup(Page, 12)

		local expanded = false
		local function refreshSubHeight()
			if expanded then
				tween(SubList, { Size = UDim2.new(1, 0, 0, SubInner.AbsoluteSize.Y) }, 0.2)
			end
		end
		SubInner:GetPropertyChangedSignal("AbsoluteSize"):Connect(refreshSubHeight)

		local function setExpanded(state)
			expanded = state
			Chevron.Text = state and "-" or "+"
			if state then
				tween(SubList, { Size = UDim2.new(1, 0, 0, SubInner.AbsoluteSize.Y) }, 0.22)
			else
				tween(SubList, { Size = UDim2.new(1, 0, 0, 0) }, 0.22)
			end
		end

		Chevron.MouseButton1Click:Connect(function()
			setExpanded(not expanded)
		end)

		local tabData = { button = TabButton, page = Page, sections = {}, nameLabel = NameLabel, iconLabel = IconLabel, stroke = tabButtonStroke, subInner = SubInner }
		Window._tabs[tabName] = tabData

		local function selectTab()
			for _, t in pairs(Window._tabs) do
				t.page.Visible = false
				tween(t.button, { BackgroundTransparency = 1 }, 0.2)
				tween(t.stroke, { Transparency = 1 }, 0.2)
				tween(t.nameLabel, { TextColor3 = Theme.SubText }, 0.2)
				if t.iconLabel then
					tween(t.iconLabel, { ImageColor3 = Theme.SubText }, 0.2)
				end
			end
			Page.Visible = true
			Window._activeTab = Page
			tween(TabButton, { BackgroundTransparency = 0.85 }, 0.2)
			tween(tabButtonStroke, { Transparency = 0.55 }, 0.2)
			tween(NameLabel, { TextColor3 = Theme.Text }, 0.2)
			if tabIcon then
				tween(IconLabel, { ImageColor3 = Theme.Text }, 0.2)
			end
			if not expanded then
				setExpanded(true)
			end
		end

		TabButton.MouseButton1Click:Connect(selectTab)
		TabButton.MouseEnter:Connect(function()
			if Page.Visible then return end
			tween(TabButton, { BackgroundTransparency = 0.93 }, 0.15)
		end)
		TabButton.MouseLeave:Connect(function()
			if Page.Visible then return end
			tween(TabButton, { BackgroundTransparency = 1 }, 0.15)
		end)

		if order == 1 then
			selectTab()
		end

		local TabAPI = {}

		function TabAPI:Section(sectionOpts)
			sectionOpts = sectionOpts or {}
			local sectionName = sectionOpts.Name or "Section"

			local parentColumn = nextPageColumn()

			local SectionFrame = create("Frame", {
				Parent = parentColumn,
				BackgroundColor3 = Theme.Panel,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
			})
			corner(SectionFrame, 10)
			stroke(SectionFrame, Theme.StrokeDim, 1)
			pad(SectionFrame, 12, 12, 10, 12)
			vlist(SectionFrame, 10)

			create("TextLabel", {
				Parent = SectionFrame,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 16),
				Font = Enum.Font.GothamBold,
				Text = sectionName,
				TextColor3 = Theme.Text,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = 1,
			})

			local _, nextElemColumn = twoColGroup(SectionFrame, 8)

			local SubItemBtn = create("TextButton", {
				Parent = SubInner,
				BackgroundTransparency = 1,
				AutoButtonColor = false,
				Size = UDim2.new(1, 0, 0, 20),
				Font = Enum.Font.Gotham,
				Text = sectionName,
				TextColor3 = Theme.SubText,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
			})
			SubItemBtn.MouseEnter:Connect(function()
				tween(SubItemBtn, { TextColor3 = Theme.Text }, 0.15)
			end)
			SubItemBtn.MouseLeave:Connect(function()
				tween(SubItemBtn, { TextColor3 = Theme.SubText }, 0.15)
			end)
			SubItemBtn.MouseButton1Click:Connect(function()
				if not Page.Visible then
					selectTab()
				end
				task.wait()
				local targetY = SectionFrame.AbsolutePosition.Y - Page.AbsolutePosition.Y + Page.CanvasPosition.Y - 10
				tween(Page, { CanvasPosition = Vector2.new(0, math.max(0, targetY)) }, 0.3)
			end)

			local sectionData = { frame = SectionFrame, entries = {} }
			table.insert(tabData.sections, sectionData)

			local SectionAPI = {}

			local function registerSearch(frame, text)
				table.insert(Window._searchIndex, { frame = frame, text = text })
				table.insert(sectionData.entries, { frame = frame, text = text })
			end

			local function newCell(height)
				local col = nextElemColumn()
				local Cell = create("Frame", {
					Parent = col,
					BackgroundColor3 = Theme.Elevated,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 0, height or 38),
				})
				corner(Cell, 8)
				stroke(Cell, Theme.StrokeDim, 1)
				return Cell
			end

			function SectionAPI:Button(o)
				o = o or {}
				local label = o.Name or "Button"
				local callback = o.Callback or function() end

				local Cell = newCell(38)
				local Btn = create("TextButton", {
					Parent = Cell,
					BackgroundTransparency = 1,
					AutoButtonColor = false,
					Size = UDim2.fromScale(1, 1),
					Text = "",
					ClipsDescendants = true,
				})
				create("TextLabel", {
					Parent = Btn,
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 10, 0, 0),
					Size = UDim2.new(1, -20, 1, 0),
					Font = Enum.Font.GothamMedium,
					Text = label,
					TextColor3 = Theme.Text,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
				})

				Btn.MouseEnter:Connect(function()
					tween(Cell, { BackgroundColor3 = Theme.Off }, 0.15)
				end)
				Btn.MouseLeave:Connect(function()
					tween(Cell, { BackgroundColor3 = Theme.Elevated }, 0.15)
				end)
				Btn.MouseButton1Down:Connect(function(x, y)
					ripple(Btn, x, y)
				end)
				Btn.MouseButton1Click:Connect(function()
					task.spawn(callback)
				end)

				registerSearch(Cell, label)
				return { Cell = Cell }
			end

			function SectionAPI:Toggle(o)
				o = o or {}
				local label = o.Name or "Toggle"
				local default = o.Default or false
				local callback = o.Callback or function() end
				local state = default

				local Cell = newCell(38)
				create("TextLabel", {
					Parent = Cell,
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 10, 0, 0),
					Size = UDim2.new(1, -60, 1, 0),
					Font = Enum.Font.GothamMedium,
					Text = label,
					TextColor3 = Theme.Text,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
				})

				local SwitchBG = create("Frame", {
					Parent = Cell,
					BackgroundColor3 = state and Highlight or Theme.Off,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -10, 0.5, 0),
					Size = UDim2.fromOffset(32, 20),
				})
				corner(SwitchBG, 999)
				stroke(SwitchBG, Theme.StrokeDim, 1)

				local Knob = create("Frame", {
					Parent = SwitchBG,
					BackgroundColor3 = Color3.fromRGB(10, 10, 10),
					Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
					Size = UDim2.fromOffset(16, 16),
				})
				corner(Knob, 999)

				local Click = create("TextButton", {
					Parent = Cell,
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1),
					Text = "",
				})

				local function render()
					tween(SwitchBG, { BackgroundColor3 = state and Highlight or Theme.Off }, 0.2)
					tween(Knob, { Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8) }, 0.2, Enum.EasingStyle.Back)
				end

				Click.MouseButton1Click:Connect(function()
					state = not state
					render()
					task.spawn(callback, state)
				end)

				registerSearch(Cell, label)
				return {
					Cell = Cell,
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

				local Cell = newCell(58)
				create("TextLabel", {
					Parent = Cell,
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 10, 0, 8),
					Size = UDim2.new(1, -20, 0, 14),
					Font = Enum.Font.GothamMedium,
					Text = label,
					TextColor3 = Theme.SubText,
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left,
				})

				local InputBG = create("Frame", {
					Parent = Cell,
					BackgroundColor3 = Theme.Off,
					Position = UDim2.new(0, 10, 0, 28),
					Size = UDim2.new(1, -20, 0, 22),
				})
				corner(InputBG, 6)
				local inputStroke = stroke(InputBG, Theme.StrokeDim, 1)

				local Box = create("TextBox", {
					Parent = InputBG,
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 8, 0, 0),
					Size = UDim2.new(1, -16, 1, 0),
					Font = Enum.Font.Gotham,
					PlaceholderText = placeholder,
					PlaceholderColor3 = Theme.SubText,
					Text = "",
					TextColor3 = Theme.Text,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Center,
					ClearTextOnFocus = false,
					ClipsDescendants = true,
				})

				Box.Focused:Connect(function()
					tween(inputStroke, { Color = Highlight }, 0.2)
				end)
				Box.FocusLost:Connect(function()
					tween(inputStroke, { Color = Theme.StrokeDim }, 0.2)
					task.spawn(callback, Box.Text)
				end)

				registerSearch(Cell, label)
				return { Cell = Cell, Box = Box }
			end

			function SectionAPI:Slider(o)
				o = o or {}
				local label = o.Name or "Slider"
				local min = o.Min or 0
				local max = o.Max or 100
				local default = math.clamp(o.Default or min, min, max)
				local callback = o.Callback or function() end
				local value = default

				local Cell = newCell(54)
				create("TextLabel", {
					Parent = Cell,
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 10, 0, 8),
					Size = UDim2.new(0.6, 0, 0, 14),
					Font = Enum.Font.GothamMedium,
					Text = label,
					TextColor3 = Theme.SubText,
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left,
				})
				local ValueLabel = create("TextLabel", {
					Parent = Cell,
					BackgroundTransparency = 1,
					Position = UDim2.new(1, -50, 0, 8),
					Size = UDim2.new(0, 40, 0, 14),
					Font = Enum.Font.GothamBold,
					Text = tostring(value),
					TextColor3 = Theme.Text,
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Right,
				})

				local Track = create("Frame", {
					Parent = Cell,
					BackgroundColor3 = Theme.Off,
					Position = UDim2.new(0, 10, 0, 34),
					Size = UDim2.new(1, -20, 0, 6),
				})
				corner(Track, 999)
				stroke(Track, Theme.StrokeDim, 1)

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
					Size = UDim2.fromOffset(12, 12),
					ZIndex = 5,
				})
				corner(Knob, 999)
				stroke(Knob, Theme.StrokeDim, 1)

				local dragSlider = false

				local function setFromAlpha(alpha)
					alpha = math.clamp(alpha, 0, 1)
					value = math.floor(min + (max - min) * alpha)
					Fill.Size = UDim2.new(alpha, 0, 1, 0)
					Knob.Position = UDim2.new(alpha, 0, 0.5, 0)
					ValueLabel.Text = tostring(value)
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

				registerSearch(Cell, label)
				return {
					Cell = Cell,
					Set = function(v)
						setFromAlpha((v - min) / (max - min))
					end,
				}
			end

			function SectionAPI:Paragraph(o)
				o = o or {}
				local title = o.Name or "Paragraph"
				local text = o.Text or ""

				local Cell = create("Frame", {
					Parent = nextElemColumn(),
					BackgroundColor3 = Theme.Elevated,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
				})
				corner(Cell, 8)
				stroke(Cell, Theme.StrokeDim, 1)
				pad(Cell, 10, 10, 8, 8)
				vlist(Cell, 4)

				create("TextLabel", {
					Parent = Cell,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 16),
					Font = Enum.Font.GothamBold,
					Text = title,
					TextColor3 = Theme.Text,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					LayoutOrder = 1,
				})
				create("TextLabel", {
					Parent = Cell,
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

				registerSearch(Cell, title)
				return { Cell = Cell }
			end

			function SectionAPI:Keybind(o)
				o = o or {}
				local label = o.Name or "Keybind"
				local default = o.Default or Enum.KeyCode.F
				local callback = o.Callback or function() end
				local currentKey = default
				local listening = false

				local Cell = newCell(38)
				create("TextLabel", {
					Parent = Cell,
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 10, 0, 0),
					Size = UDim2.new(1, -90, 1, 0),
					Font = Enum.Font.GothamMedium,
					Text = label,
					TextColor3 = Theme.Text,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
				})

				local KeyBox = create("TextButton", {
					Parent = Cell,
					BackgroundColor3 = Theme.Off,
					AutoButtonColor = false,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -10, 0.5, 0),
					Size = UDim2.fromOffset(64, 24),
					Font = Enum.Font.GothamBold,
					Text = currentKey.Name,
					TextColor3 = Theme.Text,
					TextSize = 11,
				})
				corner(KeyBox, 6)
				local keyStroke = stroke(KeyBox, Theme.StrokeDim, 1)

				KeyBox.MouseButton1Click:Connect(function()
					listening = true
					KeyBox.Text = "..."
					tween(keyStroke, { Color = Highlight }, 0.2)
				end)

				UIS.InputBegan:Connect(function(input, processed)
					if listening and input.UserInputType == Enum.UserInputType.Keyboard then
						currentKey = input.KeyCode
						KeyBox.Text = currentKey.Name
						listening = false
						tween(keyStroke, { Color = Theme.StrokeDim }, 0.2)
					elseif not processed and not listening and input.KeyCode == currentKey then
						task.spawn(callback, currentKey)
					end
				end)

				registerSearch(Cell, label)
				return { Cell = Cell }
			end

			function SectionAPI:ColorPicker(o)
				o = o or {}
				local label = o.Name or "Color"
				local default = o.Default or Color3.fromRGB(255, 255, 255)
				local callback = o.Callback or function() end
				local current = default

				local Cell = newCell(38)
				create("TextLabel", {
					Parent = Cell,
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 10, 0, 0),
					Size = UDim2.new(1, -60, 1, 0),
					Font = Enum.Font.GothamMedium,
					Text = label,
					TextColor3 = Theme.Text,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
				})

				local Swatch = create("TextButton", {
					Parent = Cell,
					BackgroundColor3 = current,
					AutoButtonColor = false,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -10, 0.5, 0),
					Size = UDim2.fromOffset(24, 24),
					Text = "",
				})
				corner(Swatch, 6)
				stroke(Swatch, Theme.StrokeDim, 1)

				local Popup = create("Frame", {
					Parent = ScreenGui,
					BackgroundColor3 = Theme.Panel,
					BorderSizePixel = 0,
					Size = UDim2.fromOffset(180, 168),
					Visible = false,
					ZIndex = 200,
				})
				corner(Popup, 10)
				stroke(Popup, Theme.StrokeDim, 1)
				pad(Popup, 12, 12, 12, 12)
				vlist(Popup, 8)

				local Preview = create("Frame", {
					Parent = Popup,
					BackgroundColor3 = current,
					Size = UDim2.new(1, 0, 0, 28),
					LayoutOrder = 0,
				})
				corner(Preview, 6)
				stroke(Preview, Theme.StrokeDim, 1)

				local r, g, b = current.R * 255, current.G * 255, current.B * 255

				local function makeChannel(name, order, initial)
					local Row = create("Frame", { Parent = Popup, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26), LayoutOrder = order })
					create("TextLabel", {
						Parent = Row,
						BackgroundTransparency = 1,
						Size = UDim2.new(0, 16, 1, 0),
						Font = Enum.Font.GothamBold,
						Text = name,
						TextColor3 = Theme.SubText,
						TextSize = 11,
					})
					local Track = create("Frame", {
						Parent = Row,
						BackgroundColor3 = Theme.Off,
						AnchorPoint = Vector2.new(0, 0.5),
						Position = UDim2.new(0, 22, 0.5, 0),
						Size = UDim2.new(1, -22, 0, 6),
					})
					corner(Track, 999)
					stroke(Track, Theme.StrokeDim, 1)
					local Fill = create("Frame", { Parent = Track, BackgroundColor3 = Highlight, Size = UDim2.new(initial / 255, 0, 1, 0) })
					corner(Fill, 999)
					local Knob = create("Frame", {
						Parent = Track,
						BackgroundColor3 = Color3.fromRGB(240, 240, 240),
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.new(initial / 255, 0, 0.5, 0),
						Size = UDim2.fromOffset(12, 12),
						ZIndex = 5,
					})
					corner(Knob, 999)
					stroke(Knob, Theme.StrokeDim, 1)
					return Track, Fill, Knob
				end

				local RTrack, RFill, RKnob = makeChannel("R", 1, r)
				local GTrack, GFill, GKnob = makeChannel("G", 2, g)
				local BTrack, BFill, BKnob = makeChannel("B", 3, b)

				local function updateColor()
					current = Color3.fromRGB(math.floor(r), math.floor(g), math.floor(b))
					Swatch.BackgroundColor3 = current
					Preview.BackgroundColor3 = current
					task.spawn(callback, current)
				end

				local function bindChannel(track, fill, knob, setVal)
					local dragC = false
					local function apply(inputPos)
						local alpha = math.clamp((inputPos.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
						fill.Size = UDim2.new(alpha, 0, 1, 0)
						knob.Position = UDim2.new(alpha, 0, 0.5, 0)
						setVal(alpha * 255)
						updateColor()
					end
					track.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
							dragC = true
							apply(input.Position)
						end
					end)
					UIS.InputChanged:Connect(function(input)
						if dragC and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
							apply(input.Position)
						end
					end)
					UIS.InputEnded:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
							dragC = false
						end
					end)
				end

				bindChannel(RTrack, RFill, RKnob, function(v) r = v end)
				bindChannel(GTrack, GFill, GKnob, function(v) g = v end)
				bindChannel(BTrack, BFill, BKnob, function(v) b = v end)

				local Blocker = nil
				local function closePopup()
					Popup.Visible = false
					if Blocker then
						Blocker:Destroy()
						Blocker = nil
					end
				end

				Swatch.MouseButton1Click:Connect(function()
					if Popup.Visible then
						closePopup()
						return
					end
					local pos = Swatch.AbsolutePosition
					local screenSize = ScreenGui.AbsoluteSize
					local px = math.clamp(pos.X - 190, 4, screenSize.X - 184)
					local py = math.clamp(pos.Y - 20, 4, screenSize.Y - 172)
					Popup.Position = UDim2.fromOffset(px, py)
					Popup.Visible = true
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

				registerSearch(Cell, label)
				return { Cell = Cell }
			end

			local function styledDropdownList(Cell, label, options, isMulti, callback)
				local Selector = create("TextButton", {
					Parent = Cell,
					BackgroundColor3 = Theme.Off,
					AutoButtonColor = false,
					Position = UDim2.new(0, 10, 0, 28),
					Size = UDim2.new(1, -20, 0, 22),
					Font = Enum.Font.Gotham,
					Text = isMulti and "  None selected" or "  Select...",
					TextColor3 = Theme.Text,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					ClipsDescendants = true,
				})
				corner(Selector, 6)
				local selectorStroke = stroke(Selector, Theme.StrokeDim, 1)

				local ListFrame = create("Frame", {
					Parent = Cell,
					BackgroundColor3 = Theme.Elevated,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 10, 0, 52),
					Size = UDim2.new(1, -20, 0, 0),
					ClipsDescendants = true,
					ZIndex = 30,
					Visible = false,
				})
				corner(ListFrame, 6)
				stroke(ListFrame, Theme.StrokeDim, 1)
				vlist(ListFrame, 2)
				pad(ListFrame, 4, 4, 4, 4)

				local open = false
				local optionButtons = {}
				local selected = {}

				local function close()
					open = false
					tween(ListFrame, { Size = UDim2.new(1, -20, 0, 0) }, 0.2)
					task.delay(0.2, function()
						if not open then
							ListFrame.Visible = false
						end
					end)
					tween(selectorStroke, { Color = Theme.StrokeDim }, 0.2)
				end

				local function openList()
					open = true
					ListFrame.Visible = true
					local h = math.min(#options * 24 + 8, 140)
					tween(ListFrame, { Size = UDim2.new(1, -20, 0, h) }, 0.2)
					tween(selectorStroke, { Color = Highlight }, 0.2)
				end

				local function refreshLabel()
					if isMulti then
						local names = {}
						for _, n in ipairs(options) do
							if selected[n] then
								table.insert(names, n)
							end
						end
						Selector.Text = #names == 0 and "  None selected" or ("  " .. table.concat(names, ", "))
					end
				end

				for i, optName in ipairs(options) do
					local OptBtn = create("TextButton", {
						Parent = ListFrame,
						BackgroundColor3 = Theme.Off,
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
						if not selected[optName] then
							tween(OptBtn, { BackgroundTransparency = 0.85 }, 0.15)
						end
					end)
					OptBtn.MouseLeave:Connect(function()
						if not selected[optName] then
							tween(OptBtn, { BackgroundTransparency = 1 }, 0.15)
						end
					end)

					OptBtn.MouseButton1Click:Connect(function()
						if isMulti then
							selected[optName] = not selected[optName] or nil
							if selected[optName] then
								tween(OptBtn, { BackgroundTransparency = 0, BackgroundColor3 = Highlight }, 0.15)
								tween(OptBtn, { TextColor3 = Color3.fromRGB(10, 10, 10) }, 0.15)
							else
								tween(OptBtn, { BackgroundTransparency = 1, BackgroundColor3 = Theme.Off }, 0.15)
								tween(OptBtn, { TextColor3 = Theme.SubText }, 0.15)
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
							for name, btn in pairs(optionButtons) do
								tween(btn, { BackgroundTransparency = 1, BackgroundColor3 = Theme.Off, TextColor3 = Theme.SubText }, 0.15)
							end
							tween(OptBtn, { BackgroundTransparency = 0, BackgroundColor3 = Highlight, TextColor3 = Color3.fromRGB(10, 10, 10) }, 0.15)
							Selector.Text = "  " .. optName
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

				return Selector
			end

			function SectionAPI:Dropdown(o)
				o = o or {}
				local label = o.Name or "Dropdown"
				local options = o.Options or {}
				local callback = o.Callback or function() end

				local Cell = newCell(58)
				Cell.ClipsDescendants = false
				create("TextLabel", {
					Parent = Cell,
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 10, 0, 8),
					Size = UDim2.new(0.7, 0, 0, 14),
					Font = Enum.Font.GothamMedium,
					Text = label,
					TextColor3 = Theme.SubText,
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left,
				})

				styledDropdownList(Cell, label, options, false, callback)

				registerSearch(Cell, label)
				return { Cell = Cell }
			end

			function SectionAPI:MultiDropdown(o)
				o = o or {}
				local label = o.Name or "MultiDropdown"
				local options = o.Options or {}
				local callback = o.Callback or function() end

				local Cell = newCell(58)
				Cell.ClipsDescendants = false
				create("TextLabel", {
					Parent = Cell,
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 10, 0, 8),
					Size = UDim2.new(0.7, 0, 0, 14),
					Font = Enum.Font.GothamMedium,
					Text = label,
					TextColor3 = Theme.SubText,
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left,
				})

				styledDropdownList(Cell, label, options, true, callback)

				registerSearch(Cell, label)
				return { Cell = Cell }
			end

			return SectionAPI
		end

		return TabAPI
	end

	Window.Root = ScreenGui
	Window.Main = Main
	Window.SetMinimized = setMinimized

	return Window
end

return Exodus
