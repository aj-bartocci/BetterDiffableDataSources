//
//  File.swift
//  
//
//  Created by AJ Bartocci on 5/25/22.
//

import UIKit

public protocol BetterTableViewDiffableDataSourceRepresentable: CollectionViewDiffableDataSourceable where SectionIdentifierType: Hashable, ItemIdentifierType: DiffableItem {
    func apply(
        _ snapshot: BetterDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>,
        animatingDifferences: Bool,
        completion: (() -> Void)?
    )
}

public class BetterTableViewDiffableDataSource<SectionIdentifierType: Hashable, ItemIdentifierType: DiffableItem>: BetterTableViewDiffableDataSourceRepresentable {
    
    private var _appleSource: Any? = nil
    @available(iOS 13.0, *)
    fileprivate var appleSource: UITableViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType.DiffIdentifier> {
        get {
            if _appleSource == nil {
                _appleSource = UITableViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType.DiffIdentifier>(
                    tableView: tableView,
                    cellProvider: { collectionView, indexPath, itemIdentifier in
                        guard let item = self.cachedSnapshot.itemLookup[itemIdentifier] else {
                            return nil
                        }
                        return self.cellProvider(collectionView, indexPath, item)
                    }
                )
            }
            return _appleSource as! UITableViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType.DiffIdentifier>
        }
    }
    
    private lazy var polyfillSource: UICollectionViewDiffableDataSourcePolyfill<SectionIdentifierType, ItemIdentifierType.DiffIdentifier> = {
        fatalError("Not implemented")
//        return UICollectionViewDiffableDataSourcePolyfill(
//            collectionView: collectionView,
//            cellProvider: { collectionView, indexPath, itemIdentifier in
//                guard let item = self.cachedSnapshot.itemLookup[itemIdentifier] else {
//                    return nil
//                }
//                return self.cellProvider(collectionView, indexPath, item)
//            }
//        )
    }()
    public typealias CellProvider = (_ tableView: UITableView, _ indexPath: IndexPath, _ itemIdentifier: ItemIdentifierType) -> UITableViewCell?
    public typealias Snapshot = BetterDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>
    private weak var tableView: UITableView!
    private let cellProvider: CellProvider
    private var cachedSnapshot = Snapshot()
        
    public init(
        tableView: UITableView,
        cellProvider: @escaping CellProvider
    ) {
        self.tableView = tableView
        self.cellProvider = cellProvider
    }
    
    public func indexPath(for identifier: ItemIdentifierType) -> IndexPath? {
        if #available(iOS 13, *) {
            return appleSource.indexPath(for: identifier.diffId)
        } else {
            return polyfillSource.indexPath(for: identifier.diffId)
        }
    }
    
    public func itemIdentifier(for indexPath: IndexPath) -> ItemIdentifierType? {
        let rawIdentifier: ItemIdentifierType.DiffIdentifier?
        if #available(iOS 13, *) {
            rawIdentifier = appleSource.itemIdentifier(for: indexPath)
        } else {
            rawIdentifier = polyfillSource.itemIdentifier(for: indexPath)
        }
        guard let rawIdentifier = rawIdentifier else {
            return nil
        }
        return cachedSnapshot.itemLookup[rawIdentifier]
    }

    private var isFirstLoad = true
    public func apply(
        _ snapshot: Snapshot,
        animatingDifferences: Bool = true,
//        thresholdForReload: Int, // TODO: add a threshold so if it's too many changes just reload
        completion: (() -> Void)? = nil
    ) {
        var underlyingSnapshot = snapshot.snapshot
        var visibleIndexPathIndex = [IndexPath: Bool]()
        
        if isFirstLoad == false {
            // when accessing indexPathsForVisibleItems or visibleCells
            // before initial load it triggers all items in collection to
            // load which is not wanted, so only do diffing after initial
            // load has been performed
            for indexPath in (tableView.indexPathsForVisibleRows ?? []) {
                visibleIndexPathIndex[indexPath] = true
            }
        }
        isFirstLoad = false
        
        var itemsToReload = [ItemIdentifierType.DiffIdentifier]()
        var itemsToReconfigure = [ItemIdentifierType.DiffIdentifier]()
        var itemsToForceRefresh = [(ItemIdentifierType, IndexPath)]()
        for value in snapshot.itemLookup.values {
            defer {
                cachedSnapshot.itemLookup[value.diffId] = value
            }
            // check if it changed
            guard let existing = cachedSnapshot.itemLookup[value.diffId] else {
                continue
            }
            guard let indexPath = self.indexPath(for: value) else {
                continue
            }
            guard visibleIndexPathIndex[indexPath] == true else {
                continue
            }
            // if the value exists and is currently visible then perform
            // the diff and reload / reconfigure
            if !existing.itemIsEqual(to: value) {
                // item has changed so it should reload
                if value.prefersReconfigureOverReload() {
                    itemsToReconfigure.append(value.diffId)
                    itemsToForceRefresh.append((value, indexPath))
                } else {
                    itemsToReload.append(value.diffId)
                }
            }
        }
        
        if #available(iOS 15, *) {
            underlyingSnapshot.reconfigureItems(itemsToReconfigure)
            underlyingSnapshot.reloadItems(itemsToReload)
        } else {
            underlyingSnapshot.reconfigureItems(itemsToReconfigure)
            underlyingSnapshot.reloadItems(itemsToReload)
        }
        
        if #available(iOS 13, *) {
            appleSource.apply(
                underlyingSnapshot,
                animatingDifferences: animatingDifferences,
                completion: { [weak self] in
                    self?.cachedSnapshot = snapshot
                    completion?()
                }
            )
        } else {
            fatalError("Not implemented")
//            polyfillSource.apply(
//                underlyingSnapshot,
//                animatingDifferences: animatingDifferences,
//                completion: { [weak self] in
//                    self?.cachedSnapshot = snapshot
//                    completion?()
//                }
//            )
        }
    }
    
    public func snapshot() -> Snapshot {
        return cachedSnapshot
    }
}
