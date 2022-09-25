import AppKit

public extension Substring {
    var range: Range<String.Index> {
        startIndex..<endIndex
    }
}

public extension CGSize {
    static func /(_ lhs: CGSize, _ rhs: CGFloat) -> CGSize {
        CGSize(width: lhs.width / rhs, height: lhs.height / rhs)
    }

    static func *(_ lhs: CGSize, _ rhs: CGFloat) -> CGSize {
        CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
    }
}

public extension CGVector {
    static func -(lhs: CGVector, rhs: CGVector) -> CGVector{
        CGVector(dx: lhs.dx - rhs.dx, dy: lhs.dy - rhs.dy)
    }

    static func +(lhs: CGVector, rhs: CGVector) -> CGVector{
        CGVector(dx: lhs.dx + rhs.dx, dy: lhs.dy + rhs.dy)
    }

    func invertedDY() -> CGVector {
        var copy = self
        copy.dy = -copy.dy
        return copy
    }
}

public extension ClosedRange where Bound: BinaryFloatingPoint {
    init<Other: BinaryFloatingPoint>(_ other: ClosedRange<Other>) {
        self = Bound(other.lowerBound)...Bound(other.upperBound)
    }

    init<Other: BinaryInteger>(_ other: ClosedRange<Other>) {
        self = Bound(other.lowerBound)...Bound(other.upperBound)
    }
}
