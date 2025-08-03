import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            InvoicesView()
                .tabItem {
                    Image(systemName: "document.on.document")
                    Text("Invoices")
                }
            ClientsView()
                .tabItem {
                    Image(systemName: "person.2")
                    Text("Clients")
                }
            ReportsView()
                .tabItem {
                    Image(systemName: "chart.pie")
                    Text("Reports")
                }
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Settings")
                }
        }
        .tint(.black) 
    }
}

#Preview {
    MainTabView()
}
