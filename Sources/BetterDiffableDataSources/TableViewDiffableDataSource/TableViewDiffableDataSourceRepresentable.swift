//
//  File.swift
//  
//
//  Created by AJ Bartocci on 5/25/22.
//

import UIKit

public protocol TableViewDiffableDataSourceable {
    associatedtype SectionIdentifierType
    associatedtype ItemIdentifierType
    
//    func indexPath(for itemIdentifier: ItemIdentifierType) -> IndexPath?
//    func itemIdentifier(for indexPath: IndexPath) -> ItemIdentifierType?
}

public protocol TableViewDiffableDataSourceRepresentable: TableViewDiffableDataSourceable where SectionIdentifierType: Hashable, ItemIdentifierType: Hashable {
    func apply(
        _ snapshot: DiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>,
        animatingDifferences: Bool,
        completion: (() -> Void)?
    )
}
