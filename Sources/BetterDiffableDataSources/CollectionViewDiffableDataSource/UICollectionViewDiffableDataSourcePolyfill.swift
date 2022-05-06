//
//  UICollectionViewDiffableDataSourcePolyfill.swift
//  DiffableCollection
//
//  Created by AJ Bartocci on 5/4/22.
//

import Foundation
import UIKit

class UICollectionViewDiffableDataSourcePolyfill<SectionIdentifierType: Hashable, ItemIdentifierType: Hashable>: NSObject, UICollectionViewDataSource, CollectionViewDiffableDataSourceRepresentable {
    
    typealias CellProvider = (_ collectionView: UICollectionView, _ indexPath: IndexPath, _ itemIdentifier: ItemIdentifierType) -> UICollectionViewCell?
    private weak var collectionView: UICollectionView!
    private let cellProvider: CellProvider
//    maybe the snapshot type can be injected?
//    this class would be a base class and then have 2 user facing classes
//    one would be the true backwards compat
//    the other would be the 'better' version of diffable datasource
    private var cachedSnapshot = DiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>()
    private var isFirstLoad = true
        
    init(
        collectionView: UICollectionView,
        cellProvider: @escaping CellProvider
    ) {
        self.collectionView = collectionView
        self.cellProvider = cellProvider
        super.init()
        collectionView.dataSource = self
    }
    
    func indexPath(for itemIdentifier: ItemIdentifierType) -> IndexPath? {
        guard let section = cachedSnapshot.sectionIdentifier(containingItem: itemIdentifier) else {
            return nil
        }
        guard let sectionIndex = cachedSnapshot.indexOfSection(section) else {
            return nil
        }
        guard let rowIndex = cachedSnapshot.indexOfItem(itemIdentifier) else {
            return nil
        }
        return IndexPath(row: rowIndex, section: sectionIndex)
    }
    
    func itemIdentifier(for indexPath: IndexPath) -> ItemIdentifierType? {
        guard indexPath.section < cachedSnapshot.sectionIdentifiers.count else {
            return nil
        }
        let section = cachedSnapshot.sectionIdentifiers[indexPath.section]
        let itemIds = cachedSnapshot.itemIdentifiers(inSection: section)
        guard indexPath.row < itemIds.count else {
            return nil
        }
        return itemIds[indexPath.row]
    }
    
    func apply(
        _ snapshot: DiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>,
        animatingDifferences: Bool,
        completion: (() -> Void)?
    ) {
        
        if isFirstLoad {
            self.isFirstLoad = false
            self.cachedSnapshot = snapshot
            collectionView.reloadData()
            completion?()
            return
        }
        
        let oldSections = cachedSnapshot.sectionIdentifiers
        let newSections = snapshot.sectionIdentifiers
        
        if
            snapshot.reloadedItemIdentifiers.isEmpty &&
            snapshot.reloadedSectionIdentifiers.isEmpty &&
            snapshot.reconfiguredItemIdentifiers.isEmpty &&
            oldSections == newSections &&
            cachedSnapshot.itemIdentifiers == snapshot.itemIdentifiers {
            // no change
            completion?()
            return
        }
        
        let itemsToReloadIndex: [ItemIdentifierType: ItemIdentifierType] = snapshot.reloadedItemIdentifiers.toDictionary(keySelector: { $0 })
        let sectionsToReloadIndex: [SectionIdentifierType: SectionIdentifierType] = snapshot.reloadedSectionIdentifiers.toDictionary(keySelector: { $0 })
        let itemsToReconfigureIndex: [ItemIdentifierType: ItemIdentifierType] = snapshot.reconfiguredItemIdentifiers.toDictionary(keySelector: { $0 })

        var insertions = [IndexPath]()
        var deletions = [IndexPath]()
        var updates = [IndexPath]()
        for (sectionIndex, section) in snapshot.sectionIdentifiers.enumerated() {
            let newItems = snapshot.itemIdentifiers(inSection: section)
            for item in newItems {
                if itemsToReloadIndex[item] != nil || itemsToReconfigureIndex[item] != nil {
                    if let indexPath = self.indexPath(for: item) {
                        updates.append(indexPath)
                    }
                }
            }
            let oldItems = cachedSnapshot.itemIdentifiers(inSection: section)
            let diff = Dwifft.diff(oldItems, newItems)
//            oldItems.diff(newItems)
            diff.forEach { change in
                switch change {
                case .insert(let rowIndex, _):
                    let indexPath = IndexPath(row: rowIndex, section: sectionIndex)
                    insertions.append(indexPath)
                case .delete(let rowIndex, _):
                    let indexPath = IndexPath(row: rowIndex, section: sectionIndex)
                    deletions.append(indexPath)
                }
            }
        }

        var insertedSections = [Int]()
        var deletedSections = [Int]()
        var updatedSections = [Int]()

        let sectionDiff = Dwifft.diff(oldSections, newSections)
        sectionDiff.forEach { change in
            switch change {
            case .delete(let index, _):
                deletedSections.append(index)
            case .insert(let index, _):
                insertedSections.append(index)
            }
        }
        for section in newSections {
            if sectionsToReloadIndex[section] != nil, let index = snapshot.indexOfSection(section) {
                updatedSections.append(index)
            }
        }

        if animatingDifferences && isFirstLoad == false {
            collectionView.performBatchUpdates {
                self.cachedSnapshot = snapshot
                collectionView.reloadItems(at: updates)
                collectionView.reloadSections(IndexSet(updatedSections))
                collectionView.deleteItems(at: deletions)
                collectionView.deleteSections(IndexSet(deletedSections))
                collectionView.insertItems(at: insertions)
                collectionView.insertSections(IndexSet(insertedSections))
            } completion: { _ in
                completion?()
            }
        } else {
            self.cachedSnapshot = snapshot
            collectionView.reloadData()
            completion?()
        }
    }
    
    // MARK: UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return cachedSnapshot.sectionIdentifiers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let section = cachedSnapshot.sectionIdentifiers[section]
        return cachedSnapshot.itemIdentifiers(inSection: section).count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let section = cachedSnapshot.sectionIdentifiers[indexPath.section]
        let item = cachedSnapshot.itemIdentifiers(inSection: section)[indexPath.row]
        return cellProvider(collectionView, indexPath, item)!
    }
}

private extension Array {
    func toDictionary<Key: Hashable>(keySelector: (Iterator.Element) -> Key) -> [Key: Iterator.Element] {
        return Dictionary(self.compactMap({ (keySelector($0), $0) }), uniquingKeysWith: ({ (first, _) in first }))
    }
}
