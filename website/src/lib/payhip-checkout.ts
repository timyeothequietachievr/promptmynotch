const DEFAULT_PAYHIP_PRODUCT_KEY = "HZSW8";
const DEFAULT_PAYHIP_CHECKOUT_URL = "https://payhip.com/b/HZSW8";

/**
 * Public checkout URL for Payhip. Product setup (file upload, Email Octopus,
 * checkout questions) is done in the Payhip dashboard — the API cannot create products yet.
 */
export function getPayhipCheckoutUrl(): string | null {
  const explicitUrl = process.env.NEXT_PUBLIC_PAYHIP_CHECKOUT_URL?.trim();
  if (explicitUrl) return explicitUrl;

  if (DEFAULT_PAYHIP_CHECKOUT_URL) return DEFAULT_PAYHIP_CHECKOUT_URL;

  const productKey =
    process.env.NEXT_PUBLIC_PAYHIP_PRODUCT_KEY?.trim() ?? DEFAULT_PAYHIP_PRODUCT_KEY;
  if (!productKey) return null;

  const useDirectCheckout =
    process.env.NEXT_PUBLIC_PAYHIP_DIRECT_CHECKOUT !== "false";

  if (useDirectCheckout) {
    return `https://payhip.com/buy?link=${encodeURIComponent(productKey)}`;
  }

  return `https://payhip.com/b/${encodeURIComponent(productKey)}`;
}

export function isPayhipCheckoutConfigured(): boolean {
  return getPayhipCheckoutUrl() !== null;
}
