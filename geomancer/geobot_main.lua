-- _____            _           _   
-- |  __ \          | |         | |  
-- | |  \/ ___  ___ | |__   ___ | |_ 
-- | | __ / _ \/ _ \| '_ \ / _ \| __|
-- | |_\ \  __/ (_) | |_) | (_) | |_ 
-- \____/\___|\___/|_.__/ \___/ \__|

-- GEOBOT v0.7
-- This bot contains some basic geomancer logic and will be extended
-- also he is awesome and epic
--

--############################################################################
--############################################################################
--############################################################################
--####											  ####
--####							ToDo				  ####
--####											  ####
--############################################################################
--############################################################################
--####											  ####
--####		1. Add Stun Dynamics to cancel stun properly		  ####
--####		2. Add Stun Retreat logic			(Done!)	  ####
--####		2.5 Add Sand Retreat logic 			(Done!)	  ####
--####		3. Add PortalKey Retreat logic		(Done!)	  ####
--####		4. Add PortalKey Aggression logic		(Done!)	  ####
--#### 		5. Add FrostfieldPlate Aggression logic	(Done!)	  ####
--####		6. Add FrostfieldPlate Retreat logic	(Done!)	  ####
--####		7. Add Earths Grasp pushing logic				  ####
--####		8. Add Sheepstick Aggression Logic 		(Done!)	  ####
--#### 		9. Add Sheepstick Retreat logic		(Done!)	  ####
--####		10. Add Stun Prediction				(Done!)	  ####
--####		11. Change Shopping Behaviour for Situational Items	  ####
--####		12. Implement ManaRing usage 			(Done!)	  ####
--####		13. Implement dyn-harass-util for self HP/Mana	(Done!) ####
--####		14. Implement dyn-harass-util for enemy HP/Mana		  ####
--####											  ####
--############################################################################


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

object.bRunLogic         = true
object.bRunBehaviors    = true
object.bUpdates         = true
object.bUseShop         = true

object.bRunCommands     = true 
object.bMoveCommands     = true
object.bAttackCommands     = true
object.bAbilityCommands = true
object.bOtherCommands     = true

object.bReportBehavior = false
object.bDebugUtility = false

object.logger = {}
object.logger.bWriteLog = false
object.logger.bVerboseLog = false

object.core         = {}
object.eventsLib     = {}
object.metadata     = {}
object.behaviorLib     = {}
object.skills         = {}

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




--####################################################################
--####################################################################
--#                                                                 ##
--#                  bot constant definitions                       ##
--#                                                                 ##
--####################################################################
--####################################################################

-- hero_<hero>  to reference the internal hon name of a hero, Hero_Yogi ==wildsoul
object.heroName = 'Hero_Geomancer'


--   item buy order. internal names  
behaviorLib.StartingItems  = {"Item_MarkOfTheNovice", "Item_MinorTotem", "Item_MinorTotem", "Item_RunesOfTheBlight", "Item_ManaPotion", "Item_HealthPotion"}
behaviorLib.LaneItems  = {"Item_ManaBattery", "Item_Steamboots", "Item_Replenish", "Item_PowerSupply"}
behaviorLib.MidItems  = {"Item_PortalKey", "Item_FrostfieldPlate"}
behaviorLib.LateItems  = {"Item_Morph", "Item_GrimoireOfPower"}


-- skillbuild table, 0=q, 1=w, 2=e, 3=r, 4=attri
object.tSkills = {
    0, 2, 2, 1, 2,
    3, 2, 0, 0, 0, 
    3, 1, 1, 1, 4,
    3, 4, 4, 4, 4,
    4, 4, 4, 4, 4,
}

behaviorLib.nCreepPushbackMul = 0.6 --default: 1
behaviorLib.nTargetPositioningMul = 0.7 --default: 1

-- bonus aggression points if a skill/item is available for use
object.nDigUp = 27
object.nSandUp = 23
object.nGraspUp = 5
object.nCrystalUp = 10
object.nPortalkeyUp = 15
object.nFrostfieldUp = 8
object.nSheepstickUp = 7

-- bonus aggression points that are applied to the bot upon successfully using a skill/item
object.nDigUse = 47
object.nSandUse = 38
object.nGraspUse = 0
object.nCrystalUse = 30
object.nPortalkeyUse = 0
object.nFrostfieldUse = 18
object.nSheepstickUse = 17

--thresholds of aggression the bot must reach to use these abilities
object.nDigThreshold = 51
object.nSandThreshold = 35
object.nGraspThreshold = 6
object.nCrystalThreshold = 58
object.nDigWithPortalkeyThreshold = 30
object.nFrostfieldThreshold = 50
object.nSheepstickThreshold = 40

