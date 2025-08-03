import SwiftUI

struct EstimatesTabView: View {
    @StateObject private var subscriptionVM = SubscriptionViewModel.shared
    @State private var showSubscriptionSheet = false
    @State private var showNewEstimate = false

    @ObservedObject private var userVM = UserViewModel.shared
    @State private var reloadID = UUID()
    
    @StateObject private var viewModel = EstimatesViewModel()
    @State private var selectedEstimate: InvoiceModel? = nil
    @State private var showEditEstimate = false

    // Показываем только оценки текущего пользователя
    var userEstimates: [InvoiceModel] {
        guard let currentUser = userVM.currentUser else { return [] }
        return Array(currentUser.invoices.filter { $0.isEstimate == true })
    }

    var body: some View {
        VStack {
            Spacer()
            if userEstimates.isEmpty {
                Image("estimatesEmptyView")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 220)
                    .padding()
                Spacer()
            } else {
                VStack {
                    List {
                        ForEach(userEstimates, id: \.self) { estimate in
                            EstimateRowView(estimate: estimate)
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                                .padding(.vertical, 6)
                                .listRowSeparator(.hidden)
                                .onTapGesture {
                                    selectedEstimate = estimate
                                }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let estimateToDelete = userEstimates[index]
                                viewModel.deleteEstimate(estimateToDelete)
                            }
                        }
                    }
                    .sheet(item: $selectedEstimate) { estimate in
                        SingleEstimateVCWrapper(invoice: estimate, isCustom: false)
                    }
                    .listRowSeparator(.hidden)
                    .listStyle(.plain)
                }
                .padding(.horizontal, 16)
            }
            Button(action: {
                if !subscriptionVM.isSubscribed {
                    showSubscriptionSheet = true
                } else {
                    showNewEstimate = true
                }
            }) {
                HStack(spacing: 8) {
                    Text("+ Create Estimate")
                        .foregroundColor(.white)
                    if !subscriptionVM.isSubscribed {
                        Image("needPremiumWhite")
                            .resizable()
                            .frame(width: 63, height: 17)
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.black)
                .cornerRadius(20)
                .padding(.horizontal, 100)
            }
            .padding(.bottom, 16)
            .sheet(isPresented: $showSubscriptionSheet) {
                SubscriptionView()
            }
            .fullScreenCover(isPresented: $showNewEstimate) {
                NewEstimateView(onDismiss: { showNewEstimate = false })
            }
        }
        .id(reloadID) // Перерисовываем весь VStack при смене пользователя
        .onReceive(userVM.$currentUser) { _ in
            reloadID = UUID()
        }
    }
}

struct EstimateRowView: View {
    let estimate: InvoiceModel

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(estimate.client?.name ?? "nil")
                    .font(.system(size: 18, weight: .semibold))
                Text("Issue: \(formatDate(estimate.Issued))")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 5) {
                HStack(spacing: 4) {
                    Text("\(String(format: "%.2f", estimate.total ?? 0))")
                        .font(.system(size: 17, weight: .semibold))
                    Text(estimate.currency ?? "")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 68)
        .background(
            Color.white
                .cornerRadius(14)
                .shadow(color: Color(.systemGray4).opacity(0.18), radius: 4, x: 0, y: 2)
        )
        .padding(.vertical, 4)
    }

    func formatDate(_ date: Date?) -> String {
        guard let date else { return "--" }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}
