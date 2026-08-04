--!strict

local Domains = script.Parent.Parent.Domains

local ServiceGraph = {}

function ServiceGraph.domainModules()
	return {
		require(Domains.SessionDomain), require(Domains.SceneDomain), require(Domains.MovementDomain),
		require(Domains.RulesDomain), require(Domains.ExplorationDomain), require(Domains.EncounterDomain),
		require(Domains.CharacterDomain), require(Domains.InventoryDomain), require(Domains.TimeDomain),
		require(Domains.UiPreferenceDomain), require(Domains.JournalDomain), require(Domains.SceneAuthoringDomain),
		require(Domains.DmWorkspaceDomain), require(Domains.ContentDomain), require(Domains.CharacterContentDomain),
		require(Domains.RulesContentDomain), require(Domains.NpcContentDomain), require(Domains.ReleaseDomain),
	}
end

return table.freeze(ServiceGraph)
