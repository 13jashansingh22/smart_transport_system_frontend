const dotenv = require("dotenv");
const { createApp } = require("../src/app");

dotenv.config();

const app = createApp();

module.exports = app;

