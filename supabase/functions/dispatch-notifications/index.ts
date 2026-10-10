// Supabase Edge Function dispatcher for the notifications pipeline.
//
// Replaces the former Firebase Scheduled Function
// (`dispatchSupabaseNotifications` in functions/src/notifications.ts) so the
// dispatcher no longer requires Firebase Blaze / Firebase Secret Manager.
//
// Flow (unchanged behaviour):
//   Supabase queue/RPCs
//     -> this Edge Function dispatcher
//     -> FCM HTTP v1 API
//     -> Customer / Owner / Barber devices
//
// Scheduling is handled Supabase-natively by pg_cron + pg_net (see the
// accompanying migration). The scheduled request is authenticated with a shared
// secret generated server-side in Supabase Vault: pg_net sends it as a Bearer
// token and this function verifies it via the service_role-only RPC
// `get_dispatch_secret()`. The secret is never committed to source control and
// never logged.
//
// FCM credentials use a Google/Firebase service account supplied through the
// `FCM_SERVICE_ACCOUNT_JSON` secret (the raw JSON key). Nothing is hardcoded and
// no credential is ever logged.

const SUPABASE_URL =
  Deno.env.get("SUPABASE_URL") ?? "https://fdvnqqjekkhtxobvcbqx.supabase.co";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
// The Firebase/FCM service-account JSON is stored as a Supabase Function
// secret. Accepts FCM_SERVICE_ACCOUNT_JSON, FIREBASE_SERVICE_ACCOUNT, or
// FIREBASE_SERVICE_ACCOUNT_JSON dynamically at invocation time.
function getFirebaseServiceAccountRaw(): string | undefined {
  return (
    Deno.env.get("FCM_SERVICE_ACCOUNT_JSON") ??
    Deno.env.get("FIREBASE_SERVICE_ACCOUNT") ??
    Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON") ??
    Deno.env.get("GOOGLE_APPLICATION_CREDENTIALS_JSON")
  );
}

const MAX_PUSH_ATTEMPTS = 5;
const DEFAULT_CHANNEL_ID = "barber_booking_default";
const FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging";
const FALLBACK_FCM_PROJECT_ID = "flash-392b3";

const NOTIFICATION_TYPES: ReadonlySet<string> = new Set([
  "bookingCreated",
  "bookingConfirmed",
  "bookingRejected",
  "bookingCancelled",
  "bookingCompleted",
  "bookingNoShow",
  "appointmentReminder",
  "scheduleChanged",
  "paymentSuccess",
  "general",
]);

// FCM HTTP v1 error codes that mean the device token itself is bad and must be
// removed (mirrors the legacy messaging/invalid-registration-token and
// messaging/registration-token-not-registered handling).
const INVALID_TOKEN_CODES: ReadonlySet<string> = new Set([
  "UNREGISTERED",
]);

type NotificationType =
  | "bookingCreated"
  | "bookingConfirmed"
  | "bookingRejected"
  | "bookingCancelled"
  | "bookingCompleted"
  | "bookingNoShow"
  | "appointmentReminder"
  | "scheduleChanged"
  | "paymentSuccess"
  | "general";

type NotificationRow = {
  id: string;
  recipient_id: string;
  type: NotificationType;
  title: string;
  body: string;
  booking_id: string | null;
  push_attempts: number;
  push_pending_tokens: string[];
};

type ServiceAccount = {
  project_id?: string;
  client_email: string;
  private_key: string;
  token_uri?: string;
};

// ---------------------------------------------------------------------------
// Validation helpers (ported from the original Firebase implementation).
// ---------------------------------------------------------------------------

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}

function isNotificationType(value: unknown): value is NotificationType {
  return typeof value === "string" && NOTIFICATION_TYPES.has(value);
}

