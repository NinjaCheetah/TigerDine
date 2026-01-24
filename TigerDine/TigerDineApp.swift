//
//  TigerDineApp.swift
//  TigerDine
//
//  Created by Campbell on 8/31/25.
//

import BackgroundTasks
import SwiftUI
import WidgetKit

@main
struct TigerDineApp: App {
    // The model needs to be instantiated here so that it's also available in the context of the refresh background task.
    @State private var model = DiningModel()
    @State private var targetLocationId: Int?
    @State private var handledLocationId: Int?
    
    /// Triggers a refresh on the model that will only make network requests if the cache is stale, and then schedules the next refresh.
    private func handleAppRefresh() async {
        do {
            try await model.getHoursByDayCached()
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("background refresh failed: ", error)
        }
        
        scheduleNextRefresh()
    }
    
    private func parseOpenedURL(url: URL) -> Int? {
        guard url.scheme == "tigerdine" else { return nil }
        
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        if components.path == "/location" {
            print("opening to a location")
            if let queryItems = components.queryItems {
                if queryItems.map(\.name).contains("id") {
                    return Int(queryItems.first(where: { $0.name == "id" })!.value!)
                }
            }
        }
        return nil
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(targetLocationId: $targetLocationId, handledLocationId: $handledLocationId)
                .environment(model)
                .onOpenURL { url in
                    targetLocationId = parseOpenedURL(url: url)
                    handledLocationId = nil
                }
        }
        .backgroundTask(.appRefresh("dev.ninjacheetah.RIT-Dining.refresh")) {
            await handleAppRefresh()
        }
    }
}
