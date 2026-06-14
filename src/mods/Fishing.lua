-- BackgroundColor3
-- Nút trắng: 230, 230, 230 (bấm nút này)
-- Nút đen: 25, 25, 25

local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local LocalPlayer = Players.LocalPlayer

-- Biến kiểm soát trạng thái câu cá
local isAutoFishing = false
local fishingLoopThread = nil -- Dùng để quản lý luồng chạy ngầm

-- Hàm giả lập click chuột trái
local function leftClick()
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
    task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
end

local function getFishingFolder()
    return workspace:FindFirstChild("FishingRope_" .. LocalPlayer.UserId)
end

-- Hàm hỗ trợ tìm ScreenGui cha để check xem game có ẩn thanh Topbar không
local function getScreenGui(obj)
    local current = obj
    while current and not current:IsA("ScreenGui") do
        current = current.Parent
    end
    return current
end

-- Hàm giả lập click chuột theo tọa độ của Nút
local function clickGuiElement(btn)
    -- Tính toán tọa độ tâm (Center) của nút bấm
    if btn:FindFirstChild("UICorner") then btn.UICorner:Destroy() end
    local posX = btn.AbsolutePosition.X + (btn.AbsoluteSize.X / 4)
    local posY = btn.AbsolutePosition.Y + (btn.AbsoluteSize.Y / 4)
    
    -- Xử lý bù trừ tọa độ nếu giao diện bị dính thanh Topbar của Roblox (khoảng 36px)
    local screenGui = getScreenGui(btn)
    if screenGui and not screenGui.IgnoreGuiInset then
        local inset = GuiService:GetGuiInset()
        posY = posY + inset.Y
    end
    
    -- Tiến hành click chuột trái chính xác vào tâm nút
    VirtualInputManager:SendMouseButtonEvent(posX, posY, 0, true, game, 0)
    task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(posX, posY, 0, false, game, 0)
end

-- ==========================================
-- Solver
-- ==========================================

local MinigameSolverThread = false

local function startMinigameSolver()
    if MinigameSolverThread then return end
    MinigameSolverThread = task.spawn(function()
        while isAutoFishing do
            task.wait(0.14)
            
            local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
            if not PlayerGui then continue end
            
            local minigameUI = PlayerGui:FindFirstChild("FishingMinigame")
            
            local MainFrame = minigameUI:WaitForChild("Frame", 3)
            if not MainFrame then continue end
            MainFrame.Size = UDim2.new(0.25, 0, 0.25, 0)
            MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
            MainFrame.AnchorPoint = Vector2.new(0.5, 0.45)

            local FrameButtons = nil
            for _, i in MainFrame:GetChildren() do
                if i.Name == "Frame" and i.Transparency == 1 then
                    FrameButtons = i
                    break
                end
            end

            for _, child in pairs(FrameButtons:GetChildren()) do
                if child:IsA("GuiButton") or child:IsA("TextButton") or child:IsA("ImageButton") then
                    if child.BackgroundColor3 == Color3.fromRGB(230, 230, 230) then
                        local OldPosition = child.Position
                        child.Position = UDim2.new(-0.3, 0, 0, 0)
                        clickGuiElement(child)
                        child.Position = OldPosition
                    end
                end
            end
        end
        MinigameSolverThread = false -- Reset khi hoàn thành hoặc dừng
    end)
end

-- Hàm chạy vòng lặp câu cá
local function startFishing()
    if fishingLoopThread then return end -- Tránh chạy đè nhiều vòng lặp
    
    fishingLoopThread = task.spawn(function()
        while isAutoFishing do
            task.wait(0.1)
            
            local folder = getFishingFolder()
            
            if not folder or not folder:FindFirstChild("Bobber") then
                -- Chưa quăng cần -> Quăng cần
                leftClick()
            else
                -- Đã quăng cần -> Chờ cá cắn câu (Sparkles)
                local sparkles = folder:FindFirstChild("Sparkles", true)
                if sparkles then
                    leftClick()
                end
            end
        end
        fishingLoopThread = nil -- Reset luồng khi dừng
    end)
end

--- ==========================================================
--- PHẦN XỬ LÝ BẬT TẮT THEO UI CỦA BẠN
--- ==========================================================

_G.UI.addEventHandler("Fishing", function(enabled)
    isAutoFishing = enabled
    
    if enabled then
        startFishing()
        startMinigameSolver()
    else
        print("🛑 Đã tắt Auto Câu Cá")
    end
end)

-- Xử lý khi tắt toàn bộ Tool/Script
_G.UI.addStopHandler(function()
    isAutoFishing = false
    print("🔌 Tool dừng hoạt động - Đã ngắt Auto Câu Cá")
end)
