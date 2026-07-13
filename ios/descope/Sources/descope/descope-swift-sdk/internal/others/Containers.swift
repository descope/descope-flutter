
class WeakCollection<T>: Sequence {
    func add(_ element: AnyObject) {
        references.removeAll { $0.element == nil }
        references.append(WeakReference(element: element))
    }

    func remove(_ element: AnyObject) {
        if let index = references.firstIndex(where: { $0.element === element }) {
            references.remove(at: index)
        }
    }

    func makeIterator() -> IndexingIterator<[T]> {
        return references.compactMap { $0.element as? T }.makeIterator()
    }

    private var references: [WeakReference] = []

    private struct WeakReference {
        weak var element: AnyObject?
    }
}