function parseNotificationRows(value: unknown): NotificationRow[] {
  if (!Array.isArray(value)) {
    throw new Error("Supabase returned an invalid notification queue.");
  }

  return value.map((row: unknown) => {
    if (
      !isRecord(row) ||
      typeof row.id !== "string" ||
      typeof row.recipient_id !== "string" ||
      !isNotificationType(row.type) ||
      typeof row.title !== "string" ||
      typeof row.body !== "string" ||
      !(typeof row.booking_id === "string" || row.booking_id === null) ||
      typeof row.push_attempts !== "number" ||
      !Array.isArray(row.push_pending_tokens) ||
      !row.push_pending_tokens.every((token) => typeof token === "string")
    ) {
      throw new Error("Supabase returned an invalid notification row.");
    }

    return {
      id: row.id,
      recipient_id: row.recipient_id,
      type: row.type,
      title: row.title,
      body: row.body,
      booking_id: row.booking_id,
      push_attempts: row.push_attempts,
      push_pending_tokens: row.push_pending_tokens,
    };
  });
}

function parseDeviceTokens(value: unknown): string[] {
  if (!Array.isArray(value)) {
    throw new Error("Supabase returned an invalid device-token list.");
  }

  return value.flatMap((row: unknown) => {
    if (!isRecord(row) || typeof row.token !== "string" || row.token.length === 0) {
      return [];
    }
    return [row.token];
  });
}


// ---------------------------------------------------------------------------
// Supabase REST access (service-role key from the Function environment).
// ---------------------------------------------------------------------------

function requireServiceRoleKey(): string {
  if (!SUPABASE_SERVICE_ROLE_KEY) {
    throw new Error("SUPABASE_SERVICE_ROLE_KEY is not configured.");
  }
  return SUPABASE_SERVICE_ROLE_KEY;
}

async function supabaseRequest(
  path: string,
  init: RequestInit = {},
): Promise<unknown> {
  const key = requireServiceRoleKey();
  const response = await fetch(`${SUPABASE_URL}/rest/v1/${path}`, {
    ...init,
    headers: {
      apikey: key,
      Authorization: `Bearer ${key}`,
      "Content-Type": "application/json",
      ...init.headers,
    },
  });

  if (!response.ok) {
    const responseBody = await response.text();
    throw new Error(
      `Supabase request failed (${response.status}): ${responseBody.slice(0, 300)}`,
    );
  }

  if (response.status === 204) {
    return null;
  }
  return await response.json();
}

async function loadDeviceTokens(recipientId: string): Promise<string[]> {
  const parameters = new URLSearchParams({
    select: "token",
    user_id: `eq.${recipientId}`,
  });
  const result = await supabaseRequest(`device_tokens?${parameters}`);
  return [...new Set(parseDeviceTokens(result))];
}

async function deleteInvalidToken(token: string): Promise<void> {
  const parameters = new URLSearchParams({token: `eq.${token}`});
  await supabaseRequest(`device_tokens?${parameters}`, {method: "DELETE"});
}

async function updatePushState(
  notification: NotificationRow,
  pushStatus: "sent" | "failed" | "pending" | "skipped",
  pushError: string | null,
  pendingTokens: string[] = [],
  nextAttemptAt: Date = new Date(),
): Promise<void> {
  const parameters = new URLSearchParams({
    id: `eq.${notification.id}`,
    push_status: "eq.processing",
  });
  const updated = await supabaseRequest(
    `notifications?${parameters}`,
    {
      method: "PATCH",
      headers: {Prefer: "return=representation"},
      body: JSON.stringify({
        push_status: pushStatus,
        push_error: pushError,
        push_claimed_at: null,
        push_pending_tokens: pendingTokens,
        push_next_attempt_at: nextAttemptAt.toISOString(),
      }),
    },
  );

  if (!Array.isArray(updated) || updated.length !== 1) {
    throw new Error("The claimed notification could not be updated.");
  }
}

