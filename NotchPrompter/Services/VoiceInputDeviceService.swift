import AVFoundation
import CoreAudio
import Foundation

struct VoiceInputDevice: Identifiable, Hashable {
    let id: String
    let name: String
}

@MainActor
final class VoiceInputDeviceService: ObservableObject {
    static let shared = VoiceInputDeviceService()

    @Published private(set) var devices: [VoiceInputDevice] = []
    @Published private(set) var selectedDeviceUID: String = ""

    private static let selectedDeviceKey = "voice_input_device_uid"

    var selectedDeviceName: String {
        devices.first(where: { $0.id == selectedDeviceUID })?.name ?? "Microphone"
    }

    private init() {
        selectedDeviceUID = UserDefaults.standard.string(forKey: Self.selectedDeviceKey) ?? ""
        refreshDevices()
    }

    func refreshDevices() {
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.microphone, .external],
            mediaType: .audio,
            position: .unspecified
        )
        devices = discovery.devices.map { device in
            VoiceInputDevice(id: device.uniqueID, name: device.localizedName)
        }

        if selectedDeviceUID.isEmpty || !devices.contains(where: { $0.id == selectedDeviceUID }) {
            if let first = devices.first {
                selectDevice(uid: first.id, applyToSystem: true)
            }
        }
    }

    func selectDevice(uid: String, applyToSystem: Bool = true) {
        selectedDeviceUID = uid
        UserDefaults.standard.set(uid, forKey: Self.selectedDeviceKey)
        if applyToSystem {
            _ = setSystemDefaultInputDevice(uid: uid)
        }
    }

    private func setSystemDefaultInputDevice(uid: String) -> Bool {
        guard let deviceID = audioDeviceID(forUID: uid) else { return false }
        var mutableID = deviceID
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let status = AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            UInt32(MemoryLayout<AudioDeviceID>.size),
            &mutableID
        )
        return status == noErr
    }

    private func audioDeviceID(forUID uid: String) -> AudioDeviceID? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &dataSize
        ) == noErr else { return nil }

        let count = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = [AudioDeviceID](repeating: 0, count: count)
        guard AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &dataSize,
            &deviceIDs
        ) == noErr else { return nil }

        for deviceID in deviceIDs {
            guard let deviceUID = deviceUID(for: deviceID), deviceUID == uid else { continue }
            return deviceID
        }
        return nil
    }

    private func deviceUID(for deviceID: AudioDeviceID) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceUID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var uid: CFString = "" as CFString
        var dataSize = UInt32(MemoryLayout<CFString>.size)
        let status = AudioObjectGetPropertyData(
            deviceID,
            &address,
            0,
            nil,
            &dataSize,
            &uid
        )
        guard status == noErr else { return nil }
        return uid as String
    }
}
