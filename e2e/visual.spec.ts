import { test, expect } from '@playwright/test';
import { pages } from "./pages.ts";

for (const pageUrl of pages) {
    test(`visual regression for ${pageUrl}`, async ({ page }) => {
      await page.goto(pageUrl, { waitUntil: 'networkidle' });

      // 1. Ensure all stylesheets are parsed
      await page.waitForFunction(() =>
        Array.from(document.styleSheets).every(
          s => !s.href || s.cssRules !== null
        )
      );

      await page.evaluate(() => document.fonts.ready);

      await page.addStyleTag({
          content: `
          *, *::before, *::after {
              animation: none !important;
              transition: none !important;
              caret-color: transparent !important;
          }
          `,
      });

      await page.evaluate(() => new Promise(requestAnimationFrame));

      await expect(page).toHaveScreenshot({ fullPage: true, timeout: 20_000 });
    });
}
