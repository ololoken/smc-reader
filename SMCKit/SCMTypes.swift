import CoreFoundation

//32 bytes
public typealias SMCBytes = (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                             UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                             UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                             UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                             UInt8, UInt8, UInt8, UInt8)

public struct SMCParamStruct {
    public enum Selector: UInt8 {
        case kSMCHandleYPCEvent  = 2
        case kSMCReadKey         = 5
        case kSMCWriteKey        = 6
        case kSMCGetKeyFromIndex = 8
        case kSMCGetKeyInfo      = 9
    }
    public enum Result: UInt8 {
        case kSMCSuccess     = 0
        case kSMCError       = 1
        case kSMCKeyNotFound = 132
    }

    public struct SMCVersion {
        var major: UInt8 = 0
        var minor: UInt8 = 0
        var build: UInt8 = 0
        var reserved: Int8 = 0
        var release: UInt16 = 0
    }

    public struct SMCPLimitData {
        var version: UInt16 = 0
        var length: UInt16 = 0
        var cpuPLimit: UInt32 = 0
        var gpuPLimit: UInt32 = 0
        var memPLimit: UInt32 = 0
    }

    public struct SMCKeyInfoData {
        var dataSize: UInt32 = 0
        var dataType: FourCharCode = 0
        var dataAttributes: UInt8 = 0
    }
    
    var key: FourCharCode = 0
    var vers = SMCVersion()
    var pLimitData = SMCPLimitData()
    var keyInfo = SMCKeyInfoData()
    var padding: UInt16 = 0
    var result: UInt8 = 0
    var status: UInt8 = 0
    var data8: UInt8 = 0
    var data32: UInt32 = 0
    var bytes: SMCBytes = (UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                           UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                           UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                           UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                           UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                           UInt8(0), UInt8(0))
}

public struct DataType: Equatable {
    let type: FourCharCode
    let size: UInt32
}

public enum SMCKnownDataType {
    static let Flt = FourCharCode(fromStaticString: "flt ");
    static let Fp1f = FourCharCode(fromStaticString: "fp1f");
    static let Fp4c = FourCharCode(fromStaticString: "fp4c");
    static let Fp5b = FourCharCode(fromStaticString: "fp5b");
    static let Fp6a = FourCharCode(fromStaticString: "fp6a");
    static let Fp79 = FourCharCode(fromStaticString: "fp79");
    static let Fp88 = FourCharCode(fromStaticString: "fp88");
    static let Fpa6 = FourCharCode(fromStaticString: "fpa6");
    static let Fpc4 = FourCharCode(fromStaticString: "fpc4");
    static let Fpe2 = FourCharCode(fromStaticString: "fpe2");
    static let Sp1e = FourCharCode(fromStaticString: "sp1e");
    static let Sp3c = FourCharCode(fromStaticString: "sp3c");
    static let Sp4b = FourCharCode(fromStaticString: "sp4b");
    static let Sp5a = FourCharCode(fromStaticString: "sp5a");
    static let Sp69 = FourCharCode(fromStaticString: "sp69");
    static let Sp78 = FourCharCode(fromStaticString: "sp78");
    static let Sp87 = FourCharCode(fromStaticString: "sp87");
    static let Sp96 = FourCharCode(fromStaticString: "sp96");
    static let Spb4 = FourCharCode(fromStaticString: "spb4");
    static let Spf0 = FourCharCode(fromStaticString: "spf0");
    static let Ui8  = FourCharCode(fromStaticString: "ui8 ");
    static let Ui16 = FourCharCode(fromStaticString: "ui16");
    static let Ui32 = FourCharCode(fromStaticString: "ui32");
    static let Ui64 = FourCharCode(fromStaticString: "ui64");
    static let Si8  = FourCharCode(fromStaticString: "si8 ");
    static let Si16 = FourCharCode(fromStaticString: "si16");
    static let Pwm  = FourCharCode(fromStaticString: "{pwm");
}
