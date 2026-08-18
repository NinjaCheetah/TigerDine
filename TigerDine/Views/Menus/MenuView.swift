//
//  MenuView.swift
//  TigerDine
//
//  Created by Campbell on 11/3/25.
//

import SwiftUI

struct MenuView: View {
    @State var accountId: Int
    @State var locationId: Int
    @State private var menuItems: [FDMenuItem] = []
    @State private var conceptToItemsMap: [String: [Int]] = [:]
    @State private var searchText: String = ""
    @State private var isLoading: Bool = true
    @State private var loadFailed: Bool = false
    @State private var selectedMealPeriod: Int = 0
    @State private var openPeriods: [Int] = []
    @StateObject private var dietaryRestrictionsModel = MenuDietaryRestrictionsModel()
    @State private var showingDietaryRestrictionsSheet: Bool = false
    
    func getOpenPeriods() async {
        // Only run this if we haven't already gotten the open periods. This is somewhat of a
        // bandaid solution to the issue of fetching this information more than once, but hey it
        // works!
        if openPeriods.isEmpty {
            switch await getFDMealPlannerOpenings(locationId: locationId) {
            case .success(let openingResults):
                openPeriods = openingResults.data.map { Int($0.id) }
                selectedMealPeriod = openPeriods[0]
                // Since this only runs once when the view first loads, we can safely use this to
                // call the method to get the data the first time. This also ensures that it doesn't
                // happen until we have the opening periods collected.
                await getMenuForPeriod(mealPeriodId: selectedMealPeriod)
            case .failure(let error):
                print(error)
                loadFailed = true
            }
        }
    }
    
    func getMenuForPeriod(mealPeriodId: Int) async {
        switch await getFDMealPlannerMenu(locationId: locationId, accountId: accountId, mealPeriodId: mealPeriodId) {
        case .success(let menus):
            let parseResults = parseFDMealPlannerMenu(menuRaw: menus)
            menuItems = parseResults.0
            conceptToItemsMap = parseResults.1
            isLoading = false
        case .failure(let error):
            print(error)
            loadFailed = true
        }
    }
    
    private var filteredMenuItems: [FDMenuItem] {
        var newItems = menuItems
        // Filter out allergens.
        newItems = newItems.filter { item in
            if !item.allergens.isEmpty {
                for allergen in item.allergens {
                    if let checkingAllergen = Allergen(rawValue: allergen.lowercased()) {
                        if dietaryRestrictionsModel.dietaryRestrictions.contains(checkingAllergen) {
                            return false
                        }
                    }
                }
            }
            return true
        }
        // Filter down to vegetarian/vegan only if enabled.
        if dietaryRestrictionsModel.isVegetarian || dietaryRestrictionsModel.isVegan {
            newItems = newItems.filter { item in
                if dietaryRestrictionsModel.isVegetarian && (item.dietaryMarkers.contains("Vegetarian") || item.dietaryMarkers.contains("Vegan")) {
                    return true
                } else if dietaryRestrictionsModel.isVegan && (item.dietaryMarkers.contains("Vegan")) {
                    return true
                }
                return false
            }
        }
        // Filter out pork/beef.
        if dietaryRestrictionsModel.noBeef {
            newItems = newItems.filter { item in
                item.dietaryMarkers.contains("Beef") == false
            }
        }
        if dietaryRestrictionsModel.noPork {
            newItems = newItems.filter { item in
                item.dietaryMarkers.contains("Pork") == false
            }
        }
        // Filter down to search contents.
        newItems = newItems.filter { item in
            let searchedLocations = searchText.isEmpty || item.name.localizedCaseInsensitiveContains(searchText)
            return searchedLocations
        }
        newItems.sort { firstItem, secondItem in
            return firstItem.name.localizedCaseInsensitiveCompare(secondItem.name) == .orderedAscending
        }
        return newItems
    }
    
    var body: some View {
        if isLoading {
            VStack {
                LoadingView(loadFailed: $loadFailed)
            }
            .task {
                await getOpenPeriods()
            }
        } else {
            VStack {
                if !menuItems.isEmpty {
                    List {
                        ForEach(conceptToItemsMap.keys.sorted(), id: \.self) { concept in
                            let itemsForConcept = filteredMenuItems.filter { item in
                                conceptToItemsMap[concept, default: []].contains(item.id)
                            }
                            
                            if !itemsForConcept.isEmpty {
                                Section(
                                    header: Text(concept)
                                ) {
                                    ForEach(itemsForConcept) { item in
                                        NavigationLink(destination: MenuItemView(menuItem: item)) {
                                            MenuItemRow(item: item)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .navigationTitle("Menu")
                    .navigationBarTitleDisplayMode(.large)
                    .searchable(text: $searchText, prompt: "Search")
                } else {
                    Image(systemName: "clock.badge.exclamationmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 75, height: 75)
                        .foregroundStyle(.accent)
                    Text("No menu is available for the selected meal period today. Try selecting a different meal period.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Picker("Meal Period", selection: $selectedMealPeriod) {
                            ForEach(openPeriods, id: \.self) { period in
                                Text(fdmpMealPeriodsMap[period]!).tag(period)
                            }
                        }
                    } label: {
                        Image(systemName: "clock")
                        Text("Meal Periods")
                    }
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    Button(action: {
                        showingDietaryRestrictionsSheet = true
                    }) {
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
            .onChange(of: selectedMealPeriod) {
                isLoading = true
                Task {
                    await getMenuForPeriod(mealPeriodId: selectedMealPeriod)
                }
            }
            .sheet(isPresented: $showingDietaryRestrictionsSheet) {
                MenuDietaryRestrictionsSheet(dietaryRestrictionsModel: dietaryRestrictionsModel)
            }
        }
    }
}

private struct MenuItemRow: View {
    let item: FDMenuItem
    
    private func badgeColor(for marker: String) -> Color {
        switch marker {
        case "Vegan", "Vegetarian":
            return .green
        default:
            return .orange
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(item.name)
            
            HStack {
                ForEach(item.dietaryMarkers, id: \.self) { dietaryMarker in
                    Text(dietaryMarker)
                        .foregroundStyle(Color.white)
                        .font(.caption)
                        .padding(4)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(badgeColor(for: dietaryMarker))
                        )
                }
            }
            
            Text("\(item.calories) Cal")
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    MenuView(accountId: 1, locationId: 1)
}
