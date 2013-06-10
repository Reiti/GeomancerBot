-------------------------------------------------------------------
-------------------------------------------------------------------
--   ____     __               ___    ____             __        --
--  /\  _`\  /\ \             /\_ \  /\  _`\          /\ \__     --
--  \ \,\L\_\\ \ \/'\       __\//\ \ \ \ \L\ \    ___ \ \ ,_\    --
--   \/_\__ \ \ \ , <     /'__`\\ \ \ \ \  _ <'  / __`\\ \ \/    --
--     /\ \L\ \\ \ \\`\  /\  __/ \_\ \_\ \ \L\ \/\ \L\ \\ \ \_   --
--     \ `\____\\ \_\ \_\\ \____\/\____\\ \____/\ \____/ \ \__\  --
--      \/_____/ \/_/\/_/ \/____/\/____/ \/___/  \/___/   \/__/  --
-------------------------------------------------------------------
-------------------------------------------------------------------
-- based on Skelbot v0.0000009
-- -- This bot represent the BARE minimum required for HoN to spawn a bot
-- -- and contains some very basic overrides you can fill in
-- 
-- GEOBOT v0.x
-- This bot contains some basic geomancer logic and will be extended
--

--####################################################################
--####################################################################
--####################################################################
--####															  ####
--####							ToDo							  ####
--####															  ####
--####################################################################
--####################################################################
--####															  ####
--####		1. Add Stun Dynamics to cancel stun properly		  ####
--####		2. Add Stun Retreat logic (Done!)							  ####
--####		2.5 Add Sand Retreat logic (Done!)							  ####
--####		3. Add PortalKey Retreat logic						  ####
--####		4. Add PortalKey Aggression logic					  ####
--#### 		5. Add FrostfieldPlate Aggression logic				  ####
--####		6. Add FrostfieldPlate Retreat logic				  ####
--####		7. Add Earths Grasp pushing logic					  ####
--####		8. Add Sheepstick Aggression Logic					  ####
--#### 		9. Add Sheepstick Retreat logic		ssssss				  ####
--####		10. Add Stun Prediction	(Done!)							  ####
--####		11. Change Shopping Behaviour for Situational Items	  ####
--####															  ####
--####################################################################


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
behaviorLib.LaneItems  = {"Item_ManaBattery", "Item_Steamboots", "Item_Replenish"}
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
object.nDigUse = 60
object.nSandUse = 50
object.nGraspUse = 0
object.nCrystalUse = 50
object.nPortalkeyUse = 0
object.nFrostfieldUse = 30
object.nSheepstickUse = 15

--thresholds of aggression the bot must reach to use these abilities
object.nDigThreshold = 56
object.nSandThreshold = 35
object.nGraspThreshold = 6
object.nCrystalThreshold = 70
object.nDigWithPortalkeyThreshold = 30
object.nFrostfieldThreshold = 50
object.nSheepstickThreshold = 40

object.nSlowedAggressionBonus = 10  -- only applicable for dig
object.nRootedAggressionBonus = 15  -- only applicable for crystal


-- thresholds for retreating
object.nRetreatQuicksandThreshold = 60
object.nRetreatDigThreshold = 60
--values used for correct placement and casting of skills
object.vecStunTargetPos = nil
object.nDigTime = 0
object.bStunned = false
object.nTimeNeededForDistance = 0
object.nDigStunRadius = 250
object.nQuicksandRadius = 	250
object.nRetreatDigTime = 0

------------ Function for finding the center of a group (used by ult and some other places). 
------------ Kudos to Stolen_id for this
local function groupCenter(tGroup, nMinCount)
    if nMinCount == nil then nMinCount = 1 end
      
    if tGroup ~= nil then
        local vGroupCenter = Vector3.Create()
        local nGroupCount = 0
        for id, creep in pairs(tGroup) do
            vGroupCenter = vGroupCenter + creep:GetPosition()
            nGroupCount = nGroupCount + 1
        end
          
        if nGroupCount < nMinCount then
            return nil
        else
            return vGroupCenter/nGroupCount-- center vector
        end
    else
        return nil  
    end
end 


--####################################################################
--####################################################################
--#                                                                 ##
--#   bot faggot overrides                                          ##
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
        if EventData.InflictorName == "Ability_Geomancer1" then
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
		core.itemFrostField = nil
	end
	
	if core.itemPortalkey ~= nil and not core.itemPortalkey:IsValid() then
		core.itemPortalkey = nil
	end
	
	
	if bUpdated then
		if core.itemSheepstick then
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
				elseif core.itemPortalkey == nil  and curItem:GetName() == "Itemp_PortalKey" then
					core.VerboseLog("Portal")
					core.itemPortalkey = core.WrapInTable(curItem)
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
     
    if skills.abilQ:CanActivate() then
        nUtil = nUtil + object.nDigUp
    end
 
    if skills.abilW:CanActivate() then
        nUtil = nUtil + object.nSandUp
    end
	
	if skills.abilE:CanActivate() then
		nUtil = nUtil + object.nGraspUp
	end
	
    if skills.abilR:CanActivate() then
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
 
    return nUtil
end
-- assign custom harass function to the behaviourLib object
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride   


-------------------------------------------------------------
--					   Stunning Behavior		   --
--  A behavior that makes sure the bot
--  doesn't cancel it's own stun               --
-------------------------------------------------------------

local function DontBreakStunUtility(botBrain)
	local utility = 0
	if core.unitSelf:HasState("State_Geomancer_Ability1_Self") then
		utility = 1
	end
	return utility
end

local function DontBreakStunExecute(botBrain)
	--Will probably add some targeting.
end

behaviorLib.DontBreakStunBehavior = {}
behaviorLib.DontBreakStunBehavior["Utility"] = DontBreakStunUtility
behaviorLib.DontBreakStunBehavior["Execute"] = DontBreakStunExecute
behaviorLib.DontBreakStunBehavior["Name"] = "DontBreakStun"
tinsert(behaviorLib.tBehaviors, behaviorLib.DontBreakStunBehavior)



--------------------------------------------------------------
-- method to predict movement of target unit      -----
-- used for prediction in casting stun and slow ------
--------------------------------------------------------------
local function PredictNextPosition(botBrain, unitTarget, vecTarget, radius) 
	if unitTarget.blsMemoryUnit then
		if unitTarget.storedPosition and unitTarget.lastStoredPosition then
			local vecLastDirection = Vector3.Normalize(unitTarget.storedPosition - unitTarget.lastStoredPosition)
			 return vecTarget + vecLastDirection*radius
		end
	end
	return vecTarget
end
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
		
		if not bActionTaken then
			if itemSheepstick then
				local nRange = itemSheepStick:GetRange()
				if itemSheepStick:CanActivate() and not bTargetVuln and nLastHarassUtility > botBrain.nSheepstickTreshold and nTargetDistanceSq < (nRange*nRange) then
					bActionTaken = core.OrderItemEntityClamp(botBrain, unitSelf, itemSheepstick, unitTarget)
				end
			elseif abilSand:CanActivate() and not bTargetSlowed and nLastHarassUtility > botBrain.nSandThreshold then
				local nRange = abilSand:GetRange()
				
				if nTargetDistanceSq < (nRange * nRange) then
					BotEcho("Casting Sand")
					bActionTaken = core.OrderAbilityPosition(botBrain, abilSand, PredictNextPosition(botBrain, unitTarget, vecTargetPosition,  object.nQuicksandRadius) )
				end
			elseif abilGrasp:CanActivate() and nLastHarassUtility > botBrain.nGraspThreshold then
				local nRange = abilGrasp:GetRange()
				local nMinManaLeft = 0
				
				if not abilDig:GetLevel() == 0 then
					nMinManaLeft = nMinManaLeft + abilDig:GetManaCost()
				end
				if abilSand:CanActivate() then
					nMinManaLeft = nMinManaLeft + abilSand:GetManaCost()
				end
				
				if (unitSelf:GetMana() - abilGrasp:GetManaCost() ) > nMinManaLeft and nTargetDistanceSq < (nRange*nRange) then
					bActionTaken = core.OrderAbilityEntity(botBrain, abilGrasp, unitTarget)
				end
			elseif abilDig:CanActivate() then
				local nRange = abilDig:GetRange()
				local nRangeSq = nRange*nRange
				if bTargetSlowed and not bTargetVuln then
					if (nLastHarassUtility + object.nSlowedAggressionBonus) > botBrain.nDigThreshold then 
						if nTargetDistanceSq < nRangeSq then
							BotEcho(object.nTimeNeededForDistance)
							BotEcho(format("Tiem since cast: %d", HoN.GetGameTime()-object.nDigTime))
							if HoN.GetGameTime()-object.nDigTime > object.nTimeNeededForDistance then
									BotEcho("Inside")
									if object.bStunned == true then
										BotEcho("Stunning")
										bActionTaken = core.OrderAbility(botBrain, abilDig)
										object.bStunned = false
									else
										BotEcho("Casting Stun")
										bActionTaken = core.OrderAbilityPosition(botBrain, abilDig, vecTargetPosition)
										object.nDigTime = HoN.GetGameTime()
										vecStunTargetPos = Vector3.Create(vecTargetPosition.x, vecTargetPosition.y, vecTargetPosition.z)
										vecStunTargetPos = PredictNextPosition(botBrain, unitTarget, vecStunTargetPos,  object.nDigStunRadius) 
										object.nTimeNeededForDistance = (Vector3.Distance(vecStunTargetPos, core.unitSelf:GetPosition())/700)*1000
										object.bStunned = true
									end
						end
					end
				end
			 elseif nLastHarassUtility > botBrain.nDigThreshold then
					if nTargetDistanceSq < nRangeSq then
						BotEcho(object.nTimeNeededForDistance)
						BotEcho(format("Tiem since cast: %d", HoN.GetGameTime()-object.nDigTime))
						if HoN.GetGameTime()-object.nDigTime > object.nTimeNeededForDistance then
								BotEcho("Inside")
								if object.bStunned == true then
									BotEcho("Stunning")
									bActionTaken = core.OrderAbility(botBrain, abilDig)
									object.bStunned = false
								else
									BotEcho("Casting Stun")
									bActionTaken = core.OrderAbilityPosition(botBrain, abilDig, vecTargetPosition)
									object.nDigTime = HoN.GetGameTime()
									vecStunTargetPos = Vector3.Create(vecTargetPosition.x, vecTargetPosition.y, vecTargetPosition.z)
									vecStunTargetPos = PredictNextPosition(botBrain, unitTarget, vecStunTargetPos, object.nDigStunRadius) 
									object.nTimeNeededForDistance = (Vector3.Distance(vecStunTargetPos, core.unitSelf:GetPosition())/700)*1000
									object.bStunned = true
								end
						end
					end
				end
			elseif abilCrystal:CanActivate() then
				local nRange = abilCrystal:GetRange()
				local nRangeSq = nRange*nRange
				if bTargetRooted then
					if (nLastHarassUtility + object.nRootedAggressionBonus) > botBrain.nCrystalThreshold then
						if nTargetDistanceSq < nRangeSq then
							-- vecCrystalTargetPos = core.GetGroupCenter(core.localUnits["EnemyHeroes"])
							 vecCrystalTargetPosition = groupCenter(core.localUnits["EnemyHeroes"], 1)
							bActionTaken = core.OrderAbilityPosition(botBrain, abilCrystal, vecCrystalTargetPosition)
						end
					end
				elseif nLastHarassUtility > botBrain.nCrystalThreshold then
					if nTargetDistanceSq < nRangeSq then
						-- vecCrystalTargetPos = core.GetGroupCenter(core.localUnits["EnemyHeroes"])
						vecCrystalTargetPosition = groupCenter(core.localUnits["EnemyHeroes"], 1)
						bActionTaken = core.OrderAbilityPosition(botBrain, abilCrystal, vecCrystalTargetPosition)
					end
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


local function RetreatExecuteOverride(botBrain)
	local bActionTaken = false
	local unitSelf = core.unitSelf
	local abilDig = skills.abilQ
	local abilQuick = skills.abilW
	if not bActionTaken then
		local tThreats = core.localUnits["EnemyHeroes"]
		if behaviorLib.lastRetreatUtil >= object.nRetreatQuicksandThreshold  and abilQuick:CanActivate() then
			BotEcho("Casting Retreat Slow")
			local vecMyPos = unitSelf:GetPosition()
			local nRange = abilQuick:GetRange()
			for key,hero in pairs(tThreats) do
				local heroPos = hero:GetPosition()
				local nTargetDistanceSq = Vector3.Distance2DSq(vecMyPos, heroPos)
				if nTargetDistanceSq < (nRange*nRange) then
					bActionTaken = core.OrderAbilityPosition(botBrain, abilQuick, heroPos)
				end
		   end
		end
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
	end
		if not bActionTaken then
			return object.RetreatFromThreatExecuteOld(botBrain)
		end
end
object.RetreatFromThreatExecuteOld = behaviorLib.RetreatFromThreatExecute
behaviorLib.RetreatFromThreatBehavior["Execute"] = RetreatExecuteOverride

BotEcho ('success')




