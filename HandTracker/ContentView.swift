import SwiftUI
import Foundation

// MARK: - Game Models

enum Suit: String, CaseIterable {
    case hearts, diamonds, clubs, spades
}

struct Card: Equatable {
    let rank: Int
    let suit: Suit
    
    var value: Int {
        let val = rank > 10 ? 10 : rank
        print("Card value calculated: \(val) for rank \(rank)")
        return val
    }
    
    var description: String {
        let rankString: String
        switch rank {
        case 1: rankString = "Ace"
        case 11: rankString = "Jack"
        case 12: rankString = "Queen"
        case 13: rankString = "King"
        default: rankString = "\(rank)"
        }
        print("Card description generated: \(rankString) of \(suit.rawValue.capitalized)")
        return "\(rankString) of \(suit.rawValue.capitalized)"
    }
    
    // Hi-Lo Card Counting Value
    var hiLoValue: Int {
        let val = {
            switch rank {
            case 2...6: return +1
            case 7...9: return 0
            default: return -1
            }
        }()
        print("Card Hi-Lo value: \(val) for rank \(rank)")
        return val
    }
}

// MARK: - Deck

class Deck {
    var cards: [Card] = []
    var cardComposition: [Int: Int] = [:] // Key: Rank, Value: Count

    init(decks: Int = 1) {
        print("Initializing deck with \(decks) deck(s)")
        for _ in 0..<decks {
            for suit in Suit.allCases {
                for rank in 1...13 {
                    let card = Card(rank: rank, suit: suit)
                    cards.append(card)
                    cardComposition[rank, default: 0] += 1
                }
            }
        }
        shuffle()
    }

    func shuffle() {
        print("Shuffling deck")
        for i in stride(from: cards.count - 1, through: 1, by: -1) {
            let randomIndex = Int.random(in: 0...i)
            cards.swapAt(i, randomIndex)
        }
        resetCardComposition()
    }
    
    func reshuffleDeck() {
        print("Reshuffling deck...")
        cards.removeAll()
        for suit in Suit.allCases {
            for rank in 1...13 {
                let card = Card(rank: rank, suit: suit)
                cards.append(card)
            }
        }
        shuffle()
    }

    func dealCard() -> Card? {
        if cards.isEmpty {
            print("Deck is empty. Automatically reshuffling...")
            reshuffleDeck()
        }

        guard !cards.isEmpty else {
            print("Error: Deck is still empty after reshuffling.")
            return nil
        }

        let card = cards.removeLast()
        cardComposition[card.rank, default: 0] -= 1
        print("Dealt card: \(card.description)")
        return card
    }

    func resetCardComposition() {
        print("Resetting card composition")
        cardComposition = [:]
        for card in cards {
            cardComposition[card.rank, default: 0] += 1
        }
    }

    func getCardComposition() -> [Int: Int] {
        print("Returning current card composition")
        return cardComposition
    }

    var remainingDecks: Double {
        let decks = Double(cards.count) / 52.0
        print("Remaining decks calculated: \(decks)")
        return decks
    }
}

// MARK: - Game State

enum GameState: String {
    case waitingForBet = "Waiting for Bet"
    case playerTurn = "Player's Turn"
    case dealerTurn = "Dealer's Turn"
    case gameOver = "Game Over"
}

// MARK: - Blackjack Game

struct BlackjackGame {
    var deck: Deck
    var playerHand: [Card] = []
    var dealerHand: [Card] = []
    var state: GameState = .waitingForBet
    var runningCount: Int = 0
    var dealtCards: [Card] = [] // History of all dealt cards
    // Properties to manage split hands
    var playerSplitHands: [[Card]] = [] // Array of hands after a split
    var currentHandIndex: Int = 0       // Index of the active hand
    
    var playerBalance: Int = 100 // Initial balance
    var currentBet: Int = 0      // Current bet for the round

    init(decks: Int = 1) {
         print("Initializing BlackjackGame with \(decks) deck(s)")
         self.deck = Deck(decks: decks)
     }
    
    
    func isSoftHand(_ hand: [Card]) -> Bool {
        let total = calculateHandTotal(hand: hand)
        let hasAce = hand.contains { $0.rank == 1 }
        return hasAce && total <= 21 && total - 10 >= 11 // Contains an Ace valued as 11
    }
    
