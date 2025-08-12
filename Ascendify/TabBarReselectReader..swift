//
//  TabBarReselectReader..swift
//  Ascendify
//
//  Created by Ellis Barker on 12/08/2025.
//

import SwiftUI

/// Listens for tab bar selections including "reselecting" the same tab,
/// which SwiftUI does not expose. Calls `onReselect(index)` on every tap.
struct TabBarReselectReader: UIViewControllerRepresentable {
    @Binding var selectedIndex: Int
    var onReselect: (Int) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(selectedIndex: $selectedIndex, onReselect: onReselect)
    }

    func makeUIViewController(context: Context) -> UITabBarController {
        let tc = UITabBarController()
        tc.delegate = context.coordinator
        return tc
    }

    func updateUIViewController(_ uiViewController: UITabBarController, context: Context) {
        uiViewController.selectedIndex = selectedIndex
    }

    final class Coordinator: NSObject, UITabBarControllerDelegate {
        @Binding var selectedIndex: Int
        let onReselect: (Int) -> Void
        private var lastIndex: Int?

        init(selectedIndex: Binding<Int>, onReselect: @escaping (Int) -> Void) {
            _selectedIndex = selectedIndex
            self.onReselect = onReselect
        }

        func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
            let newIndex = tabBarController.selectedIndex
            if lastIndex == newIndex {
                onReselect(newIndex)     // <- re-tap
            }
            selectedIndex = newIndex     // keep SwiftUI selection in sync
            lastIndex = newIndex
        }
    }
}
