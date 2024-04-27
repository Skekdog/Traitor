--[[
	GAMEMODE DOCUMENTATION
	
	Unique values -[
	PublicityLevel = "All": All players
	                 "Allies": Allies
	                 "Enemies": Non-allies
	                 "Nobody": No players
	                 
	WinsAs = "__!!Solo": Only one person can win
	
	TimeVictory = "__!!MostPoints-Solo": Whoever has most points
				  "__!!MostPoints-Role": Whichever role has most points
				  
	Accessories = "Sherlock Mesh": https://www.roblox.com/library/10760717
	
	]-
	
	Name: String = Internal Name should be same as dictionary key
	DisplayName: String = Name to show to people
	
	MinimumPlayers: Integer = Minimum players needed to start this gamemode
	
	TimeLimitBase: Number = Base time limit, can be negative
	TimePerPlayer: Number = Time to add per player, can be negative
	
	PyrrhicVictory: String!Role = Who wins if everyone is dead
	TimeVictory: String!Role = Which role wins on timeout
	TimeVictoryMusic: {AssetIDNumbers} = Music to play on timeout or UniqueValue solo win
	
	Equipment {      All equipment and weapons that will be used in the gamemode
		Entry = {Equipment: Model|Function,
				CreditCost: Integer, = Cost to buy this in credits
				Description: String, = Description to show in equipment shop
				ImageID: String, = Number part of an asset id, image to display in equipment shop
		}
	}
	
	StartWith: {Strings} = A table of tools to start with for all roles
	
	Roles {
		[InternalRoleName] = {
			Name: String = Name of the role, duh
			
			Proportion: Float (0<x<=1) = What percentage of all players should be assigned this role, taking into account Minimum
			Minimum: Integer = Minimum number of players to be assigned this role, can equal amount of players in the round
			
			Hint: String = Hint to display when a player is given that role
			Colour: Color3 = Spelt the proper way, colour that represents the role
			Accessories: {Accessories} = Accessories to apply using Humanoid:AddAccessory()
			
			KnowMissing: Boolean = Whether this role can see Missing players in player list
			PublicityLevel: String!UniqueValue = Who is this role revealed to, see unique values
			AlwaysSeeKnownAllies: Boolean = Whether this role can see known allies (PublicityLevel Allies or All) through walls
			Allies: {Strings} = A table of teammates, who you lose karma for wrongly killing. If they win, you win also
			
			StartingCredits: Integer = Amount of credits to start with
			EquipmentShop: {Strings} = A table of equipment that can be purchased in the shop. Leave blank for no equipment shop.
			StartsWith: {Strings} = Role specific starts with table, does not override gamemode StartsWith
			
			WinsAs: String = What win will be shown if this role wins
			VictoryMusic: {AssetIDNumbers} = Music to play when WinsAs wins. Only needs to be defined in WinsAs role.
			
			AwardOnDeath: {Role: Integer} = Amount of credits to award each role if a member of this role dies.
			StealCredits: Boolean = Determines whether this role can steal credits from corpses
			CorpseResultsPublicised: Boolean = Determines whether all players will be able to view the results of a corpse searched by this role in the playerlist.
			
			AnnounceDisconnect: Boolean = Send message in chat when this player disconnects ([plr has left the server. They were a [role])
		}
	}
]]

globalHighlights = {
	SuicideCult = function(round)
		local suiciders = {}
		for _,v in round.Location.Players:GetChildren() do
			if v:GetAttribute("DeathType") == "Suicide" then table.insert(suiciders,v) end
		end
		if #suiciders == 1 then return "Lonely and Depressed",suiciders[1].Name.." was the only one to kill themselves."
		elseif #suiciders == 0 then return end
		local earliestTime,earliestPlr = math.huge,nil
		for _,v in suiciders do
			if v:GetAttribute("DeathTime") < earliestTime then earliestTime,earliestPlr = v:GetAttribute("DeathTime"),v end
		end
		return "Suicide Cult Leader",earliestPlr.Name.." showed the other suiciders how to do it by being the first to go."
	end,
	Explosives = function(round)
		local plrs = round.Location.Players
		local kills = {}
		for _,v in plrs:GetChildren() do
			kills[v.Name] = {}
			for _,kill in v.KillList do
				local val = plrs:FindFirstChild(kill.Name)
				if val and val:GetAttribute("DeathType") == "Explosion" then table.insert(kills[v],val) end
			end
		end
		
		local mostCount,mostPlr,killList = 0,nil,{}
		for i,v in kills do if #v > mostCount then mostCount,mostPlr,killList = #v,i,v end end
		
		if mostPlr then
			if table.find(killList,plrs:FindFirstChild(mostPlr.Name)) then
				return "Field Research",mostPlr.Name.." tested their own resistance to explosions. It was not high enough."
			end
			return "Explosives Research Grant",mostPlr.Name.." was recognised for their research on explosions. "..tostring(mostCount).." test subjects helped out."
		end
	end,
	FirstBlood = function(round)
		local plrs = round.Location.Players
		local firstKill,killTime,firstDeath = nil,math.huge,nil
		for _,v in plrs:GetChildren() do
			for _,kill in v.KillList:GetChildren() do
				local val = plrs:FindFirstChild(kill.Name)
				if (val) and (val:GetAttribute("DeathTime") < killTime) then
					firstKill,killTime,firstDeath = v,val:GetAttribute("DeathTime"),val
				end
			end
		end
		
		if firstKill and firstDeath then
			if round:IsDamageJustified(firstKill,firstDeath,true) then
				return "First Blood",firstKill.Name.." delivered the first death but did not receive a medal."
			end
			return "First Bloody Stupid Kill",firstKill.Name.." scored the first kill by shooting a friend. Good job."
		end
	end,
	BadLuck = function(round)
		local earliestDeath,earliestPlr = math.huge,nil
		for _,v in round.Location.Players:GetChildren() do
			local t = v:GetAttribute("DeathTime")
			if (t ~= 0) and (t<earliestDeath) then
				if (t-round.StartTime) < 0.5 then
					earliestDeath,earliestPlr = t,v
				end
			end
		end
		
		if earliestPlr then return "I Hate This Game",earliestPlr.Name.." died right after the start of the round." end
		local latestDeath,latestPlr = 0,nil
		for _,v in round.Location.Players:GetChildren() do
			local t = v:GetAttribute("DeathTime")
			if (t ~= 0) and (t>latestDeath) and (round:GetRole(v.Name,true) == round.Victory) then
				if ((round.EndTime-t) < 0.5) then
					latestDeath,latestPlr = t,v
				end
			end
		end
		if latestPlr then return "Pyrrhic Victory",latestPlr.Name.." died just before their team won the round." end
	end,
}

local items = game.ReplicatedStorage.Items
local vm = game.ReplicatedStorage:FindFirstChild("VictoryMusic")

local gamemodes = {
	ThoseYouTrust = {
		Name = "ThoseYouTrust",
		DisplayName = "Those You Trust",
		Creator = "Bad King Urgrain, @Scelly_Dog",

		MinimumPlayers = 1,

		TimeLimitBase = 180,
		TimePerPlayer = 15,
		
		PyrrhicVictory = "Innocent",
		TimeVictory = "Innocent",
		TimeVictoryMusic = vm.Timeout,

		Equipment = {
			["Assault Rifle"] = {items["Assault Rifle"]},
			["Pistol"] = {items["Pistol"]},
			["XM1014"] = {items["XM1014"]},
			["Crowbar"] = {items["Crowbar"]},
			["Deagle"] = {items["Deagle"]},
			["Scout"] = {items["Scout"]},
			["SMG"] = {items["SMG"]},
			["HUGE"] = {items["HUGE"]},
			["Glock"] = {items["Glock"]},

			["Golden Gun"] = {items["Golden Gun"],2,"Instant kills if the death is justified. Otherwise - bad luck.","10282780102"},
			["Silenced Pistol"] = {items["Silenced Pistol"],1,"A significantly quieter variant of the Five-SeveN. Spies killed by silenced weapons will not scream.","299432421"},
			["Grenade"] = {items["Grenade"],2,"Explodes in a decent radius after a few seconds. Can be disarmed by being shot.","8096856961"},
			["AWP"] = {items["AWP"],1,"Slow-firing, high-power sniper rifle. Can only be shot whilst scoped in.","4772214897"},
			["Flashbang"] = {items["Flashbang"],1,"Blinds and deafens anyone in the radius, but can be disarmed by being shot.","10753198321"},

			["Bullet Vest"] = {function(plrVal)
				plrVal:FindFirstChild("Modifiers"):SetAttribute("AbsorbDamage_Torso0HumanoidRootPart_Body_Armor","60")
			end,1,"Resists damage to torso, but will break after too much.","395920626"},
			["Radar"] = {function()end,1,"Reveals the location of all players every 30 seconds.","62159372"}, -- radar is handled on the client, so mark it as a function and allow the EquipmentManager to inform the client
			["Health Station"] = {items["Health Station"],1,"Heals anyone who uses it, but needs to slowly recharge and can be destroyed by Traitors.","6567078483"},
			["Death Station"] = {items["Death Station"],1,"Kills innocents who use it, but can be destroyed by them aswell.","17068622097"}
		},
		StartWith = {"Crowbar"},

		Roles = {
			Innocent = {
				Name = "Innocent",

				Proportion = 0.625,
				Minimum = 0,

				Hint = "Survive the <font color='#ff0000'>Traitors</font>.",
				Colour = Color3.new(0,1,0),
				Sound = 9042819926,
				
				KnowMissing = false,
				PublicityLevel = "Nobody",
				AlwaysSeeKnownAllies = false,
				Allies = {"Detective","Innocent"},
				
				EquipmentShop = {},
				StartsWith = {},

				WinsAs = "Innocent",
				VictoryMusic = vm.Innocent,
				
				AnnounceDisconnect = false,
			},
			Traitor = {
				Name = "Traitor",

				Proportion = 0.25,
				Minimum = 1,

				Hint = "Kill all of the <font color='#00ff00'>Innocents</font>.",
				Colour = Color3.new(1,0,0),
				Sound = 9042088276,
				
				KnowMissing = true,
				PublicityLevel = "Allies",
				AlwaysSeeKnownAllies = true,
				Allies = {"Traitor"},

				StartingCredits = 2,
				EquipmentShop = {
					"Bullet Vest",
					"Radar",
					"Silenced Pistol",
					"Grenade",
					"AWP",
					"Death Station",
					"Flashbang",
				},
				StartsWith = {},
				
				AwardOnDeath = {
					Detective = 1
				},
				StealCredits = true,

				WinsAs = "Traitor",
				VictoryMusic = vm.Traitor,
				
				AnnounceDisconnect = true,
			},
			Detective = {
				Name = "Detective",

				Proportion = 0.125,
				Minimum = 0,

				Hint = "Use your <font color='#0000ff'>Equipment</font> to discover the <font color='#ff0000'>Traitors</font>.",
				Colour = Color3.new(0,0.34902,1),
				Sound = 9042823666,
				Accessories = {"Detective Hat"},
				
				KnowMissing = false,
				PublicityLevel = "All",
				AlwaysSeeKnownAllies = false,
				Allies = {"Innocent","Detective"},

				StartingCredits = 2,
				EquipmentShop = {"Radar","Golden Gun","Health Station","Flashbang"},
				StartsWith = {"Bullet Vest"},
				
				AwardOnDeath = {
					Traitor = 1
				},
				StealCredits = true,
				CorpseResultsPublicised = true,

				WinsAs = "Innocent",
				
				AnnounceDisconnect = true,
			}
		},

	},
	Elimination = {
		Name = "Elimination",
		DisplayName = "Elimination",
		Creator = "@Scelly_Dog",

		MinimumPlayers = 1,

		TimeLimitBase = 120,
		TimePerPlayer = 15,
		
		PyrrhicVictory = "Competitor",--"__!!MostPoints-Solo",
		TimeVictory = "Competitor",--"__!!MostPoints-Solo",
		TimeVictoryMusic = vm.Traitor,

		Equipment = {
			["Assault Rifle"] = {items["Assault Rifle"]},
			["Pistol"] = {items["Pistol"]},
			["XM1014"] = {items["XM1014"]},
			["Crowbar"] = {items["Crowbar"]},
			["Deagle"] = {items["Deagle"]},
			["Scout"] = {items["Scout"]},
			["SMG"] = {items["SMG"]},
			["HUGE"] = {items["HUGE"]},
			["Glock"] = {items["Glock"]},

			["Golden Gun"] = {items["Golden Gun"],2,"Instant kills if the death is justified. Otherwise - bad luck.","10282780102"},
			["Silenced Pistol"] = {items["Silenced Pistol"],1,"A significantly quieter variant of the Five-SeveN. Spies killed by silenced weapons will not scream.","299432421"},
			["Grenade"] = {items["Grenade"],2,"Explodes in a decent radius after a few seconds. Can be disarmed by being shot.","8096856961"},
			["AWP"] = {items["AWP"],1,"Slow-firing, high-power sniper rifle. Can only be shot whilst scoped in.","4772214897"},
			["Flashbang"] = {items["Flashbang"],1,"Blinds and deafens anyone in the radius, but can be disarmed by being shot.","10753198321"},

			["Bullet Vest"] = {function(plrVal)
				plrVal:FindFirstChild("Modifiers"):SetAttribute("AbsorbDamage_Torso0HumanoidRootPart_Body_Armor","60")
			end,1,"Resists damage to torso, but will break after too much.","395920626"},
			["Radar"] = {function()end,1,"Reveals the location of all players every 30 seconds.","62159372"}, -- radar is handled on the client, so mark it as a function and allow the EquipmentManager to inform the client
			["Health Station"] = {items["Health Station"],1,"Heals anyone who uses it, but needs to slowly recharge and can be destroyed.","6567078483"},
			["Death Station"] = {items["Death Station"],1,"Kills anyone who uses it, but can be destroyed.","17068622097"}
		},
		StartWith = {"Crowbar"},

		Roles = {
			Competitor = {
				Name = "Competitor",

				Proportion = 1,
				Minimum = 0,

				Hint = "Leave <font color='#ff0000'>Nobody</font> Standing.",
				Colour = Color3.new(1,0.0823529,0.0823529),
				Sound = 9042088276,
				
				KnowMissing = true,
				PublicityLevel = "All",
				AlwaysSeeKnownAllies = false,
				Allies = {},
				
				StartingCredits = 1,
				EquipmentShop = {"Golden Gun","Bullet Vest","Grenade","Health Station","Death Station","Flashbang"},
				StartsWith = {"Radar"},
				
				StealCredits = true,
				AwardOnDeath = {
					Competitor = 1,
				},

				WinsAs = "__!!Solo",
				VictoryMusic = vm.Traitor,
			}
		}
	}
}

function gamemodes.ValidateGamemode(gamemode)
	local noNegative = " cannot be negative"
	local notFoundOr = " not found or "
	local notFoundOrNot = " not found or not a "
	local defaulted = ", defaulted to "

	if not gamemode.Name or gamemode.Name == "" then
		error("Name"..notFoundOr.."blank")
	end
	print("Checking "..gamemode.Name)
	--BASIC CHECKS
	if typeof(gamemode.MinimumPlayers) ~= "number" then
		warn("MinimumPlayers"..notFoundOrNot.."number"..defaulted.."2")
		gamemode.MinimumPlayers = 2
	elseif gamemode.MinimumPlayers < 0 then
		warn("MinimumPlayers"..noNegative..defaulted.."2")
	end
	if typeof(gamemode.TimeLimitBase) ~= "number" then
		warn("TimeLimitBase"..notFoundOrNot.."number, round will go on until a victory is reached")
		gamemode.TimeLimitBase = math.huge
	end
	if typeof(gamemode.TimePerPlayer) ~= "number" then
		warn("TimePerPlayer"..notFoundOrNot.."number"..defaulted.."15")
		gamemode.TimePerPlayer = 15
	end
	if typeof(gamemode.TimeVictory) ~= "string" then
		warn("TimeVictory"..notFoundOr.."blank, time limit disabled")
		gamemode.TimeLimitBase = math.huge
		gamemode.TimePerPlayer = 15 --because TimePerPlayer can be set negative
	end
	--ROLE CHECKS
	if typeof(gamemode.Roles) ~= "table" then
		error("Roles"..notFoundOrNot.."table")
	elseif #gamemode.Roles < 1 then
		error("Roles cannot be empty")
	end
	for i,v in pairs(gamemode.Roles) do
		if not v.Name or v.Name == "" then
			error("Role"..tostring(i).." Name"..notFoundOr.."blank")
		end
		if typeof(v.Minimum) ~= "number" then
			warn(v.Name.." Minimum"..notFoundOrNot.."number"..defaulted.."0")
			v.Minimum = 0
		elseif v.Minimum < 0 then
			warn(v.Name.." Minimum"..noNegative..defaulted.."0")
		end
		if typeof(v.Hint) ~= "string" then
			print(v.Name.." Hint not found"..defaulted.."blank")
			v.Hint = ""
		end
		if typeof(v.Colour) ~= "Color3" then
			warn(v.Name.." Colour"..notFoundOrNot.."Color3, check the spelling!")
			v.Colour = Color3.new(0,0,0)
		end
		if typeof(v.Public) ~= "boolean" then
			warn(v.Name.." Public"..notFoundOrNot.."boolean"..defaulted.."true")
			v.Public = true
		end
		if typeof(v.Allies) ~= "table" then
			warn(v.Name.." Allies"..notFoundOrNot.."table"..defaulted.."none")
			v.Allies = {}
		end
		if typeof(v.EquipmentShop) ~= "table" then
			warn(v.Name.." EquipmentShop"..notFoundOrNot.."table"..defaulted.."none")
			v.EquipmentShop = {}
		end
		if typeof(v.StartsWith) ~= "table" then
			warn(v.Name.." StartsWith"..notFoundOrNot.."table"..defaulted.."Crowbar")
		end
		if not v.WinsAs then
			error(v.Name.." WinsAs not found")
		end
	end


	--ADVANCED CHECKS
	if gamemode.TimeLimitBase+(gamemode.MinimumPlayers*gamemode.TimePerPlayer) < 0 then
		error("Time limit is negative when playing with MinimumPlayers, check the TimePerPlayer and TimeLimitBase")
	end
end

return gamemodes