local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(script.Parent.Types)

local function makeGolden(victim: Types.Participant)
    local char = assert(victim:GetCharacter(), "Participant has no character")
    local root = char:FindFirstChild("HumanoidRootPart")

    local humanoid = char:FindFirstChildWhichIsA("Humanoid")
    if not humanoid then
        return
    end

    if root then
        local deathSound = root:FindFirstChild("DeathSound") :: Sound?
        if deathSound then
            deathSound:Destroy()
        end

        local sound = ReplicatedStorage.Assets:WaitForChild("ItemSounds"):WaitForChild("GoldenGunHit"):Clone()
        sound.Name = "DeathSound"
        sound.Parent = root :: any
    end

    local gold = BrickColor.new("Gold")

    local bodyColours = char:FindFirstChildWhichIsA("BodyColors")
    if bodyColours then
        bodyColours.HeadColor = gold
        bodyColours.LeftLegColor = gold
        bodyColours.RightLegColor = gold
        bodyColours.LeftArmColor = gold
        bodyColours.RightArmColor = gold
        bodyColours.TorsoColor = gold
    end

    for _, v in char:QueryDescendants("BasePart") do
        v.Material = Enum.Material.Metal

        if v:IsA("MeshPart") then
            v.TextureContent = Content.none
        end

        if v.Parent ~= humanoid.Parent or humanoid:GetBodyPartR15(v) == Enum.BodyPartR15.Unknown then
            v.BrickColor = gold
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