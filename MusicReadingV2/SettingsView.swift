//
//  SettingsView.swift
//  MusicReading
//
//  Created by Luis Alfonso Contreras Maya on 28/10/22.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var data: AppProgress
    @Environment(\.dismiss) var dismiss
    @Binding var inputMethod: InputMethod
    @Binding var theme: Theme
    var body: some View {
        NavigationStack{
            Form{
                Section{
                    Picker("Input method", selection: $inputMethod){
                        ForEach(InputMethod.allCases){input in
                            Text(input.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }header: {
                    Text("Input method")
                }
                Section{
                    Picker("Theme", selection: $theme){
                        ForEach(Theme.allCases){theme in
                            Text(theme.rawValue)
                        }
                    }
                }header: {
                    Text("Theme")
                }
                Section{
                    Button{
                        data.resetGameHistory()
                    }label: {
                        Text("Delete Game data")
                    }
                    Button{
                        data.resetAll()
                    }label:{
                        Text("Reset app to initial state")
                    }
                }header: {
                    Text("Development tools")
                }
            }
            .navigationTitle("Settings")
            .preferredColorScheme(theme == .Dark ? .dark : .light)
            .toolbar{
                ToolbarItem(placement: .navigationBarTrailing){
                    Button{
                        dismiss()
                    }label: {
                       Text("Done")
                    }
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(inputMethod: .constant(.Buttons), theme: .constant(.Dark))
    }
}

