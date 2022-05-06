//
//  DiffableItem.swift
//  DiffableCollection
//
//  Created by AJ Bartocci on 5/5/22.
//

import Foundation

public protocol DiffableItem {
    associatedtype DiffIdentifier: Hashable
    // Identifier to decide whether the object is in the collection or not
    var diffId: DiffIdentifier { get }
    // Used to determine if the object needs to updat or not
    func itemIsEqual(to item: Self) -> Bool
    func prefersReconfigureOverReload() -> Bool
}
