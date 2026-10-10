import SwiftUI

struct RandomCamView: View {
    @StateObject private var viewModel = WebcamViewModel()

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
                    .frame(height: 280)

                if viewModel.isLoading {
                    ProgressView("Загрузка камеры…")
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                        Text(error)
                            .multilineTextAlignment(.center)
                            .font(.footnote)
                    }
                    .foregroundColor(.secondary)
                    .padding()
                } else if let cam = viewModel.currentWebcam,
                          let urlString = cam.images.current.preview,
                          let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFit()
                        case .failure:
                            Text("Изображение недоступно")
                                .foregroundColor(.secondary)
                        case .empty:
                            ProgressView()
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Text("Нажмите кнопку, чтобы начать")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)

            if let cam = viewModel.currentWebcam {
                VStack(spacing: 4) {
                    Text(cam.title).font(.headline)
                    if let city = cam.location.city, let country = cam.location.country {
                        Text("\(city), \(country)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }

            HStack(spacing: 12) {
                Button(action: viewModel.loadRandomWebcam) {
                    Label("Случайная камера", systemImage: "shuffle")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .background(Color.accentColor)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .disabled(viewModel.isLoading)

                Button(action: viewModel.toggleSound) {
                    Image(systemName: viewModel.soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .font(.title2)
                        .frame(width: 52, height: 52)
                }
                .background(Color(.systemGray5))
                .foregroundColor(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding(.top, 24)
        .navigationTitle("Публичные веб-камеры")
    }
}
