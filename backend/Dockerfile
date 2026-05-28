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

EXPOSE 3000
CMD ["npm", "run", "dev"]