//
//  FoodTruckParticipantsView.swift
//  TigerDine
//
//  Created by Campbell Bagley on 10/12/26.
//

import SwiftUI

struct FoodTruckParticipantsView: View {
    @State var model: FoodTruckModel
    @State private var safariUrl: IdentifiableURL?

    var body: some View {
        List {
            ForEach(model.foodTrucks, id: \.self) { truck in
                HStack {
                    AsyncImage(url: URL(string: truck.imageUrl)) { image in
                        image.image?.resizable()
                    }
                        .scaledToFit()
                        .frame(width: 75, height: 75)
                    VStack(alignment: .leading) {
                        Text(truck.name)
                        if truck.description != "" {
                            Text(truck.description)
                                .foregroundStyle(.secondary)
                        }
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
        .navigationTitle("All Food Trucks")
        .sheet(item: $safariUrl) { url in
            SafariView(url: url.url)
        }
    }
}
