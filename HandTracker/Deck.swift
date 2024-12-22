//
//  Deck.swift
//  HandTracker
//
//  Created by Robe on 12/20/24.
//


import Foundation

class Deck {
    private(set) var cards: [Card] = []

    init(decks: Int = 1) {
        for _ in 0..<decks {
            for suit in Suit.allCases {
                for rank in 1...13 {
                    cards.append(Card(rank: rank, suit: suit))
                }
            }
        }
        shuffle()
    }

    func shuffle() {
        cards.shuffle()
    }

    func dealCard() -> Card? {
        guard !cards.isEmpty else { return nil }
        return cards.removeLast()
    }

    var remainingDecks: Double {
        Double(cards.count) / 52.0
    }
}