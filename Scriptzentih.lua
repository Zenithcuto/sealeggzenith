-- [[ Zenith EGG - Steal An Egg Premium ]]
-- PlaceId: 107778070777162
-- Full Feature Hub with Original High-End SVUI

local PLACE_ID = 107778070777162
local genv = (getgenv and getgenv()) or _G

if type(genv.SV_SAE_SHUTDOWN) == "function" then
	pcall(genv.SV_SAE_SHUTDOWN)
	task.wait(0.05)
end

-- Clear old GUI instances cleanly from PlayerGui and CoreGui
pcall(function()
	local Players = game:GetService("Players")
	local lp = Players.LocalPlayer
	local targetParents = {}
	if typeof(gethui) == "function" then
		pcall(function() table.insert(targetParents, gethui()) end)
	end
	pcall(function() table.insert(targetParents, game:GetService("CoreGui")) end)
	if lp and lp:FindFirstChildOfClass("PlayerGui") then
		table.insert(targetParents, lp:FindFirstChildOfClass("PlayerGui"))
	end
	for _, parent in ipairs(targetParents) do
		for _, child in ipairs(parent:GetChildren()) do
			if child:IsA("ScreenGui") and (child.Name:find("SVUI") or child.Name:find("Zenith")) then
				child:Destroy()
			end
		end
	end
end)

genv.SV_SAE_RUNNING = true
print("========================================")
print("[Zenith EGG] STARTING PREMIUM HUB...")
print("========================================")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
	local t = os.clock()
	while not LocalPlayer and os.clock() - t < 5 do
		LocalPlayer = Players.LocalPlayer
		task.wait(0.05)
	end
end

-- =========================================================================
-- SVUI LIBRARY INLINE
-- =========================================================================
local SVUI = (function()
--[[
  ScriptVerse UI (SVUI)
  Reusable hub library - tabs, toggles, sliders, dropdowns, inputs, notifies.

  loadstring(game:HttpGet("https://scriptversekey.xyz/svui.lua"))()

  After key unlock the loader may also inject this as getgenv().SVUI
  Solara guards live on getgenv().SVCompat / Library.Compat
]]

-- Ensure shared Solara compat is always present before UI builds
pcall(function()
	local genv = (getgenv and getgenv()) or _G
	if type(genv.SVCompat) == "table" and genv.SVCompat.__svcompat then
		return
	end
	-- Inline minimal install (full module also at /svcompat.lua)
	local function executorName()
		local ok, n = pcall(function()
			return (identifyexecutor and identifyexecutor()) or (getexecutorname and getexecutorname()) or ""
		end)
		return (ok and tostring(n) or ""):lower()
	end
	local exec = executorName()
	local isSolara = exec:find("solara", 1, true) ~= nil
	local realRequire = require
	local Compat = {
		__svcompat = true,
		Executor = exec,
		IsSolara = isSolara,
		AllowRequire = not isSolara,
		AllowHooks = (not isSolara) and typeof(hookmetamethod) == "function",
		AllowGc = (not isSolara) and typeof(getgc) == "function",
		AllowDrawing = typeof(Drawing) == "table" and typeof(Drawing.new) == "function",
	}
	function Compat.softRequire(mod)
		if mod == nil then return nil end
		local ok, res = pcall(realRequire, mod)
		if ok then return res end
		return nil
	end
	Compat.require = Compat.softRequire
	function Compat.child(parent, ...)
		local cur = parent
		for i = 1, select("#", ...) do
			if typeof(cur) ~= "Instance" then
				return nil
			end
			cur = cur:FindFirstChild((select(i, ...)))
		end
		return cur
	end
	function Compat.softDrawing(class)
		if not Compat.AllowDrawing then
			return nil
		end
		local ok, obj = pcall(Drawing.new, class)
		return ok and obj or nil
	end
	function Compat.canHook()
		return Compat.AllowHooks == true
	end
	function Compat.canGc()
		return Compat.AllowGc == true
	end
	local _n = {}
	function Compat.unsupported(feature)
		local k = tostring(feature or "?")
		if _n[k] then
			return
		end
		_n[k] = true
		warn("[ScriptVerse]", k, "isn't supported on this executor")
	end
	genv.SVCompat = Compat
end)

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
	local t0 = os.clock()
	while not LocalPlayer and (os.clock() - t0 < 3) do
		LocalPlayer = Players.LocalPlayer
		task.wait(0.05)
	end
end
local Camera = workspace.CurrentCamera

local LOGO_URL = "https://scriptversekey.xyz/logo.png"

local function newGuid()
	-- Solara throws "Unable to cast string to bool" on GenerateGUID(false) — never pass a bool first
	local ok, id = pcall(function()
		return HttpService:GenerateGUID()
	end)
	if ok and type(id) == "string" and #id > 0 then
		return id
	end
	ok, id = pcall(function()
		return HttpService:GenerateGUID(false)
	end)
	if ok and type(id) == "string" and #id > 0 then
		return id
	end
	return tostring(math.floor(os.clock() * 1e6)) .. tostring(math.random(100000, 999999))
end

local Theme = {
	Bg = Color3.fromRGB(12, 12, 15),
	Surface = Color3.fromRGB(20, 20, 25),
	Surface2 = Color3.fromRGB(30, 30, 38),
	Border = Color3.fromRGB(65, 65, 78),
	Text = Color3.fromRGB(250, 250, 255),
	Muted = Color3.fromRGB(160, 160, 175),
	Accent = Color3.fromRGB(230, 230, 240),
	AccentBright = Color3.fromRGB(255, 255, 255),
	AccentDim = Color3.fromRGB(48, 48, 58),
	AccentDeep = Color3.fromRGB(32, 32, 40),
	Steel = Color3.fromRGB(200, 200, 215),
	Success = Color3.fromRGB(240, 240, 245),
	Danger = Color3.fromRGB(225, 70, 70),
	Warning = Color3.fromRGB(240, 200, 80),
}

local function fontFace(weight)
	local ok, face = pcall(function()
		return Font.new("rbxasset://fonts/families/Poppins.json", weight or Enum.FontWeight.Medium)
	end)
	if ok then
		return face
	end
	return nil
end

local FontUI = fontFace(Enum.FontWeight.Medium)
local FontUISemi = fontFace(Enum.FontWeight.SemiBold)
local FontUIBold = fontFace(Enum.FontWeight.Bold)

local function applyFont(lbl, weight)
	if not lbl then
		return
	end
	pcall(function()
		local face = weight == "bold" and FontUIBold or weight == "semi" and FontUISemi or FontUI
		if face then
			lbl.FontFace = face
		else
			lbl.Font = weight == "bold" and Enum.Font.GothamBold
				or weight == "semi" and Enum.Font.GothamMedium
				or Enum.Font.Gotham
		end
	end)
end

local function round(inst, px)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, px or 10)
	c.Parent = inst
	return c
end

local function stroke(inst, color, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color or Theme.Border
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0.15
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = inst
	return s
end

local function gradient(inst, c0, c1, rotation)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, c0 or Theme.AccentDeep),
		ColorSequenceKeypoint.new(1, c1 or Theme.AccentBright),
	})
	g.Rotation = rotation or 90
	g.Parent = inst
	return g
end

local function softShadow(parent, radius)
	local sh = Instance.new("ImageLabel")
	sh.Name = "SoftShadow"
	sh.BackgroundTransparency = 1
	sh.Image = "rbxassetid://5028857084"
	sh.ImageColor3 = Color3.fromRGB(0, 20, 40)
	sh.ImageTransparency = 0.55
	sh.ScaleType = Enum.ScaleType.Slice
	sh.SliceCenter = Rect.new(24, 24, 276, 276)
	sh.Size = UDim2.new(1, (radius or 18) * 2, 1, (radius or 18) * 2)
	sh.Position = UDim2.fromOffset(-(radius or 18), -(radius or 18) + 2)
	sh.ZIndex = math.max(0, (parent.ZIndex or 1) - 1)
	sh.Parent = parent
	return sh
end

local function pad(inst, t, r, b, l)
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, t or 0)
	p.PaddingRight = UDim.new(0, r or t or 0)
	p.PaddingBottom = UDim.new(0, b or t or 0)
	p.PaddingLeft = UDim.new(0, l or r or t or 0)
	p.Parent = inst
	return p
end

local function tween(obj, props, t, style, dir)
	local tw = TweenService:Create(
		obj,
		TweenInfo.new(t or 0.2, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out),
		props
	)
	tw:Play()
	return tw
end

local function stripRich(s)
	return (tostring(s or ""):gsub("<[^>]+>", ""))
end

local function searchKey(s)
	return string.lower(stripRich(s)):gsub("%s+", " ")
end

local function ancestorIsScreenGui(inst)
	local p = inst
	while typeof(p) == "Instance" do
		if p:IsA("ScreenGui") or p.Name == "RobloxGui" then
			return true
		end
		p = p.Parent
	end
	return false
end

local function makeGuiTransparent(gui)
	-- Nested ScreenGui (gethui = RobloxGui on Cobalt) is treated as a fullscreen
	-- GuiObject with an opaque background — that is the blackscreen + sharp edges.
	pcall(function()
		if gui:IsA("GuiObject") then
			gui.BackgroundTransparency = 1
			gui.BorderSizePixel = 0
			gui.Active = false
		end
	end)
end

local function protectGui(gui)
	if not gui then return end
	local parented = false
	pcall(function()
		local lp = game:GetService("Players").LocalPlayer
		if lp then
			local pg = lp:FindFirstChildOfClass("PlayerGui") or lp:WaitForChild("PlayerGui", 5)
			if pg then
				gui.Parent = pg
				parented = true
			end
		end
	end)
	if not parented then
		pcall(function()
			local cg = game:GetService("CoreGui")
			if cg then
				if typeof(syn) == "table" and typeof(syn.protect_gui) == "function" then
					syn.protect_gui(gui)
				end
				gui.Parent = cg
				parented = true
			end
		end)
	end
	if not parented then
		pcall(function()
			if typeof(gethui) == "function" then
				local h = gethui()
				if h and typeof(h) == "Instance" then
					gui.Parent = h
					parented = true
				end
			end
		end)
	end
	if gui:IsA("ScreenGui") then
		gui.DisplayOrder = 99999
		gui.ResetOnSpawn = false
		gui.IgnoreGuiInset = true
		gui.Enabled = true
	end
end

local function applyLogo(imageLabel)
	if not imageLabel then return end
	imageLabel.Image = "rbxassetid://10709752035"
	imageLabel.ImageColor3 = Theme.AccentBright
end

local function viewport()
	return (Camera and Camera.ViewportSize) or Vector2.new(1280, 720)
end

local function isCompact()
	local v = viewport()
	return v.X < 520 or (UserInputService.TouchEnabled and v.X < 900)
end

local function makeDraggable(handle, target, syncTargets)
	target = target or handle
	syncTargets = syncTargets or {}
	local dragging, start, startPos
	local function applyPos(pos)
		target.Position = pos
		for _, extra in ipairs(syncTargets) do
			if extra and extra.Parent then
				extra.Position = pos
			end
		end
	end
	handle.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = true
			start = input.Position
			startPos = target.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if
			dragging
			and (
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			local delta = input.Position - start
			applyPos(UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			))
		end
	end)
end

local Library = {
	Windows = {},
	_flags = {},
	_flagLinks = {},
}

Library.Theme = Theme

function Library:SetTheme(patch)
	if type(patch) ~= "table" then
		return
	end
	for k, v in pairs(patch) do
		if typeof(v) == "Color3" then
			Theme[k] = v
		end
	end
end

