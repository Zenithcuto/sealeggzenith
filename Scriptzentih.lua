-- [[ Rscripts Risk Notice ]]
-- This script is not verified by rscripts.net. Deal with caution.
--
-- Stay safe:
--   • Never log in on unofficial Roblox sites or lookalike domains.
--   • Real Roblox links use roblox.com (check the .com ending).
--   • Treat fake Roblox login / "claim reward" pages as phishing.
-- [[ End Rscripts Risk Notice ]]
-- ScriptVerse Solara compat (auto)
do
	local g = (getgenv and getgenv()) or _G
	local C = rawget(g, "SVCompat")
	if type(C) ~= "table" or not C.__svcompat then
		local function executorName()
			local ok, n = pcall(function()
				return (identifyexecutor and identifyexecutor()) or (getexecutorname and getexecutorname()) or ""
			end)
			return (ok and tostring(n) or ""):lower()
		end
		local exec = executorName()
		local isSolara = exec:find("solara", 1, true) ~= nil
			or exec:find("xeno", 1, true) ~= nil
			or exec:find("micro", 1, true) ~= nil
		local realRequire = require
		C = {
			__svcompat = true,
			Executor = exec,
			IsSolara = isSolara,
			AllowRequire = true,
			AllowHooks = (not isSolara) and typeof(hookmetamethod) == "function",
			AllowGc = typeof(getgc) == "function",
			AllowDrawing = typeof(Drawing) == "table" and typeof(Drawing.new) == "function",
			rawRequire = realRequire,
		}
		function C.softRequire(mod)
			if mod == nil then return nil end
			-- Always try real require first (Flamework hubs need it).
			-- Only learn Solara-broken after the engine errors.
			local ok, res = pcall(realRequire, mod)
			if ok then return res end
			local err = string.lower(tostring(res))
			if err:find("cannot require", 1, true)
				or err:find("cast string to bool", 1, true)
				or err:find("unable to cast", 1, true)
			then
				C.IsSolara = true
				C.AllowRequire = false
			end
			return nil
		end
		C.require = C.softRequire
		C.rawRequire = realRequire
		function C.child(parent, ...)
			local cur = parent
			for i = 1, select("#", ...) do
				if typeof(cur) ~= "Instance" then return nil end
				cur = cur:FindFirstChild((select(i, ...)))
			end
			return cur
		end
		function C.softDrawing(class)
			if not C.AllowDrawing then return nil end
			local ok, obj = pcall(Drawing.new, class)
			return ok and obj or nil
		end
		function C.canHook() return C.AllowHooks == true end
		function C.canGc() return C.AllowGc == true end
		g.SVCompat = C
	end
end
local require = (function()
	local g = (getgenv and getgenv()) or _G
	local C = rawget(g, "SVCompat")
	if type(C) == "table" and type(C.require) == "function" then
		return C.require
	end
	return require
end)()

--[[
  ScriptVerse - Steal An Egg
  PlaceId: 107778070777162

  Autofarm - walk steal, plot return, eggs/pets/base automation.
  Client AC: freeze detection tables (filtergc / gmatch+GetFullName) before movement.
]]

local PLACE_ID = 107778070777162
local genv = (getgenv and getgenv()) or _G

if type(genv.SV_SAE_SHUTDOWN) == "function" then
	pcall(genv.SV_SAE_SHUTDOWN)
	task.wait(0.1)
end
if genv.SV_SAE_RUNNING then
	return
end
genv.SV_SAE_RUNNING = true
print("[ScriptVerse] Steal An Egg - loading...")

-- Client detection bypass (Steal An Egg / Grow a Chicken Fighter) - credits Killa
local function bypassClientDetections()
	if typeof(filtergc) ~= "function" or typeof(debug) ~= "table" or typeof(debug.getupvalues) ~= "function" then
		return false, "no filtergc"
	end
	local ok, fn = pcall(function()
		return filtergc("function", {
			Constants = { "gmatch", "GetFullName" },
		}, true)
	end)
	if not ok or type(fn) ~= "function" then
		return false, "filter miss"
	end
	local setMeta = (typeof(setrawmetatable) == "function" and setrawmetatable)
		or (typeof(setmetatable) == "function" and setmetatable)
	if not setMeta then
		return false, "no setmeta"
	end
	local blocked = 0
	local okUv, ups = pcall(debug.getupvalues, fn)
	if not okUv or type(ups) ~= "table" then
		return false, "no upvalues"
	end
	for _, tbl in pairs(ups) do
		if typeof(tbl) == "table" then
			local okSet = pcall(setMeta, tbl, {
				__newindex = function() end,
			})
			if okSet then
				blocked += 1
			end
		end
	end
	return blocked > 0, blocked
end

local acOk, acInfo = bypassClientDetections()
if acOk then
	print("[ScriptVerse] Client AC bypassed (" .. tostring(acInfo) .. " tables)")
else
	warn("[ScriptVerse] Client AC bypass skipped: " .. tostring(acInfo))
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local HAS_DRAWING = typeof(Drawing) == "table" or typeof(Drawing) == "userdata"

-- UI lives in PlayerGui only. Steal is walk + proximity prompt.

local function pinUiToPlayerGui()
	return LocalPlayer:WaitForChild("PlayerGui")
end

