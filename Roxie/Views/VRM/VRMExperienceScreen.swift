import SwiftUI

struct VRMExperienceScreen: View {
    @Environment(VRMContext.self) private var vrm
    @Environment(AppRootModel.self) private var root
    @Environment(AuthManager.self) private var auth
    @Environment(ChatManager.self) private var chat

    @State private var bridge: WebSceneBridge?
    @State private var modelReady: Bool = false
    @State private var showInitialLoading: Bool = true
    @State private var parallaxOffset: CGSize = .zero
    @State private var isDancing: Bool = false
    @State private var toast: ToastMessage?

    private let voice = VoiceCallService.shared
    private var isInCall: Bool { voice.isConnected || voice.isCameraMode }
    private var isCallLoading: Bool { voice.isBooting || voice.isConnecting }

    private var isDarkBackground: Bool {
        vrm.currentBackground?.isDark ?? true
    }

    var body: some View {
        @Bindable var root = root

        ZStack {
            Color.black.ignoresSafeArea()

            VRMWebView(
                bridge: $bridge,
                onModelReady: { modelReady = true },
                onMessage: { message in
                    Log.app.debug("VRM msg: \(message, privacy: .public)")
                }
            )
            .ignoresSafeArea()
            .gesture(parallaxGesture)

            VStack(spacing: 0) {
                if !isInCall {
                    SceneHeader(
                        character: vrm.currentCharacter,
                        onOpenSettings: { root.showSettings = true },
                        onOpenCharacters: { root.showCharacterSheet = true }
                    )

                    VRMUIOverlay(
                        onOpenSettings: { root.showSettings = true },
                        onTriggerDance: { bridge?.triggerDance() },
                        onToggleBGM: { BackgroundMusicManager.shared.toggle() },
                        onStartCall: { Task { await handleToggleMic() } },
                        onToggleChatList: { chat.toggleChatList() },
                        isBgmOn: BackgroundMusicManager.shared.isPlaying,
                        showChatList: chat.showChatList
                    )
                    .padding(.top, 12)
                    .transition(.opacity)
                }

                Spacer(minLength: 0)

                ChatBottomOverlay(
                    chat: chat,
                    onOpenHistory: { chat.openHistory() },
                    onToggleMic: { Task { await handleToggleMic() } },
                    onToggleVideo: { Task { await handleToggleVideo() } },
                    onCapture: { handleCapture() },
                    onSendPhoto: { root.showMediaSheet = true },
                    onDance: { handleDance() },
                    isDancing: isDancing,
                    isVoiceCallActive: voice.isConnected,
                    isVideoCallActive: voice.isCameraMode,
                    isInCall: isInCall
                )
            }
            .animation(.easeInOut(duration: 0.25), value: isInCall)

            if isCallLoading {
                VoiceLoadingOverlay(
                    visible: true,
                    characterName: vrm.currentCharacter?.name ?? "Character",
                    avatarURL: vrm.currentCharacter?.avatar ?? vrm.currentCharacter?.thumbnailUrl,
                    backgroundURL: vrm.currentBackground?.image ?? vrm.currentBackground?.thumbnail
                )
                .transition(.opacity)
            }

            if isInCall {
                CallControlsOverlay(
                    remainingSeconds: voice.remainingQuotaSeconds,
                    isCameraMode: voice.isCameraMode,
                    onEndCall: { Task { await handleToggleMic() } }
                )
                .transition(.opacity)
            }

            ToastOverlay(toast: toast)

            if showInitialLoading {
                InitialLoadingOverlay()
                    .transition(.opacity)
            }
        }
        .environment(\.isDarkBackground, isDarkBackground)
        .task {
            await vrm.refreshInitialData()
            configureChatForCurrentCharacter()
            // If the webview finished loading before Supabase responded,
            // push the just-fetched character into the scene now.
            if modelReady {
                vrm.ensureInitialModelApplied(bridge: bridge)
            }
            if vrm.isLoadingInitial == false {
                withAnimation(.easeInOut) { showInitialLoading = false }
            }
        }
        .onChange(of: vrm.currentCharacter?.id) { _, _ in
            configureChatForCurrentCharacter()
            // Force-push the new character into the scene if the webview is
            // already showing the previous one.
            if modelReady, let character = vrm.currentCharacter, let url = character.baseModelUrl {
                bridge?.loadModelByURL(url, name: character.name ?? "Character")
            }
        }
        .onChange(of: modelReady) { _, ready in
            if ready {
                vrm.ensureInitialModelApplied(bridge: bridge)
                withAnimation { showInitialLoading = false }
            }
        }
        .onChange(of: bridge != nil) { _, hasBridge in
            // Bridge is created inside `VRMWebView.makeUIView` *after* the
            // webview is instantiated. If the DB has already responded by
            // then we still want to apply the selection.
            if hasBridge, modelReady {
                vrm.ensureInitialModelApplied(bridge: bridge)
            }
        }
        .onAppear {
            chat.onAgentReply = { [weak bridge = bridge] text in
                // TTS/mouth animation would be driven here via bridge.setMouthOpen
                _ = text; _ = bridge
            }
        }
        .fullScreenCover(isPresented: $root.showSubscriptionSheet) {
            SubscriptionScreen(onClose: { root.showSubscriptionSheet = false })
        }
        .sheet(isPresented: $root.showQuestSheet) {
            SimpleSheet(title: L10n.sheetQuests, subtitle: L10n.questDaily)
        }
        .sheet(isPresented: $root.showBackgroundSheet) {
            BackgroundSheet(
                items: vrm.initialData.backgrounds,
                ownedIds: vrm.initialData.ownedBackgroundIds,
                onSelect: { bg in
                    vrm.setCurrentBackground(bg, bridge: bridge)
                    root.showBackgroundSheet = false
                },
                onLockedTap: {
                    root.showBackgroundSheet = false
                    root.showSubscriptionSheet = true
                }
            )
        }
        .sheet(isPresented: $root.showCharacterSheet) {
            CharacterSheet(
                items: vrm.initialData.characters,
                ownedIds: vrm.initialData.ownedCharacterIds,
                onSelect: { char in
                    vrm.setCurrentCharacter(char, bridge: bridge)
                    root.showCharacterSheet = false
                },
                onLockedTap: {
                    root.showCharacterSheet = false
                    root.showSubscriptionSheet = true
                }
            )
        }
        .sheet(isPresented: $root.showCostumeSheet) {
            CostumeSheet(
                items: vrm.initialData.costumes.filter { $0.characterId == vrm.currentCharacter?.id },
                ownedIds: vrm.initialData.ownedCostumeIds,
                onSelect: { costume in
                    vrm.setCurrentCostume(costume, bridge: bridge)
                    root.showCostumeSheet = false
                },
                onLockedTap: {
                    root.showCostumeSheet = false
                    root.showSubscriptionSheet = true
                }
            )
        }
        .sheet(isPresented: $root.showDanceSheet) {
            DanceSheet(
                items: vrm.initialData.dances,
                ownedIds: vrm.initialData.ownedDanceIds,
                onPlay: { dance in
                    if let file = dance.fileName {
                        bridge?.loadAnimation(named: file)
                    } else {
                        bridge?.triggerDance()
                    }
                    isDancing = true
                    root.showDanceSheet = false
                },
                onLockedTap: {
                    root.showDanceSheet = false
                    root.showSubscriptionSheet = true
                },
                onStop: {
                    bridge?.stopAction()
                    isDancing = false
                    root.showDanceSheet = false
                },
                isDancing: isDancing
            )
        }
        .sheet(isPresented: $root.showMediaSheet) {
            MediaSheet(
                items: vrm.initialData.medias.filter {
                    $0.characterId == vrm.currentCharacter?.id
                },
                ownedIds: vrm.initialData.ownedMediaIds,
                onSend: { media in
                    Task { await chat.sendMedia(media) }
                    root.showMediaSheet = false
                },
                onLockedTap: {
                    root.showMediaSheet = false
                    root.showSubscriptionSheet = true
                }
            )
        }
        .sheet(isPresented: $root.showSettings) {
            SettingsSheet()
        }
        .fullScreenCover(isPresented: Binding(
            get: { chat.showChatHistoryFullScreen },
            set: { newValue in if !newValue { chat.closeHistory() } }
        )) {
            ChatHistoryModal(chat: chat, onClose: { chat.closeHistory() })
        }
    }

