-- $Id$
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--
--  Copyright (C) 2009.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if (not gadgetHandler:IsSyncedCode()) then
	return
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "UnitPriority",
    desc      = "Adds controls to change spending priority on constructions/repairs etc",
    author    = "Licho",
    date      = "19.4.2009", --24.2.2013
    license   = "GNU GPL, v2 or later",
    layer     = -2, --must start before unit_morph.lua gadget to register GG.AddMiscPriority() first
    enabled   = not (Game.version:find('91.0') == 1)
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

include("LuaRules/Configs/customcmds.h.lua")
include("LuaRules/Configs/constants.lua")

local TooltipsA = {
	' Low.',
	' Normal.',
	' High.',
}
local TooltipsB = {
	[CMD_PRIORITY] = 'Construction Priority',
	[CMD_MISC_PRIORITY] = 'Morph&Stock Priority',
}
local DefaultState = 1

local CommandOrder = 123456
local CommandDesc = {
	id          = CMD_PRIORITY,
	type        = CMDTYPE.ICON_MODE,
	name        = 'Construction Priority',
	action      = 'priority',
	tooltip 	= 'Construction Priority' .. TooltipsA[DefaultState + 1],
	params      = {DefaultState, 'Low','Normal','High'}
}

local MiscCommandOrder = 123457
local MiscCommandDesc = {
	id          = CMD_MISC_PRIORITY,
	type        = CMDTYPE.ICON_MODE,
	name        = 'Morph&Stock Priority',
	action      = 'miscpriority',
	tooltip 	= 'Morph&Stock Priority' .. TooltipsA[DefaultState + 1],
	params      = {DefaultState, 'Low','Normal','High'}
}

local StateCount = #CommandDesc.params-1

local UnitPriority = {}  --  UnitPriority[unitID] = 0,1,2     priority of the unit
local UnitMiscPriority = {}  --  UnitMiscPriority[unitID] = 0,1,2     priority of the unit
local TeamPriorityUnits = {}  -- TeamPriorityUnits[TeamID][UnitID] = 0,2    which units are low/high priority builders
local teamMiscPriorityUnits = {} -- teamMiscPriorityUnits[TeamID][UnitID] = 0,2    which units are low/high priority builders
local TeamScale = {}  -- TeamScale[TeamID]= {0.1, 0.4}   how much to scale down production of lnormal and low prirotity units
local TeamMetalReserved = {} -- how much metal is reserved for high priority in each team
local TeamEnergyReserved = {} -- ditto for energy
local LastUnitFromFactory = {} -- LastUnitFromFactory[FactoryUnitID] = lastUnitID

-- Derandomization of resource allocation. Remembers the portion of resources allocated to the unit and gives access
-- when they have a full chunk.
local UnitConPortion = {}
local UnitMiscPortion = {}

local miscMetalDrain = {} -- metal drain for custom unit added thru GG. function
local miscTeamPriorityUnits = {} --unit  that need priority handling
local miscTeamPull = {} -- miscTeamPull[TeamID] = pull      -- how much is pulling

do
	local teams = Spring.GetTeamList()
	for i=1,#teams do
		local teamID = teams[i]
		miscTeamPull[teamID] = 0
	end
end

local priorityTypes = {
	[CMD_PRIORITY] = {id = CMD_PRIORITY, param = "buildpriority", unitTable = UnitPriority},
	[CMD_MISC_PRIORITY] = {id = CMD_MISC_PRIORITY, param = "miscpriority", unitTable = UnitMiscPriority},
}

local ALLY_ACCESS = {allied = true}

local reportedError = false

--------------------------------------------------------------------------------
--  COMMON
--------------------------------------------------------------------------------


local function isFactory(UnitDefID)
  return UnitDefs[UnitDefID].isFactory or false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local max = math.max

local spGetTeamList       = Spring.GetTeamList
local spGetTeamResources  = Spring.GetTeamResources
local spGetPlayerInfo     = Spring.GetPlayerInfo
local spGetUnitDefID      = Spring.GetUnitDefID
local spGetUnitHealth     = Spring.GetUnitHealth
local spFindUnitCmdDesc   = Spring.FindUnitCmdDesc
local spEditUnitCmdDesc   = Spring.EditUnitCmdDesc
local spInsertUnitCmdDesc = Spring.InsertUnitCmdDesc
local spRemoveUnitCmdDesc = Spring.RemoveUnitCmdDesc
local spSetUnitRulesParam = Spring.SetUnitRulesParam
local spSetTeamRulesParam = Spring.SetTeamRulesParam


