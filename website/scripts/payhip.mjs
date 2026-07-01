#!/usr/bin/env node

import { existsSync, readFileSync } from "node:fs";
import { resolve } from "node:path";

const API_BASE = "https://payhip.com/api/v2";

function loadEnvFiles() {
  for (const file of [".env.local", ".env"]) {
    const path = resolve(process.cwd(), file);
    if (!existsSync(path)) continue;

    for (const line of readFileSync(path, "utf8").split("\n")) {
      const trimmed = line.trim();
      if (!trimmed || trimmed.startsWith("#")) continue;

      const separator = trimmed.indexOf("=");
      if (separator === -1) continue;

      const key = trimmed.slice(0, separator).trim();
      let value = trimmed.slice(separator + 1).trim();
      if (
        (value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))
      ) {
        value = value.slice(1, -1);
      }

      if (!process.env[key]) {
        process.env[key] = value;
      }
    }
  }
}

function getApiKey() {
  const apiKey = process.env.PAYHIP_API_KEY;
  if (!apiKey) {
    throw new Error("PAYHIP_API_KEY is not set. Add it to .env.local");
  }
  return apiKey;
}

async function payhipRequest(path, { method = "GET", body } = {}) {
  const response = await fetch(`${API_BASE}${path}`, {
    method,
    headers: {
      "payhip-api-key": getApiKey(),
      ...(body ? { "Content-Type": "application/x-www-form-urlencoded" } : {}),
    },
    body,
  });

  const payload = await response.json();
  if (!response.ok) {
    throw new Error(payload.error ?? payload.message ?? `Payhip API error (${response.status})`);
  }

  return payload.data;
}

function parseArgs(argv) {
  const args = [...argv];
  const flags = {};
  const positionals = [];

  while (args.length > 0) {
    const current = args.shift();
    if (current.startsWith("--")) {
      const key = current.slice(2);
      const next = args[0];
      if (!next || next.startsWith("--")) {
        flags[key] = true;
      } else {
        flags[key] = args.shift();
      }
    } else {
      positionals.push(current);
    }
  }

  return { flags, positionals };
}

function printUsage() {
  console.log(`Payhip CLI

Usage:
  npm run payhip -- test
  npm run payhip -- coupons list [--limit 20] [--offset 0]
  npm run payhip -- coupons get <id>
  npm run payhip -- coupons create --code CODE --type single|multi|collection \\
      [--percent 100] [--amount 500] [--product-key KEY] [--notes TEXT] [--usage-limit N]

Environment:
  PAYHIP_API_KEY                 Required for all commands
  NEXT_PUBLIC_PAYHIP_PRODUCT_KEY Default product key for coupon create

Note: Payhip's API only supports coupons and license keys. Product setup
(file upload, Email Octopus, checkout questions) must be done in the dashboard.
`);
}

async function testApiKey() {
  await payhipRequest("/coupons?limit=1");
  console.log("Payhip API key is valid.");
}

async function listCoupons(flags) {
  const params = new URLSearchParams();
  if (flags.limit) params.set("limit", flags.limit);
  if (flags.offset) params.set("offset", flags.offset);

  const query = params.toString();
  const data = await payhipRequest(`/coupons${query ? `?${query}` : ""}`);
  console.log(JSON.stringify(data.coupons, null, 2));
}

async function getCoupon(id) {
  const data = await payhipRequest(`/coupons/${id}`);
  console.log(JSON.stringify(data, null, 2));
}

async function createCoupon(flags) {
  const code = flags.code;
  const couponType = flags.type ?? "single";
  const productKey = flags["product-key"] ?? process.env.NEXT_PUBLIC_PAYHIP_PRODUCT_KEY;

  if (!code) {
    throw new Error("--code is required");
  }

  if (couponType === "single" && !productKey) {
    throw new Error("--product-key or NEXT_PUBLIC_PAYHIP_PRODUCT_KEY is required for single coupons");
  }

  if (!flags.percent && !flags.amount) {
    throw new Error("Provide --percent or --amount");
  }

  const body = new URLSearchParams();
  body.set("code", code);
  body.set("coupon_type", couponType);
  if (flags.percent) body.set("percent_off", flags.percent);
  if (flags.amount) body.set("amount_off", flags.amount);
  if (productKey) body.set("product_key", productKey);
  if (flags.notes) body.set("notes", flags.notes);
  if (flags["usage-limit"]) body.set("usage_limit", flags["usage-limit"]);

  const data = await payhipRequest("/coupons", { method: "POST", body });
  console.log(JSON.stringify(data, null, 2));
}

async function main() {
  loadEnvFiles();

  const { flags, positionals } = parseArgs(process.argv.slice(2));
  const [resource, action, id] = positionals;

  if (!resource || resource === "help" || flags.help) {
    printUsage();
    return;
  }

  if (resource === "test") {
    await testApiKey();
    return;
  }

  if (resource !== "coupons") {
    printUsage();
    process.exitCode = 1;
    return;
  }

  if (action === "list") {
    await listCoupons(flags);
    return;
  }

  if (action === "get") {
    if (!id) throw new Error("coupon id is required");
    await getCoupon(id);
    return;
  }

  if (action === "create") {
    await createCoupon(flags);
    return;
  }

  printUsage();
  process.exitCode = 1;
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
