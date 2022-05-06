//
//  Dwifft.swift
//  Dwifft
//
//  Created by Jack Flintermann on 3/14/15.
//  Copyright (c) 2015 jflinter. All rights reserved.
//

/*

Embedding Dwifft library because their swift package isn't tagged properly. Once that is fixed
this file can be removed and the Dwifft package imported with SPM.

*/

/// SectionedValues represents, well, a bunch of sections and their associated values.
/// You can think of it sort of like an "ordered dictionary", or an order of key-pairs.
/// If you are diffing a multidimensional structure of values (what might normally be,
/// for example, a 2D array), you will want to use this.
public struct SectionedValues<Section: Equatable, Value: Equatable>: Equatable {

    /// Initializes the struct with an array of key-pairs.
    ///
    /// - Parameter sectionsAndValues: An array of tuples. The first element in the tuple is
    /// the value of the section. The second element is an array of values to be associated with
    /// that section. Ordering matters, obviously. Note, it's totally ok if `sectionsAndValues`
    /// contains duplicate sections (or duplicate values within those sections).
    public init(_ sectionsAndValues: [(Section, [Value])] = []) {
        self.sectionsAndValues = sectionsAndValues
    }

    /// The underlying tuples contained in the receiver
    public let sectionsAndValues: [(Section, [Value])]

    internal var sections: [Section] { get { return self.sectionsAndValues.map { $0.0 } } }
    internal subscript(i: Int) -> (Section, [Value]) {
        return self.sectionsAndValues[i]
    }


    /// Returns a new SectionedValues appending a new key-value pair. I think this might be useful
    /// if you're building up a SectionedValues conditionally? (Well, I hope it is, anyway.)
    ///
    /// - Parameter sectionAndValue: the new key-value pair
    /// - Returns: a new SectionedValues containing the receiever's contents plus the new pair.
    public func appending(sectionAndValue: (Section, [Value])) -> SectionedValues<Section, Value> {
        return SectionedValues(self.sectionsAndValues + [sectionAndValue])
    }

    /// Compares two `SectionedValues` instances
    public static func ==(lhs: SectionedValues<Section, Value>, rhs: SectionedValues<Section, Value>) -> Bool {
        guard lhs.sectionsAndValues.count == rhs.sectionsAndValues.count else { return false }
        for i in 0..<(lhs.sectionsAndValues.count) {
            let ltuple = lhs.sectionsAndValues[i]
            let rtuple = rhs.sectionsAndValues[i]
            if (ltuple.0 != rtuple.0 || ltuple.1 != rtuple.1) {
                return false
            }
        }
        return true
    }
}

// MARK: - Custom grouping
public extension SectionedValues where Section: Hashable {

    /// This is a convenience initializer of sorts for `SectionedValues`. It acknowledges
    /// that sometimes you have an array of things that are naturally "groupable" - maybe
    /// a list of names in an address book, that can be grouped into their first initial,
    /// or a bunch of events that can be grouped into buckets of timestamps. This will handle
    /// clumping all of your values into the correct sections, and ordering everything correctly.
    ///
    /// - Parameters:
    ///   - values: All of the values that will end up in the `SectionedValues` you're making.
    ///   - valueToSection: A function that maps each value to the section it will inhabit.
    ///     In the above examples, this would take a name and return its first initial,
    ///     or take an event and return its bucketed timestamp.
    ///   - sortSections: A function that compares two sections, and returns true if the first
    ///     should be sorted before the second. Used to sort the sections in the returned `SectionedValues`.
    ///   - sortValues: A function that compares two values, and returns true if the first
    ///     should be sorted before the second. Used to sort the values in each section of the returned `SectionedValues`.
    init(
        values: [Value],
        valueToSection: ((Value) -> Section),
        sortSections: ((Section, Section) -> Bool),
        sortValues: ((Value, Value) -> Bool)) {
        var dictionary = [Section: [Value]]()
        for value in values {
            let section = valueToSection(value)
            var current = dictionary[section] ?? []
            current.append(value)
            dictionary[section] = current
        }
        let sortedSections = dictionary.keys.sorted(by: sortSections)
        self.init(sortedSections.map { section in
            let values = dictionary[section] ?? []
            let sortedValues = values.sorted(by: sortValues)
            return (section, sortedValues)
        })
    }
    
}



