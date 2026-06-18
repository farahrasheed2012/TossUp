import Foundation

struct ChemicalElement: Identifiable, Hashable {
    let atomicNumber: Int
    let symbol: String
    let name: String

    var id: Int { atomicNumber }
}

enum ElementCatalog {
    /// First 20 elements — middle-school NSB chemistry subset.
    static let firstTwenty: [ChemicalElement] = [
        ChemicalElement(atomicNumber: 1, symbol: "H", name: "Hydrogen"),
        ChemicalElement(atomicNumber: 2, symbol: "He", name: "Helium"),
        ChemicalElement(atomicNumber: 3, symbol: "Li", name: "Lithium"),
        ChemicalElement(atomicNumber: 4, symbol: "Be", name: "Beryllium"),
        ChemicalElement(atomicNumber: 5, symbol: "B", name: "Boron"),
        ChemicalElement(atomicNumber: 6, symbol: "C", name: "Carbon"),
        ChemicalElement(atomicNumber: 7, symbol: "N", name: "Nitrogen"),
        ChemicalElement(atomicNumber: 8, symbol: "O", name: "Oxygen"),
        ChemicalElement(atomicNumber: 9, symbol: "F", name: "Fluorine"),
        ChemicalElement(atomicNumber: 10, symbol: "Ne", name: "Neon"),
        ChemicalElement(atomicNumber: 11, symbol: "Na", name: "Sodium"),
        ChemicalElement(atomicNumber: 12, symbol: "Mg", name: "Magnesium"),
        ChemicalElement(atomicNumber: 13, symbol: "Al", name: "Aluminum"),
        ChemicalElement(atomicNumber: 14, symbol: "Si", name: "Silicon"),
        ChemicalElement(atomicNumber: 15, symbol: "P", name: "Phosphorus"),
        ChemicalElement(atomicNumber: 16, symbol: "S", name: "Sulfur"),
        ChemicalElement(atomicNumber: 17, symbol: "Cl", name: "Chlorine"),
        ChemicalElement(atomicNumber: 18, symbol: "Ar", name: "Argon"),
        ChemicalElement(atomicNumber: 19, symbol: "K", name: "Potassium"),
        ChemicalElement(atomicNumber: 20, symbol: "Ca", name: "Calcium"),
    ]

    static func element(number: Int) -> ChemicalElement? {
        firstTwenty.first { $0.atomicNumber == number }
    }

    static func element(symbol: String) -> ChemicalElement? {
        firstTwenty.first { $0.symbol.caseInsensitiveCompare(symbol) == .orderedSame }
    }
}