async function storePendingTokens(
  notification: NotificationRow,
  tokens: string[],
): Promise<void> {
  const parameters = new URLSearchParams({
    id: `eq.${notification.id}`,
    push_status: "eq.processing",
  });
  const updated = await supabaseRequest(`notifications?${parameters}`, {
    method: "PATCH",
    headers: {Prefer: "return=representation"},
    body: JSON.stringify({push_pending_tokens: tokens}),
  });

  if (!Array.isArray(updated) || updated.length !== 1) {
    throw new Error("The claimed notification's devices could not be stored.");
  }
}

async function retryOrFail(
  notification: NotificationRow,
  code: string,
  pendingTokens: string[],
): Promise<void> {
  const retry = notification.push_attempts < MAX_PUSH_ATTEMPTS;
  const delayMinutes = Math.min(2 ** (notification.push_attempts - 1), 60);
  const nextAttemptAt = new Date(Date.now() + delayMinutes * 60_000);

  await updatePushState(
    notification,
    retry ? "pending" : "failed",
    code.slice(0, 500),
    pendingTokens,
    nextAttemptAt,
  );
  console.error(
    `FCM delivery failed for notification ${notification.id}: ${code}`,
  );
}

// ---------------------------------------------------------------------------
// FCM HTTP v1 authentication (OAuth2 via the service account).
// ---------------------------------------------------------------------------

function base64UrlBytes(bytes: Uint8Array): string {
  let binary = "";
  for (let i = 0; i < bytes.length; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary)
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}

function base64Url(input: string): string {
  return base64UrlBytes(new TextEncoder().encode(input));
}

async function importPrivateKey(pem: string): Promise<CryptoKey> {
  const normalized = pem
    .replace(/-----BEGIN[ A-Z_-]*PRIVATE KEY-----/g, "")
    .replace(/-----END[ A-Z_-]*PRIVATE KEY-----/g, "")
    .replace(/\s+/g, "");

  let binary: string;
  try {
    binary = atob(normalized);
  } catch (decodeError) {
    throw new Error(
      `Invalid private key PEM base64 (${decodeError instanceof Error ? decodeError.message : String(decodeError)}).`,
    );
  }

  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }

  try {
    return await crypto.subtle.importKey(
      "pkcs8",
      bytes.buffer,
      {name: "RSASSA-PKCS1-v1_5", hash: "SHA-256"},
      false,
      ["sign"],
    );
  } catch (importError) {
    throw new Error(
      `PKCS8 private key import failed (${importError instanceof Error ? importError.message : String(importError)}).`,
    );
  }
}

function tryParseJson(value: string): unknown {
  try {
    return JSON.parse(value);
  } catch {
    return undefined;
  }
}

function parseServiceAccount(): ServiceAccount {
  const raw = getFirebaseServiceAccountRaw();
  if (!raw) {
    throw new Error("FCM_SERVICE_ACCOUNT_JSON secret is not configured.");
  }

  let parsed: unknown = tryParseJson(raw);
  // Handle double-encoded JSON: a JSON string that itself contains the object.
  if (typeof parsed === "string") {
    parsed = tryParseJson(parsed);
  }

  if (
    !isRecord(parsed) ||
    typeof parsed.client_email !== "string" ||
    typeof parsed.private_key !== "string"
  ) {
    // Safe structural diagnostics only: length + first few characters. Never
    // log the private key or the full secret contents.
    console.error(
      `FCM_SERVICE_ACCOUNT_JSON is not a valid service-account JSON ` +
        `(len=${raw.length}, head=${JSON.stringify(raw.slice(0, 3))}).`,
    );
    throw new Error(
      `FCM_SERVICE_ACCOUNT_JSON secret is malformed (len=${raw.length}, record=${isRecord(parsed)}).`,
    );
  }

  const privateKey = parsed.private_key
    .replace(/\\r\\n/g, "\n")
    .replace(/\\n/g, "\n")
    .replace(/\r/g, "");

  const tokenUri =
    typeof parsed.token_uri === "string" && parsed.token_uri.trim().length > 0
      ? parsed.token_uri.trim()
      : undefined;

  return {
    project_id: typeof parsed.project_id === "string"
      ? parsed.project_id
      : undefined,
    client_email: parsed.client_email.trim(),
    private_key: privateKey,
    token_uri: tokenUri,
  };
}

