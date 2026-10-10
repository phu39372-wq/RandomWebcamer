import Foundation

// MARK: - Модели ответа

struct WebcamResponse: Decodable {
    let webcams: [Webcam]
}

struct Webcam: Decodable, Identifiable {
    let id: Int
    let title: String
    let location: WebcamLocation
    let images: WebcamImages

    enum CodingKeys: String, CodingKey {
        case id = "webcamId"
        case title, location, images
    }
}

struct WebcamLocation: Decodable {
    let city: String?
    let country: String?
    let latitude: Double
    let longitude: Double
}

struct WebcamImages: Decodable {
    let current: ImageSet
}

struct ImageSet: Decodable {
    let preview: String?
    let thumbnail: String?
    let icon: String?
}

// MARK: - Ошибки

enum WebcamError: Error, LocalizedError, Equatable {
    case badURL
    case network(String)
    case decoding(String)
    case emptyResult
    case serverError(Int)
    case missingAPIKey

    var errorDescription: String? {
        switch self {
        case .badURL: return "Некорректный URL запроса"
        case .network(let msg): return "Ошибка сети: \(msg)"
        case .decoding(let msg): return "Ошибка разбора ответа: \(msg)"
        case .emptyResult: return "Камеры не найдены"
        case .serverError(let code): return "Ошибка сервера: \(code)"
        case .missingAPIKey: return "Не задан WINDY_API_KEY (см. README)"
        }
    }
}

// MARK: - API-клиент

final class WebcamAPI {
    private let apiKey: String
    private let session = URLSession.shared

    init() {
        self.apiKey = Bundle.main.object(forInfoDictionaryKey: "WindyAPIKey") as? String ?? ""
    }

    /// Возвращает одну случайную публичную веб-камеру из сети Windy Webcams API.
    func fetchRandomWebcam() async throws -> Webcam {
        guard !apiKey.isEmpty, apiKey != "$(WINDY_API_KEY)" else {
            throw WebcamError.missingAPIKey
        }

        let approxTotal = 65000
        let randomOffset = Int.random(in: 0..<max(approxTotal - 20, 1))

        guard var components = URLComponents(string: "https://api.windy.com/webcams/api/v3/webcams") else {
            throw WebcamError.badURL
        }
        components.queryItems = [
            URLQueryItem(name: "limit", value: "20"),
            URLQueryItem(name: "offset", value: "\(randomOffset)"),
            URLQueryItem(name: "include", value: "images,location"),
            URLQueryItem(name: "lang", value: "ru")
        ]

        guard let url = components.url else { throw WebcamError.badURL }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "x-windy-api-key")
        request.timeoutInterval = 10

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw WebcamError.network(error.localizedDescription)
        }

        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw WebcamError.serverError(http.statusCode)
        }

        let decoded: WebcamResponse
        do {
            decoded = try JSONDecoder().decode(WebcamResponse.self, from: data)
        } catch {
            throw WebcamError.decoding(error.localizedDescription)
        }

        let validCams = decoded.webcams.filter { $0.images.current.preview != nil }

        guard let randomCam = validCams.randomElement() else {
            throw WebcamError.emptyResult
        }

        return randomCam
    }
}
