import SwiftUI
import Foundation

func padCardLine(_ line: String, width: Int = 9) -> String {
    return line.padding(toLength: width, withPad: " ", startingAt: 0)
}

func generateSimplifiedGoldStack(for balance: Int) -> [(row: String, color: Color)] {
    let denominations = [
        (value: 50, color: Color.yellow), // $50 chips
        (value: 25, color: Color.purple), // $25 chips
        (value: 10, color: Color.green),  // $10 chips
        (value: 5, color: Color.red)      // $5 chips
    ]
    
    var remainingBalance = balance
    var chipRows: [(row: String, color: Color)] = []

    for denomination in denominations {
        let count = remainingBalance / denomination.value
        remainingBalance %= denomination.value
        
        for _ in 0..<count {
            chipRows.append((row: "  █░█", color: denomination.color))
        }
    }

    return chipRows
}

struct ChipRowView: View {
    let row: String
    let color: Color

    var body: some View {
        Text(row)
            .font(.system(size: 16, weight: .bold, design: .monospaced))
            .foregroundColor(color)
            .multilineTextAlignment(.center)
    }
}



//struct GoldStackView: View {
//    let balance: Int
//
//    var body: some View {
//        let chipRows = generateSimplifiedGoldStack(for: balance)
//        
//        VStack(spacing: 10) {
//            ForEach(chipRows.indices, id: \.self) { index in
//                ChipRowView(row: chipRows[index].row, color: chipRows[index].color)
//            }
//
//            Text("💰 Balance: $\(balance)")
//                .font(.system(size: 14, weight: .bold, design: .monospaced))
//                .foregroundColor(.green)
//        }
//        .padding()
//        .background(Color.black.edgesIgnoringSafeArea(.all))
//    }
//}

func renderCard(_ card: Card?, hide: Bool = false) -> String {
    if hide {
        return """
        ╭──────╮
        │░░░░░░│
        │░░░░░░│
        │░ ?? ░│
        │░░░░░░│
        │░░░░░░│
        ╰──────╯
        """
    }

    guard let card = card else {
        return "Invalid Card"
    }

    let rank = card.rank == 1 ? "A" : (card.rank > 10 ? String(card.description.prefix(1)) : "\(card.rank)")
    let suitSymbols: [Suit: String] = [
        .hearts: "♥",
        .diamonds: "♦",
        .clubs: "♣",
        .spades: "♠"
    ]
    let suit = suitSymbols[card.suit] ?? "?"

    // Ensure fixed-width lines for alignment
    return """
    ╭──────╮
    │\(padCardLine("\(rank)    ", width: 6))│
    │      │
    │   \(suit)  │
    │      │
    │ \(padCardLine("   \(rank)", width: 5))│
    ╰──────╯
    """
}

func generateChipLayout(chipStack: [(amount: Int, color: Color)]) -> [[(amount: Int, color: Color)]] {
    var rows: [[(amount: Int, color: Color)]] = []
    var currentIndex = 0

    // Pyramid Rows
    let rowCapacities = [3, 2, 1] // Reverse the order: top row (1), middle row (2), bottom row (3)
    for rowCapacity in rowCapacities {
        if currentIndex < chipStack.count {
            let row = Array(chipStack[currentIndex..<min(currentIndex + rowCapacity, chipStack.count)])
            rows.insert(row, at: 0) // Insert each row at the beginning to flip the pyramid
            currentIndex += rowCapacity
        } else {
            break
        }
    }

    // ZStack Overflow (top-to-bottom for correct alignment)
      if currentIndex < chipStack.count {
          let remainingChips = Array(chipStack[currentIndex..<chipStack.count])
          rows.append(remainingChips) // Add remaining chips as the last row (ZStack)
      }

      return rows
  }

struct ChipButton: View {
    let amount: Int
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                // Outer Solid Circle (Background)
                Circle()
                    .fill(color.opacity(0.8))
                    .frame(width: 60, height: 60)

                // Outer Dotted Stroke
                Circle()
                    .strokeBorder(style: StrokeStyle(lineWidth: 5, dash: [15, 5])) // Dotted stroke
                    .foregroundColor(.white)
                    .frame(width: 54, height: 54)

                // Inner Solid Circle
                Circle()
                    .fill(color.opacity(0.8))
                    .frame(width: 48, height: 48)


                // Chip Value Text
                Text("$\(amount)")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
            }
            .shadow(color: color.opacity(0.5), radius: 3, x: 0, y: 2)
        }
    }
}

