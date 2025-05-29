import SwiftUI
import StoreKit

struct PaywallView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProduct: Product?
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    PaywallHeader()
                    
                    // Features
                    FeaturesSection()
                    
                    // Subscription options
                    SubscriptionOptionsSection(
                        products: subscriptionManager.subscriptions,
                        selectedProduct: $selectedProduct
                    )
                    
                    // CTA Button
                    SubscribeButton(
                        selectedProduct: selectedProduct,
                        isProcessing: isProcessing,
                        onSubscribe: handleSubscription
                    )
                    
                    // Restore and terms
                    FooterSection(onRestore: handleRestore)
                }
                .padding()
            }
            .navigationTitle("Go Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .overlay {
                if subscriptionManager.isLoading {
                    LoadingOverlay()
                }
            }
        }
        .task {
            await subscriptionManager.loadProducts()
            if let firstProduct = subscriptionManager.subscriptions.first {
                selectedProduct = firstProduct
            }
        }
    }
    
    private func handleSubscription() {
        guard let product = selectedProduct else { return }
        
        Task {
            isProcessing = true
            defer { isProcessing = false }
            
            do {
                let transaction = try await subscriptionManager.purchase(product)
                if transaction != nil {
                    dismiss()
                }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    private func handleRestore() {
        Task {
            await subscriptionManager.restorePurchases()
            
            if subscriptionManager.subscriptionStatus.isActive {
                dismiss()
            } else {
                errorMessage = "No active subscriptions found"
                showError = true
            }
        }
    }
}

// MARK: - Paywall Header
struct PaywallHeader: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundStyle(.yellow.gradient)
            
            Text("Unlock Premium")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Get unlimited access to all features")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical)
    }
}

// MARK: - Features Section
struct FeaturesSection: View {
    let features = [
        Feature(icon: "calendar.badge.checkmark", title: "Unlimited Workouts", description: "Access all workouts and create custom routines"),
        Feature(icon: "figure.2.and.child.holdinghands", title: "Dad-Kid Challenges", description: "Special activities designed for fathers and children"),
        Feature(icon: "chart.line.uptrend.xyaxis", title: "Advanced Analytics", description: "Track your progress with detailed statistics"),
        Feature(icon: "bell.badge", title: "Smart Reminders", description: "AI-powered notifications at the perfect time"),
        Feature(icon: "infinity", title: "Unlimited Streaks", description: "Track all your fitness streaks simultaneously"),
        Feature(icon: "person.3.fill", title: "Family Sharing", description: "Share with up to 5 family members")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Premium Features")
                .font(.headline)
            
            ForEach(features) { feature in
                HStack(spacing: 16) {
                    Image(systemName: feature.icon)
                        .font(.title2)
                        .foregroundStyle(.blue)
                        .frame(width: 32)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(feature.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text(feature.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Subscription Options
struct SubscriptionOptionsSection: View {
    let products: [Product]
    @Binding var selectedProduct: Product?
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(products, id: \.id) { product in
                SubscriptionOption(
                    product: product,
                    isSelected: selectedProduct?.id == product.id,
                    onSelect: { selectedProduct = product }
                )
            }
        }
    }
}

// MARK: - Subscription Option
struct SubscriptionOption: View {
    let product: Product
    let isSelected: Bool
    let onSelect: () -> Void
    
    var savings: String? {
        guard product.id.contains("yearly") else { return nil }
        // Calculate savings compared to monthly
        return "Save 25%"
    }
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(product.displayName)
                            .font(.headline)
                        
                        if let savings = savings {
                            Text(savings)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(product.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if let trial = product.trialText {
                        Text(trial)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(product.displayPrice)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text("per \(product.periodText)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Subscribe Button
struct SubscribeButton: View {
    let selectedProduct: Product?
    let isProcessing: Bool
    let onSubscribe: () -> Void
    
    var body: some View {
        Button(action: onSubscribe) {
            HStack {
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text("Start Free Trial")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(selectedProduct != nil ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(selectedProduct == nil || isProcessing)
    }
}

// MARK: - Footer Section
struct FooterSection: View {
    let onRestore: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Button("Restore Purchases", action: onRestore)
                .font(.footnote)
                .foregroundColor(.blue)
            
            VStack(spacing: 4) {
                Text("Recurring billing. Cancel anytime.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 8) {
                    Button("Terms of Service") { }
                        .font(.caption)
                    
                    Text("•")
                        .foregroundStyle(.secondary)
                    
                    Button("Privacy Policy") { }
                        .font(.caption)
                }
            }
        }
    }
}

// MARK: - Loading Overlay
struct LoadingOverlay: View {
    var body: some View {
        Color.black.opacity(0.5)
            .ignoresSafeArea()
            .overlay(
                ProgressView("Loading...")
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 10)
            )
    }
}

// MARK: - Feature Model
struct Feature: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
}

// MARK: - Preview
#Preview {
    PaywallView()
} 