//
//  CollectionViewDiffableDataSource.swift
//  DiffableCollection
//
//  Created by AJ Bartocci on 5/4/22.
//

import UIKit

@available(iOS, deprecated: 13.0, renamed: "UICollectionViewDiffableDataSource")
public class CollectionViewDiffableDataSource<SectionIdentifier: Hashable, ItemIdentifier: Hashable> {
    
    private var _appleSource: Any? = nil
    @available(iOS 13.0, *)
    fileprivate var appleSource: UICollectionViewDiffableDataSource<SectionIdentifier, ItemIdentifier> {
        get {
            if _appleSource == nil {
                _appleSource = UICollectionViewDiffableDataSource<SectionIdentifier, ItemIdentifier>(
                    collectionView: collectionView,
                    cellProvider: cellProvider
                )
            }
            return _appleSource as! UICollectionViewDiffableDataSource<SectionIdentifier, ItemIdentifier>
        }
    }
    
    private lazy var polyfillSource: UICollectionViewDiffableDataSourcePolyfill<SectionIdentifier, ItemIdentifier> = {
        return UICollectionViewDiffableDataSourcePolyfill(collectionView: collectionView, cellProvider: cellProvider)
    }()
    public typealias CellProvider = (_ collectionView: UICollectionView, _ indexPath: IndexPath, _ itemIdentifier: ItemIdentifier) -> UICollectionViewCell?
    public typealias Snapshot = DiffableDataSourceSnapshot<SectionIdentifier, ItemIdentifier>
    private weak var collectionView: UICollectionView!
    private let cellProvider: CellProvider
    private var cachedSnapshot = Snapshot()
        
    public init(
        collectionView: UICollectionView,
        cellProvider: @escaping CellProvider
    ) {
        self.collectionView = collectionView
        self.cellProvider = cellProvider
    }
    
    public func indexPath(for identifier: ItemIdentifier) -> IndexPath? {
        if #available(iOS 13, *) {
            return appleSource.indexPath(for: identifier)
        } else {
            return polyfillSource.indexPath(for: identifier)
        }
    }
    
    public func itemIdentifier(for indexPath: IndexPath) -> ItemIdentifier? {
        if #available(iOS 13, *) {
            return appleSource.itemIdentifier(for: indexPath)
        } else {
            return polyfillSource.itemIdentifier(for: indexPath)
        }
    }
        
    private var isFirstLoad = true
    public func apply(
        _ snapshot: Snapshot,
        animatingDifferences: Bool = true,
//        thresholdForReload: Int, // TODO: add a threshold so if it's too many changes just reload
        completion: (() -> Void)? = nil
    ) {
//        cachedSnapshot = snapshot
        if #available(iOS 13, *) {
            appleSource.apply(
                snapshot,
                animatingDifferences: animatingDifferences,
                completion: {
                    self.cachedSnapshot = snapshot
                    completion?()
                }
            )
        } else {
            polyfillSource.apply(
                snapshot,
                animatingDifferences: animatingDifferences,
                completion: {
                    self.cachedSnapshot = snapshot
                    completion?()
                }
            )
        }
    }
    
    public func snapshot() -> Snapshot {
        return cachedSnapshot
    }
}
