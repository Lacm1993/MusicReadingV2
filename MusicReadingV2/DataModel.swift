//
//  DataModel.swift
//  MusicReading
//
//  Created by Luis Alfonso Contreras Maya on 23/09/22.
//

import Foundation
import SwiftUI

//ENUMS
enum NoteName : String, CaseIterable, Identifiable, Equatable, Comparable, Hashable, Codable{
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
    case doubleWholeNote = 2
    case dottedWholeNote = 1.5
    case wholeNote = 1
    case dottedHalfNote = 0.75
    case halfNote = 0.5
    case dotterQuarterNote = 0.375
    case quarterNote = 0.25
    case dottedEightNote = 0.1875
    case eightNote = 0.125
    case dottedSixteenthNote = 0.09375
    case sixteenthNote = 0.0625
    case dottedThirtySecondNote = 0.046875
    case thirtySecondNote = 0.03125
    case dottedSixtyFourNote = 0.0234385
    case sixtyFourNote = 0.015625
    case oneHundredTwentyEightNote = 0.0078125
    var id: Self{
        self
    }
    //THESE IS PLANNING AHEAD TO A FUTURE VERSION OF THE APP THAT INCLUDES WRITTING, RIGHT NOW THIS WHOLE ENUM IS KINDA POINTLESS.
    
    //The operators work by adding the raw value of two NoteDuration instances and returning an optional NoteDuration (because not every possible note is accounted for)
    
    //The idea would be to limit the writting to a single measure and the operators would be used mainly to check when the measure is full or (if you are lacking notes or remove notes) to check which types of notes could fill the remaining space.
    
    //Ties would be handled differently, maybe with new properties to the note object (for example, one note has isFirstTied set to true, and the other has isLastTied set to true) and draw the line between those notes, or maybe if your last noteDuration goes beyond the limit of the measure allow it to "leak out" to the next one (broke the note in two the value that still fits the measure remains and the remainder moves into a new note), in the end maybe the combination of the two is what will work.
    
    //I will also need a measure object(maybe another enum) that has whats the maximum note value allowed (for example 4/4 = 1) to check when the measure is full and avoid going overboard
    
    static func +(lhs: NoteDuration, rhs: NoteDuration)-> NoteDuration?{
        return NoteDuration(rawValue: lhs.rawValue + rhs.rawValue)
    }
    static func -(lhs: NoteDuration, rhs: NoteDuration)-> NoteDuration?{
        return NoteDuration(rawValue: lhs.rawValue - rhs.rawValue)
    }
}


