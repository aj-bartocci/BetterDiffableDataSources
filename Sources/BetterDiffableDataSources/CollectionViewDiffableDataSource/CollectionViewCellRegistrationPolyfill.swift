//
//  CollectionViewCellRegistrationPolyfill.swift
//  DiffableCollection
//
//  Created by AJ Bartocci on 5/4/22.
//

import UIKit

@available(iOS, deprecated: 14.0, renamed: "UICollectionView.SupplementaryRegistration")
public struct CollectionViewSupplementaryRegistration<Supplementary> where Supplementary : UICollectionReusableView {
    public typealias Handler = (_ supplementaryView: Supplementary, _ elementKind: String, _ indexPath: IndexPath) -> Void
    let elementKind: String
    let handler: Handler
    
    public init(elementKind: String, handler: @escaping CollectionViewSupplementaryRegistration<Supplementary>.Handler) {
        self.elementKind = elementKind
        self.handler = handler
    }
}

@available(iOS, deprecated: 14.0, renamed: "UICollectionView.CellRegistration")
public struct CollectionViewCellRegistration<Cell, Item> where Cell : UICollectionViewCell {
    public typealias Handler = (_ cell: Cell, _ indexPath: IndexPath, _ itemIdentifier: Item) -> Void
    let handler: Handler
    
    public init(handler: @escaping CollectionViewCellRegistration<Cell, Item>.Handler) {
        self.handler = handler
    }
}

public extension UICollectionView {
    @available(iOS, deprecated: 14.0, renamed: "dequeueConfiguredReusableSupplementary")
    func dequeueConfiguredSupplementary<Supplementary>(
        using registration: CollectionViewSupplementaryRegistration<Supplementary>,
        for indexPath: IndexPath
    ) -> Supplementary where Supplementary : UICollectionReusableView {
        self.register(Supplementary.self, forSupplementaryViewOfKind: registration.elementKind)
        let view = self.dequeueReuseableView(Supplementary.self, ofKind: registration.elementKind, for: indexPath)
        registration.handler(view, registration.elementKind, indexPath)
        return view
    }

    @available(iOS, deprecated: 14.0, renamed: "dequeueConfiguredReusableCell")
    func dequeueConfiguredCell<Cell, Item>(
        using registration: CollectionViewCellRegistration<Cell, Item>,
        for indexPath: IndexPath,
        item: Item?
    ) -> Cell where Cell: UICollectionViewCell {
        self.register(Cell.self)
        let cell = self.dequeueReuseableCell(Cell.self, for: indexPath)
        if let item = item {
            registration.handler(cell, indexPath, item)
        }
        return cell
    }
}

// MARK: Deqeue functions
private extension UICollectionView {
    
    func register(_ cellClass: AnyClass) {
        register(cellClass, forCellWithReuseIdentifier: String(describing: cellClass))
    }
    
    func register(_ viewClass: AnyClass, forSupplementaryViewOfKind kind: String) {
        register(viewClass, forSupplementaryViewOfKind: kind, withReuseIdentifier: String(describing: viewClass))
    }
    
    func dequeueReuseableCell<T: UICollectionViewCell>(_ cellClass: T.Type, for indexPath: IndexPath) -> T {
        return dequeueReusableCell(withReuseIdentifier: String(describing: cellClass), for: indexPath) as! T
    }
    
    func dequeueReuseableView<T: UICollectionReusableView>(_ viewClass: T.Type, ofKind kind: String = UICollectionView.elementKindSectionHeader, for indexPath: IndexPath) -> T {
        return dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: String(describing: viewClass), for: indexPath) as! T
    }
}
