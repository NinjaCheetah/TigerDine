//
//  FoodTruckView.swift
//  TigerDine
//
//  Created by Campbell on 10/5/25.
//

import SwiftUI
import SafariServices

struct FoodTruckView: View {
    @State private var foodTruckEvents: [FoodTruckEvent] = []
    @State private var isLoading: Bool = true
    @State private var loadFailed: Bool = false
    @State private var showingSafari: Bool = false
    
    private func doFoodTruckStuff() async {
        switch await getFoodTruckPage() {
        case .success(let schedule):
            foodTruckEvents = parseWeekendFoodTrucks(htmlString: schedule)
            isLoading = false
        case .failure(let error):
            print(error)
            loadFailed = true
        }
    }
    
    var body: some View {
        if isLoading {
            VStack {
                LoadingView(loadFailed: $loadFailed, loadingType: .truck)
            }
            .task {
                await doFoodTruckStuff()
            }
        } else {
            ScrollView {
                VStack(alignment: .leading) {
                    Text("Weekend Food Trucks")
                        .font(.title)
                        .fontWeight(.semibold)
                    ForEach(foodTruckEvents, id: \.self) { event in
                        Divider()
                        Text(visitingChefDateDisplay.string(from: event.date))
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("\(dateDisplay.string(from: event.openTime)) - \(dateDisplay.string(from: event.closeTime))")
                            .font(.title3)
                        ForEach(event.trucks, id: \.self) { truck in
                            Text(truck)
                        }
                        Spacer()
                    }
                    Spacer()
                    Text("Food truck data is sourced directly from the RIT Events website, and may not be presented correctly. Use the globe button in the top right to access the RIT Events website directly to see the original source of the information.")
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 8)
            }
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button(action: {
                        showingSafari = true
                    }) {
                        Image(systemName: "network")
                    }
                }
            }
            .sheet(isPresented: $showingSafari) {
                SafariView(url: URL(string: "https://www.rit.edu/events/weekend-food-trucks")!)
            }
        }
    }
}
