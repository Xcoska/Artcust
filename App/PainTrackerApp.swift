import SwiftUI
import SwiftData

@main
struct PainTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [TrackedCondition.self, AssessmentRecord.self, PainLogEntry.self])
    }
}

struct RootView: View {
    var body: some View {
        TabView {
            NavigationStack {
                ConditionsListView()
            }
            .tabItem { Label("Conditions", systemImage: "list.bullet.clipboard") }

            NavigationStack {
                MoreView()
            }
            .tabItem { Label("Export & Info", systemImage: "square.and.arrow.up") }
        }
    }
}
