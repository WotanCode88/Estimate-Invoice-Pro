import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @ObservedObject var viewModel = SubscriptionViewModel.shared

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Image("subView")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: geometry.size.width * 0.8, alignment: .top)
                    .clipped()

                Spacer().frame(height: geometry.size.height * 0.04)

                VStack(spacing: 16) {
                    ForEach(viewModel.storeProducts, id: \.id) { product in
                        let info = SubscriptionProduct.all.first(where: { $0.id == product.id })
                        Button(action: {
                            if let info = info {
                                viewModel.purchase(product: info)
                            }
                        }) {
                            HStack(alignment: .center, spacing: 14) {
                                Text(product.displayName)
                                    .font(.system(size: geometry.size.width * 0.04, weight: .bold))
                                    .foregroundColor(.black)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.8)
                                
                                Spacer(minLength: 12)
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(product.displayPrice)
                                        .font(.system(size: geometry.size.width * 0.05, weight: .bold))
                                        .foregroundColor(.black)
                                    if let info = info {
                                        Text(info.title)
                                            .font(.system(size: geometry.size.width * 0.032, weight: .medium))
                                            .foregroundColor(.gray)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                    }
                                }
                            }
                            .padding(.vertical, geometry.size.height * 0.016)
                            .padding(.horizontal, geometry.size.width * 0.045)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.gray.opacity(0.4), lineWidth: 1.5)
                                    .background(Color.white.cornerRadius(16))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .frame(minHeight: max(52, geometry.size.height * 0.09))
                    }
                }
                .padding(.horizontal, geometry.size.width * 0.06)
                .padding(.top, 8)

                Spacer()
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(Color(.systemBackground))
        }
    }
}
