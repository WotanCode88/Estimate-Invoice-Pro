import SwiftUI

struct EstimateHeaderView: View {
    let dismiss: DismissAction
    var issuedDate: Date
    var dueDate: Date?
    var client: ClientModel?
    var items: [ItemModel]
    var total: Double
    var currency: String
    var onBack: () -> Void
    var back: () -> Void
    
    @State private var showAlert = false

    var body: some View {
        HStack {
            Button(action: {
                dismiss()
                back()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.black)
                    .padding(16)
                    .contentShape(Rectangle()) 
            }
            Spacer()
            Text("New Estimate")
                .font(.headline)
                .foregroundColor(.black)
            Spacer()
            Button(action: {
                let hasIssued = true
                let hasDue = dueDate != nil
                let hasClient = client != nil
                let hasItems = !items.isEmpty
                let hasTotal = total > 0
                let hasCurrency = !currency.isEmpty

                if hasIssued && hasClient && hasItems && hasTotal && hasCurrency {
                    onBack()
                } else {
                    showAlert = true
                }
            }) {
                Text("Done")
                    .font(.body)
                    .foregroundColor(.black)
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Required fields missing"),
                    message: Text("Please fill out all required fields before saving the invoice."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .padding(.horizontal)
        .frame(height: 44)
    }
}
