//
// MIT License
//
// Copyright (c) 2018-2026 Alexander Cyon (https://github.com/sajjon)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

import AVFoundation
import Foundation

/// Plays a bundled sound effect. Exists behind a protocol so views/view-models can
/// trigger audio without touching `AVFoundation` directly, and so unit tests can
/// register a no-op implementation that never produces real sound.
public protocol SoundPlayer: AnyObject {
    /// Plays the sound resource named `resourceName` with the given file extension
    /// from the provided bundle. Silently no-ops if the file cannot be located or
    /// the audio session cannot be configured.
    func play(resource resourceName: String, withExtension fileExtension: String, in bundle: Bundle)
}

extension SoundPlayer {
    /// Convenience overload that defaults to the main bundle.
    func play(resource resourceName: String, withExtension fileExtension: String) {
        play(resource: resourceName, withExtension: fileExtension, in: .main)
    }
}

/// Production implementation that uses `AVAudioPlayer` against the shared
/// `AVAudioSession`. Holds onto the player so playback isn't deallocated mid-play.
public final class DefaultSoundPlayer: SoundPlayer {
    private var player: AVAudioPlayer?

    init() {}

    public func play(resource resourceName: String, withExtension fileExtension: String, in bundle: Bundle) {
        guard let url = bundle.url(forResource: resourceName, withExtension: fileExtension) else { return }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            player?.play()
        } catch {
            print(error.localizedDescription)
        }
    }
}
