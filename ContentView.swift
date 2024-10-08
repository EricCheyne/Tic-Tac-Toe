//
//  ContentView.swift
//  Tic-Tac-Toe
//
//  Created by Eric Cheyne on 10/7/24.
//

import SwiftUI
import AVFoundation

// Define Difficulty Levels
enum DifficultyLevel {
    case easy
    case medium
    case hard
}

struct ContentView: View {
    
    
    @State private var board: [[String]] = [["", "", ""], ["", "", ""], ["", "", ""]]
    @State private var currentPlayer = "X"
    @State private var gameOver = false
    @State private var winnerMessage = ""
    @State private var playerScore = 0
    @State private var aiScore = 0
    @State private var drawCount = 0
    @State private var difficulty: DifficultyLevel = .medium
    @State private var winningIndices: [(Int, Int)] = []
    @State private var audioPlayer: AVAudioPlayer?
    
    // Accent color
    let accentColor: Color = {
        if let color = Color(hex: "#FF6F61") {
            return color
        } else {
            return Color.red // Fallback color
        }
    }()

    var body: some View {
        ZStack {
            // Background
            LinearGradient(gradient: Gradient(colors: [.blue.opacity(0.4), .purple.opacity(0.4)]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack {
                Text("Tic-Tac-Toe")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding()

                // Display Current Turn or Game Over Message
                if gameOver {
                    Text(winnerMessage)
                        .font(.title)
                        .bold()
                        .foregroundColor(.yellow)
                        .padding()
                        .transition(.scale)
                } else {
                    Text("Current Player: \(currentPlayer)")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .transition(.opacity)
                }

                // Difficulty Selector
                Picker("Select Difficulty", selection: $difficulty) {
                    Text("Easy").tag(DifficultyLevel.easy)
                    Text("Medium").tag(DifficultyLevel.medium)
                    Text("Hard").tag(DifficultyLevel.hard)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                // Display Scores
                HStack {
                    VStack {
                        Text("Player (X)")
                            .font(.headline)
                        Text("\(playerScore)")
                            .font(.title)
                            .padding()
                    }
                    .foregroundColor(.blue)

                    VStack {
                        Text("AI (O)")
                            .font(.headline)
                        Text("\(aiScore)")
                            .font(.title)
                            .padding()
                    }
                    .foregroundColor(.red)

                    VStack {
                        Text("Draws")
                            .font(.headline)
                        Text("\(drawCount)")
                            .font(.title)
                            .padding()
                    }
                    .foregroundColor(.gray)
                }

                // Game Board
                VStack(spacing: 10) {
                    ForEach(0..<3) { row in
                        HStack(spacing: 10) {
                            ForEach(0..<3) { col in
                                Button(action: {
                                    playerMove(row: row, col: col)
                                }) {
                                    ZStack {
                                        // Highlight winning cells
                                        if winningIndices.contains(where: { $0 == (row, col) }) {
                                            RoundedRectangle(cornerRadius: 15)
                                                .fill(Color.green.opacity(0.6))
                                                .frame(width: 100, height: 100)
                                                .transition(.scale)
                                        } else {
                                            RoundedRectangle(cornerRadius: 15)
                                                .fill(Color.white.opacity(0.3))
                                                .frame(width: 100, height: 100)
                                        }
                                        Text(board[row][col])
                                            .font(.system(size: 60, weight: .bold))
                                            .foregroundColor(board[row][col] == "X" ? .blue : .red)
                                    }
                                }
                                .animation(.easeInOut(duration: 0.3))
                            }
                        }
                    }
                }
                .padding()

                // Play Again and Reset Buttons
                HStack(spacing: 20) {
                    Button(action: resetGame) {
                        Text("Play Again")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }

                    Button(action: resetScores) {
                        Text("Reset Scores")
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.top)
            }
            .padding()
        }
        .alert(isPresented: $gameOver) {
            Alert(title: Text("Game Over"), message: Text(winnerMessage), dismissButton: .default(Text("OK"), action: resetGame))
        }
    }

    // Player makes a move
    func playerMove(row: Int, col: Int) {
        if board[row][col].isEmpty && currentPlayer == "X" {
            board[row][col] = currentPlayer
            if checkForWin() {
                playerScore += 1
                winnerMessage = "Player X wins!"
                gameOver = true
            } else if isDraw() {
                drawCount += 1
                winnerMessage = "It's a draw!"
                gameOver = true
            } else {
                currentPlayer = "O" // Switch to AI
                aiMove() // AI makes a move
            }
        }
    }

    // AI makes a move
    func aiMove() {
        let bestMove: (Int, Int)
        
        switch difficulty {
        case .easy:
            bestMove = randomMove()
        case .medium:
            bestMove = limitedDepthMinimaxMove()
        case .hard:
            bestMove = fullMinimaxMove()
        }

        board[bestMove.0][bestMove.1] = currentPlayer

        if checkForWin() {
            aiScore += 1
            winnerMessage = "AI wins!"
            gameOver = true
        } else if isDraw() {
            drawCount += 1
            winnerMessage = "It's a draw!"
            gameOver = true
        } else {
            currentPlayer = "X" // Switch back to player
        }
    }

    // Check for a winning pattern
    func checkForWin() -> Bool {
        let winPatterns = [
            [(0, 0), (0, 1), (0, 2)],
            [(1, 0), (1, 1), (1, 2)],
            [(2, 0), (2, 1), (2, 2)],
            [(0, 0), (1, 0), (2, 0)],
            [(0, 1), (1, 1), (2, 1)],
            [(0, 2), (1, 2), (2, 2)],
            [(0, 0), (1, 1), (2, 2)],
            [(0, 2), (1, 1), (2, 0)]
        ]

        for pattern in winPatterns {
            let p1 = board[pattern[0].0][pattern[0].1]
            let p2 = board[pattern[1].0][pattern[1].1]
            let p3 = board[pattern[2].0][pattern[2].1]

            if !p1.isEmpty && p1 == p2 && p2 == p3 {
                winningIndices = pattern
                return true
            }
        }

        return false
    }

    // Check if the game is a draw
    func isDraw() -> Bool {
        return !board.flatMap { $0 }.contains("")
    }

    // Generate random move for Easy difficulty
    func randomMove() -> (Int, Int) {
        var availableMoves: [(Int, Int)] = []
        for row in 0..<3 {
            for col in 0..<3 {
                if board[row][col].isEmpty {
                    availableMoves.append((row, col))
                }
            }
        }
        return availableMoves.randomElement()!
    }

    func limitedDepthMinimaxMove() -> (Int, Int) {
        // Placeholder logic for a simple minimax with limited depth
        return randomMove()
    }

    func fullMinimaxMove() -> (Int, Int) {
        var bestScore = Int.min
        var bestMove: (Int, Int) = (0, 0)

        for row in 0..<3 {
            for col in 0..<3 {
                if board[row][col].isEmpty {
                    board[row][col] = currentPlayer // AI's move
                    let score = minimax(depth: 0, isMaximizing: false)
                    board[row][col] = "" // Undo move

                    if score > bestScore {
                        bestScore = score
                        bestMove = (row, col)
                    }
                }
            }
        }
        return bestMove
    }

    func minimax(depth: Int, isMaximizing: Bool) -> Int {
        if checkForWin() {
            return isMaximizing ? -1 : 1 // Win for AI or Player
        } else if isDraw() {
            return 0 // Draw
        }

        if isMaximizing {
            var bestScore = Int.min
            for row in 0..<3 {
                for col in 0..<3 {
                    if board[row][col].isEmpty {
                        board[row][col] = currentPlayer // AI's move
                        let score = minimax(depth: depth + 1, isMaximizing: false)
                        board[row][col] = "" // Undo move
                        bestScore = max(score, bestScore)
                    }
                }
            }
            return bestScore
        } else {
            var bestScore = Int.max
            for row in 0..<3 {
                for col in 0..<3 {
                    if board[row][col].isEmpty {
                        board[row][col] = "X" // Player's move
                        let score = minimax(depth: depth + 1, isMaximizing: true)
                        board[row][col] = "" // Undo move
                        bestScore = min(score, bestScore)
                    }
                }
            }
            return bestScore
        }
    }

    // Reset the game board
    func resetGame() {
        board = [["", "", ""], ["", "", ""], ["", "", ""]]
        currentPlayer = "X"
        gameOver = false
        winnerMessage = ""
        winningIndices = []
    }

    // Reset the scores
    func resetScores() {
        playerScore = 0
        aiScore = 0
        drawCount = 0
        resetGame()
    }
}

// Extension to create Color from HEX
extension Color {
    init?(hex: String) {
        let r, g, b: Double
        
        let scanner = Scanner(string: hex)
        scanner.currentIndex = scanner.string.startIndex
        
        if hex.hasPrefix("#") {
            scanner.currentIndex = hex.index(after: scanner.currentIndex)
        }
        
        var rgb: UInt64 = 0
        guard scanner.scanHexInt64(&rgb) else { return nil }
        
        r = Double((rgb & 0xFF0000) >> 16) / 255.0
        g = Double((rgb & 0x00FF00) >> 8) / 255.0
        b = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}
