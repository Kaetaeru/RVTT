--!strict

local PermissionPolicy = {}

function PermissionPolicy.hasRole(context, allowed: { string }): boolean
	for _, role in allowed do
		if context.role == role then
			return true
		end
	end
	return false
end

function PermissionPolicy.owns(context, ownerUserId: unknown): boolean
	return type(ownerUserId) == "number" and ownerUserId == context.playerId
end

return table.freeze(PermissionPolicy)
