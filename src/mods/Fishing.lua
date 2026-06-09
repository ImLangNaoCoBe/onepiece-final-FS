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

local function getFrameButtons()
    local PlayerGui = game:GetService("Players").LocalPlayer.PlayerGui
    local MainFrame = PlayerGui:FindFirstChild("FishingMinigame").Frame
    MainFrame.Size = UDim2.new(0.25, 0, 0.25, 0)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.45)
    local FrameButtons = nil
    for _, i in MainFrame:GetChildren() do
        if i.Name == "Frame" and i.Transparency == 1 then
            FrameButtons = i
        end
    end
    return FrameButtons
end

local function getFishingFolder()
    return workspace:FindFirstChild("FishingRope_" .. LocalPlayer.UserId)
end

local solving = false

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
    local posX = btn.AbsolutePosition.X + (btn.AbsoluteSize.X / 2)
    local posY = btn.AbsolutePosition.Y + (btn.AbsoluteSize.Y / 2)
    
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

local function solveColorMinigame()
    if solving then return end
    solving = true

    local function finish()
        solving = false
    end

    local buttons = {}
    
    -- Lọc và gom toàn bộ nút bấm vào table 'buttons'
    task.spawn(function()
        for _, child in pairs(getFrameButtons():GetChildren()) do
            child.Size = UDim2.new(0.2, 0, 0.2, 0)
            child.SizeConstraint = Enum.SizeConstraint.RelativeXX
        end
    end)
    for _, child in pairs(getFrameButtons():GetChildren()) do
        if child:IsA("GuiButton") or child:IsA("TextButton") or child:IsA("ImageButton") then
            table.insert(buttons, child)
        end
    end

    -- Phải có ít nhất 3 nút để tìm điểm khác biệt
    if #buttons < 3 then 
        return finish() 
    end

    -- Hàm lấy màu của nút
    local function getColor(btn)
        return btn:IsA("ImageButton") and btn.ImageColor3 or btn.BackgroundColor3
    end

    ---------------------------------------------------------
    -- THUẬT TOÁN GOM NHÓM VÀ ĐẾM TẦN SUẤT MÀU
    ---------------------------------------------------------
    local colorGroups = {}

    for _, btn in ipairs(buttons) do
        local color = getColor(btn)
        local colorKey = tostring(color)
        
        if not colorGroups[colorKey] then
            colorGroups[colorKey] = {}
        end
        table.insert(colorGroups[colorKey], btn)
    end

    -- Tìm nút có màu xuất hiện duy nhất 1 lần
    local targetButton = nil
    for _, group in pairs(colorGroups) do
        if #group == 1 then
            targetButton = group[1]
            break
        end
    end

    ---------------------------------------------------------
    -- THỰC HIỆN CLICK BẰNG TỌA ĐỘ
    ---------------------------------------------------------
    if targetButton then
        print("🎯 Đã tìm thấy nút khác biệt. Tiến hành click tọa độ...")
        
        -- Gọi hàm click tọa độ thực tế thay cho getconnections
        clickGuiElement(targetButton)
        task.spawn(function()
            for _, child in pairs(getFrameButtons():GetChildren()) do
                child.Size = UDim2.new(0.2, 0, 0.2, 0)
                child.SizeConstraint = Enum.SizeConstraint.RelativeXX
            end
        end)
        task.wait(0.22) -- Chờ minigame nhận diện click trước khi mở lượt tiếp theo
    else
        warn("❌ Không tìm thấy nút nào có màu khác biệt!")
    end
    
    return finish()
end


-- Hàm chạy vòng lặp câu cá
local function startFishing()
    if fishingLoopThread then return end -- Tránh chạy đè nhiều vòng lặp
    
    fishingLoopThread = task.spawn(function()
        while isAutoFishing do
            task.wait(0.1)
            
            local folder = getFishingFolder()
            
            solveColorMinigame()
            
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

-- Thay 'FISHING_KEY' bằng biến/tên Key của nút Toggle câu cá trong UI của bạn
_G.UI.addEventHandler("Fishing", function(enabled)
    isAutoFishing = enabled
    
    if enabled then
        startFishing()
    else
        -- Khi tắt toggle, vòng lặp 'while isAutoFishing' sẽ tự dừng ở lượt kiểm tra kế tiếp
        print("🛑 Đã tắt Auto Câu Cá")
    end
end)

-- Xử lý khi tắt toàn bộ Tool/Script
_G.UI.addStopHandler(function()
    -- Cập nhật lại cài đặt trong UI nếu cần (Ví dụ: đặt tên là AutoFishing)
    if _G.UI.settings then
        _G.UI.settings.AutoFishing = false 
    end
    
    isAutoFishing = false
    print("🔌 Tool dừng hoạt động - Đã ngắt Auto Câu Cá")
end)
