local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ==========================================
-- 1. CÀI ĐẶT MẶC ĐỊNH
-- ==========================================
local Settings = {
    Box = true,
    Tracer = true,
    Name = true,
    Health = true
}

-- ==========================================
-- 2. TẠO GUI CHÍNH & KHUNG BẢO VỆ (ANTI-CRASH)
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "EspUltraMenu"
ScreenGui.ResetOnSpawn = false

-- Thử gắn vào CoreGui, nếu lỗi (do Executor) thì gắn vào PlayerGui
local success = pcall(function()
    ScreenGui.Parent = CoreGui
end)
if not success then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- ==========================================
-- 3. NÚT BẤM MỞ MENU (TOGGLE BUTTON)
-- ==========================================
local OpenBtn = Instance.new("TextButton")
OpenBtn.Size = UDim2.new(0, 100, 0, 40)
OpenBtn.Position = UDim2.new(0, 10, 0.5, -20)
OpenBtn.Text = "OPEN MENU"
OpenBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
OpenBtn.TextColor3 = Color3.new(0, 0, 0)
OpenBtn.Font = Enum.Font.SourceSansBold
OpenBtn.TextSize = 14
OpenBtn.Parent = ScreenGui

local UICornerBtn = Instance.new("UICorner")
UICornerBtn.CornerRadius = UDim.new(0, 8)
UICornerBtn.Parent = OpenBtn

-- ==========================================
-- 4. KHUNG MENU ĐIỀU KHIỂN CHÍNH
-- ==========================================
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 220, 0, 280)
MainFrame.Position = UDim2.new(0.5, -110, 0.5, -140)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.Visible = false -- Mặc định ẩn
MainFrame.Active = true
MainFrame.Draggable = true -- Hỗ trợ kéo thả
MainFrame.Parent = ScreenGui

local UICornerFrame = Instance.new("UICorner")
UICornerFrame.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 45)
Title.Text = "ESP CONTROL"
Title.TextColor3 = Color3.fromRGB(0, 255, 255)
Title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 20
Title.Parent = MainFrame

-- Hàm xử lý ẩn/hiện Menu
OpenBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
    OpenBtn.Text = MainFrame.Visible and "CLOSE" or "OPEN MENU"
    OpenBtn.BackgroundColor3 = MainFrame.Visible and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(0, 255, 255)
end)

-- Tạo nút chức năng (Toggle)
local function CreateToggle(text, pos, settingKey)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0.9, 0, 0, 40)
    Btn.Position = UDim2.new(0.05, 0, 0, pos)
    Btn.Text = text .. ": ON"
    Btn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
    Btn.TextColor3 = Color3.new(1, 1, 1)
    Btn.Font = Enum.Font.SourceSansBold
    Btn.TextSize = 16
    Btn.Parent = MainFrame

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Btn

    Btn.MouseButton1Click:Connect(function()
        Settings[settingKey] = not Settings[settingKey]
        Btn.Text = text .. (Settings[settingKey] and ": ON" or ": OFF")
        Btn.BackgroundColor3 = Settings[settingKey] and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(180, 0, 0)
    end)
end

CreateToggle("Box ESP", 60, "Box")
CreateToggle("Tracer (Line)", 110, "Tracer")
CreateToggle("Name & Distance", 160, "Name")
CreateToggle("Health Bar", 210, "Health")

-- ==========================================
-- 5. LOGIC VẼ ESP (DRAWING API)
-- ==========================================
local function CreateEsp(player)
    if player == LocalPlayer then return end -- Bỏ qua chính mình

    -- Tạo sẵn các đối tượng để tránh việc khởi tạo liên tục làm lag máy
    local Box = Drawing.new("Square")
    Box.Thickness = 1.5
    Box.Filled = false
    Box.Transparency = 1
    Box.Color = Color3.fromRGB(0, 255, 255)

    local Tracer = Drawing.new("Line")
    Tracer.Thickness = 1
    Tracer.Transparency = 1
    Tracer.Color = Color3.new(1, 1, 1)

    local Info = Drawing.new("Text")
    Info.Size = 16
    Info.Center = true
    Info.Outline = true
    Info.Color = Color3.new(1, 1, 1)

    local HealthBar = Drawing.new("Line")
    HealthBar.Thickness = 2
    HealthBar.Transparency = 1

    local connection
    connection = RunService.RenderStepped:Connect(function()
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") then
            local Root = player.Character.HumanoidRootPart
            local Hum = player.Character.Humanoid
            local Pos, OnScreen = Camera:WorldToViewportPoint(Root.Position)

            if OnScreen and Hum.Health > 0 then
                -- Tính khoảng cách (Đã fix lỗi crash khi LocalPlayer bị chết)
                local Dist = 0
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    Dist = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - Root.Position).Magnitude)
                end

                local Size = (Camera.ViewportSize.Y / Pos.Z) * 2
                local w, h = Size, Size * 1.5
                local x, y = Pos.X - w/2, Pos.Y - h/2

                -- Render Box
                if Settings.Box then
                    Box.Visible = true
                    Box.Size = Vector2.new(w, h)
                    Box.Position = Vector2.new(x, y)
                else
                    Box.Visible = false
                end

                -- Render Tracer
                if Settings.Tracer then
                    Tracer.Visible = true
                    Tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                    Tracer.To = Vector2.new(Pos.X, Pos.Y + h/2)
                else
                    Tracer.Visible = false
                end

                -- Render Name & Distance
                if Settings.Name then
                    Info.Visible = true
                    Info.Text = player.Name .. " [" .. Dist .. "m]"
                    Info.Position = Vector2.new(Pos.X, y - 20)
                else
                    Info.Visible = false
                end

                -- Render Health Bar (Đã fix lỗi dải màu)
                if Settings.Health then
                    HealthBar.Visible = true
                    local healthPercent = math.clamp(Hum.Health / Hum.MaxHealth, 0, 1)
                    HealthBar.From = Vector2.new(x - 6, y + h)
                    HealthBar.To = Vector2.new(x - 6, y + h - (h * healthPercent))
                    HealthBar.Color = Color3.fromHSV(healthPercent * 0.3, 1, 1)
                else
                    HealthBar.Visible = false
                end
            else
                Box.Visible = false
                Tracer.Visible = false
                Info.Visible = false
                HealthBar.Visible = false
            end
        else
            Box.Visible = false
            Tracer.Visible = false
            Info.Visible = false
            HealthBar.Visible = false

            -- Tự động dọn rác (Remove Data) khi người chơi thoát để tránh lag server
            if not player.Parent then
                Box:Remove()
                Tracer:Remove()
                Info:Remove()
                HealthBar:Remove()
                connection:Disconnect()
            end
        end
    end)
end

-- ==========================================
-- 6. ÁP DỤNG ESP VÀO GAME
-- ==========================================
for _, p in pairs(Players:GetPlayers()) do
    CreateEsp(p)
end

Players.PlayerAdded:Connect(CreateEsp)