object.nSlowedAggressionBonus = 10  -- only applicable for dig
object.nRootedAggressionBonus = 15  -- only applicable for crystal


-- thresholds for retreating
object.nRetreatQuicksandThreshold = 95
object.nRetreatDigThreshold = 97
object.nRetreatPortThreshold = 95
object.nRetreatFrostfieldThreshold = 95
object.nRetreatSheepThreshold = 95

object.nOldRetreatFactor = 0.9
object.nMaxLevelDifference = 4
object.nEnemyBaseThreat = 6

--values used for correct placement and casting of skills
object.vecStunTargetPos = nil
object.nDigTime = 0
object.bStunned = false
object.nTimeNeededForDistance = 0
object.nDigStunRadius = 250
object.nDigStunRadiusSq = object.nDigStunRadius*object.nDigStunRadius
object.nGraspRadius = 180
object.nQuicksandRadius = 	250
object.nRetreatDigTime = 0
object.bRetreating = false



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
local function PredictNextPosition(botBrain, unitTarget, vecTarget, radius) 
	if unitTarget.blsMemoryUnit then
		if unitTarget.storedPosition and unitTarget.lastStoredPosition then
			local vecLastDirection = Vector3.Normalize(unitTarget.storedPosition - unitTarget.lastStoredPosition)
			 return vecTarget + vecLastDirection*radius
		end
	end
	return vecTarget
end


-- function to control digging
local function castDig(botBrain, abilDig, vecTargetPosition, unitTarget)
	
	local bActionTaken = false
	
	BotEcho(object.nTimeNeededForDistance)
	BotEcho(format("Tiem since cast: %d", HoN.GetGameTime()-object.nDigTime))
	if HoN.GetGameTime()-object.nDigTime > object.nTimeNeededForDistance or Vector3.Distance2DSq(unitTarget:GetPosition(), core.unitSelf:GetPosition()) < object.nDigStunRadiusSq then
		BotEcho("Inside")
		if object.bStunned == true then
			BotEcho("Stunning")
			bActionTaken = core.OrderAbility(botBrain, abilDig)
			object.bStunned = false
		else
			BotEcho("Casting Stun")
			object.bRetreating = false
			bActionTaken = core.OrderAbilityPosition(botBrain, abilDig, vecTargetPosition)
			object.nDigTime = HoN.GetGameTime()
			vecStunTargetPos = Vector3.Create(vecTargetPosition.x, vecTargetPosition.y, vecTargetPosition.z)
			vecStunTargetPos = PredictNextPosition(botBrain, unitTarget, vecStunTargetPos,  object.nDigStunRadius) 
			object.nTimeNeededForDistance = (Vector3.Distance(vecStunTargetPos, core.unitSelf:GetPosition())/700)*1000
			object.bStunned = true
		end
	end
	
	return bActionTaken
end



--####################################################################
--####################################################################
--#                                                                 ##
--#   bot function overrides                                        ##
--#                                                                 ##
--####################################################################
--####################################################################



------------------------------
--     skills               --
------------------------------
-- @param: none
-- @return: none
function object:SkillBuild()
    core.VerboseLog("skillbuild()")

-- takes care at load/reload, <name_#> to be replaced by some convenient name.
    local unitSelf = self.core.unitSelf
    if  skills.abilQ == nil then
        skills.abilQ = unitSelf:GetAbility(0)
        skills.abilW = unitSelf:GetAbility(1)
        skills.abilE = unitSelf:GetAbility(2)
        skills.abilR = unitSelf:GetAbility(3)
        skills.abilAttributeBoost = unitSelf:GetAbility(4)
    end
    if unitSelf:GetAbilityPointsAvailable() <= 0 then
        return
    end
    
   
    local nlev = unitSelf:GetLevel()
    local nlevpts = unitSelf:GetAbilityPointsAvailable()
    for i = nlev, nlev+nlevpts do
        unitSelf:GetAbility( object.tSkills[i] ):LevelUp()
    end
end




------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function object:onthinkOverride(tGameVariables)
    self:onthinkOld(tGameVariables)
    -- custom code here
end
object.onthinkOld = object.onthink
object.onthink 	= object.onthinkOverride




