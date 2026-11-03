-- Nexto pretrained ML client: public runtime loader, CC BY-NC-SA 4.0.
local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local player=assert(Players.LocalPlayer,"Run this loader on the client")
local oldIcon=UIS.MouseIconEnabled
UIS.MouseIconEnabled=true
local gui=Instance.new("ScreenGui")
gui.Name="RobloxNextoDownload"
gui.ResetOnSpawn=false
local box=Instance.new("TextButton")
box.Name="DownloadStatus"
box.Modal=true
box.Size=UDim2.fromOffset(420,100)
box.Position=UDim2.new(0.5,-210,0.5,-50)
box.BackgroundColor3=Color3.fromRGB(14,19,29)
box.TextColor3=Color3.fromRGB(235,242,253)
box.Font=Enum.Font.Gotham
box.TextSize=14
box.TextWrapped=true
box.Text="NEXTO ML\nDownloading the pretrained client…"
box.Parent=gui
gui.Parent=player:WaitForChild("PlayerGui")
task.wait()
local ok,compiled=pcall(function()
    local source=game:HttpGet("https://raw.githubusercontent.com/Assassinatorr/roblox-nexto-loader/dcaa9ecbfa9aec8287754099a75b6db4fe4ac2d1/Nexto-1.2.0.client.luau")
    local run,failure=loadstring(source,"Roblox Nexto 1.2.0")
    assert(run,failure)
    return run
end)
if not ok then
    box.Text="NEXTO DOWNLOAD FAILED\n"..tostring(compiled).."\nClick to close."
    box.Activated:Connect(function()gui:Destroy();UIS.MouseIconEnabled=oldIcon end)
    warn(box.Text)
    return nil
end
gui:Destroy()
UIS.MouseIconEnabled=oldIcon
return compiled()
