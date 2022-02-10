FROM node:14.16.0 as base
WORKDIR /app
# Some dependencies need git to be installed (see yarn.lock)
RUN apt-get update
RUN apt-get install -y  git libusb-dev libudev-dev  build-essential libusb-1.0-0-dev
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile --ignore-scripts  && yarn cache clean
COPY . .
RUN yarn compile
RUN yarn lint
RUN yarn test
