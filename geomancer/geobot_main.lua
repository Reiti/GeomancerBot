-- _____            _           _   
-- |  __ \          | |         | |  
-- | |  \/ ___  ___ | |__   ___ | |_ 
-- | | __ / _ \/ _ \| '_ \ / _ \| __|
-- | |_\ \  __/ (_) | |_) | (_) | |_ 
-- \____/\___|\___/|_.__/ \___/ \__|

-- GEOBOT v0.8
-- This bot contains some basic geomancer logic and will be extended
-- also he is awesome and epic
-- by [IxM]NotReiti and [IxM]Giymo11



--####################################################################
--####################################################################
--#                                                                 ##
--#                       Bot Initiation                            ##
--#                                                                 ##
--####################################################################
--####################################################################

local _G = getfenv(0)
local object = _G.object

object.myName = object:GetName()

object.bRunLogic        = true
object.bRunBehaviors    = true
object.bUpdates         = true
object.bUseShop         = true

object.bRunCommands     = true 
object.bMoveCommands    = true
object.bAttackCommands  = true
object.bAbilityCommands = true
object.bOtherCommands   = true

object.bReportBehavior 	= true
object.bDebugUtility 	= false

object.logger 			= {}
object.logger.bWriteLog = false
object.logger.bVerboseLog = false

object.core             = {}
object.eventsLib        = {}
object.metadata         = {}
object.behaviorLib      = {}
object.skills           = {}

runfile "bots/core.lua"
runfile "bots/botbraincore.lua"
runfile "bots/eventsLib.lua"
runfile "bots/metadata.lua"
runfile "bots/behaviorLib.lua"

local core, eventsLib, behaviorLib, metadata, skills = object.core, object.eventsLib, object.behaviorLib, object.metadata, object.skills

local print, ipairs, pairs, string, table, next, type, tinsert, tremove, tsort, format, tostring, tonumber, strfind, strsub
    = _G.print, _G.ipairs, _G.pairs, _G.string, _G.table, _G.next, _G.type, _G.table.insert, _G.table.remove, _G.table.sort, _G.string.format, _G.tostring, _G.tonumber, _G.string.find, _G.string.sub
local ceil, floor, pi, tan, atan, atan2, abs, cos, sin, acos, max, random
    = _G.math.ceil, _G.math.floor, _G.math.pi, _G.math.tan, _G.math.atan, _G.math.atan2, _G.math.abs, _G.math.cos, _G.math.sin, _G.math.acos, _G.math.max, _G.math.random

local BotEcho, VerboseLog, BotLog = core.BotEcho, core.VerboseLog, core.BotLog
local Clamp = core.Clamp


BotEcho(object:GetName()..' loading geobot_main...')

-- Choosing lanes
core.tLanePreferences = {Jungle = 0, Mid = 4, ShortSolo = 5, LongSolo = 3, ShortSupport = 3, LongSupport = 1, ShortCarry = 2, LongCarry = 2}

-- hero_<hero>  to reference the internal hon name of a hero, Hero_Yogi ==wildsoul
object.heroName = 'Hero_Geomancer'

-- item names so I don't have to remember
local sSheepstick    = "Item_Morph"
local sFrostfield    = "Item_FrostfieldPlate"
local sPortalkey     = "Item_PortalKey"
local sRingOfSorcery = "Item_Replenish"
local sManaBattery   = "Item_ManaBattery"
local sPowerSupply   = "Item_PowerSupply"
local sSteamboots    = "Item_Steamboots"

-- Mana Costs of abilities
local nDigCost 	 = 120
local nSandCost  = 80
local nGraspCost = 100
local function getCrystalCost( nLevel )
	if nLevel == 1 then
		return 200
	elseif nLevel == 2 then
		return 250
	elseif nLevel == 3 then
		return 300
	end
end

-- item buy order. internal names  (Intel5 is Talisman of Exile)
behaviorLib.StartingItems  = {"Item_MarkOfTheNovice", "2 Item_MinorTotem", "Item_RunesOfTheBlight", "Item_ManaPotion", "Item_HealthPotion"}
behaviorLib.LaneItems      = {sManaBattery, "Item_Intelligence5", sPowerSupply, sSteamboots,"Item_MysticVestments", sRingOfSorcery}
behaviorLib.MidItems       = {sPortalkey, sFrostfield}
behaviorLib.LateItems      = {sSheepstick, "Item_GrimoireOfPower"}

-- Skillbuild table, 0 = Dig, 1 = Grasp, 2 = Quicksand, 3 = Crystal Field, 4 = Attributes
object.tSkills = {
    0, 2, 2, 1, 2,
    3, 2, 0, 0, 0, 
    3, 1, 1, 1, 4,
    3, 4, 4, 4, 4,
    4, 4, 4, 4, 4,
}

-- initialize skills
function object:SkillBuild()

    core.VerboseLog("skillbuild()")

    local unitSelf = self.core.unitSelf
    
    if  skills.abilDig == nil then -- skills are not initialized
        skills.abilDig = unitSelf:GetAbility(0)
        skills.abilSand = unitSelf:GetAbility(1)
        skills.abilGrasp = unitSelf:GetAbility(2)
        skills.abilCrystal = unitSelf:GetAbility(3)
    else
        skills.abilAttributeBoost = unitSelf:GetAbility(4)
    end

    local nPoints = unitSelf:GetAbilityPointsAvailable()
    if nPoints <= 0 then
        return
    end
    
    local nMyLevel = unitSelf:GetLevel()
    for i = nMyLevel, (nMyLevel + nPoints) do
        unitSelf:GetAbility( object.tSkills[i] ):LevelUp()
    end
