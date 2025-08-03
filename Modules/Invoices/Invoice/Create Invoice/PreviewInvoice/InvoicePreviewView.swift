import SwiftUI

struct InvoicePreviewView: View {
    let invoice: InvoiceModel
    let isPreview: Bool

    @State private var showSubscriptionSheet = false

    var body: some View {
        ZStack {
            InvoicePreviewViewControllerRepresentable(invoice: invoice, isPreview: isPreview, showSubscriptionSheet: $showSubscriptionSheet)
                .ignoresSafeArea()
                .navigationBarHidden(true)
        }
        .sheet(isPresented: $showSubscriptionSheet) {
            SubscriptionView()
        }
    }
}

struct InvoicePreviewViewControllerRepresentable: UIViewControllerRepresentable {
    let invoice: InvoiceModel
    let isPreview: Bool
    @Binding var showSubscriptionSheet: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> InvoicePreviewViewController {
        let vc = InvoicePreviewViewController(isCustom: isPreview, invoice: invoice)
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: InvoicePreviewViewController, context: Context) {
    }

    class Coordinator: NSObject, InvoicePreviewDelegate {
        var parent: InvoicePreviewViewControllerRepresentable

        init(_ parent: InvoicePreviewViewControllerRepresentable) {
            self.parent = parent
        }

        func presentSubscription() {
            parent.showSubscriptionSheet = true
        }
    }
}
