//
//  FDMealPlannerParsers.swift
//  TigerDine
//
//  Created by Campbell on 11/3/25.
//

import Foundation

func parseFDMealPlannerMenu(menuRaw: FDMealsParser) -> ([FDMenuItem], [String: [Int]]) {
    var menuItems: [FDMenuItem] = []
    if menuRaw.result.isEmpty {
        return (menuItems, [:])
    }
    
    let firstResult = menuRaw.result[0]
    var conceptToItemsMap: [String: [Int]] = [:]
    
    // I hate the FD MealPlanner API so much. Why is this entirely based on a grid system?? I feel
    // like there is no logical reason to have your menu items sorted into boxes based on where
    // they appear in a grid and not just through like ID matching or something. Holy shit.
    // And then also even if we're going to do category association by row, why does an API
    // request for one day's menu provide me with 26 weeks worth of concept data that I have to
    // match up with the main menu data?? Just show me the data for the current week! You know what
    // it is already because I had to provide it in my API request. Gah.
    var rowToConceptMap: [Int: String] = [:]
    if let concepts = firstResult.conceptData {
        for concept in concepts where concept.strWeekStartDate == firstResult.strWeekStartDate {
            let cleanConceptName = concept.conceptName.decodingHTMLEntities()
            rowToConceptMap[concept.rowId] = cleanConceptName
            
            if conceptToItemsMap[cleanConceptName] == nil {
                conceptToItemsMap[cleanConceptName] = []
            }
        }
    }
    
    if let allMenuRecipes = firstResult.allMenuRecipes {
        for recipe in allMenuRecipes {
            // Prevent duplicate items from being added, because for some reason the exact same
            // item with the exact same information might be included in FD MealPlanner more than
            // once.
            if menuItems.contains(where: { $0.id == recipe.componentId }) {
                continue
            }
            
            // englishAlternateName holds the proper name of the item, but it's blank for some
            // items for some reason. If that's the case, then we should fall back on componentName,
            // which is typically less user-friendly but works as a backup.
            let rawName = !recipe.englishAlternateName.trimmingCharacters(in: .whitespaces).isEmpty
                ? recipe.englishAlternateName.trimmingCharacters(in: .whitespaces)
                : recipe.componentName.trimmingCharacters(in: .whitespaces)
            
            let realName = rawName
                .trimmingCharacters(in: .whitespaces)
                .decodingHTMLEntities()
            
            let cleanCategory = recipe.category
                .trimmingCharacters(in: .whitespaces)
                .decodingHTMLEntities()
                .capitalized // Sometimes category names don't start with a capital letter.
            
            let allergens = !recipe.allergenName.isEmpty
                ? recipe.allergenName.components(separatedBy: ",")
                : []
            
            // Get the list of dietary markers (Vegan, Vegetarian, Pork, Beef), and drop
            // "Vegetarian" if "Vegan" is also included since that's kinda implied.
            var dietaryMarkers = !recipe.recipeProductDietaryName.isEmpty
                ? recipe.recipeProductDietaryName
                    .components(separatedBy: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                : []
            if dietaryMarkers.contains("Vegan") {
                dietaryMarkers.removeAll(where: { $0 == "Vegetarian" })
            }
            
            let calories = Int(Double(recipe.calories)?.rounded() ?? 0.0)
            
            // Collect and organize all the nutritional entries. I ordered them based off how they
            // were ordered in the nutritional facts panel on the side of the bag of goldfish that
            // lives on my desk, so presumably they're ordered correctly.
            let nutritionalEntries = [
                FDNutritionalEntry(
                    type: "Total Fat",
                    amount: Double(recipe.fat) ?? 0.0,
                    unit: recipe.fatUOM
                ),
                FDNutritionalEntry(
                    type: "Saturated Fat",
                    amount: Double(recipe.saturatedFat) ?? 0.0,
                    unit: recipe.saturatedFatUOM
                ),
                FDNutritionalEntry(
                    type: "Trans Fat",
                    amount: Double(recipe.transFattyAcid) ?? 0.0,
                    unit: recipe.transFattyAcidUOM
                ),
                FDNutritionalEntry(
                    type: "Cholesterol",
                    amount: Double(recipe.cholesterol) ?? 0.0,
                    unit: recipe.cholesterolUOM
                ),
                FDNutritionalEntry(
                    type: "Sodium",
                    amount: Double(recipe.sodium) ?? 0.0,
                    unit: recipe.sodiumUOM
                ),
                FDNutritionalEntry(
                    type: "Total Carbohydrates",
                    amount: Double(recipe.carbohydrates) ?? 0.0,
                    unit: recipe.carbohydratesUOM
                ),
                FDNutritionalEntry(
                    type: "Dietary Fiber",
                    amount: Double(recipe.dietaryFiber) ?? 0.0,
                    unit: recipe.dietaryFiberUOM
                ),
                FDNutritionalEntry(
                    type: "Total Sugars",
                    amount: Double(recipe.totalSugars) ?? 0.0,
                    unit: recipe.totalSugarsUOM
                ),
                FDNutritionalEntry(
                    type: "Protein",
                    amount: Double(recipe.protein) ?? 0.0,
                    unit: recipe.proteinUOM
                ),
                FDNutritionalEntry(
                    type: "Calcium",
                    amount: Double(recipe.calcium) ?? 0.0,
                    unit: recipe.calciumUOM
                ),
                FDNutritionalEntry(
                    type: "Iron",
                    amount: Double(recipe.iron) ?? 0.0,
                    unit: recipe.ironUOM
                ),
                FDNutritionalEntry(
                    type: "Vitamin A",
                    amount: Double(recipe.vitaminA) ?? 0.0,
                    unit: recipe.vitaminAUOM
                ),
                FDNutritionalEntry(
                    type: "Vitamin C",
                    amount: Double(recipe.vitaminC) ?? 0.0,
                    unit: recipe.vitaminCUOM
                ),
            ]
            
            let newItem = FDMenuItem(
                id: recipe.componentId,
                name: realName,
                rowId: recipe.rowId,
                exactName: recipe.componentName,
                category: cleanCategory,
                allergens: allergens,
                calories: calories,
                nutritionalEntries: nutritionalEntries,
                dietaryMarkers: dietaryMarkers,
                ingredients: recipe.ingredientStatement,
                price: recipe.sellingPrice,
                servingSize: recipe.productMeasuringSize,
                servingSizeUnit: recipe.productMeasuringSizeUnit
            )
            menuItems.append(newItem)
            
            let conceptName = rowToConceptMap[recipe.rowId] ?? "Other"
            conceptToItemsMap[conceptName, default: []].append(recipe.componentId)
        }
    }
    
    return (menuItems, conceptToItemsMap)
}