----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function object:oncombateventOverride(EventData)
	self:oncombateventOld(EventData)
 
    local nAddBonus = 0
    if EventData.Type == "Ability" then
        if EventData.InflictorName == "Ability_Geomancer1" and not object.bRetreating then
            nAddBonus = nAddBonus + object.nDigUse
        elseif EventData.InflictorName == "Ability_Germancer2" then
            nAddBonus = nAddBonus + object.nSandUse
		elseif EventData.InflictorName == "Ability_Germancer3" then
            nAddBonus = nAddBonus + object.nGraspUse
        elseif EventData.InflictorName == "Ability_Geomancer4" then
            nAddBonus = nAddBonus + object.nCrystalUse
        end
    elseif EventData.Type == "Item" then
        if core.itemSheepstick ~= nil and EventData.SourceUnit == core.unitSelf:GetUniqueID() and EventData.InflictorName == core.itemSheepstick:GetName() then
            nAddBonus = nAddBonus + self.nSheepstickUse
        elseif core.itemFrostfield ~= nil and EventData.SourceUnit == core.unitSelf:GetUniqueID() and EventData.InflictorName == core.itemFrostfield:GetName() then
            nAddBonus = nAddBonus + self.nFrostfieldUse
        elseif core.itemPortalkey ~= nil and EventData.SourceUnit == core.unitSelf:GetUniqueID() and EventData.InflictorName == core.itemPortalkey:GetName() then
            nAddBonus = nAddBonus + self.nPortalkeyUse
        end
    end
 
   if nAddBonus > 0 then
        core.DecayBonus(self)
        core.nHarassBonus = core.nHarassBonus + nAddBonus
    end
end
-- override combat event trigger function.
object.oncombateventOld = object.oncombatevent
object.oncombatevent     = object.oncombateventOverride




------------------------------------------------------
-- FindItems Override
------------------------------------------------------
local function funcFindItemsOverride(botBrain)
	local bUpdated = object.FindItemsOld(botBrain)
	
	if core.itemSheepstick ~= nil and not core.itemSheepstick:IsValid() then
		core.itemSheepStick = nil
	end
	
	if core.itemFrostfield ~= nil and not core.itemFrostfield:IsValid() then
		core.itemFrostfield = nil
	end
	
	if core.itemPortalkey ~= nil and not core.itemPortalkey:IsValid() then
		core.itemPortalkey = nil
	end
	
	if core.itemReplenish ~= nil and not core.itemReplenish:IsValid() then
		core.itemReplenish = nil
	end
	
	if core.itemManabattery ~= nil and not core.itemManabattery:IsValid() then
		core.itemManabattery = nil
	end
	
	if core.itemPowersupply ~= nil and not core.itemPowersupply:IsValid() then
		core.itemPowersupply = nil
	end
	
	if bUpdated then
		if core.itemSheepstick and core.itemFrostfield and core.itemPortalkey and core.itemReplenish and core.itemManabattery and core.itemPowersupply then
			return
		end
		local inventory = core.unitSelf:GetInventory(true)
		for slot = 1, 12, 1 do
			local curItem = inventory[slot]
			if curItem then
				if core.itemSheepstick == nil and curItem:GetName() == "Item_Morph" then
					core.VerboseLog("Sheep")
					core.itemSheepstick = core.WrapInTable(curItem)
				elseif core.itemFrostfield == nil and curItem:GetName() == "Item_FrostfieldPlate" then
					core.VerboseLog("Frostfield")
					core.itemFrostfield = core.WrapInTable(curItem)
				elseif core.itemPortalkey == nil  and curItem:GetName() == "Item_PortalKey" then
					core.VerboseLog("PortalKey")
					core.itemPortalkey = core.WrapInTable(curItem)
				elseif core.itemReplenish == nil and curItem:GetName() == "Item_Replenish" then
					core.VerboseLog("Replenish")
					core.itemReplenish = core.WrapInTable(curItem)
				elseif core.itemManabattery == nil and curItem:GetName() == "Item_ManaBattery" then
					core.VerboseLog("ManaBattery")
					core.itemManabattery = core.WrapInTable(curItem)
				elseif core.itemPowersupply == nil and curItem:GetName() == "Item_PowerSupply" then
					core.VerboseLog("PowerSupply")
					core.itemPowersupply = core.WrapInTable(curItem)
				end
			end
		end
	end
end
object.FindItemsOld = core.FindItems
core.FindItems = funcFindItemsOverride




