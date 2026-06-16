import SwiftUI

/// Advanced library filters: BPM range, musical keys, vocals, favorites.
struct LibraryFiltersSheet: View {
    @Binding var bpmMin: Int
    @Binding var bpmMax: Int
    @Binding var selectedKeys: Set<MusicalKey>
    @Binding var vocalFilter: VocalLibraryFilter
    @Binding var favoritesOnly: Bool

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Favorites only", isOn: $favoritesOnly)
                }

                Section("BPM Range") {
                    HStack {
                        Text("\(effectiveBPMMin)")
                        Slider(
                            value: bpmMinBinding,
                            in: Double(LibraryFilterLogic.bpmRangeLimit.lowerBound)...Double(effectiveBPMMax),
                            step: 1
                        )
                    }
                    HStack {
                        Text("\(effectiveBPMMax)")
                        Slider(
                            value: bpmMaxBinding,
                            in: Double(effectiveBPMMin)...Double(LibraryFilterLogic.bpmRangeLimit.upperBound),
                            step: 1
                        )
                    }
                    if LibraryFilterLogic.isBPMFilterActive(min: bpmMin, max: bpmMax) {
                        Text("\(effectiveBPMMin)–\(effectiveBPMMax) BPM")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("All tempos")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Button("Reset BPM range") {
                        bpmMin = LibraryFilterLogic.bpmRangeLimit.lowerBound
                        bpmMax = LibraryFilterLogic.bpmRangeLimit.upperBound
                    }
                    .font(.subheadline)
                }

                Section("Key") {
                    if selectedKeys.isEmpty {
                        Text("All keys")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("\(selectedKeys.count) selected")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 8)], spacing: 8) {
                        ForEach(MusicalKey.allCases.filter { $0 != .unknown }) { key in
                            keyChip(key)
                        }
                    }
                    .padding(.vertical, 4)
                    if !selectedKeys.isEmpty {
                        Button("Clear keys") { selectedKeys.removeAll() }
                            .font(.subheadline)
                    }
                }

                Section {
                    Picker("Vocals", selection: $vocalFilter) {
                        ForEach(VocalLibraryFilter.allCases) { option in
                            Label(option.menuTitle, systemImage: option.symbolName)
                                .tag(option)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                    .accessibilityIdentifier(A11yID.Library.vocalFilter)
                } header: {
                    Text("Vocals")
                } footer: {
                    Text("Uncertain tracks had detection run but the result wasn't confident enough to label.")
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .accessibilityIdentifier(A11yID.Library.filtersSheet)
    }

    private var effectiveBPMMin: Int { min(bpmMin, bpmMax) }
    private var effectiveBPMMax: Int { max(bpmMin, bpmMax) }

    private var bpmMinBinding: Binding<Double> {
        Binding(
            get: { Double(bpmMin) },
            set: { bpmMin = Int($0.rounded()) }
        )
    }

    private var bpmMaxBinding: Binding<Double> {
        Binding(
            get: { Double(bpmMax) },
            set: { bpmMax = Int($0.rounded()) }
        )
    }

    private func keyChip(_ key: MusicalKey) -> some View {
        let isOn = selectedKeys.contains(key)
        return Button {
            if isOn {
                selectedKeys.remove(key)
            } else {
                selectedKeys.insert(key)
            }
        } label: {
            Text(key.camelotCode ?? key.displayName)
                .font(.caption.weight(.medium))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    isOn ? Color.accentColor : Color(.secondarySystemBackground),
                    in: RoundedRectangle(cornerRadius: 8)
                )
                .foregroundStyle(isOn ? .white : .primary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(key.displayName)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}