local function createFallbackSVUI()
	local FallbackUI = {}
	local CoreGui = game:GetService("CoreGui")
	local Players = game:GetService("Players")
	local TweenService = game:GetService("TweenService")
	local UserInputService = game:GetService("UserInputService")
	local LocalPlayer = Players.LocalPlayer

	local parentGui = (gethui and gethui()) or CoreGui:FindFirstChild("RobloxGui") or LocalPlayer:WaitForChild("PlayerGui")

	function FallbackUI:Notify(opts)
		opts = opts or {}
		local title = opts.Title or "Notification"
		local content = opts.Content or ""
		local dur = opts.Duration or 2.5
		local col = opts.Color or Color3.fromRGB(120, 220, 160)

		local sg = parentGui:FindFirstChild("SVUI_NotifyGui")
		if not sg then
			sg = Instance.new("ScreenGui")
			sg.Name = "SVUI_NotifyGui"
			sg.ResetOnSpawn = false
			sg.DisplayOrder = 100
			sg.Parent = parentGui
		end

		local holder = sg:FindFirstChild("Holder")
		if not holder then
			holder = Instance.new("Frame")
			holder.Name = "Holder"
			holder.Size = UDim2.new(0, 260, 1, -20)
			holder.Position = UDim2.new(1, -270, 0, 10)
			holder.BackgroundTransparency = 1
			holder.Parent = sg

			local layout = Instance.new("UIListLayout")
			layout.SortOrder = Enum.SortOrder.LayoutOrder
			layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
			layout.Padding = UDim.new(0, 8)
			layout.Parent = holder
		end

		local card = Instance.new("Frame")
		card.Size = UDim2.new(1, 0, 0, 54)
		card.BackgroundColor3 = Color3.fromRGB(24, 26, 32)
		card.BorderSizePixel = 0
		card.Parent = holder

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = card

		local stroke = Instance.new("UIStroke")
		stroke.Color = col
		stroke.Thickness = 1.2
		stroke.Transparency = 0.3
		stroke.Parent = card

		local titleLbl = Instance.new("TextLabel")
		titleLbl.Size = UDim2.new(1, -16, 0, 22)
		titleLbl.Position = UDim2.new(0, 10, 0, 6)
		titleLbl.BackgroundTransparency = 1
		titleLbl.Font = Enum.Font.SourceSansBold
		titleLbl.TextSize = 15
		titleLbl.TextColor3 = col
		titleLbl.TextXAlignment = Enum.TextXAlignment.Left
		titleLbl.Text = title
		titleLbl.Parent = card

		local contentLbl = Instance.new("TextLabel")
		contentLbl.Size = UDim2.new(1, -16, 0, 20)
		contentLbl.Position = UDim2.new(0, 10, 0, 26)
		contentLbl.BackgroundTransparency = 1
		contentLbl.Font = Enum.Font.SourceSans
		contentLbl.TextSize = 13
		contentLbl.TextColor3 = Color3.fromRGB(200, 200, 210)
		contentLbl.TextXAlignment = Enum.TextXAlignment.Left
		contentLbl.Text = content
		contentLbl.Parent = card

		task.delay(dur, function()
			if card and card.Parent then
				pcall(function()
					TweenService:Create(card, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
					TweenService:Create(stroke, TweenInfo.new(0.3), { Transparency = 1 }):Play()
					TweenService:Create(titleLbl, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
					TweenService:Create(contentLbl, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
				end)
				task.wait(0.35)
				card:Destroy()
			end
		end)
	end

	function FallbackUI:CreateWindow(opts)
		opts = opts or {}
		local winTitle = opts.Title or "ScriptVerse"
		local winSub = opts.Subtitle or ""

		local sg = Instance.new("ScreenGui")
		sg.Name = "ScriptVerse_UI"
		sg.ResetOnSpawn = false
		sg.DisplayOrder = 20
		sg.Parent = parentGui

		local main = Instance.new("Frame")
		main.Name = "MainFrame"
		main.Size = UDim2.new(0, 480, 0, 320)
		main.Position = UDim2.new(0.5, -240, 0.5, -160)
		main.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
		main.BorderSizePixel = 0
		main.Active = true
		main.ClipsDescendants = true
		main.Parent = sg

		local mainCorner = Instance.new("UICorner")
		mainCorner.CornerRadius = UDim.new(0, 10)
		mainCorner.Parent = main

		local mainStroke = Instance.new("UIStroke")
		mainStroke.Color = Color3.fromRGB(50, 180, 130)
		mainStroke.Thickness = 1.5
		mainStroke.Parent = main

		local dragging, dragInput, dragStart, startPos
		local topBar = Instance.new("Frame")
		topBar.Name = "TopBar"
		topBar.Size = UDim2.new(1, 0, 0, 40)
		topBar.BackgroundColor3 = Color3.fromRGB(25, 28, 36)
		topBar.BorderSizePixel = 0
		topBar.Parent = main

		local topCorner = Instance.new("UICorner")
		topCorner.CornerRadius = UDim.new(0, 10)
		topCorner.Parent = topBar

		local titleText = Instance.new("TextLabel")
		titleText.Size = UDim2.new(1, -60, 1, 0)
		titleText.Position = UDim2.new(0, 14, 0, 0)
		titleText.BackgroundTransparency = 1
		titleText.Font = Enum.Font.SourceSansBold
		titleText.TextSize = 16
		titleText.TextColor3 = Color3.fromRGB(120, 220, 160)
		titleText.TextXAlignment = Enum.TextXAlignment.Left
		titleText.Text = winTitle .. (winSub ~= "" and (" - " .. winSub) or "")
		titleText.Parent = topBar

		local closeBtn = Instance.new("TextButton")
		closeBtn.Size = UDim2.new(0, 28, 0, 28)
		closeBtn.Position = UDim2.new(1, -34, 0, 6)
		closeBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
		closeBtn.Font = Enum.Font.SourceSansBold
		closeBtn.TextSize = 14
		closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		closeBtn.Text = "X"
		closeBtn.Parent = topBar

		local closeCorner = Instance.new("UICorner")
		closeCorner.CornerRadius = UDim.new(0, 6)
		closeCorner.Parent = closeBtn

		closeBtn.MouseButton1Click:Connect(function()
			main.Visible = not main.Visible
		end)

		topBar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = main.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
					end
				end)
			end
		end)
		topBar.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				dragInput = input
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if input == dragInput and dragging then
				local delta = input.Position - dragStart
				main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			end
		end)

		local tabHolder = Instance.new("Frame")
		tabHolder.Size = UDim2.new(0, 120, 1, -40)
		tabHolder.Position = UDim2.new(0, 0, 0, 40)
		tabHolder.BackgroundColor3 = Color3.fromRGB(22, 24, 30)
		tabHolder.BorderSizePixel = 0
		tabHolder.Parent = main

		local tabLayout = Instance.new("UIListLayout")
		tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
		tabLayout.Padding = UDim.new(0, 4)
		tabLayout.Parent = tabHolder

		local tabPadding = Instance.new("UIPadding")
		tabPadding.PaddingTop = UDim.new(0, 8)
		tabPadding.PaddingLeft = UDim.new(0, 6)
		tabPadding.PaddingRight = UDim.new(0, 6)
		tabPadding.Parent = tabHolder

		local contentArea = Instance.new("Frame")
		contentArea.Size = UDim2.new(1, -125, 1, -45)
		contentArea.Position = UDim2.new(0, 123, 0, 43)
		contentArea.BackgroundTransparency = 1
		contentArea.Parent = main

		local windowObj = { Gui = sg }
		local tabs = {}
		local firstTab = true

		function windowObj:CreateTab(tabOpts)
			tabOpts = tabOpts or {}
			local tabName = tabOpts.Title or "Tab"

			local isFirst = firstTab
			firstTab = false

			local tabBtn = Instance.new("TextButton")
			tabBtn.Size = UDim2.new(1, 0, 0, 32)
			tabBtn.BackgroundColor3 = isFirst and Color3.fromRGB(35, 42, 52) or Color3.fromRGB(28, 30, 38)
			tabBtn.Font = Enum.Font.SourceSansBold
			tabBtn.TextSize = 14
			tabBtn.TextColor3 = isFirst and Color3.fromRGB(120, 220, 160) or Color3.fromRGB(170, 170, 180)
			tabBtn.Text = tabName
			tabBtn.Parent = tabHolder

			local tabCorner = Instance.new("UICorner")
			tabCorner.CornerRadius = UDim.new(0, 6)
			tabCorner.Parent = tabBtn

			local tabFrame = Instance.new("ScrollingFrame")
			tabFrame.Size = UDim2.new(1, 0, 1, 0)
			tabFrame.BackgroundTransparency = 1
			tabFrame.BorderSizePixel = 0
			tabFrame.ScrollBarThickness = 4
			tabFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 90, 110)
			tabFrame.Visible = isFirst
			tabFrame.Parent = contentArea

			local containerLayout = Instance.new("UIListLayout")
			containerLayout.SortOrder = Enum.SortOrder.LayoutOrder
			containerLayout.Padding = UDim.new(0, 6)
			containerLayout.Parent = tabFrame

			containerLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
				tabFrame.CanvasSize = UDim2.new(0, 0, 0, containerLayout.AbsoluteContentSize.Y + 12)
			end)

			tabBtn.MouseButton1Click:Connect(function()
				for _, t in ipairs(tabs) do
					t.Frame.Visible = false
					t.Button.BackgroundColor3 = Color3.fromRGB(28, 30, 38)
					t.Button.TextColor3 = Color3.fromRGB(170, 170, 180)
				end
				tabFrame.Visible = true
				tabBtn.BackgroundColor3 = Color3.fromRGB(35, 42, 52)
				tabBtn.TextColor3 = Color3.fromRGB(120, 220, 160)
			end)

			local tabObj = {}
			table.insert(tabs, { Button = tabBtn, Frame = tabFrame })

			function tabObj:CreateSection(secName)
				local secLbl = Instance.new("TextLabel")
				secLbl.Size = UDim2.new(1, -10, 0, 24)
				secLbl.BackgroundTransparency = 1
				secLbl.Font = Enum.Font.SourceSansBold
				secLbl.TextSize = 14
				secLbl.TextColor3 = Color3.fromRGB(120, 220, 160)
				secLbl.TextXAlignment = Enum.TextXAlignment.Left
				secLbl.Text = "--- " .. tostring(secName) .. " ---"
				secLbl.Parent = tabFrame
			end

			function tabObj:CreateToggle(tOpts)
				tOpts = tOpts or {}
				local title = tOpts.Title or "Toggle"
				local state = tOpts.Default or false
				local cb = tOpts.Callback or function() end

				local frame = Instance.new("Frame")
				frame.Size = UDim2.new(1, -10, 0, 34)
				frame.BackgroundColor3 = Color3.fromRGB(26, 29, 38)
				frame.BorderSizePixel = 0
				frame.Parent = tabFrame

				local fc = Instance.new("UICorner")
				fc.CornerRadius = UDim.new(0, 6)
				fc.Parent = frame

				local lbl = Instance.new("TextLabel")
				lbl.Size = UDim2.new(1, -60, 1, 0)
				lbl.Position = UDim2.new(0, 10, 0, 0)
				lbl.BackgroundTransparency = 1
				lbl.Font = Enum.Font.SourceSans
				lbl.TextSize = 14
				lbl.TextColor3 = Color3.fromRGB(220, 220, 230)
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.Text = title
				lbl.Parent = frame

				local btn = Instance.new("TextButton")
				btn.Size = UDim2.new(0, 42, 0, 22)
				btn.Position = UDim2.new(1, -50, 0.5, -11)
				btn.BackgroundColor3 = state and Color3.fromRGB(40, 180, 100) or Color3.fromRGB(60, 65, 75)
				btn.Font = Enum.Font.SourceSansBold
				btn.TextSize = 12
				btn.TextColor3 = Color3.fromRGB(255, 255, 255)
				btn.Text = state and "ON" or "OFF"
				btn.Parent = frame

				local bc = Instance.new("UICorner")
				bc.CornerRadius = UDim.new(0, 11)
				bc.Parent = btn

				btn.MouseButton1Click:Connect(function()
					state = not state
					btn.BackgroundColor3 = state and Color3.fromRGB(40, 180, 100) or Color3.fromRGB(60, 65, 75)
					btn.Text = state and "ON" or "OFF"
					pcall(cb, state)
				end)
			end

			function tabObj:CreateSlider(sOpts)
				sOpts = sOpts or {}
				local title = sOpts.Title or "Slider"
				local minVal = sOpts.Min or 0
				local maxVal = sOpts.Max or 100
				local curVal = sOpts.Default or minVal
				local inc = sOpts.Increment or 1
				local cb = sOpts.Callback or function() end

				local frame = Instance.new("Frame")
				frame.Size = UDim2.new(1, -10, 0, 46)
				frame.BackgroundColor3 = Color3.fromRGB(26, 29, 38)
				frame.BorderSizePixel = 0
				frame.Parent = tabFrame

				local fc = Instance.new("UICorner")
				fc.CornerRadius = UDim.new(0, 6)
				fc.Parent = frame

				local lbl = Instance.new("TextLabel")
				lbl.Size = UDim2.new(1, -70, 0, 20)
				lbl.Position = UDim2.new(0, 10, 0, 4)
				lbl.BackgroundTransparency = 1
				lbl.Font = Enum.Font.SourceSans
				lbl.TextSize = 14
				lbl.TextColor3 = Color3.fromRGB(220, 220, 230)
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.Text = title
				lbl.Parent = frame

				local valLbl = Instance.new("TextLabel")
				valLbl.Size = UDim2.new(0, 50, 0, 20)
				valLbl.Position = UDim2.new(1, -60, 0, 4)
				valLbl.BackgroundTransparency = 1
				valLbl.Font = Enum.Font.SourceSansBold
				valLbl.TextSize = 14
				valLbl.TextColor3 = Color3.fromRGB(120, 220, 160)
				valLbl.TextXAlignment = Enum.TextXAlignment.Right
				valLbl.Text = tostring(curVal)
				valLbl.Parent = frame

				local barBg = Instance.new("Frame")
				barBg.Size = UDim2.new(1, -20, 0, 8)
				barBg.Position = UDim2.new(0, 10, 0, 28)
				barBg.BackgroundColor3 = Color3.fromRGB(45, 50, 62)
				barBg.BorderSizePixel = 0
				barBg.Parent = frame

				local barCorner = Instance.new("UICorner")
				barCorner.CornerRadius = UDim.new(0, 4)
				barCorner.Parent = barBg

				local fill = Instance.new("Frame")
				local pct = math.clamp((curVal - minVal) / (maxVal - minVal), 0, 1)
				fill.Size = UDim2.new(pct, 0, 1, 0)
				fill.BackgroundColor3 = Color3.fromRGB(120, 220, 160)
				fill.BorderSizePixel = 0
				fill.Parent = barBg

				local fillCorner = Instance.new("UICorner")
				fillCorner.CornerRadius = UDim.new(0, 4)
				fillCorner.Parent = fill

				local sliding = false
				local function updateSlider(inputPos)
					local relX = math.clamp((inputPos.X - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
					local rawVal = minVal + (maxVal - minVal) * relX
					local val = math.floor(rawVal / inc + 0.5) * inc
					val = math.clamp(val, minVal, maxVal)
					curVal = val
					valLbl.Text = tostring(curVal)
					fill.Size = UDim2.new((curVal - minVal) / (maxVal - minVal), 0, 1, 0)
					pcall(cb, curVal)
				end

				barBg.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						sliding = true
						updateSlider(input.Position)
					end
				end)
				UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						sliding = false
					end
				end)
				UserInputService.InputChanged:Connect(function(input)
					if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
						updateSlider(input.Position)
					end
				end)
			end

			function tabObj:CreateButton(bOpts)
				bOpts = bOpts or {}
				local title = bOpts.Title or "Button"
				local cb = bOpts.Callback or function() end

				local btn = Instance.new("TextButton")
				btn.Size = UDim2.new(1, -10, 0, 32)
				btn.BackgroundColor3 = Color3.fromRGB(40, 45, 58)
				btn.Font = Enum.Font.SourceSansBold
				btn.TextSize = 14
				btn.TextColor3 = Color3.fromRGB(240, 240, 250)
				btn.Text = title
				btn.Parent = tabFrame

				local bc = Instance.new("UICorner")
				bc.CornerRadius = UDim.new(0, 6)
				bc.Parent = btn

				btn.MouseButton1Click:Connect(function()
					pcall(cb)
				end)
			end

			return tabObj
		end

		return windowObj
	end

	return FallbackUI
