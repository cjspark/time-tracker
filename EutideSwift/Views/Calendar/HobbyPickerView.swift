import SwiftUI

struct HobbyPickerView: View {
    @Binding var selected: String
    @Binding var selectedColor: String
    let hobbies: [HobbyItem]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List(hobbies) { hobby in
                Button {
                    selected = hobby.label
                    selectedColor = hobby.color
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color(hex: hobby.color))
                            .frame(width: 16, height: 16)
                        Text(hobby.displayLabel)
                            .foregroundColor(.primary)
                        Spacer()
                        if hobby.label == selected {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("选择活动")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
