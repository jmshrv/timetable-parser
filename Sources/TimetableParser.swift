import Foundation
import SwiftSoup

public enum Day: Codable, Hashable, Equatable, Identifiable {
    public var id: Int {
        switch self {
        case .monday:
            1
        case .tuesday:
            2
        case .wednesday:
            3
        case .thursday:
            4
        case .friday:
            5
        }
    }
    
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    
    public var weekdaySymbol: String {
        let calendar = Calendar(identifier: .gregorian)
        return calendar.weekdaySymbols[id]
    }
}

public struct HourMinute: Codable, Hashable, Equatable {
    public let hour: Int
    public let minute: Int
    
    public init(hour: Int, minute: Int) {
        self.hour = hour
        self.minute = minute
    }
}

public enum Week: Codable, Hashable, Equatable {
    /// A single week
    case single(Int)
    
    /// A range of weeks, in the format (`start`, `end`)
    case range(Int, Int)
    
    public func isWithin(_ week: Int) -> Bool {
        return switch self {
        case .single(let single):
            week == single
        case .range(let start, let end):
            (start...end).contains(week)
        }
    }
}

public struct TimetableEntry: Codable, Hashable, Equatable, Identifiable {
    public let id = UUID()
    
    public let activities: [String]
    public let moduleTitle: String?
    public let sessionTitle: String
    public let type: String
    public let weeks: [Week]
    public let day: Day
    public let start: HourMinute
    public let end: HourMinute
    public let staff: String
    public let location: String
    public let notes: String?
    
//    We don't want to serialise ID
    enum CodingKeys: CodingKey {
        case activities
        case moduleTitle
        case sessionTitle
        case type
        case weeks
        case day
        case start
        case end
        case staff
        case location
        case notes
    }
    
    public init(activities: [String], moduleTitle: String?, sessionTitle: String, type: String, weeks: [Week], day: Day, start: HourMinute, end: HourMinute, staff: String, location: String, notes: String?) {
        self.activities = activities
        self.moduleTitle = moduleTitle
        self.sessionTitle = sessionTitle
        self.type = type
        self.weeks = weeks
        self.day = day
        self.start = start
        self.end = end
        self.staff = staff
        self.location = location
        self.notes = notes
    }
}

enum TimetableParserError: LocalizedError {
    /// The parser found an activity row with an invalid count.
    ///
    /// - Parameter count: The actual number of items.
    case invalidRowLength(Int)
    
    case invalidActivityForwardSlashLength(Int)
    
    case invalidDay(String)
    
    /// When parsing a time, the parser found an unexpected number of splits, for example 00:00:00.
    ///
    /// - Parameter count: The actual number of splits.
    case timeIncorrectSplits(Int)
    
    /// When parsing a time, the parser found an invalid component that couldn't be converted to an integer. For example, "zero".
    ///
    /// - Parameter component: The component that could not be parsed
    case timeInvalidComponent(String)
    
    case weekInvalidSplitDate(String)
}

public struct TimetableParser {
//    func getInputFromFile(path: String) throws -> String {
//        let url = URL(filePath: path)
//        return try String(contentsOf: url)
//    }
    
    public func parseInput(input: String) throws -> Document {
        return try SwiftSoup.parse(input)
    }
    
    /// Gets each day's `tbody` from the given document.
    ///
    /// - Returns: A list containing `tbody` elements for Monday-Friday. Will have 5 elements.
    public func dayTables(_ doc: Document) throws -> [Element] {
        return [
            try doc.select("body > table:nth-child(3) > tbody:nth-child(2)").first()!,
            try doc.select("body > table:nth-child(5) > tbody:nth-child(2)").first()!,
            try doc.select("body > table:nth-child(7) > tbody:nth-child(2)").first()!,
            try doc.select("body > table:nth-child(9) > tbody:nth-child(2)").first()!,
            try doc.select("body > table:nth-child(11) > tbody:nth-child(2)").first()!,
        ]
    }
    