------------------------------------------------------
--            customharassutility override          --
-- change utility according to usable spells here   --
------------------------------------------------------
-- @param: iunitentity hero
-- @return: number
local function CustomHarassUtilityFnOverride(hero)
    local nUtil = 0
	local nTotalMana = 0
     
    if skills.abilQ:CanActivate() then
        nUtil = nUtil + object.nDigUp
		nTotalMana = skills.abilQ:GetManaCost()
    end
 
    if skills.abilW:CanActivate() then
        nUtil = nUtil + object.nSandUp
		nTotalMana = nTotalMana + skills.abilW:GetManaCost()
    end
	
	if skills.abilE:CanActivate() then
		if skills.abilW:GetLevel() == 0 then
			nUtil = nUtil + object.nSandUp - 10
		end
		nUtil = nUtil + object.nGraspUp
		nTotalMana = nTotalMana + skills.abilE:GetManaCost()
	end
	
    if skills.abilR:CanActivate() then
        nUtil = nUtil + object.nCrystalUp
		nTotalMana = nTotalMana + skills.abilR:GetManaCost()
    end
 
    if object.itemSheepstick and object.itemSheepstick:CanActivate() then
        nUtil = nUtil + object.nSheepstickUp
		nTotalMana = nTotalMana + object.itemSheepstick:GetManaCost()
    end
	
	if object.itemPortalkey and object.itemPortalkey:CanActivate() then 
		nUtil = nUtil + object.nPortalkeyUp
		nTotalMana = nTotalMana + object.itemPortalkey:GetManaCost()
	end
	
	if object.itemFrostfield and object.itemFrostfield:CanActivate() then
		nUtil = nUtil + object.nFrostfieldUp
		nTotalMana = nTotalMana + object.itemFrostfield:GetManaCost()
	end
	
	local unitSelf = core.unitSelf
	local nUtilMul = 0
	
	nUtilMul = unitSelf:GetMana() / nTotalMana
	
	if nUtilMul > 1 then
		nUtilMul = 1
	end
	
	if not (unitSelf:GetHealthPercent() > 0.7) then
		nUtilMul = nUtilMul * ( ( unitSelf:GetHealthPercent() ) + 0.3 )
	end
	
    return nUtil * nUtilMul
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
	local nMinManaLeft = 0
	
	local unitSelf = core.unitSelf
	local abilDig = skills.abilQ
	local abilGrasp = skills.abilE
	local abilSand = skills.abilW
	local abilCrystal = skills.abilR
	
	local vecMyPosition = unitSelf:GetPosition()

	if not abilDig:GetLevel() == 0 then
		nMinManaLeft = nMinManaLeft + abilDig:GetManaCost()
	end
	if abilDig:CanActivate() then
		nMinManaLeft = nMinManaLeft + abilDig:GetManaCost()
	end
	if abilSand:CanActivate() then
		nMinManaLeft = nMinManaLeft + abilSand:GetManaCost()
	end
	if abilCrystal:CanActivate() then
		nMinManaLeft = nMinManaLeft + abilCrystal:GetManaCost()
	end
	
	if abilGrasp:CanActivate() and ( unitSelf:GetMana() - abilGrasp:GetManaCost() ) > nMinManaLeft then
		unitBestGraspTarget = funcBestTargetAOE(core.localUnits["EnemyCreeps"], object.nGraspRadius)
		if unitBestGraspTarget ~= nil then
			local nTargetDistanceSq = Vector3.Distance2DSq( vecMyPosition, unitBestGraspTarget:GetPosition() )
			local nRange = abilGrasp:GetRange()
			if nTargetDistanceSq < (nRange * nRange) then
				bActionTaken = core.OrderAbilityEntity(botBrain, abilGrasp, unitBestGraspTarget)
			end
		end
	end
	if not bActionTaken and abilDig:CanActivate() and ( unitSelf:GetMana() - abilDig:GetManaCost() ) > nMinManaLeft then
		unitBestDigTarget = funcBestTargetAOE(core.localUnits["EnemyCreeps"], object.nDigStunRadius)
		if unitBestDigTarget ~= nil then
			local nTargetDistanceSq = Vector3.Distance2DSq( vecMyPosition, unitBestDigTarget:GetPosition() )
			local nRange = abilDig:GetRange()
			if nTargetDistanceSq < (nRange * nRange) then
				bActionTaken = castDig(botBrain, abilDig, unitBestDigTarget:GetPosition(), unitBestDigTarget)
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



--------------------------------------------------------------
--					   ManaBatteryBehaviour		   			--
--  A behaviour to use the heal/mana items             		--
--------------------------------------------------------------

local function ManaBatteryUseUtility(botBrain)
	local unitSelf = core.unitSelf
	local nManaPercent = unitSelf:GetManaPercent()
	local nHealthPercent = unitSelf:GetHealthPercent()
	local nHealthMissing = unitSelf:GetMaxHealth() - unitSelf:GetHealth()
	local nManaMissing = unitSelf:GetMaxMana() - unitSelf:GetMana()
	local nCharges = 0
	local bCritical = (nManaPercent < 0.2) or (nHealthPercent < 0.2)
	local nUtility = 0
	if core.itemManabattery and core.itemManabattery:CanActivate()  then
		nCharges = core.itemManabattery:GetCharges()
	end
	if core.itemPowersupply and  core.itemPowersupply:CanActivate() then
		nCharges = core.itemPowersupply:GetCharges()
	end
	if core.itemManabattery and core.itemManabattery:CanActivate() and bCritical and nCharges > 3 then
		nUtility = 100
	elseif  core.itemPowersupply and  core.itemPowersupply:CanActivate() and bCritical and nCharges > 5 then
		nUtility = 100
	elseif (core.itemPowersupply and core.itemManabattery) and  (core.itemManabattery:CanActivate() and  core.itemPowersupply:CanActivate())  and (nHealthMissing > 10*nCharges and nManaMissing > 15*nCharges) then
		nUtility = 100
	end
	--BotEcho(nUtility)
	return nUtility
