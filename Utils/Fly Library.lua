local Players = cloneref(game:GetService("Players"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local RunService = cloneref(game:GetService("RunService"))

local FlyLibrary = {}
FlyLibrary.__index = FlyLibrary

function FlyLibrary.new()
    local self = setmetatable({}, FlyLibrary)
    
    self.Speed = 50
    self.ToggleKey = Enum.KeyCode.F
    self.isFlying = false
    self.player = Players.LocalPlayer
    self.character = nil
    self.humanoid = nil
    self.rootPart = nil
    self.gyro = nil
    self.velocity = nil
    self.connections = {}
    
    self:_init()
    return self
end

function FlyLibrary:_init()
    self.connections[1] = UserInputService.InputBegan:Connect(function(input, gp)
        if gp or UserInputService:GetFocusedTextBox() then return end
        if input.KeyCode == self.ToggleKey then
            self:Toggle()
        end
    end)
    
    self.connections[2] = RunService.RenderStepped:Connect(function()
        self:_update()
    end)
    
    if self.player.Character then
        self:_setupCharacter(self.player.Character)
    end
    
    self.connections[3] = self.player.CharacterAdded:Connect(function(char)
        self:_setupCharacter(char)
    end)
end

function FlyLibrary:_setupCharacter(char)
    self.character = char
    self.humanoid = char:WaitForChild("Humanoid")
    self.rootPart = char:WaitForChild("HumanoidRootPart")
    self:Stop()
end

function FlyLibrary:_createMovers()
    if self.gyro then self.gyro:Destroy() end
    if self.velocity then self.velocity:Destroy() end
    
    self.gyro = Instance.new("BodyGyro")
    self.gyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    self.gyro.P = 3000
    self.gyro.D = 500
    self.gyro.Parent = self.rootPart
    
    self.velocity = Instance.new("BodyVelocity")
    self.velocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    self.velocity.Velocity = Vector3.zero
    self.velocity.Parent = self.rootPart
end

function FlyLibrary:_destroyMovers()
    if self.gyro then self.gyro:Destroy(); self.gyro = nil end
    if self.velocity then self.velocity:Destroy(); self.velocity = nil end
end

function FlyLibrary:_update()
    if not self.isFlying or not self.character or not self.humanoid or not self.rootPart then
        return
    end
    
    self.humanoid.PlatformStand = true
    
    if not self.gyro or not self.velocity then
        self:_createMovers()
    end
    
    local cam = workspace.CurrentCamera
    self.gyro.CFrame = cam.CFrame
    
    if UserInputService:GetFocusedTextBox() then
        self.velocity.Velocity = Vector3.zero
        return
    end
    
    local dir = Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end
    
    self.velocity.Velocity = dir.Magnitude > 0 and dir.Unit * self.Speed or Vector3.zero
end

function FlyLibrary:Update(config)
    if config.Speed then self.Speed = config.Speed end
    if config.ToggleKey then self.ToggleKey = config.ToggleKey end
    return self
end

function FlyLibrary:Start()
    if not self.character or not self.humanoid or not self.rootPart then return self end
    
    self.isFlying = true
    self.humanoid.AutoRotate = false
    self:_createMovers()
    return self
end

function FlyLibrary:Stop()
    self.isFlying = false
    if self.humanoid then
        self.humanoid.AutoRotate = true
        self.humanoid.PlatformStand = false
    end
    self:_destroyMovers()
    return self
end

function FlyLibrary:Toggle()
    if self.isFlying then
        self:Stop()
    else
        self:Start()
    end
    return self
end

function FlyLibrary:Destroy()
    self:Stop()
    for _, conn in pairs(self.connections) do
        if conn then conn:Disconnect() end
    end
end

return FlyLibrary.new()