end

local SVUI = genv.SVUI or _G.SVUI
if not SVUI then
	pinUiToPlayerGui()
	local ok, lib = pcall(function()
		return loadstring(game:HttpGet("https://scriptversekey.xyz/svui.lua"))()
	end)
	if ok and type(lib) == "table" then
		SVUI = lib
	end
end
if not SVUI then
	warn("[ScriptVerse] SVUI external library failed to load - using built-in UI fallback")
	SVUI = createFallbackSVUI()
end

local Accent = Color3.fromRGB(120, 220, 160)
local OkGreen = Color3.fromRGB(120, 220, 140)
local WarnOrange = Color3.fromRGB(255, 140, 80)

local function softRequire(inst)
	if typeof(inst) ~= "Instance" then
		return nil
	end
	local ok, mod = pcall(require, inst)
	return ok and mod or nil
end

local Lib = ReplicatedStorage:WaitForChild("Library", 30)
local Client = Lib:WaitForChild("Client", 15)
local Util = Lib:WaitForChild("Util", 15)
local Globals = Lib:WaitForChild("Globals", 15)

local EggCmds = softRequire(Client:WaitForChild("EggCmds", 15))
local PlotCmds = softRequire(Client:WaitForChild("PlotCmds", 15))
local Network = softRequire(Client:WaitForChild("Network", 15))
local Guard = softRequire(Client:WaitForChild("ToolGameplayGuard", 15))
local Lookup = softRequire(Util:WaitForChild("GuardAreaLookupUtil", 15))
local Save = softRequire(Client:WaitForChild("Save", 15))
local BaseUpgrade = softRequire(Client:WaitForChild("BaseUpgradeClient", 15))
local AssetCmds = softRequire(Client:WaitForChild("AssetCmds", 15))
local Constants = softRequire(Globals:WaitForChild("Constants", 15))
local SpeedPowerProjection = softRequire(Client:FindFirstChild("SpeedPowerProjection"))
local TreadmillUtil = softRequire(Util:FindFirstChild("TreadmillUtil"))

