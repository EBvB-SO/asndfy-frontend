//
//  ProfileCardComponent.swift
//  Ascendify
//
//  Created by Ellis Barker on 15/03/2025.
//

import SwiftUI

// Reusable card component with shadow and tap animation
struct ProfileCard<Content: View>: View {
    var content: Content
    @State private var isPressed = false
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(
                        color: Color.black.opacity(0.12),
                        radius: isPressed ? 2 : 5,
                        x: 0,
                        y: isPressed ? 1 : 3
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .onTapGesture {
                // Simulate button press animation
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = true
                }
                // Schedule release after short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation {
                        isPressed = false
                    }
                }
            }
    }
}

// Preview for testing the profile card
struct ProfileCardComponent_Previews: PreviewProvider {
    static var previews: some View {
        ProfileCard {
            Text("Sample Card Content")
                .padding()
                .frame(width: 200, height: 100)
                .background(Color.blue.opacity(0.2))
        }
        .padding()
    }
}