local function SetMetalReserved(teamID, value)
	TeamMetalReserved[teamID] = value or 0
end

local function SetEnergyReserved(teamID, value)
	TeamEnergyReserved[teamID] = value or 0
end


local function SetPriorityState(unitID, state, prioID) 
	local cmdDescID = spFindUnitCmdDesc(unitID, prioID)
	if (cmdDescID) then
		CommandDesc.params[1] = state
		spEditUnitCmdDesc(unitID, cmdDescID, { params = CommandDesc.params, tooltip = TooltipsB[prioID] .. TooltipsA[1 + state%StateCount]})
		spSetUnitRulesParam(unitID, priorityTypes[prioID].param, state, ALLY_ACCESS)
	end
	priorityTypes[prioID].unitTable[unitID] = state	
end 

function PriorityCommand(unitID, cmdID, cmdParams, cmdOptions)
	local state = cmdParams[1]
	if cmdOptions and (cmdOptions.right) then 
		state = state - 2
	end
	state = state % StateCount

	SetPriorityState(unitID, state, cmdID)
	
	local lastUnitID = LastUnitFromFactory[unitID]  
	if lastUnitID ~= nil then 
		local _, _, _, _, progress = spGetUnitHealth(lastUnitID)
		if (progress ~= nil and progress < 1) then  -- we are building some unit ,set its priority too 
			SetPriorityState(lastUnitID, state, cmdID)
		end 
	end 
end


function gadget:AllowCommand_GetWantedCommand()
	return {[CMD_PRIORITY] = true, [CMD_MISC_PRIORITY] = true}
end

function gadget:AllowCommand_GetWantedUnitDefID()	
	return true
end

function gadget:AllowCommand(unitID, unitDefID, teamID,
                             cmdID, cmdParams, cmdOptions)
	if (cmdID == CMD_PRIORITY or cmdID == CMD_MISC_PRIORITY) then
		PriorityCommand(unitID, cmdID, cmdParams, cmdOptions)  
		return false  -- command was used
	end
	return true  -- command was not used
end

function gadget:CommandFallback(unitID, unitDefID, teamID,
                                cmdID, cmdParams, cmdOptions)
  if (cmdID ~= CMD_PRIORITY) then
    return false  -- command was not used
  end
  PriorityCommand(unitID, cmdParams, cmdOptions)  
  return true, true  -- command was used, remove it
end

local function AllowMiscBuildStep(unitID,teamID)

	local conAmount = UnitMiscPortion[unitID] or 0

	if (teamMiscPriorityUnits[teamID] == nil) then 
		teamMiscPriorityUnits[teamID] = {} 
	end
	
	if (UnitMiscPriority[unitID] == 0) then -- priority none/low
		teamMiscPriorityUnits[teamID][unitID] = 0
		local scale = TeamScale[teamID]
		if scale and scale[2] then 
			conAmount = conAmount + scale[2]
			if conAmount >= 1 then  
				UnitMiscPortion[unitID] = conAmount - 1
				return true
			else 
				UnitMiscPortion[unitID] = conAmount
				return false
			end		
		end
		return true
	end

	if (UnitMiscPriority[unitID] == 2) then  -- priority high
		teamMiscPriorityUnits[teamID][unitID] = 2
		return true
	end 
	
	teamMiscPriorityUnits[teamID][unitID] = 1
	
	local scale = TeamScale[teamID]
	if scale and scale[1] then 
		conAmount = conAmount + scale[1]
		if conAmount >= 1 then  
			UnitMiscPortion[unitID] = conAmount - 1
			return true
		else 
			UnitMiscPortion[unitID] = conAmount
			return false
		end	
	end 
	
	return true
end

function CheckMiscPriorityBuildStep(unitID, teamID, toSpend)
	return AllowMiscBuildStep(unitID,teamID)
end

