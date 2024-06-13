FROM node:22
WORKDIR /app
COPY package.json .
COPY package-lock.json .
RUN npm install
COPY . .
EXPOSE 8545
CMD [ "npx", "hardhat", "node" ]