import UIKit
import GoogleMobileAds

class AdManager: NSObject, FullScreenContentDelegate {
    static let shared = AdManager()

    // Use test ID during development — replace before App Store submission
    private let adUnitID = "ca-app-pub-3940256099942544/1033173712"

    private var interstitial: InterstitialAd?
    private var onFinished: (() -> Void)?
    private var countdownView: UIView?

    private override init() {}

    func setup() { loadAd() }

    func loadAd() {
        InterstitialAd.load(with: adUnitID, request: Request()) { [weak self] ad, error in
            if let error = error {
                print("[Ad] Load failed: \(error)")
                return
            }
            self?.interstitial = ad
            self?.interstitial?.fullScreenContentDelegate = self
        }
    }

    /// Call when user taps "Watch Ad & Play Again". Callback fires after ad dismissal.
    func showAd(from vc: UIViewController, onFinished: @escaping () -> Void) {
        guard let ad = interstitial else {
            // No ad ready — just start game
            onFinished()
            loadAd()
            return
        }
        self.onFinished = onFinished
        ad.present(from: vc)
        if let window = vc.view.window {
            showCountdownOverlay(in: window, onSkip: { [weak self] in
                self?.finish()
            })
        }
    }

    // MARK: - Countdown Overlay
    private func showCountdownOverlay(in window: UIWindow, onSkip: @escaping () -> Void) {
        let overlay = UIView(frame: window.bounds)
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        let label = UILabel()
        label.text = "3"
        label.font = .systemFont(ofSize: 48, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowRadius = 4; label.layer.shadowOpacity = 0.8
        label.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            label.topAnchor.constraint(equalTo: overlay.topAnchor, constant: 40)
        ])

        let skipBtn = UIButton(type: .system)
        skipBtn.setTitle("✕ Skip", for: .normal)
        skipBtn.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        skipBtn.setTitleColor(.white, for: .normal)
        skipBtn.backgroundColor = UIColor(white: 0, alpha: 0.55)
        skipBtn.layer.cornerRadius = 8
        skipBtn.contentEdgeInsets = UIEdgeInsets(top: 10, left: 24, bottom: 10, right: 24)
        skipBtn.isHidden = true
        skipBtn.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(skipBtn)
        NSLayoutConstraint.activate([
            skipBtn.trailingAnchor.constraint(equalTo: overlay.trailingAnchor, constant: -24),
            skipBtn.topAnchor.constraint(equalTo: overlay.topAnchor, constant: 48)
        ])
        skipBtn.addAction(UIAction { [weak self] _ in
            self?.removeCountdownOverlay()
            onSkip()
        }, for: .touchUpInside)

        window.addSubview(overlay)
        countdownView = overlay

        var count = 3
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] t in
            count -= 1
            if count > 0 {
                label.text = "\(count)"
            } else {
                t.invalidate()
                label.isHidden = true
                skipBtn.isHidden = false
            }
        }
        RunLoop.main.add(timer, forMode: .common)
    }

    private func removeCountdownOverlay() {
        countdownView?.removeFromSuperview()
        countdownView = nil
    }

    private func finish() {
        removeCountdownOverlay()
        let cb = onFinished; onFinished = nil
        cb?()
    }

    // MARK: - GADFullScreenContentDelegate
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        finish()
        loadAd()
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        finish()
        loadAd()
    }
}