    private var parallaxGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                parallaxOffset = value.translation
                bridge?.applyParallax(
                    dx: Double(value.translation.width / 160),
                    dy: Double(value.translation.height / 160)
                )
            }
            .onEnded { _ in
                parallaxOffset = .zero
                bridge?.applyParallax(dx: 0, dy: 0)
            }
    }

    private func handleToggleMic() async {
        if voice.isConnected || voice.isBooting || voice.isConnecting {
            await voice.endCall()
            bridge?.setCallMode(false)
            appendCallEndedMessage()
        } else {
            bridge?.setCallMode(true)
            await voice.startVoiceCall(character: vrm.currentCharacter)
        }
    }

    private func handleToggleVideo() async {
        if voice.isConnected {
            voice.toggleCameraMode()
        } else {
            bridge?.setCallMode(true)
            await voice.startVideoCall(character: vrm.currentCharacter)
        }
    }

    private func appendCallEndedMessage() {
        let secs = voice.lastCallDurationSeconds
        let m = secs / 60
        let s = secs % 60
        let durationStr = "\(m)m\(s)s"
        let name = vrm.currentCharacter?.name ?? "Character"
        chat.addSystemMessage("Call \(name) \(durationStr)")
    }

    private func handleCapture() {
        Task {
            guard let image = await bridge?.snapshot() else {
                presentToast(.init(text: "Couldn't capture scene", systemImage: "exclamationmark.triangle.fill"))
                return
            }
            do {
                try await CaptureService.saveToPhotos(image)
                presentToast(.init(text: "Saved to Photos", systemImage: "checkmark.circle.fill"))
            } catch CaptureService.CaptureError.permissionDenied {
                presentToast(.init(text: "Photos access denied", systemImage: "exclamationmark.triangle.fill"))
            } catch {
                presentToast(.init(text: "Save failed", systemImage: "exclamationmark.triangle.fill"))
            }
        }
    }

    private func handleDance() {
        if isDancing {
            bridge?.stopAction()
            isDancing = false
        } else {
            root.showDanceSheet = true
        }
    }

    private func presentToast(_ message: ToastMessage) {
        toast = message
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if toast?.id == message.id { toast = nil }
        }
    }

    private func configureChatForCurrentCharacter() {
        chat.configure(
            characterId: vrm.currentCharacter?.id,
            characterName: vrm.currentCharacter?.name,
            isPro: RevenueCatManager.shared.isProUser
        )
    }
}

