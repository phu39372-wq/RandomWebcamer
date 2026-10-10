import SwiftUI

@main
struct RandomWebcamApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                RandomCamView()
            }
        }
    }
}
