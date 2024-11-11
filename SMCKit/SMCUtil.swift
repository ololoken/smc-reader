import CoreFoundation

public extension FourCharCode {

    init(fromString str: String) {
        precondition(str.count == 4)

        self = str.utf8.reduce(0) { sum, character in
            return sum << 8 | UInt32(character)
        }
    }

    init(fromStaticString str: StaticString) {
        precondition(str.utf8CodeUnitCount == 4)

        self = str.withUTF8Buffer { buffer in
            return UInt32(buffer[0]) << 24 | UInt32(buffer[1]) << 16 | UInt32(buffer[2]) << 8 | UInt32(buffer[3])
        }
    }

    func toString() -> String {
        return String(describing: UnicodeScalar(self >> 24 & 0xff)!) +
               String(describing: UnicodeScalar(self >> 16 & 0xff)!) +
               String(describing: UnicodeScalar(self >> 8  & 0xff)!) +
               String(describing: UnicodeScalar(self       & 0xff)!)
    }
}


