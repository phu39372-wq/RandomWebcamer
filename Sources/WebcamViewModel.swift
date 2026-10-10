import Foundation
import AudioToolbox

@MainActor
final class WebcamViewModel: ObservableObject {
    @Published var currentWebcam: Webcam?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var soundEnabled = true

    private let api = WebcamAPI()
    private let maxRetries = 3

    // Системный звук "затвор камеры" (встроен в iOS, отдельный файл не нужен)
    private let shutterSoundID: SystemSoundID = 1108

    func loadRandomWebcam() {
        Task {
            await fetchWithRetries(attempt: 0)
        }
    }

    func toggleSound() {
        soundEnabled.toggle()
    }

    private func fetchWithRetries(attempt: Int) async {
        isLoading = true
        errorMessage = nil

        do {
            let cam = try await api.fetchRandomWebcam()
            currentWebcam = cam
            isLoading = false
            playShutterSoundIfEnabled()
        } catch {
            let isMissingKey = (error as? WebcamError) == .missingAPIKey
            if attempt < maxRetries, !isMissingKey {
                try? await Task.sleep(nanoseconds: 400_000_000)
                await fetchWithRetries(attempt: attempt + 1)
            } else {
                isLoading = false
                errorMessage = (error as? WebcamError)?.errorDescription ?? "Не удалось загрузить камеру"
            }
        }
    }

    private func playShutterSoundIfEnabled() {
        guard soundEnabled else { return }
        AudioServicesPlaySystemSound(shutterSoundID)
    }
}
