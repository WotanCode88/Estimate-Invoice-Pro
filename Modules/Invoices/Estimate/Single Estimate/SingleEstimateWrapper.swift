import SwiftUI

struct SingleEstimateVCWrapper: View {
    let invoice: InvoiceModel
    let isCustom: Bool

    var body: some View {
        ZStack {
            SingleEstimateVCRepresentable(invoice: invoice, isCustom: isCustom)
                .ignoresSafeArea()
                .navigationBarHidden(true)
        }
    }
}

struct SingleEstimateVCRepresentable: UIViewControllerRepresentable {
    let invoice: InvoiceModel
    let isCustom: Bool

    func makeUIViewController(context: Context) -> SingleEstimateVC {
        let vc = SingleEstimateVC(invoice: invoice, isCustom: isCustom)
        vc.navigationItem.hidesBackButton = true
        DispatchQueue.main.async {
            vc.navigationController?.setNavigationBarHidden(true, animated: false)
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: SingleEstimateVC, context: Context) {
        DispatchQueue.main.async {
            uiViewController.navigationController?.setNavigationBarHidden(true, animated: false)
        }
    }
}
