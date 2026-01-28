//
//  LoadingView.swift
//  TigerDine
//
//  Created by Campbell on 1/24/26.
//

import SwiftUI

enum LoadingType {
    case normal
    case truck
}

struct LoadingView: View {
    @Binding var loadFailed: Bool
    @State var loadingType: LoadingType = .normal
    
    @State private var rotationDegrees: Double = 0
    @State private var loadingText: String = ""
    
    private var animation: Animation {
        .linear
        .speed(0.1)
        .repeatForever(autoreverses: false)
    }
    
    private var loadingSymbol: String {
        switch loadingType {
        case .normal:
            return "fork.knife.circle"
        case .truck:
            return "truck.box"
        }
    }
    
    var loadingTextOptions: [String] = [
        "Loading...",
        "One moment...",
        "Hang tight...",
        "Just a moment...",
    ]
    
    var body: some View {
        VStack {
            if loadFailed {
                Image(systemName: "wifi.exclamationmark.circle")
                    .resizable()
                    .frame(width: 75, height: 75)
                    .foregroundStyle(.accent)
                Text("An error occurred while loading data. Please check your network connection and try again.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Image(systemName: loadingSymbol)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 75, height: 75)
                    .foregroundStyle(.accent)
                    .rotationEffect(.degrees(rotationDegrees))
                    .onAppear {
                        withAnimation(animation) {
                            rotationDegrees = 360.0
                        }
                    }
                Text(loadingText)
                    .foregroundStyle(.secondary)
                    .onAppear {
                        loadingText = loadingTextOptions.randomElement() ?? ""
                    }
            }
        }
        .padding()
    }
}