function gadget:AllowUnitBuildStep(builderID, teamID, unitID, unitDefID, step) 
	if (step<0) then
		--// Reclaiming isn't prioritized
		return true
	end

	local conAmount = UnitConPortion[builderID] or 0
	if (TeamPriorityUnits[teamID] == nil) then 
		TeamPriorityUnits[teamID] = {} 
	end
	
	if (UnitPriority[unitID] == 0 or (UnitPriority[builderID] == 0 and (UnitPriority[unitID] or 1) == 1 )) then -- priority none/low
		TeamPriorityUnits[teamID][builderID] = 0
		local scale = TeamScale[teamID]
		if scale and scale[2] then 
			--if scale[2] is less than 1 then it has less chance of success. scale[2] is a ratio between available-resource and desired-spending.  scale[2] is less than 1 when desired-spending is bigger than available-resources.
			conAmount = conAmount + scale[2]
			if conAmount >= 1 then  
				UnitConPortion[builderID] = conAmount - 1
				return true
			else 
				UnitConPortion[builderID] = conAmount
				return false
			end		
		end
		return true
	end

	if (UnitPriority[unitID] == 2 or (UnitPriority[builderID] == 2 and (UnitPriority[unitID] or 1) == 1)) then  -- priority high
		TeamPriorityUnits[teamID][builderID] = 2
		return true
	end 
	
	TeamPriorityUnits[teamID][builderID] = 1
	
	local scale = TeamScale[teamID]
	if scale and scale[1] then 
		conAmount = conAmount + scale[1]
		if conAmount >= 1 then  
			UnitConPortion[builderID] = conAmount - 1
			return true
		else 
			UnitConPortion[builderID] = conAmount
			return false
		end		
	end 
	
	return true
end

function gadget:GameFrame(n)
	if n % 32 == 1 then 
		TeamScale = {}
		local teams = spGetTeamList()
		for i=1,#teams do
			local teamID = teams[i]
			prioUnits = TeamPriorityUnits[teamID] or {}
			local prioSpending = 0
			local normalSpending = 0
			local lowPrioSpending = 0
			for unitID, pri in pairs(prioUnits) do  --add construction priority spending
				local unitDefID = spGetUnitDefID(unitID)
				if unitDefID ~= nil then
					if pri == 2 then 
						prioSpending = prioSpending + UnitDefs[unitDefID].buildSpeed
					elseif pri == 1 then
						normalSpending = normalSpending + UnitDefs[unitDefID].buildSpeed
					else 
						lowPrioSpending = lowPrioSpending + UnitDefs[unitDefID].buildSpeed
					end 
				end 
			end
			
			for unitID, drain in pairs(miscMetalDrain) do --add misc priority spending
				local unitDefID = spGetUnitDefID(unitID)
				local pri = teamMiscPriorityUnits[teamID] and teamMiscPriorityUnits[teamID][unitID]
				if unitDefID ~= nil and pri then
					if pri == 2 then 
						prioSpending = prioSpending + drain
					elseif pri == 1 then
						normalSpending = normalSpending + drain
					else
						lowPrioSpending = lowPrioSpending + drain
					end 
				end 
			end 
			
			--SendToUnsynced("PriorityStats", teamID,  prioSpending, lowPrioSpending, n)   

			local level, _, fakePull, income, expense, _, _, recieved = spGetTeamResources(teamID, "metal", true)
			local elevel, _, epull, eincome, eexpense, _, _, erecieved = spGetTeamResources(teamID, "energy", true)
			
			-- Make sure the misc resoucing is constantly pulling the same value regardless of whether resources are spent
			local pull = prioSpending + normalSpending + lowPrioSpending
			epull = epull + pull - fakePull

			spSetTeamRulesParam(teamID, "extraPull", pull - fakePull, ALLY_ACCESS)
			
			--if i == 1 then
			--	Spring.Echo("pull " .. pull)
			--	Spring.Echo("lowPrioSpending " .. lowPrioSpending)
			--	Spring.Echo("normalSpending " .. normalSpending)
			--	Spring.Echo("prioSpending " .. prioSpending)
			--	Spring.Echo("misc Pull " .. miscTeamPull[teamID])
			--end
			
			local levelWithInc = (income + recieved + level)
			local elevelWithInc = (eincome + erecieved + elevel)
			
			if (TeamMetalReserved[teamID] and levelWithInc < TeamMetalReserved[teamID]) or (TeamEnergyReserved [teamID] and elevelWithInc < TeamEnergyReserved[teamID]) then 
				-- below reserved level, low and normal no spending
				TeamScale[teamID] = {0,0}
			elseif (TeamMetalReserved[teamID] and TeamMetalReserved[teamID] > 0 and level <= TeamMetalReserved[teamID] + pull) or 
					(TeamEnergyReserved[teamID] and TeamEnergyReserved[teamID] > 0 and elevel <= TeamEnergyReserved[teamID] + epull) then -- approach reserved level, less low and normal spending
                    
                -- both these values are positive and at least one is less than 1
				local mRatio = (level - (TeamMetalReserved[teamID] or 0))/pull
				local eRatio = (elevel - (TeamEnergyReserved[teamID] or 0))/epull
				  
				local spare
				if mRatio < eRatio then 
					spare = levelWithInc - (TeamMetalReserved[teamID] or 0) - prioSpending
				else
					spare = elevelWithInc - (TeamEnergyReserved[teamID] or 0) - prioSpending
				end

				--Spring.Echo(spare)
				if spare > 0 then
					if normalSpending <= 0 then
						if lowPrioSpending ~= 0 then
							TeamScale[teamID] = {0,spare/lowPrioSpending} --no normal spending, but mixed chance for low priority spending
						else
							TeamScale[teamID] = {0,0} --no normal spending, and no low priority spending, only hi-priority spending
						end
					elseif spare > normalSpending then
						spare = spare - normalSpending
						if spare > 0 and lowPrioSpending ~= 0 then
							TeamScale[teamID] = {1,spare/lowPrioSpending} --full normal spending, and mixed chance low-priority spending
						else
							TeamScale[teamID] = {1,0} --full normal spending, but no low-priority spending
						end
					elseif spare > 0 then
						TeamScale[teamID] = {spare/normalSpending,0} --mixed chance normal spending, and no low-priority spending
					end
				else
					TeamScale[teamID] = {0,0} --no  normal spending, no low-Priority spending
				end
			else --normal situation, or no reserve in effect.
				if pull > expense and level < expense and prioSpending < pull then 
					TeamScale[teamID] = {
						max(0,(level + income + recieved - prioSpending) / (normalSpending)),  -- m stall  scale . spareNormal/normal-priority-spending
						max(0,(level + income + recieved - normalSpending) / (lowPrioSpending))  -- m stall low scale . spareLow/low-priority-spending
					} 
					--Spring.Echo ("m_stall" .. TeamScale[teamID])
				elseif epull > eexpense and elevel < eexpense and prioSpending < epull then 
					TeamScale[teamID] = {				
						max(0,(elevel + eincome + erecieved - prioSpending) / (normalSpending)),  -- e stall  scale
						max(0,(elevel +eincome + erecieved - normalSpending) / (lowPrioSpending))  -- e stall low scale
					}
				end 
			end

			--SendToUnsynced("ReserveState", teamID, TeamMetalReserved[teamID] or 0, TeamEnergyReserved[teamID] or 0) 
		end
		teamMiscPriorityUnits = {} --reset priority list
		TeamPriorityUnits = {} --reset builder priority list (will be checked every n%32==15 th frame)
		--SendToUnsynced("PriorityStats", nil,  0, 0, n)   
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Misc priority unit handling

