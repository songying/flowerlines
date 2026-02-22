import UIKit

class ViewController: UIViewController {
    private var gameView: GameView!
    private var gameState: GameState!
    private var gameLogic: GameLogic!
    private var volumePanel: VolumeControlView?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hex: "#1a3a1a")
        setupGame()
        setupGameView()
        AudioManager.shared.setup()
        AdManager.shared.setup()
    }

    private func setupGame() {
        gameState = GameState(highScore: ScoreStore.highScore)
        gameLogic = GameLogic(state: gameState)
        gameLogic.initGame()

        gameLogic.onGameOver    = { [weak self] in self?.handleGameOver() }
        gameLogic.onEliminateStart = { AudioManager.shared.playElim() }
        gameLogic.onMoveStart   = { AudioManager.shared.playMove() }
        gameLogic.onSelectSound = { AudioManager.shared.playSelect() }
    }

    private func setupGameView() {
        gameView = GameView()
        gameView.translatesAutoresizingMaskIntoConstraints = false
        gameView.gameState = gameState
        gameView.gameLogic = gameLogic
        view.addSubview(gameView)
        NSLayoutConstraint.activate([
            gameView.topAnchor.constraint(equalTo: view.topAnchor),
            gameView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gameView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gameView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        gameView.onNewGame    = { [weak self] in self?.startNewGame() }
        gameView.onWatchAd    = { [weak self] in self?.watchAd() }
        gameView.onVolumeToggle = { [weak self] in self?.toggleVolumePanel() }
        gameView.startLoop()
    }

    // MARK: - Game Actions
    func startNewGame() {
        ScoreStore.highScore = gameState.highScore
        gameLogic.initGame()
    }

    func watchAd() {
        AdManager.shared.showAd(from: self) { [weak self] in self?.startNewGame() }
    }

    func handleGameOver() {
        ScoreStore.highScore = gameState.highScore
        AudioManager.shared.playGameOver()
    }

    // MARK: - Volume Panel
    func toggleVolumePanel() {
        if let panel = volumePanel {
            panel.removeFromSuperview()
            volumePanel = nil
        } else {
            showVolumePanel()
        }
    }

    func showVolumePanel() {
        let panel = VolumeControlView()
        panel.audio = AudioManager.shared
        panel.translatesAutoresizingMaskIntoConstraints = false
        panel.onClose = { [weak self] in self?.toggleVolumePanel() }
        panel.refreshSliders()
        view.addSubview(panel)
        NSLayoutConstraint.activate([
            panel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            panel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            panel.widthAnchor.constraint(equalToConstant: 320),
        ])
        volumePanel = panel
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.gameView.setNeedsLayout()
            self.gameView.layoutIfNeeded()
        })
    }
}
