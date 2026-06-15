import SwiftUI

enum PaymentFormMode {
    case add(projectId: UUID)
    case edit(Payment)
}

struct PaymentFormView: View {
    let mode: PaymentFormMode
    let vm: PaymentsViewModel

    @Environment(\.dismiss) private var dismiss

    @State private var amountText = ""
    @State private var currencyCode = "USD"
    @State private var status: PaymentStatus = .pending
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var hasPaidAt = false
    @State private var paidAt = Date()
    @State private var note = ""

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Amount") {
                    HStack {
                        TextField("0.00", text: $amountText)
                            .keyboardType(.decimalPad)
                        Divider()
                        TextField("USD", text: $currencyCode)
                            .frame(width: 56)
                            .multilineTextAlignment(.trailing)
                            .textInputAutocapitalization(.characters)
                            .onChange(of: currencyCode) { _, v in
                                if v.count > 3 { currencyCode = String(v.prefix(3)) }
                            }
                    }
                }

                Section("Status") {
                    Picker("Status", selection: $status) {
                        ForEach([PaymentStatus.pending, .partial, .paid], id: \.self) { s in
                            Text(s.displayName).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Toggle("Due Date", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("", selection: $dueDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                    }
                }

                if status == .paid {
                    Section {
                        Toggle("Paid Date", isOn: $hasPaidAt)
                        if hasPaidAt {
                            DatePicker("", selection: $paidAt, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                        }
                    }
                }

                Section("Note") {
                    TextField("Optional", text: $note, axis: .vertical)
                        .lineLimit(3...)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Palette.background)
            .navigationTitle(isEditing ? "Edit Payment" : "Add Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Palette.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isEditing ? "Save" : "Add") { save() }
                        .fontWeight(.semibold)
                        .foregroundStyle(Palette.accent)
                        .disabled(amountText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .onAppear { prefill() }
    }

    // MARK: - Helpers

    private func prefill() {
        guard case .edit(let payment) = mode else { return }
        amountText = formatForInput(payment.amountMinorUnits)
        currencyCode = payment.currencyCode
        status = payment.status == .overdue ? .pending : payment.status
        if let due = payment.dueDate { hasDueDate = true; dueDate = due }
        if let paid = payment.paidAt { hasPaidAt = true; paidAt = paid }
        note = payment.note ?? ""
    }

    private func save() {
        let minorUnits = parseMinorUnits(from: amountText)
        let code = currencyCode.trimmingCharacters(in: .whitespaces).uppercased()
        let resolvedDue = hasDueDate ? dueDate : nil
        let resolvedPaid = (status == .paid && hasPaidAt) ? paidAt : nil
        let resolvedNote = note.trimmingCharacters(in: .whitespaces).isEmpty ? nil : note

        Task {
            switch mode {
            case .add(let projectId):
                await vm.add(
                    projectId: projectId,
                    amountMinorUnits: minorUnits,
                    currencyCode: code.isEmpty ? "USD" : code,
                    status: status,
                    dueDate: resolvedDue,
                    paidAt: resolvedPaid,
                    note: resolvedNote
                )
            case .edit(var payment):
                payment.amountMinorUnits = minorUnits
                payment.currencyCode = code.isEmpty ? "USD" : code
                payment.status = status
                payment.dueDate = resolvedDue
                payment.paidAt = resolvedPaid
                payment.note = resolvedNote
                payment.updatedAt = Date()
                await vm.update(payment)
            }
            dismiss()
        }
    }

    /// Parses "150.00" → 15000. Uses Decimal to avoid floating-point rounding.
    private func parseMinorUnits(from text: String) -> Int {
        let cleaned = text.trimmingCharacters(in: .whitespaces)
        guard let decimal = Decimal(string: cleaned) else { return 0 }
        let scaled = decimal * 100
        let handler = NSDecimalNumberHandler(
            roundingMode: .plain, scale: 0,
            raiseOnExactness: false, raiseOnOverflow: false,
            raiseOnUnderflow: false, raiseOnDivideByZero: false
        )
        return NSDecimalNumber(decimal: scaled).rounding(accordingToBehavior: handler).intValue
    }

    private func formatForInput(_ minorUnits: Int) -> String {
        let amount = Decimal(minorUnits) / 100
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        fmt.minimumFractionDigits = 2
        fmt.maximumFractionDigits = 2
        fmt.usesGroupingSeparator = false
        return fmt.string(from: amount as NSDecimalNumber) ?? "0.00"
    }
}
