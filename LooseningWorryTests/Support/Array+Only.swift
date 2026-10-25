extension Array {
    /// The sole element, or nil when there are none or several.
    var only: Element? {
        count == 1 ? first : nil
    }
}
