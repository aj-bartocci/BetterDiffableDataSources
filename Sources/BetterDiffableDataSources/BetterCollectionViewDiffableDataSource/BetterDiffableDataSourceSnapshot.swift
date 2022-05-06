//
//  BetterDiffableDataSourceSnapshot.swift
//  DiffableCollection
//
//  Created by AJ Bartocci on 5/5/22.
//

import UIKit

private class SnapshotWrapper<SectionIdentifierType: Hashable, ItemIdentifierType: Hashable> {
    
    private var _appleSnapshot: Any? = nil
    @available(iOS 13.0, *)
    fileprivate var appleSnapshot: NSDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType> {
        get {
            if _appleSnapshot == nil {
                _appleSnapshot = NSDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>()
            }
            return _appleSnapshot as! NSDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>
        }
        set {
            _appleSnapshot = newValue
        }
    }
}

public struct BetterDiffableDataSourceSnapshot<
    SectionIdentifierType: Hashable,
    ItemIdentifierType: DiffableItem
>: BetterSnapshotRepresentable {
    private(set) var snapshot: DiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType.DiffIdentifier>
    var itemLookup = [ItemIdentifierType.DiffIdentifier: ItemIdentifierType]()
    
    public var sectionIdentifiers: [SectionIdentifierType] {
        return snapshot.sectionIdentifiers
    }
    
    public var itemIdentifiers: [ItemIdentifierType] {
        // TODO: cache this
        let identifiers = snapshot.itemIdentifiers.compactMap({ return itemLookup[$0] })
        assert(identifiers.count == snapshot.itemIdentifiers.count, "There is a mismatch between the raw identifiers and diff identifiers")
        return identifiers
    }

    public init() {
        snapshot = DiffableDataSourceSnapshot()
    }

    mutating
    public func appendSections(_ identifiers: [SectionIdentifierType]) {
        snapshot.appendSections(identifiers)
    }
    
    mutating
    public func appendItems(_ identifiers: [ItemIdentifierType], toSection sectionIdentifier: SectionIdentifierType?) {
        var ids = [ItemIdentifierType.DiffIdentifier]()
        for identifier in identifiers {
            ids.append(identifier.diffId)
            itemLookup[identifier.diffId] = identifier
        }
        snapshot.appendItems(ids, toSection: sectionIdentifier)
    }
    
    mutating
    public func reconfigureItems(_ identifiers: [ItemIdentifierType]) {
        snapshot.reconfigureItems(identifiers.map(\.diffId))
    }
    
    mutating
    public func reloadItems(_ identifiers: [ItemIdentifierType]) {
        snapshot.reloadItems(identifiers.map(\.diffId))
    }
    
    mutating
    public func reloadSections(_ identifiers: [SectionIdentifierType]) {
        snapshot.reloadSections(identifiers)
    }
    
    public func itemIdentifiers(inSection identifier: SectionIdentifierType) -> [ItemIdentifierType] {
        let rawIdentifiers = snapshot.itemIdentifiers(inSection: identifier)
        let identifiers = rawIdentifiers.compactMap({ return itemLookup[$0] })
        assert(rawIdentifiers.count == identifiers.count, "There is a mismatch between the raw identifiers and diff identifiers")
        return identifiers
    }
    
    public func indexOfSection(_ identifier: SectionIdentifierType) -> Int? {
        return snapshot.indexOfSection(identifier)
    }
    
    public func indexOfItem(_ identifier: ItemIdentifierType) -> Int? {
        return snapshot.indexOfItem(identifier.diffId)
    }
    
    public func sectionIdentifier(containingItem identifier: ItemIdentifierType) -> SectionIdentifierType? {
        return snapshot.sectionIdentifier(containingItem: identifier.diffId)
    }

    mutating
    public func insertItems(_ identifiers: [ItemIdentifierType], afterItem target: ItemIdentifierType) {
        var ids = [ItemIdentifierType.DiffIdentifier]()
        for identifier in identifiers {
            ids.append(identifier.diffId)
            itemLookup[identifier.diffId] = identifier
        }
        snapshot.insertItems(ids, afterItem: target.diffId)
    }
}
