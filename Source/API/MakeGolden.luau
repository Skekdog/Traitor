local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(script.Parent.Types)

local function makeGolden(victim: Types.Participant)
    local char = assert(victim:GetCharacter(), "Participant has no character")
    local root = char:FindFirstChild("HumanoidRootPart")

    if root then
        local deathSound = root:FindFirstChild("DeathSound") :: Sound?
        if deathSound then
            deathSound:Destroy()
        end

        local sound = ReplicatedStorage.Assets:WaitForChild("ItemSounds"):WaitForChild("GoldenGunHit"):Clone()
        sound.Name = "DeathSound"
        sound.Parent = root :: any
    end

    local bodyColours = char:FindFirstChildWhichIsA("BodyColors")
    if bodyColours then
        local gold = BrickColor.new("Gold")

        bodyColours.HeadColor = gold
        bodyColours.LeftLegColor = gold
        bodyColours.RightLegColor = gold
        bodyColours.LeftArmColor = gold
        bodyColours.RightArmColor = gold
        bodyColours.TorsoColor = gold
    end

    for _, v in char:GetChildren() do
        if v:IsA("BasePart") then
            v.Material = Enum.Material.Metal
        end
    end

    local shirt = char:FindFirstChildOfClass("Shirt")
    if shirt then
        shirt:Destroy()
    end

    local pants = char:FindFirstChildOfClass("Pants")
    if pants then
        pants:Destroy()
    end

    local tshirt: ShirtGraphic?
    repeat
        tshirt = char:FindFirstChildOfClass("ShirtGraphic")
        if tshirt then
            tshirt:Destroy()
        end
    until not tshirt

    char:SetAttribute("RemoveClothing", true) -- for corpse disguising
    char:SetAttribute("PreservePartAppearance", true) -- likewise
end

return makeGolden