end

-- melee weight overrides
behaviorLib.nCreepPushbackMul = 0.6 --default: 1
behaviorLib.nTargetPositioningMul = 0.7 --default: 1

-- bonus aggression points if a skill is available for use
object.nDigUp = 17
object.nSandUp = 15
object.nGraspUp = 6
object.nCrystalUp = 10
-- items
object.nPortalkeyUp = 15
object.nFrostfieldUp = 8
object.nSheepstickUp = 7

-- bonus aggression points that are applied to the bot upon successfully using a skill
object.nDigUse = 30
object.nSandUse = 18
object.nGraspUse = 4
object.nCrystalUse = 25
-- items
object.nPortalkeyUse = 0
object.nFrostfieldUse = 22
object.nSheepstickUse = 18

-- bonu aggression points for enemy status effects
object.nSlowedAggressionBonus = 10  -- only applicable for dig
object.nRootedAggressionBonus = 15  -- only applicable for crystal

--thresholds of aggression the bot must reach to use these abilities
object.nDigThreshold = 62
object.nSandThreshold = 35
object.nGraspThreshold = 32
object.nCrystalThreshold = 58
object.nDigWithPortalkeyThreshold = 30 -- when you have dig and portalkey up
object.nFrostfieldThreshold = 50
object.nSheepstickThreshold = 40

-- thresholds for retreating
object.nRetreatQuicksandThreshold = 93
object.nRetreatDigThreshold = 90
object.nRetreatPortThreshold = 90
object.nRetreatFrostfieldThreshold = 92
object.nRetreatSheepThreshold = 93

object.nOldRetreatFactor = 0.9
object.nMaxLevelDifference = 4
object.nEnemyBaseThreat = 6

--values used for correct placement and casting of skills
object.vecStunTargetPos = nil
object.nDigTime = 0
object.bDigging = false
object.nTimeNeededForDistance = 0
object.nDigStunRadius = 250
object.nDigStunRadiusSq = object.nDigStunRadius*object.nDigStunRadius
object.nGraspRadius = 180
object.nQuicksandRadius = 	250
object.nRetreatDigTime = 0
object.bRetreating = false

-- diving Threshold
behaviorLib.diveThreshold = 96

-- modified (generalized) copypasta from snippet compedium
local function funcBestTargetAOE(tEnemyHeroes, nRange)
    local nHeroes = core.NumberElements(tEnemyHeroes)
    if nHeroes <= 1 then
        return tEnemyHeroes[0]
    end
 
    local tTemp = core.CopyTable(tEnemyHeroes)
 
    local nRangeSq = nRange*nRange
    local nDistSq = 0
    local unitBestTarget = nil
    local nBestTargetsHit = 0
 
    for nTargetID,unitTarget in pairs(tEnemyHeroes) do
        local nTargetsHit = 1
        local vecCurrentTargetsPosition = unitTarget:GetPosition()
        for nHeroID,unitHero in pairs(tTemp) do
            if nTargetID ~= nHeroID then
                nDistSq = Vector3.Distance2DSq(vecCurrentTargetsPosition, unitHero:GetPosition())
                if nDistSq < nRangeSq then
                    nTargetsHit = nTargetsHit + 1
                end
            end
        end
 
        if nTargetsHit > nBestTargetsHit then
            nBestTargetsHit = nTargetsHit
            unitBestTarget = unitTarget
        end
    end
 
    return unitBestTarget
end


-- method to predict movement of target unit
local function funcPredictNextPosition(botBrain, unitTarget, vecTarget, radius) 
	if unitTarget.blsMemoryUnit then
		if unitTarget.storedPosition and unitTarget.lastStoredPosition then
			local vecLastDirection = Vector3.Normalize(unitTarget.storedPosition - unitTarget.lastStoredPosition)
			 return vecTarget + vecLastDirection*radius
		end
	end
	return vecTarget
end


-- function to control digging
local function funcCastDig(botBrain, vecTargetPosition, unitTarget)
	local bActionTaken = false
	local abilDig = skills.abilDig
	if HoN.GetGameTime()-object.nDigTime > object.nTimeNeededForDistance or Vector3.Distance2DSq(unitTarget:GetPosition(), core.unitSelf:GetPosition()) < object.nDigStunRadiusSq then
		if object.bDigging == true then
			bActionTaken = core.OrderAbility(botBrain, abilDig)
			object.bDigging = false
		else
			object.bRetreating = false
			bActionTaken = core.OrderAbilityPosition(botBrain, abilDig, vecTargetPosition)
			object.nDigTime = HoN.GetGameTime()
			vecStunTargetPos = Vector3.Create(vecTargetPosition.x, vecTargetPosition.y, vecTargetPosition.z)
			vecStunTargetPos = funcPredictNextPosition(botBrain, unitTarget, vecStunTargetPos,  object.nDigStunRadius) 
			object.nTimeNeededForDistance = (Vector3.Distance(vecStunTargetPos, core.unitSelf:GetPosition())/700)*1000
			object.bDigging = true
		end
	end
	
	return bActionTaken
end

