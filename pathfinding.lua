local npc = {}


PFS = game:GetService("PathfindingService")
SSS = game:GetService("ServerScriptService")
repStore = game:GetService("ReplicatedStorage")
servStore = game:GetService("ServerStorage")
regionModule = require(SSS.CombatModules:WaitForChild("RotatedRegion3"))

---
--- PATHFINDING MODULE
--- 

-- Enemy will target nearest player unless a player has a specified 'targetting priority'.
-- Enemies will have very high agro radius.

-- Vars being used in "Config":
-- Vars being used in "Static":
-- Vars being used in "Vars": 

function npc.targetPlr(enemy)
	if not enemy:FindFirstChild("HumanoidRootPart") then print("Root not found in enemy." )return end
	if not enemy:FindFirstChild("Monster") then print("Humanoid not found in enemy.")return end
	
	local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
	local monster = enemy:FindFirstChild("Monster")
	local enemyConfig = enemy.Config
	local enemyVars = enemy.Vars
	
	-- "findNearestTarget" returns the closest player to the enemy.
	local function findNearestTarget()
		local target
		local targetRange
		for _, plr in pairs(game.Players:GetPlayers()) do
			if plr.Character then
				if plr.Character:FindFirstChild("HumanoidRootPart") then
					
					local plrRoot = plr.Character:FindFirstChild("HumanoidRootPart")
					local dist = (plrRoot.Position - enemyRoot.Position).magnitude
					
					if dist <= enemyConfig.agroDist.Value then -- if player is within range.
						if not targetRange then
							target = plr
							targetRange = dist
						elseif dist >= targetRange then
							target = plr
							targetRange = dist
						end
					end
					
				end
			end
		end
		
		if target then return target end
	end
	------
	
	
	-- Function to calculate "newPos" which is used to generate a position which is offset by the attackMag variable.
	local function goTo(pos)
		local ai = enemyRoot.Position
		local attackMag = enemyConfig.attackMag.Value
		
		local newPos = (ai - pos).Unit * attackMag + pos 
		
		monster:MoveTo(newPos) -- Moves the player to the offset position.
	end
	------
	
	
	-- Function "checkRayCast" is used to see if there's no obstacles in the way. Returns true if the path is clear.
	local function checkRayCast(plrRoot) -- Checking if area is clear, without field of view.
		
		print("checking raycast for the player.")
		-- creates raycast from the enemy to the player.
		local ray = Ray.new(enemyRoot.Position, (plrRoot.Position - enemyRoot.Position).Unit * 100)
		
		-- Generates ignorelist, which removes any extra pieces that are not the players root part.
		local ignoreList = {}
		local c = plrRoot.Parent:GetChildren()
		for _, plrPart in pairs(c) do
			if plrPart ~= plrRoot then
				table.insert(ignoreList, plrPart)
			end
		end
		
		table.insert(ignoreList, workspace.__mobs) -- adds all mobs to the ignorelist.
		local hit, position = workspace:FindPartOnRayWithIgnoreList(ray, ignoreList)
		
		if hit then -- If the ray hits the playerr or another object.
			local hum = hit.Parent:FindFirstChild("Humanoid")
			if not hum then -- If the hit part is not the player.
				hum = hit.Parent.Parent:FindFirstChild("Humanoid")
			end
			if hum then return true end
		end
		
	end
	------
	
	-- Function "createPath" is used to generate a path around objects 
	local function createPath(plrRoot)
		local agentRad = enemyConfig.agentRad.Value
		local agentHeight = enemyConfig.agentHeight.Value
		
		local args = {
			AgentRadius = agentRad,
			AgentHeight = agentHeight,
			AgentCanJump = true,
		}
		local path = PFS:CreatePath(args)
		path:ComputeAsync(enemyRoot.Position, plrRoot.Position)
		local points = path:GetWaypoints()
		
		if path.Status == Enum.PathStatus.Success then
			
			
			for i,v in pairs(points) do
				warn("generating point: ".. i)
				-- TRACE DEBUGGER PATH: Displays the waypoints to achieve destination.
				
				--[[
				spawn(function()
					print("spawning part.")
					local part = Instance.new("Part")
					part.Shape = "Ball"
					part.Material = "Neon"
					part.Size = Vector3.new(0.6, 0.6, 0.6)
					part.Position = v.Position
					part.Anchored = true
					part.CanCollide = false
					part.Parent = workspace.pathtrace
					wait(2)
					part:Destroy()
				end)
				]]
				
				local check = checkRayCast(plrRoot)
				if check then goTo(plrRoot.Position) break end
				
				monster:MoveTo(v.Position)
				wait(.25)
			end
			
		else
			print("path status failed")
			goTo(plrRoot.Position)
		end
	end
	
	
	-- Main event. Handles what to do during certain situations.
	local function runPath()
		
		-- 1. Find nearest target, store as variable.
		-- 2. Take player variable, raycast to see if there's anything in the way.
		-- 3. Create path if no human is detected from the raycast.
		
		local plr = findNearestTarget()
		
		if plr then
			print("player found: ".. plr.Name)
			if plr.Character then
				print("character found")
				if plr.Character:FindFirstChild("HumanoidRootPart") then
					print("root found")
					local plrRoot = plr.Character:FindFirstChild("HumanoidRootPart")
					local canSee = checkRayCast(plrRoot)
					
					if canSee then
						warn("raycast hit")
						goTo(plrRoot.Position)
					else
						print("Generating path")
						createPath(plrRoot)
					end
				end
			end
		end
	end
	
	runPath()
	
end


return npc
