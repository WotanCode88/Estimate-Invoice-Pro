import SwiftUI

struct InvoicesView: View {
    @StateObject private var coordinator = InvoicesCoordinator()
    @State private var selectedTab: Tab = .invoices

    enum Tab: String, CaseIterable, Identifiable {
        case invoices = "Invoices"
        case estimates = "Estimates"
        var id: String { rawValue }
    }

    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()
            VStack {
                Spacer().frame(height: 24)
                
                HStack {
                    Picker("Select Tab", selection: $selectedTab) {
                        ForEach(Tab.allCases) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 300)
                }
                .padding(.horizontal)
                
                Spacer()
                
                Group {
                    switch selectedTab {
                    case .invoices:
                        InvoicesTabView(coordinator: coordinator)
                    case .estimates:
                        EstimatesTabView()
                    }
                }
                
                Spacer()
            }
            .fullScreenCover(isPresented: $coordinator.isPresentingNewInvoice) {
                NewInvoiceView(onDismiss: { coordinator.dismissNewInvoice() })
            }
        }
    }
}