function AddMiscPriorityUnit(unitID,teamID) --remotely add a priority command.
	if not UnitMiscPriority[unitID] then
		local unitDefID = Spring.GetUnitDefID(unitID)
		local ud = UnitDefs[unitDefID]
		spInsertUnitCmdDesc(unitID, MiscCommandOrder, MiscCommandDesc)
		SetPriorityState(unitID, DefaultState, CMD_MISC_PRIORITY)
	end
end

function StartMiscPriorityResourcing(unitID,teamID,metalDrain) --remotely add a priority command.
	if not UnitMiscPriority[unitID] then
		AddMiscPriorityUnit(unitID,teamID)
	end
	miscTeamPull[teamID] = miscTeamPull[teamID] + metalDrain
	miscMetalDrain[unitID] = metalDrain
end

function StopMiscPriorityResourcing(unitID,teamID) --remotely remove a forced priority command.
	miscTeamPull[teamID] = miscTeamPull[teamID] - (miscMetalDrain[unitID] or 0)
	if (not reportedError) and (not miscMetalDrain[unitID]) then
		Spring.Echo("StopMiscPriorityResourcing nil miscMetalDrain")
		reportedError = true
	end
	miscMetalDrain[unitID] = nil
end

function RemoveMiscPriorityUnit(unitID,teamID) --remotely remove a forced priority command.
	if UnitMiscPriority[unitID] then
		if miscMetalDrain[unitID] then
			StopMiscPriorityResourcing(unitID,teamID)
		end
		local unitDefID = Spring.GetUnitDefID(unitID)
		local ud = UnitDefs[unitDefID]
		local cmdDescID = spFindUnitCmdDesc(unitID, CMD_MISC_PRIORITY)
		if (cmdDescID) then
			spRemoveUnitCmdDesc(unitID, cmdDescID)
			spSetUnitRulesParam(unitID, "miscpriority", 1) --reset to normal priority so that overhead icon doesn't show wrench
		end
	end
