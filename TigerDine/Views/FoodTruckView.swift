//
//  FoodTruckView.swift
//  TigerDine
//
//  Created by Campbell on 10/5/25.
//

import SwiftUI
import SafariServices

struct FoodTruckView: View {
    @State private var foodTruckEvents: [Date: [FoodTruckEvent]] = [:]
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
    
    private var foodTruckEventsByDay: [[FoodTruckEvent]] {
        foodTruckEvents
            .sorted(by: { $0.key < $1.key })
            .map(\.value)
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
            List {
                ForEach(foodTruckEventsByDay, id: \.self) { day in
                    Section(
                        header: Text(visitingChefDateDisplay.string(from: day[0].date))
                    ) {
                        ForEach(day, id: \.self) { event in
                            let calendar = Calendar.current
                            
                            HStack(alignment: .top) {
                                VStack(alignment: .leading) {
                                    ForEach(event.trucks, id: \.self) { truck in
                                        Text(truck)
                                    }
                                }
                                
                                Spacer()
                                
                                Text("\(dateDisplay.string(from: event.openTime)) - \(dateDisplay.string(from: event.closeTime))")
                                    .foregroundStyle(.secondary)
                            }
                            .opacity(calendar.component(.day, from: day[0].date)
                                     < calendar.component(.day, from: .now) ? 0.3 : 1.0)
                        }
                    }
                }
                
                Section {
                    Text("Food truck data is sourced directly from the RIT Events website, and " +
                         "may not always display correctly. Use the globe button in the top " +
                         "right to access the RIT Events website directly to see the original " +
                         "source for this information.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 8, bottom: 8, trailing: 8))
                .listRowBackground(Color.clear)
            }
            .navigationTitle("Weekend Food Trucks")
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
