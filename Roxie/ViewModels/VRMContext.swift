import Foundation
import SwiftUI

/// Port of `src/context/VRMContext.tsx`. Owns catalog data + the user's
/// current selection, and knows how to push the selection into the VRM
/// scene via a `WebSceneBridge` once the WebView is ready.
@MainActor
@Observable
final class VRMContext {
    struct InitialData {
        var characters: [CharacterItem] = []
        var ownedCharacterIds: Set<String> = []
        var backgrounds: [BackgroundItem] = []
        var ownedBackgroundIds: Set<String> = []
        var costumes: [CostumeItem] = []
        var ownedCostumeIds: Set<String> = []
        var dances: [DanceItem] = []
        var ownedDanceIds: Set<String> = []
        var medias: [MediaItem] = []
        var ownedMediaIds: Set<String> = []
    }

    var initialData: InitialData = .init()
    var isLoadingInitial: Bool = false
    var initialLoadError: String?

    var currentCharacter: CharacterItem?
    var currentCostume: CostumeItem?
    var currentBackground: BackgroundItem?

    private let characters = CharacterRepository()
    private let backgrounds = BackgroundRepository()
    private let costumes = CostumeRepository()
    private let dances = DanceRepository()
    private let medias = MediaRepository()

    private var hasAppliedInitialModel = false

    func refreshInitialData() async {
        isLoadingInitial = true
        defer { isLoadingInitial = false }

        let charsValue: [CharacterItem] = (try? await characters.fetchAllCharacters()) ?? []
        let ownedCharsValue: [String] = (try? await characters.fetchOwnedCharacterIds()) ?? []
        let bgsValue: [BackgroundItem] = (try? await backgrounds.fetchAllBackgrounds()) ?? []
        let ownedBgsValue: [String] = (try? await characters.fetchOwnedItemIds(itemType: "background")) ?? []
        let costumesValue: [CostumeItem] = (try? await costumes.fetchAllCostumes()) ?? []
        let ownedCostumesValue: [String] = (try? await characters.fetchOwnedItemIds(itemType: "costume")) ?? []
        let dancesValue: [DanceItem] = (try? await dances.fetchAllDances()) ?? []
        let ownedDancesValue: [String] = (try? await characters.fetchOwnedItemIds(itemType: "dance")) ?? []
        let mediasValue: [MediaItem] = (try? await medias.fetchAllMedia()) ?? []
        let ownedMediasValue: [String] = (try? await characters.fetchOwnedItemIds(itemType: "media")) ?? []

        initialData = InitialData(
            characters: charsValue,
            ownedCharacterIds: Set(ownedCharsValue),
            backgrounds: bgsValue,
            ownedBackgroundIds: Set(ownedBgsValue),
            costumes: costumesValue,
            ownedCostumeIds: Set(ownedCostumesValue),
            dances: dancesValue,
            ownedDanceIds: Set(ownedDancesValue),
            medias: mediasValue,
            ownedMediaIds: Set(ownedMediasValue)
        )

        Log.app.info("Loaded \(charsValue.count) characters, \(bgsValue.count) backgrounds, \(costumesValue.count) costumes")
        ensureDefaultSelection()
        initialLoadError = charsValue.isEmpty ? L10n.errorLoad : nil
    }

    func setCurrentCharacter(_ character: CharacterItem?, bridge: WebSceneBridge? = nil) {
        currentCharacter = character
        Persistence.characterId = character?.id
        if let name = character?.name, !name.isEmpty { Persistence.modelName = name }
        if let url = character?.baseModelUrl { Persistence.modelURL = url }

        if let character, let bridge, let url = character.baseModelUrl {
            bridge.loadModelByURL(url, name: character.name ?? "Character")
        }

        // Pick character's default background if none is set yet
        if let defaultBgId = character?.backgroundDefaultId,
           let bg = initialData.backgrounds.first(where: { $0.id == defaultBgId }) {
            setCurrentBackground(bg, bridge: bridge)
        }
    }