    func strategyHint(for hand: [Card], dealerUpCard: Card?) -> String {
        guard let dealerUpCard = dealerUpCard else { return "No hint available." }
        let dealerValue = dealerUpCard.value
        let total = calculateHandTotal(hand: hand)

        if hand.count == 2, hand[0].rank == hand[1].rank { // Pair splitting
            switch hand[0].rank {
            case 1: return "Split Aces"
            case 8: return "Split Eights"
            case 9: return dealerValue == 7 || dealerValue >= 10 ? "Stand" : "Split"
            case 10: return "Stand (Never Split Tens)"
            default: return dealerValue >= 2 && dealerValue <= 7 ? "Split" : "Hit"
            }
        }

        if isSoftHand(hand) { // Soft totals
            switch total {
            case 13...17: return dealerValue >= 7 ? "Hit" : "Double Down"
            case 18: return dealerValue >= 9 ? "Hit" : (dealerValue >= 3 && dealerValue <= 6 ? "Double Down" : "Stand")
            default: return "Stand"
            }
        } else { // Hard totals
            switch total {
            case 4...8: return "Hit"
            case 9: return dealerValue >= 3 && dealerValue <= 6 ? "Double Down" : "Hit"
            case 10: return dealerValue <= 9 ? "Double Down" : "Hit"
            case 11: return "Double Down"
            case 12: return dealerValue >= 4 && dealerValue <= 6 ? "Stand" : "Hit"
            case 13...16: return dealerValue <= 6 ? "Stand" : "Hit"
            default: return "Stand"
            }
        }
    }
    
    static func basicStrategyTable() -> String {
        let headers = ["Your Total", "Dealer 2-6", "Dealer 7-A"]
        let rows = [
            ["Hard 4-8", "Hit", "Hit"],
            ["Hard 9", "Double Down", "Hit"],
            ["Hard 10", "Double Down", "Hit"],
            ["Hard 11", "Double Down", "Double Down"],
            ["Hard 12", "Stand", "Hit"],
            ["Hard 13-16", "Stand", "Hit"],
            ["Hard 17+", "Stand", "Stand"],
            ["Soft 13-17", "Hit", "Hit"],
            ["Soft 18", "Stand/Double", "Hit"],
            ["Soft 19+", "Stand", "Stand"],
            ["Pair Aces/8s", "Split", "Split"],
            ["Pair 9s", "Split/Stand", "Stand"],
            ["Pair 10s", "Stand", "Stand"]
        ]
        return asciiTable(headers: headers, rows: rows)
    }
    
    mutating func canTakeInsurance() -> Bool {
        // Insurance is available if dealer's up card is an Ace
        guard dealerHand.count == 2, dealerHand[1].rank == 1 else {
            return false
        }
        return true
    }
    
    
    mutating func takeInsurance() {
        guard canTakeInsurance() else {
            print("Insurance is not available.")
            return
        }

        let insuranceBet = currentBet / 2
        guard playerBalance >= insuranceBet else {
            print("Not enough balance to take insurance.")
            return
        }

        print("Taking insurance...")
        playerBalance -= insuranceBet
        
        

        // Reveal dealer's hand and check for blackjack
        let dealerTotal = calculateHandTotal(hand: dealerHand)
        if dealerTotal == 21 {
            print("Dealer has blackjack. Insurance pays out.")
            playerBalance += insuranceBet * 3 // 2:1 payout + original bet back
        } else {
            print("Dealer does not have blackjack. Insurance lost.")
        }
    }
    
    mutating func canSplit() -> Bool {
        guard playerHand.count == 2, // Ensure only two cards are in hand
              playerHand[0].rank == playerHand[1].rank, // Both cards must have the same rank
              playerBalance >= currentBet else { // Check if player has enough balance
            print("Player cannot split.")
            return false
        }
        return true
    }
    
    mutating func canDoubleDown() -> Bool {
        // Player can double down if they have exactly two cards and enough balance
        return playerHand.count == 2 && playerBalance >= currentBet
    }
    