local function funcCastEscapeDig(botBrain, vecTargetPosition)
	local bActionTaken = false
	local abilDig = skills.abilDig
	if HoN.GetGameTime()-object.nDigTime > object.nTimeNeededForDistance then
		if object.bDigging == true then
			bActionTaken = core.OrderAbility(botBrain, abilDig)
			object.bDigging = false
		else
			object.bRetreating = false
			bActionTaken = core.OrderAbilityPosition(botBrain, abilDig, vecTargetPosition)
			object.nDigTime = HoN.GetGameTime()
			vecStunTargetPos = Vector3.Create(vecTargetPosition.x, vecTargetPosition.y, vecTargetPosition.z)
			object.nTimeNeededForDistance = (Vector3.Distance(vecStunTargetPos, core.unitSelf:GetPosition())/700)*1000
			object.bDigging = true
		end
	end
	
	return bActionTaken
end


-- onthink Override
function object:onthinkOverride(tGameVariables)
    self:onthinkOld(tGameVariables)
    
    local itemSteamboots = core.GetItem(sSteamboots)
    if itemSteamboots and itemSteamboots:CanActivate() then
	    -- Toggle Steamboots for more Health/Mana
		local unitSelf = core.unitSelf
		local sKey = itemSteamboots:GetActiveModifierKey()

		if sKey == "str" then -- Toggle away from STR if health is high enough
			if unitSelf:GetHealthPercent() > .65 then
				self:OrderItem(itemSteamboots.object, false)
			end
		elseif sKey == "agi" then -- Always toggle past AGI
			self:OrderItem(itemSteamboots.object, false)
		elseif sKey == "int" then -- Toggle away from INT if health gets too low
			if unitSelf:GetHealthPercent() < .40 then
				self:OrderItem(itemSteamboots.object, false)
			end
		end
    end
    -- TODO: end your dig when the destinatino is reached / you get your target(s)
end

object.onthinkOld = object.onthink
object.onthink 	= object.onthinkOverride


----------------------------------------------
-- use to check for infilictors (fe. buffs) --
----------------------------------------------

local function onAbilityEvent( sInflictorName )
	if sInflictorName == "Ability_Geomancer1" and not object.bRetreating then
        return object.nDigUse
    elseif sInflictorName == "Ability_Geomancer2" then
        return object.nSandUse
	elseif sInflictorName == "Ability_Geomancer3" then
        return object.nGraspUse
    elseif sInflictorName == "Ability_Geomancer4" then
        return object.nCrystalUse
    else
    	return 0
	end
end

local function onItemEvent( sInflictorName )
	local itemSheepStick = core.GetItem(sSheepstick)
	local itemFrostfield = core.GetItem(sFrostfield)
	local itemPortalkey  = core.GetItem(sPortalkey)

	if itemSheepstick ~= nil and sInflictorName == itemSheepstick:GetName() then
        return self.nSheepstickUse
    elseif itemFrostfield ~= nil and sInflictorName == itemFrostfield:GetName() then
        return self.nFrostfieldUse
    elseif itemPortalkey ~= nil and sInflictorName == itemPortalkey:GetName() then
        return self.nPortalkeyUse
    else 
    	return 0
	end
end

function object:oncombateventOverride(EventData)
	self:oncombateventOld(EventData)
	
	-- add check if it's a retreat behaviour 
	if bRetreating == true then
		bRetreating = false
		return
	end
	
    local nAddBonus = 0

    if EventData.Type == "Ability" then
    	BotEcho("  ABILILTY EVENT!  InflictorName: "..EventData.InflictorName)
    	nAddBonus = onAbilityEvent(EventData.InflictorName)
    elseif EventData.Type == "Item" then
    	BotEcho("  ITEM EVENT!  InflictorName: "..EventData.InflictorName)
        if EventData.SourceUnit == core.unitSelf:GetUniqueID() then
        	nAddBonus = onItemEvent(EventData.InflictorName)
    	end
    end
 
   if nAddBonus > 0 then
        core.DecayBonus(self)
        core.nHarassBonus = core.nHarassBonus + nAddBonus
    end
end

-- override combat event trigger function.
object.oncombateventOld = object.oncombatevent
object.oncombatevent    = object.oncombateventOverride


local function getTotalAggressiveManaCost()
	local nTotalMana = skills.abilDig:GetManaCost() -- always save mana for this one, even if it's on CD

	if skills.abilGrasp:GetLevel() > 0 then
		nTotalMana = nTotalMana + skills.abilGrasp:GetManaCost()
	end
	if skills.abilSand:GetLevel() > 0 then
		nTotalMana = nTotalMana + skills.abilSand:GetManaCost()
	end
	if skills.abilCrystal:GetLevel() > 0 then
		nTotalMana = nTotalMana + skills.abilCrystal:GetManaCost()
	end

	local itemSheepStick = core.GetItem(sSheepstick)
	local itemFrostfield = core.GetItem(sFrostfield)
	local itemPortalkey  = core.GetItem(sPortalkey)

	if itemSheepstick ~= nil then
		nTotalMana = nTotalMana + itemSheepstick:GetManaCost()
	end
	if itemFrostfield ~= nil then
		nTotalMana = nTotalMana + itemFrostfield:GetManaCost()
	end
	if itemPortalkey ~= nil then
		nTotalMana = nTotalMana + itemPortalkey:GetManaCost()
	end

	return nTotalMana
end

