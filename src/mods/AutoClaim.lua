local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local SamNPC = workspace.Ignore.NPCs.DailyQuest.Sam

local isAutoClaim = false
local loopThread = nil

local function clickGuiElement(btn)
    for _, connection in pairs(getconnections(btn.MouseButton1Click)) do
        connection:Fire() 
    end
    task.wait(0.1)
end

-- Vòng lặp tự động dịch chuyển đến Sam để nhận thưởng rồi quay về
local function startAutoClaim()
    if loopThread then return end

    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    local SamTimer = PlayerGui.Menu.Frame.MenuList.Stats.Frame.A.Sam.SamTimer
    local Option = PlayerGui.QuestGui.Dialogue.Options.Option
    local Leave = PlayerGui.QuestGui.Dialogue.Options.Leave

    loopThread = task.spawn(function()
        while isAutoClaim do
            task.wait(0.1)
            
            -- Kiểm tra nếu Sam đã sẵn sàng nhận thưởng
            if string.find(SamTimer.Text, "Ready") then
                local character = LocalPlayer.Character
                local hrp = character and character:FindFirstChild("HumanoidRootPart")
                local samHRP = SamNPC:FindFirstChild("HumanoidRootPart")
                
                if hrp and samHRP then
                    print("Đang dịch chuyển tới Sam để nhận quà...")
                    
                    -- 1. Lưu vị trí đứng hiện tại của Player
                    local originalCFrame = hrp.CFrame
                    
                    -- 2. Dịch chuyển Player đến trước mặt Sam (cách 2 studs để chắc chắn click được)
                    hrp.CFrame = samHRP.CFrame * CFrame.new(0, 0, 3)
                    task.wait(0.2) -- Chờ game nhận diện vị trí mới
                    
                    -- 3. Click NPC và tương tác với UI
                    fireclickdetector(SamNPC.HumanoidRootPart.ClickDetector)
                    task.wait(0.4)
                    clickGuiElement(Option)
                    task.wait(0.4)
                    clickGuiElement(Option)
                    task.wait(0.4)
                    clickGuiElement(Leave)
                    
                    -- 4. Dịch chuyển Player quay trở lại vị trí ban đầu ngay lập tức
                    hrp.CFrame = originalCFrame
                    print("Đã nhận xong quà và quay trở lại vị trí cũ!")
                    
                    -- Đợi 4 giây cooldown trước khi check lượt tiếp theo
                    task.wait(4)
                end
            end
        end
        loopThread = nil
    end)
end

--- ==========================================================
--- UI Handler
--- ==========================================================

_G.UI.addEventHandler("AutoClaim", function(enabled)
    isAutoClaim = enabled
    if enabled then
        startAutoClaim()
    end
end)

_G.UI.addStopHandler(function()
    isAutoClaim = false
end)