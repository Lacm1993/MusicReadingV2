//
//  StatisticsView.swift
//  MusicReading
//
//  Created by Luis Alfonso Contreras Maya on 28/09/22.
//

import SwiftUI
import Charts

struct StatisticsView: View {
    @Environment(\.dismiss) var dismiss
    let historyData: HistoryChartObjects
    let levelData: LevelChartObjects
    let numberOfRuns : Int
    let maxScore: Int
    let levelStatus : Bool
    let score : Int
    let theme: Theme
    let isNextLevelUnlocked: NextLevelUnlocked
    
    var levelScoreLabel: AttributedString{
        let str = "**Score per note this time**"
        if let s1 = try? AttributedString(markdown: str){
            return s1
        }else{
            return AttributedString(str)
        }
    }
    var globalScoreLabel : AttributedString{
        switch numberOfRuns{
        case 1:
            let str = "**Total score per note** (first time you've played)"
            let s1 = try? AttributedString(markdown: str)
            if let s1{
                return s1
            }else{
                return AttributedString(str)
            }
        default:
            let str = "**Total score per note** (You have played \(numberOfRuns) times)"
            let s1 = try? AttributedString(markdown: str)
            if let s1{
                return s1
            }else{
                return AttributedString(str)
            }
        }
    }
    var maxScoreInfo: AttributedString{
        let str = "**Current max score** (for all the times you have played) is **\(maxScore)** the required score to complete this level is **\(Level.requiredScore)**"
        if let s1 = try? AttributedString(markdown: str){
            return s1
        }else{
            return AttributedString(str)
        }
    }
    var levelCompleteInfo: AttributedString{
        var s1 = AttributedString("This level is \(levelStatus ? "complete": "incomplete.")")
        if let range = s1.range(of: "complete"){
            s1[range].foregroundColor = .green
        }
        if let range = s1.range(of: "incomplete"){
            s1[range].foregroundColor = .red
        }
        return s1
    }
    var nextLevelUnlockedInfo: AttributedString{
        var str = ""
        switch isNextLevelUnlocked{
        case .True:
            str += "You have unlocked the next level, go check it out!"
        case .False:
            str += "Try again to unlock the next level"
        case .None:
            str += "You have completed every level, congrats!"
        case .Done:
            str += ""
        case .NotApplicable:
            str += ""
        }
        var s1 = AttributedString(str)
        if isNextLevelUnlocked == .True{
            s1.foregroundColor = .green
        }else if isNextLevelUnlocked == .False{
            s1.foregroundColor = .red
        }else if isNextLevelUnlocked == .None{
            s1.foregroundColor = .yellow
        }
        return s1
    }
    
    var body: some View {
        NavigationStack{
            GeometryReader{geo in
                
                let outerVStackSpacing = geo.size.height * 0.05
                let chartFrame = CGSize(width: geo.size.width * 0.50, height: geo.size.width * 0.50)
                
                ScrollView(.vertical){
                    VStack(spacing: outerVStackSpacing){
                        VStack(spacing: 10){
                            Text(maxScoreInfo)
                            Text(levelCompleteInfo)
                            Text(nextLevelUnlockedInfo)
                        }
                        .padding()
                        Divider()
                        VStack(spacing: 30){
                            VStack{
                                Text(levelScoreLabel)
                                Chart{
                                    ForEach(levelData.objects){object in
                                        BarMark(x: .value("Name", object.note.simpleLabel()),
                                                y: .value("Count", object.count))
                                        .foregroundStyle(by: .value("Status", object.status.rawValue.uppercased()))
                                    }
                                }
                                .chartForegroundStyleScale(["RIGHT": Color.green, "WRONG": Color.red])
                                .frame(width: chartFrame.width, height: chartFrame.height)
                            }
                            Divider()
                            VStack{
                                Text(globalScoreLabel)
                                Chart{
                                    ForEach(historyData.objects, id: \.self){object in
                                        BarMark(x: .value("Name", object.note.simpleLabel()),
                                                y: .value("Count", object.count))
                                        .foregroundStyle(by: .value("Status", object.status.rawValue.uppercased()))
                                    }
                                }
                                .chartForegroundStyleScale(["RIGHT": Color.green, "WRONG": Color.red])
                                .frame(width: chartFrame.width, height: chartFrame.height)
                            }
                            Button("Go back to the game"){
                                dismiss()
                            }
                            .buttonStyle(BorderedButtonStyle())
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .navigationTitle("Statistics")
                .theme(preferedScheme: theme)
                .textAndSystemImagesColor(preferedScheme: theme)
                .customToolbarApperance()
            }
        }
    }
    init(level: Level, score: [Note: ScoreInstance.ScorePerNote], theme: Theme, isNextLevelUnlocked: NextLevelUnlocked){
        historyData = HistoryChartObjects(level: level)
        levelData = LevelChartObjects(score: score)
        numberOfRuns = level.numberOrTries + 1
        maxScore = level.maxScore
        levelStatus = level.isCompleted
        var getScore = 0
        for i in score.keys{
            getScore += score[i]!.right
        }
        self.score = getScore
        self.theme = theme
        self.isNextLevelUnlocked = isNextLevelUnlocked
    }
}
struct StatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        StatisticsView(level: Level(notes: []), score: [:], theme: .Dark, isNextLevelUnlocked: .False)
    }
}

