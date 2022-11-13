//
//  MusicReadingV2App.swift
//  MusicReadingV2
//
//  Created by Luis Alfonso Contreras Maya on 09/11/22.
//

import SwiftUI

@main
struct MusicReadingV2App: App {
    @StateObject var midiManager = MIDIModule()
     var body: some Scene {
         WindowGroup {
             ContentView()
                 .environmentObject(midiManager)
         }
     }
}