    mutating func doubleDown() {
        guard canDoubleDown() else {
            print("Cannot double down.")
            return
        }

        print("Doubling down...")
        playerBalance -= currentBet
        currentBet *= 2

        // Deal one card
        if let newCard = deck.dealCard() {
            playerHand.append(newCard)
            updateRunningCount(with: [newCard])
            print("Player hand after doubling down: \(playerHand.map { $0.description })")
        }

        // Check hand total to proceed
        if calculateHandTotal(hand: playerHand) > 21 {
            print("Player busts after doubling down.")
            resolveBet(won: false)
            state = .gameOver
        } else {
            dealerTurn()
        }
    }
    
    mutating func doubleDownSplitHand() {
        guard currentHandIndex < playerSplitHands.count,
              playerSplitHands[currentHandIndex].count == 2,
              playerBalance >= currentBet else {
            print("Cannot double down on this hand.")
            return
        }

        print("Doubling down on split hand \(currentHandIndex + 1)...")
        playerBalance -= currentBet
        currentBet *= 2

        if let newCard = deck.dealCard() {
            playerSplitHands[currentHandIndex].append(newCard)
            updateRunningCount(with: [newCard])
            print("Split hand \(currentHandIndex + 1) after doubling down: \(playerSplitHands[currentHandIndex].map { $0.description })")
        }

        moveToNextHand()
    }
    
    mutating func splitHand() {
        guard canSplit() else { return }

        print("Splitting hand...")
        // Create a new hand by splitting the player's cards
        let newHand = [playerHand.removeLast()]
        playerSplitHands = [playerHand, newHand]

        // Deduct an additional bet
        playerBalance -= currentBet

        // Deal one card to each split hand
        if let cardForFirstHand = deck.dealCard(),
           let cardForSecondHand = deck.dealCard() {
            playerSplitHands[0].append(cardForFirstHand)
            playerSplitHands[1].append(cardForSecondHand)
        }

        // Start with the first hand
        currentHandIndex = 0
        playerHand = playerSplitHands[currentHandIndex]
        state = .playerTurn

        print("Player hands after split: \(playerSplitHands.map { $0.map { $0.description } })")
    }

    mutating func placeBet(amount: Int) -> Bool {
        print("Placing bet: \(amount)")
        let minBet = 5
        let maxBet = 100

        guard amount >= minBet, amount <= maxBet else {
            print("Error: Bet must be between \(minBet) and \(maxBet).")
            return false
        }
        guard amount <= playerBalance else {
            print("Error: Insufficient balance to place bet.")
            return false
        }

        currentBet = amount
        playerBalance -= amount
        print("Bet placed successfully. New balance: \(playerBalance)")
        state = .waitingForBet
        return true
    }

    mutating func resolveBet(won: Bool, blackjack: Bool = false) {
        if won {
            if blackjack {
                // 3:2 payout for blackjack
                playerBalance += Int(Double(currentBet) * 2.5) // 2.5x payout
                print("Player won with a blackjack! New balance: \(playerBalance)")
            } else {
                // Standard 1:1 payout
                playerBalance += currentBet * 2
                print("Player won. New balance: \(playerBalance)")
            }
        } else {
            print("Player lost. Balance remains: \(playerBalance)")
        }
        currentBet = 0
        print("resolveBet called with won: \(won), blackjack: \(blackjack)")
    }
    
    func calculateHandTotal(hand: [Card]) -> Int {
        var total = 0
        var hasAce = false
        
        for card in hand {
            total += card.value
            if card.rank == 1 { // Ace
                hasAce = true
            }
        }
        
        if hasAce && total + 10 <= 21 {
            total += 10
        }
        print("Hand total calculated: \(total)")
        return total
    }
    
