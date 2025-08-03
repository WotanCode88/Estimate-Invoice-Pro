import SwiftUI

struct ClientsView: View {
    @StateObject private var coordinator = ClientsCoordinator()
    @StateObject private var viewModel = ClientsViewModel()

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(UIColor.systemGray6)
                .ignoresSafeArea()

            VStack(alignment: .center, spacing: 0) {
                Text("Clients")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.top, 32)
                    .padding(.horizontal, 24)

                SearchBar(text: $viewModel.searchText)
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                HStack {
                    Text("Name")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Total paid")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                .padding(.horizontal, 24)
                .padding(.bottom, 4)

                if viewModel.filteredClients.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Text("Add clients or import from your contacts")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(viewModel.filteredClients) { client in
                                ClientRow(client: client, totalPaid: viewModel.totalPaid(for: client))
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                    }
                }

                Spacer()
            }

            Button(action: {
                coordinator.isPresentingAddClient = true
            }) {
                Text("+ Add Client")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.black)
                    .cornerRadius(20)
                    .padding(.horizontal, 100)
                    .padding(.bottom, 24)
            }
        }
        .onTapGesture {
            UIApplication.shared.hideKeyboard()
        }
        .fullScreenCover(isPresented: $coordinator.isPresentingAddClient) {
            AddClientView()
        }
        .onAppear { viewModel.loadClients() }
        .onChange(of: coordinator.isPresentingAddClient) { isPresented in
            if !isPresented {
                viewModel.loadClients()
            }
        }
    }
}

struct ClientRow: View {
    let client: ClientModel
    let totalPaid: Double

    var body: some View {
        HStack {
            Text(client.name)
                .font(.body)
                .foregroundColor(.black)
            Spacer()
            Text("\(String(format: "%.2f", totalPaid))")
                .font(.body)
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
    }
}
