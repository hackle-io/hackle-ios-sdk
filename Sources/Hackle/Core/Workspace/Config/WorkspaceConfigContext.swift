import Foundation

struct WorkspaceConfigContext: WorkspaceContext {
    let workspace: WorkspaceConfig   // WorkspaceType = WorkspaceConfig
    let modifiedAt: String?
    let dto: WorkspaceConfigDto

    static func of(dto: WorkspaceConfigDto, modifiedAt: String?) -> WorkspaceConfigContext {
        WorkspaceConfigContext(
            workspace: DefaultWorkspaceConfig.from(dto: dto, modifiedAt: modifiedAt),
            modifiedAt: modifiedAt,
            dto: dto
        )
    }

    static func from(dto: WorkspaceConfigRecordDto) -> WorkspaceConfigContext {
        of(dto: dto.config, modifiedAt: dto.lastModified)
    }
}