extension Array where Iterator.Element == Int{
    static func *(lhs: [Element], rhs: [Element])-> [Element]{
        let shortestSide = lhs.count <= rhs.count ? lhs : rhs
        let largestSide = lhs.count > rhs.count ? lhs : rhs
        var newArray = [Element]()
        for i in 0..<shortestSide.count{
            newArray.append(shortestSide[i] * largestSide[i])
        }
        return newArray
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
enum Clef: Hashable, Codable, Identifiable, CaseIterable{
    static var allCases: [Clef]{
        [.G, .F, .C(atLine: 1), .C(atLine: 2), .C(atLine: 3), .C(atLine: 4)]
    }
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
enum NextLevelUnlocked{
    case True
    case False
    case Done
    case None
    case NotApplicable
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
        return "\(name.rawValue)\(accidental.rawValue)\(register), duration:\(duration.rawValue), clef: \(clef.stringValue()), MIDI value: \(MIDINoteNumber)"
    }
    fileprivate(set) var name: NoteName
    @RegisterControl fileprivate(set) var register: Int
    fileprivate(set) var duration : NoteDuration
    fileprivate(set) var accidental: NoteAccidental
    fileprivate(set) var clef: Clef
    fileprivate(set) var MIDINoteNumber : Int
    func simpleLabel()-> String{
        "\(self.name.rawValue)\(self.register)"
    }
}
extension Note : CustomStringConvertible{
    var description: String{
        return "name: \(self.name)\(accidental.rawValue)\(self.register), duration: \(self.duration), in clef: \(self.clef.stringValue()), midiValue: \(MIDINoteNumber)\n"
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
    
    var sequenceCount: Int
    var sequenceNoteCount: Int
    
    fileprivate(set) var notes: [Note]
    fileprivate(set) var id = UUID()
    @MaxScoreControl fileprivate(set) var maxScore: Int
    fileprivate(set) var numberOrTries: Int
    fileprivate(set) var percentagePerNote : [Note : ScorePerNote]
    fileprivate(set) var isFreeLevel: Bool
    fileprivate(set) var isEnabled: Bool
    fileprivate(set) var isDeletable: Bool
    fileprivate(set) var isSequence: Bool
    
    var isCompleted: Bool{
        guard !isFreeLevel else{
            return true
        }
        return maxScore >= Level.requiredScore
    }
    var uniqueNoteNames: [String]{
        let set = self.notes.reduce(into: Set<String>()){uniqueNames, note in
            uniqueNames.insert(note.name.rawValue)
        }
        guard set.count > 1 else{
            var array = [String]()
            self.notes.forEach{note in
                array.append(note.simpleLabel())
            }
            return array.sorted(by: <)
        }
        let array = set.noteOrderSorting()
        return array
    }
    var uniqueNoteCount: Int{
        uniqueNoteNames.count
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
    init(numberOfQuestions: Int = 100, timer: Int = 120, sequenceCount: Int = 5, sequenceNoteCount: Int = 5 ,numberOrTries: Int = 0, maxScore: Int = 0, isFreeLevel: Bool = false, isEnabled: Bool = false, isDeletable: Bool = false, isSequence: Bool = false, notes: [Note]) {
        self.numberOfQuestions = numberOfQuestions
        self.timer = timer
        self.sequenceCount = sequenceCount
        self.sequenceNoteCount = sequenceNoteCount
        self.numberOrTries = numberOrTries
        self.maxScore = maxScore
        self.isFreeLevel = isFreeLevel
        self.isEnabled = isEnabled
        self.isDeletable = isDeletable
        self.isSequence = isSequence
        self.notes = notes
        self.percentagePerNote = notes.reduce(into: [:]){dict, note in
            dict[note] = ScorePerNote(right: 0, wrong: 0)
        }
    }
    //PlaceHolder level
    init(){
        self.numberOfQuestions = 0
        self.timer = 0
        self.sequenceCount = 0
        self.sequenceNoteCount = 0
        self.notes = [Note(name: .C, register: 4, duration: .quarterNote, accidental: .None, clef: .G, MIDINoteNumber: 60)]
        self.id = UUID()
        self.maxScore = 0
        self.numberOrTries = 0
        self.isFreeLevel = false
        self.isEnabled = true
        self.isDeletable = false
        self.isSequence = false
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
    
    var count: Int{
        levels.count
    }
    var firstMandatoryLevelID: UUID{
        self.levels[0].id
    }
    //If there are no free levels it returns a random UUID which might mess up with the scroll view reader, i dont know
    var firstCustomLevelID: UUID?{
        self.levels.first(where: {level in level.isFreeLevel})?.id
    }
    
    
    func level(withID id: UUID)-> Level{
        return levels.first{level in level.id == id } ?? Level()
    }
    func indexOfLevel(withID id: UUID)-> Int{
        levels.firstIndex{level in level.id == id} ?? -1
    }
    
    
    func updateLevelInfo(with newInfo: Level){
        if let index = levels.firstIndex(where: {level in level.id == newInfo.id}){
            levels[index] = newInfo
        }
    }
    func unlockNextLevel(fromLevelWithID id: UUID)-> NextLevelUnlocked{
        guard let index = levels.firstIndex(where: {level in level.id == id}) else{
            return .NotApplicable
        }
        guard levels[index].isCompleted else{
            return .False
        }

        guard index + 1 < count else{
            return .None
        }
        
        guard !levels[index + 1].isFreeLevel else{
            return .NotApplicable
        }
        guard !levels[index + 1].isEnabled else{
            return .Done
        }

        levels[index + 1].isEnabled = true
        return .True
    }
    func addLevel(withNumberOfQuestions numberOfQuestions: Int, timer: Int, notes: Array<Note>){
        var percentagePerNote = [Note : Level.ScorePerNote]()
        for note in notes{
            percentagePerNote[note] = Level.ScorePerNote(right: 0, wrong: 0)
        }
        let notesArray = notes.sorted()
        let level = Level(numberOfQuestions: numberOfQuestions, timer: timer, isFreeLevel: true, isEnabled: true, isDeletable: true, notes: notesArray)
        self.levels.append(level)
        self.saveData()
    }
    func addSequenceLevel(sequenceCount: Int, sequenceNoteCount: Int, sequenceTimer: Int, notes: Array<Note>){
        let level = Level(timer: sequenceTimer, sequenceCount: sequenceCount, sequenceNoteCount: sequenceNoteCount, isFreeLevel: true, isEnabled: true, isDeletable: true, isSequence:  true, notes: notes)
        self.levels.append(level)
        self.saveData()
    }
    
    func delete(level: Level){
        guard level.isDeletable else{
            return
        }
        let levelIndex = levels.firstIndex(of: level)!
        levels.remove(at: levelIndex)
        self.saveData()
    }
    func note(with name: NoteName, register: Int,and clef: Clef, getMIDINumberFrom midiInfo: MIDIInfo)-> Note{
        let octave = midiInfo.list.first{ $0.octave == register}!
        var midiNoteNumber = 0
        for i in octave.notes{
            if i.name == name.rawValue{
                midiNoteNumber = i.number
                break
            }
        }
        return Note(name: name, register: register, duration: .quarterNote, accidental: .None, clef: clef, MIDINoteNumber: midiNoteNumber)
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

    
    //Only for development, resets the game to the initial state
    func resetAll(){
        levels = [Level(isEnabled: true,
                        notes: [Note(name: .C, register: 4, duration: .quarterNote, accidental: .None, clef: .G, MIDINoteNumber: 60),
                                                   Note(name: .G, register: 4, duration: .quarterNote, accidental: .None, clef: .G, MIDINoteNumber: 67)
                                                  ]),
                  Level(
                        notes: [Note(name: .C, register: 4, duration: .quarterNote,             accidental: .None, clef: .G, MIDINoteNumber: 60),
                                Note(name: .G, register: 4, duration: .quarterNote, accidental: .None, clef: .G, MIDINoteNumber: 67),
                                Note(name: .C, register: 5, duration: .quarterNote, accidental: .None, clef: .G, MIDINoteNumber: 72),
                                Note(name: .G, register: 5, duration: .quarterNote, accidental: .None, clef: .G, MIDINoteNumber: 79)
                        ])
        ]
        saveData()
    }
    //Deletes maxScore, numberOfTries, and the scorePerNote for every level but it leaves everything else as is
    func resetGameHistory(){
        for i in 0..<levels.count{
            levels[i].maxScore = 0
            levels[i].numberOrTries = 0
            for note in levels[i].notes{
                levels[i].percentagePerNote[note] = Level.ScorePerNote(right: 0, wrong: 0)
            }
        }
        saveData()
    }
    init() {
        if let object : [Level] = FileManager.default.loadData(for: "Levels.json"){
            levels = object
            return
        }
        levels = [Level(isEnabled: true,
                        notes: [Note(name: .C, register: 4, duration: .quarterNote, accidental: .None, clef: .G, MIDINoteNumber: 60),
                                Note(name: .G, register: 4, duration: .quarterNote, accidental: .None, clef: .G, MIDINoteNumber: 67)
                        ]),
                  Level(isSequence: false,
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
//MIDI List
struct MIDINote: Codable{
    var name: String
    var number: Int
}
struct MIDIOctave: Codable{
    var octave: Int
    var notes: [MIDINote]
}
struct MIDIInfo{
    var list: [MIDIOctave]
    init(){
        if let url = Bundle.main.url(forResource: "MIDIData", withExtension: "json"){
            if let data = try? Data(contentsOf: url){
                if let object = try? JSONDecoder().decode([MIDIOctave].self, from: data){
                    list = object
                    return
                }
            }
        }
        list = []
    }
}


