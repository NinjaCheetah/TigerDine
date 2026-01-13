//
//  HoursGague.swift
//  TigerDineWidgets
//
//  Created by Campbell on 1/8/26.
//

import SwiftUI

struct OpeningHoursGauge: View {
    let openTime: Date?
    let closeTime: Date?
    let now: Date

    private let dayDuration: TimeInterval = 86_400
    
    private var barFillColor: Color {
        let calendar = Calendar.current
        
        if let openTime = openTime, let closeTime = closeTime {
            if now >= openTime && now <= closeTime {
                if closeTime == calendar.date(byAdding: .day, value: 1, to: openTime)! {
                    return Color.green
                } else if closeTime < calendar.date(byAdding: .minute, value: 30, to: now)! {
                    return Color.orange
                } else {
                    return Color.green
                }
            } else if openTime <= calendar.date(byAdding: .minute, value: 30, to: now)! && closeTime > now {
                return Color.orange
            } else {
                return Color.red
            }
        } else {
            return Color.red
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let barHeight: CGFloat = 16
            
            let startOfToday = Calendar.current.startOfDay(for: now)
            let startOfTomorrow = Calendar.current.date(byAdding: .day, value: 1, to: startOfToday)!

            let nowX = position(for: now, start: startOfToday, width: width)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.gray.opacity(0.25))
                    .frame(height: barHeight)

                // We can skip drawing this entire capsule if the location is never open, since there would be no opening period
                // to draw.
                if let openTime = openTime, let closeTime = closeTime {
                    let openX = position(for: openTime, start: startOfToday, width: width)
                    let closeX = position(
                        for: closeTime,
                        start: closeTime < openTime ? startOfTomorrow : startOfToday,
                        width: width
                    )
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [barFillColor.opacity(0.7), barFillColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, closeX - openX), height: barHeight)
                        .offset(x: openX)
                }

                Circle()
                    .fill(Color.white)
                    .frame(width: 18, height: 18)
                    .shadow(radius: 1)
                    .offset(x: nowX - 5)
            }
            .frame(height: 20)
        }
        .frame(height: 20)
    }

    private func position(for date: Date, start: Date, width: CGFloat) -> CGFloat {
        let seconds = date.timeIntervalSince(start)
        let normalized = seconds / dayDuration
        return normalized * width
    }
}
