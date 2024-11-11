import IOKit
import Foundation

public struct SMCKit {

    public enum SMCError: Error {
        case driverNotFound
        case failedToOpen
        case keyNotFound(code: String)
        case notPrivileged
        case unsafeFanSpeed
        case unknown(kIOReturn: kern_return_t, SMCResult: UInt8)
    }

    fileprivate static var connection = UnsafeMutablePointer<io_connect_t>.allocate(capacity: 1)

    public static func open() throws {
        let iter = UnsafeMutablePointer<io_iterator_t>.allocate(capacity: 1);
        let res = IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("AppleSMC"), iter);
        if (res != kIOReturnSuccess) { throw SMCError.driverNotFound }
        let service = IOIteratorNext(iter.pointee);
        IOObjectRelease(iter.pointee);
        iter.deallocate();

        if (service == kIOReturnNotFound) { throw SMCError.driverNotFound }

        let result = IOServiceOpen(service, mach_task_self_, 0, SMCKit.connection)
        IOObjectRelease(service)

        if (result != kIOReturnSuccess) { throw SMCError.failedToOpen }
    }

    @discardableResult
    public static func close() -> Bool {
        let result = IOServiceClose(SMCKit.connection.pointee)
        return result == kIOReturnSuccess
    }

    public static func keyInformation(_ key: FourCharCode) throws -> DataType {
        var inputStruct = SMCParamStruct()

        inputStruct.key = key
        inputStruct.data8 = SMCParamStruct.Selector.kSMCGetKeyInfo.rawValue

        let outputStruct = try callDriver(&inputStruct)
        return DataType(type: outputStruct.keyInfo.dataType,
                        size: UInt32(outputStruct.keyInfo.dataSize))
    }

    public static func keyCodeAtIndex(_ index: Int) throws -> FourCharCode {
        var inputStruct = SMCParamStruct()

        inputStruct.data8 = SMCParamStruct.Selector.kSMCGetKeyFromIndex.rawValue
        inputStruct.data32 = UInt32(index)

        return try callDriver(&inputStruct).key
    }

    public static func readData(_ key: FourCharCode) throws -> (SMCParamStruct.SMCKeyInfoData, SMCParamStruct) {
        let keyInfo = try keyInformation(key)
        var inputStruct = SMCParamStruct()
        inputStruct.key = key
        inputStruct.keyInfo.dataSize = keyInfo.size
        inputStruct.keyInfo.dataType = keyInfo.type
        inputStruct.data8 = SMCParamStruct.Selector.kSMCReadKey.rawValue;
        return (inputStruct.keyInfo, try callDriver(&inputStruct))
    }
    
    public static func readDoubleValue(_ key: FourCharCode) throws -> Double {
        let (keyInfo, data) = try readData(key)
        let bytes = Mirror(reflecting: data.bytes).children.map({byte in byte.value as! UInt8 }).prefix(Int(keyInfo.dataSize));
        switch keyInfo.dataType {
        case SMCKnownDataType.Ui8: return Double(bytes.withUnsafeBytes { b in b.load(as: UInt8.self)})
        case SMCKnownDataType.Ui16: return Double(bytes.withUnsafeBytes { b in b.load(as: UInt16.self)})
        case SMCKnownDataType.Ui32: return Double(bytes.reversed().withUnsafeBytes { b in b.load(as: UInt32.self)})
        case SMCKnownDataType.Ui64: return Double(bytes.withUnsafeBytes { b in b.load(as: UInt64.self)})
        case SMCKnownDataType.Flt: return Double(bytes.withUnsafeBytes { b in b.load(as: Float.self)})
        case SMCKnownDataType.Fp1f: return Double(bytes.withUnsafeBytes { b in b.load(as: UInt16.self)})/0x8000
        case SMCKnownDataType.Sp1e: return Double(bytes.withUnsafeBytes { b in b.load(as: UInt16.self)})/0x4000
        case SMCKnownDataType.Sp3c: fallthrough
        case SMCKnownDataType.Fp4c: return Double(bytes.withUnsafeBytes { b in b.load(as: UInt16.self)})/0x1000
        case SMCKnownDataType.Sp4b: fallthrough
        case SMCKnownDataType.Fp5b: return Double(bytes.withUnsafeBytes { b in b.load(as: UInt16.self)})/0x800
        case SMCKnownDataType.Sp5a: fallthrough
        case SMCKnownDataType.Fp6a: return Double(bytes.withUnsafeBytes { b in b.load(as: UInt16.self)})/0x400
        case SMCKnownDataType.Sp69: fallthrough
        case SMCKnownDataType.Fp79: return Double(bytes.withUnsafeBytes { b in b.load(as: UInt16.self)})/0x200
        case SMCKnownDataType.Sp78: fallthrough
        case SMCKnownDataType.Fp88: return Double(bytes.withUnsafeBytes { b in b.load(as: UInt16.self)})/0x100
        case SMCKnownDataType.Sp87: return Double(bytes.withUnsafeBytes { b in b.load(as: UInt16.self)})/0x80
        case SMCKnownDataType.Sp96: fallthrough
        case SMCKnownDataType.Fpa6: return Double(bytes.withUnsafeBytes { b in b.load(as: UInt16.self)})/0x40
        case SMCKnownDataType.Spb4: fallthrough
        case SMCKnownDataType.Fpc4: return Double(bytes.withUnsafeBytes { b in b.load(as: UInt16.self)})/0x10
        case SMCKnownDataType.Fpe2: return Double(bytes.withUnsafeBytes { b in b.load(as: UInt16.self)})/0x4
        case SMCKnownDataType.Spf0: return Double(bytes.withUnsafeBytes { b in b.load(as: UInt16.self)})
        case SMCKnownDataType.Si8: return Double(bytes.withUnsafeBytes { b in b.load(as: Int8.self)})
        case SMCKnownDataType.Si16: return Double(bytes.withUnsafeBytes { b in b.load(as: Int16.self)})
        case SMCKnownDataType.Pwm: return Double(bytes.withUnsafeBytes { b in b.load(as: UInt16.self)})*100/0x10000
        default:
            return -5;
        }
    }

    public static func callDriver(_ inputStruct: inout SMCParamStruct, selector: SMCParamStruct.Selector = .kSMCHandleYPCEvent) throws -> SMCParamStruct {
        assert(MemoryLayout<SMCParamStruct>.stride == 80, "SMCParamStruct size is != 80")

        var outputStruct = SMCParamStruct()
        let inputStructSize = MemoryLayout<SMCParamStruct>.stride
        var outputStructSize = MemoryLayout<SMCParamStruct>.stride

        let result = IOConnectCallStructMethod(SMCKit.connection.pointee,
                                               UInt32(selector.rawValue),
                                               &inputStruct,
                                               inputStructSize,
                                               &outputStruct,
                                               &outputStructSize)

        switch (result, outputStruct.result) {
            case (kIOReturnSuccess, SMCParamStruct.Result.kSMCSuccess.rawValue): return outputStruct
            case (kIOReturnSuccess, SMCParamStruct.Result.kSMCKeyNotFound.rawValue): throw SMCError.keyNotFound(code: inputStruct.key.toString())
            case (kIOReturnNotPrivileged, _): throw SMCError.notPrivileged
            default: throw SMCError.unknown(kIOReturn: result, SMCResult: outputStruct.result)
        }
    }
}

extension SMCKit {

    public static func allKeys() throws -> [(code: FourCharCode, type: DataType)] {
        let count = try keyCount()
        var keys = [(code: FourCharCode, type: DataType)]()
        for i in 0 ..< count {
            do {
                let key = try keyCodeAtIndex(i)
                keys.append((code: key, type: try keyInformation(key)))
            } catch SMCError.notPrivileged { /* ignore private keys */ }
        }
        return keys
    }

    public static func keyCount() throws -> Int {
        let (type, data) = try readData(FourCharCode(fromStaticString: "#KEY"))
        assert(type.dataType == SMCKnownDataType.Ui32, "#KEY count type must be Ui32, \(type.dataType.toString()) provided")
        return Int(Mirror(reflecting: data.bytes).children
            .map { byte in byte.value as! UInt8 }
            .prefix(Int(type.dataSize))
            .reversed().withUnsafeBytes { b in b.load(as: UInt32.self)})
    }

    public static func keyExists(_ code: FourCharCode) throws -> Bool {
        do {
            _ = try keyInformation(code)
        } catch SMCError.keyNotFound { return false }

        return true
    }
}

