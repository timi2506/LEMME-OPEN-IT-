//
//  ContentView.swift
//  LEMME OPEN IT!
//
//  Created by Tim on 31.10.25.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Binding var importFile: Bool
    @State var isTargeted = false
    @State var dropLocation: CGPoint?
    @State var blur = false
    @State var workItem: DispatchWorkItem?
    @StateObject var notificationManager = NotificationManager.shared

    var body: some View {
        ZStack(alignment: .top) {
            VStack {
                Image(systemName: "arrow.down.app.dashed")
                    .font(.system(size: 125, weight: .light))
                Text("Drop here")
                    .font(.system(size: 25, weight: .regular))
            }
            .foregroundStyle(isTargeted ? .blue : .primary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(.rect)
            .dropDestination(for: URL.self, action: { items, location in
                blur = false
                dropLocation = location
                for url in items {
                    do {
                        try cleanAndOpenFile(with: url)
                        let notification = CustomNotification(title: FileManager.default.displayName(atPath: url.path(percentEncoded: false)), description: "Successfully cleared Quarantine Flag", image: NSWorkspace.shared.icon(forFile: url.path(percentEncoded: false)))
                        NotificationManager.shared.display(notification)
                    } catch {
                        presentError(error)
                    }
                }
                return true
            }, isTargeted: { bool in
                withAnimation {
                    isTargeted = bool
                }
            })
            .onTapGesture {
                importFile.toggle()
            }
            if let dropLocation {
                Circle()
                    .frame(width: 25, height: 25)
                    .foregroundStyle(.blue)
                    .blur(radius: blur ? 100 : 5)
                    .position(dropLocation)
            }
            ScrollView {
                VStack {
                    if notificationManager.notifications.isEmpty {
                        HStack {
                            Spacer()
                            Text("No Notifications")
                            Spacer()
                        }
                    }
                    ForEach(notificationManager.notifications) { notif in
                        HStack {
                            if let image = notif.image {
                                Image(nsImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 50)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            VStack(alignment: .leading) {
                                Text(notif.title)
                                    .bold()
                                Text(notif.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .top)), removal: .opacity.combined(with: .move(edge: .top))))
                        if notif.id != notificationManager.notifications.last?.id && notificationManager.notifications.count > 1 {
                            Divider()
                        }
                    }
                }
                .background {
                    RoundedRectangle(cornerRadius: 15)
                        .foregroundStyle(.ultraThinMaterial)
                }
                .padding()
                .offset(y: notificationManager.notifications.isEmpty ? -100 : 0)
                .opacity(notificationManager.notifications.isEmpty ? 0 : 1)
            }
            .scrollIndicators(.never)
            .allowsHitTesting(!notificationManager.notifications.isEmpty)
        }
        .onChange(of: dropLocation) { _ in
            blur = false
            withAnimation(.easeIn(duration: 3)) {
                blur = true
            }
            workItem?.cancel()
            workItem = DispatchWorkItem {
                withAnimation {
                    self.dropLocation = nil
                }
            }
            if let workItem {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.5, execute: workItem)
            }
        }
        .onOpenURL { url in
            do {
                try cleanAndOpenFile(with: url)
                let notification = CustomNotification(title: FileManager.default.displayName(atPath: url.path(percentEncoded: false)), description: "Successfully cleared Quarantine Flag", image: NSWorkspace.shared.icon(forFile: url.path(percentEncoded: false)))
                NotificationManager.shared.display(notification)
            } catch {
                presentError(error)
            }
        }
    }
}

func presentError(_ error: Error) {
    let alert = NSAlert(error: error)
    alert.messageText = "An Error occured"
    alert.informativeText = error.localizedDescription
    alert.alertStyle = .critical
    alert.icon = NSApplication.shared.applicationIconImage
    alert.runModal()
}

import Combine

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    @Published var notifications: [CustomNotification] = []
    func display(_ notif: CustomNotification) {
        withAnimation {
            notifications.append(notif)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                self.notifications.removeAll(where: { $0.id == notif.id })
            }
        }
    }
}

struct CustomNotification: Hashable, Identifiable {
    init(id: UUID = UUID(), title: String, description: String, image: NSImage? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.image = image
    }
    var id = UUID()
    var title: String
    var description: String
    var image: NSImage?
}

#Preview {
    ContentView(importFile: .constant(false))
}
