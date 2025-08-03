//import SwiftUI
//
//struct SubscriptionView: View {
//    @ObservedObject var viewModel = SubscriptionViewModel.shared
//
//    var body: some View {
//        VStack(spacing: 0) {
//            Image("subView")
//                .resizable()
//                .aspectRatio(contentMode: .fit)
//                .frame(maxWidth: UIScreen.main.bounds.width * 0.8, alignment: .top)
//                .clipped()
//
//            Spacer().frame(height: 32)
//
//            VStack(spacing: 20) {
//                ForEach(SubscriptionProduct.all, id: \.id) { product in
//                    Button(action: {
//                        viewModel.purchase(product: product)
//                    }) {
//                        Image(product.assetName)
//                            .resizable()
//                            .aspectRatio(contentMode: .fit)
//                            .frame(height: 72)
//                            .frame(maxWidth: .infinity)
//                    }
//                    .buttonStyle(PlainButtonStyle())
//                }
//            }
//            .padding(.horizontal, 24)
//            .padding(.top, 8)
//
//            Spacer()
//        }
//    }
//}
//
//#Preview {
//    SubscriptionView()
//}


import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @ObservedObject var viewModel = SubscriptionViewModel.shared

    var body: some View {
        VStack(spacing: 0) {
            Image("subView")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: UIScreen.main.bounds.width * 0.8, alignment: .top)
                .clipped()

            Spacer().frame(height: 32)

            VStack(spacing: 20) {
                ForEach(viewModel.storeProducts, id: \.id) { product in
                    Button(action: {
                        if let info = SubscriptionProduct.all.first(where: { $0.id == product.id }) {
                            viewModel.purchase(product: info)
                        }
                    }) {
                        // Только ассет
                        Image(SubscriptionProduct.all.first(where: { $0.id == product.id })?.assetName ?? "defaultAsset")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 72)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)

            Spacer()
        }
    }
}
