const dotenv = require("dotenv");
const { createApp } = require("./app");

dotenv.config();

const app = createApp();
const port = Number(process.env.PORT || 3000);

if (require.main === module) {
  app.listen(port, () => {
    console.log(`Backend listening on http://localhost:${port}`);
  });
}

module.exports = { app };

