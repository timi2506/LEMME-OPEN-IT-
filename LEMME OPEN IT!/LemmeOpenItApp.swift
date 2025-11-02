//
//  LEMME_OPEN_IT_App.swift
//  LEMME OPEN IT!
//
//  Created by Tim on 31.10.25.
//

import SwiftUI
import UniformTypeIdentifiers

@main
struct LemmeOpenItApp: App {
    @AppStorage("openOnSuccess") var openOnSuccess = true
    @State var importFile = false
    var body: some Scene {
        WindowGroup {
            ContentView(importFile: $importFile)
                .fileImporter(isPresented: $importFile, allowedContentTypes: [.data, .application]) { result in
                    do {
                        let url = try result.get()
                        try cleanAndOpenFile(with: url)
                        let notification = CustomNotification(title: FileManager.default.displayName(atPath: url.path(percentEncoded: false)), description: "Successfully cleared Quarantine Flag", image: NSWorkspace.shared.icon(forFile: url.path(percentEncoded: false)))
                        NotificationManager.shared.display(notification)
                    } catch {
                        presentError(error)
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Open File", systemImage: "arrow.up.forward.app") {
                    importFile.toggle()
                }
                .keyboardShortcut("O", modifiers: .command)
            }
        }
        Settings {
            Form {
                Toggle("Open on Success", isOn: $openOnSuccess)
            }
            .formStyle(.grouped)
        }
    }
}

import ExtendedAttributes

func cleanAndOpenFile(with url: URL) throws {
    try url.extendedAttributes.remove("com.apple.quarantine")
    let bool = UserDefaults.standard.bool(forKey: "openOnSuccess")
    if bool {
            NSWorkspace.shared.open(url)
    }
}
