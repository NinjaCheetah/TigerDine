//
//  HoursGague.swift
//  TigerDineWidgets
//
//  Created by Campbell on 1/8/26.
//

import SwiftUI

struct OpeningHoursGauge: View {
    let diningTimes: [DiningTimes]?
    let now: Date

    private let dayDuration: TimeInterval = 86_400
    
    private var barFillColor: Color {
        if let diningTimes = diningTimes {
            let openStatus = parseMultiOpenStatus(diningTimes: diningTimes)
            switch openStatus {
            case .open:
                return Color.green
            case .closed:
                return Color.red
            case .openingSoon, .closingSoon:
                return Color.orange
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
                if let diningTimes = diningTimes {
                    // Need to iterate here to account for locations that have multiple opening periods (Gracie's/Brick City Cafe).
                    ForEach(diningTimes, id: \.self) { diningTime in
                        let openX = position(for: diningTime.openTime, start: startOfToday, width: width)
                        let closeX = position(
                            for: diningTime.closeTime,
                            start: diningTime.closeTime < diningTime.openTime ? startOfTomorrow : startOfToday,
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
