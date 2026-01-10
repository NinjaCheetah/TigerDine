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
    
    /// Triggers a refresh on the model that will only make network requests if the cache is stale, and then schedules the next refresh.
    func handleAppRefresh() async {
        do {
            try await model.getHoursByDayCached()
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("background refresh failed: ", error)
        }
        
        scheduleNextRefresh()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(model)
        }
        .backgroundTask(.appRefresh("dev.ninjacheetah.RIT-Dining.refresh")) {
            await handleAppRefresh()
        }
    }
}
