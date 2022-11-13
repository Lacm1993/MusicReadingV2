//
//  DataModel.swift
//  MusicReading
//
//  Created by Luis Alfonso Contreras Maya on 23/09/22.
//

import Foundation
import SwiftUI

//ENUMS
enum NoteName : String, Identifiable, Equatable, Comparable, Hashable, Codable{
    static func < (lhs: NoteName, rhs: NoteName) -> Bool {
        let order = Array("CDEFGAB")
        return order.firstIndex(of: Character(lhs.rawValue))! < order.firstIndex(of: Character(rhs.rawValue))!
    }
    case C
    case D
    case E
    case F
    case G
    case A
    case B
    var id: Self{
        self
    }
}
enum NoteDuration : Double, Identifiable, Equatable, Comparable, Hashable, Codable{
    static func < (lhs: NoteDuration, rhs: NoteDuration) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    case wholeNote = 1
    case halfNote = 0.5
    case quarterNote = 0.25
    case eightNote = 0.125
    case sixteenthNote = 0.0625
    case thirtySecondNote = 0.03125
    case sixtyFourNote = 0.015625
    var id: Self{
        self
    }
}
enum NoteAccidental : String, Identifiable, Equatable, Comparable, Hashable, Codable{
    static func < (lhs: NoteAccidental, rhs: NoteAccidental) -> Bool {
        switch (lhs, rhs){
        case (Natural, Sharp), (Flat, Natural), (None, Sharp), (Flat, None), (Flat, Sharp):
            return true
        default:
            return false
        }
    }
    case Sharp = "♯"
    case Flat = "♭"
    case Natural = "♮"
    case None = ""
    var id: Self{
        self
    }
}
enum Clef: Hashable, Codable, Identifiable{
    case G
    case F
    case C(atLine: Int)
    var id: Self{
        self
    }
    func stringValue()-> String{
        switch self {
        case .G:
            return "G"
        case .F:
            return "F"
        case .C(let line):
            return "C at line:\(line)"
        }
    }
}
enum AnswerStatus: String, Identifiable{
    case Right
    case Wrong
    var id: Self{
        self
    }
}
enum InputMethod: String, Identifiable, CaseIterable{
    case Buttons
    case MIDI
    case Audio
    var id: Self{
        self
    }
}
enum Theme: String, CaseIterable, Identifiable{
    case Light
    case Dark
    var id: Self{
        self
    }
}


//PROPERTYWRAPPERS
@propertyWrapper
struct RegisterControl : Hashable, Codable{
    var register: Int
    var wrappedValue: Int{
        get{
            register
        }
        set{
            if newValue > 8{
                register = 8
            }else if newValue < 0{
                register = 0
            }else{
                register = newValue
            }
        }
    }
    init(wrappedValue: Int) {
        register = wrappedValue
    }
}
@propertyWrapper
struct MaxScoreControl: Hashable, Codable{
    var maxScore: Int
    var wrappedValue: Int{
        get{
            maxScore
        }
        set{
            maxScore = max(maxScore, newValue)
        }
    }
    init(wrappedValue: Int) {
        maxScore = wrappedValue
    }
}