end

local function ManaBatteryUseExecute(botBrain)
	if core.itemPowersupply and core.itemPowersupply:CanActivate() then 
		core.OrderItemClamp(botBrain, unitSelf, core.itemPowersupply, true)
	elseif core.itemManabattery and core.itemManabattery:CanActivate() then
		core.OrderItemClamp(botBrain, unitSelf, core.itemManabattery, true)
	end
end

behaviorLib.ManaBatteryUseBehavior = {}
behaviorLib.ManaBatteryUseBehavior["Utility"] = ManaBatteryUseUtility
behaviorLib.ManaBatteryUseBehavior["Execute"] = ManaBatteryUseExecute
behaviorLib.ManaBatteryUseBehavior["Name"] = "ManaBatteryUse"
tinsert(behaviorLib.tBehaviors, behaviorLib.ManaBatteryUseBehavior)

---------------------------------------------------------------------------
--   return to fountain if g > *
--   kudos to naib
---------------------------------------------------------------------------
-- Util
object.purseMax = 6000
object.purseMin = 3000
function behaviorLib.bigPurseUtility(botBrain)
    local bDebugEchos = false
     
    local Clamp = core.Clamp
    local m = (100/(object.purseMax - object.purseMin))
    nUtil = m*botBrain:GetGold() - m*object.purseMin
    nUtil = Clamp(nUtil,0,100)
 
    if bDebugEchos then BotEcho(format("Bot return Priority: [%s%s]",string.rep('#',nUtil/10),string.rep('_',10 -nUtil/10))) end
 
    return nUtil
end
 
-- Execute
function behaviorLib.bigPurseExecute(botBrain)
    local unitSelf = core.unitSelf
 
    local wellPos = core.allyWell and core.allyWell:GetPosition() or behaviorLib.PositionSelfBackUp()
    core.OrderMoveToPosAndHoldClamp(botBrain, unitSelf, wellPos, false)
end  
behaviorLib.bigPurseBehavior = {}
behaviorLib.bigPurseBehavior["Utility"] = behaviorLib.bigPurseUtility
behaviorLib.bigPurseBehavior["Execute"] = behaviorLib.bigPurseExecute
behaviorLib.bigPurseBehavior["Name"] = "bigPurse"
tinsert(behaviorLib.tBehaviors, behaviorLib.bigPurseBehavior)


