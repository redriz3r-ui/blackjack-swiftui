import Foundation

enum Suit: String, CaseIterable {
    case hearts, diamonds, clubs, spades
}

struct Card: Equatable {
    let rank: Int
    let suit: Suit

    var value: Int {
        rank > 10 ? 10 : rank
    }

    var description: String {
        switch rank {
        case 1: return "Ace of \(suit.rawValue.capitalized)"
        case 11: return "Jack of \(suit.rawValue.capitalized)"
        case 12: return "Queen of \(suit.rawValue.capitalized)"
        case 13: return "King of \(suit.rawValue.capitalized)"
        default: return "\(rank) of \(suit.rawValue.capitalized)"
        }
    }

    var hiLoValue: Int {
        switch rank {
        case 2...6: return 1
        case 10...13, 1: return -1
        default: return 0
        }
    }
    
}


//
//  Card.swift
//  HandTracker
//
//  Created by Robe on 12/19/24.
//

