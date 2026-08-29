//
//  ContentView.swift
//  TigerDine
//
//  Created by Campbell on 8/31/25.
//

import SwiftUI

struct ContentView: View {
    // These are persistent settings, so store them with @AppStorage.
    @AppStorage("openLocationsOnly") var openLocationsOnly: Bool = false
    @AppStorage("openLocationsFirst") var openLocationsFirst: Bool = false

    @Environment(DiningModel.self) var model
    
    @Binding var targetLocationId: Int?
    @Binding var handledLocationId: Int?
    
    @State private var showingDonationSheet: Bool = false
    @State private var hiddenSectionExpanded: Bool = false
    @State private var searchText: String = ""
    @State private var path = NavigationPath()
    
    // This function still sucks and loves to not work, I really gotta fix it eventually. Its
    // purpose is to handle the links given to the app by the widgets, so when you tap on a widget
    // for a given location the app opens to the details for that location.
    private func handleOpenDeepLink() {
        guard
            model.loadingState == .loaded,
            let targetLocationId,
            handledLocationId != targetLocationId,
            !model.locationsByDay.isEmpty,
            let location = model.locationsByDay[0].first(where: { $0.id == targetLocationId })
            else { return }
        
        handledLocationId = targetLocationId
        print("TigerDine opened to \(location.name)")
        
        // Reset the path back to the root (which is here, ContentView).
        path = NavigationPath()
        // Do this in an async block because apparently SwiftUI won't handle these two
        // NavigationPath changes consecutively. Putting the second change in an async block makes
        // it actually update the path the second time.
        DispatchQueue.main.async {
            path.append(location)
            self.targetLocationId = nil
        }
    }
    
    var body: some View {
        NavigationStack(path: $path) {
            if model.loadingState != .loaded {
                VStack {
                    LoadingView(state: model.loadingState)
                }
            } else {
                VStack() {
                    List {
                        Section(content: {
                            NavigationLink(destination: VisitingChefsView()) {
                                Text("Upcoming Visiting Chefs")
                            }
                            
                            NavigationLink(destination: FoodTruckView()) {
                                Text("Weekend Food Trucks")
                            }
                        }, header: {
                            Text(fullTextDateDisplay.string(from: model.lastRefreshed!))
                        })
                        
                        Section(content: {
                            // Prevents crashing if the list is empty. Which shouldn't ever happen,
                            // but still.
                            if !model.locationsByDay.isEmpty {
                                LocationList(
                                    openLocationsFirst: $openLocationsFirst,
                                    openLocationsOnly: $openLocationsOnly,
                                    searchText: $searchText,
                                    hiddenLocations: false
                                )
                            }
                        })
                        
                        // This section is just for showing locations that have been hidden.
                        Section(content: {
                            if hiddenSectionExpanded {
                                if !model.locationsByDay.isEmpty {
                                    LocationList(
                                        openLocationsFirst: $openLocationsFirst,
                                        openLocationsOnly: $openLocationsOnly,
                                        searchText: $searchText,
                                        hiddenLocations: true
                                    )
                                }
                            }
                        }, header: {
                            Button {
                                withAnimation {
                                    hiddenSectionExpanded.toggle()
                                }
                            } label: {
                                HStack {
                                    Text("Hidden Locations")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .rotationEffect(.degrees(hiddenSectionExpanded ? 90 : 0))
                                }
                            }
                            .buttonStyle(.plain)
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
                    .onChange(of: model.loadingState) {
                        handleOpenDeepLink()
                    }
                }
                .navigationTitle("TigerDine")
                .searchable(text: $searchText, prompt: "Search")
                .refreshable {
                    await model.getDiningData(cached: false)
                }
                .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        NavigationLink(destination: VisitingChefsPushView()) {
                            Image(systemName: "bell")
                        }
                        Menu {
                            Button(action: {
                                Task {
                                    await model.getDiningData(cached: false)
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
                            
                            NavigationLink(destination: FeedbackView()) {
                                Label("Feedback", systemImage: "paperplane")
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
