//
//  ContentView.swift
//  TigerDine
//
//  Created by Campbell on 8/31/25.
//

import SwiftUI

struct ContentView: View {
    // Save sort/filter options in AppStorage so that they actually get saved.
    @AppStorage("openLocationsOnly") var openLocationsOnly: Bool = false
    @AppStorage("openLocationsFirst") var openLocationsFirst: Bool = false

    @Environment(DiningModel.self) var model
    
    @Binding var targetLocationId: Int?
    @Binding var handledLocationId: Int?
    
    @State private var loadFailed: Bool = false
    @State private var showingDonationSheet: Bool = false
    @State private var searchText: String = ""
    @State private var path = NavigationPath()
    
    // Small wrapper around the method on the model so that errors can be handled by showing the uh error screen.
    private func getDiningData(bustCache: Bool = false) async {
        do {
            if bustCache {
                try await model.getHoursByDay()
            }
            else {
                try await model.getHoursByDayCached()
            }
        } catch {
            loadFailed = true
        }
    }
    
    // Start a perpetually running timer to refresh the open statuses, so that they automatically switch as appropriate without
    // needing to refresh the data. You don't need to yell at the API again to know that the location opening at 11:00 AM should now
    // display "Open" instead of "Opening Soon" now that it's 11:01.
    private func updateOpenStatuses() async {
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
            model.updateOpenStatuses()
            // If the last refreshed date isn't today, that means we probably passed midnight and need to refresh the data.
            // So do that.
            if !Calendar.current.isDateInToday(model.lastRefreshed ?? Date()) {
                Task {
                    await getDiningData()
                }
            }
        }
    }
    
    private func handleOpenDeepLink() {
        guard
            model.isLoaded,
            let targetLocationId,
            handledLocationId != targetLocationId,
            !model.locationsByDay.isEmpty,
            let location = model.locationsByDay[0].first(where: { $0.id == targetLocationId })
            else { return }
        handledLocationId = targetLocationId
        print("TigerDine opened to \(location.name)")
        // Reset the path back to the root (which is here, ContentView).
        path = NavigationPath()
        // Do this in an async block because apparently SwiftUI won't handle these two NavigationPath changes
        // consecutively. Putting the second change in an async block makes it actually update the path the
        // second time.
        DispatchQueue.main.async {
            path.append(location)
            self.targetLocationId = nil
        }
    }
    
    var body: some View {
        NavigationStack(path: $path) {
            if !model.isLoaded {
                VStack {
                    LoadingView(loadFailed: $loadFailed)
                }
            } else {
                VStack() {
                    List {
                        Section(content: {
                            NavigationLink(destination: VisitingChefs()) {
                                Text("Upcoming Visiting Chefs")
                            }
                            NavigationLink(destination: FoodTruckView()) {
                                Text("Weekend Food Trucks")
                            }
                        })
                        Section(content: {
                            // Prevents crashing if the list is empty. Which shouldn't ever happen but still.
                            if !model.locationsByDay.isEmpty {
                                LocationList(
                                    openLocationsFirst: $openLocationsFirst,
                                    openLocationsOnly: $openLocationsOnly,
                                    searchText: $searchText
                                )
                            }
                        }, footer: {
                            if let lastRefreshed = model.lastRefreshed {
                                VStack(alignment: .center) {
                                    Text("Last refreshed: \(lastRefreshed.formatted())")
                                        .foregroundStyle(.secondary)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                        })
                    }
                    .navigationDestination(for: DiningLocation.self) { location in
                        DetailView(locationId: location.id)
                    }
                    .onChange(of: targetLocationId) {
                        handleOpenDeepLink()
                    }
                    .onChange(of: model.isLoaded) {
                        handleOpenDeepLink()
                    }
                }
                .navigationTitle("TigerDine")
                .searchable(text: $searchText, prompt: "Search")
                .refreshable {
                    await getDiningData(bustCache: true)
                }
                .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        NavigationLink(destination: VisitingChefPush()) {
                            Image(systemName: "bell.badge")
                        }
                        Menu {
                            Button(action: {
                                Task {
                                    await getDiningData(bustCache: true)
                                }
                            }) {
                                Label("Refresh", systemImage: "arrow.clockwise")
                            }
                            #if DEBUG
                            Button(action: {
                                model.lastRefreshed = Date(timeIntervalSince1970: 0.0)
                            }) {
                                Label("Invalidate Cache", systemImage: "ant")
                            }
                            #endif
                            Divider()
                            NavigationLink(destination: AboutView()) {
                                Image(systemName: "info.circle")
                                Text("About")
                            }
                            Button(action: {
                                showingDonationSheet = true
                            }) {
                                Label("Donate", systemImage: "heart")
                            }
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                        }
                    }
                    ToolbarItemGroup(placement: .bottomBar) {
                        Menu {
                            Toggle(isOn: $openLocationsOnly) {
                                Label("Hide Closed Locations", systemImage: "eye.slash")
                            }
                            Toggle(isOn: $openLocationsFirst) {
                                Label("Open Locations First", systemImage: "arrow.up.arrow.down")
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease")
                        }
                        if #unavailable(iOS 26.0) {
                            Spacer()
                        }
                    }
                    if #available(iOS 26.0, *) {
                        ToolbarSpacer(.flexible, placement: .bottomBar)
                        DefaultToolbarItem(kind: .search, placement: .bottomBar)
                    }
                }
            }
        }
        .task {
            await getDiningData()
            await updateOpenStatuses()
        }
        .sheet(isPresented: $showingDonationSheet) {
            DonationView()
        }
    }
}

#Preview {
    @Previewable @State var targetLocationId: Int?
    @Previewable @State var handledLocationId: Int?
    
    ContentView(targetLocationId: $targetLocationId, handledLocationId: $handledLocationId)
}