--------------------------------------------------------------
--                    Harass Behavior                       --
-- All code how to use abilities against enemies goes here  --
--------------------------------------------------------------
-- @param botBrain: CBotBrain
-- @return: none
--
local function HarassHeroExecuteOverride(botBrain)
    
    local unitTarget = behaviorLib.heroTarget
    if unitTarget == nil then
        return object.harassExecuteOld(botBrain) --Target is invalid, move on to the next behavior
    end
    
    
    local unitSelf = core.unitSelf
    local vecMyPosition = unitSelf:GetPosition() 
    local nAttackRange = core.GetAbsoluteAttackRangeToUnit(unitSelf, unitTarget)
    local nMyExtraRange = core.GetExtraRange(unitSelf)
    
    local vecTargetPosition = unitTarget:GetPosition()
    local nTargetExtraRange = core.GetExtraRange(unitTarget)
    local nTargetDistanceSq = Vector3.Distance2DSq(vecMyPosition, vecTargetPosition)

    local nLastHarassUtility = behaviorLib.lastHarassUtil
    local bCanSee = core.CanSeeUnit(botBrain, unitTarget)    
    local bActionTaken = false
    if core.CanSeeUnit(botBrain, unitTarget) then
		local bTargetVuln = unitTarget:IsStunned() or unitTarget:IsImmobilized() or unitTarget:IsPerplexed()
		local bTargetSlowed = unitTarget:GetMoveSpeed() < 200
		local bTargetRooted = bTargetVuln or bTargetSlowed
		local abilDig = skills.abilQ
		local abilGrasp = skills.abilE
		local abilSand = skills.abilW
		local abilCrystal = skills.abilR
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
						vecPortalkeyTargetPosition = funcBestTargetAOE(core.localUnits["EnemyHeroes"], object.nDigStunRadius):GetPosition()
						object.bRetreating = false
						core.OrderAbilityPosition(botBrain, abilDig, vecTargetPosition)
						bActionTaken = core.OrderItemPosition(botBrain, unitSelf, core.itemPortalkey, vecPortalkeyTargetPosition)
					end
				elseif nTargetDistanceSq < nRangeSq then
					bActionTaken = castDig(botBrain, abilDig, vecTargetPosition, unitTarget)
				end
			elseif bTargetSlowed and not bTargetVuln then
				if (nLastHarassUtility + object.nSlowedAggressionBonus) > botBrain.nDigThreshold then 
					if nTargetDistanceSq < nRangeSq then
						bActionTaken = castDig(botBrain, abilDig, vecTargetPosition, unitTarget)
					end
				end
			end
		end
		
		if not bActionTaken and abilSand:CanActivate() then
			if not bTargetSlowed and nLastHarassUtility > botBrain.nSandThreshold then
				local nRange = abilSand:GetRange()
				
				if nTargetDistanceSq < (nRange * nRange) then
					BotEcho("Casting Sand")
					bActionTaken = core.OrderAbilityPosition(botBrain, abilSand, PredictNextPosition(botBrain, unitTarget, vecTargetPosition,  object.nQuicksandRadius) )
				end
			end
		end
		
		if not bActionTaken and abilGrasp:CanActivate() then
			if nLastHarassUtility > botBrain.nGraspThreshold then
				
				local nRange = abilGrasp:GetRange()
				local nMinManaLeft = 0
				
				if not abilDig:GetLevel() == 0 then
					nMinManaLeft = nMinManaLeft + abilDig:GetManaCost()
				end
				if abilSand:CanActivate() then
					nMinManaLeft = nMinManaLeft + abilSand:GetManaCost()
				end
				
				if (unitSelf:GetMana() - abilGrasp:GetManaCost() ) > nMinManaLeft and nTargetDistanceSq < (nRange*nRange) then
					BotEcho("Grasping")
					bActionTaken = core.OrderAbilityEntity(botBrain, abilGrasp, unitTarget)
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
    --- Insert abilities code here, set bActionTaken to true 
    --- if an ability command has been given successfully
    
    
    if not bActionTaken then
        return object.harassExecuteOld(botBrain)
    end 
end
-- overload the behaviour stock function with custom 
object.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride


--local function RetreatExecuteOverride(botBrain)
--	local bActionTaken = false
--	local unitSelf = core.unitSelf
--	local abilDig = skills.abilQ
--	local abilQuick = skills.abilW
--		local tThreats = core.localUnits["EnemyHeroes"]
--	if not bActionTaken then
--		if behaviorLib.lastRetreatUtil >= object.nRetreatQuicksandThreshold  and abilQuick:
--			CanActivate() then
--			BotEcho("Casting Retreat Slow")
--			local vecMyPos = unitSelf:GetPosition()
--			local nRange = abilQuick:GetRange()
--			for key,hero in pairs(tThreats) do
--				local heroPos = hero:GetPosition()
--				local nTargetDistanceSq = Vector3.Distance2DSq(vecMyPos, heroPos)
--				if nTargetDistanceSq < (nRange*nRange) then
--					bActionTaken = core.OrderAbilityPosition(botBrain, abilQuick, heroPos)
--				end
--		   end
--		end
	--	if behaviorLib.lastRetreatUtil >= object.nRetreatDigThreshold and abilDig:CanActivate() then
	--		if HoN.GetGameTime()-object.nRetreatDigTime > 2000 then
	--			BotEcho("Casting Retreat Dig")
	--			local vecMyPos = unitSelf:GetPosition()
	--			local wellPos = core.allyWell and core.allyWell:GetPosition() 
	--			local targetPos = vecMyPos + Vector3.Create(wellPos.x/abs(wellPos.x), wellPos.y/abs(wellPos.y), wellPos.z)
	--			BotEcho(format("My Pos: %d-%d | Taret Pos: %d-%d", vecMyPos.x, vecMyPos.y, targetPos.x, targetPos.y))
	--			bActionTaken = core.OrderAbilityPosition(botBrain, abilDig, targetPos)
	--			object.nRetreatDigTime = HoN.GetGameTime()
	--		end
	--	end
--	end
--		if not bActionTaken then
--			return object.RetreatFromThreatExecuteOld(botBrain)
--		end
--end
--object.RetreatFromThreatExecuteOld = behaviorLib.RetreatFromThreatExecute
--behaviorLib.RetreatFromThreatBehavior["Execute"] = RetreatExecuteOverride