------------------------------------------------------
--            customharassutility override          --
-- change utility according to usable spells here   --
------------------------------------------------------
local function CustomHarassUtilityFnOverride(hero)
    local nUtil = 0
	local nTotalMana = getTotalAggressiveManaCost()

	-- check health percentage, be more aggressive with more health
	-- check total mana availability, add only the utils of what you really can use

    if skills.abilDig:CanActivate() then
        nUtil = nUtil + object.nDigUp
    end
    if skills.abilGrasp:CanActivate() then
		nUtil = nUtil + object.nGraspUp
	end
 
    if skills.abilSand:CanActivate() then
        nUtil = nUtil + object.nSandUp
    end
    if skills.abilCrystal:CanActivate() then
        nUtil = nUtil + object.nCrystalUp
    end
 
    if object.itemSheepstick and object.itemSheepstick:CanActivate() then
        nUtil = nUtil + object.nSheepstickUp
    end
	if object.itemPortalkey and object.itemPortalkey:CanActivate() then 
		nUtil = nUtil + object.nPortalkeyUp
	end
	if object.itemFrostfield and object.itemFrostfield:CanActivate() then
		nUtil = nUtil + object.nFrostfieldUp
	end
	
	local unitSelf = core.unitSelf
	local nUtilMul = 0
	
	-- if we have mana to do e.g. 80% of the skills available, we use only 80% of the aggression util for these skills
	nUtilMul = unitSelf:GetMana() / nTotalMana
	
	if nUtilMul > 1 then
		nUtilMul = 1
	end
	
	-- if we have more than 70% health, we use the full aggression
	-- the 70% below get scaled to 30% to 100% and multiplied with the aggression util

	if not (unitSelf:GetHealthPercent() > 0.7) then
		nUtilMul = nUtilMul * ( ( unitSelf:GetHealthPercent() ) + 0.3 )
	end
	-- we ensure that the util never goes above 100
	nUtil = Clamp(nUtil, 0, 100)
	-- not more than 100 because nUtilMul can never be more than 1
    return nUtil*nUtilMul
end
-- assign custom harass function to the behaviourLib object
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride   



--------------------------------------------------------------
--                    Push Overrides                        --
-- A behaviour to use abilities to push						--
--------------------------------------------------------------
-- @param botBrain: CBotBrain
-- @return: none
--


local function funcAbilityPush(botBrain)
	local bActionTaken = false
	local unitBestGraspTarget = nil
	local unitBestDigTarget = nil
	local nTotalMana = getTotalAggressiveManaCost()
	
	local unitSelf = core.unitSelf
	local abilDig = skills.abilDig
	local abilGrasp = skills.abilGrasp
	local abilSand = skills.abilSand
	local abilCrystal = skills.abilCrystal
	
	local vecMyPosition = unitSelf:GetPosition()

	local enemyCreeps = core.localUnits["EnemyCreeps"]
	
	if abilGrasp:CanActivate() and ( unitSelf:GetMana() - abilGrasp:GetManaCost() ) > nTotalMana then
		unitBestGraspTarget = funcBestTargetAOE(enemyCreeps, object.nGraspRadius)
		if unitBestGraspTarget ~= nil then
			local nTargetDistanceSq = Vector3.Distance2DSq( vecMyPosition, unitBestGraspTarget:GetPosition() )
			local nRange = abilGrasp:GetRange()
			if nTargetDistanceSq < (nRange * nRange) then
				bActionTaken = core.OrderAbilityEntity(botBrain, abilGrasp, unitBestGraspTarget)
			end
		end
	end
	if not bActionTaken and abilDig:CanActivate() and ( unitSelf:GetMana() - abilDig:GetManaCost() ) > nTotalMana then -- we have enough mana to fight if we have to
		local count = 0
		for key, value in pairs(enemyCreeps) do 
			if not value:isMagicImmune() then 
				count = count + 1
			end
		end -- there is no other way to get the size :/
		BotEcho("There are " .. count .. " enemy creeps around.")
		if count >= 3 then 
			unitBestDigTarget = funcBestTargetAOE(enemyCreeps, object.nDigStunRadius)
			if unitBestDigTarget ~= nil then
				local nTargetDistanceSq = Vector3.Distance2DSq( vecMyPosition, unitBestDigTarget:GetPosition() )
				local nRange = abilDig:GetRange()
				if nTargetDistanceSq < (nRange * nRange) then
					bActionTaken = funcCastDig(botBrain, unitBestDigTarget:GetPosition(), unitBestDigTarget)
				end
			end
		end
	end
		
	
	return bActionTaken
end


local function PushExecuteOverride(botBrain)
	if not funcAbilityPush(botBrain) then 
		return object.PushExecuteOld(botBrain)
	end
end
object.PushExecuteOld = behaviorLib.PushBehavior["Execute"]
behaviorLib.PushBehavior["Execute"] = PushExecuteOverride


local function TeamGroupBehaviorOverride(botBrain)
	if not funcAbilityPush(botBrain) then 
		return object.TeamGroupBehaviorOld(botBrain)
	end
end
object.TeamGroupBehaviorOld = behaviorLib.TeamGroupBehavior["Execute"]
behaviorLib.TeamGroupBehavior["Execute"] = TeamGroupBehaviorOverride


