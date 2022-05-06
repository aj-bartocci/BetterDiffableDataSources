//
//  CollectionViewDiffableDataSourceRepresentable.swift
//  DiffableCollection
//
//  Created by AJ Bartocci on 5/4/22.
//

import UIKit

public protocol CollectionViewDiffableDataSourceable {
    associatedtype SectionIdentifierType
    associatedtype ItemIdentifierType
    
    func indexPath(for itemIdentifier: ItemIdentifierType) -> IndexPath?
    func itemIdentifier(for indexPath: IndexPath) -> ItemIdentifierType?
}

public protocol CollectionViewDiffableDataSourceRepresentable: CollectionViewDiffableDataSourceable where SectionIdentifierType: Hashable, ItemIdentifierType: Hashable {
    func apply(
        _ snapshot: DiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>,
        animatingDifferences: Bool,
        completion: (() -> Void)?
    )
}