/// These get returned from calls to Dwifft.diff(). They represent insertions or deletions
/// that need to happen to transform one array into another.
enum DiffStep<Value> : CustomDebugStringConvertible {
    /// An insertion.
    case insert(Int, Value)
    /// A deletion.
    case delete(Int, Value)

    var debugDescription: String {
        switch(self) {
        case let .insert(i, j):
            return "+\(j)@\(i)"
        case let .delete(i, j):
            return "-\(j)@\(i)"
        }
    }

    /// The index to be inserted or deleted.
    var idx: Int {
        switch(self) {
        case let .insert(i, _):
            return i
        case let .delete(i, _):
            return i
        }
    }

    /// The value to be inserted or deleted.
    var value: Value {
        switch(self) {
        case let .insert(_, j):
            return j
        case let .delete(_, j):
            return j
        }
    }
}

/// These get returned from calls to Dwifft.diff(). They represent insertions or deletions
/// that need to happen to transform one `SectionedValues` into another.
enum SectionedDiffStep<Section, Value>: CustomDebugStringConvertible {
    /// An insertion, at a given section and row.
    case insert(Int, Int, Value)
    /// An deletion, at a given section and row.
    case delete(Int, Int, Value)
    /// A section insertion, at a given section.
    case sectionInsert(Int, Section)
    /// A section deletion, at a given section.
    case sectionDelete(Int, Section)

    internal var section: Int {
        switch self {
        case let .insert(s, _, _): return s
        case let .delete(s, _, _): return s
        case let .sectionInsert(s, _): return s
        case let .sectionDelete(s, _): return s
        }
    }

    var debugDescription: String {
        switch self {
        case let .sectionDelete(s, _): return "ds(\(s))"
        case let .sectionInsert(s, _): return "is(\(s))"
        case let .delete(section, row, _): return "d(\(section) \(row))"
        case let .insert(section, row, _): return "i(\(section) \(row))"
        }
    }
}

/// Namespace for the `diff` and `apply` functions.
enum Dwifft {

    /// Returns the sequence of `DiffStep`s required to transform one array into another.
    ///
    /// - Parameters:
    ///   - lhs: an array
    ///   - rhs: another, uh, array
    /// - Returns: the series of transformations that, when applied to `lhs`, will yield `rhs`.
    static func diff<Value: Equatable>(_ lhs: [Value], _ rhs: [Value]) -> [DiffStep<Value>] {
        if lhs.isEmpty {
            return rhs.enumerated().map(DiffStep.insert)
        } else if rhs.isEmpty {
            return lhs.enumerated().map(DiffStep.delete).reversed()
        }

        let table = MemoizedSequenceComparison.buildTable(lhs, rhs)
        var result = diffInternal(table, lhs, rhs, lhs.count, rhs.count, ([], []))
        while case let .call(f) = result {
            result = f()
        }
        guard case let .done(accum) = result else { fatalError("unreachable code") }
        return accum.1 + accum.0
    }

    /// Applies a diff to an array. The following should always be true:
    /// Given `x: [T], y: [T]`, `Dwifft.apply(Dwifft.diff(x, y), toArray: x) == y`
    ///
    /// - Parameters:
    ///   - diff: a diff, as computed by calling `Dwifft.diff`. Note that you *must* be careful to
    ///   not modify said diff before applying it, and to only apply it to the left hand side of a
    ///   previous call to `Dwifft.diff`. If not, this can (and probably will) trigger an array out of bounds exception.
    ///   - lhs: an array.
    /// - Returns: `lhs`, transformed by `diff`.
    static func apply<Value>(diff: [DiffStep<Value>], toArray lhs: [Value]) -> [Value] {
        var copy = lhs
        for result in diff {
            switch result {
            case let .delete(idx, _):
                copy.remove(at: idx)
            case let .insert(idx, val):
                copy.insert(val, at: idx)
            }
        }
        return copy
    }

