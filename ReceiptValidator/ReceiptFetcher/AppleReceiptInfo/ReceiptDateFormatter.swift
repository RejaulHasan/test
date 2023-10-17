//
//  ReceiptDateFormatter.swift
//  ReceiptValidator
//
//  Created by Admin on 17/10/23.
//

import Foundation

// MARK: ReceiptDateFormatter

/// Static formatting methods to use for string encoded date values in receipts
enum ReceiptDateFormatter {

    /// Uses receipt-conform representation of dates like "2017-01-01T12:00:00Z",
    /// as a fallback, dates like "2017-01-01T12:00:00.123Z" are also parsed.
    static func date(from string: String) -> Date? {
        return self.defaultDateFormatter.date(from: string) // expected
            ?? self.fallbackDateFormatterWithMS.date(from: string) // try again with milliseconds
    }

    /// Uses receipt-conform representation of dates like "2017-01-01T12:00:00Z" (rfc3339 without millis)
    static let defaultDateFormatter: DateFormatter = {
        let dateDateFormatter = DateFormatter()
        dateDateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        dateDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return dateDateFormatter
    }()

    /// Uses representation of dates like "2017-01-01T12:00:00.123Z"
    ///
    /// This is not the officially intended format, but added after hearing reports about new format adding ms https://twitter.com/depth42/status/1314179654811607041
    ///
    /// The formatting String was taken from https://github.com/IdeasOnCanvas/AppReceiptValidator/pull/73
    /// where tests were performed to check if it works
    static let fallbackDateFormatterWithMS: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSS'Z'"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return dateFormatter
    }()
}
