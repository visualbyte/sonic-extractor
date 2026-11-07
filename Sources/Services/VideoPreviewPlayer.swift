import Foundation
import AVFoundation
import Combine

@MainActor
public final class VideoPreviewPlayer: ObservableObject {
    @Published public var isPlaying: Bool = false
    @Published public var currentTime: Double = 0.0
    @Published public var duration: Double = 0.0
    @Published public var currentURL: URL?
    
    private var player: AVPlayer?
    private var timeObserver: Any?
    
    public init() {}
    
    public func load(url: URL, durationSec: Double) {
        stop()
        currentURL = url
        duration = durationSec
        let item = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: item)
        self.player = newPlayer
        
        let interval = CMTime(seconds: 0.1, preferredTimescale: 600)
        timeObserver = newPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            self.currentTime = CMTimeGetSeconds(time)
            if self.duration > 0 && self.currentTime >= self.duration {
                self.isPlaying = false
                self.seek(to: 0)
            }
        }
    }
    
    public func togglePlayPause() {
        guard let player = player else { return }
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            if currentTime >= duration {
                seek(to: 0)
            }
            player.play()
            isPlaying = true
        }
    }
    
    public func seek(to time: Double) {
        currentTime = time
        let targetTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    public func stop() {
        if let observer = timeObserver, let player = player {
            player.removeTimeObserver(observer)
        }
        timeObserver = nil
        player?.pause()
        player = nil
        isPlaying = false
        currentTime = 0.0
    }
}
