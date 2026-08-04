--!strict

local Version = {
	SCHEMA = 1,
	PROTOCOL = 1,
	BUILD = "rvtt-remake-greenfield-1",
	RULESET = "dnd5e-2024",
	LOCALE = "ko-KR",
}

function Version.supportsProtocol(value: unknown): boolean
	return type(value) == "number" and value == Version.PROTOCOL
end

return table.freeze(Version)
