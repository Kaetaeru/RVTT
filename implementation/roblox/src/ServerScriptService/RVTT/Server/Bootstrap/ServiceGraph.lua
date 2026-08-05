--!strict

local Domains = script.Parent.Parent.Domains

export type DomainModule = {
	id: string,
	slice: number,
	initialState: () -> any,
	register: (registry: any) -> (),
}

local ServiceGraph = {}

function ServiceGraph.domainModules(): { DomainModule }
	return {
		require(Domains.SessionDomain) :: DomainModule,
		require(Domains.SceneDomain) :: DomainModule,
		require(Domains.MovementDomain) :: DomainModule,
		require(Domains.RulesDomain) :: DomainModule,
		require(Domains.ExplorationDomain) :: DomainModule,
		require(Domains.EncounterDomain) :: DomainModule,
		require(Domains.CharacterDomain) :: DomainModule,
		require(Domains.InventoryDomain) :: DomainModule,
		require(Domains.TimeDomain) :: DomainModule,
		require(Domains.UiPreferenceDomain) :: DomainModule,
		require(Domains.JournalDomain) :: DomainModule,
		require(Domains.SceneAuthoringDomain) :: DomainModule,
		require(Domains.DmWorkspaceDomain) :: DomainModule,
		require(Domains.ContentDomain) :: DomainModule,
		require(Domains.CharacterContentDomain) :: DomainModule,
		require(Domains.RulesContentDomain) :: DomainModule,
		require(Domains.NpcContentDomain) :: DomainModule,
		require(Domains.ReleaseDomain) :: DomainModule,
	}
end

return table.freeze(ServiceGraph)
