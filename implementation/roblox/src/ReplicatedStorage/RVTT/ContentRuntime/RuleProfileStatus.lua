--!strict

-- Server publication replaces these values with RulePackageResolver.clientSafeStatus().
-- No source binding, repository, revision, count, digest, or credential field is allowed here.
return {
	activeProfile = "public",
	basePackageId = "rvtt.core.rules",
	fallbackActive = false,
	fallbackReasonCode = nil,
	attributionRequired = true,
}
