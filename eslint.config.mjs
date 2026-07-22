import { defineConfig, globalIgnores } from "eslint/config";
import nextVitals from "eslint-config-next/core-web-vitals";
import nextTs from "eslint-config-next/typescript";

const eslintConfig = defineConfig([
  ...nextVitals,
  ...nextTs,
  // Override default ignores of eslint-config-next.
  globalIgnores([
    // Default ignores of eslint-config-next:
    ".next/**",
    "out/**",
    "build/**",
    "next-env.d.ts",
    // Foundry dependencies and build output. Vendored third-party Solidity
    // repos ship their own JS tooling, which has no business being linted
    // against this project's rules.
    "contracts/lib/**",
    "contracts/out/**",
    "contracts/cache/**",
  ]),
]);

export default eslintConfig;
