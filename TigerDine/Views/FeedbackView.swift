//
//  FeedbackView.swift
//  TigerDine
//
//  Created by Campbell on 2/16/26.
//

import SwiftUI
import MessageUI

struct FeedbackView: View {
    @Environment(\.openURL) private var openURL
    
    @State private var showingMailView = false
    @State private var mailResult: Result<MFMailComposeResult, Error>? = nil
    
    var body: some View {
        List {
            VStack(alignment: .leading, spacing: 8) {
                Text("Did I break something? Oops.")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Or maybe you just have a suggestion to make TigerDine even cooler. Either way, I'd love to hear your feedback! (Or maybe the hours for a location are off, in which case that feedback is RIT's to handle.)")
                    .foregroundStyle(.secondary)
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 8, bottom: 8, trailing: 8))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            
            Section(
                header: Text("Incorrect Location Hours"),
                footer: Text("If the hours do not match between TigerDine and RIT's website, please contact me instead and I'll look into it.")
            ) {
                Button(action: {
                    openURL(URL(string: "https://www.rit.edu/dining/locations")!)
                }) {
                    HStack(alignment: .center) {
                        Image(systemName: "clock.badge.questionmark")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .foregroundStyle(Color.accentColor)
                        VStack(alignment: .leading) {
                            Text("Confirm Against the RIT Website")
                            Text("Check that the hours displayed in TigerDine match RIT's website.")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                        }
                        Spacer()
                        Image(systemName: "chevron.forward")
                    }
                }
                .buttonStyle(.plain)
                Button(action: {
                    openURL(URL(string: "https://www.rit.edu/its/support")!)
                }) {
                    HStack(alignment: .center) {
                        Image(systemName: "clock.badge.exclamationmark")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .foregroundStyle(Color.accentColor)
                        VStack(alignment: .leading) {
                            Text("Submit an ITS Ticket")
                            Text("If hours are also incorrect on RIT's website, submit a ticket to ITS.")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                        }
                        Spacer()
                        Image(systemName: "chevron.forward")
                    }
                }
                .buttonStyle(.plain)
            }
            
            Section(
                header: Text("App Issues and Feedback"),
                footer: Text("Just don't spam my inbox, please and thank you.")
            ) {
                Button(action: {
                    openURL(URL(string: "https://github.com/NinjaCheetah/TigerDine/issues")!)
                }) {
                    HStack(alignment: .center) {
                        Image(systemName: "ant.circle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .foregroundStyle(Color.accentColor)
                        VStack(alignment: .leading) {
                            Text("Submit a GitHub Issue")
                            Text("Report a bug or suggest a feature on TigerDine's GitHub repository.")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                        }
                        Spacer()
                        Image(systemName: "chevron.forward")
                    }
                }
                .buttonStyle(.plain)
                Button(action: {
                    showingMailView = true
                }) {
                    HStack(alignment: .center) {
                        Image(systemName: "envelope.circle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .foregroundStyle(Color.accentColor)
                        VStack(alignment: .leading) {
                            Text("Send Me an Email")
                            Text("Not a GitHub user? Feel free to submit feedback via email.")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                        }
                        Spacer()
                        Image(systemName: "chevron.forward")
                    }
                }
                .buttonStyle(.plain)
                .disabled(!MailView.canSendMail())
                .sheet(isPresented: $showingMailView) {
                    MailView(result: $mailResult)
                }
            }
        }
        .navigationTitle("Feedback")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    FeedbackView()
}
