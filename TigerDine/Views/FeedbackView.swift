//
//  FeedbackView.swift
//  TigerDine
//
//  Created by Campbell on 2/16/26.
//

import SwiftUI
import MessageUI

struct FeedbackView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) private var openURL
    
    @State private var showingMailView = false
    @State private var mailResult: Result<MFMailComposeResult, Error>? = nil
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "paperplane")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .foregroundStyle(Color.accentColor)
                        Text("Submit Feedback")
                            .fontWeight(.bold)
                            .font(.title)
                    }
                    Text("Did I break something? Oops.")
                    Text("Or maybe you just have a suggestion to make TigerDine even cooler. Either way, I'd love to hear your feedback! (Or maybe the hours for a location are off, in which case that feedback is RIT's to handle.)")
                        .foregroundStyle(.secondary)
                    Text("Incorrect Location Hours")
                        .padding(.top, 12)
                    Button(action: {
                        openURL(URL(string: "https://www.rit.edu/dining/locations")!)
                    }) {
                        HStack(alignment: .center) {
                            Image(systemName: "clock.badge.questionmark")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .foregroundStyle(Color.accentColor)
                            VStack(alignment: .leading) {
                                Text("Confirm Against the RIT Website")
                                    .fontWeight(.bold)
                                Text("Check that the hours displayed in TigerDine match RIT's website.")
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                            Image(systemName: "chevron.forward")
                        }
                        .padding(.all, 6)
                        .background (
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.secondary.opacity(0.1))
                        )
                    }
                    .buttonStyle(.plain)
                    Button(action: {
                        openURL(URL(string: "https://www.rit.edu/its/support")!)
                    }) {
                        HStack(alignment: .center) {
                            Image(systemName: "clock.badge.exclamationmark")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .foregroundStyle(Color.accentColor)
                            VStack(alignment: .leading) {
                                Text("Submit an ITS Ticket")
                                    .fontWeight(.bold)
                                Text("If hours are also incorrect on RIT's website, submit a ticket to ITS.")
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                            Image(systemName: "chevron.forward")
                        }
                        .padding(.all, 6)
                        .background (
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.secondary.opacity(0.1))
                        )
                    }
                    .buttonStyle(.plain)
                    Text("If the hours do not match between TigerDine and RIT's website, please contact me instead and I'll look into it.")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    Text("TigerDine Issues and Feedback")
                        .padding(.top, 12)
                    Button(action: {
                        openURL(URL(string: "https://github.com/NinjaCheetah/TigerDine/issues")!)
                    }) {
                        HStack(alignment: .center) {
                            Image(systemName: "ant.circle")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .foregroundStyle(Color.accentColor)
                            VStack(alignment: .leading) {
                                Text("Submit a GitHub Issue")
                                    .fontWeight(.bold)
                                Text("Report a bug or suggest a feature on TigerDine's GitHub repository.")
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                            Image(systemName: "chevron.forward")
                        }
                        .padding(.all, 6)
                        .background (
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.secondary.opacity(0.1))
                        )
                    }
                    .buttonStyle(.plain)
                    Button(action: {
                        showingMailView = true
                    }) {
                        HStack(alignment: .center) {
                            Image(systemName: "envelope.circle")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .foregroundStyle(Color.accentColor)
                            VStack(alignment: .leading) {
                                Text("Send Me an Email")
                                    .fontWeight(.bold)
                                Text("Not a GitHub user? Feel free to submit feedback via email.")
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                            Image(systemName: "chevron.forward")
                        }
                        .padding(.all, 6)
                        .background (
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.secondary.opacity(0.1))
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!MailView.canSendMail())
                    .sheet(isPresented: $showingMailView) {
                        MailView(result: $mailResult)
                    }
                    Text("Just don't spam my inbox, please and thank you.")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .toolbar {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

#Preview {
    FeedbackView()
}
