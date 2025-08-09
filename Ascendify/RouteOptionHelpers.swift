import SwiftUI

/// Any enum that backs a “route option” can conform to this.
protocol RouteOption: Hashable {
  var rawValue: String { get }    // comes from `enum Foo: String`
  var iconName: String { get }    // your existing computed property
  var color: Color { get }        // we’ll add this in extensions
}

/// A generic multi-select grid for any `RouteOption`.
struct RouteCharacteristicSelector<T: RouteOption>: View {
  let title: String
  let description: String
  let options: [T]
  @Binding var selectedOptions: Set<T>

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title).font(.subheadline).foregroundColor(.tealBlue)
      Text(description).font(.caption).foregroundColor(.gray)

      LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
        ForEach(options, id: \.self) { option in
          Button {
            if selectedOptions.contains(option) {
              selectedOptions.remove(option)
            } else {
              selectedOptions.insert(option)
            }
          } label: {
            HStack {
              Image(systemName: option.iconName)
                .foregroundColor(selectedOptions.contains(option)
                                 ? option.color
                                 : .gray)
              Text(option.rawValue)
                .fontWeight(selectedOptions.contains(option) ? .semibold : .regular)
              Spacer()
              if selectedOptions.contains(option) {
                Image(systemName: "checkmark").foregroundColor(option.color)
              }
            }
            .padding(.vertical, 8).padding(.horizontal, 10)
            .background(
              RoundedRectangle(cornerRadius: 8)
                .fill(selectedOptions.contains(option)
                      ? option.color.opacity(0.1)
                      : Color(.systemGray6))
            )
            .overlay(
              RoundedRectangle(cornerRadius: 8)
                .stroke(selectedOptions.contains(option)
                        ? option.color
                        : .clear,
                        lineWidth: 1)
            )
          }
          .buttonStyle(PlainButtonStyle())
        }
      }
    }
  }
}

// MARK: – Only add the `color` implementations here:

extension RouteAngle: RouteOption {
  var color: Color { .tealBlue }
}

extension RouteLength: RouteOption {
  var color: Color { .ascendGreen }
}

extension HoldType: RouteOption {
  var color: Color { .purple }
}