// Cached for the lifetime of a single function invocation.
let cachedAccessToken: {value: string; exp: number} | null = null;

async function getAccessToken(serviceAccount: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedAccessToken && cachedAccessToken.exp - 60 > now) {
    return cachedAccessToken.value;
  }

  const tokenUrl =
    serviceAccount.token_uri ?? "https://oauth2.googleapis.com/token";

  const header = {alg: "RS256", typ: "JWT"};
  const claims = {
    iss: serviceAccount.client_email,
    scope: FCM_SCOPE,
    aud: tokenUrl,
    iat: now,
    exp: now + 3600,
  };
  const unsignedJwt = `${base64Url(JSON.stringify(header))}.${
    base64Url(JSON.stringify(claims))
  }`;

  const key = await importPrivateKey(serviceAccount.private_key);
  let signature: ArrayBuffer;
  try {
    signature = await crypto.subtle.sign(
      "RSASSA-PKCS1-v1_5",
      key,
      new TextEncoder().encode(unsignedJwt),
    );
  } catch (signError) {
    throw new Error(
      `JWT signing failed (${signError instanceof Error ? signError.message : String(signError)}).`,
    );
  }
  const jwt = `${unsignedJwt}.${base64UrlBytes(new Uint8Array(signature))}`;

  const response = await fetch(tokenUrl, {
    method: "POST",
    headers: {"Content-Type": "application/x-www-form-urlencoded"},
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  if (!response.ok) {
    let errorDetail = "";
    try {
      const errJson = await response.json();
      if (isRecord(errJson)) {
        const desc = typeof errJson.error_description === "string"
          ? errJson.error_description
          : "";
        const err = typeof errJson.error === "string" ? errJson.error : "";
        errorDetail = err && desc ? `${err}: ${desc}` : (err || desc || JSON.stringify(errJson));
      }
    } catch {
      // keep empty if body is unparseable
    }
    throw new Error(
      `FCM OAuth2 token request failed (${response.status}${errorDetail ? `: ${errorDetail}` : ""}).`,
    );
  }

  const tokenJson = await response.json();
  if (!isRecord(tokenJson) || typeof tokenJson.access_token !== "string") {
    throw new Error("FCM OAuth2 token response was malformed.");
  }

  const expiresIn = typeof tokenJson.expires_in === "number"
    ? tokenJson.expires_in
    : 3600;
  cachedAccessToken = {value: tokenJson.access_token, exp: now + expiresIn};
  return cachedAccessToken.value;
}

// ---------------------------------------------------------------------------
// FCM delivery (one HTTP v1 request per token; FCM HTTP v1 has no multicast).
// ---------------------------------------------------------------------------

function buildFcmMessage(
  notification: NotificationRow,
): Record<string, unknown> {
  return {
    notification: {
      title: notification.title,
      body: notification.body,
    },
    data: {
      type: notification.type,
      bookingId: notification.booking_id ?? "",
      recipientId: notification.recipient_id,
    },
    android: {
      priority: "high",
      collapse_key: notification.id.slice(0, 64),
      notification: {
        channel_id: DEFAULT_CHANNEL_ID,
        sound: "default",
      },
    },
    apns: {
      headers: {"apns-collapse-id": notification.id.slice(0, 64)},
      payload: {aps: {sound: "default"}},
    },
  };
}

async function mapWithConcurrency<T, R>(
  items: T[],
  limit: number,
  fn: (item: T, index: number) => Promise<R>,
): Promise<R[]> {
  const results: R[] = new Array(items.length);
  let cursor = 0;
  const workerCount = Math.max(1, Math.min(limit, items.length));
  const workers = Array.from({length: workerCount}, async () => {
    while (cursor < items.length) {
      const index = cursor++;
      results[index] = await fn(items[index], index);
    }
  });
  await Promise.all(workers);
  return results;
}

type SendResult = {ok: boolean; invalid: boolean; code: string};

async function sendToToken(
  serviceAccount: ServiceAccount,
  accessToken: string,
  message: Record<string, unknown>,
  token: string,
): Promise<SendResult> {
  const projectId = serviceAccount.project_id ??
    Deno.env.get("FCM_PROJECT_ID") ??
    FALLBACK_FCM_PROJECT_ID;
  const url = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

  let response: Response;
  try {
    response = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${accessToken}`,
      },
      body: JSON.stringify({message: {...message, token}}),
    });
  } catch {
    return {ok: false, invalid: false, code: "network"};
  }

  if (response.ok) {
    return {ok: true, invalid: false, code: "ok"};
  }

  let code = `http_${response.status}`;
  try {
    const body = await response.json();
    const error = isRecord(body) ? body.error : undefined;
    if (isRecord(error)) {
      const details = Array.isArray(error.details) ? error.details : [];
      const fcmError = details.find((detail: unknown) =>
        isRecord(detail) &&
        String(detail["@type"] ?? "").includes("google.firebase.fcm.v1.FcmError")
      );
      const fcmCode = isRecord(fcmError) ? fcmError.errorCode : undefined;
      if (typeof fcmCode === "string") {
        code = fcmCode;
      } else if (typeof error.status === "string") {
        code = error.status;
      }
    }
  } catch {
    // Keep the http_<status> code if the body cannot be parsed.
  }

  return {ok: false, invalid: INVALID_TOKEN_CODES.has(code), code};
}

async function deliverNotification(
  notification: NotificationRow,
  serviceAccount: ServiceAccount,
): Promise<void> {
  const tokens = notification.push_pending_tokens.length > 0
    ? notification.push_pending_tokens
    : await loadDeviceTokens(notification.recipient_id);

  if (tokens.length === 0) {
    await updatePushState(notification, "skipped", "no registered devices");
    return;
  }

  if (notification.push_pending_tokens.length === 0) {
    await storePendingTokens(notification, tokens);
    notification.push_pending_tokens = tokens;
  }

  const accessToken = await getAccessToken(serviceAccount);
  const message = buildFcmMessage(notification);

  // FCM HTTP v1 sends one message per token (no multicast endpoint), so the
  // legacy 500-token multicast batch becomes bounded-concurrency per-token
  // sends. 500 mirrors the previous maximum batch size.
  const results = await mapWithConcurrency(tokens, 500, (token) =>
    sendToToken(serviceAccount, accessToken, message, token));

  const retryTokens: string[] = [];
  const invalidTokens: string[] = [];
  const failureCodes = new Set<string>();
  let successCount = 0;

  results.forEach((result, index) => {
    if (result.ok) {
      successCount++;
      return;
    }
    failureCodes.add(result.code);
    if (result.invalid) {
      invalidTokens.push(tokens[index]);
    } else {
      retryTokens.push(tokens[index]);
    }
  });

  for (const token of invalidTokens) {
    await deleteInvalidToken(token);
  }

  if (retryTokens.length > 0) {
    const summary = [...failureCodes].join(", ") ||
      "FCM returned no successful deliveries";
    await retryOrFail(notification, summary, retryTokens);
    return;
  }

  if (successCount > 0) {
    const failureSummary = [...failureCodes].join(", ").slice(0, 500);
    await updatePushState(
      notification,
      "sent",
      failureSummary.length > 0 ? failureSummary : null,
    );
    if (failureCodes.size > 0) {
      console.warn(
        `Some device deliveries failed for notification ${notification.id}.`,
      );
    }
    return;
  }

  await updatePushState(
    notification,
    "skipped",
    [...failureCodes].join(", ").slice(0, 500) || "No valid device tokens",
  );
}


// ---------------------------------------------------------------------------
// Dispatcher (mirrors the former onSchedule body).
// ---------------------------------------------------------------------------

async function runDispatch(): Promise<{dispatched: number}> {
  try {
    await supabaseRequest("rpc/create_due_appointment_reminders", {
      method: "POST",
      body: "{}",
    });
  } catch (error) {
    console.error("Could not enqueue due appointment reminders:", error);
  }

  const claimed = await supabaseRequest("rpc/claim_notification_pushes", {
    method: "POST",
    body: JSON.stringify({p_limit: 100}),
  });

  const notifications = parseNotificationRows(claimed);

  // Cache the parsed credentials, but parse inside each notification's
  // recovery scope so a malformed secret cannot strand the claimed batch.
  let serviceAccount: ServiceAccount | null = null;

  for (const notification of notifications) {
    try {
      serviceAccount ??= parseServiceAccount();
      await deliverNotification(notification, serviceAccount);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      console.error(
        `Recovering notification ${notification.id} after a dispatcher error:`,
        errorMsg,
      );
      try {
        // Keep the normal attempt limit and backoff for failures outside the
        // per-token FCM result path (token loading, OAuth, or persistence).
        await retryOrFail(
          notification,
          `dispatcher_error: ${errorMsg}`.slice(0, 500),
          notification.push_pending_tokens,
        );
      } catch (recoveryError) {
        // If Supabase itself is unavailable, stale-claim recovery remains the
        // final safety net in claim_notification_pushes.
        console.error(
          `Could not recover claimed notification ${notification.id}:`,
          recoveryError,
        );
      }
    }
  }

  return {dispatched: notifications.length};
}

// ---------------------------------------------------------------------------
// Authenticated HTTP entrypoint invoked by pg_cron/pg_net every minute.
// ---------------------------------------------------------------------------

function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) {
    return false;
  }
  let mismatch = 0;
  for (let i = 0; i < a.length; i++) {
    mismatch |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return mismatch === 0;
}

// The expected shared secret lives in Supabase Vault (single source of truth,
// never committed). It is exposed to service_role only through a security
// definer RPC. pg_net reads the same Vault secret and sends it as the Bearer
// token, so the scheduled call is authenticated without any public endpoint.
async function fetchExpectedDispatchSecret(): Promise<string | null> {
  const result = await supabaseRequest("rpc/get_dispatch_secret", {
    method: "POST",
    body: "{}",
  });
  return typeof result === "string" ? result : null;
}

async function isAuthorized(request: Request): Promise<boolean> {
  const expected = await fetchExpectedDispatchSecret();
  if (!expected) {
    return false;
  }
  const header = request.headers.get("authorization") ?? "";
  const token = header.startsWith("Bearer ") ? header.slice(7) : "";
  return timingSafeEqual(token, expected);
}

Deno.serve(async (request: Request): Promise<Response> => {
  try {
    if (!(await isAuthorized(request))) {
      return new Response(JSON.stringify({error: "unauthorized"}), {
        status: 401,
        headers: {"Content-Type": "application/json"},
      });
    }
  } catch (error) {
    console.error("Authorization check failed:", error);
    return new Response(JSON.stringify({error: "unauthorized"}), {
      status: 401,
      headers: {"Content-Type": "application/json"},
    });
  }

  try {
    const result = await runDispatch();
    return new Response(JSON.stringify({ok: true, ...result}), {
      status: 200,
      headers: {"Content-Type": "application/json"},
    });
  } catch (error) {
    // Do not log secrets; the error message never includes credentials.
    console.error("Dispatch failed:", error);
    return new Response(JSON.stringify({error: "dispatch failed"}), {
      status: 500,
      headers: {"Content-Type": "application/json"},
    });
  }
});