local function getGraspDamage()
	nLevel = skills.abilGrasp:GetLevel()
	vecDamageValues = {16, 24, 32, 40}
	BotEcho("Grasp level: " .. nLevel)
	return vecDamageValues[nLevel] * 10  -- for 5 seconds, .5 seconds delay in between
end





-- tracks movement for targets based on a list, so its reusable
-- key is the identifier for different uses (fe. RaMeteor for his path of destruction)
-- vTargetPos should be passed the targets position of the moment
-- to use this for prediction add the vector to a units position and multiply it
-- the function checks for 100ms cycles so one second should be multiplied by 20

-- NOT CURRENTLY USED!

local tRelativeMovements = {}
local function createRelativeMovementTable(key)
	--BotEcho('Created a relative movement table for: '..key)
	tRelativeMovements[key] = {
		vLastPos = Vector3.Create(),
		vRelMov = Vector3.Create(),
		timestamp = 0
	}
--	BotEcho('Created a relative movement table for: '..tRelativeMovements[key].timestamp)
end
-- createRelativeMovementTable("GeoSand") -- for aggressive sand
createRelativeMovementTable("GeoDig")
createRelativeMovementTable("CreepPush") -- for creep-groups while pushing (Dig)

local function relativeMovement(sKey, vTargetPos)
	local debugEchoes = false
	
	local gameTime = HoN.GetGameTime()
	local key = sKey
	local vLastPos = tRelativeMovements[key].vLastPos
	local nTS = tRelativeMovements[key].timestamp
	local timeDiff = gameTime - nTS 
	
	if debugEchoes then
		BotEcho('Updating relative movement for key: '..key)
		BotEcho('Relative Movement position: '..vTargetPos.x..' | '..vTargetPos.y..' at timestamp: '..nTS)
		BotEcho('Relative lastPosition is this: '..vLastPos.x)
	end
	
	if timeDiff >= 90 and timeDiff <= 140 then -- 100 should be enough (every second cycle)
		local relativeMov = vTargetPos-vLastPos
		
		if vTargetPos.LengthSq > vLastPos.LengthSq
		then relativeMov =  relativeMov*-1 end
		
		tRelativeMovements[key].vRelMov = relativeMov
		tRelativeMovements[key].vLastPos = vTargetPos
		tRelativeMovements[key].timestamp = gameTime
		
		
		if debugEchoes then
			BotEcho('Relative movement -- x: '..relativeMov.x..' y: '..relativeMov.y)
			BotEcho('^r---------------Return new-'..tRelativeMovements[key].vRelMov.x)
		end
		
		return relativeMov
	elseif timeDiff >= 150 then
		tRelativeMovements[key].vRelMov =  Vector3.Create(0,0)
		tRelativeMovements[key].vLastPos = vTargetPos
		tRelativeMovements[key].timestamp = gameTime
	end
	
	if debugEchoes then BotEcho('^g---------------Return old-'..tRelativeMovements[key].vRelMov.x) end
	return tRelativeMovements[key].vRelMov
end


--------------------------------------------------------------
--                    Harass Behavior                       --
-- All code how to use abilities against enemies goes here  --
--------------------------------------------------------------

local function HarassHeroExecuteOverride(botBrain)
    
    local unitTarget = behaviorLib.heroTarget
    if unitTarget == nil or not unitTarget:IsValid() then
        return object.harassExecuteOld(botBrain) --Target is invalid, move on to the next behavior
    end
    
    local nLastHarassUtility = behaviorLib.lastHarassUtil

    local bCanSeeTarget = core.CanSeeUnit(botBrain, unitTarget)
    
    local unitSelf = core.unitSelf
    local vecMyPosition = unitSelf:GetPosition() 
    local nAttackRange = core.GetAbsoluteAttackRangeToUnit(unitSelf, unitTarget)
    local nMyExtraRange = core.GetExtraRange(unitSelf)
    
    local vecTargetPosition = unitTarget:GetPosition()
    local nTargetExtraRange = core.GetExtraRange(unitTarget)
    local nTargetDistanceSq = Vector3.Distance2DSq(vecMyPosition, vecTargetPosition)

    local bActionTaken = false

    local nMana = unitSelf:GetMana()

    local nTotalManaCost = getTotalAggressiveManaCost(unitSelf)

    BotEcho("lastHarassUtil: " .. nLastHarassUtility)

