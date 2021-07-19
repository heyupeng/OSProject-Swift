//
//  CompanyIdentfier.swift
//  Sample-Swift
//
//  Created by Peng on 2021/6/9.
//

import Foundation

/// Company Identfier of the manufacture data for bluetooth
///
/// [Lookup company-identifiers](https://www.bluetooth.com/specifications/assigned-numbers/company-identifiers/)
///
struct CompanyIdentfier {
    var decimal: UInt
    var hexadecimal: String
    var company: String
}

extension CompanyIdentfier: CustomStringConvertible {
    var description: String {
        return "decimal: \(decimal), hex: \(hexadecimal), company: \(company)"
    }
}

extension CompanyIdentfier {
    static var companyIdentfiers: [CompanyIdentfier] = {
        if let url = Bundle.main.url(forResource: "CompanyIdentfiers - CSV", withExtension: "csv") {
            return Self.loadCompanyIdentfiers(fileURL: url)
        }
        return []
    }()
    
    static func loadCompanyIdentfiers(fileURL: URL) -> [CompanyIdentfier] {
        print("--- It begins to load company-identifiers. ---")
        let parser = CSVParser(contentsOf: fileURL)
        guard parser.parse(), parser.entities.count > 1 else {
            return []
        }
        
        let object = parser.entities
        var cpys: [CompanyIdentfier] = []
        for idx in 1..<object.count {
            if object[idx].count < 3 { continue }
            let decimal = object[idx][0]
            let hexadecimal = object[idx][1]
            let company = object[idx][2]
            let cpy = CompanyIdentfier(decimal: UInt(decimal)!, hexadecimal: hexadecimal, company: company)
            cpys.append(cpy)
        }
        print("--- It has loaded \(cpys.count) company-identifiers. ---")
        return cpys;
    }
    
    init?(decimal: UInt8) {
        let idx = Self.companyIdentfiers.count - 1 - Int(decimal)
        if idx >= 0, Self.companyIdentfiers[idx].decimal == decimal {
            self = Self.companyIdentfiers[idx]
            return
        }
        return nil
    }
}