if not EggCmds or not PlotCmds or not Guard or not Lookup then
	warn("[ScriptVerse] Steal An Egg modules unavailable")
	genv.SV_SAE_RUNNING = nil
	return
end

local NetMap = (Constants and Constants.NETWORK_MAP) or (Network and Network.NET_MAP)
local PivotKey = (NetMap and NetMap.ClientCharacter and NetMap.ClientCharacter.SET_PIVOT)
	or "ClientCharacter: SetPivot"
local ImpulseKey = (NetMap and NetMap.ClientCharacter and NetMap.ClientCharacter.BEGIN_IMPULSE)
	or "ClientCharacter: BeginImpulse"

local SeparationLine = nil
local cachedPlayPos, cachedSafePos

local function getSeparationLine()
	if SeparationLine and SeparationLine.Parent then
		return SeparationLine
	end
	local objs = Workspace:FindFirstChild("__OBJECTS") or Workspace:WaitForChild("__OBJECTS", 20)
	if not objs then
		return nil
	end
	local areas = objs:FindFirstChild("Areas")
	if not areas then
		return nil
	end
	SeparationLine = areas:FindFirstChild("SeparationLine")
	return SeparationLine
end

local function netInvoke(key, ...)
	if not Network or not key then
		return false
	end
	local args = table.pack(...)
	local ok, a = pcall(function()
		return Network.Invoke(key, table.unpack(args, 1, args.n))
	end)
	return ok and a == true
end

local function netFire(key, ...)
	if not Network or not key then
		return
	end
	local args = table.pack(...)
	pcall(function()
		Network.Fire(key, table.unpack(args, 1, args.n))
	end)
end

local conns = {}
local espPool = {}
local flyConn, noclipConn, infJumpConn

local State = {
	running = true,
	busy = false,
	busySince = nil,
	status = "Idle",

	carrying = false,

	instantSteal = false,
	autofarm = false,
	preferHighValue = true,
	autoReturn = true,
	autoDrop = false,
	serverHop = false,
	hopTarget = "",
	allAreas = true,
	areaCursor = 1,

	autoSellEggs = false,
	autoPlace = false,
	autoHatch = false,
	autoEquipBest = false,
	autoFuse = false,
	autoSellPets = false,
	neverSellMutated = true,
	neverSellEquipped = true,

	claimOffline = false,
	autoUpgrade = false,
	autoTreadmill = false,
	autoClaimIndex = false,
	autoGroupReward = false,
	autoBuyTrail = false,
	autoEquipTrail = false,
	autoEquipGear = false,

	espWorldEgg = false,
	espCarriedEgg = false,
	espGuard = false,
	espPet = false,
	espPlayer = false,
	espMachine = false,
	espPlot = false,

	speedOn = false,
	walkSpeed = 32,
	jumpOn = false,
	jumpPower = 80,
	infJump = false,
	noclip = false,
	fly = false,
	flySpeed = 32,
	antiAfk = true,

	travelSpeed = 16,
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
	lastHop = 0,
	lastAfk = 0,
}

local function notify(title, content, color, dur)
	pcall(function()
		SVUI:Notify({
			Title = title,
			Content = content,
			Duration = dur or 2.2,
			Color = color or Accent,
		})
	end)
end

local function track(conn)
	table.insert(conns, conn)
	return conn
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

local function root()
	local char = LocalPlayer.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function hum()
	local char = LocalPlayer.Character
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function zeroVel(part)
	if not part then
		return
	end
	part.AssemblyLinearVelocity = Vector3.zero
	part.AssemblyAngularVelocity = Vector3.zero
end

local function waitRoot(timeout)
	timeout = timeout or 15
	local char = LocalPlayer.Character
	if not char then
		char = LocalPlayer.CharacterAdded:Wait()
	end
	return char:WaitForChild("HumanoidRootPart", timeout)
end

local AssetsDirectory = nil
pcall(function()
	local Assets = require(ReplicatedStorage.Directory.Assets)
	AssetsDirectory = Assets and Assets.Directory
end)

local function burstPivot(cf, fires)
	local r = root()
	if not r or not cf then
		return
	end
	fires = fires or 2
	for _ = 1, fires do
		if Network and PivotKey then
			pcall(function()
				Network.Fire(PivotKey, cf)
			end)
		end
		r.CFrame = cf
		zeroVel(r)
		task.wait(0.014)
	end
end

local function smoothPath(goal, steps, firesPerStep)
	local r = root()
	if not r or not goal then
		return false
	end
	steps = steps or 16
	firesPerStep = firesPerStep or 2
	local from = r.Position
	for i = 1, steps do
		if not State.running then
			return false
		end
		r = root()
		if not r then
			return false
		end
		local p = from:Lerp(goal, i / steps)
		burstPivot(CFrame.new(p.X, math.max(p.Y, r.Position.Y), p.Z), firesPerStep)
	end
	return true
end

local function pivotTo(cf)
	burstPivot(cf, 3)
end

local function pivotPath(goal, steps)
	return smoothPath(goal, steps or 16, 2)
end

local function fastTp(cf)
	burstPivot(cf, 3)
	return true
end

local function lerpTp(from, to, steps)
	if typeof(to) == "Vector3" then
		return smoothPath(to, steps or 16, 2)
	end
	return smoothPath(to.Position, steps or 16, 2)
end

local function fastPath(goal, steps)
	local r = root()
	if not r or not goal then
		return false
	end
	steps = steps or 16
	local from = r.Position
	for i = 1, steps do
		if not State.running then
			return false
		end
		r = root()
		if not r then
			return false
		end
		local p = from:Lerp(goal, i / steps)
		local cf = CFrame.new(p.X, math.max(p.Y, r.Position.Y), p.Z)
		if Network and PivotKey then
			pcall(function()
				Network.Fire(PivotKey, cf)
			end)
		end
		r.CFrame = cf
		zeroVel(r)
		task.wait(0.009)
	end
	return true
end

local function travelTo(goal)
	local r = root()
	if not r then
		return false
	end
	if (r.Position - goal).Magnitude > 8 then
		smoothPath(goal, 18, 2)
	end
	burstPivot(CFrame.new(goal), 2)
	return true
end

local function inGameplay()
	if type(Guard.IsLocalPlayerInGameplayArea) == "function" then
		return Guard.IsLocalPlayerInGameplayArea() == true
	end
	return false
end

