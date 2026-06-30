//  AudioService.swift
//  Drift

import AVFoundation
import Combine

@MainActor
final class AudioService: NSObject, ObservableObject {

    static let maxDuration: TimeInterval = 10

    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var savedPath: String? = nil

    // Recording
    private var recorder: AVAudioRecorder?
    private var timer: Timer?
    private var currentURL: URL?

    // Dreamy playback engine (delay + reverb)
    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let reverb = AVAudioUnitReverb()
    private let delay = AVAudioUnitDelay()
    private var engineConfigured = false

    private var recordingsDir: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Recordings", isDirectory: true)
    }

    override init() {
        super.init()
        try? FileManager.default.createDirectory(at: recordingsDir, withIntermediateDirectories: true)
    }

    // MARK: - Recording

    func startRecording() {
        Haptic.medium()
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
        try? session.setActive(true)

        let url = recordingsDir.appendingPathComponent("\(UUID().uuidString).m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        recorder = try? AVAudioRecorder(url: url, settings: settings)
        recorder?.delegate = self
        recorder?.record()
        currentURL = url
        isRecording = true
        recordingDuration = 0

        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.recordingDuration = self.recorder?.currentTime ?? 0
                if self.recordingDuration >= Self.maxDuration {
                    self.stopRecording()
                }
            }
        }
    }

    func stopRecording() {
        Haptic.soft()
        timer?.invalidate()
        timer = nil
        recorder?.stop()
        isRecording = false
        savedPath = currentURL?.lastPathComponent
    }

    // MARK: - Dreamy playback (delay + reverb via AVAudioEngine)

    /// Wires playerNode → delay → reverb → mixer once, reused across plays.
    private func configureEngineIfNeeded() {
        guard !engineConfigured else { return }

        engine.attach(playerNode)
        engine.attach(delay)
        engine.attach(reverb)

        // Dreamy preset: long lush reverb + a soft slapback delay underneath
        reverb.loadFactoryPreset(.largeHall2)
        reverb.wetDryMix = 55   // mostly wet for that "in a dream" wash

        delay.delayTime = 0.32
        delay.feedback = 35
        delay.lowPassCutoff = 3500
        delay.wetDryMix = 30

        let format = engine.mainMixerNode.outputFormat(forBus: 0)
        engine.connect(playerNode, to: delay, format: format)
        engine.connect(delay, to: reverb, format: format)
        engine.connect(reverb, to: engine.mainMixerNode, format: format)

        engineConfigured = true
    }

    func startPlayback(path: String) {
        let url = recordingsDir.appendingPathComponent(path)
        guard FileManager.default.fileExists(atPath: url.path) else { return }

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default)
        try? session.setActive(true)

        configureEngineIfNeeded()

        guard let file = try? AVAudioFile(forReading: url) else { return }

        do {
            if !engine.isRunning { try engine.start() }
        } catch {
            return
        }

        playerNode.stop()
        playerNode.scheduleFile(file, at: nil) { [weak self] in
            Task { @MainActor [weak self] in
                // Allow the reverb tail to finish before flipping isPlaying off
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                self?.isPlaying = false
            }
        }
        playerNode.play()
        isPlaying = true
    }

    func stopPlayback() {
        playerNode.stop()
        isPlaying = false
    }

    func deleteRecording(path: String) {
        let url = recordingsDir.appendingPathComponent(path)
        try? FileManager.default.removeItem(at: url)
        if savedPath == path { savedPath = nil }
    }

    var formattedDuration: String {
        let s = Int(recordingDuration)
        return String(format: "0:%02d", s)
    }

    /// 0...1 progress toward the max recording duration, for ring/progress UI.
    var recordingProgress: Double {
        min(recordingDuration / Self.maxDuration, 1.0)
    }
}

extension AudioService: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {}
}
