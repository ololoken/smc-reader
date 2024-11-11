//
//  main.swift
//  smc
//
//  Created by Roman Turchin on 08.11.2024.
//

import Foundation

var bufferSize = 64
var buffer = [CChar](repeating: 0, count: bufferSize)
sysctlbyname("machdep.cpu.brand_string", &buffer, &bufferSize, nil, 0)
let model = String(cString: buffer);

var coreSensors = [FourCharCode]();
switch true {
case model.contains(/[Mm]1/):
    //cpu performance cores
    coreSensors.append(FourCharCode(fromStaticString: "Tp01"));
    coreSensors.append(FourCharCode(fromStaticString: "Tp05"));
    coreSensors.append(FourCharCode(fromStaticString: "Tp0D"));
    coreSensors.append(FourCharCode(fromStaticString: "Tp0H"));
    coreSensors.append(FourCharCode(fromStaticString: "Tp0L"));
    coreSensors.append(FourCharCode(fromStaticString: "Tp0P"));
    coreSensors.append(FourCharCode(fromStaticString: "Tp0X"));
    coreSensors.append(FourCharCode(fromStaticString: "Tp0b"));
    // CPU efficient cores
    coreSensors.append(FourCharCode(fromStaticString: "Tp09"));
    coreSensors.append(FourCharCode(fromStaticString: "Tp0T"));
    break;
case model.contains(/[Mm]2/):
    //cpu performance cores
    coreSensors.append(FourCharCode(fromString: "Tp01"))
    coreSensors.append(FourCharCode(fromString: "Tp09"))
    coreSensors.append(FourCharCode(fromString: "Tp0f"))
    coreSensors.append(FourCharCode(fromString: "Tp0n"))
    coreSensors.append(FourCharCode(fromString: "Tp05"))
    coreSensors.append(FourCharCode(fromString: "Tp0D"))
    coreSensors.append(FourCharCode(fromString: "Tp0j"))
    coreSensors.append(FourCharCode(fromString: "Tp0r"))
    //cpu efficient cores
    coreSensors.append(FourCharCode(fromString: "Tp1h"))
    coreSensors.append(FourCharCode(fromString: "Tp1t"))
    coreSensors.append(FourCharCode(fromString: "Tp1p"))
    coreSensors.append(FourCharCode(fromString: "Tp1l"))
    break;
case model.contains(/[Mm]3/):
    //cpu performance cores
    coreSensors.append(FourCharCode(fromStaticString: "Tp01"))
    coreSensors.append(FourCharCode(fromStaticString: "Tp09"))
    coreSensors.append(FourCharCode(fromStaticString: "Tp0f"))
    coreSensors.append(FourCharCode(fromStaticString: "Tp0n"))
    coreSensors.append(FourCharCode(fromStaticString: "Tp05"))
    coreSensors.append(FourCharCode(fromStaticString: "Tp0D"))
    coreSensors.append(FourCharCode(fromStaticString: "Tp0j"))
    coreSensors.append(FourCharCode(fromStaticString: "Tp0r"))
    break;
default: print("Model [\(model)] not supported")
}

try SMCKit.open()

let coreSensorsData = coreSensors
    .map {key in
        let val: Double;
        do { val = try SMCKit.readDoubleValue(key) }
        catch { val = -1.0 }
        print(key.toString(), val);
        return val;
    }
    .filter { val in val > 0 }

print("avg cores temp:", coreSensorsData.reduce(0, { sum, val in sum + val })/Double(coreSensorsData.count), "˚C");

SMCKit.close()

exit(0);