local function onGameplaySide(pos)
	local line = getSeparationLine()
	if not line or not pos then
		return false
	end
	if type(Lookup.IsInGameplaySide) == "function" then
		return Lookup.IsInGameplaySide(line, pos) == true
	end
	local rel = line.CFrame:PointToObjectSpace(pos)
	return rel.Z > 0
end

local function resolveArenaPoints()
	local line = getSeparationLine()
	if not line then
		return nil, nil
	end
	if cachedPlayPos and cachedSafePos then
		return cachedPlayPos, cachedSafePos
	end

	local tryPlay = {
		line.Position + Vector3.new(55, 4, 0),
		line.Position + line.CFrame.LookVector * 45 + Vector3.new(0, 4, 0),
		line.Position - line.CFrame.LookVector * 45 + Vector3.new(0, 4, 0),
	}
	for _, p in ipairs(tryPlay) do
		if onGameplaySide(p) then
			cachedPlayPos = p
			break
		end
	end
	if not cachedPlayPos then
		for x = -80, 80, 5 do
			for z = -80, 80, 5 do
				local p = line.Position + Vector3.new(x, 4, z)
				if onGameplaySide(p) then
					cachedPlayPos = p
					break
				end
			end
			if cachedPlayPos then
				break
			end
		end
	end
	cachedPlayPos = cachedPlayPos or (line.Position + Vector3.new(55, 4, 0))

	local trySafe = {
		line.Position - Vector3.new(55, 4, 0),
		line.Position - line.CFrame.LookVector * 30 + Vector3.new(0, 4, 0),
		line.Position + line.CFrame.LookVector * -30 + Vector3.new(0, 4, 0),
	}
	for _, p in ipairs(trySafe) do
		if not onGameplaySide(p) then
			cachedSafePos = p
			break
		end
	end
	cachedSafePos = cachedSafePos or (line.Position - Vector3.new(55, 4, 0))
	return cachedPlayPos, cachedSafePos
end

local function walkRunTo(goal, speed, timeout)
	local h = hum()
	if not h or not goal then
		return false
	end
	speed = math.min(speed or 16, 16)
	timeout = timeout or 45
	local saved = h.WalkSpeed
	h.WalkSpeed = speed
	h:MoveTo(goal)
	local t0 = os.clock()
	while os.clock() - t0 < timeout and State.running do
		local r = root()
		if not r then
			break
		end
		local dist = (goal - r.Position).Magnitude
		if dist <= 4.5 then
			h.WalkSpeed = saved
			h:Move(Vector3.zero, false)
			return true
		end
		local flat = Vector3.new(goal.X - r.Position.X, 0, goal.Z - r.Position.Z)
		if flat.Magnitude > 0.3 then
			h:Move(flat.Unit, false)
		end
		task.wait(0.15)
	end
	h.WalkSpeed = saved
	h:Move(Vector3.zero, false)
	local r = root()
	return r and (r.Position - goal).Magnitude <= 10
end

local function freezeSpeedPower()
	local fn = SpeedPowerProjection and SpeedPowerProjection.GetSpeedPower
	if type(fn) ~= "function" or type(setupvalue) ~= "function" or type(getupvalue) ~= "function" then
		return
	end
	pcall(function()
		for i = 1, 12 do
			local v = getupvalue(fn, i)
			if type(v) == "number" then
				setupvalue(fn, i, 1e7)
				break
			end
		end
	end)
	pcall(function()
		local d = Save and Save.Get and Save.Get()
		if type(d) == "table" and type(d.SpeedPower) == "number" and d.SpeedPower < 1e6 then
			d.SpeedPower = 1e7
		end
	end)
end

local speedBV

local function applySpeed()
	local r = root()
	local h = hum()
	if State.speedOn or State.fly then
		freezeSpeedPower()
	end
	-- Never overwrite Humanoid.WalkSpeed - game derives it from SpeedPower and kills you if it desyncs.
	if speedBV and (not State.speedOn or not r or speedBV.Parent ~= r) then
		pcall(function()
			speedBV:Destroy()
		end)
		speedBV = nil
	end
	if State.speedOn and r then
		if not speedBV or speedBV.Parent ~= r then
			speedBV = Instance.new("BodyVelocity")
			speedBV.Name = "SV_Speed"
			speedBV.MaxForce = Vector3.new(8e4, 0, 8e4)
			speedBV.Parent = r
		end
		local dir = Vector3.zero
		if h and h.MoveDirection.Magnitude > 0.05 then
			dir = Vector3.new(h.MoveDirection.X, 0, h.MoveDirection.Z).Unit
		end
		speedBV.Velocity = dir * State.walkSpeed
	end
end

local function eggValue(rec)
	local score = 0
	local cat = rec and rec.AssetCategory
	if cat and AssetsDirectory then
		local entry = AssetsDirectory[cat]
		if entry and entry.Rarity and type(entry.Rarity.RarityNumber) == "number" then
			score = entry.Rarity.RarityNumber
		end
	end
	if type(rec.Mutations) == "table" then
		score = score + #rec.Mutations * 50
	end
	if rec.IsRare == true or rec.Rare == true then
		score = score + 200
	end
	return score
end

local function getAreaEggSnapshot()
	local snap
	if type(EggCmds.GetAreaEggSnapshot) == "function" then
		snap = EggCmds.GetAreaEggSnapshot()
	end
	if (not snap or not snap.Records) and type(EggCmds.RequestAreaEggSnapshot) == "function" then
		pcall(function()
			snap = EggCmds.RequestAreaEggSnapshot()
		end)
	end
	return snap
end

local function listGameplayEggs(filterName)
	local snap = getAreaEggSnapshot()
	local r = root()
	local list = {}
	for _, rec in pairs((snap and snap.Records) or {}) do
		if type(rec) == "table" and rec.State == "Slot" and type(rec.Uid) == "string" then
			if #rec.Uid >= 32 and not rec.Uid:find(":", 1, true) and not rec.Uid:find("FirstArea", 1, true) then
				local pos = rec.BottomCFrame and rec.BottomCFrame.Position
				if pos and onGameplaySide(pos) then
					if filterName == "" or string.find(string.lower(rec.AssetCategory or ""), string.lower(filterName), 1, true) then
						list[#list + 1] = {
							rec = rec,
							dist = r and (pos - r.Position).Magnitude or math.huge,
							value = eggValue(rec),
						}
					end
				end
			end
		end
	end
	if State.preferHighValue then
		table.sort(list, function(a, b)
			if a.value ~= b.value then
				return a.value > b.value
			end
			return a.dist < b.dist
		end)
	else
		table.sort(list, function(a, b)
			return a.dist < b.dist
		end)
	end
	return list
end

local function crossToArena()
	if inGameplay() then
		return true
	end
	local line = getSeparationLine()
	if not line then
		return false
	end
	local playPos = line.Position + Vector3.new(55, 4, 0)
	local safePos = line.Position - Vector3.new(55, 4, 0)

	State.status = "Walking to arena"
	walkRunTo(safePos, 16, 20)
	walkRunTo(playPos, 16, 25)
	task.wait(0.2)
	return inGameplay()
end

local function findEggPrompt(uid, pos)
	local function nearPrompt(inst)
		if not inst:IsA("ProximityPrompt") or not inst.Enabled then
			return false
		end
		local part = inst.Parent
		if not part or not part:IsA("BasePart") or not pos then
			return false
		end
		return (part.Position - pos).Magnitude < 10
	end

	if uid then
		local model = Workspace:FindFirstChild(uid, true)
		if model then
			local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
			if prompt then
				return prompt
			end
		end
	end

	local objs = Workspace:FindFirstChild("__OBJECTS")
	if objs then
		for _, inst in ipairs(objs:GetDescendants()) do
			if nearPrompt(inst) then
				return inst
			end
		end
	end

	for _, inst in ipairs(Workspace:GetDescendants()) do
		if nearPrompt(inst) then
			return inst
		end
	end
	return nil
