import Foundation
import AVFoundation
import Combine

@MainActor
public final class AudioPlayerManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published public var isPlaying: Bool = false
    @Published public var currentTime: Double = 0.0
    @Published public var duration: Double = 0.0
    @Published public var currentURL: URL?
    
    private var audioPlayer: AVAudioPlayer?
    private var timer: AnyCancellable?
    
    public override init() {
        super.init()
    }
    
    public func load(url: URL) {
        stop()
        currentURL = url
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.prepareToPlay()
            self.audioPlayer = player
            self.duration = player.duration
            self.currentTime = 0.0
        } catch {
            print("Failed to initialize audio player: \(error)")
        }
    }
    
    public func togglePlayPause() {
        guard let player = audioPlayer else { return }
        if isPlaying {
            player.pause()
            isPlaying = false
            timer?.cancel()
        } else {
            player.play()
            isPlaying = true
            startTimer()
        }
    }
    
    public func seek(to time: Double) {
        guard let player = audioPlayer else { return }
        player.currentTime = time
        currentTime = time
    }
    
    public func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentTime = 0.0
        duration = 0.0
        timer?.cancel()
    }
    
    private func startTimer() {
        timer?.cancel()
        timer = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, let player = self.audioPlayer else { return }
                if player.isPlaying {
                    self.currentTime = player.currentTime
                }
            }
    }
    
    public nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
            self.currentTime = 0.0
            self.timer?.cancel()
        }
    }
}
