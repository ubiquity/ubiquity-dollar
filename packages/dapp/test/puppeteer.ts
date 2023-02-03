import scrape from "./scraper-kernel/src/scrape";
import path from "path";

export default async function puppeteerTest() {
  console.log("Hello from puppeteer.ts");

  const config = {
    urls: "http://localhost:3000/",
    pagesDirectory: path.join(__dirname, "pages/"),
    verbose: 5,
  };

  const result = await scrape(config);
  console.log({ result });
  process.exit(0);
}

puppeteerTest();
