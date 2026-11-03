import SwiftUI
import AppKit

@main
struct SlopMonsterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject var settings = AppSettings.shared
    
    var body: some Scene {
        // Full Primary Application Window
        WindowGroup("SlopMonster", id: "main") {
            MainWindowView()
                .navigationTitle("SlopMonster")
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 1040, height: 680)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Draft") {
                    NotificationCenter.default.post(name: .newDraftRequested, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command])
                
                Button("Paste and Cleanse Clipboard") {
                    NotificationCenter.default.post(name: .cleanseClipboardRequested, object: nil)
                }
                .keyboardShortcut("v", modifiers: [.command, .shift])
            }
        }
        
        // Native Preferences Window
        Settings {
            SettingsView()
        }
        
        // Companion Menu Bar Extra for Always-On Access
        MenuBarExtra("SlopMonster", systemImage: "sparkles.rectangle.stack") {
            Button("Open SlopMonster App") {
                NSApp.activate(ignoringOtherApps: true)
                if let window = NSApp.windows.first(where: { $0.canBecomeMain }) {
                    window.makeKeyAndOrderFront(nil)
                }
            }
            .keyboardShortcut("o", modifiers: [.command])
            
            Divider()
            
            Button("Cleanse Clipboard Directly") {
                cleanseClipboardFromMenuBar()
            }
            
            Divider()
            
            Button("Settings...") {
                NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
            }
            .keyboardShortcut(",", modifiers: [.command])
            
            Button("Quit SlopMonster") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: [.command])
        }
        .menuBarExtraStyle(.menu)
    }
    
    private func cleanseClipboardFromMenuBar() {
        guard let clip = NSPasteboard.general.string(forType: .string), !clip.isEmpty else { return }
        Task {
            let creds = settings.activeCredentials()
            do {
                let res = try await CleanseService.shared.cleanse(
                    draft: clip,
                    provider: settings.cleanseProvider,
                    baseURL: creds.baseURL,
                    apiKey: creds.apiKey,
                    model: creds.model,
                    context: settings.writingContext
                )
                await MainActor.run {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(res.cleansedText, forType: .string)
                    RetroSound.playCleanChime()
                }
            } catch {
                // Show notification or alert if needed
            }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // App is fully initialized
    }
}

extension Notification.Name {
    static let newDraftRequested = Notification.Name("newDraftRequested")
    static let cleanseClipboardRequested = Notification.Name("cleanseClipboardRequested")
}
