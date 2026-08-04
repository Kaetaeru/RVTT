--!strict

local catalog = {
	INVALID_ENVELOPE = "error.protocol.invalid_envelope",
	UNSUPPORTED_VERSION = "error.protocol.unsupported_version",
	UNAUTHORIZED = "error.security.unauthorized",
	RATE_LIMITED = "error.security.rate_limited",
	STALE_EPOCH = "error.authority.stale_epoch",
	STALE_REVISION = "error.authority.stale_revision",
	DUPLICATE_COMMAND = "error.command.duplicate",
	UNKNOWN_COMMAND = "error.command.unknown",
	VALIDATION_FAILED = "error.validation.failed",
	NOT_FOUND = "error.common.not_found",
	CONFLICT = "error.common.conflict",
	NOT_READY = "error.common.not_ready",
	PERSISTENCE_FAILED = "error.persistence.failed",
	MIGRATION_FAILED = "error.persistence.migration_failed",
	CONTENT_BLOCKED = "error.content.blocked",
	INTERNAL_ERROR = "error.internal",
}

return table.freeze(catalog)