local function ManaRingAlwaysUtility(botBrain) 
	if(core.itemReplenish and core.itemReplenish:CanActivate() and core.unitSelf:GetMana()<(core.unitSelf:GetMaxMana()-135))  then
		return 100
	end
	return 0
end

local function ManaRingAlwaysExecute(botBrain)
		core.OrderItemClamp(botBrain, unitSelf, core.itemReplenish, true)
end
behaviorLib.ManaRingAlwaysBehavior = {}
behaviorLib.ManaRingAlwaysBehavior["Utility"] = ManaRingAlwaysUtility
behaviorLib.ManaRingAlwaysBehavior["Execute"] = ManaRingAlwaysExecute
behaviorLib.ManaRingAlwaysBehavior["Name"] = "ManaRingAlways"
tinsert(behaviorLib.tBehaviors, behaviorLib.ManaRingAlwaysBehavior)

--------------------------------------------------
-- RetreatFromThreat Override --
--------------------------------------------------
--pretty much copypasta from 
--DarkFire
--Kairus101
--VHD
--kudos to those geniuses

--This function returns the position of the enemy hero.
--If he is not shown on map it returns the last visible spot
--as long as it is not older than 10s
local function funcGetEnemyPosition(unitEnemy)
	if unitEnemy == nil then return Vector3.Create(20000, 20000) end
	local tEnemyPosition = core.unitSelf.tEnemyPosition
	local tEnemyPositionTimestamp = core.unitSelf.tEnemyPositionTimestamp
	if tEnemyPosition == nil then
		-- initialize new table
		core.unitSelf.tEnemyPosition = {}
		core.unitSelf.tEnemyPositionTimestamp = {}
		tEnemyPosition = core.unitSelf.tEnemyPosition
		tEnemyPositionTimestamp = core.unitSelf.tEnemyPositionTimestamp
		local tEnemyTeam = HoN.GetHeroes(core.enemyTeam)
		--vector beyond map
		for x, hero in pairs(tEnemyTeam) do
			tEnemyPosition[hero:GetUniqueID()] = Vector3.Create(20000, 20000)
			tEnemyPositionTimestamp[hero:GetUniqueID()] = HoN.GetGameTime()
		end
	end
	local vecPosition = unitEnemy:GetPosition()
	--enemy visible?
	if vecPosition then
		--update table
		tEnemyPosition[unitEnemy:GetUniqueID()] = unitEnemy:GetPosition()
		tEnemyPositionTimestamp[unitEnemy:GetUniqueID()] = HoN.GetGameTime()
	end
	--return position, 10s memory
	if tEnemyPositionTimestamp[unitEnemy:GetUniqueID()] <= HoN.GetGameTime() + 10000 then
		return tEnemyPosition[unitEnemy:GetUniqueID()]
	else
		return Vector3.Create(20000, 20000)
	end
end

local function funcGetThreatOfEnemy(unitEnemy)
	if unitEnemy == nil or not unitEnemy:IsAlive() then return 0 end
	local unitSelf = core.unitSelf
	local nDistanceSq = Vector3.Distance2DSq(unitSelf:GetPosition(), funcGetEnemyPosition (unitEnemy))
	if nDistanceSq > 4000000 then return 0 end	
	local nMyLevel = unitSelf:GetLevel()
	local nEnemyLevel = unitEnemy:GetLevel()
	--Level differences increase / decrease actual nThreat
	local nThreat = object.nEnemyBaseThreat + Clamp(nEnemyLevel - nMyLevel, 0, object.nMaxLevelDifference)
	nThreat = Clamp(3*(112810000-nDistanceSq) / (4*(19*nDistanceSq+32810000)),0.75,2) * nThreat
	return nThreat
end

local function positionOffset(pos, angle, distance) --this is used by minions to form a ring around people.
	tmp = Vector3.Create(cos(angle)*distance,sin(angle)*distance)
	return tmp+pos
end

local function EscapeDig(botBrain)
	local vecWellPos = core.allyWell and core.allyWell:GetPosition() or behaviorLib.PositionSelfBackUp()
	local abilDig = skills.abilQ
	local vecMyPos=core.unitSelf:GetPosition()
	if (Vector3.Distance2DSq(vecMyPos, vecWellPos)>600*600)then
		if (abilDig:CanActivate() and HoN.GetGameTime()-object.nRetreatDigTime > 2000) then
			object.nRetreatDigTime = HoN.GetGameTime()
			object.bRetreating = true
			return core.OrderAbilityPosition(botBrain, abilDig, positionOffset(core.unitSelf:GetPosition(), atan2(vecWellPos.y-vecMyPos.y,vecWellPos.x-vecMyPos.x), abilDig:GetRange()))
		end
	end
	return false
end


