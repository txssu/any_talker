// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require("tailwindcss/plugin");
const fs = require("fs");
const path = require("path");
const defaultTheme = require("tailwindcss/defaultTheme");

module.exports = {
  content: [
    "./js/**/*.js",
    "../lib/any_talker_web.ex",
    "../lib/any_talker_web/**/*.*ex",
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ["Roboto", ...defaultTheme.fontFamily.sans],
      },
      colors: {
        "tg-bg": "var(--tg-theme-bg-color)",
        "tg-text": "var(--tg-theme-text-color)",
        "tg-hint": "var(--tg-theme-hint-color)",
        "tg-link": "var(--tg-theme-link-color)",
        "tg-button": "var(--tg-theme-button-color)",
        "tg-button-text": "var(--tg-theme-button-text-color)",
        "tg-secondary-bg": "var(--tg-theme-secondary-bg-color)",
        "tg-header-bg": "var(--tg-theme-header-bg-color)",
        "tg-bottom-bar-bg": "var(--tg-theme-bottom-bar-bg-color)",
        "tg-accent-text": "var(--tg-theme-accent-text-color)",
        "tg-section-bg": "var(--tg-theme-section-bg-color)",
        "tg-section-header-text": "var(--tg-theme-section-header-text-color)",
        "tg-section-separator": "var(--tg-theme-section-separator-color)",
        "tg-subtitle-text": "var(--tg-theme-subtitle-text-color)",
        "tg-destructive-text": "var(--tg-theme-destructive-text-color)",
      },
      spacing: {
        "tg-safe-top": "var(--tg-safe-area-inset-top)",
        "tg-safe-bottom": "var(--tg-safe-area-inset-bottom)",
        "tg-safe-left": "var(--tg-safe-area-inset-left)",
        "tg-safe-right": "var(--tg-safe-area-inset-right)",
      },
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    // Allows prefixing tailwind classes with LiveView classes to add rules
    // only when LiveView classes are applied, for example:
    //
    //     <div class="phx-click-loading:animate-ping">
    //
    plugin(({ addVariant }) =>
      addVariant("phx-click-loading", [
        ".phx-click-loading&",
        ".phx-click-loading &",
      ]),
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-submit-loading", [
        ".phx-submit-loading&",
        ".phx-submit-loading &",
      ]),
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-change-loading", [
        ".phx-change-loading&",
        ".phx-change-loading &",
      ]),
    ),

    // Embeds Heroicons (https://heroicons.com) into your app.css bundle
    // See your `CoreComponents.icon/1` for more information.
    //
    plugin(function ({ matchComponents, theme }) {
      let iconsDir = path.join(__dirname, "../deps/heroicons/optimized");
      let values = {};
      let icons = [
        ["", "/24/outline"],
        ["-solid", "/24/solid"],
        ["-mini", "/20/solid"],
        ["-micro", "/16/solid"],
      ];
      icons.forEach(([suffix, dir]) => {
        fs.readdirSync(path.join(iconsDir, dir)).forEach((file) => {
          let name = path.basename(file, ".svg") + suffix;
          values[name] = { name, fullPath: path.join(iconsDir, dir, file) };
        });
      });
      matchComponents(
        {
          hero: ({ name, fullPath }) => {
            let content = fs
              .readFileSync(fullPath)
              .toString()
              .replace(/\r?\n|\r/g, "");
            let size = theme("spacing.6");
            if (name.endsWith("-mini")) {
              size = theme("spacing.5");
            } else if (name.endsWith("-micro")) {
              size = theme("spacing.4");
            }
            return {
              [`--hero-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
              "-webkit-mask": `var(--hero-${name})`,
              mask: `var(--hero-${name})`,
              "mask-repeat": "no-repeat",
              "background-color": "currentColor",
              "vertical-align": "middle",
              display: "inline-block",
              width: size,
              height: size,
            };
          },
        },
        { values },
      );
    }),
  ],
};
