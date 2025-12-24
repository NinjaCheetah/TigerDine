//
//  VisitingChefsPush.swift
//  TigerDine
//
//  Created by Campbell on 10/1/25.
//

import SwiftUI

struct VisitingChefPush: View {
    @AppStorage("visitingChefPushEnabled") var pushEnabled: Bool = false
    @AppStorage("notificationOffset") var notificationOffset: Int = 2
    @Environment(DiningModel.self) var model
    @State private var pushAllowed: Bool = false
    private let visitingChefs = [
        "California Rollin' Sushi",
        "D'Mangu",
        "Esan's Kitchen",
        "Halal n Out",
        "just chik'n",
        "KO-BQ",
        "Macarollin'",
        "P.H. Express",
        "Tandoor of India"
    ]
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("Visiting Chef Notifications"),
                    footer: Text(!pushAllowed ? "You must allow notifications from TigerDine to use this feature." : "")) {
                    Toggle(isOn: $pushEnabled) {
                        Text("Notifications Enabled")
                    }
                    .disabled(!pushAllowed)
                    .onChange(of: pushEnabled) {
                        if pushEnabled {
                            Task {
                                await model.scheduleAllPushes()
                            }
                        } else {
                            Task {
                                await model.cancelAllPushes()
                            }
                        }
                    }
                    Picker("Send Notifications", selection: $notificationOffset) {
                        Text("1 Hour Before").tag(1)
                        Text("2 Hours Before").tag(2)
                        Text("3 Hours Before").tag(3)
                    }
                    .disabled(!pushAllowed || !pushEnabled)
                    .onChange(of: notificationOffset) {
                        Task {
                            // If we changed the offset, we need to reschedule everything.
                            await model.cancelAllPushes()
                            await model.scheduleAllPushes()
                        }
                    }
                }
                Section(footer: Text("Get notified when and where a specific visiting chef will be on campus.")) {
                    ForEach(visitingChefs, id: \.self) { chef in
                        Toggle(isOn: Binding(
                            get: {
                                model.notifyingChefs.contains(chef)
                            },
                            set: { isOn in
                                if isOn {
                                    model.notifyingChefs.add(chef)
                                    Task {
                                        await model.schedulePushesForChef(chef)
                                    }
                                } else {
                                    model.notifyingChefs.remove(chef)
                                    model.visitingChefPushes.cancelPushesForChef(name: chef)
                                }
                            }
                        )) {
                            Text(chef)
                        }
                    }
                }
                .disabled(!pushAllowed || !pushEnabled)
                #if DEBUG
                Section(header: Text("DEBUG - Scheduled Pushes")) {
                    Button(action: {
                        Task {
                            await model.scheduleAllPushes()
                        }
                    }) {
                        Text("Schedule All")
                    }
                    Button(action: {
                        let uuids = model.visitingChefPushes.pushes.map(\.uuid)
                        Task {
                            await cancelVisitingChefNotifs(uuids: uuids)
                            model.visitingChefPushes.pushes.removeAll()
                        }
                    }) {
                        Text("Cancel All")
                    }
                    .tint(.red)
                    ForEach(model.visitingChefPushes.pushes, id: \.uuid) { push in
                        VStack(alignment: .leading) {
                            Text("\(push.name) at \(push.location)")
                            Text(push.uuid)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(push.startTime) - \(push.endTime)")
                                .foregroundStyle(.secondary)
                        }
                        .swipeActions {
                            Button(action: {
                                Task {
                                    await cancelVisitingChefNotifs(uuids: [push.uuid])
                                    model.visitingChefPushes.pushes.remove(at: model.visitingChefPushes.pushes.firstIndex(of: push)!)
                                }
                            }) {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(.red)
                        }
                    }
                }
                #endif
            }
        }
        .onAppear {
            Task {
                let center = UNUserNotificationCenter.current()
                do {
                    try await center.requestAuthorization(options: [.alert, .sound])
                } catch {
                    print(error)
                }
                let settings = await center.notificationSettings()
                guard (settings.authorizationStatus == .authorized) else { pushEnabled = false; return }
                pushAllowed = true
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    VisitingChefPush()
}
