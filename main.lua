--------------------------------------------------------------------------------------------------------------------------------------------------
--------------------- Balance : v0.1
--------------------- Add new item : All enemies got the same amount of life
--------------------- To do : ugly code, optimisation
--------------------- Made by Gamergeo
--------------------------------------------------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------------------------------------------------
--------------------- Mod and variable definition
--------------------------------------------------------------------------------------------------------------------------------------------------

local Balance = RegisterMod("balance", 1)
local game = Game()

CollectibleType.COLLECTIBLE_BALANCE = Isaac.GetItemIdByName("Balance")

-- Total Life of ennemies, at any moment
Balance.TotalLife = 0

-- Debug Text : Show a debug text
local debugText = "Empty"
local debugChangeText = ""
function Balance:Text()
	Isaac.RenderText(debugText, 100, 100, 255, 0, 0, 255)
	
	if (debugText ~= debugChangeText) then
		debugChangeText = debugText
		Isaac.DebugString(debugText)
	end
end
Balance:AddCallback(ModCallbacks.MC_POST_RENDER, Balance.Text)

--------------------------------------------------------------------------------------------------------------------------------------------------
--------------------- Callback methods
--------------------------------------------------------------------------------------------------------------------------------------------------
  
-- On Start : Give Item (Will be deleted)
function Balance:OnStart()
	debugText = "Start"
	Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, CollectibleType.COLLECTIBLE_BALANCE, Vector(320,300), Vector(0,0), nil)
end

Balance:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, Balance.OnStart)

-- On New Room : Equalize all life
-- function Balance:OnNewRoom() 
	-- debugText = "Enter new room"

	-- if Balance:HasBalance() then
		-- Balance:CalculateAllLife()
		-- debugText = "TotalLife : " .. tostring(Balance.TotalLife)
		-- Balance:SetNewLife()
	-- end
-- end

-- Balance:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, Balance.OnNewRoom)

-- onNPCDamage = Equalize the new life
function Balance:OnNPCDamage(target, amount, source, dealer)

	-- Ennemy has been damaged : we need to damage every enemy in the room
	if Balance:HasBalance() and target:IsActiveEnemy() then
	
		Isaac.DebugString("Ennemy life: " .. tostring(target.HitPoints))
		Isaac.DebugString("Damage: " .. tostring(amount))
		
		local newTotalLife = target.HitPoints - amount
		
		-- Damage is mortal : everyone will die !
		if (newTotalLife <= 0) then
			debugText = "Die die die"
		
			for i, entity in pairs(Isaac.GetRoomEntities()) do
			
				-- We dont change the target life, he is damaged by returning nil at the end of the function
				if entity:IsActiveEnemy() and entity:ToNPC() ~= target then
					entity:Kill()
				end
			end
			Balance.TotalLife = 0
		else
			--debugText = "Total life after dmg " .. tostring(target.HitPoints - amount)
			for i, entity in pairs(Isaac.GetRoomEntities()) do
			
				-- We dont change the target life, he is damaged by returning nil at the end of the function
				if entity:IsActiveEnemy() and entity.Index ~= target.Index then
					entity.HitPoints = newTotalLife
				end
			end
			
			Balance.TotalLife = newTotalLife
			debugText = "Total life after dmg " .. tostring(Balance.TotalLife)
		end
	end
end

Balance:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, Balance.OnNPCDamage)

-- new enemy spawned : set the correct total life
-- Remarks : npc is not yet editable in fact. some values will be set after this event, making useless to change npc stats
-- For exemple, npc.HitPoints is accurate here. But you can't add health points for some reasons
function Balance:OnEnemySpawn(npc)
	if Balance:HasBalance() and npc:IsActiveEnemy() and npc:IsVulnerableEnemy() then
		Balance.TotalLife = Balance.TotalLife + npc.HitPoints
		debugText = "Spawning total life" .. tostring(Balance.TotalLife)
	end
end

Balance:AddCallback(ModCallbacks.MC_POST_NPC_INIT, Balance.OnEnemySpawn)

-- Enemy updated  : we should check the life is ok
function Balance:OnNpcUpdate(npc)
  	if Balance:HasBalance() and npc:IsActiveEnemy() and npc:IsVulnerableEnemy() and not npc:IsDead() and npc.HitPoints ~= Balance.TotalLife then
		Isaac.DebugString("Npc Updated life from " .. tostring(npc.HitPoints)  .. " to " .. tostring(Balance.TotalLife))
		npc.HitPoints = Balance.TotalLife
	end
end

Balance:AddCallback(ModCallbacks.MC_NPC_UPDATE , Balance.OnNpcUpdate)

--------------------------------------------------------------------------------------------------------------------------------------------------
--------------------- Utilitary methods
--------------------------------------------------------------------------------------------------------------------------------------------------

-- return true if one player has Balance
function Balance:HasBalance()

	for playersNum = 1, game:GetNumPlayers() do
		local player = game:GetPlayer(playersNum)
		
		if player:HasCollectible(CollectibleType.COLLECTIBLE_BALANCE) then
			return true
		end
	end
	
	return false
end

-- calculate the total amount of ennemies life
function Balance:CalculateAllLife()
    local totalLife = 0
	
	for i, entity in pairs(Isaac.GetRoomEntities()) do
		if entity:IsVulnerableEnemy() and entity:IsActiveEnemy() then
		  totalLife = totalLife + entity.HitPoints
		end
	end
	Balance.TotalLife = totalLife
end

-- set the @numberLife as life for every ennemy
function Balance:SetNewLife()
	for i, entity in pairs(Isaac.GetRoomEntities()) do
		if entity:IsVulnerableEnemy() and entity:IsActiveEnemy()  then
			
			Isaac.DebugString("entity " .. tostring(i) .. " life : " .. tostring(entity.HitPoints))
			entity.HitPoints = Balance.TotalLife
		end
    end
end