    mutating func dealInitialCards() {
        print("Dealing initial cards...")
        playerHand.removeAll()
        dealerHand.removeAll()

        if deck.cards.count < 20 { // Threshold for reshuffling
            print("Low deck count. Reshuffling...")
            deck.reshuffleDeck()
        }

        if let playerCard1 = deck.dealCard(),
           let playerCard2 = deck.dealCard(),
           let dealerCard1 = deck.dealCard(),
           let dealerCard2 = deck.dealCard() {
            playerHand = [playerCard1, playerCard2]
            dealerHand = [dealerCard1, dealerCard2]

            updateRunningCount(with: playerHand + dealerHand)

                // Check for natural blackjack and handle insurance
                if calculateHandTotal(hand: playerHand) == 21 {
                    if calculateHandTotal(hand: dealerHand) == 21 {
                        print("Push: Both player and dealer have blackjack!")
                        playerBalance += currentBet // Refund bet
                    } else {
                        print("Player wins with a blackjack!")
                        resolveBet(won: true, blackjack: true)
                    }
                    state = .gameOver
                } else if calculateHandTotal(hand: dealerHand) == 21 {
                    print("Dealer wins with a blackjack!")
                    state = .gameOver
                } else if canTakeInsurance() {
                    // Offer insurance to the player
                    print("Dealer's up card is an Ace. Insurance is available.")
                } else {
                    state = .playerTurn
                }
            } else {
                print("Error: Not enough cards to deal a new hand.")
                state = .gameOver
            }
        }
    
    mutating func playerHit() -> Card? {
        print("Player chose to hit")
        guard state == .playerTurn, let card = deck.dealCard() else {
            print("Invalid action: either not player's turn or no cards available.")
            return nil
        }
        playerHand.append(card)
        updateRunningCount(with: [card])
        print("Player hand after hit: \(playerHand.map { $0.description })")

        // Check if the current hand is a bust
        if calculateHandTotal(hand: playerHand) > 21 {
            print("Player busted on current hand.")
            moveToNextHand()
        }
        return card
    }

    // Move to the next hand if the current hand is finished
    mutating func moveToNextHand() {
        currentHandIndex += 1
        if currentHandIndex < playerSplitHands.count {
            playerHand = playerSplitHands[currentHandIndex]
            print("Switching to next hand: \(playerHand.map { $0.description })")
        } else {
            print("All hands played. Dealer's turn begins.")
            state = .dealerTurn
        }
    }
    
    // Helper to check for soft 17
    func hasSoft17(_ hand: [Card]) -> Bool {
        let total = calculateHandTotal(hand: hand)
        let hasAce = hand.contains { $0.rank == 1 }
        return hasAce && total == 17
    }
    
    
    mutating func dealerTurn() {
        print("[Dealer's Turn] Dealer starts with hand: \(dealerHand.map { $0.description })")
        while calculateHandTotal(hand: dealerHand) < 17 || (calculateHandTotal(hand: dealerHand) == 17 && hasSoft17(dealerHand)) {
            if let card = deck.dealCard() {
                dealerHand.append(card)
                updateRunningCount(with: [card])
                print("[Dealer's Turn] Dealer drew card: \(card.description)")
            } else {
                print("[Dealer's Turn] Error: Deck is empty.")
                break
            }
        }

        // Compare dealer's hand with each player's split hand
        for (index, hand) in playerSplitHands.enumerated() {
            let playerTotal = calculateHandTotal(hand: hand)
            let dealerTotal = calculateHandTotal(hand: dealerHand)
            print("Final dealer total: \(dealerTotal), player hand \(index + 1) total: \(playerTotal)")

            if dealerTotal > 21 || playerTotal > dealerTotal {
                resolveBet(won: true)
            } else if playerTotal < dealerTotal {
                resolveBet(won: false)
            } else {
                print("Push: Player hand \(index + 1) and dealer have the same total!")
                playerBalance += currentBet // Refund bet for a tie
            }
        }

        state = .gameOver
    }
    
    mutating func updateRunningCount(with cards: [Card]) {
        for card in cards {
            runningCount += card.hiLoValue
            dealtCards.append(card)
            print("Updated running count: \(runningCount)")
        }
    }
    
    func trueCount() -> Double {
          let count = deck.remainingDecks > 0 ? Double(runningCount) / deck.remainingDecks : 0
          print("True count calculated: \(count)")
          return count
      }
    
    mutating func resetGame() {
        print("Resetting game")
        playerHand.removeAll()
        dealerHand.removeAll()
        currentBet = 0
        state = .waitingForBet
    }
}