    /// Returns the sequence of `SectionedDiffStep`s required to transform one `SectionedValues` into another.
    ///
    /// - Parameters:
    ///   - lhs: a `SectionedValues`
    ///   - rhs: another, uh, `SectionedValues`
    /// - Returns: the series of transformations that, when applied to `lhs`, will yield `rhs`.
    static func diff<Section, Value>(lhs: SectionedValues<Section, Value>, rhs: SectionedValues<Section, Value>) -> [SectionedDiffStep<Section, Value>] {
        if lhs.sections == rhs.sections {
            let allResults: [[SectionedDiffStep<Section, Value>]] = (0..<lhs.sections.count).map { i in
                let lValues = lhs.sectionsAndValues[i].1
                let rValues = rhs.sectionsAndValues[i].1
                let rowDiff = Dwifft.diff(lValues, rValues)
                let results: [SectionedDiffStep<Section, Value>] = rowDiff.map { result in
                    switch result {
                    case let .insert(j, t): return SectionedDiffStep.insert(i, j, t)
                    case let .delete(j, t): return SectionedDiffStep.delete(i, j, t)
                    }
                }
                return results
            }
            let flattened = allResults.flatMap { $0 }
            let insertions = flattened.filter { result in
                if case .insert = result { return true }
                return false
            }
            let deletions = flattened.filter { result in
                if case .delete = result { return true }
                return false
            }
            return deletions + insertions

        } else {
            var middleSectionsAndValues = lhs.sectionsAndValues
            let sectionDiff = Dwifft.diff(lhs.sections, rhs.sections)
            var sectionInsertions: [SectionedDiffStep<Section, Value>] = []
            var sectionDeletions: [SectionedDiffStep<Section, Value>] = []
            for result in sectionDiff {
                switch result {
                case let .insert(i, s):
                    sectionInsertions.append(SectionedDiffStep.sectionInsert(i, s))
                    middleSectionsAndValues.insert((s, []), at: i)
                case let .delete(i, s):
                    sectionDeletions.append(SectionedDiffStep.sectionDelete(i, s))
                    middleSectionsAndValues.remove(at: i)
                }
            }

            let middle = SectionedValues(middleSectionsAndValues)
            let rowResults = Dwifft.diff(lhs: middle, rhs: rhs)

            // we need to calculate a mapping from the final section indices to the original
            // section indices. This lets us perform the deletions before the section deletions,
            // which makes UITableView + UICollectionView happy. See https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/TableView_iPhone/ManageInsertDeleteRow/ManageInsertDeleteRow.html#//apple_ref/doc/uid/TP40007451-CH10-SW9
            var indexMapping = Array(0..<lhs.sections.count)
            for deletion in sectionDeletions {
                indexMapping.remove(at: deletion.section)
            }
            for insertion in sectionInsertions {
                indexMapping.insert(-1, at: insertion.section)
            }
            var mapping = [Int: Int]()
            for (i, j) in indexMapping.enumerated() {
                mapping[i] = j
            }

            let deletions = rowResults.filter { result in
                if case .delete = result {
                    return true
                }
                return false
            }

            let insertions = rowResults.filter { result in
                if case .insert = result {
                    return true
                }
                return false
            }

            let mappedDeletions: [SectionedDiffStep<Section, Value>] = deletions.map { deletion in
                guard case let .delete(section, row, val) = deletion else { fatalError("not possible") }
                guard let newIndex = mapping[section], newIndex != -1 else { fatalError("not possible") }
                return .delete(newIndex, row, val)
            }

            return mappedDeletions + sectionDeletions + sectionInsertions + insertions

        }
    }

