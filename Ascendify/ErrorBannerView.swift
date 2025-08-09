//
//  ErrorBannerView.swift
//  Ascendify
//
//  Created by Ellis Barker on 13/04/2025.
//

import SwiftUI

struct ErrorBannerView: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        VStack {
            bannerContent
        }
    }

    private var bannerContent: some View {
        HStack {
            icon
            messageText
            Spacer()
            dismissButton
        }
        .padding()
        .background(Color.red)
        .cornerRadius(8)
        .padding(.horizontal)
    }

    private var icon: some View {
        Image(systemName: "exclamationmark.triangle")
            .foregroundColor(.white)
    }

    private var messageText: some View {
        Text(message)
            .foregroundColor(.white)
    }

    private var dismissButton: some View {
        Button(action: onDismiss) {
            Image(systemName: "xmark")
                .foregroundColor(.white)
        }
    }
}