func monteCarloSimulation(
    deck: Deck,
    game: BlackjackGame,
    playerHand: [Card],
    dealerHand: [Card],
    iterations: Int = 100000
) -> (bestCard: String, probabilities: [(String, Double)]) {
    print("\n[DEBUG] Starting Monte Carlo Simulation")
    
    let currentPlayerTotal = game.calculateHandTotal(hand: game.playerHand)
    let dealerTotal = game.calculateHandTotal(hand: game.dealerHand)

    print("Player total: \(currentPlayerTotal), Dealer total: \(dealerTotal)")
    
    // Cache the deck composition for simulation
    let deckComposition = deck.getCardComposition()
    print("[DEBUG] Deck composition before simulation: \(deckComposition)")
    
    // Track how often each card rank improves the player's chances
    var cardCounts: [Int: Int] = [:]

    // Simulation loop
    for _ in 0..<iterations {
        // Simulate the deck state
        var simulatedDeck = deck.cards.shuffled()
        
        // Draw a card for the player
        if let drawnCard = simulatedDeck.popLast() {
            let newPlayerTotal = currentPlayerTotal + drawnCard.value
            
            // Check if the new total is favorable (<= 21 and beats dealer)
            if newPlayerTotal <= 21 && newPlayerTotal >= dealerTotal {
                cardCounts[drawnCard.rank, default: 0] += 1
            }
        }
    }
    
    // Calculate probabilities for each rank
    let probabilities = (1...13).compactMap { rank -> (String, Double)? in
        guard let count = cardCounts[rank] else { return nil }
        let probability = Double(count) / Double(iterations) * 100
        let rankName = rank > 10 ? ["Jack", "Queen", "King"][rank - 11] : (rank == 1 ? "Ace" : "\(rank)")
        return (rankName, probability)
    }
    .sorted { $0.1 > $1.1 } // Sort by probability descending
    
    // Determine the best card
    let bestCard = probabilities.first?.0 ?? "No favorable card"

    print("[DEBUG] Best card: \(bestCard), Probabilities: \(probabilities)\n")
    
    return (bestCard, probabilities)
}

func asciiTable(headers: [String], rows: [[String]]) -> String {
    guard !headers.isEmpty else { return "Error: No headers provided." }
    guard rows.allSatisfy({ $0.count == headers.count }) else { return "Error: Row and header column counts do not match." }

    // Helper function to create a single row with padding
    func createRow(columns: [String]) -> String {
        columns.map { " \($0.padding(toLength: 12, withPad: " ", startingAt: 0)) " }
            .joined(separator: "║")
    }

    // Build table parts
    let topBorder = "╔" + Array(repeating: "═══════", count: headers.count).joined(separator: "╦") + "╗"
    let headerRow = "║" + createRow(columns: headers) + "║"
    let divider = "╠" + Array(repeating: "════════════", count: headers.count).joined(separator: "╬") + "╣"
    let dataRows = rows.map { "║" + createRow(columns: $0) + "║" }.joined(separator: "\n")
    let bottomBorder = "╚" + Array(repeating: "═══════", count: headers.count).joined(separator: "╩") + "╝"

    // Combine all parts
    return [topBorder, headerRow, divider, dataRows, bottomBorder].joined(separator: "\n")
}

func asciiTableRow(columns: [String]) -> String {
    let row = columns.map { column in
        let paddedColumn = column.padding(toLength: 12, withPad: " ", startingAt: 0)
        return " \(paddedColumn) "
    }.joined(separator: "║")
    return "║" + row + "║"
}

struct AsciiTableView: View {
    let headers = ["Rank", "Suit", "Value"]
    let rows = [
        ["A", "Spades", "11"],
        ["10", "Hearts", "10"],
        ["5", "Clubs", "5"]
    ]
    