end

function gadget:UnitTaken(unitID, unitDefID, oldTeamID, teamID)
	if miscMetalDrain[unitID] then
		StopMiscPriorityResourcing(unitID,oldTeamID)
	end
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Unit Handling

function gadget:Initialize()
	GG.CheckMiscPriorityBuildStep  = CheckMiscPriorityBuildStep
	GG.AddMiscPriorityUnit         = AddMiscPriorityUnit
	GG.StartMiscPriorityResourcing = StartMiscPriorityResourcing
	GG.StopMiscPriorityResourcing  = StopMiscPriorityResourcing
	GG.RemoveMiscPriorityUnit      = RemoveMiscPriorityUnit

	gadgetHandler:RegisterCMDID(CMD_PRIORITY)
	gadgetHandler:RegisterCMDID(CMD_MISC_PRIORITY)

	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local teamID = Spring.GetUnitTeam(unitID)
		spInsertUnitCmdDesc(unitID, CommandOrder, CommandDesc)
	end

end

function gadget:RecvLuaMsg(msg, playerID)
	if msg:find("mreserve:",1,true) then
		local _,_,spec,teamID = spGetPlayerInfo(playerID)
		local amount = msg:sub(10)
		if spec then return end
		SetMetalReserved(teamID, amount*1)
	end	
	if msg:find("ereserve:",1,true) then
		local _,_,spec,teamID = spGetPlayerInfo(playerID)
		local amount = msg:sub(10)
		if spec then return end
		SetEnergyReserved(teamID, amount*1)
	end
end

function gadget:UnitCreated(UnitID, UnitDefID, TeamID, builderID) 
	local prio  = DefaultState
	if (builderID ~= nil)  then
		local unitDefID = spGetUnitDefID(builderID)
		if (unitDefID ~= nil and UnitDefs[unitDefID].isFactory) then 
			prio = UnitPriority[builderID] or DefaultState  -- inherit priorty from factory
			LastUnitFromFactory[builderID] = UnitID 
		end
	end 	
	UnitPriority[UnitID] =  prio
	CommandDesc.params[1] = prio
	spInsertUnitCmdDesc(UnitID, CommandOrder, CommandDesc)
end



function gadget:UnitFinished(unitID, unitDefID, teamID) 
	local ud = UnitDefs[unitDefID]
	
	if ((ud.isFactory or ud.isBuilder) and ud.buildSpeed > 0) then 
		SetPriorityState(unitID, DefaultState, CMD_PRIORITY)
	else  -- not a builder priority makes no sense now
		UnitPriority[unitID] = nil
		local cmdDescID = spFindUnitCmdDesc(unitID, CMD_PRIORITY)
		if (cmdDescID) then
			spRemoveUnitCmdDesc(unitID, cmdDescID)
		end
	end 

end 

function gadget:UnitDestroyed(UnitID, unitDefID, teamID) 
	UnitPriority[UnitID] = nil
	LastUnitFromFactory[UnitID] = nil
    local ud = UnitDefs[unitDefID]
	if UnitMiscPriority[unitID] then
		RemoveMiscPriorityUnit(unitID,teamID)
	end
    if ud then
		if ud.metalStorage and ud.metalStorage > 0 and TeamMetalReserved[teamID] then
			local _, sto = spGetTeamResources(teamID, "metal")
			if sto and TeamMetalReserved[teamID] > sto - ud.metalStorage then
				SetMetalReserved(teamID, sto - ud.metalStorage)
			end
		end
		if ud.energyStorage and ud.energyStorage > 0 and TeamEnergyReserved[teamID] then
			local _, sto = spGetTeamResources(teamID, "energy") - HIDDEN_STORAGE
			if sto and TeamEnergyReserved[teamID] > sto - ud.energyStorage then
				SetEnergyReserved(teamID, sto - ud.energyStorage)
			end
		end
    end
end
