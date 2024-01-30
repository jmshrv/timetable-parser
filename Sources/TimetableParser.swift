// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import ArgumentParser
import SwiftSoup

struct TimetableEntry {
    let activity: String
    let moduleTitle: String?
    let sessionTitle: String
    let type: String
    let weeks: String
    let day: String
    let start: String
    let end: String
    let staff: String
    let location: String
    let notes: String?
}

enum TimetableParserError: LocalizedError {
    /// The parser found an activity row with an invalid count.
    ///
    /// - Parameter count: The actual number of items.
    case InvalidRowLength(Int)
}

@main
struct TimetableParser: ParsableCommand {
    @Argument(help: "The timetable, as a saved HTML file")
    var inputPath: String
    
    func getInputFromFile(path: String) throws -> String {
        let url = URL(filePath: path)
        return try String(contentsOf: url)
    }
    
    func parseInput(input: String) throws -> Document {
        return try SwiftSoup.parse(input)
    }
    
    /// Gets each day's `tbody` from the given document.
    ///
    /// - Returns: A list containing `tbody` elements for Monday-Friday. Will have 5 elements.
    func dayTables(_ doc: Document) throws -> [Element] {
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
            throw TimetableParserError.InvalidRowLength(rowDatas.size())
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
            activity: try activity.text(),
            moduleTitle: try moduleTitle.text(),
            sessionTitle: try sessionTitle.text(),
            type: try type.text(),
            weeks: try weeks.text(),
            day: try day.text(),
            start: try start.text(),
            end: try end.text(),
            staff: try staff.text(),
            location: try location.text(),
            notes: try notes.text()
        )
    }
    
    func activitiesFromDay(_ day: Element) throws -> [TimetableEntry] {
        let rows = try day.select("tr")
        
        return try rows.map(activityFromRow)
    }
    
    func run() throws {
        let input = try getInputFromFile(path: inputPath)
        let doc = try parseInput(input: input)
        
        let days = try dayTables(doc)
        
        let activities = try days.map(activitiesFromDay)
        
        print(activities)
    }
}