-- wanted behaviour:
--  IMPLEMENTED:
--   grasp when much mana to harass
--   grasp when target low hp to keep out of lane (check behaviour)
--   don't grasp when target is too fast (>= 365 movementspeed)
--   sand when high aggression to start initiation
--   don't sand when no damage abilities up and no allies are around
--  TODO:
--   dig in when target has hardly chance to escape
--      check for own distance to him
--      his possible locations when you have reached him (stun/slowed)
--      your stun radius
--   crystal when many people together (as that is probably a teamfight and you want to spread them)    
--   crystal when at least one target has no chance to escape and aggression is high
--   pk in when high aggression and enough TotalMana
--   use sheepstick like sand
--   use FFplate after a PK in
	
	local bTargetCanMove = not unitTarget:IsStunned() and not unitTarget:IsImmobilized()

	local abilGrasp = skills.abilGrasp
	local abilSand = skills.abilSand
	local abilDig = skills.abilDig
	local abilCrystal = skills.abilCrystal

	-- Grasp
	if bCanSeeTarget and not bActionTaken then
		-- Magic EHP calculated by correct formula from HoNForum (also, MagicResistance ~= MagicArmor!)
		
		local nRange = abilGrasp:GetRange()

		BotEcho("Can See Unit")

		if abilGrasp:CanActivate() and nTargetDistanceSq < nRange*nRange then
			BotEcho("Grasp can activate & is in range")
			local nTargetMagicHitPoints = unitTarget:GetHealth() / (1 - unitTarget:GetMagicResistance())
			local bDoGrasp = false
			local nGraspDamage = getGraspDamage()

			if nTargetMagicHitPoints < nGraspDamage / 10 then  -- check if one grasp hit is enough to kill
				BotEcho("One Hit")
				bDoGrasp = true
			elseif ( unitTarget:GetMoveSpeed() < 365 or not bTargetCanMove ) then
				BotEcho("is slow enough")
				if nMana == unitSelf:GetMaxMana() or nMana - nGraspCost > nTotalManaCost then
					BotEcho("Do the mana grasp")
					bDoGrasp = true
				elseif nGraspDamage > nTargetMagicHitPoints then
					BotEcho("Do the killing grasp")
					bDoGrasp = true
				elseif nLastHarassUtility > object.nGraspThreshold then
					BotEcho("Do the aggression grasp")
					bDoGrasp = true
				end
			end
			if bDoGrasp then
				bActionTaken = core.OrderAbilityEntity(botBrain, abilGrasp, unitTarget)
				if bActionTaken then 
					BotEcho("grasped!")
				end
			end
		end
	end


	-- Quicksand
	if not bActionTaken then
		
		local doSand = false

		local nRange = abilSand:GetRange()
		local castActionTime = 0.3
		-- decided for no accurate prediction, because castactiontime = 300ms and radius is 250u
		-- approximating will have to do: center point at predicted movement + 75
		local nOffset = 75
		-- result: there are 175u Sand behind the target, 325 in front of him
		if abilSand:CanActivate() and nLastHarassUtility > object.nSandThreshold then
			if abilDig:CanActivate() and ( abilGrasp:CanActivate() or abilCrystal:CanActivate() ) then -- we have enough damage abilities
				local nManaCost = abilSand:GetManaCost() + abilDig:GetManaCost()
				if abilGrasp:CanActivate() and nManaCost + abilGrasp:GetManaCost() < unitSelf:GetMana() then
					doSand = true
				elseif abilCrystal:CanActivate() and nManaCost + abilCrystal:GetManaCost() < unitSelf:GetMana() then
					doSand = true
				end
			else
				local allyHeroes = core.localUnits["AllyHeroes"]
				local count = 0
				for _ in pairs(allyHeroes) do count = count + 1 end
				if count > 0 then
					doSand = true
				end
			end
			if doSand then
				if not bTargetCanMove then
					BotEcho("target cannot move!")
					bActionTaken = botBrain:OrderAbilityPosition(abilSand, vecTargetPosition)
					if bActionTaken then BotEcho("Ordered Sand!") end
				else
					local vecPredictedEnemyMovement = Vector3.Create(0, 0)
					local nAngle = 0
					if not unitTarget.blsMemoryUnit or unitTarget.storedPosition ~= unitTarget.lastStoredPosition then
						local vecEnemyHeading = unitTarget:GetHeading()
						if not vecEnemyHeading and unitTarget.storedPosition and unitTarget.lastStoredPosition then
							vecEnemyHeading = core.enemyWell - vecTargetPosition
						end
						if vecEnemyHeading then
							nAngle = atan2(vecEnemyHeading.y, vecEnemyHeading.x)
							vecPredictedEnemyMovement = vecEnemyHeading * unitTarget:GetMoveSpeed() * castActionTime
						end
					else
						local vecEnemyToWell = core.enemyWell - vecTargetPosition
						nAngle = atan2(vecEnemyToWell.y, vecEnemyToWell.x)
					end
					local vecOffset = Vector3.Create(cos(nAngle) * nOffset, sin(nAngle) * nOffset)
					-- as cos(alpha) is the x, and sin the y component
					local vecCastPosition = vecTargetPosition + vecPredictedEnemyMovement + vecOffset
					if Vector3.Distance2DSq(vecMyPosition, vecCastPosition) < nRange*nRange then
						BotEcho("predicted enemy position in range!")
						bActionTaken = botBrain:OrderAbilityPosition(abilSand, vecCastPosition)
						if bActionTaken then BotEcho("Ordered Sand!") end
					end
				end
			end
		end
	end

    if core.CanSeeUnit(botBrain, unitTarget) then
		local bTargetVuln = unitTarget:IsStunned() or unitTarget:IsImmobilized()
		local bTargetSlowed = unitTarget:GetMoveSpeed() < 200
		local bTargetRooted = bTargetVuln or bTargetSlowed
		local abilDig = skills.abilDig
		local abilGrasp = skills.abilGrasp
		local abilSand = skills.abilSand
		local abilCrystal = skills.abilCrystal
		local itemSheepstick = core.itemSheepstick
		
		if not bActionTaken and itemSheepstick then
			local nRange = itemSheepstick:GetRange()
			if itemSheepstick:CanActivate() and not bTargetVuln and nLastHarassUtility > botBrain.nSheepstickThreshold and nTargetDistanceSq < (nRange*nRange) then
				bActionTaken = core.OrderItemEntityClamp(botBrain, unitSelf, itemSheepstick, unitTarget)
			end
		end
		
		if not bActionTaken and abilDig:CanActivate() then
			local nRange = abilDig:GetRange()
			local nRangeSq = nRange*nRange
			
			if nLastHarassUtility > botBrain.nDigThreshold then
				if core.itemPortalkey and core.itemPortalkey:CanActivate() then
					nTooCloseRangeSq = ( object.nDigStunRadius + 150 ) * ( object.nDigStunRadius + 150 )
					if nTargetDistanceSq > nTooCloseRangeSq and nTargetDistanceSq < nRangeSq then
						unitBestTarget = funcBestTargetAOE(core.localUnits["EnemyHeroes"], object.nDigStunRadius)
						if unitBestTarget == nil then
							unitBestTarget = unitTarget
						end
						vecPortalkeyTargetPosition = unitBestTarget:GetPosition()
						object.bRetreating = false
						core.OrderAbilityPosition(botBrain, abilDig, vecTargetPosition)
						bActionTaken = core.OrderItemPosition(botBrain, unitSelf, core.itemPortalkey, vecPortalkeyTargetPosition)
					end
				elseif nTargetDistanceSq < nRangeSq then
					bActionTaken = funcCastDig(botBrain, vecTargetPosition, unitTarget)
				end
			elseif bTargetSlowed and not bTargetVuln then
				if (nLastHarassUtility + object.nSlowedAggressionBonus) > botBrain.nDigThreshold then 
					if nTargetDistanceSq < nRangeSq then
						bActionTaken = funcCastDig(botBrain,vecTargetPosition, unitTarget)
					end
				end
			end
		end
		
		if not bActionTaken and abilCrystal:CanActivate() then
			local nRange = abilCrystal:GetRange()
			local nRangeSq = nRange*nRange
			if core.itemFrostfield and core.itemFrostfield:CanActivate() then
				core.OrderItemClamp(botBrain, unitSelf, core.itemFrostfield)
			end
			if bTargetRooted then
				if (nLastHarassUtility + object.nRootedAggressionBonus) > botBrain.nCrystalThreshold then
					if nTargetDistanceSq < nRangeSq then
						 vecCrystalTargetPosition = core.GetGroupCenter(core.localUnits["EnemyHeroes"])
						 bActionTaken = core.OrderAbilityPosition(botBrain, abilCrystal, vecCrystalTargetPosition)
					end
				end
			elseif nLastHarassUtility > botBrain.nCrystalThreshold then
				if nTargetDistanceSq < nRangeSq then
					vecCrystalTargetPosition = core.GetGroupCenter(core.localUnits["EnemyHeroes"])
					bActionTaken = core.OrderAbilityPosition(botBrain, abilCrystal, vecCrystalTargetPosition)
				end
			end
			object.bTargetVulnOld = bTargetVuln
		end
	end
    
    if not bActionTaken then
        return object.harassExecuteOld(botBrain)
    end 