    func activityFromRow(_ row: Element) throws -> TimetableEntry {
        let rowDatas = try row.select("td")
        
        if rowDatas.size() != 11 {
            throw TimetableParserError.invalidRowLength(rowDatas.size())
        }
        
        let activity = rowDatas[0]
        let moduleTitle = rowDatas[1]
        let sessionTitle = rowDatas[2]
        let type = rowDatas[3]
        let weeks = rowDatas[4]
        let day = rowDatas[5]
        let start = rowDatas[6]
        let end = rowDatas[7]
        let staff = rowDatas[8]
        let location = rowDatas[9]
        let notes = rowDatas[10]
        
        return TimetableEntry(
            activities: try parseActivity(activity),
            moduleTitle: try parseNullable(moduleTitle),
            sessionTitle: try sessionTitle.text(),
            type: try type.text(),
            weeks: try parseWeeks(try weeks.text()),
            day: try parseDay(day),
            start: try parseTime(try start.text()),
            end: try parseTime(try end.text()),
            staff: try staff.text(),
            location: try location.text(),
            notes: try parseNullable(notes)
        )
    }
    
    public func activitiesFromDay(_ day: Element) throws -> [TimetableEntry] {
        let rows = try day.select("tr")
        
        return try rows.dropFirst().map(activityFromRow)
    }
    
    /// Parses the timetable's activity text into module codes. For example:
    ///
    /// `COMP/3007/01/L/01/01,COMP/4106/01/L/01/01_JT` becomes `["COMP3007", "COMP4106"]`
    func parseActivity(_ element: Element) throws -> [String] {
        var text = try element.text()
        
//        Some modules have extra stuff like <22> which we don't care about
        if let splitText = text.split(separator: "<").first {
            text = String(splitText)
        }
        
        return try text.split(separator: ",").map {
            let split = $0.split(separator: "/").prefix(2)
            
            guard split.count >= 2 else {
                print(text)
                print($0)
                throw TimetableParserError.invalidActivityForwardSlashLength(split.count)
            }
            
            return split.prefix(2).joined()
        }
    }
    
    func parseDay(_ element: Element) throws -> Day {
        return switch try element.text() {
        case "Monday":
                .monday
        case "Tuesday":
                .tuesday
        case "Wednesday":
                .wednesday
        case "Thursday":
                .thursday
        case "Friday":
                .friday
        default:
            throw TimetableParserError.invalidDay(try element.text())
        }
    }
    
    /// Parses a "nullable" field. In the timetable HTML, some fields have an empty space when there is no info.
    func parseNullable(_ element: Element) throws -> String? {
        let text = try element.text()
        
//        Yes, the timetabling document specifically uses non-breaking spaces
        if text == "\u{00A0}" {
            return nil
        }
        
        return text
    }
    
    func parseTime(_ timeString: String) throws -> HourMinute {
        let split = timeString.split(separator: ":")
        
        guard split.count == 2 else {
            throw TimetableParserError.timeIncorrectSplits(split.count)
        }
        
        guard let hour = Int(split[0]) else {
            throw TimetableParserError.timeInvalidComponent(String(split[0]))
        }
        
        guard let minute = Int(split[1]) else {
            throw TimetableParserError.timeInvalidComponent(String(split[1]))
        }
        
        return HourMinute(hour: hour, minute: minute)
    }
    
    func parseWeeks(_ weeksString: String) throws -> [Week] {
        return try weeksString
            .split(separator: ",")
            .map { week in
                let weekString = week.trimmingCharacters(in: .whitespaces)
                
                if let singleWeek = Int(weekString) {
                    return .single(singleWeek)
                } else {
                    let split = weekString.split(separator: "-")
                    
                    guard split.count == 2 else {
                        throw TimetableParserError.weekInvalidSplitDate(weekString)
                    }
                    
                    let start = Int(split[0])
                    let end = Int(split[1])

                    guard let start = start, let end = end else {
                        throw TimetableParserError.weekInvalidSplitDate(weeksString)
                    }

                    
                    return .range(start, end)
                }
            }
    }
}