struct ContentView: View {
    @StateObject private var game = BlackjackGame(decks: 1)
    @State private var dealtCardIndex: Int = 0 // Track how many cards have been dealt
    @State private var cardOpacity: [Double] = Array(repeating: 0.0, count: 10)
    @State private var cardOffset: [CGSize] = Array(repeating: CGSize(width: 0, height: -500), count: 10)
    @State private var showPlayerTotal: Bool = false
    @State private var showDealerTotal: Bool = false
    @State private var goldStackOpacity: Double = 1.0
    @State private var currentBet: Int = 0 // Current bet amount
    @State private var chipStack: [(amount: Int, color: Color)] = [] // Chips in the stack
    @State private var cardScale: [CGFloat] = Array(repeating: 0.0, count: 10) // Scale for card flip
    @State private var winnings: Int = 0 // Amount won or lost in the round
    @State private var showWinnings: Bool = false // Whether to display winnings prominently
    @State private var chipStackOffset: CGSize = .zero // Animation offset for chips
    

    
    var body: some View {
//        ZStack {
//            // Background Image
//            Image("FeltTable") // Replace with your image asset name
//                .resizable()
//                .brightness(-0.1)
//                .blur(radius: 3)
//                .overlay(
//                    LinearGradient(
//                        gradient: Gradient(colors: [Color.black.opacity(0.2), Color.clear, Color.black.opacity(0.2)]),
//                        startPoint: .top,
//                        endPoint: .bottom
//                    )
//                    )
//                .scaledToFill() // Ensures the image fills the entire view
//                .ignoresSafeArea() // Makes the background extend beyond safe areas
            VStack(spacing: 20) {
                
                
                HStack(alignment: .top, spacing: 20){
                    VStack {
                        Text("Dealer's Hand")
                            .font(.headline)
                            .foregroundColor(.red)
                        HStack(spacing: 100) {
                            // Dealer's cards
                            HStack {
                                ForEach(game.dealerHand.indices, id: \.self) { index in
                                    Text(renderCard(game.dealerHand[safe: index], hide: index == 1 && game.state != .gameOver))
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(.black)
                                        .padding(-4)
                                        .padding(.vertical, -5)
                                        .background(Color.white) // Card background
                                        .cornerRadius(3)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 4)
                                                .stroke(Color.black.opacity(0.6), lineWidth: 1.5) // Subtle border
                                        )
                                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                                        .fixedSize(horizontal: true, vertical: true) // Ensure proper size
                                        .opacity(cardOpacity[index]) // Apply opacity
                                        .offset(cardOffset[index])   // Apply offset
                                        .animation(.easeOut(duration: 0.5), value: cardOpacity[index]) // Apply animation
                                }
                            }
                            
                        }
                        Text("Total: \(game.state != .gameOver ? "Hidden" : "\(game.calculateHandTotal(hand: game.dealerHand))")")
                            .font(.headline)
                            .foregroundColor(.red)
                        
                        if showDealerTotal {
                            Text("Total: \(game.state == .gameOver ? "\(game.calculateHandTotal(hand: game.dealerHand))" : "Hidden")")
                                .font(.headline)
                                .foregroundColor(.blue)
                                .opacity(showDealerTotal ? 1.0 : 0.0)
                                .animation(.easeIn(duration: 0.5), value: showDealerTotal)
                        }
                    }
                    
                    
                    // Deck symbol
                    Text("""
            ╭──────╮╮
            │░░░░░░││
            │░░░░░░││
            │░ ?? ░││
            │░░░░░░││
            │░░░░░░││
            ╰──────╯╯
            """)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.red)
                    .padding(-3)
                    .padding(.vertical, -5)
                    .background(Color.white) // Card background
                    .cornerRadius(3)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.black.opacity(0.2), lineWidth: 2) // Subtle border
                    )
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    .fixedSize(horizontal: true, vertical: true) // Ensure proper size
                }
                // Dealer and Player Hands
                VStack(spacing: 20) {
                    // Winnings Display
                    if showWinnings {
                        VStack(spacing: 0) {
                            // Top border of the box
                            Text("""
                        ╭──────────────────────╮
                        """)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            
                            // Content inside the box
                            Text(winnings > 0 ? "You Won $\(winnings)!" : "BUST!")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(winnings > 0 ? .green : .red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 2)
                            
                            // Bottom border of the box
                            Text("""
                        ╰──────────────────────╯
                        """)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(10)
                        .transition(.scale)
                        .animation(.easeInOut(duration: 3.0), value: showWinnings)
                    }
                    
                    Divider()
                    
                    // Player Section
                    VStack(spacing: 20) {
                        Text("Player's Hand")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        ForEach(game.playerHands.indices, id: \.self) { handIndex in
                            VStack {
                                // Show total for each hand
                                
                                
                                HStack {
                                    ForEach(game.playerHands[handIndex].indices, id: \.self) { cardIndex in
                                        Text(renderCard(game.playerHands[handIndex][safe: cardIndex]))
                                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                                            .foregroundColor(.red)
                                            .padding(-4)
                                            .padding(.vertical, -5)
                                            .background(Color.white) // Card background
                                            .cornerRadius(3)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .stroke(Color.red.opacity(0.6), lineWidth: 1.5) // Subtle border
                                            )
                                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                                            .fixedSize(horizontal: true, vertical: true) // Ensure proper size
                                            .opacity(cardOpacity[cardIndex + handIndex * 5]) // Adjust for each hand
                                            .offset(cardOffset[cardIndex + handIndex * 5])   // Adjust for each hand
                                            .animation(.easeOut(duration: 0.5), value: cardOpacity[cardIndex + handIndex * 5])
                                    }
                                    
                               
                                    
                                    // Generate chip layout
                                    let chipRows = generateChipLayout(chipStack: chipStack)
                                    
                                    VStack(spacing: 5) {
                                        // Render pyramid rows
                                        ForEach(0..<chipRows.count, id: \.self) { rowIndex in
                                            HStack(spacing: 5) {
                                                ForEach(0..<chipRows[rowIndex].count, id: \.self) { chipIndex in
                                                    let chip = chipRows[rowIndex][chipIndex]
                                                    Text("█░█")
                                                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                                                        .foregroundColor(chip.color)
                                                        .padding(2)
                                                        .offset(chipStackOffset) // Optional animation offset
                                                        .animation(.easeOut(duration: 0.5), value: chipStackOffset)
                                                }
                                            }
                                            .opacity(rowIndex < 3 ? 1.0 : 0.8) // Pyramid rows are fully visible, ZStack rows have slight transparency
                                        }
                                        // Add overflow visualization (ZStack for remaining chips)
                                        if chipRows.count > 3 {
                                            ZStack {
                                                ForEach(chipRows[3].indices.reversed(), id: \.self) { overflowIndex in
                                                    let chip = chipRows[3][overflowIndex]
                                                    Text("█░█")
                                                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                                                        .foregroundColor(chip.color)
                                                        .padding(2)
                                                        .offset(CGSize(width: 0, height: CGFloat(-overflowIndex * 10))) // Flip overflow from bottom to top
                                                        .animation(.easeOut(duration: 0.5), value: chipStackOffset)
                                                }
                                            }
                                        }
                                    }
                                    if showPlayerTotal {
                                        Text("Total: \(game.calculateHandTotal(hand: game.playerHands[handIndex]))")
                                            .font(.headline)
                                            .foregroundColor(.green)
                                    }
                                    
                                }
                                
                                
                                
                                
                                
                            }
                        }
                        
                    }
                }
                .padding()
                
                
                // Gold Stack and Balance
                //            VStack {
                //                GoldStackView(balance: game.playerBalance)
                //                    .opacity(goldStackOpacity)
                //                    .animation(.easeInOut(duration: 0.5), value: goldStackOpacity)
                //            }
                
                Divider()
                // Action Buttons
                HStack(spacing: 5) {
                    
                    if game.state == .waitingForBet {
                        VStack(spacing: 10) {
                            // Display Balance
                            Text("💰 Balance: $\(game.playerBalance)")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(.green)
                            
                            // Strategy Hint Placeholder
                            Text("""
                        Current Bet: $\(currentBet)
                        """)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.yellow)
                            .multilineTextAlignment(.center)
                            .padding()
                            .cornerRadius(10)
                            
                            // Betting Buttons
                            HStack(spacing: 10) {
                                ForEach([5, 10, 25, 50], id: \.self) { amount in
                                    let boxColor: Color = amount == 50 ? .gold : amount == 25 ? .purple : amount == 10 ? .green : .red
                                    
                                    ChipButton(amount: amount, color: boxColor) {
                                        currentBet += amount
                                        chipStack.append((amount: amount, color: boxColor))
                                    }
                                }
                            }
                            
                            // Action Buttons
                            HStack(spacing: 20) {
                                // Clear Bet Button
                                Button(action: {
                                    currentBet = 0
                                    chipStack.removeAll()
                                }) {
                                    Text("""
                                ╭───────────╮
                                │ Clear Bet │
                                ╰───────────╯
                                """)
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                    .padding()
                                    
                                }
                                
                                // Deal Button
                                Button(action: {
                                    if currentBet > 0 {
                                        game.placeBet(amount: currentBet)
                                        dealInitialCards()
                                    }
                                }) {
                                    Text("""
                                ╭──────────╮
                                │   DEAL   │
                                ╰──────────╯
                                """)
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(currentBet > 0 ? Color.green : Color.white)
                                    .padding()
                                }
                                .disabled(currentBet == 0)
                            }
                        }
                        .padding()
                        .cornerRadius(10)
                    } else if game.state == .playerTurn {
                        VStack(spacing: 10) {
                            Text("💰 Balance: $\(game.playerBalance)")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(.green)
                            Text("📊 Strategy Hint: \(game.strategyHint(for: game.playerHand, dealerUpCard: game.dealerHand.first))")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(.yellow)
                                .padding()
                            
                            HStack(spacing: 20) {
                                // Hit Button
                                Button(action: {
                                    dealNextPlayerCard()
                                }) {
                                    Text("""
                                ╭──────────╮
                                │   HIT    │
                                ╰──────────╯
                                """)
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.green.opacity(0.8), Color.green.opacity(0.5)]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .foregroundColor(.white)
                                }
                                .padding()
                                
                                
                                // Stand Button
                                Button(action: {
                                    revealDealerTotal()
                                    game.resolveGame()
                                }) {
                                    Text("""
                                ╭──────────╮
                                │   STAND  │
                                ╰──────────╯
                                """)
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                }
                                .padding()
                            }
                        }
                    } else if game.state == .gameOver {
                        Button(action: {
                            resetGame()
                        }) {
                            Text("Play Again")
                                .padding()
                                .background(Color.orange)
                                .cornerRadius(8)
                                .foregroundColor(.white)
                        }
                    }
                }
                
                
            }
            .padding()
        }
