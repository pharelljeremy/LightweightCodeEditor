import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var codeText = ""
    @State private var fileName = ""
    @State private var fileURL: URL? = nil
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isDarkMode = false
    @State private var showingSavePicker = false
    @State private var showingOpenPicker = false
    
    var textEditorBackground: Color {
        isDarkMode ? Color(white: 0.2) : Color(white: 0.95)
    }
    
    var textEditorForeground: Color {
        isDarkMode ? Color.white : Color.black
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                HStack {
                    Button(action: {
                        isDarkMode.toggle()
                    }) {
                        Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .foregroundColor(isDarkMode ? .yellow : .orange)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        codeText = ""
                        fileURL = nil
                        fileName = ""
                    }) {
                        Image(systemName: "trash")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 25, height: 25)
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal)
                
                ZStack(alignment: .leading) {
                    if fileName.isEmpty {
                        Text("Enter filename (any extension)")
                            .padding(8)
                            .foregroundColor(isDarkMode ? .gray : .gray)
                    }
                    TextField("", text: $fileName)
                        .padding(8)
                        .background(isDarkMode ? Color(white: 0.2) : Color(white: 0.95))
                        .cornerRadius(8)
                        .foregroundColor(isDarkMode ? .white : .black)
                }
                .padding(.horizontal)
                
                TextEditor(text: $codeText)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 300)
                    .scrollContentBackground(.hidden)
                    .background(textEditorBackground)
                    .foregroundColor(textEditorForeground)
                    .cornerRadius(8)
                    .padding(.horizontal)
                
                HStack {
                    Button(action: {
                        showingOpenPicker = true
                    }) {
                        HStack {
                            Image(systemName: "folder")
                            Text("Open File")
                        }
                        .foregroundColor(.white)
                        .frame(width: 140, height: 44)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                    
                    Button(action: saveFile) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Save")
                        }
                        .foregroundColor(.white)
                        .frame(width: 140, height: 44)
                        .background(Color.green)
                        .cornerRadius(8)
                    }
                }
            }
            .padding()
            .background(isDarkMode ? Color(white: 0.1) : Color.white)
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Message"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(isPresented: $showingSavePicker) {
                DocumentPicker(codeText: codeText, fileName: fileName) { success in
                    if success {
                        alertMessage = "File saved successfully!"
                        showingAlert = true
                    }
                }
            }
            .sheet(isPresented: $showingOpenPicker) {
                OpenFilePicker { text, name, url in
                    if let text = text {
                        codeText = text
                        fileName = name
                        fileURL = url
                    } else {
                        alertMessage = "Failed to open file"
                        showingAlert = true
                    }
                }
            }
        }
    }
    
    private func saveFile() {
        if let url = fileURL {
            do {
                try codeText.write(to: url, atomically: true, encoding: .utf8)
                alertMessage = "File saved successfully!"
            } catch {
                alertMessage = "Failed to save file: \(error.localizedDescription)"
            }
            showingAlert = true
        } else {
            guard !fileName.isEmpty else {
                alertMessage = "Please enter a filename"
                showingAlert = true
                return
            }
            
            guard !codeText.isEmpty else {
                alertMessage = "Please enter some text"
                showingAlert = true
                return
            }
            
            showingSavePicker = true
        }
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    let codeText: String
    let fileName: String
    let completion: (Bool) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let tempDir = FileManager.default.temporaryDirectory
        let tempFileURL = tempDir.appendingPathComponent(fileName)
        
        do {
            try codeText.write(to: tempFileURL, atomically: true, encoding: .utf8)
        } catch {
            print("Error creating temporary file: \(error.localizedDescription)")
            completion(false)
        }
        
        let picker = UIDocumentPickerViewController(forExporting: [tempFileURL])
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let completion: (Bool) -> Void
        
        init(completion: @escaping (Bool) -> Void) {
            self.completion = completion
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            completion(true)
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            completion(false)
        }
    }
}

struct OpenFilePicker: UIViewControllerRepresentable {
    let completion: (String?, String, URL?) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [
            UTType.plainText,
            UTType.pythonScript,
            UTType.sourceCode
        ])
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let completion: (String?, String, URL?) -> Void
        
        init(completion: @escaping (String?, String, URL?) -> Void) {
            self.completion = completion
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else {
                print("No URL selected")
                completion(nil, "", nil)
                return
            }
            
            // Start accessing the security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                print("Failed to access security scoped resource")
                completion(nil, "", nil)
                return
            }
            
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            
            do {
                let text = try String(contentsOf: url, encoding: .utf8)
                completion(text, url.lastPathComponent, url)
            } catch {
                print("Error reading file: \(error.localizedDescription)")
                completion(nil, "", nil)
            }
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            completion(nil, "", nil)
        }
    }
}

#Preview {
    ContentView()
}
