import js from "@eslint/js";
import eslintConfigPrettier from "eslint-config-prettier";
import tseslint from "typescript-eslint";
import ts from 'typescript-eslint'
import pluginReact from "eslint-plugin-react";
import globals from "globals";
import pluginSvelte from "eslint-plugin-svelte";
import { config as baseConfig } from "./index.js";

/**
 * A custom ESLint configuration for libraries that use Next.js.
 *
 * @type {import("eslint").Linter.Config}
 * */
export const config = [
  ...baseConfig,
  js.configs.recommended,
  eslintConfigPrettier,
  ...tseslint.configs.recommended,
  ...pluginSvelte.configs["flat/recommended"],
  {
    ...pluginReact.configs.flat.recommended,
    languageOptions: {
      ...pluginReact.configs.flat.recommended.languageOptions,
      globals: {
        ...globals.serviceworker,
      },
    },
  },
  {
    ignores: [".svelte-kit/**/*"]
  },
  {
    files: ["**/*.svelte"],
    languageOptions: {
      parserOptions: {
        parser: ts.parser
      }
    }
  }
];
