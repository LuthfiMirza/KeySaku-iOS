import SwiftUI

/// Tampilan Registrasi Akun Baru KeySaku ke Server Laravel 12
public struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    private var authService = AuthService.shared
    
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var passwordConfirmation = ""
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 60))
                            .foregroundStyle(Color(hex: "#10B981"))
                        
                        Text("Daftar Akun KeySaku")
                            .font(.title2.weight(.bold))
                        
                        Text("Buat akun untuk sinkronisasi data keuangan keluarga ke server cloud.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    // Form Card
                    VStack(spacing: 16) {
                        if let error = authService.errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text(error)
                                    .font(.footnote)
                            }
                            .foregroundStyle(.red)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Nama Lengkap
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Nama Lengkap")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundStyle(.secondary)
                                TextField("contoh: Budi Santoso", text: $name)
                            }
                            .padding()
                            .background(Color(.tertiarySystemFill))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Email
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Alamat Email")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundStyle(.secondary)
                                TextField("nama@domain.com", text: $email)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                            }
                            .padding()
                            .background(Color(.tertiarySystemFill))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Password
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Kata Sandi")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundStyle(.secondary)
                                SecureField("Minimal 8 karakter", text: $password)
                            }
                            .padding()
                            .background(Color(.tertiarySystemFill))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Konfirmasi Password
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Konfirmasi Kata Sandi")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            HStack {
                                Image(systemName: "lock.shield.fill")
                                    .foregroundStyle(.secondary)
                                SecureField("Ulangi kata sandi", text: $passwordConfirmation)
                            }
                            .padding()
                            .background(Color(.tertiarySystemFill))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Tombol Submit
                        Button(action: handleRegister) {
                            HStack {
                                if authService.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Daftar Sekarang")
                                        .font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(isFormValid ? Color(hex: "#10B981") : Color.gray.opacity(0.4))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(!isFormValid || authService.isLoading)
                        .padding(.top, 8)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal)
                }
                .padding(.bottom, 30)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Tutup") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        password.count >= 6 &&
        password == passwordConfirmation
    }
    
    private func handleRegister() {
        Task {
            let success = await authService.register(
                name: name,
                email: email,
                password: password,
                passwordConfirmation: passwordConfirmation
            )
            if success {
                dismiss()
            }
        }
    }
}

#Preview {
    RegisterView()
}
