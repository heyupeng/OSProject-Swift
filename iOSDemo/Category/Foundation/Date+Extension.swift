//
//  Date+Extension.swift
//  Sample-Swift
//
//  Created by Peng on 2021/5/17.
//

import Foundation

extension Date {
    var year: Int {
        return Calendar.current.component(.year, from: self)
    }
    var month: Int {
        return Calendar.current.component(.month, from: self)
    }
    var day: Int {
        return Calendar.current.component(.day, from: self)
    }
    var hour: Int {
        return Calendar.current.component(.hour, from: self)
    }
    var weekday: Int {
        let weekday = Calendar.current.component(.weekday, from: self)
        let cnWeekday = [7, 1, 2, 3, 4, 5, 6]
        return cnWeekday[weekday - 1]
    }
    
    /// 当日初始时间
    var startTimeStamp: Int {
        let timeZone = TimeZone.current
        let offset = timeZone.secondsFromGMT()
        
        let time = Int(self.timeIntervalSince1970)
        let time2 = time % 86400
        return time - time2 - offset
    }
    
    func format(format: String) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
}
