const PAYHIP_API_BASE = "https://payhip.com/api/v2";

export type PayhipCouponType = "single" | "multi" | "collection";

export type PayhipCoupon = {
  id: number;
  code: string;
  coupon_type: PayhipCouponType;
  percent_off: number | null;
  amount_off: number | null;
  product_key: string | null;
  collection_id: string | null;
  start_date: string | null;
  end_date: string | null;
  minimum_purchase_amount: number | null;
  usage_limit: number | null;
  notes: string | null;
};

export type CreatePayhipCouponInput = {
  code: string;
  coupon_type: PayhipCouponType;
  percent_off?: number;
  amount_off?: number;
  product_key?: string;
  collection_id?: string;
  notes?: string;
  usage_limit?: number;
  start_date?: string;
  end_date?: string;
  minimum_purchase_amount?: number;
};

type PayhipApiResponse<T> = {
  data: T;
};

function getApiKey(): string {
  const apiKey = process.env.PAYHIP_API_KEY;
  if (!apiKey) {
    throw new Error("PAYHIP_API_KEY is not set");
  }
  return apiKey;
}

async function payhipRequest<T>(
  path: string,
  options: {
    method?: "GET" | "POST" | "PUT";
    body?: URLSearchParams;
  } = {},
): Promise<T> {
  const response = await fetch(`${PAYHIP_API_BASE}${path}`, {
    method: options.method ?? "GET",
    headers: {
      "payhip-api-key": getApiKey(),
      ...(options.body ? { "Content-Type": "application/x-www-form-urlencoded" } : {}),
    },
    body: options.body,
    cache: "no-store",
  });

  const payload = (await response.json()) as PayhipApiResponse<T> & {
    error?: string;
    message?: string;
  };

  if (!response.ok) {
    throw new Error(
      payload.error ?? payload.message ?? `Payhip API error (${response.status})`,
    );
  }

  return payload.data;
}

export async function listPayhipCoupons(options?: {
  limit?: number;
  offset?: number;
}): Promise<PayhipCoupon[]> {
  const params = new URLSearchParams();
  if (options?.limit !== undefined) params.set("limit", String(options.limit));
  if (options?.offset !== undefined) params.set("offset", String(options.offset));

  const query = params.toString();
  const data = await payhipRequest<{ coupons: PayhipCoupon[] }>(
    `/coupons${query ? `?${query}` : ""}`,
  );

  return data.coupons;
}

export async function getPayhipCoupon(id: number): Promise<PayhipCoupon> {
  return payhipRequest<PayhipCoupon>(`/coupons/${id}`);
}

export async function createPayhipCoupon(
  input: CreatePayhipCouponInput,
): Promise<PayhipCoupon> {
  const body = new URLSearchParams();
  body.set("code", input.code);
  body.set("coupon_type", input.coupon_type);

  if (input.percent_off !== undefined) body.set("percent_off", String(input.percent_off));
  if (input.amount_off !== undefined) body.set("amount_off", String(input.amount_off));
  if (input.product_key) body.set("product_key", input.product_key);
  if (input.collection_id) body.set("collection_id", input.collection_id);
  if (input.notes) body.set("notes", input.notes);
  if (input.usage_limit !== undefined) {
    body.set("usage_limit", String(input.usage_limit));
  }
  if (input.start_date) body.set("start_date", input.start_date);
  if (input.end_date) body.set("end_date", input.end_date);
  if (input.minimum_purchase_amount !== undefined) {
    body.set("minimum_purchase_amount", String(input.minimum_purchase_amount));
  }

  return payhipRequest<PayhipCoupon>("/coupons", {
    method: "POST",
    body,
  });
}

export async function verifyPayhipApiKey(): Promise<boolean> {
  await listPayhipCoupons({ limit: 1 });
  return true;
}
