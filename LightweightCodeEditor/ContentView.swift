import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var codeText = ""
    @State private var fileName = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isDarkMode = false
    @State private var showingSavePicker = false

    var textEditorBackground: Color {
        isDarkMode ? Color(white: 0.2) : Color(white: 0.95)
    }

    var textEditorForeground: Color {
        isDarkMode ? Color.white : Color.black
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Button(action: {
                    isDarkMode.toggle()
                }) {
                    Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundColor(isDarkMode ? .yellow : .orange)
                }
                .padding(.horizontal)

                ZStack(alignment: .leading) {
                    if fileName.isEmpty {
                        Text("Enter filename (any extension)")
                            .padding(8)
                            .foregroundColor(isDarkMode ? .black : .gray)
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

                Button(action: prepareForSave) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Save")
                    }
                    .foregroundColor(.white)
                    .frame(width: 200, height: 44)
                    .background(Color.green)
                    .cornerRadius(8)
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
        }
    }

    private func prepareForSave() {
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
            print("Error creating temporary file: \(error)")
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

#Preview {
    ContentView()
}