//STRUCTS
struct Note: Identifiable, Equatable, Comparable, Hashable, Codable{
    static func < (lhs: Note, rhs: Note) -> Bool {
        if lhs.register == rhs.register{
            if lhs.name == rhs.name{
                return lhs.accidental < rhs.accidental
            }
            return lhs.name < rhs.name
        }
        return lhs.register < rhs.register
    }
    static func == (lhs: Note, rhs: Note) -> Bool {
        return lhs.MIDINoteNumber == rhs.MIDINoteNumber
    }
    var id: String{
        return "\(name.rawValue)\(accidental.rawValue)\(register), duration:\(duration.rawValue), clef: \(clef.stringValue())"
    }
    fileprivate(set) var name: NoteName
    @RegisterControl fileprivate(set) var register: Int
    fileprivate(set) var duration : NoteDuration
    fileprivate(set) var accidental: NoteAccidental
    fileprivate(set) var clef: Clef
    fileprivate(set) var MIDINoteNumber : Int
    func chartLabel()-> String{
        "\(self.name.rawValue) \(self.register)"
    }
}
extension Note : CustomStringConvertible{
    var description: String{
        return "name: \(self.name)\(accidental.rawValue)\(self.register), duration: \(self.duration), in clef: \(self.clef.stringValue())\n"
    }
}
struct Level: Identifiable, Codable, Hashable{
    static let requiredScore = 90
    struct ScorePerNote: Codable, Hashable{
        var right: Int
        var wrong: Int
    }
    var numberOfQuestions: Int
    var timer: Int
    fileprivate(set) var notes: [Note]
    fileprivate(set) var id: Int
    @MaxScoreControl fileprivate(set) var maxScore: Int
    fileprivate(set) var numberOrTries: Int
    fileprivate(set) var percentagePerNote : [Note : ScorePerNote]
    fileprivate(set) var freeLevel: Bool
    var isCompleted: Bool{
        guard !freeLevel else{
            return true
        }
        return maxScore >= Level.requiredScore
    }
    var uniqueNoteNames: [NoteName]{
        let set = self.notes.reduce(into: Set<NoteName>()){uniqueNames, note in
            uniqueNames.insert(note.name)
        }
        let array = set.sorted{first, second in
            first < second
        }
        return array
    }
    var noteCount: Int{
        notes.count
    }
    mutating func updateStatistics(for note: Note, status: AnswerStatus){
        switch status{
        case .Right:
            self.percentagePerNote[note]!.right += 1
        case .Wrong:
            self.percentagePerNote[note]!.wrong += 1
        }
    }
    mutating func updateMaxScoreAndNumberOfTries(with newScore: Int){
        maxScore = newScore
        numberOrTries += 1
    }
    func note(at index: Int)-> Note?{
        guard index >= 0 && index < noteCount else{
            return nil
        }
        return self.notes[index]
    }
    fileprivate func score(for note: Note, status: AnswerStatus)-> Int{
        switch status {
        case .Right:
            return self.percentagePerNote[note]?.right ?? 0
        case .Wrong:
            return self.percentagePerNote[note]?.wrong ?? 0
        }
    }
    init(numberOfQuestions: Int, timer: Int, id: Int, numberOrTries: Int, maxScore: Int = 0, notes: [Note], freeLevel: Bool = false) {
        self.numberOfQuestions = numberOfQuestions
        self.timer = timer
        self.notes = notes
        self.id = id
        self.maxScore = maxScore
        self.numberOrTries = numberOrTries
        self.freeLevel = freeLevel
        self.percentagePerNote = notes.reduce(into: [:]){dict, note in
            dict[note] = ScorePerNote(right: 0, wrong: 0)
        }
    }
    //PlaceHolder level
    init(){
        self.numberOfQuestions = 0
        self.timer = 120
        self.notes = [Note(name: .C, register: 4, duration: .quarterNote, accidental: .None, clef: .G, MIDINoteNumber: 60)]
        self.id = 0
        self.maxScore = 0
        self.numberOrTries = 0
        self.freeLevel = false
        self.percentagePerNote = [Note(name: .C, register: 4, duration: .quarterNote, accidental: .None, clef: .G, MIDINoteNumber: 60):  ScorePerNote(right: 0, wrong: 0)]
    }
}
struct HistoryChartObject: Identifiable, Hashable{
    var count: Int
    var status: AnswerStatus
    var note: Note
    var id: Self{
        self
    }
}
struct HistoryChartObjects{
    var objects: [HistoryChartObject]
    init(level: Level){
        var objects = [HistoryChartObject]()
        for note in level.notes{
            let rightData = HistoryChartObject(count: level.score(for: note, status: .Right), status: .Right, note: note)
            let wrongData = HistoryChartObject(count: level.score(for: note, status: .Wrong), status: .Wrong, note: note)
            objects.append(rightData)
            objects.append(wrongData)
        }
        self.objects = objects
    }
}
struct LevelChartObject: Identifiable, Hashable{
    var id: Self{
        self
    }
    var count: Int
    var status: AnswerStatus
    var note: Note
}
struct LevelChartObjects{
    var objects: [LevelChartObject]
    init(score: [Note: ScoreInstance.ScorePerNote]){
        var objects = [LevelChartObject]()
        for i in score.keys{
            let rightAnswers = LevelChartObject(count: score[i]!.right, status: .Right, note: i)
            let wrongAnswers = LevelChartObject(count: score[i]!.wrong, status: .Wrong, note: i)
            objects.append(rightAnswers)
            objects.append(wrongAnswers)
        }
        self.objects = objects
    }
}
struct ScoreInstance{
    struct ScorePerNote{
        var right = 0
        var wrong = 0
    }
    var scorePerNote: [Note : ScorePerNote]
    init(){
        scorePerNote = [:]
    }
}
//This objects will be the data of the tutorials that will show up at the beginning of every level
struct TutorialContent{
}
struct Tutorial{
}
struct TutorialCard{
}


