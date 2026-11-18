-- Plaid 매퍼가 저장하던 카테고리 문자열을 앱(iOS BudgetCategory.rawValue) 값으로 통일
-- (목표와 거래의 category를 서버에서 문자열로 비교하기 때문에 값이 다르면 게이지/알림에 반영되지 않음)
UPDATE "Transaction" SET "category" = 'grocery'            WHERE "category" = 'groceries';
UPDATE "Transaction" SET "category" = 'utilities'          WHERE "category" = 'util';
UPDATE "Transaction" SET "category" = 'generalMerchandise' WHERE "category" = 'general merchandise';
UPDATE "Transaction" SET "category" = 'personalCare'       WHERE "category" = 'personal care';
UPDATE "Transaction" SET "category" = 'generalServices'    WHERE "category" = 'general services';

UPDATE "Goal" SET "category" = 'grocery'            WHERE "category" = 'groceries';
UPDATE "Goal" SET "category" = 'utilities'          WHERE "category" = 'util';
UPDATE "Goal" SET "category" = 'generalMerchandise' WHERE "category" = 'general merchandise';
UPDATE "Goal" SET "category" = 'personalCare'       WHERE "category" = 'personal care';
UPDATE "Goal" SET "category" = 'generalServices'    WHERE "category" = 'general services';
