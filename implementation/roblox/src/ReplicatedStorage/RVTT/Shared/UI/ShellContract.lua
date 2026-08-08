--!strict

export type Role = string
export type Mode = string
export type Surface = string
export type Context = { role: Role, mode: Mode, surface: Surface }

local validRoles = { observer = true, player = true, dm = true }
local validSurfaces = { gameplay = true, management = true, session = true, dm = true }

local ShellContract = {
	Surface = table.freeze({
		GAMEPLAY = "gameplay",
		MANAGEMENT = "management",
		SESSION = "session",
		DM = "dm",
	}),
}

local function projectedRole(payload: any, userId: number): Role
	local domains = if type(payload) == "table" then payload.domains else nil
	local session = if type(domains) == "table" then domains.session else nil
	local memberships = if type(session) == "table" then session.memberships else nil
	local membership = if type(memberships) == "table" then memberships[tostring(userId)] else nil
	local role = if type(membership) == "table" then membership.role else nil
	if type(role) == "string" and validRoles[role] == true then
		return role :: any
	end
	return "observer" :: Role
end

local function projectedMode(payload: any): Mode
	local domains = if type(payload) == "table" then payload.domains else nil
	local session = if type(domains) == "table" then domains.session else nil
	if type(session) ~= "table" or session.phase ~= "active" then
		return "session" :: Mode
	end
	local encounter = if type(domains) == "table" then domains.encounter else nil
	local active = if type(encounter) == "table" then encounter.active else nil
	if type(active) == "table" and active.status == "active" then
		return "encounter" :: Mode
	end
	return "exploration" :: Mode
end

function ShellContract.isSurfaceAllowed(role: any, surface: any): boolean
	if type(role) ~= "string" or validRoles[role] ~= true then
		return false
	end
	if type(surface) ~= "string" or validSurfaces[surface] ~= true then
		return false
	end
	if surface == "dm" then
		return role == "dm"
	end
	if surface == "management" then
		return role == "player" or role == "dm"
	end
	return true
end

function ShellContract.resolve(payload: any, userId: number): Context
	local role = projectedRole(payload, userId)
	local mode = projectedMode(payload)
	local surface: Surface
	if role == "dm" and mode ~= "session" then
		surface = "dm"
	elseif mode == "session" then
		surface = "session"
	else
		surface = "gameplay"
	end
	return { role = role, mode = mode, surface = surface }
end

return table.freeze(ShellContract)

