//
//  Requests.swift
//  TigerDine
//
//  Created by Campbell on 8/31/25.
//

import Foundation

enum InvalidHTTPError: Error {
    case invalid
}

// This code has now been mostly rewritten to be pretty and async instead of being horrifying
// callback based code in a context where callback based code made no sense. I love async!
// Get information for all dining locations.
func getAllDiningInfoTC(date: Date?) async -> Result<DiningLocationsParser, Error> {
    // The endpoint requires that you specify a date, so get today's if we don't have one.
    let dateString: String = getTCAPIFriendlyDateString(date: date ?? Date())
    let urlString = "https://tigercenter.rit.edu/tigerCenterApi/tc/dining-all?date=\(dateString)"
//    let urlString = "https://tigercenter.rit.edu/tigerCenterApi/tc/dining-all?date=2026-04-24"
    
    guard let url = URL(string: urlString) else {
        return .failure(URLError(.badURL))
    }
    
    do {
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            return .failure(InvalidHTTPError.invalid)
        }
        
        let decoded = try JSONDecoder().decode(DiningLocationsParser.self, from: data)
        return .success(decoded)
    } catch {
        return .failure(error)
    }
}

func getAllDiningInfoRM() async -> Result<[DiningLocationRMParser], Error> {
    // This endpoint does *not* require a date, it fetches data for a 2 week span no matter what.
    let urlString = "https://www.rit.edu/feeds/mobile-app/dining-all.php"
    print("making request to RIT Mobile API")
    
    guard let url = URL(string: urlString) else {
        return .failure(URLError(.badURL))
    }
    
    do {
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            return .failure(InvalidHTTPError.invalid)
        }
        
        let decoded = try JSONDecoder().decode([DiningLocationRMParser].self, from: data)
        return .success(decoded)
    } catch {
        print("hit an error: \(error)")
        return .failure(error)
    }
}

// Get information for just one dining location based on its location ID.
func getSingleDiningInfo(date: String?, locId: Int) async -> Result<DiningLocationTCParser, Error> {
    // The current date and the location ID are required to get information for just one location.
    let dateString: String = date ?? getTCAPIFriendlyDateString(date: Date())
    let urlString = "https://tigercenter.rit.edu/tigerCenterApi/tc/dining-single?date=\(dateString)&locId=\(locId)"
    print("making request to \(urlString)")

    guard let url = URL(string: urlString) else {
        return .failure(URLError(.badURL))
    }

    do {
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            return .failure(InvalidHTTPError.invalid)
        }
        
        let decoded = try JSONDecoder().decode(DiningLocationTCParser.self, from: data)
        return .success(decoded)
    } catch {
        return .failure(error)
    }
}

// Get the occupancy information for a location using its MDO ID, whatever that stands for. This ID
// is provided alongside the other main ID in the data returned by the TigerCenter API.
func getOccupancyPercentage(mdoId: Int) async -> Result<Double, Error> {
    let urlString = "https://maps.rit.edu/proxySearch/densityMapDetail.php?mdo=\(mdoId)"
    print("making request to \(urlString)")
    
    guard let url = URL(string: urlString) else {
        return .failure(URLError(.badURL))
    }
    
    do {
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            return .failure(InvalidHTTPError.invalid)
        }
        
        let occupancy = try JSONDecoder().decode([DiningOccupancyParser].self, from: data)
        if !occupancy.isEmpty {
            print("current occupancy: \(occupancy[0].count)")
            print("maximum occupancy: \(occupancy[0].max_occ)")
            let occupancyPercentage = Double(occupancy[0].count) / Double(occupancy[0].max_occ) * 100
            print("occupancy percentage: \(occupancyPercentage)%")
            return .success(occupancyPercentage)
        } else {
            return .failure(DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Failed to decode JSON")))
        }
    } catch {
        return .failure(error)
    }
}

func getFoodTruckInfo() async -> Result<[FoodTruckRMParser], Error> {
    let urlString = "https://www.rit.edu/dining/feeds/mobile-app/food-trucks.php?showAll=1"
    print("making request to \(urlString)")
    
    guard let url = URL(string: urlString) else {
        return .failure(URLError(.badURL))
    }

    do {
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            return .failure(InvalidHTTPError.invalid)
        }
        
        let decoded = try JSONDecoder().decode([FoodTruckRMParser].self, from: data)
        return .success(decoded)
    } catch {
        return .failure(error)
    }
}

func searchFDMealPlannerLocations() async -> Result<FDSearchResponseParser, Error> {
    let urlString = "https://locations.fdmealplanner.com/api/v1/location-data-webapi/search-locationByAccount?AccountShortName=RIT&pageIndex=1&pageSize=0"
    
    guard let url = URL(string: urlString) else {
        return .failure(URLError(.badURL))
    }

    do {
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            return .failure(InvalidHTTPError.invalid)
        }
        
        let decoded = try JSONDecoder().decode(FDSearchResponseParser.self, from: data)
        return .success(decoded)
    } catch {
        return .failure(error)
    }
}

func getFDMealPlannerOpenings(locationId: Int) async -> Result<FDMealPeriodsParser, Error> {
    let urlString = "https://apiservicelocatorstenantrit.fdmealplanner.com/api/v1/data-locator-webapi/20/mealPeriods?LocationId=\(locationId)"
    print("making request to \(urlString)")
    
    guard let url = URL(string: urlString) else {
        return .failure(URLError(.badURL))
    }

    do {
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            return .failure(InvalidHTTPError.invalid)
        }
        
        let decoded = try JSONDecoder().decode(FDMealPeriodsParser.self, from: data)
        return .success(decoded)
    } catch {
        return .failure(error)
    }
}

func getFDMealPlannerMenu(locationId: Int, accountId: Int, mealPeriodId: Int) async -> Result<FDMealsParser, Error> {
    let dateString = getFDMPAPIFriendlyDateString(date: Date())
    let urlString = "https://apiservicelocatorstenantrit.fdmealplanner.com/api/v1/data-locator-webapi/20/meals?menuId=0&accountId=\(accountId)&locationId=\(locationId)&mealPeriodId=\(mealPeriodId)&tenantId=20&monthId=\(Calendar.current.component(.month, from: Date()))&startDate=\(dateString)&endDate=\(dateString)"
    print("making request to \(urlString)")
    
    guard let url = URL(string: urlString) else {
        return .failure(URLError(.badURL))
    }

    do {
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            return .failure(InvalidHTTPError.invalid)
        }
        
        let decoded = try JSONDecoder().decode(FDMealsParser.self, from: data)
        return .success(decoded)
    } catch {
        return .failure(error)
    }
}
