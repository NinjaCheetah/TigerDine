//
//  MenuItemView.swift
//  TigerDine
//
//  Created by Campbell on 11/6/25.
//

import SwiftUI

struct MenuItemView: View {
    @State var menuItem: FDMenuItem
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading) {
                    Text(menuItem.name)
                        .font(.title)
                        .fontWeight(.bold)
                    Text(menuItem.category)
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    HStack {
                        ForEach(menuItem.dietaryMarkers, id: \.self) { dietaryMarker in
                            Text(dietaryMarker)
                                .foregroundStyle(Color.white)
                                .font(.caption)
                                .padding(5)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill({
                                            switch dietaryMarker {
                                            case "Vegan", "Vegetarian":
                                                return Color.green
                                            default:
                                                return Color.orange
                                            }
                                        }())
                                )
                        }
                    }
                }
                .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 8, trailing: 8))
                .listRowBackground(Color.clear)
            }
            
            Section {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Nutrition Facts")
                        .font(.largeTitle)
                        .fontWeight(.black)
                    
                    if (menuItem.servingSize != 0) {
                        Rectangle()
                            .fill(Color.primary)
                            .frame(height: 1)
                        
                        HStack {
                            Text("Serving Size")
                                .font(.title2)
                                .fontWeight(.black)
                            Spacer()
                            Text("\(menuItem.servingSize) \(menuItem.servingSizeUnit)")
                                .font(.title2)
                                .fontWeight(.black)
                        }
                    }
                    
                    Rectangle()
                        .fill(Color.primary)
                        .frame(height: 16)
                    
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading) {
                            Text("Amount per serving")
                                .font(.body)
                                .fontWeight(.bold)
                            Text("Calories")
                                .font(.title)
                                .fontWeight(.black)
                        }
                        Spacer()
                        Text("\(menuItem.calories)")
                            .font(.largeTitle)
                            .fontWeight(.black)
                    }
                    
                    Rectangle()
                        .fill(Color.primary)
                        .frame(height: 8)
                    
                    ForEach(menuItem.nutritionalEntries, id: \.self) { entry in
                        HStack {
                            switch entry.type {
                            case "Saturated Fat", "Trans Fat", "Dietary Fiber", "Total Sugars":
                                Text(entry.type)
                                    .padding(.leading, 16)
                            case "Calcium", "Iron", "Vitamin A", "Vitamin C":
                                Text(entry.type)
                            default:
                                Text(entry.type)
                                    .fontWeight(.black)
                            }
                            
                            Spacer()
                            
                            Text(String(format: "%.1f\(entry.unit)", entry.amount))
                        }
                        
                        switch entry.type {
                        case "Protein":
                            Rectangle()
                                .fill(Color.primary)
                                .frame(height: 16)
                        case "Vitamin C":
                            Rectangle()
                                .fill(Color.primary)
                                .frame(height: 8)
                        default:
                            Rectangle()
                                .fill(Color.primary)
                                .frame(height: 1)
                        }
                    }
                }
            }
            
            if !menuItem.allergens.isEmpty {
                Section(
                    header: Text("Allergens")
                ) {
                    Text(menuItem.allergens.joined(separator: ", "))
                        .textSelection(.enabled)
                }
            }
            
            Section(
                header: Text("Ingredients")
            ) {
                Text(menuItem.ingredients)
                    .textSelection(.enabled)
            }
        }
        .listSectionSpacing(.compact)
        .contentMargins(.top, 0)
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    MenuItemView(
        menuItem: FDMenuItem(
            // I hate having to manually define stuff like this for previews. But not as much as I
            // would've hated implementing the nutrition label without a preview!
            id: 0,
            name: "Bacon, Gouda, & Egg Sandwich",
            exactName: "Sandwich Bacon Egg Gouda BNZ",
            category: "Breakfast Sandwiches",
            allergens: ["Egg", "Gluten", "Milk", "Soy", "Wheat"],
            calories: 409,
            nutritionalEntries: [
                FDNutritionalEntry(
                    type: "Total Fat",
                    amount: 16.7,
                    unit: "g"
                ),
                FDNutritionalEntry(
                    type: "Saturated Fat",
                    amount: 6.0,
                    unit: "g"
                ),
                FDNutritionalEntry(
                    type: "Trans Fat",
                    amount: 0.0,
                    unit: "g"
                ),
                FDNutritionalEntry(
                    type: "Cholesterol",
                    amount: 144.8,
                    unit: "mg"
                ),
                FDNutritionalEntry(
                    type: "Sodium",
                    amount: 930.3,
                    unit: "mg"
                ),
                FDNutritionalEntry(
                    type: "Total Carbohydrates",
                    amount: 40.6,
                    unit: "g"
                ),
                FDNutritionalEntry(
                    type: "Dietary Fiber",
                    amount: 1.1,
                    unit: "g"
                ),
                FDNutritionalEntry(
                    type: "Total Sugars",
                    amount: 3.3,
                    unit: "g"
                ),
                FDNutritionalEntry(
                    type: "Protein",
                    amount: 24.0,
                    unit: "g"
                ),
                FDNutritionalEntry(
                    type: "Calcium",
                    amount: 286.0,
                    unit: "mg"
                ),
                FDNutritionalEntry(
                    type: "Iron",
                    amount: 3.2,
                    unit: "mg"
                ),
                FDNutritionalEntry(
                    type: "Vitamin A",
                    amount: 0.0,
                    unit: "iu"
                ),
                FDNutritionalEntry(
                    type: "Vitamin C",
                    amount: 0.0,
                    unit: "mg"
                ),
            ],
            dietaryMarkers: ["Pork"],
            ingredients: " Smoked Gouda (Pasteurized Milk, Cheese Culture, Salt And Enzymes, Cream, Water, Whey, Sodium Citrate (Emulsifier), Salt, Sorbic Acid (To Protect Flavor)), Plain Bagel (Enriched Bleached Wheat Flour (Wheat Flour, Malted Barley Flour, Niacin, Reduced Iron, Potassium Bromate, Thiamine Mononitrate, Riboflavin, Folic Acid), Water, Bagel Base (Sugar, Salt, Malted Barley Flour Contains 2% or Less of Molasses Powder [Molasses, Wheat Starch], Mono- and Diglycerides, Ammonium Chloride, Enriched Wheat Flour [Wheat Flour, Niacin, Reduced Iron, Thiamine Mononitrate, Riboflavin, Folic Acid], Ascorbic Acid [Vitamin C], L-Cysteine Hydrochloride, Enzymes), Sugar, Dough Conditioner (enriched wheat flour, [wheat flour, niacin, recued iron, thiamine mononitrate, riboflavin, folic acid], Sugar, Wheat Gluten, Calcium Stearoyl lactylate, hydrolyzed wheat gluten, monoglycerides and 2% or less of enzymes, salt and yeast.), Scrambled Egg Patty (Whole Eggs, Whey, Nonfat Milk, Vegetable Oil (Canola And/or Soybean Oil), Contains 2% Or Less of the Following: Salt, Xanthan Gum, Citric Acid, White Pepper, Natural Butter Flavor), Bacon (Pork cured with Water, Salt, Sugar, Smoke Flavoring, Sodium Phosphate, Sodium Erythorbate, Sodium Nitrite)",
            price: 4.79,
            servingSize: 1,
            servingSizeUnit: "Each")
    )
}
