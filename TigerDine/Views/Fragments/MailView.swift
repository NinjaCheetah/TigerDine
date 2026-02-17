//
//  MailView.swift
//  TigerDine
//
//  Created by Campbell on 2/16/26.
//

import SwiftUI
import MessageUI

// More gross yucky UIKit code :(
// Unfortunately there's no native SwiftUI MailView.
struct MailView: UIViewControllerRepresentable {
    @Environment(\.dismiss) var dismiss
    @Binding var result: Result<MFMailComposeResult, Error>?
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        var parent: MailView
        
        init(_ parent: MailView) {
            self.parent = parent
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            defer {
                parent.dismiss()
            }
            if let error = error {
                parent.result = .failure(error)
            } else {
                parent.result = .success(result)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setToRecipients(["campbell@ninjacheetah.dev"])
        vc.setSubject("TigerDine Feedback")
        //vc.setMessageBody("", isHTML: false)
        return vc
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {
        
    }
    
    static func canSendMail() -> Bool {
        return MFMailComposeViewController.canSendMail()
    }
}
