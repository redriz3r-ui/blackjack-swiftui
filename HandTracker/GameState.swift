//
//  GameState.swift
//  HandTracker
//
//  Created by Robe on 12/20/24.
//


import Foundation

enum GameState: String {
    case waitingForBet = "Waiting for Bet"
    case playerTurn = "Player's Turn"
    case dealerTurn = "Dealer's Turn"
    case splitTurn = "Split Hand Turn"
    case gameOver = "Game Over"
}

class BlackjackGame: ObservableObject {
    @Published var dealerHand: [Card] = []
    @Published var playerHands: [[Card]] = [] // Stores multiple hands for splitting
    @Published var currentHandIndex: Int = 0 // Tracks which hand the player is currently playing
    @Published var playerBalance: Int = 100
    @Published var state: GameState = .waitingForBet

    private(set) var deck: Deck
    private(set) var currentBet: Int = 0

    init(decks: Int = 1) {
        self.deck = Deck(decks: decks)
    }
    
    var playerHand: [Card] {
        get {
            guard playerHands.indices.contains(currentHandIndex) else {
                print("Error: currentHandIndex (\(currentHandIndex)) out of bounds for playerHands (\(playerHands.count))")
                return [] // Return an empty array as a fallback
            }
            return playerHands[currentHandIndex]
        }
        set {
            guard playerHands.indices.contains(currentHandIndex) else {
                print("Error: Attempt to set playerHand at invalid index \(currentHandIndex)")
                return
            }
            playerHands[currentHandIndex] = newValue
        }
    }
    
    func dealerTurn() {
        guard state == .dealerTurn else { return }
        
        let dealerTotal = calculateHandTotal(hand: dealerHand)
        let hasSoft17 = dealerTotal == 17 && dealerHand.contains { $0.rank == 1 } // Soft 17 check

        if dealerTotal >= 17 && !hasSoft17 {
            // Dealer stands, resolve the game
            state = .gameOver
            resolveGame()
        } else {
            // Dealer hits
            if let newCard = deck.dealCard() {
                dealerHand.append(newCard)
            }
            
            // Check for bust
            if calculateHandTotal(hand: dealerHand) > 21 {
                state = .gameOver
                resolveGame()
            } else {
                // Continue dealer turn
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.dealerTurn()
                }
            }
        }
    }
    
    
    func strategyHint(for hand: [Card], dealerUpCard: Card?) -> String {
        guard let dealerUpCard = dealerUpCard else { return "No hint available" }
        let playerTotal = calculateHandTotal(hand: hand)
        let dealerValue = dealerUpCard.value

        // Check for pairs
        if hand.count == 2 && hand[0].rank == hand[1].rank {
            if hand[0].rank == 1 || hand[0].rank == 8 {
                return "Split"
            } else if hand[0].rank == 5 {
                return dealerValue >= 2 && dealerValue <= 9 ? "Double Down" : "Hit"
            }
        }

        // Check for soft hands (contains an Ace counted as 11)
        if hand.contains(where: { $0.rank == 1 }) {
            if playerTotal == 18 {
                return dealerValue >= 9 ? "Hit" : "Stand"
            } else if playerTotal >= 19 {
                return "Stand"
            } else {
                return "Hit"
            }
        }

        // Hard totals
        if playerTotal >= 17 {
            return "Stand"
        } else if playerTotal >= 13 && dealerValue <= 6 {
            return "Stand"
        } else if playerTotal == 12 && (dealerValue >= 4 && dealerValue <= 6) {
            return "Stand"
        } else {
            return "Hit"
        }
    }

    func placeBet(amount: Int) -> Bool {
        guard amount <= playerBalance else { return false }
        currentBet = amount
        playerBalance -= amount
        state = .playerTurn
        return true
    }
    
    func playerStand() {
        guard state == .playerTurn else { return }
        state = .dealerTurn
        dealerTurn()
    }
    
    func doubleDown() {
        guard state == .playerTurn else { return } // Ensure it's the player's turn
        guard playerBalance >= currentBet else { return } // Ensure enough balance

        playerBalance -= currentBet // Deduct the additional bet
        currentBet *= 2 // Double the bet
        let _ = playerHit() // Player hits one card

        // End player's turn after doubling down
        if state == .playerTurn {
            playerStand()
        }
    }
    
    func split() {
        guard playerHand.count == 2 else { return }
        guard playerHand[0].rank == playerHand[1].rank else { return }
        guard playerBalance >= currentBet else { return }

        playerBalance -= currentBet
        let secondCard = playerHand.removeLast()

        // Create two hands
        playerHands[currentHandIndex] = [playerHand[0], deck.dealCard()!]
        playerHands.append([secondCard, deck.dealCard()!])

        state = .splitTurn
    }

    func dealInitialCards() {
        playerHands = [[deck.dealCard(), deck.dealCard()].compactMap { $0 }]
        dealerHand = [deck.dealCard(), deck.dealCard()].compactMap { $0 }
        currentHandIndex = 0 // Ensures the current hand is valid
    }
    
    func playerHit() {
          guard state == .playerTurn else { return }

          if let newCard = deck.dealCard() {
              playerHand.append(newCard)

              // Check for bust
              if calculateHandTotal(hand: playerHand) > 21 {
                  state = .gameOver
                  resolveGame()
              }
          }
      }
    
    

    func resolveGame() {
        let dealerTotal = calculateHandTotal(hand: dealerHand)

        if state == .splitTurn {
            // Resolve each split hand individually
            for hand in playerHands {
                let playerTotal = calculateHandTotal(hand: hand)
                if playerTotal > 21 || (dealerTotal <= 21 && dealerTotal >= playerTotal) {
                    // Player loses this hand
                    continue
                } else {
                    // Player wins this hand
                    playerBalance += currentBet * 2
                }
            }
        } else {
            // Single hand resolution
            let playerTotal = calculateHandTotal(hand: playerHand)
            if playerTotal > 21 || (dealerTotal <= 21 && dealerTotal >= playerTotal) {
                currentBet = 0 // Player loses
            } else {
                playerBalance += currentBet * 2 // Player wins
            }
        }

        state = .gameOver
    }

    func resetGame() {
        playerHand = []
        dealerHand = []
        state = .waitingForBet
        currentBet = 0
    }

     func calculateHandTotal(hand: [Card]) -> Int {
        let total = hand.reduce(0) { $0 + $1.value }
        if hand.contains(where: { $0.rank == 1 }) && total + 10 <= 21 {
            return total + 10
        }
        return total
    }
}
