//
//  FoodTruckParticipantsView.swift
//  TigerDine
//
//  Created by Campbell Bagley on 10/12/26.
//

import SwiftUI

struct FoodTruckParticipantsView: View {
    @State private var foodTrucks: [FoodTruck] = []
    @State private var loadingState: LoadingState = .loading
    @State private var safariUrl: IdentifiableURL?
    
    private func doFoodTruckStuff() async {
        switch await getFoodTruckInfo() {
        case .success(let data):
            foodTrucks = data
            loadingState = .loaded
        case .failure(let error):
            print(error)
            loadingState = .failed
        }
    }
    
    
    var body: some View {
        if loadingState != .loaded {
            VStack {
                LoadingView(state: loadingState, loadingType: .truck)
            }
            .task {
                await doFoodTruckStuff()
            }
        } else {
            List {
                ForEach(foodTrucks, id: \.self) { truck in
                    HStack {
                        AsyncImage(url: URL(string: truck.imageUrl)) { image in
                            image.image?.resizable()
                        }
                            .scaledToFit()
                            .frame(width: 75, height: 75)
                        VStack(alignment: .leading) {
                            Text(truck.title)
                            Text(truck.description)
                                .foregroundStyle(.secondary)
                            Button(action: {
                                safariUrl = IdentifiableURL(
                                    url: URL(string: truck.url)!
                                )
                            }) {
                                Text("View Website")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Food Trucks")
            .sheet(item: $safariUrl) { url in
                SafariView(url: url.url)
            }
        }
    }
}