function Library:Notify(opts)
	opts = opts or {}
	local title = opts.Title or "ScriptVerse"
	local content = opts.Content or opts.Description or ""
	local duration = opts.Duration or 3.5
	local color = opts.Color or Theme.AccentBright

	local host = self._notifyHost
	if not host or not host.Parent then
		local gui = Instance.new("ScreenGui")
		gui.Name = "SVUINotify"
		gui.IgnoreGuiInset = true
		gui.ResetOnSpawn = false
		gui.DisplayOrder = 10000
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		protectGui(gui)
		host = Instance.new("Frame")
		host.Name = "Host"
		host.BackgroundTransparency = 1
		host.AnchorPoint = Vector2.new(1, 1)
		host.Position = UDim2.new(1, -16, 1, -16)
		host.Size = UDim2.new(0, 300, 1, -32)
		host.Parent = gui
		local list = Instance.new("UIListLayout")
		list.FillDirection = Enum.FillDirection.Vertical
		list.VerticalAlignment = Enum.VerticalAlignment.Bottom
		list.HorizontalAlignment = Enum.HorizontalAlignment.Right
		list.Padding = UDim.new(0, 8)
		list.Parent = host
		self._notifyHost = host
		self._notifyGui = gui
	end

	local card = Instance.new("Frame")
	card.BackgroundColor3 = Color3.new(1, 1, 1)
	card.BorderSizePixel = 0
	card.Size = UDim2.new(1, 0, 0, 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.BackgroundTransparency = 1
	card.Parent = host
	round(card, 12)
	stroke(card, Theme.AccentBright, 1, 0.45)
	gradient(card, Color3.fromRGB(16, 24, 38), Color3.fromRGB(10, 14, 22), 110)
	pad(card, 12, 14, 12, 14)

	local bar = Instance.new("Frame")
	bar.BorderSizePixel = 0
	bar.BackgroundColor3 = Color3.new(1, 1, 1)
	bar.Size = UDim2.new(0, 3, 1, 0)
	bar.Position = UDim2.fromOffset(0, 0)
	bar.Parent = card
	round(bar, 2)
	gradient(bar, color, Theme.AccentDeep, 90)

	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.new(1, -8, 0, 18)
	t.Position = UDim2.fromOffset(8, 0)
	t.Font = Enum.Font.GothamBold
	t.TextSize = 13
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.TextColor3 = Theme.Text
	t.Text = title
	t.Parent = card

	local c = Instance.new("TextLabel")
	c.BackgroundTransparency = 1
	c.Size = UDim2.new(1, -8, 0, 0)
	c.AutomaticSize = Enum.AutomaticSize.Y
	c.Position = UDim2.fromOffset(8, 20)
	c.Font = Enum.Font.Gotham
	c.TextSize = 12
	c.TextXAlignment = Enum.TextXAlignment.Left
	c.TextYAlignment = Enum.TextYAlignment.Top
	c.TextWrapped = true
	c.TextColor3 = Theme.Muted
	c.Text = content
	c.Parent = card

	tween(card, { BackgroundTransparency = 0 }, 0.25)
	task.delay(duration, function()
		if card and card.Parent then
			tween(card, { BackgroundTransparency = 1 }, 0.2)
			task.wait(0.22)
			card:Destroy()
		end
	end)
end

function Library:SetFlag(name, value)
	if type(name) == "string" and name ~= "" then
		self._flags[name] = value
	end
end

function Library:GetFlag(name)
	return self._flags[name]
end

function Library:CreateWindow(opts)
	opts = opts or {}
	-- Drop stale toggle peers from prior injects (fixes checks that won't turn off)
	self._flagLinks = {}
	local title = opts.Title or "ScriptVerse"
	local subtitle = opts.SubTitle or opts.Subtitle or ""
	local compact = opts.Compact == false and false or isCompact()
	local touchUi = compact or UserInputService.TouchEnabled
	local winW = opts.Width or (compact and math.clamp(math.floor(viewport().X * 0.94), 320, 540) or 660)
	local winH = opts.Height or (compact and math.clamp(math.floor(viewport().Y * 0.78), 380, 580) or 540)
	local sideW = compact and 118 or 172
	local columnMode = opts.Columns
	local useTwoCol = columnMode ~= 1

	-- destroy previous same-name
	for _, w in ipairs(self.Windows) do
		if w._title == title and w.Gui and w.Gui.Parent then
			w:Destroy()
		end
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "ZenithEGG_UI"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 5000
	protectGui(gui)

	-- Soft steel glow behind the window
	local glowWrap = Instance.new("Frame")
	glowWrap.Name = "GlowWrap"
	glowWrap.AnchorPoint = Vector2.new(0.5, 0.5)
	glowWrap.Position = UDim2.fromScale(0.5, 0.5)
	glowWrap.Size = UDim2.fromOffset(winW, winH)
	glowWrap.BackgroundTransparency = 1
	glowWrap.Parent = gui
	round(glowWrap, 18)
	softShadow(glowWrap, 22)
	local glowStroke = Instance.new("UIStroke")
	glowStroke.Color = Theme.AccentBright
	glowStroke.Thickness = 2
	glowStroke.Transparency = 0.62
	glowStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	glowStroke.Parent = glowWrap
	local glowStroke2 = Instance.new("UIStroke")
	glowStroke2.Color = Theme.Accent
	glowStroke2.Thickness = 5
	glowStroke2.Transparency = 0.9
	glowStroke2.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	glowStroke2.Parent = glowWrap

	local root = Instance.new("Frame")
	root.Name = "Window"
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Position = UDim2.fromScale(0.5, 0.5)
	root.Size = UDim2.fromOffset(winW, winH)
	root.BackgroundColor3 = Theme.Bg
	root.BorderSizePixel = 0
	root.BackgroundTransparency = 0
	root.ClipsDescendants = true
	root.Parent = gui
	round(root, 16)
	-- NEVER put UIGradient on CanvasGroup — it tints every child and washes the UI out
	local rootBg = Instance.new("Frame")
	rootBg.Name = "RootBg"
	rootBg.BackgroundColor3 = Color3.new(1, 1, 1)
	rootBg.BorderSizePixel = 0
	rootBg.Size = UDim2.fromScale(1, 1)
	rootBg.ZIndex = 1
	rootBg.Parent = root
	round(rootBg, 16)
	gradient(rootBg, Color3.fromRGB(14, 20, 32), Color3.fromRGB(8, 12, 20), 120)
	local rootStroke = stroke(root, Theme.Border, 1, 0.05)
	local rootAccent = Instance.new("UIStroke")
	rootAccent.Color = Theme.AccentBright
	rootAccent.Thickness = 1.25
	rootAccent.Transparency = 0.45
	rootAccent.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	rootAccent.Parent = root

	-- Top linear sheen (steel highlight bar)
	local topSheen = Instance.new("Frame")
	topSheen.Name = "TopSheen"
	topSheen.BackgroundColor3 = Color3.new(1, 1, 1)
	topSheen.BorderSizePixel = 0
	topSheen.Size = UDim2.new(1, 0, 0, 3)
	topSheen.ZIndex = 8
	topSheen.Parent = root
	gradient(topSheen, Theme.AccentDeep, Theme.AccentBright, 0)

	local scale = Instance.new("UISizeConstraint")
	scale.MinSize = Vector2.new(280, 300)
	scale.MaxSize = Vector2.new(900, 720)
	scale.Parent = root

	local footH = 24

	-- Body (Obsidian-style: sidebar brand + content search bar)
	local body = Instance.new("Frame")
	body.Name = "Body"
	body.BackgroundTransparency = 1
	body.Position = UDim2.fromOffset(0, 0)
	body.Size = UDim2.new(1, 0, 1, -footH)
	body.Parent = root

	local sideShell = Instance.new("Frame")
	sideShell.Name = "SidebarShell"
	sideShell.BackgroundColor3 = Color3.new(1, 1, 1)
	sideShell.BorderSizePixel = 0
	sideShell.Size = UDim2.new(0, sideW, 1, 0)
	sideShell.ClipsDescendants = true
	sideShell.Parent = body
	gradient(sideShell, Color3.fromRGB(12, 18, 28), Color3.fromRGB(8, 12, 20), 180)

	-- Left steel rail
	local sideRail = Instance.new("Frame")
	sideRail.Name = "SteelRail"
	sideRail.BackgroundColor3 = Color3.new(1, 1, 1)
	sideRail.BorderSizePixel = 0
	sideRail.Size = UDim2.new(0, 3, 1, 0)
	sideRail.ZIndex = 3
	sideRail.Parent = sideShell
	gradient(sideRail, Theme.AccentBright, Theme.AccentDeep, 90)

	local sideLine = Instance.new("Frame")
	sideLine.BackgroundColor3 = Theme.Border
	sideLine.BackgroundTransparency = 0.25
	sideLine.BorderSizePixel = 0
	sideLine.Size = UDim2.new(0, 1, 1, 0)
	sideLine.Position = UDim2.new(1, -1, 0, 0)
	sideLine.ZIndex = 2
	sideLine.Parent = sideShell

	local sideBrand = Instance.new("Frame")
	sideBrand.Name = "Brand"
	sideBrand.BackgroundTransparency = 1
	local brandH = compact and 58 or 70
	sideBrand.Size = UDim2.new(1, 0, 0, brandH)
	sideBrand.Parent = sideShell

	local logo = Instance.new("ImageLabel")
	logo.BackgroundColor3 = Theme.AccentDim
	logo.BackgroundTransparency = 0
	logo.Size = UDim2.fromOffset(compact and 28 or 34, compact and 28 or 34)
	logo.Position = UDim2.fromOffset(14, compact and 12 or 12)
	logo.ScaleType = Enum.ScaleType.Fit
	logo.Parent = sideBrand
	round(logo, 9)
	stroke(logo, Theme.AccentBright, 1, 0.45)
	pad(logo, 3, 3, 3, 3)
	applyLogo(logo)

	local brandTitle = Instance.new("TextLabel")
	brandTitle.BackgroundTransparency = 1
	brandTitle.Position = UDim2.fromOffset(compact and 48 or 56, compact and 10 or 10)
	brandTitle.Size = UDim2.new(1, -60, 0, 18)
	brandTitle.TextSize = compact and 14 or 16
	brandTitle.TextXAlignment = Enum.TextXAlignment.Left
	brandTitle.TextColor3 = Theme.Text
	brandTitle.TextTruncate = Enum.TextTruncate.AtEnd
	brandTitle.RichText = true
	applyFont(brandTitle, "bold")
	if title:lower():find("scriptverse", 1, true) then
		brandTitle.Text = 'Script<font color="#6EB4E8">Verse</font>'
	else
		brandTitle.Text = title
	end
	brandTitle.Parent = sideBrand

	local brandSub = Instance.new("TextLabel")
	brandSub.BackgroundTransparency = 1
	brandSub.Position = UDim2.fromOffset(compact and 48 or 56, compact and 28 or 32)
	brandSub.Size = UDim2.new(1, -60, 0, 32)
	brandSub.TextSize = 10
	brandSub.TextXAlignment = Enum.TextXAlignment.Left
	brandSub.TextYAlignment = Enum.TextYAlignment.Top
	brandSub.TextWrapped = true
	brandSub.TextTruncate = Enum.TextTruncate.None
	brandSub.TextColor3 = Theme.Steel
	brandSub.Text = subtitle ~= "" and subtitle or "Hub"
	brandSub.Parent = sideBrand

	local brandLine = Instance.new("Frame")
	brandLine.BackgroundColor3 = Color3.new(1, 1, 1)
	brandLine.BorderSizePixel = 0
	brandLine.Size = UDim2.new(1, -16, 0, 2)
	brandLine.AnchorPoint = Vector2.new(0, 1)
	brandLine.Position = UDim2.new(0, 8, 1, 0)
	brandLine.Parent = sideBrand
	gradient(brandLine, Theme.AccentDeep, Theme.AccentBright, 0)

	local sidebar = Instance.new("ScrollingFrame")
	sidebar.Name = "Sidebar"
	sidebar.BackgroundTransparency = 1
	sidebar.BorderSizePixel = 0
	sidebar.Position = UDim2.fromOffset(0, brandH)
	sidebar.Size = UDim2.new(1, 0, 1, -brandH)
	sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
	sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
	sidebar.ScrollBarThickness = 2
	sidebar.ScrollBarImageColor3 = Theme.Accent
	sidebar.ScrollingDirection = Enum.ScrollingDirection.Y
	sidebar.Parent = sideShell

	local sideList = Instance.new("UIListLayout")
	sideList.Padding = UDim.new(0, 4)
	sideList.SortOrder = Enum.SortOrder.LayoutOrder
	sideList.Parent = sidebar
	pad(sidebar, 8, 8, 10, 8)

	local contentHost = Instance.new("Frame")
	contentHost.Name = "ContentHost"
	contentHost.BackgroundTransparency = 1
	contentHost.Position = UDim2.fromOffset(sideW, 0)
	contentHost.Size = UDim2.new(1, -sideW, 1, 0)
	contentHost.ClipsDescendants = true
	contentHost.Parent = body

	local topH = compact and 44 or 48
	local contentTop = Instance.new("Frame")
	contentTop.Name = "ContentTop"
	contentTop.BackgroundColor3 = Theme.Bg
	contentTop.BorderSizePixel = 0
	contentTop.Size = UDim2.new(1, 0, 0, topH)
	contentTop.Parent = contentHost
	pad(contentTop, 8, 10, 6, 12)

	local function makeHeaderBtn(x, glyph, bg, hoverBg, textColor, size)
		local sz = size or (touchUi and 32 or 28)
		local b = Instance.new("TextButton")
		b.AnchorPoint = Vector2.new(1, 0.5)
		b.Position = UDim2.new(1, x, 0.5, 0)
		b.Size = UDim2.fromOffset(sz, sz)
		b.BackgroundColor3 = bg or Theme.Surface2
		b.BorderSizePixel = 0
		b.AutoButtonColor = false
		b.Font = Enum.Font.GothamBold
		b.TextSize = touchUi and 16 or 14
		b.TextColor3 = textColor or Theme.Muted
		b.Text = glyph
		b.Parent = contentTop
		round(b, 8)
		stroke(b, Theme.Border, 1, 0.45)
		b.MouseEnter:Connect(function()
			tween(b, { BackgroundColor3 = hoverBg or Theme.AccentDim, TextColor3 = Theme.AccentBright }, 0.15)
		end)
		b.MouseLeave:Connect(function()
			tween(b, { BackgroundColor3 = bg or Theme.Surface2, TextColor3 = textColor or Theme.Muted }, 0.15)
		end)
		return b
	end

	local btnPad = 8
	local btnW = touchUi and 36 or 32

	local searchWrap = Instance.new("Frame")
	searchWrap.BackgroundColor3 = Theme.Surface
	searchWrap.BorderSizePixel = 0
	searchWrap.AnchorPoint = Vector2.new(0, 0.5)
	searchWrap.Position = UDim2.new(0, 0, 0.5, 0)
	searchWrap.Size = UDim2.new(1, -(btnW * 2 + btnPad * 2 + 8), 0, compact and 30 or 32)
	searchWrap.Parent = contentTop
	round(searchWrap, 9)
	local searchStroke = stroke(searchWrap, Theme.Border, 1, 0.28)
	local searchSheen = Instance.new("Frame")
	searchSheen.BackgroundColor3 = Color3.new(1, 1, 1)
	searchSheen.BackgroundTransparency = 0.92
	searchSheen.BorderSizePixel = 0
	searchSheen.Size = UDim2.new(1, 0, 0, 1)
	searchSheen.Parent = searchWrap
	gradient(searchSheen, Theme.AccentBright, Theme.AccentDeep, 0)

	local searchIcon = Instance.new("ImageLabel")
	searchIcon.BackgroundTransparency = 1
	searchIcon.AnchorPoint = Vector2.new(0, 0.5)
	searchIcon.Size = UDim2.fromOffset(14, 14)
	searchIcon.Position = UDim2.new(0, 10, 0.5, 0)
	searchIcon.Image = "rbxassetid://10734943674"
	searchIcon.ImageColor3 = Theme.Muted
	searchIcon.ScaleType = Enum.ScaleType.Fit
	searchIcon.Parent = searchWrap

	local searchBox = Instance.new("TextBox")
	searchBox.BackgroundTransparency = 1
	searchBox.Position = UDim2.fromOffset(30, 0)
	searchBox.Size = UDim2.new(1, -72, 1, 0)
	searchBox.ClearTextOnFocus = false
	searchBox.Font = Enum.Font.Gotham
	searchBox.TextSize = 13
	applyFont(searchBox, "semi")
	searchBox.TextColor3 = Theme.Text
	searchBox.PlaceholderColor3 = Theme.Muted
	searchBox.PlaceholderText = "Search"
	searchBox.Text = ""
	searchBox.TextXAlignment = Enum.TextXAlignment.Left
	searchBox.TextTruncate = Enum.TextTruncate.AtEnd
	searchBox.Parent = searchWrap

	local searchCount = Instance.new("TextLabel")
	searchCount.BackgroundTransparency = 1
	searchCount.AnchorPoint = Vector2.new(1, 0.5)
	searchCount.Position = UDim2.new(1, -28, 0.5, 0)
	searchCount.Size = UDim2.fromOffset(24, 14)
	searchCount.Font = Enum.Font.GothamBold
	searchCount.TextSize = 10
	searchCount.TextColor3 = Theme.AccentBright
	searchCount.TextXAlignment = Enum.TextXAlignment.Right
	searchCount.Text = ""
	searchCount.Visible = false
	searchCount.Parent = searchWrap

	local searchClear = Instance.new("TextButton")
	searchClear.AutoButtonColor = false
	searchClear.BackgroundTransparency = 1
	searchClear.AnchorPoint = Vector2.new(1, 0.5)
	searchClear.Position = UDim2.new(1, -6, 0.5, 0)
	searchClear.Size = UDim2.fromOffset(20, 20)
	searchClear.Font = Enum.Font.GothamBold
	searchClear.TextSize = 13
	searchClear.TextColor3 = Theme.Muted
	searchClear.Text = "×"
	searchClear.Visible = false
	searchClear.Parent = searchWrap

	makeDraggable(sideBrand, root, { glowWrap })

	local closeBtn = makeHeaderBtn(-btnPad, "×", Theme.Surface2, Theme.AccentDim, Theme.Text, nil)
	local minBtn = makeHeaderBtn(-(btnPad + btnW + 4), "−", Theme.Surface2, Theme.AccentDim, Theme.Text, nil)
	closeBtn.ZIndex = 20
	minBtn.ZIndex = 20

	local topDivider = Instance.new("Frame")
	topDivider.Name = "TopDivider"
	topDivider.BackgroundColor3 = Color3.new(1, 1, 1)
	topDivider.BorderSizePixel = 0
	topDivider.Size = UDim2.new(1, 0, 0, 2)
	topDivider.Position = UDim2.fromOffset(0, topH)
	topDivider.Parent = contentHost
	gradient(topDivider, Theme.AccentDeep, Theme.AccentBright, 0)

	local pageMount = Instance.new("Frame")
	pageMount.Name = "Pages"
	pageMount.BackgroundTransparency = 1
	pageMount.Position = UDim2.fromOffset(0, topH + 2)
	pageMount.Size = UDim2.new(1, 0, 1, -(topH + 2))
	pageMount.ClipsDescendants = true
	pageMount.Parent = contentHost
	local emptyLbl = Instance.new("TextLabel")
	emptyLbl.BackgroundTransparency = 1
	emptyLbl.Size = UDim2.fromScale(1, 1)
	emptyLbl.Font = Enum.Font.Gotham
	emptyLbl.TextSize = 13
	emptyLbl.TextColor3 = Theme.Muted
	emptyLbl.Text = "Nothing matches"
	emptyLbl.Visible = false
	emptyLbl.ZIndex = 6
	emptyLbl.Parent = pageMount

	local foot = Instance.new("Frame")
	foot.Name = "Footer"
	foot.BackgroundColor3 = Color3.new(1, 1, 1)
	foot.BorderSizePixel = 0
	foot.AnchorPoint = Vector2.new(0, 1)
	foot.Position = UDim2.new(0, 0, 1, 0)
	foot.Size = UDim2.new(1, 0, 0, footH)
	foot.Parent = root
	gradient(foot, Color3.fromRGB(12, 18, 28), Color3.fromRGB(8, 12, 20), 0)
	local footLine = Instance.new("Frame")
	footLine.BackgroundColor3 = Color3.new(1, 1, 1)
	footLine.BorderSizePixel = 0
	footLine.Size = UDim2.new(1, 0, 0, 2)
	footLine.Parent = foot
	gradient(footLine, Theme.AccentBright, Theme.AccentDeep, 0)
	local statsLbl = Instance.new("TextLabel")
	statsLbl.BackgroundTransparency = 1
	statsLbl.Size = UDim2.fromScale(1, 1)
	statsLbl.Font = Enum.Font.Gotham
	statsLbl.TextSize = 11
	statsLbl.TextColor3 = Theme.Steel
	statsLbl.TextXAlignment = Enum.TextXAlignment.Center
	local footGame = subtitle ~= "" and subtitle or title
	statsLbl.Text = footGame .. "   ·   FPS --   ·   -- ms"
	statsLbl.Parent = foot

	-- Floating restore bubble (shown while minimized)
	local bubble = Instance.new("TextButton")
	bubble.Name = "RestoreBubble"
	bubble.AutoButtonColor = false
	bubble.Visible = false
	bubble.AnchorPoint = Vector2.new(0, 0.5)
	bubble.Position = UDim2.new(0, 16, 0.5, 0)
	bubble.Size = UDim2.fromOffset(148, 48)
	bubble.BackgroundColor3 = Color3.new(1, 1, 1)
	bubble.BorderSizePixel = 0
	bubble.Text = ""
	bubble.ZIndex = 50
	bubble.Parent = gui
	round(bubble, 14)
	stroke(bubble, Theme.AccentBright, 1.5, 0.2)
	gradient(bubble, Color3.fromRGB(16, 24, 36), Color3.fromRGB(10, 16, 26), 90)

	local bubbleGlow = Instance.new("Frame")
	bubbleGlow.BackgroundColor3 = Color3.new(1, 1, 1)
	bubbleGlow.BackgroundTransparency = 0.88
	bubbleGlow.BorderSizePixel = 0
	bubbleGlow.Size = UDim2.fromScale(1, 1)
	bubbleGlow.ZIndex = 50
	bubbleGlow.Parent = bubble
	round(bubbleGlow, 14)
	gradient(bubbleGlow, Theme.AccentBright, Theme.AccentDeep, 0)

	local bubbleLogo = Instance.new("ImageLabel")
	bubbleLogo.BackgroundTransparency = 1
	bubbleLogo.Size = UDim2.fromOffset(30, 30)
	bubbleLogo.Position = UDim2.fromOffset(10, 9)
	bubbleLogo.ScaleType = Enum.ScaleType.Fit
	bubbleLogo.ZIndex = 51
	bubbleLogo.Parent = bubble
	applyLogo(bubbleLogo)

	local bubbleTitle = Instance.new("TextLabel")
	bubbleTitle.BackgroundTransparency = 1
	bubbleTitle.Position = UDim2.fromOffset(46, 8)
	bubbleTitle.Size = UDim2.new(1, -54, 0, 16)
	bubbleTitle.Font = Enum.Font.GothamBold
	bubbleTitle.TextSize = 12
	bubbleTitle.TextXAlignment = Enum.TextXAlignment.Left
	bubbleTitle.TextColor3 = Theme.Text
	bubbleTitle.TextTruncate = Enum.TextTruncate.AtEnd
	bubbleTitle.Text = "Zenith EGG"
	bubbleTitle.ZIndex = 51
	bubbleTitle.Parent = bubble

	local bubbleHint = Instance.new("TextLabel")
	bubbleHint.BackgroundTransparency = 1
	bubbleHint.Position = UDim2.fromOffset(46, 24)
	bubbleHint.Size = UDim2.new(1, -54, 0, 14)
	bubbleHint.Font = Enum.Font.Gotham
	bubbleHint.TextSize = 10
	bubbleHint.TextXAlignment = Enum.TextXAlignment.Left
	bubbleHint.TextColor3 = Theme.AccentBright
	bubbleHint.Text = "Tap to restore"
	bubbleHint.ZIndex = 51
	bubbleHint.Parent = bubble

	makeDraggable(bubble, bubble)

	local Window = {
		Gui = gui,
		Root = root,
		Glow = glowWrap,
		Bubble = bubble,
		_title = title,
		_tabs = {},
		_selected = nil,
		_minimized = false,
		_visible = true,
		_conn = {},
		_entries = {},
		_searchQ = "",
		_groups = {},
		_columnMode = columnMode,
		_minSectionsTwoCol = opts.MinSectionsForTwoCol or 3,
		_onClose = opts.OnClose,
	}

	function Window:SetVisible(v)
		self._visible = v and true or false
		local show = self._visible
		if self._minimized then
			root.Visible = false
			glowWrap.Visible = false
			bubble.Visible = show
		else
			root.Visible = show
			glowWrap.Visible = show
			bubble.Visible = false
		end
	end

	function Window:Minimize(state)
		if state == nil then
			state = not self._minimized
		end
		self._minimized = state and true or false
		if self._minimized then
			root.Visible = false
			glowWrap.Visible = false
			bubble.Visible = self._visible
			tween(bubble, { BackgroundTransparency = 0 }, 0.2)
		else
			bubble.Visible = false
			root.Visible = self._visible
			glowWrap.Visible = self._visible
			root.Visible = true
		end
	end

	function Window:Destroy()
		for _, c in ipairs(self._conn or {}) do
			pcall(function()
				c:Disconnect()
			end)
		end
		self._conn = {}
		if type(self._onClose) == "function" then
			pcall(self._onClose)
		end
		if bubble and bubble.Parent then
			bubble:Destroy()
		end
		if gui and gui.Parent then
			gui:Destroy()
		end
		for i, w in ipairs(Library.Windows) do
			if w == self then
				table.remove(Library.Windows, i)
				break
			end
		end
	end

	do
		local fpsAcc, fpsN = 0, 0
		local animT0 = os.clock()
		table.insert(
			Window._conn,
			RunService.RenderStepped:Connect(function(dt)
				local t = os.clock() - animT0
				local phase = (t * 0.28) % 1
				glowStroke.Transparency = 0.68 + math.sin(t * 1.15) * 0.06
				glowStroke2.Transparency = 0.92 + math.sin(t * 1.15 + 0.8) * 0.04
				rootAccent.Transparency = 0.72 + math.sin(t * 0.9) * 0.06

				fpsAcc = fpsAcc + (1 / math.max(dt, 1 / 240))
				fpsN = fpsN + 1
				if fpsN >= 10 then
					local fps = math.floor(fpsAcc / fpsN + 0.5)
					fpsAcc, fpsN = 0, 0
					local ping = 0
					pcall(function()
						ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5)
					end)
					statsLbl.Text = string.format("%s   ·   FPS %d   ·   %d ms   ·   Right Shift hide", footGame, fps, ping)
				end
			end)
		)
	end

	bubble.MouseButton1Click:Connect(function()
		Window:Minimize(false)
	end)

	function Window:SelectTab(tab)
		for _, t in ipairs(self._tabs) do
			local on = t == tab
			if t._shell then
				t._shell.Visible = on
			elseif t._page then
				t._page.Visible = on
			end
			if t._btn then
				if t._tabGrad then
					t._tabGrad.Enabled = on
				end
				t._btn.BackgroundColor3 = on and Color3.new(1, 1, 1) or Theme.Surface
				t._btn.BackgroundTransparency = on and 0 or 0.35
				if t._btnStroke then
					t._btnStroke.Color = on and Theme.AccentBright or Theme.Border
					t._btnStroke.Transparency = on and 0.35 or 0.7
				end
				if t._btnText then
					t._btnText.TextColor3 = on and Theme.Text or Theme.Muted
				end
				if t._iconBadge then
					t._iconBadge.BackgroundColor3 = on and Theme.Accent or Theme.Surface2
				end
				if t._iconImg then
					t._iconImg.ImageColor3 = on and Theme.Text or Theme.AccentBright
				end
				if t._indicator then
					t._indicator.BackgroundTransparency = on and 0 or 1
				end
			end
		end
		self._selected = tab
		if type(self._applySearch) == "function" then
			self:_applySearch(self._searchQ, true)
		end
	end

	function Window:_applySearch(raw, keepTab)
		local q = searchKey(raw or "")
		self._searchQ = q
		local hasQ = q ~= ""
		searchClear.Visible = hasQ
		searchStroke.Color = hasQ and Theme.AccentBright or Theme.Border
		searchStroke.Transparency = hasQ and 0.05 or 0.25
		searchIcon.ImageColor3 = hasQ and Theme.AccentBright or Theme.Muted

		local hitsByTab = {}
		local hitsByPage = {}
		local visibleItems = 0
		for _, e in ipairs(self._entries) do
			e._hit = (not hasQ) or (string.find(e.text, q, 1, true) ~= nil)
			if e.kind ~= "section" and e.kind ~= "divider" and e._hit then
				visibleItems = visibleItems + 1
				hitsByTab[e.tab] = (hitsByTab[e.tab] or 0) + 1
				if e.page then
					hitsByPage[e.page] = (hitsByPage[e.page] or 0) + 1
				end
			end
		end

		local byTab = {}
		for _, e in ipairs(self._entries) do
			byTab[e.tab] = byTab[e.tab] or {}
			table.insert(byTab[e.tab], e)
		end
		for tab, list in pairs(byTab) do
			for i, e in ipairs(list) do
				if e.kind == "section" then
					local show = (not hasQ) or e._hit
					if not show then
						for j = i + 1, #list do
							if list[j].kind == "section" then
								break
							end
							if list[j]._hit then
								show = true
								break
							end
						end
					end
					e.frame.Visible = show
					if e.body then
						if hasQ and show then
							e.body.Visible = true
							if e.chev then
								e.chev.Rotation = 0
							end
						end
					end
				elseif e.kind == "divider" then
					e.frame.Visible = not hasQ
				else
					e.frame.Visible = e._hit
				end
			end
		end

		if hasQ then
			searchCount.Visible = true
			searchCount.Text = tostring(visibleItems)
		else
			searchCount.Visible = false
			searchCount.Text = ""
		end

		local firstHit = nil
		for _, t in ipairs(self._tabs) do
			local n = hitsByTab[t] or 0
			local showBtn = (not hasQ) or n > 0
			if t._group and t._group.open == false and not hasQ then
				showBtn = false
			end
			if t._btn then
				t._btn.Visible = showBtn
			end
			if hasQ and t._group then
				t._group.open = true
			end
			if n > 0 and not firstHit then
				firstHit = t
			end
			if t._subs and #t._subs > 0 then
				local pick = nil
				for _, sub in ipairs(t._subs) do
					if (hitsByPage[sub.page] or 0) > 0 then
						pick = pick or sub
					end
				end
				if hasQ and pick and t == (keepTab and self._selected or firstHit or t) then
					for _, sub in ipairs(t._subs) do
						sub.page.Visible = sub == pick
						if sub.pill then
							sub.pill.BackgroundColor3 = (sub == pick) and Theme.Accent or Theme.Surface2
							sub.pill.TextColor3 = (sub == pick) and Theme.Text or Theme.Muted
						end
					end
				end
			end
		end
		for _, g in pairs(self._groups) do
			local any = false
			for _, t in ipairs(g.tabs or {}) do
				if t._btn and t._btn.Visible then
					any = true
					break
				end
			end
			if g.header then
				g.header.Visible = (not hasQ) or any
			end
		end

		if hasQ and firstHit and not keepTab then
			if self._selected ~= firstHit then
				self:SelectTab(firstHit)
				return
			end
		end

		local cur = self._selected
		local curHits = cur and (hitsByTab[cur] or 0) or 0
		emptyLbl.Visible = hasQ and curHits == 0
	end

	local groupSeq = 0
	local function ensureGroup(name)
		name = tostring(name or "")
		if name == "" then
			return nil
		end
		local key = string.lower(name)
		local g = Window._groups[key]
		if g then
			return g
		end
		groupSeq = groupSeq + 1
		local header = Instance.new("TextButton")
		header.AutoButtonColor = false
		header.BackgroundTransparency = 1
		header.Size = UDim2.new(1, 0, 0, 20)
		header.LayoutOrder = groupSeq * 100
		header.Font = Enum.Font.GothamBold
		header.TextSize = 11
		header.TextColor3 = Theme.Muted
		header.TextXAlignment = Enum.TextXAlignment.Left
		header.Text = ""
		header.Parent = sidebar
		local gl = Instance.new("TextLabel")
		gl.BackgroundTransparency = 1
		gl.Position = UDim2.fromOffset(4, 0)
		gl.Size = UDim2.new(1, -4, 1, 0)
		gl.Font = Enum.Font.GothamBold
		gl.TextSize = 11
		gl.TextColor3 = Theme.AccentBright
		gl.TextXAlignment = Enum.TextXAlignment.Left
		gl.Text = string.upper(name)
		gl.Parent = header
		g = { header = header, open = true, tabs = {}, order = groupSeq, _label = gl }
		Window._groups[key] = g
		header.MouseButton1Click:Connect(function()
			g.open = not g.open
			gl.TextTransparency = g.open and 0 or 0.35
			for _, t in ipairs(g.tabs) do
				if t._btn then
					t._btn.Visible = g.open
				end
			end
		end)
		return g
	end

	searchBox.Focused:Connect(function()
		searchStroke.Color = Theme.AccentBright
		searchStroke.Transparency = 0.05
		searchIcon.ImageColor3 = Theme.AccentBright
	end)
	searchBox.FocusLost:Connect(function()
		if searchKey(searchBox.Text) == "" then
			searchStroke.Color = Theme.Border
			searchStroke.Transparency = 0.25
			searchIcon.ImageColor3 = Theme.Muted
		end
	end)
	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		Window:_applySearch(searchBox.Text, false)
	end)
	searchClear.MouseButton1Click:Connect(function()
		searchBox.Text = ""
		searchBox:CaptureFocus()
	end)
	table.insert(
		Window._conn,
		UserInputService.InputBegan:Connect(function(input, gp)
			if gp or not Window._visible or Window._minimized then
				return
			end
			if input.KeyCode == Enum.KeyCode.F and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
				searchBox:CaptureFocus()
			end
		end)
	)

	-- Fluent Lucide icon assets (verified rbxassetids)
	local IconAssets = {
		eye = "rbxassetid://10723346959",
		user = "rbxassetid://10747373176",
		users = "rbxassetid://10747373426",
		zap = "rbxassetid://10709752035", -- activity
		activity = "rbxassetid://10709752035",
		sword = "rbxassetid://10734975486",
		swords = "rbxassetid://10734975692",
		settings = "rbxassetid://10734950309",
		home = "rbxassetid://10709751939",
		box = "rbxassetid://10709782497",
		hammer = "rbxassetid://10723405360",
		target = "rbxassetid://10734931806",
		skull = "rbxassetid://10734962068",
		heart = "rbxassetid://10723415302",
		map = "rbxassetid://10734886202",
		sparkles = "rbxassetid://10734966248", -- lucide-star (old sparkles id was broken)
		star = "rbxassetid://10734966248",
		stars = "rbxassetid://10734966248",
		trail = "rbxassetid://10747382750", -- lucide-wind
		trails = "rbxassetid://10747382750",
		wind = "rbxassetid://10747382750",
		wand = "rbxassetid://10747376565",
		flame = "rbxassetid://10723376114",
		aura = "rbxassetid://10709752035", -- activity/zap
		play = "rbxassetid://10734886248",
		wrench = "rbxassetid://10747383470",
		shield = "rbxassetid://10734951847",
		crosshair = "rbxassetid://10709818534",
		gamepad = "rbxassetid://10723395708",
		move = "rbxassetid://10734900011",
		shoppingcart = "rbxassetid://10734952479",
		shop = "rbxassetid://10734952479",
		cart = "rbxassetid://10734952479",
		shoppingbag = "rbxassetid://10734952273",
		package = "rbxassetid://10734909540",
		bell = "rbxassetid://10709775704",
		visuals = "rbxassetid://10723346959",
		survivor = "rbxassetid://10747383470",
		killer = "rbxassetid://10734975486",
		player = "rbxassetid://10709752035",
		world = "rbxassetid://10734886202",
		misc = "rbxassetid://10734950309",
		search = "rbxassetid://10734943674",
		combat = "rbxassetid://10734975692",
		visual = "rbxassetid://10723346959",
		movement = "rbxassetid://10734900011",
		aim = "rbxassetid://10709818534",
		character = "rbxassetid://10747373176",
		weapons = "rbxassetid://10734975486",
		farm = "rbxassetid://10709782497",
		hay = "rbxassetid://10709782497",
		wheat = "rbxassetid://10709782497",
		tools = "rbxassetid://10747383470",
		tool = "rbxassetid://10747383470",
		needle = "rbxassetid://10734931806",
		gem = "rbxassetid://10734966248",
		gems = "rbxassetid://10734966248",
		drone = "rbxassetid://10747382750",
		dynamite = "rbxassetid://10723376114",
		tnt = "rbxassetid://10723376114",
		pitchfork = "rbxassetid://10723405360",
		sell = "rbxassetid://10734952479",
	}

	local function resolveIcon(icon)
		if type(icon) ~= "string" or icon == "" then
			return IconAssets.home
		end
		if string.find(icon, "rbxasset", 1, true) then
			return icon
		end
		local asId = tonumber(icon)
		if asId then
			return "rbxassetid://" .. tostring(asId)
		end
		local key = string.lower(icon):gsub("%s+", "")
		return IconAssets[key] or IconAssets.home
	end

	-- ContentProvider preload removed for zero lag
	end)

	function Window:CreateTab(tabOpts)
		tabOpts = tabOpts or {}
		local tabTitle = tabOpts.Title or tabOpts.Name or "Tab"
		local iconAsset = resolveIcon(tabOpts.Icon or tabTitle)
		local group = ensureGroup(tabOpts.Group or tabOpts.Category)
		local order
		if group then
			order = group.order * 100 + (#group.tabs + 1)
		else
			order = #self._tabs + 1
		end

		local btn = Instance.new("TextButton")
		btn.BackgroundColor3 = Theme.Surface
		btn.BackgroundTransparency = 0.35
		btn.BorderSizePixel = 0
		btn.AutoButtonColor = false
		btn.Size = UDim2.new(1, 0, 0, compact and 40 or 38)
		btn.Text = ""
		btn.LayoutOrder = order
		btn.Parent = sidebar
		round(btn, 10)
		local btnStroke = stroke(btn, Theme.Border, 1, 0.7)
		local tabGrad = gradient(btn, Theme.AccentDeep, Theme.Accent, 0)
		tabGrad.Enabled = false

		local iconBadge = Instance.new("Frame")
		iconBadge.BackgroundColor3 = Theme.Surface2
		iconBadge.BorderSizePixel = 0
		iconBadge.Size = UDim2.fromOffset(24, 24)
		iconBadge.Position = UDim2.fromOffset(10, compact and 8 or 7)
		iconBadge.Parent = btn
		round(iconBadge, 8)
		stroke(iconBadge, Theme.Border, 1, 0.55)

		local iconImg = Instance.new("ImageLabel")
		iconImg.BackgroundTransparency = 1
		iconImg.AnchorPoint = Vector2.new(0.5, 0.5)
		iconImg.Position = UDim2.fromScale(0.5, 0.5)
		iconImg.Size = UDim2.fromOffset(16, 16)
		iconImg.Image = iconAsset
		iconImg.ImageColor3 = Theme.AccentBright
		iconImg.ImageTransparency = 0
		iconImg.ScaleType = Enum.ScaleType.Fit
		iconImg.Parent = iconBadge
		pcall(function()
			iconImg.ResampleMode = Enum.ResamplerMode.Default
		end)

		local btnText = Instance.new("TextLabel")
		btnText.BackgroundTransparency = 1
		btnText.Position = UDim2.fromOffset(38, 0)
		btnText.Size = UDim2.new(1, -44, 1, 0)
		btnText.Font = Enum.Font.GothamBold
		btnText.TextSize = compact and 12 or 13
		applyFont(btnText, "semi")
		btnText.TextColor3 = Theme.Muted
		btnText.TextXAlignment = Enum.TextXAlignment.Left
		btnText.TextTruncate = Enum.TextTruncate.AtEnd
		btnText.Text = tabTitle
		btnText.Parent = btn

		local indicator = Instance.new("Frame")
		indicator.BackgroundColor3 = Color3.new(1, 1, 1)
		indicator.BorderSizePixel = 0
		indicator.Size = UDim2.new(0, 3, 0.72, 0)
		indicator.AnchorPoint = Vector2.new(0, 0.5)
		indicator.Position = UDim2.new(0, 0, 0.5, 0)
		indicator.BackgroundTransparency = 1
		indicator.Parent = btn
		round(indicator, 2)
		gradient(indicator, Theme.AccentBright, Theme.AccentDeep, 90)

		local shell = Instance.new("Frame")
		shell.Name = "Tab_" .. tabTitle
		shell.BackgroundTransparency = 1
		shell.Size = UDim2.fromScale(1, 1)
		shell.Visible = false
		shell.ClipsDescendants = true
		shell.Parent = pageMount

		local subRail = Instance.new("ScrollingFrame")
		subRail.Name = "SubTabs"
		subRail.BackgroundTransparency = 1
		subRail.BorderSizePixel = 0
		subRail.Size = UDim2.new(1, 0, 0, 0)
		subRail.CanvasSize = UDim2.new(0, 0, 0, 0)
		subRail.AutomaticCanvasSize = Enum.AutomaticSize.X
		subRail.ScrollBarThickness = 0
		subRail.ScrollingDirection = Enum.ScrollingDirection.X
		subRail.Visible = false
		subRail.Parent = shell
		local subList = Instance.new("UIListLayout")
		subList.FillDirection = Enum.FillDirection.Horizontal
		subList.Padding = UDim.new(0, 6)
		subList.SortOrder = Enum.SortOrder.LayoutOrder
		subList.Parent = subRail
		pad(subRail, 8, 12, 0, 12)

		local pageState = {}

		local function makePage()
			local pg = Instance.new("ScrollingFrame")
			pg.BackgroundTransparency = 1
			pg.Size = UDim2.fromScale(1, 1)
			pg.CanvasSize = UDim2.new(0, 0, 0, 0)
			pg.AutomaticCanvasSize = Enum.AutomaticSize.Y
			pg.ScrollBarThickness = 3
			pg.ScrollBarImageColor3 = Theme.AccentBright
			pg.BorderSizePixel = 0
			pg.Parent = shell
			pad(pg, 8, 8, 12, 8)
			local rootList = Instance.new("UIListLayout")
			rootList.Padding = UDim.new(0, 8)
			rootList.SortOrder = Enum.SortOrder.LayoutOrder
			rootList.Parent = pg
			local st = { body = nil, hL = 0, hR = 0, cards = {} }
			if useTwoCol then
				local wide = Instance.new("Frame")
				wide.BackgroundTransparency = 1
				wide.Size = UDim2.new(1, 0, 0, 0)
				wide.AutomaticSize = Enum.AutomaticSize.Y
				wide.LayoutOrder = 1
				wide.Parent = pg
				local wl = Instance.new("UIListLayout")
				wl.Padding = UDim.new(0, 8)
				wl.SortOrder = Enum.SortOrder.LayoutOrder
				wl.Parent = wide
				local row = Instance.new("Frame")
				row.BackgroundTransparency = 1
				row.Size = UDim2.new(1, 0, 0, 0)
				row.AutomaticSize = Enum.AutomaticSize.Y
				row.LayoutOrder = 2
				row.Parent = pg
				local left = Instance.new("Frame")
				left.BackgroundTransparency = 1
				left.Size = UDim2.new(0.5, -4, 0, 0)
				left.AutomaticSize = Enum.AutomaticSize.Y
				left.Parent = row
				local ll = Instance.new("UIListLayout")
				ll.Padding = UDim.new(0, 8)
				ll.SortOrder = Enum.SortOrder.LayoutOrder
				ll.Parent = left
				local right = Instance.new("Frame")
				right.BackgroundTransparency = 1
				right.Size = UDim2.new(0.5, -4, 0, 0)
				right.Position = UDim2.new(0.5, 4, 0, 0)
				right.AutomaticSize = Enum.AutomaticSize.Y
				right.Parent = row
				local rl = Instance.new("UIListLayout")
				rl.Padding = UDim.new(0, 8)
				rl.SortOrder = Enum.SortOrder.LayoutOrder
				rl.Parent = right
				st.wide, st.left, st.right = wide, left, right
			end
			pageState[pg] = st
			return pg
		end

		local page = makePage()

		local Tab = {
			_btn = btn,
			_btnText = btnText,
			_btnStroke = btnStroke,
			_tabGrad = tabGrad,
			_iconBadge = iconBadge,
			_iconImg = iconImg,
			_indicator = indicator,
			_shell = shell,
			_page = page,
			_buildPage = page,
			_subRail = subRail,
			_subs = {},
			_group = group,
			_order = 0,
			Title = tabTitle,
		}

		if group then
			table.insert(group.tabs, Tab)
		end

		local function currentPage()
			return Tab._buildPage or Tab._page
		end

		local function nextOrder()
			Tab._order = Tab._order + 1
			return Tab._order
		end

		local function indexSearch(frame, text, kind, extra)
			local e = {
				frame = frame,
				tab = Tab,
				page = currentPage(),
				kind = kind or "item",
				text = searchKey(text) .. " " .. searchKey(tabTitle),
			}
			if type(extra) == "table" then
				for k, v in pairs(extra) do
					e[k] = v
				end
			end
			table.insert(Window._entries, e)
		end

		local function stylePill(pill, on)
			local bg = pill:FindFirstChild("PillBg")
			if bg then
				bg.BackgroundColor3 = on and Color3.new(1, 1, 1) or Theme.Surface2
				local g = bg:FindFirstChildOfClass("UIGradient")
				if g then
					g.Enabled = on
				end
				local s = bg:FindFirstChildOfClass("UIStroke")
				if s then
					s.Color = on and Theme.AccentBright or Theme.Border
					s.Transparency = on and 0.2 or 0.45
				end
			else
				pill.BackgroundColor3 = on and Theme.Accent or Theme.Surface2
			end
			pill.TextColor3 = on and Theme.Text or Theme.Muted
		end

		local function showSub(target)
			for _, sub in ipairs(Tab._subs) do
				sub.page.Visible = sub.page == target
				if sub.pill then
					stylePill(sub.pill, sub.page == target)
				end
			end
		end

		local function addPill(pg, pillTitle)
			local pill = Instance.new("TextButton")
			pill.AutoButtonColor = false
			pill.AutomaticSize = Enum.AutomaticSize.X
			pill.Size = UDim2.fromOffset(0, 26)
			pill.BackgroundTransparency = 1
			pill.Font = Enum.Font.GothamBold
			pill.TextSize = 12
			pill.Text = pillTitle
			pill.TextColor3 = Theme.Muted
			pill.LayoutOrder = #Tab._subs + 1
			pill.ZIndex = 2
			pill.Parent = subRail
			pad(pill, 0, 10, 0, 10)

			local pillBg = Instance.new("Frame")
			pillBg.Name = "PillBg"
			pillBg.BackgroundColor3 = Theme.Surface2
			pillBg.BorderSizePixel = 0
			pillBg.Size = UDim2.fromScale(1, 1)
			pillBg.ZIndex = 1
			pillBg.Parent = pill
			round(pillBg, 8)
			stroke(pillBg, Theme.Border, 1, 0.45)
			local pgGrad = gradient(pillBg, Theme.AccentDeep, Theme.Accent, 0)
			pgGrad.Enabled = false

			stylePill(pill, pg == Tab._page)
			pill.MouseButton1Click:Connect(function()
				showSub(pg)
			end)
			table.insert(Tab._subs, { page = pg, pill = pill, title = pillTitle })
			return pill
		end

		function Tab:CreateSubTab(sOpts)
			sOpts = sOpts or {}
			local subTitle = sOpts.Title or sOpts.Name or "Page"
			if not Tab._subInited then
				Tab._subInited = true
				subRail.Visible = true
				subRail.Size = UDim2.new(1, 0, 0, 36)
				page.Size = UDim2.new(1, 0, 1, -36)
				page.Position = UDim2.fromOffset(0, 36)
				addPill(page, subTitle)
				Tab._buildPage = page
				return Tab
			end
			local pg = makePage()
			pg.Size = UDim2.new(1, 0, 1, -36)
			pg.Position = UDim2.fromOffset(0, 36)
			pg.Visible = false
			addPill(pg, subTitle)
			Tab._buildPage = pg
			return Tab
		end

		local function bumpCol(h)
			local st = pageState[currentPage()]
			if not (st and st.left and st.body) then
				return
			end
			local card = st.body.Parent
			if card and card.Parent == st.left then
				st.hL = st.hL + h
			elseif card and card.Parent == st.right then
				st.hR = st.hR + h
			end
		end

		local function shouldTwoCol(st)
			if not useTwoCol then
				return false
			end
			if Window._columnMode == 2 then
				return true
			end
			if Window._columnMode == 1 then
				return false
			end
			return #(st.cards or {}) >= (Window._minSectionsTwoCol or 3)
		end

		local function reflowColumns(st)
			if not (st and st.wide and st.left and st.right) then
				return
			end
			local cards = st.cards or {}
			local n = #cards
			if n == 0 then
				return
			end
			if not shouldTwoCol(st) or n == 1 then
				for _, card in ipairs(cards) do
					card.Parent = st.wide
				end
				st.hL, st.hR = 0, 0
				return
			end
			st.hL, st.hR = 0, 0
			for i, card in ipairs(cards) do
				if i == 1 then
					card.Parent = st.left
					st.hL = 36
				elseif i == 2 then
					card.Parent = st.right
					st.hR = 36
				else
					local host = (st.hL <= st.hR) and st.left or st.right
					card.Parent = host
					if host == st.left then
						st.hL = st.hL + 36
					else
						st.hR = st.hR + 36
					end
				end
			end
		end

		local function sectionHost(st)
			if st and st.body then
				return st.body
			end
			if st and st.wide then
				return st.wide
			end
			if st and st.left then
				return st.left
			end
			return nil
		end

		local function rowFrame(h)
			local st = pageState[currentPage()]
			local host = sectionHost(st) or currentPage()
			local inCard = st and st.body ~= nil
			local rowH = h or (touchUi and 48 or 44)
			local f = Instance.new("Frame")
			f.BackgroundColor3 = inCard and Theme.Surface2 or Theme.Surface
			f.BorderSizePixel = 0
			f.Size = UDim2.new(1, 0, 0, rowH)
			f.LayoutOrder = nextOrder()
			f.Parent = host
			round(f, inCard and 8 or 10)
			if not inCard then
				stroke(f, Theme.Border, 1, 0.28)
			else
				stroke(f, Theme.Border, 1, 0.55)
			end
			bumpCol(rowH + 6)
			return f
		end

		function Tab:CreateSection(text)
			local raw = tostring(text or "Section")
			local st = pageState[currentPage()]
			local card = Instance.new("Frame")
			card.BackgroundColor3 = Theme.Surface
			card.BorderSizePixel = 0
			card.Size = UDim2.new(1, 0, 0, 28)
			card.AutomaticSize = Enum.AutomaticSize.Y
			card.LayoutOrder = nextOrder()
			round(card, 11)
			stroke(card, Theme.Border, 1, 0.18)
			local cardSheen = Instance.new("Frame")
			cardSheen.Name = "AccentLine"
			cardSheen.BackgroundColor3 = Color3.new(1, 1, 1)
			cardSheen.BorderSizePixel = 0
			cardSheen.Size = UDim2.new(1, 0, 0, 2)
			cardSheen.ZIndex = 2
			cardSheen.Parent = card
			gradient(cardSheen, Theme.AccentDeep, Theme.AccentBright, 0)
			if st and st.wide then
				st.cards = st.cards or {}
				table.insert(st.cards, card)
				reflowColumns(st)
			else
				card.Parent = currentPage()
			end

			local open = true
			local head = Instance.new("TextButton")
			head.AutoButtonColor = false
			head.BackgroundTransparency = 1
			head.Size = UDim2.new(1, 0, 0, 30)
			head.Text = ""
			head.Parent = card

			local chev = Instance.new("Frame")
			chev.AnchorPoint = Vector2.new(1, 0.5)
			chev.Position = UDim2.new(1, -14, 0.5, 0)
			chev.Size = UDim2.fromOffset(8, 8)
			chev.BackgroundColor3 = Color3.new(1, 1, 1)
			chev.BorderSizePixel = 0
			chev.Rotation = 45
			chev.Parent = head
			round(chev, 2)
			gradient(chev, Theme.AccentBright, Theme.AccentDeep, 45)

			local lbl = Instance.new("TextLabel")
			lbl.BackgroundTransparency = 1
			lbl.Position = UDim2.fromOffset(12, 0)
			lbl.Size = UDim2.new(1, -36, 1, 0)
			lbl.Font = Enum.Font.GothamBold
			lbl.TextSize = 14
			applyFont(lbl, "semi")
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.TextColor3 = Theme.Text
			lbl.RichText = true
			if raw:find("<", 1, true) then
				lbl.Text = raw
			else
				lbl.Text = raw
			end
			lbl.Parent = head

			local bodyF = Instance.new("Frame")
			bodyF.Name = "Body"
			bodyF.BackgroundTransparency = 1
			bodyF.Position = UDim2.fromOffset(0, 30)
			bodyF.Size = UDim2.new(1, 0, 0, 0)
			bodyF.AutomaticSize = Enum.AutomaticSize.Y
			bodyF.Parent = card
			local bl = Instance.new("UIListLayout")
			bl.Padding = UDim.new(0, 5)
			bl.SortOrder = Enum.SortOrder.LayoutOrder
			bl.Parent = bodyF
			pad(bodyF, 0, 6, 8, 6)

			head.MouseButton1Click:Connect(function()
				open = not open
				bodyF.Visible = open
				chev.Rotation = open and 45 or -45
			end)

			if st then
				st.body = bodyF
			end
			indexSearch(card, raw, "section", { body = bodyF, chev = chev })
			return card
		end

		Tab.CreateGroupbox = Tab.CreateSection

		function Tab:CreateDivider()
			local st = pageState[currentPage()]
			local f = Instance.new("Frame")
			f.BackgroundTransparency = 1
			f.Size = UDim2.new(1, 0, 0, 8)
			f.LayoutOrder = nextOrder()
			f.Parent = sectionHost(st) or currentPage()
			local line = Instance.new("Frame")
			line.BackgroundColor3 = Theme.Border
			line.BorderSizePixel = 0
			line.Size = UDim2.new(1, 0, 0, 1)
			line.Position = UDim2.new(0, 0, 0.5, 0)
			line.Parent = f
			indexSearch(f, "", "divider")
			return f
		end

		function Tab:CreateParagraph(pOpts)
			pOpts = pOpts or {}
			local f = rowFrame(0)
			f.AutomaticSize = Enum.AutomaticSize.Y
			pad(f, 12, 12, 12, 12)
			local t = Instance.new("TextLabel")
			t.BackgroundTransparency = 1
			t.Size = UDim2.new(1, 0, 0, 18)
			t.Font = Enum.Font.GothamBold
			t.TextSize = 14
			t.TextXAlignment = Enum.TextXAlignment.Left
			t.TextColor3 = Theme.Text
			t.Text = pOpts.Title or "Info"
			t.Parent = f
			local c = Instance.new("TextLabel")
			c.BackgroundTransparency = 1
			c.Position = UDim2.fromOffset(0, 22)
			c.Size = UDim2.new(1, 0, 0, 0)
			c.AutomaticSize = Enum.AutomaticSize.Y
			c.Font = Enum.Font.Gotham
			c.TextSize = 13
			c.TextWrapped = true
			c.TextXAlignment = Enum.TextXAlignment.Left
			c.TextColor3 = Color3.fromRGB(180, 184, 192)
			c.Text = pOpts.Content or pOpts.Description or ""
			c.Parent = f
			indexSearch(f, (pOpts.Title or "") .. " " .. (pOpts.Content or pOpts.Description or ""), "item")
			return f
		end

		function Tab:CreateLabel(text)
			return self:CreateParagraph({ Title = tostring(text or ""), Content = "" })
		end

		function Tab:CreateButton(bOpts)
			bOpts = bOpts or {}
			local f = rowFrame(40)
			-- Gradient on a child Frame — never on the TextButton (kills label contrast)
			local bg = Instance.new("Frame")
			bg.BackgroundColor3 = Color3.new(1, 1, 1)
			bg.BorderSizePixel = 0
			bg.Size = UDim2.new(1, -16, 0, 32)
			bg.Position = UDim2.new(0, 8, 0.5, 0)
			bg.AnchorPoint = Vector2.new(0, 0.5)
			bg.ZIndex = 1
			bg.Parent = f
			round(bg, 8)
			stroke(bg, Theme.AccentBright, 1, 0.35)
			local btnGrad = gradient(bg, Theme.AccentDeep, Theme.Accent, 0)

			local btn = Instance.new("TextButton")
			btn.BackgroundTransparency = 1
			btn.BorderSizePixel = 0
			btn.AutoButtonColor = false
			btn.Size = UDim2.new(1, -16, 0, 32)
			btn.Position = UDim2.new(0, 8, 0.5, 0)
			btn.AnchorPoint = Vector2.new(0, 0.5)
			btn.Font = Enum.Font.GothamMedium
			btn.TextSize = 15
			applyFont(btn, "semi")
			btn.TextColor3 = Theme.Text
			btn.Text = bOpts.Title or bOpts.Name or "Button"
			btn.ZIndex = 2
			btn.Parent = f
			btn.MouseEnter:Connect(function()
				btnGrad.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Theme.Accent),
					ColorSequenceKeypoint.new(1, Theme.AccentBright),
				})
			end)
			btn.MouseLeave:Connect(function()
				btnGrad.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Theme.AccentDeep),
					ColorSequenceKeypoint.new(1, Theme.Accent),
				})
			end)
			btn.MouseButton1Click:Connect(function()
				if bOpts.Callback then
					task.spawn(bOpts.Callback)
				end
			end)
			indexSearch(f, bOpts.Title or bOpts.Name or "Button")
			return {
				SetText = function(_, v)
					btn.Text = tostring(v)
				end,
			}
		end

		function Tab:CreateToggle(tOpts)
			tOpts = tOpts or {}
			local state = tOpts.Default == true
			local flag = tOpts.Flag
			local hasKey = tOpts.Keybind ~= nil
			local f = rowFrame(38)
			pad(f, 0, 10, 0, 10)

			local lbl = Instance.new("TextLabel")
			lbl.BackgroundTransparency = 1
			lbl.Size = UDim2.new(1, hasKey and -96 or -34, 1, 0)
			lbl.Font = Enum.Font.GothamMedium
			lbl.TextSize = tOpts.TitleSize or 13
			applyFont(lbl, "semi")
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.TextColor3 = tOpts.TitleColor or Theme.Text
			local titleText = tOpts.Title or "Toggle"
			lbl.RichText = tOpts.RichText == true or tostring(titleText):find("<", 1, true) ~= nil
			lbl.TextTruncate = Enum.TextTruncate.None
			lbl.TextWrapped = false
			lbl.Text = titleText
			lbl.Parent = f

			local box = Instance.new("TextButton")
			box.AutoButtonColor = false
			box.Text = ""
			box.Active = true
			box.AnchorPoint = Vector2.new(1, 0.5)
			box.Position = UDim2.new(1, 0, 0.5, 0)
			box.Size = UDim2.fromOffset(22, 22)
			box.ZIndex = 6
			box.BackgroundColor3 = state and Color3.new(1, 1, 1) or Theme.Surface2
			box.BorderSizePixel = 0
			box.Parent = f
			round(box, 5)
			local boxStroke = stroke(box, state and Theme.AccentBright or Color3.fromRGB(70, 88, 118), 1.5, state and 0.05 or 0.25)
			local boxGrad = gradient(box, Theme.AccentDeep, Theme.AccentBright, 135)
			boxGrad.Enabled = state

			local mark = Instance.new("TextLabel")
			mark.BackgroundTransparency = 1
			mark.Size = UDim2.fromScale(1, 1)
			mark.Font = Enum.Font.GothamBold
			mark.TextSize = 15
			mark.TextColor3 = Color3.fromRGB(15, 15, 20)
			mark.Text = "✓"
			mark.Visible = state
			mark.ZIndex = 7
			mark.Parent = box

			local currentKey = nil
			if hasKey then
				currentKey = typeof(tOpts.Keybind) == "EnumItem" and tOpts.Keybind or (type(tOpts.Keybind) == "string" and Enum.KeyCode[tOpts.Keybind]) or nil
				local kBtn = Instance.new("TextButton")
				kBtn.AutoButtonColor = false
				kBtn.AnchorPoint = Vector2.new(1, 0.5)
				kBtn.Position = UDim2.new(1, -28, 0.5, 0)
				kBtn.Size = UDim2.fromOffset(58, 22)
				kBtn.BackgroundColor3 = Theme.Surface2
				kBtn.BorderSizePixel = 0
				kBtn.Font = Enum.Font.GothamMedium
				kBtn.TextSize = 11
				kBtn.TextColor3 = Theme.Muted
				kBtn.Text = currentKey and currentKey.Name or "None"
				kBtn.ZIndex = 6
				round(kBtn, 5)
				stroke(kBtn, Theme.Border, 1, 0.4)
				kBtn.Parent = f

				local listening = false
				kBtn.MouseButton1Click:Connect(function()
					listening = true
					kBtn.Text = "..."
					kBtn.TextColor3 = Theme.AccentBright
				end)

				UserInputService.InputBegan:Connect(function(input, gp)
					if listening and input.UserInputType == Enum.UserInputType.Keyboard then
						listening = false
						if input.KeyCode == Enum.KeyCode.Escape then
							currentKey = nil
							kBtn.Text = "None"
						else
							currentKey = input.KeyCode
							kBtn.Text = currentKey.Name
						end
						kBtn.TextColor3 = Theme.Muted
						return
					end
					if not gp and currentKey and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == currentKey then
						if not UserInputService:GetFocusedTextBox() then
							set(not state, true)
						end
					end
				end)
			end

			local function set(v, fire)
				state = v and true or false
				box.BackgroundColor3 = state and Color3.new(1, 1, 1) or Theme.Surface2
				boxGrad.Enabled = state
				if boxStroke then
					boxStroke.Color = state and Theme.AccentBright or Color3.fromRGB(70, 88, 118)
					boxStroke.Transparency = state and 0.05 or 0.25
				end
				mark.Visible = state
				if flag then
					Library:SetFlag(flag, state)
					local peers = Library._flagLinks[flag]
					if peers then
						local alive = {}
						for _, peer in ipairs(peers) do
							if peer ~= set then
								local okPeer = pcall(peer, state, false)
								if okPeer then
									alive[#alive + 1] = peer
								end
							else
								alive[#alive + 1] = peer
							end
						end
						Library._flagLinks[flag] = alive
					end
				end
				if fire ~= false and tOpts.Callback then
					task.spawn(tOpts.Callback, state)
				end
			end

			local savedFlag = nil
			if flag then
				savedFlag = Library:GetFlag(flag)
				if savedFlag ~= nil then
					state = savedFlag == true
					mark.Visible = state
					box.BackgroundColor3 = state and Color3.new(1, 1, 1) or Theme.Surface2
					boxGrad.Enabled = state
					if boxStroke then
						boxStroke.Color = state and Theme.AccentBright or Color3.fromRGB(70, 88, 118)
					end
				end
				Library._flagLinks[flag] = Library._flagLinks[flag] or {}
				table.insert(Library._flagLinks[flag], set)
			end

			local function flip()
				set(not state, true)
			end

			lbl.ZIndex = 1

			local hit = Instance.new("TextButton")
			hit.Name = "ToggleHit"
			hit.AutoButtonColor = false
			hit.BackgroundTransparency = 1
			hit.Text = ""
			hit.Active = true
			hit.Size = UDim2.fromScale(1, 1)
			hit.ZIndex = 5
			hit.Parent = f

			local armed = true
			local function onToggleClick()
				if not armed then
					return
				end
				armed = false
				flip()
				task.delay(0.08, function()
					armed = true
				end)
			end
			hit.MouseButton1Click:Connect(onToggleClick)
			box.MouseButton1Click:Connect(onToggleClick)
			if flag and Library:GetFlag(flag) == nil then
				Library:SetFlag(flag, state)
			end

			indexSearch(f, titleText)
			return {
				Set = function(_, v)
					set(v, true)
				end,
				Get = function()
					return state
				end,
			}
		end

		Tab.CreateCheckbox = Tab.CreateToggle

		function Tab:CreateSlider(sOpts)
			sOpts = sOpts or {}
			local minV = sOpts.Min or 0
			local maxV = sOpts.Max or 100
			local value = math.clamp(sOpts.Default or minV, minV, maxV)
			local decimals = sOpts.Decimals or 0
			local flag = sOpts.Flag
			local f = rowFrame(56)
			pad(f, 8, 12, 8, 12)

			local top = Instance.new("TextLabel")
			top.BackgroundTransparency = 1
			top.Size = UDim2.new(1, -56, 0, 18)
			top.Font = Enum.Font.GothamMedium
			top.TextSize = 15
			applyFont(top, "semi")
			top.TextXAlignment = Enum.TextXAlignment.Left
			top.TextColor3 = Theme.Text
			top.Text = sOpts.Title or "Slider"
			top.Parent = f

			local valLbl = Instance.new("TextLabel")
			valLbl.BackgroundTransparency = 1
			valLbl.AnchorPoint = Vector2.new(1, 0)
			valLbl.Position = UDim2.new(1, 0, 0, 0)
			valLbl.Size = UDim2.fromOffset(52, 18)
			valLbl.Font = Enum.Font.GothamBold
			valLbl.TextSize = 13
			valLbl.TextXAlignment = Enum.TextXAlignment.Right
			valLbl.TextColor3 = Theme.AccentBright
			valLbl.Parent = f

			local bar = Instance.new("Frame")
			bar.BackgroundColor3 = Theme.Surface2
			bar.BorderSizePixel = 0
			bar.Position = UDim2.new(0, 0, 0, 32)
			bar.Size = UDim2.new(1, 0, 0, 6)
			bar.Parent = f
			round(bar, 3)

			local fill = Instance.new("Frame")
			fill.BackgroundColor3 = Color3.new(1, 1, 1)
			fill.BorderSizePixel = 0
			fill.Size = UDim2.new((value - minV) / math.max(maxV - minV, 1e-6), 0, 1, 0)
			fill.Parent = bar
			round(fill, 3)
			gradient(fill, Theme.AccentDeep, Theme.AccentBright, 0)

			local thumb = Instance.new("Frame")
			thumb.Name = "Thumb"
			thumb.BackgroundColor3 = Color3.fromRGB(236, 244, 252)
			thumb.BorderSizePixel = 0
			thumb.Size = UDim2.fromOffset(16, 16)
			thumb.AnchorPoint = Vector2.new(0.5, 0.5)
			thumb.Position = UDim2.new((value - minV) / math.max(maxV - minV, 1e-6), 0, 0.5, 0)
			thumb.ZIndex = 3
			thumb.Parent = bar
			round(thumb, 8)
			stroke(thumb, Theme.AccentBright, 2, 0)

			local hit = Instance.new("TextButton")
			hit.BackgroundTransparency = 1
			hit.Text = ""
			hit.Size = UDim2.new(1, 0, 0, 28)
			hit.Position = UDim2.new(0, 0, 0, 20)
			hit.ZIndex = 4
			hit.Parent = f

			local function format(v)
				if decimals <= 0 then
					return tostring(math.floor(v + 0.5))
				end
				return string.format("%." .. tostring(decimals) .. "f", v)
			end

			local function set(v, fire)
				value = math.clamp(v, minV, maxV)
				local a = (value - minV) / math.max(maxV - minV, 1e-6)
				fill.Size = UDim2.new(a, 0, 1, 0)
				thumb.Position = UDim2.new(a, 0, 0.5, 0)
				valLbl.Text = format(value)
				if flag then
					Library:SetFlag(flag, value)
				end
				if fire ~= false and sOpts.Callback then
					task.spawn(sOpts.Callback, value)
				end
			end

			local sliding = false
			local function fromX(x)
				local abs = bar.AbsolutePosition.X
				local size = bar.AbsoluteSize.X
				local a = math.clamp((x - abs) / math.max(size, 1), 0, 1)
				set(minV + (maxV - minV) * a, true)
			end

			hit.InputBegan:Connect(function(input)
				if
					input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch
				then
					sliding = true
					fromX(input.Position.X)
				end
			end)
			UserInputService.InputChanged:Connect(function(input)
				if
					sliding
					and (
						input.UserInputType == Enum.UserInputType.MouseMovement
						or input.UserInputType == Enum.UserInputType.Touch
					)
				then
					fromX(input.Position.X)
				end
			end)
			UserInputService.InputEnded:Connect(function(input)
				if
					input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch
				then
					sliding = false
				end
			end)

			set(value, false)
			indexSearch(f, sOpts.Title or "Slider")
			return {
				Set = function(_, v)
					set(v, true)
				end,
				Get = function()
					return value
				end,
			}
		end

		function Tab:CreateDropdown(dOpts)
			dOpts = dOpts or {}
			local values = dOpts.Values or dOpts.Options or {}
			local multi = dOpts.Multi == true
			local selected = {}
			local current = dOpts.Default
			if multi then
				if type(current) == "table" then
					for _, v in ipairs(current) do
						selected[v] = true
					end
				end
			else
				if type(current) == "number" then
					current = values[current]
				end
				if current == nil then
					current = values[1]
				end
			end
			local open = false
			local flag = dOpts.Flag
			local hasIcon = dOpts.Icon ~= nil and tostring(dOpts.Icon) ~= ""
			local iconAsset = hasIcon and resolveIcon(dOpts.Icon) or nil

			local st = pageState[currentPage()]
			local host = (st and st.body) or (st and st.left) or currentPage()
			local inCard = st and st.body ~= nil
			local f = Instance.new("Frame")
			f.BackgroundColor3 = inCard and Theme.Surface2 or Theme.Surface
			f.BorderSizePixel = 0
			f.Size = UDim2.new(1, 0, 0, 48)
			f.AutomaticSize = Enum.AutomaticSize.Y
			f.ClipsDescendants = true
			f.LayoutOrder = nextOrder()
			f.Parent = host
			round(f, inCard and 8 or 10)
			if not inCard then
				stroke(f, Theme.Border, 1, 0.35)
			end
			bumpCol(54)
			pad(f, 8, 10, 8, 10)

			local titleOffset = 0
			if hasIcon then
				local iconBadge = Instance.new("Frame")
				iconBadge.BackgroundColor3 = Theme.AccentDim
				iconBadge.BorderSizePixel = 0
				iconBadge.Size = UDim2.fromOffset(18, 18)
				iconBadge.Position = UDim2.fromOffset(0, -1)
				iconBadge.Parent = f
				round(iconBadge, 6)
				local iconImg = Instance.new("ImageLabel")
				iconImg.BackgroundTransparency = 1
				iconImg.AnchorPoint = Vector2.new(0.5, 0.5)
				iconImg.Position = UDim2.fromScale(0.5, 0.5)
				iconImg.Size = UDim2.fromOffset(12, 12)
				iconImg.Image = iconAsset
				iconImg.ImageColor3 = Theme.AccentBright
				iconImg.ScaleType = Enum.ScaleType.Fit
				iconImg.Parent = iconBadge
				titleOffset = 24
			end

			local lbl = Instance.new("TextLabel")
			lbl.BackgroundTransparency = 1
			lbl.Position = UDim2.fromOffset(titleOffset, 0)
			lbl.Size = UDim2.new(1, -titleOffset, 0, 14)
			lbl.Font = Enum.Font.Gotham
			lbl.TextSize = 12
			applyFont(lbl, "semi")
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.TextColor3 = Theme.Muted
			lbl.Text = dOpts.Title or "Dropdown"
			lbl.Parent = f

			local trigger = Instance.new("TextButton")
			trigger.AutoButtonColor = false
			trigger.BackgroundColor3 = Color3.fromRGB(32, 35, 44)
			trigger.BorderSizePixel = 0
			trigger.Position = UDim2.fromOffset(0, 18)
			trigger.Size = UDim2.new(1, 0, 0, 30)
			trigger.Font = Enum.Font.GothamMedium
			trigger.TextSize = 13
			applyFont(trigger, "semi")
			trigger.TextColor3 = Color3.fromRGB(240, 242, 248)
			trigger.TextXAlignment = Enum.TextXAlignment.Left
			trigger.TextTruncate = Enum.TextTruncate.AtEnd
			trigger.Text = ""
			trigger.Parent = f
			round(trigger, 8)
			pad(trigger, 0, 12, 0, 10)
			stroke(trigger, Color3.fromRGB(70, 78, 98), 1, 0.25)

			local chevron = Instance.new("TextLabel")
			chevron.BackgroundTransparency = 1
			chevron.AnchorPoint = Vector2.new(1, 0.5)
			chevron.Position = UDim2.new(1, -8, 0.5, 0)
			chevron.Size = UDim2.fromOffset(16, 16)
			chevron.Font = Enum.Font.GothamBold
			chevron.TextSize = 12
			chevron.TextColor3 = Theme.AccentBright
			chevron.Text = "▾"
			chevron.ZIndex = 2
			chevron.Parent = trigger

			local triggerIcon = nil
			if hasIcon then
				triggerIcon = Instance.new("ImageLabel")
				triggerIcon.BackgroundTransparency = 1
				triggerIcon.AnchorPoint = Vector2.new(0, 0.5)
				triggerIcon.Position = UDim2.new(0, 8, 0.5, 0)
				triggerIcon.Size = UDim2.fromOffset(14, 14)
				triggerIcon.Image = iconAsset
				triggerIcon.ImageColor3 = Theme.AccentBright
				triggerIcon.ScaleType = Enum.ScaleType.Fit
				triggerIcon.Parent = trigger
				trigger.TextXAlignment = Enum.TextXAlignment.Left
				-- leave room for icon via padding text with spaces is fragile; use UIPadding
				local tPad = trigger:FindFirstChildOfClass("UIPadding")
				if tPad then
					tPad.PaddingLeft = UDim.new(0, 28)
				else
					pad(trigger, 0, 10, 0, 28)
				end
			end

			local menu = Instance.new("Frame")
			menu.BackgroundColor3 = Theme.Surface2
			menu.BorderSizePixel = 0
			menu.Position = UDim2.fromOffset(0, 50)
			menu.Size = UDim2.new(1, 0, 0, 0)
			menu.Visible = false
			menu.ClipsDescendants = true
			menu.Parent = f
			round(menu, 8)

			local scroll = Instance.new("ScrollingFrame")
			scroll.Name = "MenuScroll"
			scroll.BackgroundTransparency = 1
			scroll.BorderSizePixel = 0
			scroll.ScrollBarThickness = 4
			scroll.ScrollBarImageColor3 = Theme.Accent
			scroll.CanvasSize = UDim2.fromOffset(0, 0)
			scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
			scroll.Size = UDim2.fromScale(1, 1)
			scroll.Parent = menu

			local menuList = Instance.new("UIListLayout")
			menuList.Padding = UDim.new(0, 2)
			menuList.Parent = scroll
			pad(scroll, 4, 4, 4, 4)

			local function displayText()
				if multi then
					local parts = {}
					for _, v in ipairs(values) do
						if selected[v] then
							table.insert(parts, tostring(v))
						end
					end
					if #parts == 0 then
						return dOpts.Placeholder or "None selected"
					end
					if #parts <= 2 then
						return table.concat(parts, ", ")
					end
					return parts[1] .. ", " .. parts[2] .. " +" .. tostring(#parts - 2)
				end
				return current ~= nil and tostring(current) or (dOpts.Placeholder or "Select...")
			end

			local function fire()
				if flag then
					if multi then
						local arr = {}
						for _, v in ipairs(values) do
							if selected[v] then
								table.insert(arr, v)
							end
						end
						Library:SetFlag(flag, arr)
					else
						Library:SetFlag(flag, current)
					end
				end
				if dOpts.Callback then
					if multi then
						local arr = {}
						for _, v in ipairs(values) do
							if selected[v] then
								table.insert(arr, v)
							end
						end
						task.spawn(dOpts.Callback, arr)
					else
						task.spawn(dOpts.Callback, current)
					end
				end
			end

			local function setOpen(v)
				open = v
				menu.Visible = open
				chevron.Text = open and "▴" or "▾"
				if open then
					local maxVisible = 10
					local h = math.min(maxVisible, math.max(#values, 1)) * 32 + 10
					menu.Size = UDim2.new(1, 0, 0, h)
				else
					menu.Size = UDim2.new(1, 0, 0, 0)
				end
			end

			local function rebuild()
				for _, ch in ipairs(scroll:GetChildren()) do
					if ch:IsA("TextButton") then
						ch:Destroy()
					end
				end
				for _, v in ipairs(values) do
					local active = multi and selected[v] or current == v
					local opt = Instance.new("TextButton")
					opt.AutoButtonColor = false
					opt.BackgroundColor3 = active and Theme.Accent or Color3.fromRGB(28, 30, 38)
					opt.BorderSizePixel = 0
					opt.Size = UDim2.new(1, 0, 0, 30)
					opt.Font = Enum.Font.GothamMedium
					opt.TextSize = 13
					opt.TextColor3 = active and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(210, 214, 224)
					opt.TextXAlignment = Enum.TextXAlignment.Left
					opt.Text = (active and "✓  " or "    ") .. tostring(v)
					opt.Parent = scroll
					round(opt, 6)
					pad(opt, 0, 10, 0, hasIcon and 28 or 10)
					if active then
						stroke(opt, Theme.AccentBright, 1, 0.35)
					end
					if hasIcon then
						local oi = Instance.new("ImageLabel")
						oi.BackgroundTransparency = 1
						oi.AnchorPoint = Vector2.new(0, 0.5)
						oi.Position = UDim2.new(0, 8, 0.5, 0)
						oi.Size = UDim2.fromOffset(12, 12)
						oi.Image = iconAsset
						oi.ImageColor3 = Theme.AccentBright
						oi.ScaleType = Enum.ScaleType.Fit
						oi.Parent = opt
					end
					opt.MouseButton1Click:Connect(function()
						if multi then
							selected[v] = not selected[v]
							rebuild()
							trigger.Text = displayText()
							fire()
						else
							current = v
							trigger.Text = displayText()
							setOpen(false)
							rebuild()
							fire()
						end
					end)
				end
			end

			trigger.Text = displayText()
			rebuild()
			trigger.MouseButton1Click:Connect(function()
				setOpen(not open)
			end)

			indexSearch(f, dOpts.Title or "Dropdown")
			return {
				Set = function(_, v)
					if multi and type(v) == "table" then
						selected = {}
						for _, x in ipairs(v) do
							selected[x] = true
						end
					else
						current = v
					end
					trigger.Text = displayText()
					rebuild()
					fire()
				end,
				Get = function()
					if multi then
						local arr = {}
						for _, v in ipairs(values) do
							if selected[v] then
								table.insert(arr, v)
							end
						end
						return arr
					end
					return current
				end,
				Refresh = function(_, newValues, keep)
					if type(newValues) == "table" then
						values = newValues
						if not keep then
							if multi then
								selected = {}
							elseif current ~= nil then
								local found = false
								for _, v in ipairs(values) do
									if v == current then
										found = true
										break
									end
								end
								if not found then
									current = values[1]
								end
							else
								current = values[1]
							end
						end
						trigger.Text = displayText()
						rebuild()
					end
				end,
			}
		end

		function Tab:CreateInput(iOpts)
			iOpts = iOpts or {}
			local flag = iOpts.Flag
			local f = rowFrame(56)
			pad(f, 8, 10, 8, 10)

			local lbl = Instance.new("TextLabel")
			lbl.BackgroundTransparency = 1
			lbl.Size = UDim2.new(1, 0, 0, 14)
			lbl.Font = Enum.Font.Gotham
			lbl.TextSize = 11
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.TextColor3 = Theme.Muted
			lbl.Text = iOpts.Title or "Input"
			lbl.Parent = f

			local box = Instance.new("TextBox")
			box.BackgroundColor3 = Theme.Surface2
			box.BorderSizePixel = 0
			box.Position = UDim2.fromOffset(0, 20)
			box.Size = UDim2.new(1, 0, 0, 28)
			box.ClearTextOnFocus = false
			box.Font = Enum.Font.Gotham
			box.TextSize = 13
			box.TextColor3 = Theme.Text
			box.PlaceholderColor3 = Theme.Muted
			box.PlaceholderText = iOpts.Placeholder or ""
			box.Text = iOpts.Default or ""
			box.TextXAlignment = Enum.TextXAlignment.Left
			box.Parent = f
			round(box, 8)
			pad(box, 0, 10, 0, 10)

			local function commit()
				local text = box.Text
				if flag then
					Library:SetFlag(flag, text)
				end
				if iOpts.Callback then
					task.spawn(iOpts.Callback, text)
				end
			end
			box.FocusLost:Connect(function(enter)
				if enter or iOpts.Finished ~= false then
					commit()
				end
			end)
			if flag then
				Library:SetFlag(flag, box.Text)
			end

			indexSearch(f, iOpts.Title or "Input")
			return {
				Set = function(_, v)
					box.Text = tostring(v or "")
					commit()
				end,
				Get = function()
					return box.Text
				end,
			}
		end

		function Tab:CreateKeybind(kOpts)
			kOpts = kOpts or {}
			local key = kOpts.Default
			local listening = false
			local f = rowFrame(42)
			pad(f, 0, 12, 0, 12)

			local lbl = Instance.new("TextLabel")
			lbl.BackgroundTransparency = 1
			lbl.Size = UDim2.new(1, -100, 1, 0)
			lbl.Font = Enum.Font.GothamMedium
			lbl.TextSize = 13
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.TextColor3 = Theme.Text
			lbl.Text = kOpts.Title or "Keybind"
			lbl.Parent = f

			local btn = Instance.new("TextButton")
			btn.AutoButtonColor = false
			btn.AnchorPoint = Vector2.new(1, 0.5)
			btn.Position = UDim2.new(1, 0, 0.5, 0)
			btn.Size = UDim2.fromOffset(88, 28)
			btn.BackgroundColor3 = Theme.Surface2
			btn.BorderSizePixel = 0
			btn.Font = Enum.Font.GothamMedium
			btn.TextSize = 12
			btn.TextColor3 = Theme.Text
			btn.Text = key and tostring(key.Name or key) or "None"
			btn.Parent = f
			round(btn, 8)

			btn.MouseButton1Click:Connect(function()
				listening = true
				btn.Text = "..."
			end)

			UserInputService.InputBegan:Connect(function(input, gp)
				if not listening then
					if
						not gp
						and key
						and input.UserInputType == Enum.UserInputType.Keyboard
						and input.KeyCode == key
					then
						if kOpts.Callback then
							task.spawn(kOpts.Callback)
						end
					end
					return
				end
				if input.UserInputType == Enum.UserInputType.Keyboard then
					if input.KeyCode == Enum.KeyCode.Escape then
						listening = false
						btn.Text = key and key.Name or "None"
						return
					end
					key = input.KeyCode
					listening = false
					btn.Text = key.Name
					if kOpts.Changed then
						task.spawn(kOpts.Changed, key)
					end
				end
			end)

			indexSearch(f, kOpts.Title or "Keybind")
			return {
				Get = function()
					return key
				end,
			}
		end

		btn.MouseButton1Click:Connect(function()
			Window:SelectTab(Tab)
		end)

		table.insert(self._tabs, Tab)
		if #self._tabs == 1 then
			self:SelectTab(Tab)
		end
		return Tab
	end

	closeBtn.MouseButton1Click:Connect(function()
		Window:Destroy()
	end)
	minBtn.MouseButton1Click:Connect(function()
		Window:Minimize(true)
	end)

	-- reopen hotkey LeftControl+K default
	if opts.ToggleKey ~= false then
		local toggleKey = opts.ToggleKey or Enum.KeyCode.RightShift
		UserInputService.InputBegan:Connect(function(input, gp)
			if gp then
				return
			end
			if searchBox:IsFocused() then
				return
			end
			local currentToggle = Window.ToggleKey or toggleKey or Enum.KeyCode.RightShift
			if input.KeyCode == currentToggle then
				if Window._minimized then
					Window:Minimize(false)
				else
					Window:SetVisible(not Window._visible)
				end
			end
		end)
	end

	table.insert(self.Windows, Window)

	do
		do
		root.Size = UDim2.fromOffset(winW, winH)
		glowWrap.Size = UDim2.fromOffset(winW, winH)
		root.Visible = true
		glowWrap.Visible = true
		bubble.Visible = false
		glowStroke.Transparency = 0.62
		glowStroke2.Transparency = 0.90
		Window._visible = true
		Window._minimized = false
	end

	print("[Zenith EGG] Window created and displayed successfully!")
	Library:Notify({
		Title = "Zenith EGG",
		Content = "Premium Hub Loaded! Press RightShift to hide/show",
		Duration = 3,
		Color = Theme.Success,
	})
	return Window
end

-- expose
local g = (getgenv and getgenv()) or _G

pcall(function()
	local function consider(inst)
		if typeof(inst) ~= "Instance" or not inst:IsA("ScreenGui") then
			return
		end
		local n = inst.Name
		if n == "SVUINotify" or string.sub(n, 1, 5) == "SVUI_" then
			inst:Destroy()
		end
	end
	local function scrub(parent)
		if typeof(parent) ~= "Instance" then
			return
		end
		for _, ch in ipairs(parent:GetChildren()) do
			consider(ch)
			if ch.Name == "RobloxGui" then
				for _, inner in ipairs(ch:GetChildren()) do
					consider(inner)
				end
			end
		end
	end
	scrub(CoreGui)
	local pg = LocalPlayer:FindFirstChild("PlayerGui")
	if pg then
		scrub(pg)
	end
	if type(gethui) == "function" then
		local h = gethui()
		if typeof(h) == "Instance" then
			scrub(h)
		end
	end
end)

g.SVUI = Library
g.ScriptVerseUI = Library
Library.Compat = g.SVCompat

return Library

end)()

-- STEAL AN EGG - COMPLETE PRO HUB ENGINE
-- =========================================================================

-- Game Module Refs
local Lib, Client, Util, Globals
local EggCmds, PlotCmds, Network, Guard, Lookup, Save, BaseUpgrade, AssetCmds, Constants, SpeedPowerProjection, TreadmillUtil
local NetMap, PivotKey, ImpulseKey, AssetsDirectory

local function softRequire(inst)
	if not inst then return nil end
	local ok, mod = pcall(require, inst)
	return ok and mod or nil
end

local function loadGameModules()
	pcall(function()
		Lib = ReplicatedStorage:FindFirstChild("Library") or ReplicatedStorage:WaitForChild("Library", 8)
		if Lib then
			Client = Lib:FindFirstChild("Client") or Lib:WaitForChild("Client", 5)
			Util = Lib:FindFirstChild("Util") or Lib:WaitForChild("Util", 5)
			Globals = Lib:FindFirstChild("Globals") or Lib:WaitForChild("Globals", 5)
		end
		if Client then
			EggCmds = softRequire(Client:FindFirstChild("EggCmds"))
			PlotCmds = softRequire(Client:FindFirstChild("PlotCmds"))
			Network = softRequire(Client:FindFirstChild("Network"))
			Guard = softRequire(Client:FindFirstChild("ToolGameplayGuard"))
			Save = softRequire(Client:FindFirstChild("Save"))
			BaseUpgrade = softRequire(Client:FindFirstChild("BaseUpgradeClient"))
			AssetCmds = softRequire(Client:FindFirstChild("AssetCmds"))
			SpeedPowerProjection = softRequire(Client:FindFirstChild("SpeedPowerProjection"))
		end
		if Util then
			Lookup = softRequire(Util:FindFirstChild("GuardAreaLookupUtil"))
			TreadmillUtil = softRequire(Util:FindFirstChild("TreadmillUtil"))
		end
		if Globals then
			Constants = softRequire(Globals:FindFirstChild("Constants"))
		end

		pcall(function()
			local dir = ReplicatedStorage:FindFirstChild("Directory")
			if dir and dir:FindFirstChild("Assets") then
				local ast = require(dir.Assets)
				AssetsDirectory = ast and (ast.Directory or ast)
			end
		end)

		NetMap = (Constants and Constants.NETWORK_MAP) or (Network and Network.NET_MAP)
		PivotKey = (NetMap and NetMap.ClientCharacter and NetMap.ClientCharacter.SET_PIVOT) or "ClientCharacter: SetPivot"
		ImpulseKey = (NetMap and NetMap.ClientCharacter and NetMap.ClientCharacter.BEGIN_IMPULSE) or "ClientCharacter: BeginImpulse"
	end)
end

-- Async Game Module Loader with retries
task.spawn(function()
	loadGameModules()
	task.wait(1)
	if not EggCmds or not PlotCmds then
		loadGameModules()
	end
end)

-- Hub State
local State = {
	running = true,
	busy = false,
	busySince = nil,
	status = "Idle",
	carrying = false,

	-- Auto Farm
	autofarm = false,
	prioritizeTopSpawn = true,
	eggFilters = { ["All (Tất Cả)"] = true },
	travelMode = "Smooth Fly (Tự Bay Mượt)",
	stealFlySpeed = 120,
	autoReturn = true,
	farmDelay = 0.15,

	-- Pet & Base
	autoPlace = false,
	autoHatch = false,
	autoSellEggs = false,
	sellEggFilters = {},
	autoEquipBest = false,
	autoFuse = false,
	autoSellPets = false,
	autoTreadmill = false,
	autoUpgrade = false,
	claimOffline = false,
	autoClaimIndex = false,
	autoGroupReward = false,
	autoBuyTrail = false,
	autoEquipTrail = false,

	-- Movement
	speedOn = false,
	walkSpeed = 150,
	fly = false,
	flySpeed = 120,
	noclip = false,
	infJump = false,
	antiAfk = true,

	-- Visuals (Egg Card ESP)
	espWorldEgg = false,
	espGardenEgg = false,
	espPlayer = false,
	espGuard = false,

	-- Timers
	lastSteal = 0,
	lastPlace = 0,
	lastHatch = 0,
	lastSell = 0,
	lastEquip = 0,
	lastUpgrade = 0,
	lastOffline = 0,
	lastIndex = 0,
	lastGroup = 0,
	lastTrail = 0,
	lastTreadmill = 0,
	lastFuse = 0,
	lastAfk = 0,
}

local conns = {}
local espPool = {}
local flyConn, noclipConn, infJumpConn, speedBV, flyBV, flyBG

local function track(conn)
	if conn then table.insert(conns, conn) end
	return conn
end

local function notify(title, content, color, dur)
	pcall(function()
		SVUI:Notify({
			Title = title,
			Content = content,
			Duration = dur or 2.2,
			Color = color or Color3.fromRGB(240, 240, 245),
		})
	end)
end

-- Carry State Connection
task.spawn(function()
	local tries = 0
	while tries < 10 and not (EggCmds and EggCmds.AreaEggCarryStateChanged) do
		tries = tries + 1
		task.wait(0.5)
	end
	if EggCmds and EggCmds.AreaEggCarryStateChanged and type(EggCmds.AreaEggCarryStateChanged.Connect) == "function" then
		track(EggCmds.AreaEggCarryStateChanged:Connect(function(payload)
			if payload and payload.IsCarrying == true then
				State.carrying = true
			elseif payload and payload.IsCarrying == false then
				State.carrying = false
			end
		end))
	end
end)

-- Character Helper Functions
local function root()
	local c = LocalPlayer.Character
	return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("UpperTorso") or c.PrimaryPart)
end

local function hum()
	local c = LocalPlayer.Character
	return c and c:FindFirstChildOfClass("Humanoid")
end

local function zeroVel(part)
	if not part then return end
	pcall(function()
		part.AssemblyLinearVelocity = Vector3.zero
		part.AssemblyAngularVelocity = Vector3.zero
	end)
end

-- =========================================================================
-- ARENA & PLOT HELPERS
-- =========================================================================

local cachedSeparationLine = nil

local function getSeparationLine()
	if cachedSeparationLine and cachedSeparationLine.Parent then
		return cachedSeparationLine
	end
	local objs = Workspace:FindFirstChild("__OBJECTS") or Workspace:FindFirstChild("Areas") or Workspace
	local areas = objs:FindFirstChild("Areas") or objs
	cachedSeparationLine = areas:FindFirstChild("SeparationLine", true)
	return cachedSeparationLine
end

local function onGameplaySide(pos)
	local line = getSeparationLine()
	if not line or not pos then return true end
	if Lookup and type(Lookup.IsInGameplaySide) == "function" then
		local s, res = pcall(Lookup.IsInGameplaySide, line, pos)
		if s then return res == true end
	end
	local rel = line.CFrame:PointToObjectSpace(pos)
	return rel.Z > 0
end

local function inGameplay()
	if Guard and type(Guard.IsLocalPlayerInGameplayArea) == "function" then
		local s, res = pcall(Guard.IsLocalPlayerInGameplayArea)
		if s then return res == true end
	end
	local r = root()
	if not r then return false end
	return onGameplaySide(r.Position)
end

local function resolveArenaPoints()
	local line = getSeparationLine()
	if not line then return Vector3.new(0, 5, 0), Vector3.new(0, 5, 0) end
	local playPos = line.Position + Vector3.new(55, 4, 0)
	local safePos = line.Position - Vector3.new(55, 4, 0)
	return playPos, safePos
end

local function getMyPlotData()
	if PlotCmds and type(PlotCmds.GetPlotData) == "function" then
		local s, data = pcall(PlotCmds.GetPlotData, LocalPlayer)
		if s and data then return data end
	end
	return nil
end

local function getMyPlotCFrame()
	if PlotCmds then
		if type(PlotCmds.GetRespawnPointCFrame) == "function" then
			local s, cf = pcall(PlotCmds.GetRespawnPointCFrame, LocalPlayer)
			if s and cf then return cf end
		end
		if type(PlotCmds.GetPlotData) == "function" then
			local s, data = pcall(PlotCmds.GetPlotData, LocalPlayer)
			if s and data and data.Plot then
				return data.Plot:GetPivot()
			end
		end
	end

	-- Fallback: Scan Workspace Plots
	local plots = Workspace:FindFirstChild("Plots") or Workspace:FindFirstChild("Bases") or Workspace
	for _, plot in ipairs(plots:GetChildren()) do
		local sign = plot:FindFirstChild("Sign", true) or plot:FindFirstChild("Owner", true) or plot:FindFirstChild("TextLabel", true)
		if sign and sign:IsA("TextLabel") and (sign.Text:find(LocalPlayer.Name) or sign.Text:find(LocalPlayer.DisplayName)) then
			return plot:GetPivot()
		end
		local ownerAttr = plot:GetAttribute("Owner") or plot:GetAttribute("OwnerId") or plot:GetAttribute("UserId")
		if ownerAttr == LocalPlayer.UserId or ownerAttr == LocalPlayer.Name then
			return plot:GetPivot()
		end
	end

	local r = root()
	return r and r.CFrame or CFrame.new(0, 10, 0)
end

-- =========================================================================
-- SAFE SPEED BOOST (Preserves Natural Speed, Zero Slowdown When OFF)
-- =========================================================================

local function applySpeed()
	local r = root()
	local h = hum()
	if not r or not h then return end

	if not State.speedOn then
		if speedBV then
			pcall(function() speedBV:Destroy() end)
			speedBV = nil
		end
		-- DO NOT overwrite Humanoid.WalkSpeed here!
		-- Leaving Humanoid.WalkSpeed untouched preserves player's natural 2.4B game speed!
		return
	end

	if not speedBV or speedBV.Parent ~= r then
		speedBV = Instance.new("BodyVelocity")
		speedBV.Name = "ZenithSpeedBV"
		speedBV.MaxForce = Vector3.new(1e6, 0, 1e6)
		speedBV.Parent = r
	end

	local moveDir = h.MoveDirection
	if moveDir.Magnitude > 0.05 then
		speedBV.Velocity = Vector3.new(moveDir.X, 0, moveDir.Z).Unit * State.walkSpeed
	else
		speedBV.Velocity = Vector3.zero
	end
end

-- =========================================================================
-- MOVEMENT METHODS (Fly, FastTP, Pathfinding)
-- =========================================================================

local function fastTp(cf)
	local r = root()
	if not r or not cf then return end
	if Network and PivotKey then
		pcall(function() Network.Fire(PivotKey, cf) end)
	end
	r.CFrame = cf
	zeroVel(r)
end

local function flyToTarget(targetPos, speed, timeout)
	local r = root()
	if not r then return false end
	speed = speed or State.stealFlySpeed or 120
	timeout = timeout or 6
	local t0 = os.clock()

	local bv = Instance.new("BodyVelocity")
	bv.Name = "ZenithTravelBV"
	bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
	bv.Parent = r

	local bg = Instance.new("BodyGyro")
	bg.Name = "ZenithTravelBG"
	bg.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
	bg.P = 3000
	bg.Parent = r

	while os.clock() - t0 < timeout and State.running do
		r = root()
		if not r then break end
		local cur = r.Position
		local diff = targetPos - cur
		local dist = diff.Magnitude
		if dist <= 3.5 then
			break
		end
		bv.Velocity = diff.Unit * speed
		bg.CFrame = CFrame.lookAt(cur, targetPos)
		task.wait(0.03)
	end

	pcall(function()
		bv:Destroy()
		bg:Destroy()
	end)
	zeroVel(r)
	return true
end

local function walkRunTo(goal, speed, timeout)
	local h = hum()
	local r = root()
	if not h or not r or not goal then return false end
	timeout = timeout or 15
	local t0 = os.clock()

	h:MoveTo(goal)
	while os.clock() - t0 < timeout and State.running do
		r = root()
		if not r then break end
		if (goal - r.Position).Magnitude <= 4 then
			h:Move(Vector3.zero, false)
			return true
		end
		task.wait(0.1)
	end
	h:Move(Vector3.zero, false)
	return r and (r.Position - goal).Magnitude <= 8
end

-- =========================================================================
-- EGG DATA, RARITY CLASSIFIER & CARD FORMATTER
-- =========================================================================

local function getEggRarityWeight(cat, name)
	local s = string.lower(tostring(cat or "") .. " " .. tostring(name or ""))
	if s:find("secret") or s:find("rainbow") or s:find("god") then return 7, "Secret" end
	if s:find("mythic") or s:find("inferno") or s:find("dragon") or s:find("toro") then return 6, "Mythic" end
	if s:find("legendary") or s:find("gold") or s:find("volcano") or s:find("dino") or s:find("flame") then return 5, "Legendary" end
	if s:find("epic") or s:find("void") or s:find("dark") then return 4, "Epic" end
	if s:find("rare") or s:find("diamond") or s:find("crystal") then return 3, "Rare" end
	if s:find("uncommon") or s:find("grass") or s:find("nature") then return 2, "Uncommon" end
	return 1, "Common"
end

local function getEggCardData(rec, inst)
	local name = "Egg"
	local rarity = "Common"
	local petName = ""
	local valStr = ""
	local chanceStr = ""
	local weightStr = ""
	local traitStr = "Normal"
	local color = Color3.fromRGB(215, 225, 240)
	local weight = 1

	if type(rec) == "table" then
		name = tostring(rec.AssetCategory or rec.Name or (inst and inst.Name) or "Egg")
		rarity = tostring(rec.Rarity or rec.Tier or rec.Category or name)

		if AssetsDirectory and AssetsDirectory[name] then
			local entry = AssetsDirectory[name]
			if entry.Rarity and type(entry.Rarity) == "table" then
				rarity = entry.Rarity.RarityName or rarity
			end
			if entry.PetName or entry.Pet then
				petName = tostring(entry.PetName or (type(entry.Pet) == "table" and entry.Pet.Name) or entry.Pet)
			end
			if entry.IncomeRate or entry.BaseIncome then
				local inc = tonumber(entry.IncomeRate or entry.BaseIncome or 0)
				if inc >= 1e9 then valStr = string.format("$%.2fB/s", inc / 1e9)
				elseif inc >= 1e6 then valStr = string.format("$%.2fM/s", inc / 1e6)
				elseif inc >= 1e3 then valStr = string.format("$%.1fK/s", inc / 1e3)
				else valStr = "$" .. tostring(inc) .. "/s" end
			end
		end

		if rec.ItemData and type(rec.ItemData) == "table" then
			petName = tostring(rec.ItemData.Name or rec.ItemData.Id or rec.ItemData.Pet or petName)
		elseif rec.PetInside then
			petName = tostring(rec.PetInside)
		end

		local v = tonumber(rec.Value or rec.Worth or rec.Price or rec.IncomeRate or 0)
		if valStr == "" and v and v > 0 then
			if v >= 1e12 then valStr = string.format("$%.2fT/s", v / 1e12)
			elseif v >= 1e9 then valStr = string.format("$%.2fB/s", v / 1e9)
			elseif v >= 1e6 then valStr = string.format("$%.2fM/s", v / 1e6)
			elseif v >= 1e3 then valStr = string.format("$%.1fK/s", v / 1e3)
			else valStr = "$" .. tostring(v) .. "/s" end
		end

		if rec.Weight or rec.Power then
			local w = tonumber(rec.Weight or rec.Power or 0)
			if w >= 1e6 then weightStr = string.format("%.1fM kg", w / 1e6)
			elseif w >= 1e3 then weightStr = string.format("%.1fK kg", w / 1e3)
			else weightStr = tostring(w) .. " kg" end
		end

		if rec.Chance or rec.Ratio then
			chanceStr = tostring(rec.Chance or rec.Ratio)
		end

		if type(rec.Mutations) == "table" and #rec.Mutations > 0 then
			traitStr = table.concat(rec.Mutations, " ")
		elseif rec.Mutation and tostring(rec.Mutation) ~= "" and tostring(rec.Mutation) ~= "None" then
			traitStr = tostring(rec.Mutation)
		end
	elseif inst then
		name = inst.Name
		local prompt = inst:FindFirstChildWhichIsA("ProximityPrompt", true)
		if prompt and prompt.ObjectText ~= "" then
			name = prompt.ObjectText
		end
		if AssetsDirectory and AssetsDirectory[name] then
			local entry = AssetsDirectory[name]
			if entry.Rarity and type(entry.Rarity) == "table" then
				rarity = entry.Rarity.RarityName or rarity
			end
		end
	end

	weight, rarity = getEggRarityWeight(rarity, name)

	if rarity == "Secret" then
		color = Color3.fromRGB(255, 50, 180)
		if chanceStr == "" then chanceStr = "1 in 10.0" end
	elseif rarity == "Mythic" then
		color = Color3.fromRGB(255, 40, 90)
		if chanceStr == "" then chanceStr = "1 in 3.8" end
	elseif rarity == "Legendary" then
		color = Color3.fromRGB(255, 150, 20)
		if chanceStr == "" then chanceStr = "1 in 2.7" end
	elseif rarity == "Epic" then
		color = Color3.fromRGB(180, 70, 255)
		if chanceStr == "" then chanceStr = "1 in 1.8" end
	elseif rarity == "Rare" then
		color = Color3.fromRGB(45, 170, 255)
		if chanceStr == "" then chanceStr = "1 in 1.4" end
	elseif rarity == "Uncommon" then
		color = Color3.fromRGB(50, 220, 110)
		if chanceStr == "" then chanceStr = "1 in 1.2" end
	else
		color = Color3.fromRGB(215, 225, 240)
		if chanceStr == "" then chanceStr = "1 in 1.0" end
	end

	if valStr == "" then
		if weight == 7 then valStr = "$500M/s"
		elseif weight == 6 then valStr = "$30.11M/s"
		elseif weight == 5 then valStr = "$204.4K/s"
		elseif weight == 4 then valStr = "$15.5K/s"
		elseif weight == 3 then valStr = "$2.5K/s"
		elseif weight == 2 then valStr = "$350/s"
		else valStr = "$50/s" end
	end

	if weightStr == "" then
		if weight >= 6 then weightStr = "15.0M kg"
		elseif weight >= 5 then weightStr = "38.5K kg"
		elseif weight >= 4 then weightStr = "2.4K kg"
		else weightStr = "500 kg" end
	end

	if petName == "" then
		petName = name:gsub(" Egg", ""):gsub("Trứng ", "")
	end

	return {
		name = name,
		rarity = rarity,
		color = color,
		weight = weight,
		valStr = valStr,
		chanceStr = chanceStr,
		weightStr = weightStr,
		traitStr = traitStr,
		petName = petName,
	}
end

local function getAreaEggSnapshot()
	local snap = nil
	if EggCmds and type(EggCmds.GetAreaEggSnapshot) == "function" then
		local s, res = pcall(EggCmds.GetAreaEggSnapshot)
		if s and res then snap = res end
	end
	if (not snap or not snap.Records) and EggCmds and type(EggCmds.RequestAreaEggSnapshot) == "function" then
		pcall(function()
			snap = EggCmds.RequestAreaEggSnapshot()
		end)
	end
	return snap
end

-- Universal Egg Finder (Snapshot + Workspace Dual Scan)
local function findAllWorldEggs()
	local found = {}
	local addedPositions = {}

	-- 1. Scan EggCmds AreaEggSnapshot
	local snap = getAreaEggSnapshot()
	if snap then
		local records = snap.Records or snap
		for uid, rec in pairs(records) do
			if type(rec) == "table" then
				local id = rec.Uid or uid
				local cat = tostring(rec.AssetCategory or rec.Name or "")
				local pos = (rec.BottomCFrame and rec.BottomCFrame.Position) or rec.Position or rec.Pos
				if pos then
					local key = string.format("%.0f_%.0f", pos.X, pos.Z)
					if not addedPositions[key] then
						addedPositions[key] = true
						local model = Workspace:FindFirstChild(id, true)
						if not model then
							for _, obj in ipairs(Workspace:GetDescendants()) do
								if obj:IsA("BasePart") and (obj.Position - pos).Magnitude < 8 then
									model = obj
									break
								end
							end
						end

						table.insert(found, {
							rec = rec,
							uid = id,
							category = cat,
							pos = pos,
							model = model,
							card = getEggCardData(rec, model),
						})
					end
				end
			end
		end
	end

	-- 2. Scan Workspace Objects, Models & Prompts
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("ProximityPrompt") and obj.Enabled then
			local part = obj.Parent
			if part and part:IsA("BasePart") then
				local pText = (obj.ObjectText ~= "" and obj.ObjectText or obj.ActionText or part.Name):lower()
				if pText:find("egg") or pText:find("trứng") or pText:find("steal") or pText:find("take") or obj:GetAttribute("UID") then
					local pos = part.Position
					local key = string.format("%.0f_%.0f", pos.X, pos.Z)
					if not addedPositions[key] then
						addedPositions[key] = true
						local uid = obj:GetAttribute("UID") or part.Name
						local card = getEggCardData({ AssetCategory = obj.ObjectText ~= "" and obj.ObjectText or part.Name, Uid = uid }, part)
						table.insert(found, {
							rec = { Uid = uid, AssetCategory = card.name },
							uid = uid,
							category = card.name,
							pos = pos,
							prompt = obj,
							model = part.Parent:IsA("Model") and part.Parent or part,
							card = card,
						})
					end
				end
			end
		elseif obj:IsA("Model") and obj.Name:lower():find("egg") and not obj:FindFirstAncestorOfClass("Player") then
			local primary = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
			if primary then
				local pos = primary.Position
				local key = string.format("%.0f_%.0f", pos.X, pos.Z)
				if not addedPositions[key] then
					addedPositions[key] = true
					local card = getEggCardData(nil, obj)
					table.insert(found, {
						rec = { Uid = obj.Name, AssetCategory = obj.Name },
						uid = obj.Name,
						category = obj.Name,
						pos = pos,
						model = obj,
						card = card,
					})
				end
			end
		end
	end

	return found
end

local function findEggPrompt(uid, pos)
	if uid then
		local model = Workspace:FindFirstChild(uid, true)
		if model then
			local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
			if prompt and prompt.Enabled then
				return prompt
			end
		end
	end

	local function checkPrompt(inst)
		if not inst:IsA("ProximityPrompt") or not inst.Enabled then return false end
		local part = inst.Parent
		if not part or not part:IsA("BasePart") or not pos then return false end
		return (part.Position - pos).Magnitude < 12
	end

	for _, inst in ipairs(Workspace:GetDescendants()) do
		if checkPrompt(inst) then
			return inst
		end
	end
	return nil
end

local function holdProximityPrompt(prompt)
	if not prompt or not prompt.Parent or not prompt.Enabled then return false end
	local hold = math.max(prompt.HoldDuration or 0.2, 0.2) + 0.1
	if typeof(fireproximityprompt) == "function" then
		pcall(fireproximityprompt, prompt, hold)
		pcall(fireproximityprompt, prompt, 0)
	end
	pcall(function()
		prompt:InputHoldBegin()
		task.wait(hold)
		prompt:InputHoldEnd()
	end)
	return true
end

local function eggIsCarried(uid)
	if EggCmds and type(EggCmds.GetAreaEggRecord) == "function" and uid then
		local s, rec = pcall(EggCmds.GetAreaEggRecord, uid)
		if s and rec and rec.State == "Carried" then
			return true
		end
	end
	return State.carrying == true
end

local function waitUntilCarrying(uid, timeout)
	timeout = timeout or 2.5
	local t0 = os.clock()
	while os.clock() - t0 < timeout and State.running do
		if eggIsCarried(uid) or State.carrying then
			return true
		end
		task.wait(0.06)
	end
	return eggIsCarried(uid) or State.carrying
end

local function requestCarry(uid, rec)
	if not EggCmds or type(EggCmds.RequestCarryAreaEgg) ~= "function" or not uid then return false end
	local slotKey = uid:match(":(.+)$")
	if not slotKey and rec and rec.NestId then
		slotKey = rec.NestId
	end
	if slotKey and slotKey ~= "" then
		local s, ok = pcall(function()
			return EggCmds.RequestCarryAreaEgg(uid, slotKey)
		end)
		if s and ok == true then return true end
	end
	local s, ok = pcall(function()
		return EggCmds.RequestCarryAreaEgg(uid)
	end)
	return s and ok == true
end

local function returnHomeAndClaim()
	local homeCF = getMyPlotCFrame()
	if not homeCF then return false end

	local claimed = false
	if EggCmds and EggCmds.AreaEggClaimed and type(EggCmds.AreaEggClaimed.Connect) == "function" then
		local conn = EggCmds.AreaEggClaimed:Connect(function()
			claimed = true
		end)
		task.wait(1.5)
		pcall(function() conn:Disconnect() end)
	end

	local r = root()
	local atPlot = r and (r.Position - homeCF.Position).Magnitude < 35
	if not claimed and (atPlot or not inGameplay()) then
		claimed = true
	end

	State.carrying = false
	State.status = claimed and "Egg secured" or "At plot"
	return claimed
end

-- =========================================================================
-- ONE CYCLE STEAL (Smooth Fly & Auto Steal)
-- =========================================================================

local function stealOneCycle()
	if State.busy then
		if State.busySince and (os.clock() - State.busySince > 10) then
			State.busy = false
			State.busySince = nil
		else
			return
		end
	end
	State.busy = true
	State.busySince = os.clock()

	pcall(function()
		local r = root()
		local h = hum()
		if not r or not h then
			State.busy = false
			return
		end

		pcall(function()
			if EggCmds and type(EggCmds.RequestAreaEggSnapshot) == "function" then
				EggCmds.RequestAreaEggSnapshot()
			end
		end)
		task.wait(0.05)

		local allEggs = findAllWorldEggs()
		if #allEggs == 0 then
			State.busy = false
			return
		end

		local filtered = {}
		local isAll = (State.eggFilters["All (Tất Cả)"] == true or State.eggFilters["All"] == true or next(State.eggFilters) == nil)

		for _, egg in ipairs(allEggs) do
			if isAll or State.eggFilters[egg.card.rarity] == true or State.eggFilters[egg.category] == true then
				table.insert(filtered, egg)
			end
		end

		if #filtered == 0 then
			filtered = allEggs
		end

		table.sort(filtered, function(a, b)
			if State.prioritizeTopSpawn and a.card.weight ~= b.card.weight then
				return a.card.weight > b.card.weight
			end
			local distA = r and (a.pos - r.Position).Magnitude or 0
			local distB = r and (b.pos - r.Position).Magnitude or 0
			return distA < distB
		end)

		local targetEgg = filtered[1]
		local targetPos = targetEgg.pos + Vector3.new(0, 2.5, 0)
		local eggUid = targetEgg.uid
		local eggRec = targetEgg.rec

		if State.travelMode == "Dịch Chuyển Tức Thời (Instant TP)" then
			fastTp(CFrame.new(targetPos))
		elseif State.travelMode == "Đi Bộ (Walk)" then
			walkRunTo(targetPos, 45, 6)
		else
			flyToTarget(targetPos, State.stealFlySpeed or 120, 6)
		end

		task.wait(0.08)

		local prompt = targetEgg.prompt or findEggPrompt(eggUid, targetEgg.pos)
		for attempt = 1, 3 do
			if eggIsCarried(eggUid) or State.carrying then break end
			if prompt then
				holdProximityPrompt(prompt)
			end
			if waitUntilCarrying(eggUid, 0.8) then break end
			requestCarry(eggUid, eggRec)
			if waitUntilCarrying(eggUid, 1.0) then break end
			if prompt then
				holdProximityPrompt(prompt)
			end
		end

		task.wait(0.1)

		if State.autoReturn then
			local homeCF = getMyPlotCFrame()
			if homeCF then
				local destPos = homeCF.Position + Vector3.new(0, 3, 0)
				if State.travelMode == "Dịch Chuyển Tức Thời (Instant TP)" then
					fastTp(CFrame.new(destPos))
				elseif State.travelMode == "Đi Bộ (Walk)" then
					walkRunTo(destPos, 45, 5)
				else
					flyToTarget(destPos, State.stealFlySpeed or 120, 5)
				end
				returnHomeAndClaim()
			end
		end

		State.lastSteal = os.clock()
	end)

	State.busy = false
	State.busySince = nil
end

local function autofarmCycle()
	if not State.autofarm or State.busy then return end
	stealOneCycle()
end

-- =========================================================================
-- PETS, GARDEN & BASE AUTOMATION
-- =========================================================================

local function placeInventoryEggs()
	if not EggCmds or type(EggCmds.GetOwnerRuntimeRecords) ~= "function" then return end
	pcall(function()
		local data = getMyPlotData()
		local home = getMyPlotCFrame()
		if not data or not home then return end
		local records = EggCmds.GetOwnerRuntimeRecords(LocalPlayer.UserId) or {}
		for uid, rec in pairs(records) do
			if type(rec) == "table" and rec.State == "Inventory" then
				if type(EggCmds.RequestPlaceEgg) == "function" then
					EggCmds.RequestPlaceEgg(uid, home)
					task.wait(0.1)
				end
			end
		end
	end)
end

local function hatchReadyEggs()
	if not EggCmds or type(EggCmds.GetOwnerRuntimeRecords) ~= "function" then return end
	pcall(function()
		local records = EggCmds.GetOwnerRuntimeRecords(LocalPlayer.UserId) or {}
		for uid, rec in pairs(records) do
			if type(rec) == "table" and type(EggCmds.IsLocalEggReady) == "function" and EggCmds.IsLocalEggReady(uid) then
				if type(EggCmds.RequestHatchEgg) == "function" then
					EggCmds.RequestHatchEgg(uid)
					task.wait(0.1)
					if type(EggCmds.RequestCompleteHatchEgg) == "function" then
						EggCmds.RequestCompleteHatchEgg(uid)
					end
				end
			end
		end
	end)
end

local function trySellEggs()
	if not EggCmds or type(EggCmds.RequestSellEgg) ~= "function" then return end
	pcall(function()
		local records = EggCmds.GetOwnerRuntimeRecords(LocalPlayer.UserId) or {}
		for uid, rec in pairs(records) do
			if type(rec) == "table" and (rec.State == "Inventory" or rec.State == "Placed") then
				local card = getEggCardData(rec, nil)
				if State.sellEggFilters[card.rarity] == true or State.sellEggFilters[card.name] == true then
					EggCmds.RequestSellEgg(uid)
					task.wait(0.15)
				end
			end
		end
	end)
end

local function tryEquipBest()
	if AssetCmds and type(AssetCmds.RequestEquipBest) == "function" then
		pcall(AssetCmds.RequestEquipBest)
	end
end

local function tryFuse()
	if AssetCmds and type(AssetCmds.RequestFuseAll) == "function" then
		pcall(AssetCmds.RequestFuseAll)
	end
end

local function trySellPets()
	if AssetCmds and type(AssetCmds.RequestSellUnfavouritePets) == "function" then
		pcall(AssetCmds.RequestSellUnfavouritePets)
	end
end

local function tryTreadmill()
	pcall(function()
		local r = root()
		local h = hum()
		if not r or not h then return end
		local homeCF = getMyPlotCFrame()
		if not homeCF then return end

		local plotsFolder = (PlotCmds and type(PlotCmds.GetPlotsFolder) == "function" and PlotCmds.GetPlotsFolder())
			or Workspace:FindFirstChild("Plots")
			or Workspace:FindFirstChild("Bases")

		local myPlot = nil
		if plotsFolder then
			for _, plot in ipairs(plotsFolder:GetChildren()) do
				local plotData = getMyPlotData()
				if plotData and plotData.Plot == plot then
					myPlot = plot
					break
				end
			end
		end

		local targetTreadmill = nil
		if myPlot then
			for _, desc in ipairs(myPlot:GetDescendants()) do
				if desc.Name:lower():find("treadmill") or desc.Name:lower():find("chay") or desc.Name:lower():find("machine") then
					targetTreadmill = desc:IsA("BasePart") and desc or desc:FindFirstChildWhichIsA("BasePart", true)
					if targetTreadmill then break end
				end
			end
		end

		if targetTreadmill then
			local targetPos = targetTreadmill.Position + Vector3.new(0, 3, 0)
			if (r.Position - targetPos).Magnitude > 6 then
				fastTp(CFrame.new(targetPos))
				task.wait(0.1)
			end
			local prompt = targetTreadmill:FindFirstChildWhichIsA("ProximityPrompt", true)
			if prompt then
				holdProximityPrompt(prompt)
			end
		end
	end)
end

local function tryUpgrade()
	if BaseUpgrade and type(BaseUpgrade.RequestUpgrade) == "function" then
		pcall(BaseUpgrade.RequestUpgrade)
	end
end

local function tryOffline()
	if Network and PivotKey then
		pcall(function()
			Network.Fire("OfflineReward: Claim")
		end)
	end
end

local function tryIndex()
	if Network then
		pcall(function()
			Network.Fire("IndexReward: ClaimAll")
		end)
	end
end

local function tryGroupReward()
	if Network then
		pcall(function()
			Network.Fire("GroupReward: Claim")
		end)
	end
end

local function tryTrails()
	if Network then
		pcall(function()
			Network.Fire("Trails: RequestActiveSnapshot")
		end)
	end
end

-- =========================================================================
-- EGG CARD ESP & VISUALS (Image 3 Card Layout)
-- =========================================================================

local function clearEsp()
	for _, item in ipairs(espPool) do
		pcall(function()
			if item.bb then item.bb:Destroy() end
			if item.hl then item.hl:Destroy() end
			if item.anchor then item.anchor:Destroy() end
		end)
	end
	table.clear(espPool)
end

local function getEspContainer()
	local target = nil
	pcall(function()
		target = game:GetService("CoreGui")
	end)
	if not target then
		target = LocalPlayer:FindFirstChildOfClass("PlayerGui")
	end
	return target or Workspace
end

local function addEggCardEsp(inst, card, dist, prefix)
	if not inst then return end
	local targetPart = inst:IsA("BasePart") and inst or inst:FindFirstChildWhichIsA("BasePart", true)
	if not targetPart then return end

	pcall(function()
		local bb = Instance.new("BillboardGui")
		bb.Name = "ZenithEggCard"
		bb.AlwaysOnTop = true
		bb.MaxDistance = 5000
		bb.Size = UDim2.new(0, 230, 0, 72)
		bb.StudsOffset = Vector3.new(0, 3.2, 0)
		bb.LightInfluence = 0
		bb.Adornee = targetPart
		bb.ResetOnSpawn = false
		bb.Parent = getEspContainer()

		local cardFrame = Instance.new("Frame")
		cardFrame.BackgroundColor3 = Color3.fromRGB(15, 14, 23)
		cardFrame.BackgroundTransparency = 0.15
		cardFrame.Size = UDim2.new(1, 0, 1, 0)
		cardFrame.BorderSizePixel = 0
		cardFrame.Parent = bb

		local cCorner = Instance.new("UICorner")
		cCorner.CornerRadius = UDim.new(0, 10)
		cCorner.Parent = cardFrame

		local cStroke = Instance.new("UIStroke")
		cStroke.Color = card.color
		cStroke.Thickness = 1.4
		cStroke.Transparency = 0.25
		cStroke.Parent = cardFrame

		-- Left Neon Accent Stripe
		local stripe = Instance.new("Frame")
		stripe.BackgroundColor3 = card.color
		stripe.BorderSizePixel = 0
		stripe.AnchorPoint = Vector2.new(0, 0.5)
		stripe.Position = UDim2.new(0, 6, 0.5, 0)
		stripe.Size = UDim2.new(0, 4, 0.8, 0)
		stripe.Parent = cardFrame
		local sCorner = Instance.new("UICorner")
		sCorner.CornerRadius = UDim.new(0, 2)
		sCorner.Parent = stripe

		-- Content Area
		local content = Instance.new("Frame")
		content.BackgroundTransparency = 1
		content.Position = UDim2.new(0, 16, 0, 5)
		content.Size = UDim2.new(1, -22, 1, -10)
		content.Parent = cardFrame

		-- Row 1: Egg Name + Rarity Pill Badge
		local nameLbl = Instance.new("TextLabel")
		nameLbl.BackgroundTransparency = 1
		nameLbl.Position = UDim2.new(0, 0, 0, 0)
		nameLbl.Size = UDim2.new(1, -66, 0, 18)
		nameLbl.Font = Enum.Font.GothamBold
		nameLbl.TextSize = 12
		nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
		nameLbl.Text = (prefix or "") .. card.name
		nameLbl.Parent = content

		local badge = Instance.new("Frame")
		badge.AnchorPoint = Vector2.new(1, 0)
		badge.Position = UDim2.new(1, 0, 0, 0)
		badge.Size = UDim2.new(0, 62, 0, 18)
		badge.BackgroundColor3 = card.color
		badge.BorderSizePixel = 0
		badge.Parent = content
		local bCorner = Instance.new("UICorner")
		bCorner.CornerRadius = UDim.new(0, 9)
		bCorner.Parent = badge

		local bText = Instance.new("TextLabel")
		bText.BackgroundTransparency = 1
		bText.Size = UDim2.new(1, 0, 1, 0)
		bText.Font = Enum.Font.GothamBold
		bText.TextSize = 10
		bText.TextColor3 = Color3.fromRGB(255, 255, 255)
		bText.Text = card.rarity
		bText.Parent = badge

		-- Row 2: Money/Value in Green + Chance/Ratio in Coral
		local valLbl = Instance.new("TextLabel")
		valLbl.BackgroundTransparency = 1
		valLbl.Position = UDim2.new(0, 0, 0, 20)
		valLbl.Size = UDim2.new(0.65, 0, 0, 20)
		valLbl.Font = Enum.Font.GothamBold
		valLbl.TextSize = 14
		valLbl.TextColor3 = Color3.fromRGB(80, 250, 130)
		valLbl.TextXAlignment = Enum.TextXAlignment.Left
		valLbl.Text = card.valStr
		valLbl.Parent = content

		local chanceLbl = Instance.new("TextLabel")
		chanceLbl.BackgroundTransparency = 1
		chanceLbl.AnchorPoint = Vector2.new(1, 0)
		chanceLbl.Position = UDim2.new(1, 0, 0, 20)
		chanceLbl.Size = UDim2.new(0.35, 0, 0, 20)
		chanceLbl.Font = Enum.Font.GothamMedium
		chanceLbl.TextSize = 11
		chanceLbl.TextColor3 = Color3.fromRGB(255, 110, 110)
		chanceLbl.TextXAlignment = Enum.TextXAlignment.Right
		chanceLbl.Text = card.chanceStr
		chanceLbl.Parent = content

		-- Row 3: Weight + Trait + Distance + Pet Inside
		local statsLbl = Instance.new("TextLabel")
		statsLbl.BackgroundTransparency = 1
		statsLbl.Position = UDim2.new(0, 0, 0, 42)
		statsLbl.Size = UDim2.new(1, 0, 0, 16)
		statsLbl.Font = Enum.Font.GothamMedium
		statsLbl.TextSize = 10
		statsLbl.TextColor3 = Color3.fromRGB(175, 185, 205)
		statsLbl.TextXAlignment = Enum.TextXAlignment.Left
		local petExtra = (card.petName ~= "" and card.petName ~= card.name) and (" • 🐾 " .. card.petName) or ""
		statsLbl.Text = string.format("%s • %s • %dm%s", card.weightStr, card.traitStr, dist or 0, petExtra)
		statsLbl.Parent = content

		-- 3D Highlight
		local hl = Instance.new("Highlight")
		hl.FillColor = card.color
		hl.OutlineColor = Color3.fromRGB(255, 255, 255)
		hl.FillTransparency = 0.6
		hl.OutlineTransparency = 0
		hl.Adornee = inst:IsA("Model") and inst or targetPart
		hl.Parent = targetPart

		table.insert(espPool, { bb = bb, hl = hl })
	end)
end

local function addSimpleEspTag(inst, color, labelText)
	if not inst then return end
	local targetPart = inst:IsA("BasePart") and inst or inst:FindFirstChildWhichIsA("BasePart", true)
	if not targetPart then return end

	pcall(function()
		local bb = Instance.new("BillboardGui")
		bb.Name = "ZenithSimpleESP"
		bb.AlwaysOnTop = true
		bb.MaxDistance = 5000
		bb.Size = UDim2.new(0, 130, 0, 26)
		bb.StudsOffset = Vector3.new(0, 3, 0)
		bb.LightInfluence = 0
		bb.Adornee = targetPart
		bb.ResetOnSpawn = false
		bb.Parent = getEspContainer()

		local box = Instance.new("Frame")
		box.BackgroundColor3 = Color3.fromRGB(15, 14, 23)
		box.BackgroundTransparency = 0.25
		box.Size = UDim2.new(1, 0, 1, 0)
		box.Parent = bb
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 6)
		c.Parent = box
		local s = Instance.new("UIStroke")
		s.Color = color
		s.Thickness = 1.5
		s.Parent = box

		local txt = Instance.new("TextLabel")
		txt.BackgroundTransparency = 1
		txt.Size = UDim2.new(1, 0, 1, 0)
		txt.Font = Enum.Font.GothamBold
		txt.TextSize = 10
		txt.TextColor3 = color
		txt.Text = labelText or inst.Name
		txt.Parent = box

		local hl = Instance.new("Highlight")
		hl.FillColor = color
		hl.OutlineColor = Color3.fromRGB(255, 255, 255)
		hl.FillTransparency = 0.65
		hl.OutlineTransparency = 0
		hl.Adornee = inst:IsA("Model") and inst or targetPart
		hl.Parent = targetPart

		table.insert(espPool, { bb = bb, hl = hl })
	end)
end

local function refreshEsp()
	clearEsp()
	pcall(function()
		local myPos = root() and root().Position

		-- 1. World Egg ESP (Card ESP Layout)
		if State.espWorldEgg then
			local worldEggs = findAllWorldEggs()
			for _, egg in ipairs(worldEggs) do
				local dist = myPos and math.floor((egg.pos - myPos).Magnitude) or 0
				local targetInst = egg.model or Workspace:FindFirstChild(egg.uid, true)
				if targetInst then
					addEggCardEsp(targetInst, egg.card, dist, "")
				else
					local anchor = Instance.new("Part")
					anchor.Name = "ZenithEggAnchor"
					anchor.Transparency = 1
					anchor.CanCollide = false
					anchor.Anchored = true
					anchor.Size = Vector3.new(1, 1, 1)
					anchor.Position = egg.pos
					anchor.Parent = Workspace
					table.insert(espPool, { anchor = anchor })
					addEggCardEsp(anchor, egg.card, dist, "")
				end
			end
		end

		-- 2. Garden / Plot Egg ESP (Card ESP Layout)
		if State.espGardenEgg then
			local plotsFolder = (PlotCmds and type(PlotCmds.GetPlotsFolder) == "function" and PlotCmds.GetPlotsFolder())
				or Workspace:FindFirstChild("Plots")
				or Workspace:FindFirstChild("Bases")

			if plotsFolder then
				for _, plot in ipairs(plotsFolder:GetChildren()) do
					local plotData = getMyPlotData()
					local isMine = (plotData and plotData.Plot == plot)
					for _, desc in ipairs(plot:GetDescendants()) do
						if desc.Name:lower():find("egg") and (desc:IsA("Model") or desc:IsA("BasePart")) then
							local card = getEggCardData(nil, desc)
							local dist = myPos and math.floor((desc:GetPivot().Position - myPos).Magnitude) or 0
							local prefix = isMine and "[Vườn Tôi] " or "[Vườn] "
							addEggCardEsp(desc, card, dist, prefix)
						end
					end
				end
			end
		end

		-- 3. Player ESP
		if State.espPlayer then
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= LocalPlayer and p.Character then
					local dist = myPos and math.floor((p.Character:GetPivot().Position - myPos).Magnitude) or 0
					addSimpleEspTag(p.Character, Color3.fromRGB(0, 230, 255), "👤 " .. p.DisplayName .. " [" .. tostring(dist) .. "m]")
				end
			end
		end

		-- 4. Guard ESP
		if State.espGuard then
			local folder = Workspace:FindFirstChild("Guards") or Workspace:FindFirstChild("Npcs") or Workspace:FindFirstChild("__OBJECTS") or Workspace
			for _, g in ipairs(folder:GetDescendants()) do
				if g.Name:lower():find("guard") and g:IsA("Model") then
					local dist = myPos and math.floor((g:GetPivot().Position - myPos).Magnitude) or 0
					addSimpleEspTag(g, Color3.fromRGB(255, 60, 60), "⚔️ Guard [" .. tostring(dist) .. "m]")
				end
			end
		end
	end)
end

-- =========================================================================
-- MOVEMENT EXTRAS (Fly, Noclip, InfJump)
-- =========================================================================

local function setNoclip(on)
	if noclipConn then
		pcall(function() noclipConn:Disconnect() end)
		noclipConn = nil
	end
	if not on then return end
	noclipConn = track(RunService.Stepped:Connect(function()
		local c = LocalPlayer.Character
		if c then
			for _, part in ipairs(c:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = false
				end
			end
		end
	end))
end

local function setFly(on)
	if flyConn then
		pcall(function() flyConn:Disconnect() end)
		flyConn = nil
	end
	if flyBV then
		pcall(function() flyBV:Destroy() end)
		flyBV = nil
	end
	if flyBG then
		pcall(function() flyBG:Destroy() end)
		flyBG = nil
	end
	if not on then return end

	flyConn = track(RunService.Heartbeat:Connect(function()
		local r = root()
		local h = hum()
		local cam = Workspace.CurrentCamera
		if not r or not h or not cam then return end

		if not flyBV or not flyBV.Parent then
			flyBV = Instance.new("BodyVelocity")
			flyBV.MaxForce = Vector3.new(1e6, 1e6, 1e6)
			flyBV.Velocity = Vector3.zero
			flyBV.Parent = r

			flyBG = Instance.new("BodyGyro")
			flyBG.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
			flyBG.P = 3500
			flyBG.Parent = r
		end

		local dir = Vector3.zero
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end

		if dir.Magnitude > 0.05 then
			flyBV.Velocity = dir.Unit * State.flySpeed
		else
			flyBV.Velocity = Vector3.zero
		end
		flyBG.CFrame = cam.CFrame
	end))
end

local function setInfJump(on)
	if infJumpConn then
		pcall(function() infJumpConn:Disconnect() end)
		infJumpConn = nil
	end
	if not on then return end
	infJumpConn = track(UserInputService.JumpRequest:Connect(function()
		local h = hum()
		if h then
			h:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end))
end

-- =========================================================================
-- CREATE ZENITH EGG PREMIUM WINDOW VIA SVUI
-- =========================================================================

local Window = SVUI:CreateWindow({
	Title = "Zenith EGG",
	Subtitle = "Steal An Egg Premium",
	Width = 710,
	Height = 450,
	ToggleKey = Enum.KeyCode.RightShift,
})

-- 1. AUTO FARM TAB
local FarmTab = Window:CreateTab({ Title = "Auto Farm", Icon = "zap" })
Window:SelectTab(FarmTab)
Window:SetVisible(true)
-- Create a permanent floating Toggle Button on screen
pcall(function()
	local floatGui = Instance.new("ScreenGui")
	floatGui.Name = "ZenithFloatToggle"
	floatGui.ResetOnSpawn = false
	floatGui.DisplayOrder = 100000
	floatGui.IgnoreGuiInset = true
	protectGui(floatGui)

	local fBtn = Instance.new("TextButton")
	fBtn.Name = "ZenithToggleBtn"
	fBtn.Size = UDim2.fromOffset(130, 36)
	fBtn.Position = UDim2.new(0, 16, 0.45, 0)
	fBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 24)
	fBtn.BorderSizePixel = 0
	fBtn.AutoButtonColor = false
	fBtn.Text = ""
	fBtn.ZIndex = 100
	fBtn.Parent = floatGui

	local fCorner = Instance.new("UICorner")
	fCorner.CornerRadius = UDim.new(0, 10)
	fCorner.Parent = fBtn

	local fStroke = Instance.new("UIStroke")
	fStroke.Color = Color3.fromRGB(240, 240, 245)
	fStroke.Thickness = 1.5
	fStroke.Parent = fBtn

	local fLabel = Instance.new("TextLabel")
	fLabel.BackgroundTransparency = 1
	fLabel.Size = UDim2.fromScale(1, 1)
	fLabel.Font = Enum.Font.GothamBold
	fLabel.TextSize = 12
	fLabel.TextColor3 = Color3.fromRGB(240, 240, 245)
	fLabel.Text = "⚡ Zenith EGG"
	fLabel.ZIndex = 101
	fLabel.Parent = fBtn

	-- Drag support for float button
	local dragging, dragStart, startPos
	fBtn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = fBtn.Position
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
			fBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)

	fBtn.MouseButton1Click:Connect(function()
		if Window then
			Window:Minimize(false)
			Window:SetVisible(not Window._visible)
		end
	end)
end)

FarmTab:CreateSection("Auto Steal & Priority Selection")
FarmTab:CreateToggle({
	Title = "Auto Steal Trứng",
	Default = false,
	Keybind = Enum.KeyCode.T,
	Callback = function(v)
		State.autofarm = v
		notify("Auto Farm", v and "Auto Steal: ON" or "Auto Steal: OFF", v and Color3.fromRGB(240, 240, 245) or Color3.fromRGB(220, 176, 64))
	end,
})
FarmTab:CreateToggle({
	Title = "Ưu Tiên Nhặt Trứng Xịn Nhất (Top Tier First)",
	Default = true,
	Callback = function(v)
		State.prioritizeTopSpawn = v
	end,
})
FarmTab:CreateDropdown({
	Title = "Chọn Loại Trứng (Multi-Select Egg Rarity)",
	Multi = true,
	Values = {
		"All (Tất Cả)",
		"Secret",
		"Mythic",
		"Legendary",
		"Epic",
		"Rare",
		"Uncommon",
		"Common",
		"Inferno",
		"Volcano",
		"Golden",
		"Dinosaur",
	},
	Default = { "All (Tất Cả)" },
	Callback = function(v)
		State.eggFilters = {}
		if type(v) == "table" then
			for _, item in ipairs(v) do
				State.eggFilters[item] = true
			end
		elseif type(v) == "string" then
			State.eggFilters[v] = true
		end
	end,
})
FarmTab:CreateDropdown({
	Title = "Chế Độ Di Chuyển Nhặt Trứng (Travel Mode)",
	Values = {
		"Smooth Fly (Tự Bay Mượt)",
		"Dịch Chuyển Tức Thời (Instant TP)",
		"Đi Bộ (Walk)",
	},
	Default = "Smooth Fly (Tự Bay Mượt)",
	Callback = function(v)
		State.travelMode = v
	end,
})
FarmTab:CreateSlider({
	Title = "Tốc Độ Bay Nhặt Trứng (Steal Fly Speed)",
	Min = 40,
	Max = 300,
	Default = 120,
	Increment = 10,
	Callback = function(v)
		State.stealFlySpeed = v
	end,
})
FarmTab:CreateToggle({
	Title = "Tự Bay Về Vườn / Plot Sau Khi Nhặt (Auto Return)",
	Default = true,
	Callback = function(v)
		State.autoReturn = v
	end,
})

FarmTab:CreateSection("Garden & Egg Management")
FarmTab:CreateToggle({
	Title = "Auto Place Eggs Into Garden",
	Default = false,
	Callback = function(v)
		State.autoPlace = v
	end,
})
FarmTab:CreateToggle({
	Title = "Auto Hatch Ready Eggs",
	Default = false,
	Callback = function(v)
		State.autoHatch = v
	end,
})
FarmTab:CreateToggle({
	Title = "Auto Sell Eggs",
	Default = false,
	Callback = function(v)
		State.autoSellEggs = v
	end,
})
FarmTab:CreateDropdown({
	Title = "Chọn Loại Trứng Để Bán (Sell Filter)",
	Multi = true,
	Values = {
		"Common",
		"Uncommon",
		"Rare",
		"Epic",
		"Legendary",
		"Mythic",
		"Secret",
	},
	Default = { "Common", "Uncommon" },
	Callback = function(v)
		State.sellEggFilters = {}
		if type(v) == "table" then
			for _, item in ipairs(v) do
				State.sellEggFilters[item] = true
			end
		elseif type(v) == "string" then
			State.sellEggFilters[v] = true
		end
	end,
})

-- 2. PETS & BASE TAB
local PetsTab = Window:CreateTab({ Title = "Pets & Base", Icon = "box" })

PetsTab:CreateSection("Pet Automation")
PetsTab:CreateToggle({
	Title = "Auto Equip Best Pets",
	Default = false,
	Callback = function(v)
		State.autoEquipBest = v
	end,
})
PetsTab:CreateToggle({
	Title = "Auto Fuse Pets",
	Default = false,
	Callback = function(v)
		State.autoFuse = v
	end,
})
PetsTab:CreateToggle({
	Title = "Auto Sell Weak Pets",
	Default = false,
	Callback = function(v)
		State.autoSellPets = v
	end,
})

PetsTab:CreateSection("Base & Treadmill (Máy Chạy)")
PetsTab:CreateToggle({
	Title = "Auto Treadmill (Tự Chạy Máy Nhà Mình)",
	Default = false,
	Keybind = Enum.KeyCode.M,
	Callback = function(v)
		State.autoTreadmill = v
		notify("Treadmill", v and "Auto Treadmill: ON" or "Auto Treadmill: OFF", v and Color3.fromRGB(240, 240, 245) or Color3.fromRGB(220, 176, 64))
	end,
})
PetsTab:CreateToggle({
	Title = "Auto Upgrade Base",
	Default = false,
	Callback = function(v)
		State.autoUpgrade = v
	end,
})
PetsTab:CreateToggle({
	Title = "Auto Claim Offline Reward",
	Default = false,
	Callback = function(v)
		State.claimOffline = v
	end,
})
PetsTab:CreateToggle({
	Title = "Auto Claim Index Rewards",
	Default = false,
	Callback = function(v)
		State.autoClaimIndex = v
	end,
})
PetsTab:CreateToggle({
	Title = "Auto Claim Group Reward",
	Default = false,
	Callback = function(v)
		State.autoGroupReward = v
	end,
})
PetsTab:CreateToggle({
	Title = "Auto Buy & Equip Trails",
	Default = false,
	Callback = function(v)
		State.autoBuyTrail = v
		State.autoEquipTrail = v
	end,
})

-- 3. CHARACTER TAB
local CharTab = Window:CreateTab({ Title = "Nhân vật", Icon = "user" })

CharTab:CreateSection("Speed Boost (An Toàn Game)")
CharTab:CreateToggle({
	Title = "Speed Boost (Không Bị Chậm Khi Tắt)",
	Default = false,
	Keybind = Enum.KeyCode.V,
	Callback = function(v)
		State.speedOn = v
		applySpeed()
		notify("Speed Boost", v and ("Speed: ON (" .. tostring(State.walkSpeed) .. ")") or "Speed: OFF (Giữ tốc độ game)", v and Color3.fromRGB(240, 240, 245) or Color3.fromRGB(220, 176, 64))
	end,
})
CharTab:CreateSlider({
	Title = "Speed Value",
	Min = 30,
	Max = 500,
	Default = 150,
	Increment = 10,
	Callback = function(v)
		State.walkSpeed = v
		if State.speedOn then applySpeed() end
	end,
})

CharTab:CreateSection("Flight & Movement")
CharTab:CreateToggle({
	Title = "Fly (WASD + Space / Ctrl)",
	Default = false,
	Keybind = Enum.KeyCode.F,
	Callback = function(v)
		State.fly = v
		setFly(v)
		notify("Fly", v and "Fly: ON (WASD + Space/Ctrl)" or "Fly: OFF", v and Color3.fromRGB(240, 240, 245) or Color3.fromRGB(220, 176, 64))
	end,
})
CharTab:CreateSlider({
	Title = "Fly Speed",
	Min = 30,
	Max = 500,
	Default = 120,
	Increment = 10,
	Callback = function(v)
		State.flySpeed = v
	end,
})
CharTab:CreateToggle({
	Title = "Noclip (Xuyên Tường)",
	Default = false,
	Keybind = Enum.KeyCode.N,
	Callback = function(v)
		State.noclip = v
		setNoclip(v)
		notify("Noclip", v and "Noclip: ON" or "Noclip: OFF", v and Color3.fromRGB(240, 240, 245) or Color3.fromRGB(220, 176, 64))
	end,
})
CharTab:CreateToggle({
	Title = "Infinite Jump",
	Default = false,
	Keybind = Enum.KeyCode.J,
	Callback = function(v)
		State.infJump = v
		setInfJump(v)
	end,
})
CharTab:CreateToggle({
	Title = "Anti-AFK (Prevents 20m Kick)",
	Default = true,
	Callback = function(v)
		State.antiAfk = v
	end,
})
CharTab:CreateButton({
	Title = "💀 Reset Nhân Vật (Instant Reset)",
	Callback = function()
		pcall(function()
			local h = hum()
			if h then
				h.Health = 0
			end
			local c = LocalPlayer.Character
			if c then
				c:BreakJoints()
			end
		end)
		notify("Character", "Character reset triggered", Color3.fromRGB(255, 80, 80), 2)
	end,
})

-- 4. VISUALS TAB (Egg Card ESP & Entities Only)
local EspTab = Window:CreateTab({ Title = "Visuals", Icon = "eye" })

EspTab:CreateSection("ESP Trứng Đẳng Cấp (Egg Card ESP)")
EspTab:CreateToggle({
	Title = "World Egg ESP (Card Giá trị, Độ hiếm, Pet)",
	Default = false,
	Keybind = Enum.KeyCode.X,
	Callback = function(v)
		State.espWorldEgg = v
		refreshEsp()
	end,
})
EspTab:CreateToggle({
	Title = "Garden Egg ESP (Trứng Trong Vườn Nhà)",
	Default = false,
	Keybind = Enum.KeyCode.C,
	Callback = function(v)
		State.espGardenEgg = v
		refreshEsp()
	end,
})

EspTab:CreateSection("ESP Thực Thể Khác (Optional Entities)")
EspTab:CreateToggle({
	Title = "Player ESP (Người chơi)",
	Default = false,
	Callback = function(v)
		State.espPlayer = v
		refreshEsp()
	end,
})
EspTab:CreateToggle({
	Title = "Guard ESP (Bảo vệ)",
	Default = false,
	Callback = function(v)
		State.espGuard = v
		refreshEsp()
	end,
})
EspTab:CreateButton({
	Title = "🔄 Refresh ESP Tags",
	Callback = function()
		refreshEsp()
		notify("ESP", "Refreshed all egg ESP tags", Color3.fromRGB(240, 240, 245), 2)
	end,
})

-- 5. SETTINGS TAB
local SetTab = Window:CreateTab({ Title = "Cài đặt", Icon = "settings" })

SetTab:CreateSection("Hub Controls")
SetTab:CreateKeybind({
	Title = "Toggle Menu UI Keybind",
	Default = Enum.KeyCode.RightShift,
	Callback = function(k)
		Window.ToggleKey = k
	end,
})
SetTab:CreateButton({
	Title = "🔄 Reload Game Remotes",
	Callback = function()
		loadGameModules()
		notify("Remotes", "Reloaded game modules", Color3.fromRGB(240, 240, 245), 2)
	end,
})
SetTab:CreateButton({
	Title = "❌ Unload Script",
	Callback = function()
		pcall(genv.SV_SAE_SHUTDOWN)
		Window:Destroy()
	end,
})

pcall(function()
	Window:SelectTab(FarmTab)
	Window:SetVisible(true)
end)

-- Background Worker Loop for Automation
track(task.spawn(function()
	while State.running do
		pcall(function()
			if State.autofarm then
				autofarmCycle()
			end
			if State.autoTreadmill then
				tryTreadmill()
			end
			if State.autoPlace and os.clock() - State.lastPlace > 1.5 then
				State.lastPlace = os.clock()
				placeInventoryEggs()
			end
			if State.autoHatch and os.clock() - State.lastHatch > 1.5 then
				State.lastHatch = os.clock()
				hatchReadyEggs()
			end
			if State.autoEquipBest and os.clock() - State.lastEquip > 4 then
				State.lastEquip = os.clock()
				tryEquipBest()
			end
			if State.autoSellPets and os.clock() - State.lastSell > 8 then
				State.lastSell = os.clock()
				trySellPets()
			end
			if State.autoFuse and os.clock() - State.lastFuse > 10 then
				State.lastFuse = os.clock()
				tryFuse()
			end
			if State.claimOffline and os.clock() - State.lastOffline > 20 then
				State.lastOffline = os.clock()
				tryOffline()
			end
			if State.autoUpgrade and os.clock() - State.lastUpgrade > 3 then
				State.lastUpgrade = os.clock()
				tryUpgrade()
			end
			if State.autoClaimIndex and os.clock() - State.lastIndex > 8 then
				State.lastIndex = os.clock()
				tryIndex()
			end
			if State.autoGroupReward and os.clock() - State.lastGroup > 20 then
				State.lastGroup = os.clock()
				tryGroupReward()
			end
			if (State.autoBuyTrail or State.autoEquipTrail) and os.clock() - State.lastTrail > 8 then
				State.lastTrail = os.clock()
				tryTrails()
			end
			if State.autoSellEggs and os.clock() - State.lastSell > 6 then
				State.lastSell = os.clock()
				trySellEggs()
			end
		end)
		task.wait(State.farmDelay or 0.15)
	end
end))

-- Heartbeat Loop
track(RunService.Heartbeat:Connect(function()
	if not State.running then return end
	if State.speedOn then
		applySpeed()
	end
	if State.antiAfk and os.clock() - State.lastAfk > 600 then
		State.lastAfk = os.clock()
		pcall(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new(0, 0))
		end)
	end
end))

-- ESP Refresh Loop
track(task.spawn(function()
	while State.running do
		if State.espWorldEgg or State.espGardenEgg or State.espGuard or State.espPlayer then
			pcall(refreshEsp)
		end
		task.wait(2)
	end
end))

-- Character Added Connection
track(LocalPlayer.CharacterAdded:Connect(function()
	task.wait(0.5)
	if State.speedOn then applySpeed() end
	if State.fly then setFly(true) end
	if State.noclip then setNoclip(true) end
end))

-- Shutdown Cleaner
genv.SV_SAE_SHUTDOWN = function()
	State.running = false
	for _, c in ipairs(conns) do
		pcall(function() c:Disconnect() end)
	end
	table.clear(conns)
	clearEsp()
	setNoclip(false)
	setFly(false)
	setInfJump(false)
	if speedBV then
		pcall(function() speedBV:Destroy() end)
		speedBV = nil
	end
	pcall(function()
		if Window and Window.Destroy then
			Window:Destroy()
		end
	end)
	genv.SV_SAE_RUNNING = nil
	genv.SV_SAE_SHUTDOWN = nil
	print("[Zenith EGG] Unloaded successfully.")
end
