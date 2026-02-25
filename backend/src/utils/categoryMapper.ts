export const mapPlaidCategory = (detailedCategory?: string | null): string => {
    if (!detailedCategory) return 'others'; // default
    if (detailedCategory.startsWith('INCOME_')) return 'income';
    if (detailedCategory.startsWith('TRANSPORTATION_')) return 'transportation';
    if (detailedCategory.startsWith('GENERAL_MERCHANDISE_')) return 'general merchandise';
    if (detailedCategory.startsWith('PERSONAL_CARE_')) return 'personal care';
    if (detailedCategory.startsWith('ENTERTAINMENT_')) return 'entertainment';
    if (detailedCategory.startsWith('GENERAL_SERVICES_')) return 'general services';
    if (detailedCategory.startsWith('MEDICAL_')) return 'medical';

    if (detailedCategory == 'FOOD_AND_DRINK_COFFEE') return 'cafe';
    if (detailedCategory == 'FOOD_AND_DRINK_GROCERIES') return 'groceries';
    if (detailedCategory.startsWith('FOOD_AND_DRINK_')) return 'food';

    if (detailedCategory == 'RENT_AND_UTILITIES_RENT') return 'rent';
    if (detailedCategory.startsWith('RENT_AND_UTILITIES_')) return 'util';

    return 'others';
};
