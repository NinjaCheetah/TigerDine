//
//  FoodTruckModel.swift
//  TigerDine
//
//  Created by Campbell Bagley on 10/14/26.
//

import SwiftUI

@Observable
class FoodTruckModel {
    var foodTrucks: [FoodTruck] = []
    
    var loadingState: LoadingState = .loading
    
    init() {
        Task { await getFoodTruckData() }
    }
    
    func getFoodTruckData() async {
        switch await getFoodTruckInfo() {
        case .success(let trucks):
            var newTrucks: [FoodTruck] = []
            for truck in trucks {
                newTrucks.append(parseFoodTruckInfoRM(truck: truck))
            }
            foodTrucks = newTrucks
            loadingState = .loaded
        case .failure(let error):
            print(error)
            loadingState = .failed
        }
    }
    
    func getDatesWithTrucks() -> [Date] {
        var dates: [Date] = []
        
        for truck in foodTrucks {
            for availability in truck.availability {
                if !dates.contains(availability.date) {
                    dates.append(availability.date)
                }
            }
        }
        
        return dates
    }
    
    func getFoodTrucksForDate(date: Date) -> [FoodTruck] {
        var matchingTrucks: [FoodTruck] = []
        
        for truck in foodTrucks {
            for availability in truck.availability {
                if Calendar.current.isDate(availability.date, equalTo: date, toGranularity: .day) {
                    matchingTrucks.append(truck)
                }
            }
        }
        
        return matchingTrucks
    }
}