    var body: some View {
        Text(asciiTable(headers: headers, rows: rows))
            .font(.system(size: 14, weight: .bold, design: .monospaced))
            .foregroundColor(.red)
            .padding()
            .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}

/// Helper function to render a single card as ASCII with Unicode suit symbols
func renderCard(_ card: Card?) -> Text {
    guard let card = card else {
        // Placeholder for hidden card
        return Text("""
        ╔════╗
        ║    ║
        ║ ?? ║
        ║    ║
        ╚════╝
        """).foregroundColor(.white)
    }
    
    let rank = card.rank == 1 ? "A" : (card.rank > 10 ? String(card.description.prefix(1)) : "\(card.rank)")
    let suitSymbol: String
    let suitColor: Color
    switch card.suit {
    case .hearts:
        suitSymbol = "♥"
        suitColor = .red
    case .diamonds:
        suitSymbol = "♦"
        suitColor = .red
    case .clubs:
        suitSymbol = "♣"
        suitColor = .black
    case .spades:
        suitSymbol = "♠"
        suitColor = .black
    }
    
    return Text("""
    ╔════╗
    ║\(rank)   ║
    ║  \(suitSymbol) ║
    ║   \(rank)║
    ╚════╝
    """).foregroundColor(suitColor)
}

func convertRankNameToValue(_ name: String) -> Int {
    switch name {
    case "Ace": return 1
    case "Jack": return 11
    case "Queen": return 12
    case "King": return 13
    default: return Int(name) ?? 0
    }
}

// Helper function to render multiple cards horizontally
func renderHandHorizontally(_ hand: [Card], hideFirstCard: Bool = false) -> String {
    let renderedCards = hand.enumerated().map { index, card in
        if index == 0 && hideFirstCard {
            // Hidden card representation
            return """
            ╔════╗
            ║    ║
            ║ ?? ║
            ║    ║
            ╚════╝
            """
        } else {
            let rank = card.rank == 1 ? "A" : (card.rank > 10 ? String(card.description.prefix(1)) : "\(card.rank)")
            let suitSymbol: String
            switch card.suit {
            case .hearts: suitSymbol = "♥"
            case .diamonds: suitSymbol = "♦"
            case .clubs: suitSymbol = "♣"
            case .spades: suitSymbol = "♠"
            }
            return """
            ╔════╗
            ║\(rank)   ║
            ║  \(suitSymbol) ║
            ║   \(rank)║
            ╚════╝
            """
        }
    }

    // Split each card's string into rows and combine them horizontally
    let rows = renderedCards.map { $0.split(separator: "\n") }
    guard let firstCardRows = rows.first else { return "" }

    return (0..<firstCardRows.count).map { rowIndex in
        rows.map { $0[rowIndex] }.joined(separator: " ")
    }.joined(separator: "\n")
}

func generateGoldStack(for balance: Int) -> String {
    let goldPerRow = 10 // Each row represents $10
    let rows = balance / goldPerRow
    var stack = ""

    for _ in 0..<rows {
        stack += "  █░█░\n"
    }

    return stack.isEmpty ? "No gold left!" : stack
}

struct GoldStackView: View {
    let balance: Int

    var body: some View {
        VStack {
            Text("Player's Gold Stack")
                .font(.headline)
                .foregroundColor(.yellow)

            Text(generateGoldStack(for: balance))
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(.yellow)
                .multilineTextAlignment(.center)
                .padding()

            Text("💰 Balance: $\(balance)")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.green)
        }
        .padding()
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}

// Refined ASCII-styled button with larger size and title-like appearance
struct AsciiButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("""
            ╔═════╗
            ║\(label)  ║
            ╚═════╝
            """)
            .font(.system(size: 14, weight: .bold, design: .monospaced)) // Larger font
            .foregroundColor(.white)
        }
        .buttonStyle(PlainButtonStyle()) // Ensure plain styling
    }
}


struct ContentView: View {
    @State private var game = BlackjackGame(decks: 1)
    @State private var showMonteCarloResults = false
    @State private var monteCarloResults: (bestCard: String, probabilities: [(String, Double)])?
    @State private var showBasicStrategyTable = false

    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text("""
            ╔══════════════════════════════════╗
            ║          BLACKJACK TRAINER       ║
            ╚══════════════════════════════════╝
            """)
            .font(.system(size: 16, weight: .bold, design: .monospaced))
            .foregroundColor(.white)

