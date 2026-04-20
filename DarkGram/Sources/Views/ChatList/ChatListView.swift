import SwiftUI
import TDLibKit

struct ChatListView: View {
    @EnvironmentObject var tdManager: TDManager
    @EnvironmentObject var tweaks: TweakSettings
    @EnvironmentObject var theme: ThemeManager

    @State private var searchText = ""
    @State private var showSettings = false
    @State private var selectedChat: Chat?

    var filteredChats: [Chat] {
        let sorted = tdManager.chats.sorted {
            ($0.positions.first?.order ?? 0) > ($1.positions.first?.order ?? 0)
        }
        if searchText.isEmpty { return sorted }
        return sorted.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.colors.bg.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(theme.colors.textSecondary)
                        TextField("Поиск", text: $searchText)
                            .foregroundColor(theme.colors.text)
                    }
                    .padding(10)
                    .background(theme.colors.surface)
                    .cornerRadius(10)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                    // Ghost mode banner
                    if tweaks.ghostMode {
                        HStack(spacing: 6) {
                            Image(systemName: "eye.slash.fill")
                            Text("Ghost Mode активен")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(theme.colors.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(theme.colors.accent.opacity(0.12))
                    }

                    // Chat list
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredChats, id: \.id) { chat in
                                ChatRowView(chat: chat)
                                    .onTapGesture { selectedChat = chat }
                                Divider()
                                    .background(theme.colors.separator)
                                    .padding(.leading, 76)
                            }
                        }
                    }
                }
            }
            .navigationTitle("DarkGram+")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(theme.colors.accent)
                    }
                }
            }
            .toolbarBackground(theme.colors.bg, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(item: $selectedChat) { chat in
                ChatView(chat: chat)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }
}
