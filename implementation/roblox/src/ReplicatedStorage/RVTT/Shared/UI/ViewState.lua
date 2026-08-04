--!strict

local ViewState = table.freeze({
	LOADING = "loading",
	READY = "ready",
	EMPTY = "empty",
	WAITING = "waiting",
	DENIED = "denied",
	STALE = "stale",
	ERROR = "error",
	RESYNCING = "resyncing",
	RECOVERING = "recovering",
})

return ViewState
