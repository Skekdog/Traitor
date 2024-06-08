---------------------------------------------------------------------------------------------------------------------

--	Upload "MainModule" to a FREE model. Use model ID in the MAP/ command.
--	Ex. MAP/495394399
--  YOUR MAP CAN AND WILL BE STOLEN! Please keep the ID a secret.

-- Models -----------------------------------------------------------------------------------------------------------

--	"ActionItems" should contain scripted objects such as buttons and Traitor nodes.
--		* CanCollide only
--		* Either Anchored or Non-Anchored
--				* Anchored Examples: buttons, Traitor nodes
--				* Non-Anchored Examples: welded parts
--		* Raycasting collision
--		* Regenerates on round start

--	"Bounds" should contain any parts that shouldn't block bullets.
--		* Either CanCollide or Non-CanCollide
--				* CanCollide Examples: invisible walls, stair assist ramp
--				* Non-CanCollide Examples: tree leaves, graffiti
--		* Anchored only

--	"Props" should contain any parts that are mobile or destructible.
--		* CanCollide only
--		* Either Anchored or Non-Anchored
--				* Anchored Examples: destructible wall chunks
--				* Non-Anchored Examples: all other props
--		* Raycasting collision
--		* Regenerates on round start

--	"Map" should contain any parts that are solid.
--		* CanCollide only
--		* Anchored only
--		* Raycasting collision

-- Props ------------------------------------------------------------------------------------------------------------

--	Must be a Part (models will cause errors.) Props are allowed to have welded Parts as children.
--	Any custom props should be labelled with Custom_ before the name.
--	Anchored props cannot be grabbed, but Non-Anchored props need NoGrab to prevent grabbing.

-- Outbound API -----------------------------------------------------------------------------------------------------

--	game:GetService("ReplicatedStorage").ServerInterconnect.GetCredits:Invoke(string PlayerName)
--		return number Credits

--	game:GetService("ReplicatedStorage").ServerInterconnect.GetGameTeam:Invoke(string PlayerName)
--		return string TeamName

--	game:GetService("ReplicatedStorage").ServerInterconnect.IsNear:Invoke(Player Player, Vector3 Position, number Magnitude)
--		return boolean IsNear

--	game:GetService("ReplicatedStorage").ServerInterconnect.DamagePlayer:Fire(boolean Pregame, <nil | Player Assailant | string AssailantName | true>, Player Target, number Damage, string TypeOfDamage, <nil | Vector3 Position> )
--		Pregame must be 'true' if the player should get hurt before the round starts.
--		Use 'true' for parameter 2 if crediting whoever pushed Target.
--		Use 'nil' for parameter 2 if no credit is desired.
--		TypeOfDamage must be one of the following:
--			<empty string>
--			Fall
--			Prop
--			Fire
--			Water
--			C4
--		Position is optional. It shows the player what direction the damage came from.

--	game:GetService("ReplicatedStorage").ServerInterconnect.Door:Fire(nil, nil, BasePart Door, boolean Direction)

--	game:GetService("ReplicatedStorage").ServerInterconnect.ExplosiveBarrel:Fire(BasePart Barrel, <nil | Player Assailant | string AssailantName>)

--	game:GetService("ReplicatedStorage").ServerInterconnect.GenericExplosion:Fire(<nil | Player Assailant | string AssailantName>, Vector3 Position, number Radius, number Damage)

--	game:GetService("ReplicatedStorage").ServerInterconnect.GiveWeapon:Fire(<Player Player | string PlayerName>, string WeaponName, <nil | integer Magazine>, <nil | integer Reserve>)
--		WeaponName must be one of the following:
--			AWP
--			Binoculars
--			C4
--			DNA scanner
--			Death Station
--			Decoy
--			Defuser
--			Desert Eagle
--			Discombobulator
--			Five-seveN
--			Flare gun
--			Freeze grenade
--			G18
--			Golden gun
--			Headtaker
--			Health Station
--			Incendiary grenade
--			Jihad bomb
--			Knife
--			M1014
--			M11
--			M249 SAW
--			M4A1 Carbine
--			Melon launcher
--			Newton launcher
--			Nyan gun
--			Poltergeist
--			Radio
--			Scout
--			Silenced Pistol
--			Smoke grenade
--			Teleporter
--			Turtle
--			UMP Prototype
--			Visualizer

--	game:GetService("ReplicatedStorage").ServerInterconnect.SetLastPosition:Fire(<Player Player | string PlayerName>, Vector3 Position)

--	game:GetService("ReplicatedStorage").ServerInterconnect.SpawnAmmo:Fire(string Ammo, integer Reserve, CFrame Origin, Vector3 Velocity, Vector3 RotVelocity)
--		Ammo must be one of the following:
--			High-Cal
--			Mil-Spec
--			Rifle
--			SMG
--			Shotgun

--	game:GetService("ReplicatedStorage").ServerInterconnect.SpawnWeapon:Fire(string WeaponName, <nil | integer Magazine>, <nil | integer Reserve>, CFrame Origin, Vector3 Velocity, Vector3 RotVelocity)
--		WeaponName must be one of the following:
--			(See list under GiveWeapon)

--	game:GetService("ReplicatedStorage").ServerInterconnect.SubtractCredit:Fire(<Player Player | string PlayerName>)

--	Door.DoorLocked.Value = bool Locked

-- Inbound API ------------------------------------------------------------------------------------------------------

--	game:GetService("ReplicatedStorage").ServerAnnouncements.PlayerInjured.Event:Connect(Player Victim, <nil | Player Assailant>, number Damage, number Health, bool Died)

--	game:GetService("ReplicatedStorage").ServerAnnouncements.RoundProgressed.Event:Connect(<0 | 1 | 2 | 3>, integer RoundsUntilMapChange)
--		Parameter 1 will be one of the following:
--			0	Waiting for players
--			1	Preparing
--			2	In progress
--			3	Round over

-- Messaging API ----------------------------------------------------------------------------------------------------

--	game:GetService("ReplicatedStorage").ClientEvents.TakeChat:FireClient(Player Recipient, string Message, boolean Use_Team_Chat, <nil | integer Sender_UserId>)

--	game:GetService("ReplicatedStorage").ClientEvents.TakeNotification:FireClient(Player Recipient, string Message, integer Color)

--	game:GetService("ReplicatedStorage").ClientEvents.TakeHint:FireClient(Player Recipient, string Message)

-- Terrain Shortcuts ------------------------------------------------------------------------------------------------

--	Copy Terrain to TerrainRegion
--	workspace.Terrain:CopyRegion(workspace.Terrain.MaxExtents).Parent = workspace

--	Clear Terrain
--	workspace.Terrain:Clear()

--	Paste TerrainRegion to Terrain
--	workspace.Terrain:PasteRegion(workspace.TerrainRegion, workspace.Terrain.MaxExtents.Min, true)