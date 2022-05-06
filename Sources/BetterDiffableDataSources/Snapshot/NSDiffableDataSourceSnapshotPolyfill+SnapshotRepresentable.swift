//
//  NSDiffableDataSourceSnapshotPolyfill+SnapshotRepresentable.swift
//  DiffableCollection
//
//  Created by AJ Bartocci on 5/4/22.
//

import Foundation

//private class SnapshotCache<SectionIdentifierType: Hashable, ItemIdentifierType: Hashable> {
//    var cachedItemIdentifiers: [ItemIdentifierType]?
//    var itemIndex: [ItemIdentifierType: Int]?
//
//    func invalidate() {
//        cachedItemIdentifiers = nil
//    }
//}

struct NSDiffableDataSourceSnapshotPolyfill<SectionIdentifierType: Hashable, ItemIdentifierType: Hashable>: SnapshotRepresentable {
    
    private var sections = [SectionIdentifierType]()
    private var sectionItemIndex = [SectionIdentifierType: [ItemIdentifierType]]()
    private var itemSectionIndex = [ItemIdentifierType: SectionIdentifierType]()
    
    private var currentSection: SectionIdentifierType?
    
    var reloadedItemIdentifiers: [ItemIdentifierType] = []
    var reconfiguredItemIdentifiers: [ItemIdentifierType] = []
    var reloadedSectionIdentifiers: [SectionIdentifierType] = []
    
//    private let cache = SnapshotCache<SectionIdentifierType, ItemIdentifierType>()
    
    var itemIdentifiers: [ItemIdentifierType] {
        // TODO: optimize calculation with caching
        var items = [ItemIdentifierType]()
        for section in sections {
            items.append(contentsOf: itemIdentifiers(inSection: section))
        }
        return items
    }
    
    var sectionIdentifiers: [SectionIdentifierType] {
        return sections
    }
    
    mutating
    func appendSections(_ identifiers: [SectionIdentifierType]) {
        sections.append(contentsOf: identifiers)
        currentSection = identifiers.last
    }
    
    mutating
    func appendItems(_ identifiers: [ItemIdentifierType], toSection sectionIdentifier: SectionIdentifierType?) {
        let section: SectionIdentifierType
        if let sectionIdentifier = sectionIdentifier {
            section = sectionIdentifier
        } else {
            guard let currentSection = currentSection else {
                // copying Apple's logic with fatal error here
                fatalError("There are currently no sections in the data source. Please add a section first.")
            }
            section = currentSection
        }
        addItems(identifiers, toSection: section)
    }
    
    mutating
    private func addItems(_ identifiers: [ItemIdentifierType], toSection section: SectionIdentifierType) {
        var items = sectionItemIndex[section] ?? []
        for identifier in identifiers {
            itemSectionIndex[identifier] = section
            items.append(identifier)
        }
        sectionItemIndex[section] = items
    }
    
    mutating
    private func insertItems(
        _ identifiers: [ItemIdentifierType],
        toSection section: SectionIdentifierType,
        atIndex startIndex: Int,
        insertBefore: Bool
    ) {
        let items = sectionItemIndex[section] ?? []
        if startIndex == 0 {
            // insert at beginning
            sectionItemIndex[section] = []
            for identifier in identifiers {
                itemSectionIndex[identifier] = section
                sectionItemIndex[section]?.append(identifier)
            }
            sectionItemIndex[section]?.append(contentsOf: items)
        } else if startIndex < items.count - 1 {
            // insert midway
            var newItems = [ItemIdentifierType]()
            for (index, existingItem) in items.enumerated() {
                if index < startIndex {
                    newItems.append(existingItem)
                } else {
                    if index == startIndex {
                        if !insertBefore {
                            newItems.append(existingItem)
                        }
                        for identifier in identifiers {
                            itemSectionIndex[identifier] = section
                            newItems.append(identifier)
                        }
                        if insertBefore {
                            newItems.append(existingItem)
                        }
                    } else {
                        newItems.append(existingItem)
                    }
                }
            }
            sectionItemIndex[section] = newItems
        } else {
            // append to end
            sectionItemIndex[section] = items
            for identifier in identifiers {
                itemSectionIndex[identifier] = section
                sectionItemIndex[section]?.append(identifier)
            }
        }
    }
    
    func itemIdentifiers(inSection identifier: SectionIdentifierType) -> [ItemIdentifierType] {
        return sectionItemIndex[identifier] ?? []
    }
    
    mutating
    func insertItems(_ identifiers: [ItemIdentifierType], afterItem afterIdentifier: ItemIdentifierType) {
        // If the after item doesn't exist in Apple's implementation there is a fatal error with
        // message: "Invalid parameter not satisfying: section != NSNotFound"
        // So this will fatal as well but with a better message
        guard let section = itemSectionIndex[afterIdentifier],
              let index = indexOfItem(afterIdentifier) else {
            fatalError("afterItem not found in snapshot. Underlying Apple errror: 'Invalid parameter not satisfying: section != NSNotFound' or 'Invalid update: destination for insertion operation [\(afterIdentifier)] is in the insertion identifier list for update'")
        }
        insertItems(identifiers, toSection: section, atIndex: index, insertBefore: false)
    }
    
    mutating
    func insertItems(_ identifiers: [ItemIdentifierType], beforeItem afterIdentifier: ItemIdentifierType) {
        // If the after item doesn't exist in Apple's implementation there is a fatal error with
        // message: "Invalid parameter not satisfying: section != NSNotFound"
        // So this will fatal as well but with a better message
        guard let section = itemSectionIndex[afterIdentifier],
              let index = indexOfItem(afterIdentifier) else {
            fatalError("afterItem not found in snapshot. Underlying Apple errror: 'Invalid parameter not satisfying: section != NSNotFound' or 'Invalid update: destination for insertion operation [\(afterIdentifier)] is in the insertion identifier list for update'")
        }
        insertItems(identifiers, toSection: section, atIndex: index, insertBefore: true)
    }
    
    func indexOfSection(_ identifier: SectionIdentifierType) -> Int? {
        // TODO: optimize with caching
        return sections.firstIndex(of: identifier)
    }
    
    func indexOfItem(_ identifier: ItemIdentifierType) -> Int? {
        // TODO: optimize with caching
        guard let section = itemSectionIndex[identifier],
              let index = itemIdentifiers(inSection: section).firstIndex(of: identifier) else {
            return nil
        }
        return index
    }
    
    func sectionIdentifier(containingItem identifier: ItemIdentifierType) -> SectionIdentifierType? {
        return itemSectionIndex[identifier]
    }
    
    mutating
    func reconfigureItems(_ identifiers: [ItemIdentifierType]) {
        reconfiguredItemIdentifiers = identifiers
    }
    
    mutating
    func reloadItems(_ identifiers: [ItemIdentifierType]) {
        reloadedItemIdentifiers = identifiers
    }
    
    mutating
    func reloadSections(_ identifiers: [SectionIdentifierType]) {
        reloadedSectionIdentifiers = identifiers
    }
}
