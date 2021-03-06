--[[
Lennys Scripts by Lenny. (STEAM_0:0:30422103)
Modified and improved by Ott (STEAM_0:0:36527860)
This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/.
Credit to the author must be given when using/sharing this work or derivative work from it.
]]
CreateClientConVar("lenny_aimsnap", 0)
CreateClientConVar("lenny_aimsnap_fov", 45)
CreateClientConVar("lenny_aimsnap_ignore_blocked", 1)
CreateClientConVar("lenny_aimsnap_prioritize", 0)
CreateClientConVar("lenny_aimsnap_target_friends", 0)
CreateClientConVar("lenny_aimsnap_target_npcs", 0)
CreateClientConVar("lenny_aimsnap_target_nonanons", 0)
CreateClientConVar("lenny_aimsnap_target_players", 1)
CreateClientConVar("lenny_aimsnap_single_target", 0)
CreateClientConVar("lenny_aimsnap_preserve_angles", 0)
CreateClientConVar("lenny_aimsnap_360noscopezzz", 0)

local FOV = GetConVarNumber("lenny_aimsnap_fov")
local preserve = GetConVarNumber("lenny_aimsnap_preserve_angles")
local ignoreblocked = GetConVarNumber("lenny_aimsnap_ignore_blocked")
local singletarget = GetConVarNumber("lenny_aimsnap_single_target")
local targetfriends = GetConVarNumber("lenny_aimsnap_target_friends")
local targetnonanons = GetConVarNumber("lenny_aimsnap_target_nonanons")
local targetnpcs = GetConVarNumber("lenny_aimsnap_target_npcs")
local targetplayers = GetConVarNumber("lenny_aimsnap_target_players")
local aimprioritize = GetConVarNumber("lenny_aimsnap_prioritize")
local noscope = GetConVarNumber("lenny_aimsnap_360noscopezzz")

local midx = ScrW()*.5
local midy = ScrH()*.5
local realang = Angle(0, 0, 0)
local lastang = Angle(0, 0, 0)
local newtarget = false
local scopeoffset = 0
local friends = {}
if Lenny then 
	if Lenny.friends then
		friends = Lenny.friends
	else
		Lenny.friends = {}
	end
end

local function getplayer(name)
	for k, v in pairs(player.GetAll()) do
		if v:Name() == name then return v end
	end
end

local function friendmenu()
	local menu = vgui.Create("DFrame")
	menu:SetSize(500,350)
	menu:MakePopup()
	menu:SetTitle("Friends List")
	menu:Center()
	menu:SetKeyBoardInputEnabled()


	local noton = vgui.Create("DListView",menu)
	noton:SetSize(200,menu:GetTall()-40)
	noton:SetPos(10,30)
	noton:AddColumn("Players")

	local on = vgui.Create("DListView",menu)
	on:SetSize(200,menu:GetTall()-40)
	on:SetPos(menu:GetWide()-210,30)
	on:AddColumn("Friends")

	local addent = vgui.Create("DButton",menu)
	addent:SetSize(50,25)
	addent:SetPos(menu:GetWide()/2-25,menu:GetTall()/2-20)
	addent:SetText("+")
	addent.DoClick = function() 
		if noton:GetSelectedLine() != nil then 
			local ent = getplayer(noton:GetLine(noton:GetSelectedLine()):GetValue(1))
			if !table.HasValue(friends,ent) then 
				table.insert(friends,ent)
				if Lenny then table.insert(Lenny.friends,ent) end
				noton:RemoveLine(noton:GetSelectedLine())
				on:AddLine(ent:Name())
			end
		end
	end

	local rement = vgui.Create("DButton",menu)
	rement:SetSize(50,25)
	rement:SetPos(menu:GetWide()/2-25,menu:GetTall()/2+20)
	rement:SetText("-")
	rement.DoClick = function()
		if on:GetSelectedLine() != nil then
			local ent = getplayer(on:GetLine(on:GetSelectedLine()):GetValue(1))
			if table.HasValue(friends,ent) then 
				for k,v in pairs(friends) do 
					if v == ent then 
						table.remove(friends,k) 
						if Lenny then table.remove(Lenny.friends,k) end
					end 
				end
					on:RemoveLine(on:GetSelectedLine())
					noton:AddLine(ent:Name())
			end
		end
	end

	local added = {}
	for _,v in pairs(player.GetAll()) do
		if !table.HasValue(added,v) and !table.HasValue(friends,v) then
			table.insert(added,v)
		end
	end
	table.sort(added, function(a, b)
		return tostring(a:Name()) < tostring(b:Name())
	end)
	for k, v in pairs(added) do
		noton:AddLine(v:Name())
	end
	table.sort(friends, function(a, b)
		return tostring(a:Name()) < tostring(b:Name())
	end)
	for _,v in pairs(friends) do
		on:AddLine(v:Name())
	end

end
concommand.Add("lenny_friends", friendmenu)