private struct InitialLoadingOverlay: View {
    @State private var glow = false
    var body: some View {
        ZStack {
            Cyber.bg.ignoresSafeArea()
            VStack(spacing: 18) {
                ZStack {
                    HexagonShape()
                        .stroke(Cyber.cyan.opacity(0.7), lineWidth: 2)
                        .shadow(color: Cyber.cyan.opacity(glow ? 0.9 : 0.3), radius: glow ? 18 : 6)
                    Image(systemName: "circle.hexagongrid.fill")
                        .font(.system(size: 38, weight: .heavy))
                        .foregroundStyle(Cyber.cyan)
                }
                .frame(width: 100, height: 115)
                .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: glow)

                Text(L10n.Cyber.initializing)
                    .font(Cyber.mono(11, weight: .heavy))
                    .foregroundStyle(Cyber.cyan)
                    .tracking(2.4)
                Text("//bonie.os")
                    .font(Cyber.mono(13, weight: .semibold))
                    .foregroundStyle(Cyber.textDim)
                    .tracking(1.4)
            }
        }
        .onAppear { glow = true }
    }
}

private struct SimpleSheet: View {
    let title: String
    let subtitle: String

    var body: some View {
        CyberSheetChrome(title: title, subtitle: "Quest // Daily", tint: Cyber.amber) {
            VStack(spacing: 16) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 48, weight: .heavy))
                    .foregroundStyle(Cyber.amber)
                    .shadow(color: Cyber.amber.opacity(0.7), radius: 8)
                    .padding(.top, 24)
                Text(subtitle.uppercased())
                    .font(Cyber.mono(13, weight: .heavy))
                    .foregroundStyle(Cyber.text)
                    .tracking(1.4)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Spacer()
            }
        }
        .presentationDetents([.medium, .large])
    }
}