end
-- overload the behaviour stock function with custom 
object.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride


--------------------------------------------------
-- RetreatFromThreat Override --
--------------------------------------------------

local function funcPositionOffset(pos, angle, distance) 
	tmp = Vector3.Create(cos(angle)*distance,sin(angle)*distance)
	return tmp+pos
end


--cast dig in direction of well
local function funcEscapeDig(botBrain)
	BotEcho('Escape dig')
	local abilDig = skills.abilDig
	local bActionTaken = false
	local vecTarget = behaviorLib.GetSafeBlinkPosition(core.allyWell:GetPosition(), abilDig:GetRange())
	if abilDig:CanActivate() and core.unitSelf:GetHealthPercent() < .425 then
		bActionTaken = funcCastEscapeDig(botBrain, vecTarget)
		if not bActionTaken then
			bActionTaken = funcCastEscapeDig(botBrain, core.allyWell:GetPosition())
		end
		object.bRetreating=true
	end
	return bActionTaken
end

--port in direction of well
local function funcEscapePortal(botBrain)
	local bActionTaken = false
	local itemPortalkey = core.GetItem(sPortalkey)
	if itemPortalkey and itemPortalkey:CanActivate() then
		bActionTaken = core.OrderBlinkItemToEscape(botBrain, itemPortalkey, true, false)
		if not bActionTaken then
			bActionTaken = core.OrderItemPosition(botBrain, itemPortalkey, core.allyWell:GetPosition())
		object.bRetreating = true
		end
	end
	return bActionTaken
end

