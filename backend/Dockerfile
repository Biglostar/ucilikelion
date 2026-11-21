# 1. 베이스 이미지 확인 (Alpine 기준 예시)
FROM node:18-alpine

# 2. Prisma 엔진에 필요한 라이브러리 설치
RUN apk add --no-cache openssl openssl-dev libc6-compat

WORKDIR /usr/src/app

COPY package*.json ./
RUN npm install

# 3. Prisma 스키마 복사 및 클라이언트 재생성 (중요!)
COPY prisma ./prisma
RUN npx prisma generate

COPY . .

# 4. TypeScript를 빌드 단계에서 컴파일 → 타입 에러가 있으면 여기서 빌드가 실패하고
#    Railway는 직전 정상 배포를 그대로 유지한다 (깨진 코드가 프로덕션에 올라가지 않음).
RUN npm run build

EXPOSE 3000

# 5. 컴파일된 결과를 프로덕션 모드로 실행 (ts-node-dev/nodemon 아님)
CMD ["sh", "-c", "npx prisma migrate deploy && npm start"]