end

local function holdProximityPrompt(prompt)
	if not prompt or not prompt.Enabled then
		return false
	end
	local hold = math.max(prompt.HoldDuration or 0.5, 0.4) + 0.25
	if typeof(fireproximityprompt) == "function" then
		local ok = pcall(fireproximityprompt, prompt, hold)
		if ok then
			task.wait(hold + 0.1)
			return true
		end
	end
	local ok = pcall(function()
		prompt:InputHoldBegin()
		task.wait(hold)
		prompt:InputHoldEnd()
	end)
	task.wait(0.1)
	return ok
end

local function eggIsCarried(uid)
	if type(EggCmds.GetAreaEggRecord) == "function" and uid then
		local rec = EggCmds.GetAreaEggRecord(uid)
		if rec and rec.State == "Carried" then
			return true
		end
	end
	return State.carrying == true
end

local function waitUntilCarrying(uid, timeout)
	timeout = timeout or 6
	local t0 = os.clock()
	while os.clock() - t0 < timeout and State.running do
		if eggIsCarried(uid) or State.carrying then
			return true
		end
		task.wait(0.08)
	end
	return eggIsCarried(uid) or State.carrying
end

local function pickNearestEgg()
	local eggs = listGameplayEggs("")
	if #eggs == 0 then
		return nil
	end
	table.sort(eggs, function(a, b)
		return a.dist < b.dist
	end)
	if State.preferHighValue then
		local best = eggs[1]
		for i = 1, math.min(5, #eggs) do
			if eggs[i].value > best.value then
				best = eggs[i]
			end
		end
		return best.rec
	end
	return eggs[1].rec
end

local function requestCarry(uid, rec)
	local slotKey = uid:match(":(.+)$")
	if not slotKey and rec and rec.NestId then
		slotKey = rec.NestId
	end
	if slotKey and slotKey ~= "" then
		local s, ok = pcall(function()
			return EggCmds.RequestCarryAreaEgg(uid, slotKey)
		end)
		if s and ok == true then
			return true
		end
	end
	local s, ok, err = pcall(function()
		return EggCmds.RequestCarryAreaEgg(uid)
	end)
	if s and ok == true then
		return true
	end
	return false, s and tostring(err or ok) or "Carry failed"
end

local function goNear(pos)
	return walkRunTo(pos + Vector3.new(0, 2, 0), 16, 40)
end

local function grabEgg(rec)
	local uid = rec.Uid
	local pos = rec.BottomCFrame and rec.BottomCFrame.Position
	if not uid or not pos then
		return false, "No egg"
	end

	if not inGameplay() then
		if not crossToArena() then
			return false, "Not in arena"
		end
		task.wait(0.15)
	end

	if not inGameplay() then
		return false, "Enter arena first"
	end

	State.status = "Going to egg"
	if not goNear(pos) then
		return false, "Could not reach egg"
	end

	local prompt = findEggPrompt(uid, pos)
	for attempt = 1, 3 do
		if eggIsCarried(uid) or State.carrying then
			break
		end
		if prompt then
			State.status = "Hold to grab"
			holdProximityPrompt(prompt)
		end
		if waitUntilCarrying(uid, 1.2) then
			break
		end
		local ok = requestCarry(uid, rec)
		if ok == true or waitUntilCarrying(uid, 1.5) then
			break
		end
		goNear(pos)
		prompt = findEggPrompt(uid, pos)
	end

	if eggIsCarried(uid) or State.carrying or waitUntilCarrying(uid, 2) then
		State.carrying = true
		return true
	end
	return false, "Could not grab egg"
end

local function fleeToPlot()
	local home = PlotCmds.GetRespawnPointCFrame(LocalPlayer)
	local line = getSeparationLine()
	if not home or not line then
		return false
	end

	State.status = "Back to plot"
	local exitPt = line.Position - line.CFrame.LookVector * 38 + Vector3.new(0, 3, 0)
	local hp = home.Position + Vector3.new(0, 3, 0)

	if inGameplay() then
		walkRunTo(exitPt, 16, 45)
	end
	walkRunTo(hp, 16, 50)
	applySpeed()
	return true
end

local function returnHomeAndClaim()
	if not fleeToPlot() then
		return false
	end

	task.wait(2)

	local claimed = false
	if EggCmds.AreaEggClaimed and type(EggCmds.AreaEggClaimed.Connect) == "function" then
		local conn = EggCmds.AreaEggClaimed:Connect(function()
			claimed = true
		end)
		task.wait(2.5)
		pcall(function()
			conn:Disconnect()
		end)
	end

	local r = root()
	local home = PlotCmds.GetRespawnPointCFrame(LocalPlayer)
	local atPlot = home and r and (r.Position - home.Position).Magnitude < 20
	if not claimed and (atPlot or not inGameplay()) then
		claimed = true
	end

	State.carrying = false
	State.status = claimed and "Egg secured" or "At plot"
	return claimed
end

local function walkTo(goal)
	local r = root()
	if not r then
		return false
	end
	local pos = typeof(goal) == "Vector3" and goal or (goal and goal.Position)
	if not pos then
		return false
	end
	return lerpTp(r.Position, pos, 12)
end

local function ensureGameplay()
	return crossToArena()
end

local function goHome()
	return returnHomeAndClaim()
end

local function stealOneCycle()
	if State.busy then
		return false
	end
	State.busy = true
	State.busySince = os.clock()

	local ok, result = pcall(function()
		if not waitRoot(12) then
			notify("Steal", "Spawn in first", WarnOrange, 2)
			return false
		end

		if not crossToArena() or not inGameplay() then
			notify("Steal", "Could not enter arena", WarnOrange, 2.5)
			return false
		end

		pcall(function()
			if EggCmds.RequestAreaEggSnapshot then
				EggCmds.RequestAreaEggSnapshot()
			end
		end)
		task.wait(0.15)

		local egg = pickNearestEgg()
		if not egg then
			notify("Steal", "No eggs in arena", WarnOrange, 2)
			return false
		end

		local label = egg.AssetCategory or "egg"
		local grabbed, grabErr = grabEgg(egg)
		if not grabbed then
			notify("Steal", tostring(grabErr or "Grab failed"), WarnOrange, 2.5)
			return false
		end

		returnHomeAndClaim()
		State.lastSteal = os.clock()
		notify("Steal", "Delivered " .. label .. " to base", OkGreen, 2.5)
		return true
	end)

	State.busy = false
	State.busySince = nil

	if not ok then
		warn("[ScriptVerse]", result)
		local msg = tostring(result):gsub("^%s+", ""):sub(1, 72)
		notify("Steal", msg ~= "" and msg or "Error - try again", WarnOrange, 3)
		return false
	end
	return result == true
end

local function tryCarryEgg(target)
	return grabEgg(target)
end

local function autofarmCycle()
	return stealOneCycle()
end

genv.SV_SAE_STEAL = stealOneCycle

local function doStealOnce()
	return stealOneCycle()
end

local function getPlotPlaceCFrame()
	local data = PlotCmds.GetPlotData(LocalPlayer)
	if not data then
		return nil
	end
	local petArea = data.PetArea
	if petArea and petArea:IsA("BasePart") then
		return petArea.CFrame * CFrame.new(0, 2, -4)
	end
	local home = PlotCmds.GetRespawnPointCFrame(LocalPlayer)
	return home and home * CFrame.new(0, 0, -6)
end

local function placeInventoryEggs()
	if not State.autoPlace then
		return
	end
	if os.clock() - State.lastPlace < 1.5 then
		return
	end
	local cf = getPlotPlaceCFrame()
	if not cf then
		return
	end
	local records = EggCmds.GetOwnerRuntimeRecords(LocalPlayer.UserId) or {}
	for uid, rec in pairs(records) do
		if type(rec) == "table" and rec.Placement == nil then
			local ok = EggCmds.RequestPlaceEgg(uid, cf)
			if ok == true then
				State.lastPlace = os.clock()
				return
			end
		end
	end
end

local function hatchReadyEggs()
	if not State.autoHatch then
		return
	end
	if os.clock() - State.lastHatch < 1.5 then
		return
	end
	local records = EggCmds.GetOwnerRuntimeRecords(LocalPlayer.UserId) or {}
	for uid in pairs(records) do
		if type(EggCmds.IsLocalEggReady) == "function" and EggCmds.IsLocalEggReady(uid) then
			local ok = EggCmds.RequestHatchEgg(uid)
			if ok == true then
				pcall(function()
					EggCmds.RequestCompleteHatchEgg(uid)
				end)
				State.lastHatch = os.clock()
				return
			end
		end
	end
end

local function petHasMutation(item)
	if type(item) ~= "table" then
		return false
	end
	if item.BaseMutation and item.BaseMutation ~= "" and item.BaseMutation ~= "None" then
		return true
	end
	if type(item.Mutations) == "table" then
		for _, m in ipairs(item.Mutations) do
			if m and m ~= "None" then
				return true
			end
		end
	end
	return false
end

local function tryEquipBest()
	if not State.autoEquipBest or not NetMap or not NetMap.Backpack then
		return
	end
	if os.clock() - State.lastEquip < 4 then
		return
	end
	if netInvoke(NetMap.Backpack.EQUIP_BEST) then
		State.lastEquip = os.clock()
	end
end

local function trySellPets()
	if not State.autoSellPets or not NetMap or not NetMap.ActiveAssets then
		return
	end
	if os.clock() - State.lastSell < 3 then
		return
	end
	if not AssetCmds then
		return
	end
	local records = AssetCmds.GetOwnerRuntimeRecords(LocalPlayer.UserId) or {}
	for uid, rec in pairs(records) do
		if type(rec) == "table" and type(rec.ItemData) == "table" then
			local skip = (State.neverSellMutated and petHasMutation(rec.ItemData))
				or (State.neverSellEquipped and rec.Equipped)
			if not skip and netInvoke(NetMap.ActiveAssets.REQUEST_SELL, uid) then
				State.lastSell = os.clock()
				return
			end
		end
	end
end

local function tryFuse()
	if not State.autoFuse or not NetMap or not NetMap.FuseMachine then
		return
	end
	if os.clock() - State.lastFuse < 8 then
		return
	end
	if netInvoke(NetMap.FuseMachine.REQUEST_START_FUSE or NetMap.FuseMachine.START_FUSE) then
		State.lastFuse = os.clock()
	end
end

local function tryOffline()
	if not State.claimOffline or not NetMap or not NetMap.OfflineAssets then
		return
	end
	if os.clock() - State.lastOffline < 15 then
		return
	end
	if netInvoke(NetMap.OfflineAssets.REQUEST_REDEEM or NetMap.OfflineAssets.REDEEM) then
		State.lastOffline = os.clock()
	end
end

local function tryUpgrade()
	if not State.autoUpgrade or not BaseUpgrade then
		return
	end
	if os.clock() - State.lastUpgrade < 5 then
		return
	end
	local save = Save and Save.Get(LocalPlayer, false)
	if save and BaseUpgrade.CanAffordNext(save) then
		BaseUpgrade.RequestCashUpgrade()
		State.lastUpgrade = os.clock()
	end
end

local function tryIndex()
	if not State.autoClaimIndex or not NetMap or not NetMap.Index then
		return
	end
	if os.clock() - State.lastIndex < 20 then
		return
	end
	if netInvoke(NetMap.Index.REQUEST_CLAIM_ALL) then
		State.lastIndex = os.clock()
	end
end

local function tryGroupReward()
	if not State.autoGroupReward or not NetMap or not NetMap.GroupReward then
		return
	end
	if os.clock() - State.lastGroup < 30 then
		return
	end
	if netInvoke(NetMap.GroupReward.REQUEST_CLAIM or NetMap.GroupReward.CLAIM_REWARD) then
		State.lastGroup = os.clock()
	end
end

local function tryTrails()
	if not NetMap or not NetMap.Trails then
		return
	end
	if State.autoBuyTrail and os.clock() - State.lastTrail > 12 then
		if netInvoke(NetMap.Trails.REQUEST_PURCHASE) then
			State.lastTrail = os.clock()
		end
	end
	if State.autoEquipTrail then
		netInvoke(NetMap.Trails.REQUEST_ACTIVE_SNAPSHOT)
	end
end

local function tryTreadmill()
	if not State.autoTreadmill or not NetMap or not NetMap.Treadmills then
		return
	end
	if os.clock() - State.lastTreadmill < 6 then
		return
	end
	if netInvoke(NetMap.Treadmills.REQUEST_EQUIP_STATIC) then
		State.lastTreadmill = os.clock()
	end
end

local function trySellEggs()
	if not State.autoSellEggs or not NetMap or not NetMap.AssetInventory then
		return
	end
	local key = NetMap.AssetInventory.REQUEST_SELL_ALL or NetMap.AssetInventory.SELL_ALL_ASSETS
	if key then
		netFire(key)
	end
end

local function farmTick()
	if State.busy then
		if State.busySince and os.clock() - State.busySince > 90 then
			State.busy = false
			State.busySince = nil
			warn("[ScriptVerse] Autofarm busy timeout - reset")
		else
			return
		end
	end
	if not State.autofarm then
		return
	end
	autofarmCycle()
end

-- â”€â”€ ESP â”€â”€

local function clearEsp()
	for _, d in ipairs(espPool) do
		pcall(function()
			if d.line then
				d.line:Remove()
			end
			if d.text then
				d.text:Remove()
			end
			if d.hl then
				d.hl:Destroy()
			end
		end)
	end
	table.clear(espPool)
end

local function addHighlight(inst, color, label)
	if not inst or not inst.Parent then
		return
	end
	local hl = Instance.new("Highlight")
	hl.FillTransparency = 0.65
	hl.OutlineTransparency = 0.2
	hl.FillColor = color
	hl.OutlineColor = color
	hl.Adornee = inst:IsA("Model") and inst or inst:FindFirstAncestorWhichIsA("Model") or inst
	hl.Parent = inst
	table.insert(espPool, { hl = hl, label = label })
end

local function refreshEsp()
	clearEsp()
	if not State.running then
		return
	end

	if State.espWorldEgg then
		for _, e in ipairs(listGameplayEggs("")) do
			local model = Workspace:FindFirstChild(e.rec.Uid, true)
			if model then
				addHighlight(model, Color3.fromRGB(255, 220, 90), e.rec.AssetCategory)
			end
		end
	end

	if State.espPlot then
		local folder = PlotCmds.GetPlotsFolder and PlotCmds.GetPlotsFolder()
		if folder then
			for _, plot in ipairs(folder:GetChildren()) do
				addHighlight(plot, Color3.fromRGB(90, 180, 255), plot.Name)
			end
		end
	end

	if State.espGuard then
		local guardAreas = Workspace:FindFirstChild("__OBJECTS")
			and Workspace.__OBJECTS:FindFirstChild("Areas")
			and Workspace.__OBJECTS.Areas:FindFirstChild("GuardAreas")
		if guardAreas then
			for _, area in ipairs(guardAreas:GetChildren()) do
				local guard = area:FindFirstChild("Guard")
				if guard then
					addHighlight(guard, Color3.fromRGB(255, 80, 80), "Guard")
				end
			end
		end
	end

	if State.espPlayer then
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= LocalPlayer and plr.Character then
				addHighlight(plr.Character, Color3.fromRGB(255, 120, 120), plr.Name)
			end
		end
	end

	if State.espPet and AssetCmds then
		local records = AssetCmds.GetOwnerRuntimeRecords(LocalPlayer.UserId) or {}
		for uid in pairs(records) do
			local model = Workspace:FindFirstChild(uid, true)
			if model then
				addHighlight(model, Color3.fromRGB(120, 255, 160), "Pet")
			end
		end
	end

	if State.espMachine then
		for _, inst in ipairs(Workspace:GetDescendants()) do
			if inst.Name:find("Fuse") or inst.Name:find("Treadmill") then
				if inst:IsA("Model") then
					addHighlight(inst, Color3.fromRGB(180, 120, 255), inst.Name)
				end
			end
		end
	end
end

-- â”€â”€ Movement extras â”€â”€

local function setNoclip(on)
	if noclipConn then
		noclipConn:Disconnect()
		noclipConn = nil
	end
	if not on then
		return
	end
	noclipConn = track(RunService.Stepped:Connect(function()
		local char = LocalPlayer.Character
		if not char then
			return
		end
		for _, p in ipairs(char:GetDescendants()) do
			if p:IsA("BasePart") then
				p.CanCollide = false
			end
		end
	end))
end

local flyBV, flyBG

local function setFly(on)
	if flyConn then
		flyConn:Disconnect()
		flyConn = nil
	end
	if flyBV then
		pcall(function()
			flyBV:Destroy()
		end)
		flyBV = nil
	end
	if flyBG then
		pcall(function()
			flyBG:Destroy()
		end)
		flyBG = nil
	end
	if not on then
		return
	end
	flyConn = track(RunService.Heartbeat:Connect(function()
		local r = root()
		local h = hum()
		if not r or not h then
			return
		end
		local cam = Workspace.CurrentCamera
		if not cam then
			return
		end
		if not flyBV or not flyBV.Parent then
			flyBV = Instance.new("BodyVelocity")
			flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
			flyBV.Velocity = Vector3.zero
			flyBV.Parent = r
			flyBG = Instance.new("BodyGyro")
			flyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
			flyBG.P = 3000
			flyBG.Parent = r
		end
		local dir = Vector3.zero
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then
			dir += cam.CFrame.LookVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then
			dir -= cam.CFrame.LookVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then
			dir -= cam.CFrame.RightVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then
			dir += cam.CFrame.RightVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			dir += Vector3.yAxis
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
			dir -= Vector3.yAxis
		end
		if dir.Magnitude < 0.05 and h.MoveDirection.Magnitude > 0.1 then
			dir = Vector3.new(h.MoveDirection.X, 0, h.MoveDirection.Z)
		end
		flyBV.Velocity = dir.Magnitude > 0 and dir.Unit * State.flySpeed or Vector3.zero
		flyBG.CFrame = cam.CFrame
		freezeSpeedPower()
	end))
end

local function setInfJump(on)
	if infJumpConn then
		infJumpConn:Disconnect()
		infJumpConn = nil
	end
	if not on then
		return
	end
	local UIS = game:GetService("UserInputService")
	infJumpConn = track(UIS.JumpRequest:Connect(function()
		local h = hum()
		if h then
			h:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end))
end

-- â”€â”€ UI (PlayerGui only) â”€â”€

pinUiToPlayerGui()
task.wait(0.15)

local Window = SVUI:CreateWindow({
	Title = "Steal An Egg",
	Subtitle = "ScriptVerse",
})

pcall(function()
	local pg = LocalPlayer:WaitForChild("PlayerGui")
	if Window and Window.Gui then
		Window.Gui.Parent = pg
		Window.Gui.DisplayOrder = 10
	end
end)

local CharTab = Window:CreateTab({ Title = "Character" })
local EspTab = Window:CreateTab({ Title = "ESP" })

CharTab:CreateSection("Movement")
CharTab:CreateToggle({
	Title = "Walk Speed",
	Default = false,
	Callback = function(v)
		State.speedOn = v
		applySpeed()
		notify("Speed", v and "On" or "Off", v and OkGreen or WarnOrange)
	end,
})
CharTab:CreateSlider({
	Title = "Speed",
	Min = 16,
	Max = 80,
	Default = 32,
	Increment = 1,
	Callback = function(v)
		State.walkSpeed = v
		if State.speedOn then
			applySpeed()
		end
	end,
})
CharTab:CreateToggle({
	Title = "Fly",
	Default = false,
	Callback = function(v)
		State.fly = v
		setFly(v)
		notify("Fly", v and "WASD + Space / Ctrl" or "Off", v and OkGreen or WarnOrange)
	end,
})
CharTab:CreateSlider({
	Title = "Fly Speed",
	Min = 16,
	Max = 80,
	Default = 32,
	Increment = 1,
	Callback = function(v)
		State.flySpeed = v
	end,
})
CharTab:CreateButton({
	Title = "Unload",
	Callback = function()
		pcall(genv.SV_SAE_SHUTDOWN)
	end,
})

EspTab:CreateSection("ESP")
local espOpts = {
	{ "World Egg ESP", "espWorldEgg" },
	{ "Carried Egg ESP", "espCarriedEgg" },
	{ "Guard ESP", "espGuard" },
	{ "Pet ESP", "espPet" },
	{ "Player ESP", "espPlayer" },
	{ "Machine ESP", "espMachine" },
	{ "Plot ESP", "espPlot" },
}
for _, pair in ipairs(espOpts) do
	EspTab:CreateToggle({
		Title = pair[1],
		Default = false,
		Callback = function(v)
			State[pair[2]] = v
			refreshEsp()
		end,
	})
end

-- â”€â”€ Loops â”€â”€

track(LocalPlayer.CharacterAdded:Connect(function()
	task.wait(0.5)
	if State.speedOn then
		applySpeed()
	end
	if State.fly then
		setFly(true)
	end
end))

track(RunService.Heartbeat:Connect(function()
	if not State.running then
		return
	end
	if State.speedOn or State.fly then
		freezeSpeedPower()
	end
	if State.speedOn then
		applySpeed()
	end
	if State.antiAfk and os.clock() - State.lastAfk > 900 then
		State.lastAfk = os.clock()
		pcall(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new(0, 0))
		end)
	end
end))

track(task.spawn(function()
	while State.running do
		if State.espWorldEgg or State.espCarriedEgg or State.espGuard or State.espPet or State.espPlayer or State.espMachine or State.espPlot then
			refreshEsp()
		end
		task.wait(2.5)
	end
end))

genv.SV_SAE_SHUTDOWN = function()
	State.running = false
	for _, c in ipairs(conns) do
		pcall(function()
			c:Disconnect()
		end)
	end
	table.clear(conns)
	clearEsp()
	setNoclip(false)
	setFly(false)
	setInfJump(false)
	if speedBV then
		pcall(function()
			speedBV:Destroy()
		end)
		speedBV = nil
	end
	genv.SV_SAE_RUNNING = nil
	genv.SV_SAE_SHUTDOWN = nil
end

notify("Steal An Egg", "Character + ESP", OkGreen, 3)
