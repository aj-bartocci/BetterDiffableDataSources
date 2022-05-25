//
//  File.swift
//  
//
//  Created by AJ Bartocci on 5/25/22.
//
import UIKit

@available(iOS 13, *)
extension UITableViewDiffableDataSource: TableViewDiffableDataSourceRepresentable {
    public func apply(
        _ snapshot: DiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>,
        animatingDifferences: Bool,
        completion: (() -> Void)?
    ) {
        self.apply(
            snapshot.iOS13Snapshot(),
            animatingDifferences: animatingDifferences,
            completion: completion
        )
    }
}