//CLASS
class AppProgress: ObservableObject{
    static let completedLevelsKey = "CompletedLevels"
    static let enabledLevelsKey = "EnabledLevels"
    @Published var levels: [Level]
    @AppStorage(AppProgress.completedLevelsKey) var completedLevels = 0
    @AppStorage(AppProgress.enabledLevelsKey) var enabledLevels = 1
    func level(withID id: Int)-> Level{
        return levels.first{level in level.id == id} ?? Level(numberOfQuestions: 0, timer: 120, id: -1, numberOrTries: 0, notes: [Note(name: .C, register: 4, duration: .quarterNote, accidental: .None, clef: .G, MIDINoteNumber: 60)])
    }
    func saveData(){
        if let data = try? JSONEncoder().encode(levels){
            let url = FileManager.default.getDocumentDirectory().appendingPathComponent("Levels.json")
            do{
                try data.write(to: url)
            }catch{
                print("Failed to write to the documents directory")
            }
        }
    }
    func updateLevelInfo(with newInfo: Level){
        if let index = levels.firstIndex(where: {level in level.id == newInfo.id}){
            levels[index] = newInfo
        }
    }
    
    //This function will create custom levels and optionally add them to the array of levels
    func createLevel(){}
    
    init() {
        if let object : [Level] = FileManager.default.loadData(for: "Levels.json"){
            levels = object
            return
        }
        levels = [Level(numberOfQuestions: 100, timer: 120,
                        id: 1,
                        numberOrTries: 0,
                        notes: [Note(name: .C, register: 4, duration: .quarterNote, accidental: .None, clef: .G, MIDINoteNumber: 60),
                                Note(name: .G, register: 4, duration: .quarterNote, accidental: .None, clef: .G, MIDINoteNumber: 67)
                        ]),
                  Level(numberOfQuestions: 100, timer: 120,
                        id: 2,
                        numberOrTries: 0,
                        notes: [Note(name: .C, register: 4, duration: .quarterNote,             accidental: .None, clef: .G, MIDINoteNumber: 60),
                                Note(name: .G, register: 4, duration: .quarterNote, accidental: .None, clef: .G, MIDINoteNumber: 67),
                                Note(name: .C, register: 5, duration: .quarterNote, accidental: .None, clef: .G, MIDINoteNumber: 72),
                                Note(name: .G, register: 5, duration: .quarterNote, accidental: .None, clef: .G, MIDINoteNumber: 79)
                        ])
        ]
    }
}
class NavigationHistory: ObservableObject{
    static let key = "Stack"
    @Published var stack: [Level]
    func saveStackHistory(){
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(stack){
            UserDefaults.standard.set(data, forKey: NavigationHistory.key)
        }
    }
    init(){
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.data(forKey: NavigationHistory.key){
            if let object = try? decoder.decode([Level].self, from: data){
                stack = object
                return
            }
        }
        stack = []
    }
}


//EXTENSIONS
extension FileManager{
    fileprivate func getDocumentDirectory()-> URL{
        let paths = self.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    fileprivate func loadData<T: Codable>(for component: String)-> [T]?{
        let directory = getDocumentDirectory().appendingPathComponent(component)
        if let data = try? Data(contentsOf: directory){
            if let object = try? JSONDecoder().decode([T].self, from: data){
                return object
            }
        }
        return nil
    }
}
