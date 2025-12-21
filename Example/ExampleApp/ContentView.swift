import SwiftUI
import X04Checker

struct ContentView: View {
    @State private var monkey = false
    @State private var showAlert = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Monkey status:")
                .font(.headline)

            Text(monkey ? "🐒 Monkey!" : "✅ Clean")
                .font(.title)
                .foregroundColor(monkey ? .red : .green)
        }
        .padding()
        .onAppear {
            monkey = UIDevice.current.x04
            showAlert = monkey
        }
        .alert("Warning", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your device appears to have a monkey. Certain features may be disabled.")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
