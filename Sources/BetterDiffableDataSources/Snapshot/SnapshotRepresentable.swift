//
//  SnapshotRepresentable.swift
//  DiffableCollection
//
//  Created by AJ Bartocci on 5/4/22.
//

import Foundation

public protocol DiffSnapshottable {
    associatedtype SectionIdentifierType
    associatedtype ItemIdentifierType
    
    init()
    
    var sectionIdentifiers: [SectionIdentifierType] { get }
    var itemIdentifiers: [ItemIdentifierType] { get }

    mutating func appendSections(_ identifiers: [SectionIdentifierType])
    mutating func appendItems(_ identifiers: [ItemIdentifierType], toSection sectionIdentifier: SectionIdentifierType?)
    @available(iOS 15, *)
    mutating func reconfigureItems(_ identifiers: [ItemIdentifierType])
    mutating func reloadItems(_ identifiers: [ItemIdentifierType])
    mutating func reloadSections(_ identifiers: [SectionIdentifierType])
    
    func itemIdentifiers(inSection identifier: SectionIdentifierType) -> [ItemIdentifierType]
    
    func indexOfSection(_ identifier: SectionIdentifierType) -> Int?
    func indexOfItem(_ identifier: ItemIdentifierType) -> Int?
    func sectionIdentifier(containingItem identifier: ItemIdentifierType) -> SectionIdentifierType?
    
    // TODO: implement other functions as needed
}

public protocol SnapshotRepresentable: DiffSnapshottable where SectionIdentifierType: Hashable, ItemIdentifierType: Hashable { }

public protocol BetterSnapshotRepresentable: DiffSnapshottable where SectionIdentifierType: Hashable, ItemIdentifierType: DiffableItem { }