    /// Applies a diff to a `SectionedValues`. The following should always be true:
    /// Given `x: SectionedValues<S,T>, y: SectionedValues<S,T>`,
    /// `Dwifft.apply(Dwifft.diff(lhs: x, rhs: y), toSectionedValues: x) == y`
    ///
    /// - Parameters:
    ///   - diff: a diff, as computed by calling `Dwifft.diff`. Note that you *must* be careful to
    ///   not modify said diff before applying it, and to only apply it to the left hand side of a
    ///   previous call to `Dwifft.diff`. If not, this can (and probably will) trigger an array out of bounds exception.
    ///   - lhs: a `SectionedValues`.
    /// - Returns: `lhs`, transformed by `diff`.
    static func apply<Section, Value>(diff: [SectionedDiffStep<Section, Value>], toSectionedValues lhs: SectionedValues<Section, Value>) -> SectionedValues<Section, Value> {
        var sectionsAndValues = lhs.sectionsAndValues
        for result in diff {
            switch result {
            case let .sectionInsert(sectionIndex, val):
                sectionsAndValues.insert((val, []), at: sectionIndex)
            case let .sectionDelete(sectionIndex, _):
                sectionsAndValues.remove(at: sectionIndex)
            case let .insert(sectionIndex, rowIndex, val):
                sectionsAndValues[sectionIndex].1.insert(val, at: rowIndex)
            case let .delete(sectionIndex, rowIndex, _):
                sectionsAndValues[sectionIndex].1.remove(at: rowIndex)
            }
        }
        return SectionedValues(sectionsAndValues)
    }

    private static func diffInternal<Value: Equatable>(
        _ table: [[Int]],
        _ x: [Value],
        _ y: [Value],
        _ i: Int,
        _ j: Int,
        _ currentResults: ([DiffStep<Value>], [DiffStep<Value>])
        ) -> Result<([DiffStep<Value>], [DiffStep<Value>])> {
        if i == 0 && j == 0 {
            return .done(currentResults)
        }
        else {
            return .call {
                var nextResults = currentResults
                if i == 0 {
                    nextResults.0 = [DiffStep.insert(j-1, y[j-1])] + nextResults.0
                    return diffInternal(table, x, y, i, j-1, nextResults)
                } else if j == 0 {
                    nextResults.1 = nextResults.1 + [DiffStep.delete(i-1, x[i-1])]
                    return diffInternal(table, x, y, i - 1, j, nextResults)
                } else if table[i][j] == table[i][j-1] {
                    nextResults.0 = [DiffStep.insert(j-1, y[j-1])] + nextResults.0
                    return diffInternal(table, x, y, i, j-1, nextResults)
                } else if table[i][j] == table[i-1][j] {
                    nextResults.1 = nextResults.1 + [DiffStep.delete(i-1, x[i-1])]
                    return diffInternal(table, x, y, i - 1, j, nextResults)
                } else {
                    return diffInternal(table, x, y, i-1, j-1, nextResults)
                }
            }
        }
    }
}

fileprivate enum Result<T>{
    case done(T)
    case call(() -> Result<T>)
}

fileprivate struct MemoizedSequenceComparison<T: Equatable> {
    static func buildTable(_ x: [T], _ y: [T]) -> [[Int]] {
        let n = x.count, m = y.count
        var table = Array(repeating: Array(repeating: 0, count: m + 1), count: n + 1)
        // using unsafe pointers lets us avoid swift array bounds-checking, which results in a considerable speed boost.
        table.withUnsafeMutableBufferPointer { unsafeTable in
            x.withUnsafeBufferPointer { unsafeX in
                y.withUnsafeBufferPointer { unsafeY in
                    for i in 1...n {
                        for j in 1...m {
                            if unsafeX[i&-1] == unsafeY[j&-1] {
                                unsafeTable[i][j] = unsafeTable[i&-1][j&-1] + 1
                            } else {
                                unsafeTable[i][j] = max(unsafeTable[i&-1][j], unsafeTable[i][j&-1])
                            }
                        }
                    }

                }
            }
        }
        return table
    }
}


// MARK: - Deprecated
extension Array where Element: Equatable {

    /// Deprecated in favor of `Dwifft.diff`.
    @available(*, deprecated)
    func diff(_ other: [Element]) -> [DiffStep<Element>] {
        return Dwifft.diff(self, other)
    }

    /// Deprecated in favor of `Dwifft.apply`.
    @available(*, deprecated)
    func apply(_ diff: [DiffStep<Element>]) -> [Element] {
        return Dwifft.apply(diff: diff, toArray: self)
    }

}