    func setCurrentCostume(_ costume: CostumeItem?, bridge: WebSceneBridge? = nil) {
        currentCostume = costume
        guard let charId = currentCharacter?.id else { return }
        Persistence.setCostumeSelection(for: charId, CharacterCostumeSelection(
            costumeId: costume?.id,
            modelName: costume?.costumeName,
            modelURL: costume?.modelUrl
        ))
        if let costume, let bridge, let url = costume.modelUrl {
            bridge.loadModelByURL(url, name: costume.costumeName ?? "Costume")
        }
    }

    func setCurrentBackground(_ background: BackgroundItem?, bridge: WebSceneBridge? = nil) {
        currentBackground = background
        guard let charId = currentCharacter?.id else { return }
        let bgUrl = background?.image ?? background?.videoUrl
        Persistence.setBackgroundSelection(for: charId, CharacterBackgroundSelection(
            backgroundId: background?.id,
            backgroundURL: bgUrl,
            backgroundName: background?.name
        ))
        if let url = bgUrl { Persistence.backgroundURL = url }
        if let name = background?.name { Persistence.backgroundName = name }

        guard let bridge, let background else { return }
        // Videos go through setBackgroundVideo; static images through setBackgroundImage
        if let videoUrl = background.videoUrl, !videoUrl.isEmpty {
            bridge.setBackgroundVideo(videoUrl)
        } else if let imageUrl = background.image, !imageUrl.isEmpty {
            bridge.setBackgroundImage(imageUrl)
        }
    }

    /// Called once the WebView emits `modelLoaded` / `initialReady`. Pushes
    /// the currently-selected character + background into the scene (the RN
    /// equivalent is `ensureInitialModelApplied`).
    func ensureInitialModelApplied(bridge: WebSceneBridge?) {
        guard !hasAppliedInitialModel, let bridge else { return }
        guard let character = currentCharacter else {
            Log.app.info("ensureInitialModelApplied: no current character yet, retry after fetch")
            return
        }

        // Prefer costume model URL, fall back to character base model URL.
        let costumeSelection = Persistence.getCostumeSelection(for: character.id)
        let modelUrl = costumeSelection?.modelURL ?? character.baseModelUrl ?? ""
        let modelName = costumeSelection?.modelName ?? character.name ?? "Model"

        if !modelUrl.isEmpty {
            bridge.loadModelByURL(modelUrl, name: modelName)
            Log.app.info("applied model \(modelName, privacy: .public) url=\(modelUrl, privacy: .public)")
        } else {
            Log.app.warning("Character \(character.id) has no base_model_url — scene stays empty")
        }

        // Apply persisted / default background too.
        let bgSelection = Persistence.getBackgroundSelection(for: character.id)
        if let bgUrl = bgSelection?.backgroundURL, !bgUrl.isEmpty {
            if bgUrl.hasSuffix(".mp4") || bgUrl.contains("/video") {
                bridge.setBackgroundVideo(bgUrl)
            } else {
                bridge.setBackgroundImage(bgUrl)
            }
        } else if let bgId = character.backgroundDefaultId,
                  let bg = initialData.backgrounds.first(where: { $0.id == bgId }) {
            if let videoUrl = bg.videoUrl, !videoUrl.isEmpty {
                bridge.setBackgroundVideo(videoUrl)
            } else if let imageUrl = bg.image, !imageUrl.isEmpty {
                bridge.setBackgroundImage(imageUrl)
            }
        }

        hasAppliedInitialModel = true
    }

    private func ensureDefaultSelection() {
        if currentCharacter == nil,
           let persistedId = Persistence.characterId,
           let match = initialData.characters.first(where: { $0.id == persistedId }) {
            currentCharacter = match
        }
        if currentCharacter == nil {
            currentCharacter = initialData.characters.first
        }
    }
}
