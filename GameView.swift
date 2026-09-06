import SwiftUI

struct GameView: View {
    @State private var playerX: CGFloat = 0.5
    @State private var enemies: [Enemy] = []
    @State private var shots: [Shot] = []
    @State private var score = 0
    @State private var isPlaying = true
    @State private var lastTick = Date()
    @State private var lastSpawn = Date()

    private let timer = Timer.publish(every: 0.03, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(colors: [Color(red: 0.03, green: 0.05, blue: 0.15), Color(red: 0.12, green: 0.02, blue: 0.20)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                Canvas { context, size in
                    drawStars(context: &context, size: size)
                    drawShots(context: &context, size: size)
                    drawEnemies(context: &context, size: size)
                    drawPlayer(context: &context, size: size)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            guard isPlaying else { return }
                            playerX = min(max(value.location.x / proxy.size.width, 0.08), 0.92)
                        }
                )

                VStack {
                    HStack {
                        Label("SCORE \(score)", systemImage: "sparkles")
                            .font(.system(.headline, design: .rounded).weight(.bold))
                            .foregroundStyle(.white)
                        Spacer()
                        Text("IPA SHOOTER")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .tracking(2)
                            .foregroundStyle(.cyan)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    Spacer()
                }

                if !isPlaying {
                    VStack(spacing: 14) {
                        Text("GAME OVER")
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Score  \(score)")
                            .foregroundStyle(.white.opacity(0.75))
                        Button("もう一度プレイ") {
                            resetGame()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.cyan)
                    }
                    .padding(30)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
                }
            }
            .onReceive(timer) { now in
                tick(now: now, size: proxy.size)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func tick(now: Date, size: CGSize) {
        guard isPlaying else { return }
        let delta = min(now.timeIntervalSince(lastTick), 0.08)
        lastTick = now

        if now.timeIntervalSince(lastSpawn) > 0.75 {
            enemies.append(Enemy(x: CGFloat.random(in: 0.08...0.92), y: -0.08, speed: CGFloat.random(in: 0.12...0.20)))
            lastSpawn = now
        }

        shots = shots.map { Shot(x: $0.x, y: $0.y - CGFloat(delta) * 0.9) }.filter { $0.y > -0.1 }
        enemies = enemies.map { Enemy(x: $0.x, y: $0.y + $0.speed * CGFloat(delta), speed: $0.speed) }.filter { $0.y < 1.1 }

        var remainingEnemies: [Enemy] = []
        for enemy in enemies {
            let hit = shots.contains { abs($0.x - enemy.x) < 0.055 && abs($0.y - enemy.y) < 0.06 }
            if hit {
                score += 10
                shots.removeAll { abs($0.x - enemy.x) < 0.055 && abs($0.y - enemy.y) < 0.06 }
            } else if abs(enemy.x - playerX) < 0.09 && enemy.y > 0.82 {
                isPlaying = false
            } else {
                remainingEnemies.append(enemy)
            }
        }
        enemies = remainingEnemies

        if shots.count < 6 && Int(now.timeIntervalSince1970 * 100) % 12 == 0 {
            shots.append(Shot(x: playerX, y: 0.84))
        }
    }

    private func resetGame() {
        score = 0
        enemies = []
        shots = []
        playerX = 0.5
        lastTick = Date()
        lastSpawn = Date()
        isPlaying = true
    }

    private func drawStars(context: inout GraphicsContext, size: CGSize) {
        for index in 0..<32 {
            let x = CGFloat((index * 73) % 100) / 100 * size.width
            let y = CGFloat((index * 47) % 100) / 100 * size.height
            let rect = CGRect(x: x, y: y, width: 2, height: 2)
            context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.18)))
        }
    }

    private func drawPlayer(context: inout GraphicsContext, size: CGSize) {
        let center = CGPoint(x: playerX * size.width, y: size.height * 0.88)
        var path = Path()
        path.move(to: CGPoint(x: center.x, y: center.y - 22))
        path.addLine(to: CGPoint(x: center.x - 18, y: center.y + 16))
        path.addLine(to: CGPoint(x: center.x, y: center.y + 8))
        path.addLine(to: CGPoint(x: center.x + 18, y: center.y + 16))
        path.closeSubpath()
        context.fill(path, with: .color(.cyan))
        context.stroke(path, with: .color(.white), lineWidth: 2)
    }

    private func drawEnemies(context: inout GraphicsContext, size: CGSize) {
        for enemy in enemies {
            let rect = CGRect(x: enemy.x * size.width - 16, y: enemy.y * size.height - 16, width: 32, height: 32)
            context.fill(Path(roundedRect: rect, cornerRadius: 8), with: .color(.pink))
            context.stroke(Path(roundedRect: rect, cornerRadius: 8), with: .color(.white.opacity(0.8)), lineWidth: 2)
        }
    }

    private func drawShots(context: inout GraphicsContext, size: CGSize) {
        for shot in shots {
            let rect = CGRect(x: shot.x * size.width - 2, y: shot.y * size.height - 10, width: 4, height: 14)
            context.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(.yellow))
        }
    }
}

private struct Enemy {
    let x: CGFloat
    let y: CGFloat
    let speed: CGFloat
}

private struct Shot {
    let x: CGFloat
    let y: CGFloat
}

#Preview {
    GameView()
}
