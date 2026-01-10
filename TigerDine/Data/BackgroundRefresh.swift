//
//  BackgroundRefresh.swift
//  TigerDine
//
//  Created by Campbell on 1/9/26.
//

import SwiftUI
import BackgroundTasks

/// This is the global function used to tell iOS that we want to schedule a new instance of the background refresh task. It's used both in the main app to automatically reschedule a task when one completes, and also within the dining model to schedule a task when a refresh finishes.
func scheduleNextRefresh() {
    let request = BGAppRefreshTaskRequest(
        identifier: "dev.ninjacheetah.RIT-Dining.refresh"
    )
    
    // Refresh NO SOONER than 6 hours from now. That's not super important since the task will exit pretty much immediately
    // if the cache is still fresh, but we really don't need to try more frequently than this so don't bother.
    request.earliestBeginDate = Date(timeIntervalSinceNow: 6 * 60 * 60)
    
    do {
        try BGTaskScheduler.shared.submit(request)
    } catch {
        print("failed to schedule background refresh: ", error)
    }
}