            // Game State
            Text("🎲 \(game.state.rawValue.uppercased()) 🎲")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.yellow)

            Divider().background(Color.gray)

            // Dealer and Player Hands
            HStack(alignment: .top, spacing: 20) {
                // Dealer Section
                VStack(alignment: .center, spacing: 10) {
                    Text("DEALER")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.red)
                    Text(renderHandHorizontally(game.dealerHand, hideFirstCard: game.state != .gameOver))
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Text("Total: \(game.state == .gameOver ? "\(game.calculateHandTotal(hand: game.dealerHand))" : "Hidden")")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.blue)
                }

                Divider().frame(height: 100).background(Color.gray)

                // Player Section
                VStack(alignment: .center, spacing: 10) {
                    Text("PLAYER")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.green)
                    ForEach(0..<max(1, game.playerSplitHands.count), id: \.self) { index in
                        let hand = game.playerSplitHands.isEmpty ? game.playerHand : game.playerSplitHands[index]
                        Text(renderHandHorizontally(hand))
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(index == game.currentHandIndex ? .green : .white)
                        Text("Total: \(game.calculateHandTotal(hand: hand))")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(index == game.currentHandIndex ? .green : .white)
                    }
                }
            }

            Divider().background(Color.gray)
            
            // Strategy Tip Section
                    if game.state == .playerTurn {
                        let hint = game.strategyHint(
                            for: game.playerHand,
                            dealerUpCard: game.dealerHand.first
                        )
                        Text("📊 Strategy Tip: \(hint)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.yellow)
                            .padding()
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(8)
                    }

            // Action Buttons
            VStack(spacing: 10) {
                if game.state == .waitingForBet {
                    Text("💵 Place Your Bet 💵")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.yellow)
                    HStack(spacing: 10) {
                        ForEach([5, 10, 20, 50], id: \.self) { amount in
                            AsciiButton(label: "$\(amount)") {
                                if game.placeBet(amount: amount) {
                                    game.dealInitialCards()
                                    monteCarloResults = monteCarloSimulation(
                                        deck: game.deck,
                                        game: game,
                                        playerHand: game.playerHand,
                                        dealerHand: game.dealerHand
                                    )
                                    game.state = .playerTurn
                                }
                            }
                        }
                    }
                } else if game.state == .playerTurn {
                    HStack(spacing: 10) {
                        AsciiButton(label: "HIT") {
                            if let _ = game.playerHit(), game.calculateHandTotal(hand: game.playerHand) > 21 {
                                monteCarloResults = monteCarloSimulation(
                                    deck: game.deck,
                                    game: game,
                                    playerHand: game.playerHand,
                                    dealerHand: game.dealerHand
                                )
                                game.state = .gameOver
                                game.resolveBet(won: false)
                            }
                        }
                        AsciiButton(label: "STAND") {
                            game.dealerTurn()
                        }
                    }
                } else if game.state == .gameOver {
                    AsciiButton(label: "Play Again") {
                        game.resetGame()
                        game.state = .waitingForBet
                    }
                }
            }

            Divider().background(Color.gray)

            // Gold Stack and Stats
            VStack(spacing: 10) {
                GoldStackView(balance: game.playerBalance)
                VStack(alignment: .leading, spacing: 5) {
                    Text("Game Stats")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.yellow)
                    Text("Running Count: \(game.runningCount)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.green)
                    Text("True Count: \(String(format: "%.2f", game.trueCount()))")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.green)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}

struct BasicStrategyTableView: View {
    var body: some View {
        ScrollView {
            Text(BlackjackGame.basicStrategyTable())
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .padding()
                .background(Color.black.edgesIgnoringSafeArea(.all))
        }
    }
}



struct TestChipStackView: View {
    var body: some View {
        VStack {
            // Horizontal chips
            Text("══ ══ ══ ══")
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundColor(.red)

            // Vertical striped chips
            Text("""
            █░█░
            █░█░
            █░█░
            """)
            .font(.system(size: 16, weight: .bold, design: .monospaced))
            .foregroundColor(.blue)

            // Example caption
            Text("Example Chip Stack")
                .foregroundColor(.white)
                .font(.caption)
        }
        .padding()
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}


// MARK: - Deck Viewer
struct DeckViewer: View {
    let cardComposition: [Int: Int]

    var body: some View {
        VStack {
            Text("📋 Remaining Deck Composition 📋")
                .font(.headline)
                .padding()

            List {
                ForEach(1...13, id: \.self) { rank in
                    let rankString: String = {
                        switch rank {
                        case 1: return "Ace"
                        case 11: return "Jack"
                        case 12: return "Queen"
                        case 13: return "King"
                        default: return "\(rank)"
                        }
                    }()

                    Text("\(rankString): \(cardComposition[rank, default: 0]) cards remaining")
                }
            }
        }
    }
}
