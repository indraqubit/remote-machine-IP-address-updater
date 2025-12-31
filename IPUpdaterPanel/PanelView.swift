import SwiftUI

struct PanelView: View {
    @ObservedObject var viewModel: PanelViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("IP Updater Configuration")
                .font(.title2)
                .padding(.top)
            
            Form {
                Toggle("Enable Agent", isOn: $viewModel.enabled)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email Addresses")
                        .font(.headline)
                    Text("One email per line")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextEditor(text: $viewModel.emailsText)
                        .frame(height: 80)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    if let error = viewModel.emailError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Resend API Key")
                        .font(.headline)
                    SecureField("Enter API key", text: $viewModel.apiKey)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Label (Optional)")
                        .font(.headline)
                    TextField("", text: $viewModel.label)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes (Optional)")
                        .font(.headline)
                    TextEditor(text: $viewModel.notes)
                        .frame(height: 60)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
            }
            .padding()
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    viewModel.cancel()
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Test Email") {
                    viewModel.sendTestEmail()
                }
                .disabled(!viewModel.enabled || viewModel.emailsText.isEmpty || viewModel.apiKey.isEmpty)
                
                Button("Save") {
                    if viewModel.save() {
                        NSApplication.shared.terminate(nil)
                    }
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}