local function EscapePortal(botBrain)
	local vecWellPos = core.allyWell and core.allyWell:GetPosition() or behaviorLib.PositionSelfBackUp()
	local vecMyPos=core.unitSelf:GetPosition()
	if (Vector3.Distance2DSq(vecMyPos, vecWellPos)>600*600)then
		if core.itemPortalkey and core.itemPortalkey:CanActivate() then
			object.bRetreating = true
			return core.OrderItemPosition(botBrain, core.itemPortalkey, positionOffset(core.unitSelf:GetPosition(), atan2(vecWellPos.y-vecMyPos.y,vecWellPos.x-vecMyPos.x), core.itemPortalkey:GetRange()))
		end
	end
	return false
end

local function CustomRetreatFromThreatUtilityFnOverride(botBrain)
	local bDebugEchos = false
	local nUtilityOld = behaviorLib.lastRetreatUtil
	local nUtility = object.RetreatFromThreatUtilityOld(botBrain) * object.nOldRetreatFactor

	--decay with a maximum of 4 utilitypoints per frame to ensure a longer retreat time
	if nUtilityOld > nUtility +4 then
		nUtility = nUtilityOld -4
	end
	
	--bonus of allies decrease fear
	local allies = core.localUnits["AllyHeroes"]
	local nAllies = core.NumberElements(allies) + 1
	--get enemy heroes
	local tEnemyTeam = HoN.GetHeroes(core.enemyTeam)
	--calculate the threat-value and increase utility value
	for id, enemy in pairs(tEnemyTeam) do
		nUtility = nUtility + funcGetThreatOfEnemy(enemy) / nAllies
	end
	return Clamp(nUtility, 0, 100)
end

local function funcRetreatFromThreatExecuteOverride(botBrain)
	local unitSelf = core.unitSelf
	local unitTarget = behaviorLib.heroTarget
	local vecPos = behaviorLib.PositionSelfBackUp()
	local nlastRetreatUtil = behaviorLib.lastRetreatUtil
	local nNow = HoN.GetGameTime()
	local abilQuick = skills.abilW
	local tThreats = core.localUnits["EnemyHeroes"]
	if behaviorLib.lastRetreatUtil> object.nRetreatDigThreshold and EscapeDig(botBrain) then return true end
	if behaviorLib.lastRetreatUtil> object.nRetreatPortThreshold and EscapePortal(botBrain) then return true end
	if behaviorLib.lastRetreatUtil> object.nRetreatFrostfieldThreshold and core.itemFrostfield and core.itemFrostfield:CanActivate() then
		local nFrostTriggerRadiusSq = 400*400
		for key,hero in pairs(tThreats) do
			local heroPos  = hero:GetPosition()
			local nTargetDistanceSq = Vector3.Distance2DSq(vecMyPos, heroPos)
			if nTargetDistanceSq < nFrostTriggerRadiusSq then
				core.OrdeItem(botBrain, core.itemFrostfield)
				return true
			end
		end
	end
	if behaviorLib.lastRetreatUtil> object.nRetreatQuicksandThreshold  and abilQuick:CanActivate() then
		BotEcho("Casting Retreat Slow")
		local vecMyPos = unitSelf:GetPosition()
		local nRange = abilQuick:GetRange()
		for key,hero in pairs(tThreats) do
			local heroPos = hero:GetPosition()
			local nTargetDistanceSq = Vector3.Distance2DSq(vecMyPos, heroPos)
			if nTargetDistanceSq < (nRange*nRange) then
				core.OrderAbilityPosition(botBrain, abilQuick, heroPos)
				return true
			end
		  end
	end
	if behaviorLib.lastRetreatUtil> object.nRetreatSheepThreshold and core.itemSheepstick and core.itemSheepsstick:CanActivate() then
		local nRangeSq = core.itemSheepstick:GetRange()
		for key, hero in pairs(tThreats) do
			local heroPos = hero:GetPosition()
			local nTargetDistanceSq = Vector3.Distance2DSq(vecMyPos, heroPos)
			if nTargetDistanceSq < nRangeSq then
				core.OrderItemEntityClamp(botBrain, unitSelf, itemSheepstick, hero)
				return true
			end
		end
	end
	return core.OrderMoveToPosClamp(botBrain, core.unitSelf, vecPos, false)
end

object.RetreatFromThreatUtilityOld = behaviorLib.RetreatFromThreatUtility
behaviorLib.RetreatFromThreatBehavior["Utility"] = CustomRetreatFromThreatUtilityFnOverride
object.RetreatFromThreatExecuteOld = behaviorLib.RetreatFromThreatExecute
behaviorLib.RetreatFromThreatBehavior["Execute"] = funcRetreatFromThreatExecuteOverride

BotEcho ('success')