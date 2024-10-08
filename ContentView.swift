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
    // Game state variables
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
                    .foregroundColor(accentColor)
                    .padding()
                
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
                                        if winningIndices.contains(where: { $0 == (row, col) }) {
                                            RoundedRectangle(cornerRadius: 15)
                                                .fill(accentColor.opacity(0.6))
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
                                            .scaleEffect(gameOver ? 1.5 : 1.0)
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
                            .background(accentColor)
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
            playSound(named: "move") // Play sound for the player's move
            if checkForWin() {
                playerScore += 1
                winnerMessage = "Player X wins!"
                gameOver = true
                playSound(named: "win") // Play sound for winning
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
            bestMove = minimaxMove()
        case .hard:
            bestMove = limitedDepthMinimaxMove(depth: 4)
        }
        
        board[bestMove.0][bestMove.1] = currentPlayer
        playSound(named: "move") // Play sound for the AI's move
        
        if checkForWin() {
            aiScore += 1
            winnerMessage = "AI wins!"
            gameOver = true
            playSound(named: "win") // Play sound for winning
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
        let winningPatterns: [[(Int, Int)]] = [
            [(0, 0), (0, 1), (0, 2)], // Row 1
            [(1, 0), (1, 1), (1, 2)], // Row 2
            [(2, 0), (2, 1), (2, 2)], // Row 3
            [(0, 0), (1, 0), (2, 0)], // Column 1
            [(0, 1), (1, 1), (2, 1)], // Column 2
            [(0, 2), (1, 2), (2, 2)], // Column 3
            [(0, 0), (1, 1), (2, 2)], // Diagonal
            [(0, 2), (1, 1), (2, 0)], // Diagonal
        ]
        
        for pattern in winningPatterns {
            let first = board[pattern[0].0][pattern[0].1]
            if first != "" && pattern.allSatisfy({ board[$0.0][$0.1] == first }) {
                winningIndices = pattern
                return true
            }
        }
        return false
    }
    
    // Check for a draw
    func isDraw() -> Bool {
        return board.flatMap { $0 }.allSatisfy { !$0.isEmpty }
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
    
    // Play sound effects
    func playSound(named soundName: String) {
        guard let url = Bundle.main.url(forResource: soundName, withExtension: "wav") else { return }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Error loading sound: \(error)")
        }
    }
    
    // Random AI move
    func randomMove() -> (Int, Int) {
        var emptyCells: [(Int, Int)] = []
        for row in 0..<3 {
            for col in 0..<3 {
                if board[row][col].isEmpty {
                    emptyCells.append((row, col))
                }
            }
        }
        return emptyCells.randomElement() ?? (0, 0)
    }
    
    // Minimax function to evaluate the board state
    private func minimax(depth: Int, isMaximizing: Bool) -> Int {
        if checkForWin() {
            return isMaximizing ? -1 : 1 // Adjust scores for winning
        }
        if isDraw() {
            return 0 // Draw
        }

        if depth == 0 {
            return 0 // No more depth to explore
        }

        if isMaximizing {
            var bestScore = Int.min
            for row in 0..<3 {
                for col in 0..<3 {
                    if board[row][col].isEmpty {
                        board[row][col] = "O" // AI's turn
                        let score = minimax(depth: depth - 1, isMaximizing: false)
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
                        board[row][col] = "X" // Player's turn
                        let score = minimax(depth: depth - 1, isMaximizing: true)
                        board[row][col] = "" // Undo move
                        bestScore = min(score, bestScore)
                    }
                }
            }
            return bestScore
        }
    }
    
    // Minimax AI move
    func minimaxMove() -> (Int, Int) {
        var bestScore = Int.min
        var bestMove = (0, 0)
        
        // Loop through the board to find the best move
        for row in 0..<3 {
            for col in 0..<3 {
                if board[row][col].isEmpty {
                    // Make the move
                    board[row][col] = "O" // AI's move
                    
                    // Calculate the score using minimax
                    let score = minimax(depth: 0, isMaximizing: false)
                    
                    // Undo the move
                    board[row][col] = ""
                    
                    if score > bestScore {
                        bestScore = score
                        bestMove = (row, col)
                    }
                }
            }
        }
        return bestMove
    }
    
    // Limited depth minimax AI move
    func limitedDepthMinimaxMove(depth: Int) -> (Int, Int) {
        var bestScore = Int.min
        var bestMove = (0, 0)
        
        // Iterate through all possible moves
        for row in 0..<3 {
            for col in 0..<3 {
                if board[row][col].isEmpty { // Check if the cell is empty
                    board[row][col] = "O" // Assume AI is "O"
                    
                    // Get the score for this move
                    let score = minimax(depth: depth, isMaximizing: false) // Ensure this call is correct
                    
                    board[row][col] = "" // Undo the move
                    
                    if score > bestScore {
                        bestScore = score
                        bestMove = (row, col)
                    }
                }
            }
        }
        
        return bestMove
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

