import UIKit

class VolumeControlView: UIView {
    var audio: AudioManager = .shared
    var onClose: (() -> Void)?

    private let bgmSlider  = UISlider()
    private let sfxSlider  = UISlider()
    private let bgmMuteBtn = UIButton(type: .system)
    private let sfxMuteBtn = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { super.init(coder: coder); setup() }

    private func setup() {
        backgroundColor = UIColor(white: 0.1, alpha: 0.92)
        layer.cornerRadius = 16
        layer.borderColor = UIColor(hex: "#4caf50").cgColor
        layer.borderWidth = 1.5

        let title = UILabel()
        title.text = "Volume Settings"
        title.font = .boldSystemFont(ofSize: 18)
        title.textColor = .white
        title.textAlignment = .center

        let bgmLabel = makeLabel("🎵 BGM")
        let sfxLabel = makeLabel("🔊 SFX")

        bgmSlider.minimumValue = 0; bgmSlider.maximumValue = 1
        bgmSlider.addTarget(self, action: #selector(bgmChanged), for: .valueChanged)
        bgmSlider.tintColor = UIColor(hex: "#4caf50")

        sfxSlider.minimumValue = 0; sfxSlider.maximumValue = 1
        sfxSlider.addTarget(self, action: #selector(sfxChanged), for: .valueChanged)
        sfxSlider.tintColor = UIColor(hex: "#4caf50")

        style(bgmMuteBtn, title: "Mute")
        style(sfxMuteBtn, title: "Mute")
        bgmMuteBtn.addTarget(self, action: #selector(toggleBGMMute), for: .touchUpInside)
        sfxMuteBtn.addTarget(self, action: #selector(toggleSFXMute), for: .touchUpInside)

        let closeBtn = UIButton(type: .system)
        style(closeBtn, title: "Close")
        closeBtn.backgroundColor = UIColor(hex: "#2e7d32")
        closeBtn.addTarget(self, action: #selector(close), for: .touchUpInside)

        let bgmRow = hstack(bgmSlider, bgmMuteBtn)
        let sfxRow = hstack(sfxSlider, sfxMuteBtn)

        let stack = UIStackView(arrangedSubviews: [title, bgmLabel, bgmRow, sfxLabel, sfxRow, closeBtn])
        stack.axis = .vertical; stack.spacing = 12; stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
        ])

        refreshSliders()
    }

    private func makeLabel(_ text: String) -> UILabel {
        let l = UILabel(); l.text = text; l.textColor = UIColor(hex: "#a5d6a7"); l.font = .systemFont(ofSize: 15)
        return l
    }

    private func style(_ btn: UIButton, title: String) {
        btn.setTitle(title, for: .normal); btn.tintColor = .white
        btn.backgroundColor = UIColor(white: 0.25, alpha: 1)
        btn.layer.cornerRadius = 8
        btn.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        btn.titleLabel?.font = .systemFont(ofSize: 14)
    }

    private func hstack(_ a: UIView, _ b: UIView) -> UIView {
        let s = UIStackView(arrangedSubviews: [a, b])
        s.axis = .horizontal; s.spacing = 10; s.alignment = .center
        return s
    }

    func refreshSliders() {
        bgmSlider.value = audio.bgmMuted ? 0 : audio.bgmVolume
        sfxSlider.value = audio.sfxMuted ? 0 : audio.sfxVolume
        bgmMuteBtn.setTitle(audio.bgmMuted ? "Unmute" : "Mute", for: .normal)
        sfxMuteBtn.setTitle(audio.sfxMuted ? "Unmute" : "Mute", for: .normal)
    }

    @objc private func bgmChanged() { audio.setBGMVolume(bgmSlider.value) }
    @objc private func sfxChanged() { audio.setSFXVolume(sfxSlider.value) }
    @objc private func toggleBGMMute() { audio.toggleBGMMute(); refreshSliders() }
    @objc private func toggleSFXMute() { audio.toggleSFXMute(); refreshSliders() }
    @objc private func close() { onClose?() }
}
