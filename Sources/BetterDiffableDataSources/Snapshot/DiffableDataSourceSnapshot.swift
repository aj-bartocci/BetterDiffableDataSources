//
//  PolyfilledSnapshot.swift
//  DiffableCollection
//
//  Created by AJ Bartocci on 5/4/22.
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

@available(iOS, deprecated: 13.0, renamed: "NSDiffableDataSourceSnapshot")
public struct DiffableDataSourceSnapshot<SectionIdentifierType: Hashable, ItemIdentifierType: Hashable>: SnapshotRepresentable {
    
    private (set) var reloadedItemIdentifiers: [ItemIdentifierType] = []
    private (set) var reconfiguredItemIdentifiers: [ItemIdentifierType] = []
    private (set) var reloadedSectionIdentifiers: [SectionIdentifierType] = []
    
    private let snapshotWrapper = SnapshotWrapper<SectionIdentifierType, ItemIdentifierType>()
    private var polyfillSnapshot = NSDiffableDataSourceSnapshotPolyfill<SectionIdentifierType, ItemIdentifierType>()
    
    public init() { }
    
    public var sectionIdentifiers: [SectionIdentifierType] {
        if #available(iOS 13, *) {
            return snapshotWrapper.appleSnapshot.sectionIdentifiers
        } else {
            return polyfillSnapshot.sectionIdentifiers
        }
    }
    
    public var itemIdentifiers: [ItemIdentifierType] {
        if #available(iOS 13, *) {
            return snapshotWrapper.appleSnapshot.itemIdentifiers
        } else {
            return polyfillSnapshot.itemIdentifiers
        }
    }

    mutating
    public func appendSections(_ identifiers: [SectionIdentifierType]) {
        if #available(iOS 13, *) {
            snapshotWrapper.appleSnapshot.appendSections(identifiers)
        } else {
            polyfillSnapshot.appendSections(identifiers)
        }
    }

    mutating
    public func appendItems(_ identifiers: [ItemIdentifierType], toSection sectionIdentifier: SectionIdentifierType?) {
        if #available(iOS 13, *) {
            snapshotWrapper.appleSnapshot.appendItems(identifiers, toSection: sectionIdentifier)
        } else {
            polyfillSnapshot.appendItems(identifiers, toSection: sectionIdentifier)
        }
    }
    
    public func itemIdentifiers(inSection identifier: SectionIdentifierType) -> [ItemIdentifierType] {
        if #available(iOS 13, *) {
            return snapshotWrapper.appleSnapshot.itemIdentifiers(inSection: identifier)
        } else {
            return polyfillSnapshot.itemIdentifiers(inSection: identifier)
        }
    }
    
    public func indexOfSection(_ identifier: SectionIdentifierType) -> Int? {
        if #available(iOS 13, *) {
            return snapshotWrapper.appleSnapshot.indexOfSection(identifier)
        } else {
            return polyfillSnapshot.indexOfSection(identifier)
        }
    }
    
    public func indexOfItem(_ identifier: ItemIdentifierType) -> Int? {
        if #available(iOS 13, *) {
            return snapshotWrapper.appleSnapshot.indexOfItem(identifier)
        } else {
            return polyfillSnapshot.indexOfItem(identifier)
        }
    }
    
    public func sectionIdentifier(containingItem identifier: ItemIdentifierType) -> SectionIdentifierType? {
        if #available(iOS 13, *) {
            return snapshotWrapper.appleSnapshot.sectionIdentifier(containingItem: identifier)
        } else {
            return polyfillSnapshot.sectionIdentifier(containingItem: identifier)
        }
    }

    mutating
    public func reconfigureItems(_ identifiers: [ItemIdentifierType]) {
        reconfiguredItemIdentifiers = identifiers
        if #available(iOS 15, *) {
            snapshotWrapper.appleSnapshot.reconfigureItems(identifiers)
        } else {
            polyfillSnapshot.reconfigureItems(identifiers)
        }
    }

    mutating
    public func reloadItems(_ identifiers: [ItemIdentifierType]) {
        reloadedItemIdentifiers = identifiers
        if #available(iOS 13, *) {
            snapshotWrapper.appleSnapshot.reloadItems(identifiers)
        } else {
            polyfillSnapshot.reloadItems(identifiers)
        }
    }
    
    mutating
    public func reloadSections(_ identifiers: [SectionIdentifierType]) {
        reloadedSectionIdentifiers = identifiers
        if #available(iOS 13, *) {
            snapshotWrapper.appleSnapshot.reloadSections(identifiers)
        } else {
            polyfillSnapshot.reloadSections(identifiers)
        }
    }

    mutating
    public func insertItems(_ identifiers: [ItemIdentifierType], afterItem afterIdentifier: ItemIdentifierType) {
        if #available(iOS 13, *) {
            snapshotWrapper.appleSnapshot.insertItems(identifiers, afterItem: afterIdentifier)
        } else {
            polyfillSnapshot.insertItems(identifiers, afterItem: afterIdentifier)
        }
    }

    @available(iOS 13, *)
    func iOS13Snapshot() -> NSDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType> {
        return snapshotWrapper.appleSnapshot
    }
}
