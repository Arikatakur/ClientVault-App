import SwiftUI

struct AddEditVaultItemView: View {
    enum Mode {
        case add
        case edit(VaultItem)
    }

    let mode: Mode
    let vm: VaultViewModel

    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var type: VaultItemType = .password
    @State private var secret = ""
    @State private var username = ""
    @State private var url = ""
    @State private var notes = ""
    // TOTP-specific
    @State private var totpIssuer = ""
    @State private var totpAccount = ""
    @State private var showOTPAuthImport = false
    @State private var otpauthURL = ""
    // Password generator
    @State private var showGeneratorOptions = false
    @State private var generatorLength: Double = 20
    @State private var generatorUppercase = true
    @State private var generatorNumbers = true
    @State private var generatorSymbols = true

    @State private var isSaving = false
    @State private var errorMessage: String?

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !secret.isEmpty &&
        !isSaving
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    TextField("Title", text: $title)
                        .listRowBackground(Palette.surfaceElevated)

                    Picker("Type", selection: $type) {
                        ForEach(VaultItemType.allCases) { t in
                            Text(t.displayName).tag(t)
                        }
                    }
                    .listRowBackground(Palette.surfaceElevated)
                }

                if type == .totp {
                    totpSection
                } else {
                    secretSection
                }

                if type == .password || type == .apiKey {
                    Section("Details") {
                        if type == .password {
                            TextField("Username", text: $username)
                                .textInputAutocapitalization(.never)
                                .listRowBackground(Palette.surfaceElevated)
                        }
                        TextField("URL", text: $url)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)
                            .listRowBackground(Palette.surfaceElevated)
                    }
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                        .listRowBackground(Palette.surfaceElevated)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(Typography.footnote())
                            .foregroundStyle(Palette.danger)
                            .listRowBackground(Palette.surfaceElevated)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Palette.background)
            .navigationTitle(isEditing ? "Edit Item" : "New Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView().tint(Palette.vault)
                    } else {
                        Button("Save") { Task { await save() } }
                            .disabled(!canSave)
                    }
                }
            }
            .sheet(isPresented: $showOTPAuthImport) {
                otpauthImportSheet
            }
        }
        .onAppear { populateIfEditing() }
    }

    // MARK: - Secret section (non-TOTP)

    private var secretSection: some View {
        Section {
            SecureField(secretLabel, text: $secret)
                .textContentType(isEditing ? .password : .newPassword)
                .listRowBackground(Palette.surfaceElevated)

            if type == .password {
                generatorRow
            }
        } header: {
            Text("Secret")
        }
    }

    // MARK: - TOTP section

    private var totpSection: some View {
        Section {
            SecureField("Seed (base32)", text: $secret)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .listRowBackground(Palette.surfaceElevated)

            TextField("Issuer (e.g. GitHub)", text: $totpIssuer)
                .listRowBackground(Palette.surfaceElevated)

            TextField("Account (e.g. user@example.com)", text: $totpAccount)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .listRowBackground(Palette.surfaceElevated)

            Button {
                showOTPAuthImport = true
            } label: {
                Label("Import from otpauth:// URL", systemImage: "qrcode.viewfinder")
                    .font(Typography.subheadline())
                    .foregroundStyle(Palette.vault)
            }
            .listRowBackground(Palette.surfaceElevated)
        } header: {
            Text("TOTP Seed")
        } footer: {
            Text("The seed is encrypted on-device. Codes are generated locally and never synced.")
                .font(Typography.footnote())
        }
    }

    // MARK: - Password generator row

    private var generatorRow: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Button {
                withAnimation { showGeneratorOptions.toggle() }
            } label: {
                Label(
                    showGeneratorOptions ? "Hide generator" : "Generate password",
                    systemImage: "wand.and.sparkles"
                )
                .font(Typography.subheadline())
                .foregroundStyle(Palette.vault)
            }
            .buttonStyle(.plain)

            if showGeneratorOptions {
                Divider()
                VStack(spacing: Spacing.sm) {
                    HStack {
                        Text("Length: \(Int(generatorLength))")
                            .font(Typography.caption())
                            .foregroundStyle(Palette.textSecondary)
                        Spacer()
                    }
                    Slider(value: $generatorLength, in: 8...64, step: 1)
                        .tint(Palette.vault)

                    Toggle("Uppercase (A–Z)", isOn: $generatorUppercase)
                        .font(Typography.subheadline())
                        .tint(Palette.vault)
                    Toggle("Numbers (0–9)", isOn: $generatorNumbers)
                        .font(Typography.subheadline())
                        .tint(Palette.vault)
                    Toggle("Symbols (!@#…)", isOn: $generatorSymbols)
                        .font(Typography.subheadline())
                        .tint(Palette.vault)

                    let strength = PasswordGenerator.strength(of: secret)
                    if !secret.isEmpty {
                        strengthBar(strength)
                    }

                    Button {
                        let opts = PasswordGenerator.Options(
                            length: Int(generatorLength),
                            includeUppercase: generatorUppercase,
                            includeLowercase: true,
                            includeNumbers: generatorNumbers,
                            includeSymbols: generatorSymbols
                        )
                        secret = PasswordGenerator.generate(options: opts)
                        Haptics.shared.impact(.light)
                    } label: {
                        Text("Generate")
                            .font(Typography.subheadline().weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.sm)
                            .background(Palette.vault, in: RoundedRectangle(cornerRadius: Radius.sm))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .listRowBackground(Palette.surfaceElevated)
    }

    private func strengthBar(_ strength: PasswordGenerator.Strength) -> some View {
        HStack(spacing: Spacing.xs) {
            Text("Strength:")
                .font(Typography.caption())
                .foregroundStyle(Palette.textSecondary)
            Text(strength.label)
                .font(Typography.caption().weight(.semibold))
                .foregroundStyle(strength.color)
            Spacer()
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Palette.surface)
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(strength.color)
                        .frame(width: geo.size.width * strength.fraction, height: 4)
                        .animation(.easeInOut, value: strength.fraction)
                }
            }
            .frame(width: 80, height: 4)
        }
    }

    // MARK: - OTPAuth import sheet

    private var otpauthImportSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text("Paste an otpauth:// URL from your authenticator app or QR code scanner.")
                    .font(Typography.subheadline())
                    .foregroundStyle(Palette.textSecondary)

                TextField("otpauth://totp/...", text: $otpauthURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(Typography.mono())
                    .padding(Spacing.md)
                    .background(Palette.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.md))

                Button {
                    if let parsed = TOTPGenerator.parseOTPAuthURL(otpauthURL) {
                        secret = parsed.seed
                        if let issuer = parsed.issuer { totpIssuer = issuer }
                        if let account = parsed.account { totpAccount = account }
                        if title.isEmpty { title = parsed.issuer ?? parsed.account ?? "" }
                        Haptics.shared.success()
                        showOTPAuthImport = false
                    } else {
                        Haptics.shared.error()
                    }
                } label: {
                    Text("Import")
                        .font(Typography.body().weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(Palette.vault, in: RoundedRectangle(cornerRadius: Radius.md))
                }
                .disabled(otpauthURL.isEmpty)

                Spacer()
            }
            .padding(Spacing.lg)
            .background(Palette.background)
            .navigationTitle("Import OTPAuth URL")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showOTPAuthImport = false }
                }
            }
        }
    }

    // MARK: - Helpers

    private var secretLabel: String {
        switch type {
        case .password:   return "Password"
        case .apiKey:     return "API Key"
        case .secureNote: return "Note"
        case .card:       return "Card number"
        case .totp:       return "Seed (base32)"
        case .custom:     return "Secret"
        }
    }

    private func populateIfEditing() {
        guard case .edit(let item) = mode else { return }
        title = item.title
        type = item.type
        guard let body = try? vm.decryptBody(of: item) else { return }
        secret = body.secret
        username = body.username ?? ""
        url = body.url ?? ""
        notes = body.notes ?? ""
        // For TOTP, notes field stores issuer|account separated by newline as convention
        if type == .totp, let extraFields = body.url {
            let parts = extraFields.split(separator: "|", maxSplits: 1)
            totpIssuer = parts.count > 0 ? String(parts[0]) : ""
            totpAccount = parts.count > 1 ? String(parts[1]) : ""
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        errorMessage = nil

        // For TOTP, pack issuer+account into url field so they survive the generic VaultItemBody
        let effectiveURL: String?
        if type == .totp {
            let combined = "\(totpIssuer)|\(totpAccount)"
            effectiveURL = combined == "|" ? nil : combined
        } else {
            effectiveURL = url.isEmpty ? nil : url
        }

        let body = VaultItemBody(
            secret: secret,
            username: username.isEmpty ? nil : username,
            url: effectiveURL,
            notes: notes.isEmpty ? nil : notes
        )
        do {
            switch mode {
            case .add:
                try await vm.addItem(title: title, type: type, body: body)
            case .edit(let item):
                try await vm.updateItem(item, title: title, body: body)
            }
            Haptics.shared.success()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            Haptics.shared.error()
        }
    }
}

// MARK: - Strength display helpers

private extension PasswordGenerator.Strength {
    var label: String {
        switch self {
        case .weak:       return "Weak"
        case .fair:       return "Fair"
        case .strong:     return "Strong"
        case .veryStrong: return "Very Strong"
        }
    }

    var color: Color {
        switch self {
        case .weak:       return Palette.danger
        case .fair:       return Palette.warning
        case .strong:     return Palette.info
        case .veryStrong: return Palette.success
        }
    }

    var fraction: CGFloat {
        switch self {
        case .weak:       return 0.25
        case .fair:       return 0.5
        case .strong:     return 0.75
        case .veryStrong: return 1.0
        }
    }
}
