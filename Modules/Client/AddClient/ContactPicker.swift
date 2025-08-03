import SwiftUI
import ContactsUI

struct ContactPicker: UIViewControllerRepresentable {
    var onSelect: (ContactData) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onSelect: onSelect)
    }

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    final class Coordinator: NSObject, CNContactPickerDelegate {
        var onSelect: (ContactData) -> Void

        init(onSelect: @escaping (ContactData) -> Void) {
            self.onSelect = onSelect
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            let name = CNContactFormatter.string(from: contact, style: .fullName) ?? ""
            let email = contact.emailAddresses.first?.value as String? ?? ""
            let phone = contact.phoneNumbers.first?.value.stringValue ?? ""
            let address = contact.postalAddresses.first?.value
            let formattedAddress = address.map {
                [$0.street, $0.city, $0.state, $0.postalCode, $0.country].filter { !$0.isEmpty }.joined(separator: ", ")
            } ?? ""

            let contactData = ContactData(
                name: name,
                email: email,
                phone: phone,
                address: formattedAddress
            )
            onSelect(contactData)
        }
    }
}