--override RetreatFromThreatExecute
local function funcRetreatFromThreatExecuteOverride(botBrain)
	local unitSelf = core.unitSelf
	local vecMyPos = unitSelf:GetPosition()
	local unitTarget = behaviorLib.heroTarget
	local vecPos = behaviorLib.PositionSelfBackUp()
	local nlastRetreatUtil = behaviorLib.lastRetreatUtil
	local nNow = HoN.GetGameTime()
	local abilDiguick = skills.abilSand
	
	if behaviorLib.lastRetreatUtil> object.nRetreatDigThreshold and funcEscapeDig(botBrain) then return true end
	if behaviorLib.lastRetreatUtil> object.nRetreatPortThreshold and funcEscapePortal(botBrain) then return true end
	
	BotEcho('RetreatUtil: '..nlastRetreatUtil)
	local tThreats = core.localUnits["EnemyHeroes"]
	if tThreats ~= nil then
		if behaviorLib.lastRetreatUtil> object.nRetreatFrostfieldThreshold and core.itemFrostfield and core.itemFrostfield:CanActivate() then
			local nFrostTriggerRadiusSq = 400*400
			for key,hero in pairs(tThreats) do
				local heroPos  = hero:GetPosition()
				local nTargetDistanceSq = Vector3.Distance2DSq(vecMyPos, heroPos)
				if nTargetDistanceSq < nFrostTriggerRadiusSq then
					bRetreating = true
					core.OrderItemClamp(botBrain, unitSelf, core.itemFrostfield)
					return true
				end
			end
		end
		if behaviorLib.lastRetreatUtil> object.nRetreatQuicksandThreshold and abilDiguick:CanActivate() then
			local nRange = abilDiguick:GetRange()
			for key,hero in pairs(tThreats) do
				local heroPos = hero:GetPosition()
				local nTargetDistanceSq = Vector3.Distance2DSq(vecMyPos, heroPos)
				if nTargetDistanceSq < (nRange*nRange) then
				bRetreating = true
					core.OrderAbilityPosition(botBrain, abilDiguick, heroPos)
					return true
				end
			  end
		end
		if behaviorLib.lastRetreatUtil> object.nRetreatSheepThreshold and core.itemSheepstick and core.itemSheepstick:CanActivate() then
			local nRangeSq = core.itemSheepstick:GetRange()
			for key, hero in pairs(tThreats) do
				local heroPos = hero:GetPosition()
				local nTargetDistanceSq = Vector3.Distance2DSq(vecMyPos, heroPos)
				if nTargetDistanceSq < nRangeSq then
					bRetreating = true
					core.OrderItemEntityClamp(botBrain, unitSelf, itemSheepstick, hero)
					return true
				end
			end
		end
	end
	return core.OrderMoveToPosClamp(botBrain, core.unitSelf, vecPos, false)
end

object.RetreatFromThreatExecuteOld = behaviorLib.RetreatFromThreatExecute
behaviorLib.RetreatFromThreatBehavior["Execute"] = funcRetreatFromThreatExecuteOverride

------------------------------------------------
--				Chat Overrides                --
------------------------------------------------
object.killMessages = {}
object.killMessages.General = {
    "I need your love, I need your time!",
    "Make my Millenium",
    "You didn't see that one coming, did you?",
    "Feels good.",
    "Tired already?",
    "No diggedy, no doubt."
    }
  
local function ProcessKillChatOverride(unitTarget, sTargetPlayerName)
    local nCurrentTime = HoN.GetGameTime()
    if nCurrentTime < core.nNextChatEventTime then
        return
    end  
      
    local nToSpamOrNotToSpam = random(0,1)
    BotEcho(core.nKillChatChance)
    if(nToSpamOrNotToSpam < core.nKillChatChance) then
        local nDelay = random(core.nChatDelayMin, core.nChatDelayMax)
        local nMessage = random(#object.killMessages.General)
        core.AllChat(format(object.killMessages.General[nMessage], sTargetPlayerName), nDelay)
    end
      
    core.nNextChatEventTime = nCurrentTime + core.nChatEventInterval
end
core.ProcessKillChat = ProcessKillChatOverride 

object.respawnMessages = {}
object.respawnMessages.General = {
    "Here I go again!",
    "Selfdestruct aborted.",
    "Keep calm and continue playing!",
    "When life gives you lemons, make life take the lemons back",
    "Aaah, the feeling of solid ground under my feet...",
    "Why did i turn into a bug? D:"
    }
  
local function ProcessRespawnChatOverride(unitTarget, sTargetPlayerName)
    local nCurrentTime = HoN.GetGameTime()
    if nCurrentTime < core.nNextChatEventTime then
        return
    end  
      
    local nToSpamOrNotToSpam = random(0,100)/100
    BotEcho(core.nRespawnChatChance)
    if(nToSpamOrNotToSpam < core.nRespawnChatChance) then
        local nDelay = random(core.nChatDelayMin, core.nChatDelayMax)
        local nMessage = random(#object.respawnMessages.General)
        core.AllChat(format(object.respawnMessages.General[nMessage], sTargetPlayerName), nDelay)
    end
      
    core.nNextChatEventTime = nCurrentTime + core.nChatEventInterval
end
core.ProcessRespawnChat = ProcessRespawnChatOverride 

object.deathMessages = {}
object.deathMessages.General = {
    "Oh.. I think my dev missed a semicolon there.",
    "Happens.",
    "I kinda.. stumbled over my own feet.",
    "Oh sh** my cat is on fire!",
    "Oh.. how very kafkaesque.."
    }
  
local function ProcessDeathChatOverride(unitTarget, sTargetPlayerName)
    local nCurrentTime = HoN.GetGameTime()
    if nCurrentTime < core.nNextChatEventTime then
        return
    end  
      
    local nToSpamOrNotToSpam = random(0,100)/100
    BotEcho(core.nDeathChatChance)
    if(nToSpamOrNotToSpam < core.nDeathChatChance) then
        local nDelay = random(core.nChatDelayMin, core.nChatDelayMax)
        local nMessage = random(#object.deathMessages.General)
        core.AllChat(format(object.deathMessages.General[nMessage], sTargetPlayerName), nDelay)
    end
      
    core.nNextChatEventTime = nCurrentTime + core.nChatEventInterval
end
core.ProcessDeathChat = ProcessDeathChatOverride 

BotEcho ('success')