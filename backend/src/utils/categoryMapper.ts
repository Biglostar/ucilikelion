// 앱(iOS BudgetCategory.rawValue)과 같은 카테고리 문자열로 저장해야 목표(Goal)와 거래가 서버에서 매칭된다
export const mapPlaidCategory = (detailedCategory?: string | null): string => {
    if (!detailedCategory) return 'others'; // default
    if (detailedCategory.startsWith('INCOME_')) return 'income';
    if (detailedCategory.startsWith('TRANSFER_IN')) return 'income';
    if (detailedCategory.startsWith('TRANSPORTATION_')) return 'transportation';
    if (detailedCategory.startsWith('GENERAL_MERCHANDISE_')) return 'generalMerchandise';
    if (detailedCategory.startsWith('PERSONAL_CARE_')) return 'personalCare';
    if (detailedCategory.startsWith('ENTERTAINMENT_')) return 'entertainment';
    if (detailedCategory.startsWith('GENERAL_SERVICES_')) return 'generalServices';
    if (detailedCategory.startsWith('MEDICAL_')) return 'medical';

    if (detailedCategory == 'FOOD_AND_DRINK_COFFEE') return 'cafe';
    if (detailedCategory == 'FOOD_AND_DRINK_GROCERIES') return 'grocery';
    if (detailedCategory.startsWith('FOOD_AND_DRINK_')) return 'food';

    if (detailedCategory == 'RENT_AND_UTILITIES_RENT') return 'rent';
    if (detailedCategory.startsWith('RENT_AND_UTILITIES_')) return 'utilities';

    return 'others';
};
