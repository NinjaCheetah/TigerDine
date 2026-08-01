//
//  AboutView.swift
//  TigerDine
//
//  Created by Campbell on 9/12/25.
//

import SwiftUI

struct AboutView: View {
    @Environment(\.openURL) private var openURL
    let appVersionString: String =
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    let buildNumber: String =
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
    let copyrightString: String =
        Bundle.main.object(forInfoDictionaryKey: "NSHumanReadableCopyright") as! String
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .center, spacing: 8) {
                    Image("Icon")
                        .resizable()
                        .frame(width: 128, height: 128)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    
                    VStack(alignment: .center, spacing: 2) {
                        Text("TigerDine for iOS")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("An unofficial RIT Dining app")
                            .font(.subheadline)
                    }
                    
                    VStack(alignment: .center, spacing: 2) {
                        Text("Version \(appVersionString) (\(buildNumber))")
                            .foregroundStyle(.secondary)
                        
                        Text(copyrightString)
                            .foregroundStyle(.secondary)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            }
            
            Section(header: Text("Links")) {
                Button(action: {
                    openURL(URL(string: "https://github.com/NinjaCheetah/TigerDine")!)
                }) {
                    Label("Source Code", systemImage: "network")
                }
                
                Button(action: {
                    openURL(URL(string: "https://tigercenter.rit.edu/")!)
                }) {
                    Label("TigerCenter", systemImage: "fork.knife.circle")
                }
                
                Button(action: {
                    openURL(URL(string: "https://maps.rit.edu/")!)
                }) {
                    Label("Official RIT Map", systemImage: "map")
                }
                
                Button(action: {
                    openURL(URL(string: "https://fdmealplanner.com/")!)
                }) {
                    Label("FD MealPlanner", systemImage: "menucard")
                }
            }
            
            Section(
                footer: Text("This app is not affiliated, associated, authorized, endorsed by, or" +
                             " in any way officially connected with the Rochester Institute of " +
                             "Technology. This app is student created and maintained.")
            ) {
                EmptyView()
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    AboutView()
}
