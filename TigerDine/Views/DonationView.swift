//
//  DonationView.swift
//  TigerDine
//
//  Created by Campbell on 9/17/25.
//

import SwiftUI

struct DonationView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) private var openURL
    
    @State private var symbolHidden: Bool = true
    @State private var symbolFilled: Bool = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    VStack(alignment: .center, spacing: 12) {
                        if #available(iOS 26.0, *) {
                            Image(systemName: symbolFilled ? "heart.fill" : "heart")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 64, height: 64)
                                .foregroundStyle(.red)
                                .symbolEffect(.drawOn, isActive: symbolHidden)
                                .contentTransition(.symbolEffect(.replace.downUp))
                                .onAppear {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                                        symbolHidden = false
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                            symbolFilled = true
                                        }
                                    }
                                }
                        } else {
                            Image(systemName: "heart.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 64, height: 64)
                                .foregroundStyle(.red)
                        }
                        Text("Donate")
                            .fontWeight(.bold)
                            .font(.title)
                        Text("The TigerDine app is free and open source software!")
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                        Text("However, the Apple Developer Program is expensive, and I have to pay $100/year to keep this app on the App Store. If you can, I'd appreciate it if you wouldn't mind tossing a coin or two my way to help and make that expense a little less painful.")
                            .multilineTextAlignment(.center)
                        Text("No pressure though.")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                }
                .listRowBackground(Color.clear)
                .frame(maxWidth: .infinity)
                
                Section {
                    Button(action: {
                        openURL(URL(string: "https://ko-fi.com/ninjacheetah")!)
                    }) {
                        HStack(alignment: .center) {
                            Image("kofiLogo")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            VStack(alignment: .leading) {
                                Text("Tip Me on Ko-fi")
                                Text("Chip in as much or as little as you'd like!")
                                    .foregroundStyle(.secondary)
                                    .font(.subheadline)
                            }
                            Spacer()
                            Image(systemName: "chevron.forward")
                        }
                    }
                    .buttonStyle(.plain)
                    Button(action: {
                        openURL(URL(string: "https://paypal.me/NinjaCheetahX")!)
                    }) {
                        HStack(alignment: .center) {
                            Image("paypalLogo")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            VStack(alignment: .leading) {
                                Text("Send Me Money Directly")
                                Text("PayPal won't take a cut!")
                                    .foregroundStyle(.secondary)
                                    .font(.subheadline)
                            }
                            Spacer()
                            Image(systemName: "chevron.forward")
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .toolbar {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                }
            }
        }
    }
}

#Preview {
    DonationView()
}