-- getting all members of the nonanon groups to mark them for later
local nonanonp = {}
local nonanon = {}

local function NonAnonPSuccess(body)
	local ID64s = string.Explode("|", body)

	if #ID64s > 0 then
		table.remove(ID64s, #ID64s)
		for k, v in pairs(ID64s) do
			table.insert(nonanonp, v)
		end
	end
end

local function OnFail(error)
	print("We failed to contact gmod.itslenny.de")
	print(error)
	
end

local function GetNonAnonPMembers()
	http.Fetch("http://www.gmod.itslenny.de/lennys/nonanon/groupinfo", NonAnonPSuccess, OnFail)
end

GetNonAnonPMembers()


local function sorter(v1, v2)
	if aimprioritize == 1 then
		if v1[5] > v2[5] then
			return true
		elseif v1[5] == v2[5] then
			if v1[6] < v2[6] then
				return true
			end
		end
	else
		if v1[3] < v2[3] then
			return true
		end
	end
end

local disfromaim = {}

local function isinfov(dist)
	if dist <= FOV then
		return true
	else
		return false
	end
end

local function angledistance(a, b, c)
	--return math.acos((a^2 + b^2 - c^2) / (2 * a * b)) * 59 --maaaath
end
local function angledifference(a, b)
	return math.abs(a.y - b.y)
end

local function rollover(n, min, max)
	while true do
		if n > max then
			n = min + n - max
		elseif n < min then
			n = max - min - n
		else
			return n
		end
	end
end

local function calcaim(v)
	local hat = v:LookupBone("ValveBiped.Bip01_Head1")
	local spine = v:LookupBone("ValveBiped.Bip01_Spine2")
	local origin = v:GetPos() + v:OBBCenter()
	local hatpos = Vector(0, 0, 0)
	if hat then
		hatpos = v:GetBonePosition(hat)
	elseif spine then
		hatpos = v:GetBonePosition(spine)
	else
		hatpos = origin
	end
	local scrpos = hatpos:ToScreen()
	local tracedat = {}
	tracedat.start = LocalPlayer():GetShootPos()
	tracedat.endpos = hatpos
	tracedat.mask = MASK_SHOT
	tracedat.filter = LocalPlayer()
	local trac = util.TraceLine(tracedat)
	local dmg = 0
	--local angdis = angledistance(LocalPlayer():GetShootPos():Distance(LocalPlayer():GetEyeTrace().HitPos), LocalPlayer():GetShootPos():Distance(hatpos), LocalPlayer():GetEyeTrace().HitPos:Distance(hatpos))
	local angdis = angledifference(LocalPlayer():EyeAngles(), (hatpos - LocalPlayer():GetShootPos()):Angle())
	local distocenter = math.abs(rollover(angdis, -180, 180))
	local distoplayer = LocalPlayer():GetPos():Distance(v:GetPos())
	if isinfov(distocenter) then
		if (trac.Entity == NULL or trac.Entity == v) or ignoreblocked == 0 then
			table.insert(disfromaim, {v,  scrpos, distocenter, hatpos, dmg, distoplayer})
		end
	end
end

local function aimsnap()
	disfromaim = {}
	surface.SetDrawColor(Color(255,255,255))
	local targets = {}
	if targetplayers == 1 then
		targets = player.GetAll()
	end
	if targetnpcs == 1 then
		for k, v in pairs(ents.GetAll()) do
			if v:IsNPC() then
				table.insert(targets, v)
			end
		end
	end
	for k, v in pairs(targets) do
		if (v:Health() > 0 or singletarget == 1) and v:IsValid() then
			if v != LocalPlayer() and v:IsPlayer() then
				if !(v:GetFriendStatus() == "friend" or table.HasValue(friends, v)) or targetfriends == 1 then
					if !table.HasValue(nonanonp, v:SteamID64()) or targetnonanons == 1 then
						calcaim(v)
					end
				end
			elseif v:IsNPC() then
				if v:Health() > 0 and v:IsValid() then
					calcaim(v)
				end
			end
		end
	end
	table.sort(disfromaim, sorter)
	surface.SetDrawColor(Color(0 , 255, 0))
	if disfromaim[1] then
		surface.DrawLine(midx, midy, disfromaim[1][2].x, disfromaim[1][2].y)
	end
end


concommand.Add("lenny_aimsnap_snap", function()
	if disfromaim[1] then
		LocalPlayer():SetEyeAngles((disfromaim[1][4] - LocalPlayer():GetShootPos()):Angle())
	else
		chat.AddText("No Target!")
	end
end)



concommand.Add("+lenny_aim", function()
	if GetConVarNumber("lenny_aimsnap") == 0 then
		chat.AddText("lenny_aimsnap must be 1 !!!")
	else
		realang = LocalPlayer():EyeAngles()
		lastang = LocalPlayer():EyeAngles()
		newtarget = true
		hook.Add("CreateMove", "snappyaim", function(cmd)
			if preserve then
				realang = realang + cmd:GetViewAngles() - lastang
			else
				realang = cmd:GetViewAngles()
			end
			--cmd:SetViewAngles(realang)
			if disfromaim[1] and LocalPlayer():Alive() and disfromaim[1][1]:IsValid() then
				if LocalPlayer():GetActiveWeapon():Clip1() > 0 then
					local targetang = (disfromaim[1][4] - LocalPlayer():GetShootPos()):Angle()
					targetang:Normalize()
					if newtarget then
						if targetang.y - cmd:GetViewAngles().y > 0 then scopeoffset = 3 else scopeoffset = -3 end
						newtarget = false
					end
					realang.y = math.NormalizeAngle(realang.y)
					
					if noscope == 1 then
						if cmd:KeyDown(IN_ATTACK) or math.abs(cmd:GetViewAngles().y - targetang.y) < 6 then
							cmd:SetViewAngles(targetang)
						else
							cmd:SetViewAngles(Angle(targetang.p, cmd:GetViewAngles().y - scopeoffset, 0))
						end
					else
						cmd:SetViewAngles(targetang)
					end
					
					if preserve == 1 then
						local move = Vector(cmd:GetForwardMove(), cmd:GetSideMove(), cmd:GetUpMove())
						move:Rotate(Angle((cmd:GetViewAngles()).p, (cmd:GetViewAngles() - realang).y, (cmd:GetViewAngles() - realang).r))
						cmd:SetForwardMove(move.x)
						cmd:SetSideMove(move.y)
						cmd:SetUpMove(move.z)
					end
					
					lastang = cmd:GetViewAngles()
				else
					newtarget = true
					if preserve == 1 then
						cmd:SetViewAngles(realang)
					end
				end
			else
				newtarget = true
				if preserve == 1 then
					cmd:SetViewAngles(realang)
				end
			end
			lastang = cmd:GetViewAngles()
		end)
		if preserve == 1 then
			hook.Add("CalcView", "preservativeaim", function(ply, pos, ang, fov)
				view = {}
				view.origin = pos
				view.angles = realang
				view.fov = fov
				--view.vm_angles = Angle(ang.p, (realang.y * 2) - ang.y, ang.r)
				view.vm_angles = ang
				return view
			end)
		end
	end

end)

concommand.Add("-lenny_aim", function()
	hook.Remove("CreateMove", "snappyaim")
	hook.Remove("Think", "snappyaim")
	hook.Remove("CalcView", "preservativeaim")
	LocalPlayer():SetEyeAngles(realang)
end)






hook.Remove("HUDPaint", "aimsnap")

if GetConVarNumber("lenny_aimsnap") == 1 then
	hook.Add("HUDPaint", "aimsnap", aimsnap)
end

-- end of prep


cvars.AddChangeCallback("lenny_aimsnap", function() 
	if GetConVarNumber("lenny_aimsnap") == 1 then
		hook.Add("HUDPaint", "aimsnap", aimsnap)
	else
		hook.Remove("HUDPaint", "aimsnap")
	end
end)

cvars.AddChangeCallback("lenny_aimsnap_fov", function() 
	FOV = GetConVarNumber("lenny_aimsnap_fov")
end)
cvars.AddChangeCallback("lenny_aimsnap_preserve_angles", function() 
	preserve = GetConVarNumber("lenny_aimsnap_preserve_angles")
end)
cvars.AddChangeCallback("lenny_aimsnap_ignore_blocked", function() 
	ignoreblocked = GetConVarNumber("lenny_aimsnap_ignore_blocked")
end)
cvars.AddChangeCallback("lenny_aimsnap_single_target", function() 
	singletarget = GetConVarNumber("lenny_aimsnap_single_target")
end)
cvars.AddChangeCallback("lenny_aimsnap_target_friends", function() 
	targetfriends = GetConVarNumber("lenny_aimsnap_target_friends")
end)
cvars.AddChangeCallback("lenny_aimsnap_target_nonanons", function() 
	targetnonanons = GetConVarNumber("lenny_aimsnap_target_nonanons")
end)
cvars.AddChangeCallback("lenny_aimsnap_target_npcs", function() 
	targetnpcs = GetConVarNumber("lenny_aimsnap_target_npcs")
end)
cvars.AddChangeCallback("lenny_aimsnap_target_players", function() 
	targetplayers = GetConVarNumber("lenny_aimsnap_target_players")
end)
cvars.AddChangeCallback("lenny_aimsnap_prioritize", function() 
	aimprioritize = GetConVarNumber("lenny_aimsnap_prioritize")
end)
cvars.AddChangeCallback("lenny_aimsnap_360noscopezzz", function()
	noscope = GetConVarNumber("lenny_aimsnap_360noscopezzz")
end)

MsgC(Color(0,255,0), "\nLennys AimSnap initialized!\n")
