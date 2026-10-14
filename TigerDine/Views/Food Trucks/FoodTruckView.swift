//
//  FoodTruckView.swift
//  TigerDine
//
//  Created by Campbell on 10/5/25.
//

import SwiftUI

struct FoodTruckView: View {
    @State var model: FoodTruckModel = FoodTruckModel()
    @State private var loadingState: LoadingState = .loading
    @State private var safariUrl: IdentifiableURL?
    
    var body: some View {
        if model.loadingState != .loaded {
            VStack {
                LoadingView(state: loadingState, loadingType: .truck)
            }
        } else {
            List {
                Section {
                    NavigationLink(destination: FoodTruckParticipantsView(model: model)) {
                        Text("All Participating Food Trucks")
                    }
                }
                
                ForEach(model.getDatesWithTrucks(), id: \.self) { date in
                    Section(
                        header: Text(visitingChefDateDisplay.string(from: date))
                    ) {
                        ForEach(model.getFoodTrucksForDate(date: date), id: \.self) { truck in
                            let calendar = Calendar.current
                            
                            let availability = truck.availability.filter { t in
                                calendar.isDate(t.date, equalTo: date, toGranularity: .day)
                            }.first! // There should only be one match here anyway.
                            
                            HStack(alignment: .top) {
                                HStack {
                                    AsyncImage(url: URL(string: truck.imageUrl)) { image in
                                        image.image?
                                            .resizable()
                                        // Apply the alt text we're provided for the logo.
                                            .accessibilityLabel(truck.imageAltTag)
                                    }
                                        .scaledToFit()
                                        .frame(width: 75, height: 75)
                                    VStack(alignment: .leading) {
                                        Text(truck.name)
                                        Text("\(dateDisplay.string(from: availability.openTime)) - \(dateDisplay.string(from: availability.closeTime))")
                                            .foregroundStyle(.secondary)
                                        Button(action: {
                                            safariUrl = IdentifiableURL(
                                                url: URL(string: availability.mapsUrl)!
                                            )
                                        }) {
                                            Text(availability.locationName)
                                        }
                                        Text(truck.description)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .opacity(calendar.compare(date, to: .now, toGranularity: .day) == .orderedAscending ? 0.3 : 1.0)
                        }
                    }
                }
            }
            .navigationTitle("Weekend Food Trucks")
            .sheet(item: $safariUrl) { url in
                SafariView(url: url.url)
            }
        }
    }
}

#Preview {
    let previewModel = FoodTruckModel()
    
    let foodTrucks: [FoodTruck] = [
        FoodTruck(
            id: 115541,
            name: "Bento Stop ROC",
            description: "",
            imageUrl: "https://www.rit.edu/dining/sites/rit.edu.dining/files/styles/medium/public/images/food-truck/BentoStop.jpg?itok=PFqm6pw-",
            imageAltTag: "Bento Stop ROC logo featuring bold red lettering, a rice bowl illustration, and crossed chopsticks.",
            url: "https://www.facebook.com/people/Bento-Stop-ROC/61590981985013/",
            availability: []
        ),
        FoodTruck(
            id: 115538,
            name: "Bubble Waffle Bus",
            description: "Delicious ice cream sundaes on bubble waffles!",
            imageUrl: "https://www.rit.edu/dining/sites/rit.edu.dining/files/styles/medium/public/images/food-truck/BWB.jpg?itok=r2ySemW8",
            imageAltTag: "Bubble Waffle Bus logo featuring colorful bubble-style lettering topped with waffles, fruit, and whipped cream.",
            url: "https://www.facebook.com/people/Bubble-Waffle-Bus/61574352321698/",
            availability: [
                FoodTruckAvailability(
                    date: Date(timeIntervalSince1970: 1792108800),
                    openTime: Date(timeIntervalSince1970: 1792184400),
                    closeTime: Date(timeIntervalSince1970: 1792195200),
                    mapsUrl: "https://maps.rit.edu/details/1020",
                    locationName: "Student Alumni Union",
                    location: ""
                )
            ]
        ),
        FoodTruck(
            id: 115461,
            name: "Macarollin",
            description: "Gourmet mac and cheese bowls",
            imageUrl: "https://www.rit.edu/dining/sites/rit.edu.dining/files/styles/medium/public/images/food-truck/Macarollin.webp?itok=VLQTm81h",
            imageAltTag: "Macarollin logo displayed in green and orange stylized lettering on an orange gradient background",
            url: "https://www.macarollin.com/",
            availability: [
                FoodTruckAvailability(
                    date: Date(timeIntervalSince1970: 1792108800),
                    openTime: Date(timeIntervalSince1970: 1792184400),
                    closeTime: Date(timeIntervalSince1970: 1792195200),
                    mapsUrl: "https://maps.rit.edu/details/1020",
                    locationName: "SAU",
                    location: ""
                )
            ]
        ),
        FoodTruck(
            id: 115464,
            name: "Melt",
            description: "Freshly melted grilled cheese sandwiches",
            imageUrl: "https://www.rit.edu/dining/sites/rit.edu.dining/files/styles/medium/public/images/food-truck/Melt.webp?itok=jXSSY2Nn",
            imageAltTag: "Melt logo",
            url: "https://melttruckroc.com/",
            availability: [
                FoodTruckAvailability(
                    date: Date(timeIntervalSince1970: 1792108800),
                    openTime: Date(timeIntervalSince1970: 1792184400),
                    closeTime: Date(timeIntervalSince1970: 1792195200),
                    mapsUrl: "https://maps.rit.edu/details/1020",
                    locationName: "SAU",
                    location: ""
                )
            ]
        ),
        FoodTruck(
            id: 115488,
            name: "Schutt's Apple Mill",
            description: "Mini fried cakes.",
            imageUrl: "https://www.rit.edu/dining/sites/rit.edu.dining/files/styles/medium/public/images/food-truck/SchuttsAppleMill.webp?itok=SP3FLccU",
            imageAltTag: "Schutt's Apple Mill logo",
            url: "https://schuttsapplemill.com/",
            availability: [
                FoodTruckAvailability(
                    date: Date(timeIntervalSince1970: 1792195200),
                    openTime: Date(timeIntervalSince1970: 1792269000),
                    closeTime: Date(timeIntervalSince1970: 1792276200),
                    mapsUrl: "https://maps.rit.edu/details/1318",
                    locationName: "Global Village",
                    location: ""
                )
            ]
        ),
        FoodTruck(
            id: 115467,
            name: "Tuscan Wood Fired Pizza",
            description: "Wood fired pizzas ",
            imageUrl: "https://www.rit.edu/dining/sites/rit.edu.dining/files/styles/medium/public/images/food-truck/TuscanWoodFiredPizza_0.webp?itok=TCuqUNKb",
            imageAltTag: "Tuscan Wood Fired Pizza logo",
            url: "https://www.tuscanwf.com/",
            availability: [
                FoodTruckAvailability(
                    date: Date(timeIntervalSince1970: 1792195200),
                    openTime: Date(timeIntervalSince1970: 1792269000),
                    closeTime: Date(timeIntervalSince1970: 1792276200),
                    mapsUrl: "https://maps.rit.edu/details/1318",
                    locationName: "Global Village",
                    location: ""
                )
            ]
        )
    ]
    
    previewModel.foodTrucks = foodTrucks
    
    return NavigationStack {
        FoodTruckView(model: previewModel)
    }
}