//    }

    // MARK: - Game Logic with Animations

    private func dealInitialCards() {
        game.dealInitialCards() // Prepare initial cards for player and dealer
        game.currentHandIndex = 0 // Ensure index is reset
        showPlayerTotal = false
        showDealerTotal = false

        let delay = 1.0 // Delay between each card being dealt

        // Define the sequence of dealing
        let dealSequence = [
            ("player", 0),  // Player 1
            ("dealer", 0),  // Dealer 1
            ("player", 1),  // Player 2
            ("dealer", 1)   // Dealer 2
        ]

        // Animate each card in the sequence
        for (index, deal) in dealSequence.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + (delay * Double(index))) {
                if deal.0 == "player" {
                    // Player card animation
                    withAnimation(.easeOut(duration: 0.5)) {
                        cardOpacity[deal.1] = 1.0 // Fade in
                        cardOffset[deal.1] = .zero // Slide into position
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            cardScale[deal.1] = 1.0 // Flip effect
                        }
                    }
                } else if deal.0 == "dealer" {
                    // Dealer card animation
                    withAnimation(.easeOut(duration: 0.5)) {
                        cardOpacity[deal.1 + 5] = 1.0 // Fade in
                        cardOffset[deal.1 + 5] = .zero // Slide into position
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            cardScale[deal.1 + 5] = (deal.1 == 0 || showDealerTotal) ? 1.0 : 0.0 // Flip only first card or reveal hidden card when ready
                        }
                    }
                }

                // Show totals once all cards are dealt
                if index == dealSequence.count - 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        showPlayerTotal = true
                        if game.state == .gameOver {
                            showDealerTotal = true
                        }
                    }
                }
            }
        }
    }

    private func dealNextPlayerCard() {
        if let newCard = game.deck.dealCard() {
            game.playerHand.append(newCard)
            let index = game.playerHand.count - 1

            // Animate new card from the deck to the player's hand
            cardOpacity[index] = 0.0
            cardOffset[index] = CGSize(width: 100, height: -200) // Starting near the deck
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.5)) {
                    cardOpacity[index] = 1.0
                    cardOffset[index] = .zero // Move to the hand position
                }
            }
        }
    }

    private func revealDealerTotal() {
        showDealerTotal = true

        // Calculate winnings
        let dealerTotal = game.calculateHandTotal(hand: game.dealerHand)
        let playerTotal = game.calculateHandTotal(hand: game.playerHand)

        if playerTotal > dealerTotal && playerTotal <= 21 || dealerTotal > 21 {
            winnings = currentBet * 2 // Double the bet on a win
            game.playerBalance += winnings
        } else if playerTotal == dealerTotal {
            winnings = currentBet // Return the bet on a tie
            game.playerBalance += winnings
        } else {
            winnings = 0 // Lose the bet
            
            // Animate chips to the dealer
              DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                  withAnimation(.easeInOut(duration: 0.5)) {
                      chipStackOffset = CGSize(width: 100, height: -200) // Adjust as needed for dealer
                  }
              }
        }

        // Show the winnings prominently
        showWinnings = true

        // Animate chips back to the player
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.5)) {
                chipStackOffset = CGSize(width: -100, height: 200) // Adjust as needed
            }
        }

        // Reset chips and hide winnings after the animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.5)) {
                chipStack.removeAll()
                chipStackOffset = .zero
                showWinnings = false
            }
        }
    }

    private func resetGame() {
        game.resetGame()
        cardOpacity = Array(repeating: 0.0, count: 10)
        cardOffset = Array(repeating: CGSize(width: 0, height: -500), count: 10)
        showPlayerTotal = false
        showDealerTotal = false
    }
}
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension Color {
    static let gold = Color(red: 1.0, green: 0.84, blue: 0.0) // Gold RGB values
}
