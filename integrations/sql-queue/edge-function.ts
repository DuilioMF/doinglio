import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const url = Deno.env.get("SUPABASE_URL") || "";
const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";
const n8nToken = Deno.env.get("DOINGLIO_SQL_N8N_TOKEN") || "";
const workerToken = Deno.env.get("DOINGLIO_SQL_WORKER_TOKEN") || "";
const db = createClient(url, serviceKey, { auth: { persistSession: false } });
const json = (data: unknown, status = 200) => new Response(JSON.stringify(data), { status, headers: { "content-type": "application/json", "cache-control": "no-store" } });
const fail = (error: string, status = 400) => json({ ok: false, error }, status);
const validUuid = (s: unknown) => typeof s === "string" && /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(s);
async function equals(a: string, b: string) {
  if (!a || !b) return false;
  const [x, y] = await Promise.all([crypto.subtle.digest("SHA-256", new TextEncoder().encode(a)), crypto.subtle.digest("SHA-256", new TextEncoder().encode(b))]);
  const xa = new Uint8Array(x), ya = new Uint8Array(y);
  let mismatch = xa.length ^ ya.length;
  for (let i = 0; i < xa.length; i++) mismatch |= xa[i] ^ ya[i];
  return mismatch === 0;
}
function hasAccess(row: any, station: number) {
  const validPayment = row?.payment_exempt === true || (!!row?.paid_until && Date.parse(row.paid_until) > Date.now());
  const stations = Array.isArray(row?.station_ids) ? row.station_ids.map(Number) : [];
  return row?.enabled === true && validPayment && stations.includes(station);
}
async function permitted(phone: string, station: number) {
  const { data, error } = await db.from("doinglio_phone_access")
    .select("enabled,payment_exempt,paid_until,station_ids")
    .eq("phone_e164", phone).eq("specialist_key", "capitan-rodolfo").maybeSingle();
  if (error) throw new Error("ACCESS_LOOKUP_FAILED");
  return hasAccess(data, station);
}
Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return fail("POST_REQUIRED", 405);
  if (!n8nToken || !workerToken || !serviceKey) return fail("NOT_CONFIGURED", 503);
  const supplied = req.headers.get("x-doinglio-token") || "";
  const [isN8n, isWorker] = await Promise.all([equals(supplied, n8nToken), equals(supplied, workerToken)]);
  if (!isN8n && !isWorker) return fail("UNAUTHORIZED", 401);
  let body: any;
  try { body = await req.json(); } catch { return fail("INVALID_JSON"); }
  const action = String(body?.action || "");
  try {
    if (action === "health") return json({ok:true, configured:true, role:isWorker?"worker":"n8n"});
    if (action === "enqueue") {
      if (!isN8n) return fail("FORBIDDEN",403);
      const phone = String(body.phone || "").replace(/[^0-9]/g, "");
      const waId = String(body.wa_message_id || "").trim();
      const question = String(body.question || "").trim().slice(0,1000);
      const station = Number(body.idEstacion);
      if (!/^\d{8,16}$/.test(phone) || !waId || waId.length > 250 || !question || !Number.isSafeInteger(station) || station<=0)
        return fail("INVALID_INPUT");
      if (String(body.intent) !== "station_circuit") return fail("INTENT_NOT_ALLOWED",403);
      if (!(await permitted(phone, station))) return fail("PHONE_OR_STATION_NOT_AUTHORIZED",403);
      const existing = await db.from("doinglio_sql_question_queue").select("id,status").eq("wa_message_id",waId).eq("specialist_key","capitan-rodolfo").maybeSingle();
      if (existing.error) throw new Error("QUEUE_LOOKUP_FAILED");
      if (existing.data) return json({ok:true,id:existing.data.id,status:existing.data.status,duplicate:true});
      const {data,error} = await db.from("doinglio_sql_question_queue").insert({
        wa_message_id:waId,phone_e164:phone,specialist_key:"capitan-rodolfo",
        question,intent:"station_circuit",result_metadata:{idEstacion:station,source:"n8n"}
      }).select("id,status").single();
      if (error && error.code === "23505") {
        const again = await db.from("doinglio_sql_question_queue").select("id,status").eq("wa_message_id",waId).eq("specialist_key","capitan-rodolfo").single();
        if (!again.error) return json({ok:true,...again.data,duplicate:true});
      }
      if (error) throw new Error("ENQUEUE_FAILED");
      return json({ok:true,id:data.id,status:data.status});
    }
    if (action === "claim") {
      if (!isWorker) return fail("FORBIDDEN",403);
      const {data,error} = await db.rpc("doinglio_sql_claim_next");
      if(error) throw new Error("CLAIM_FAILED");
      for(const job of (data||[])){
        const station=Number(job.result_metadata?.idEstacion);
        if (!Number.isSafeInteger(station) || !(await permitted(job.phone_e164,station))) {
          await db.from("doinglio_sql_question_queue").update({status:"failed",completed_at:new Date().toISOString(),reply_text:"Acceso no autorizado o estación no permitida."}).eq("id",job.id).eq("status","processing");
          continue;
        }
        return json({ok:true,job:{id:job.id,intent:job.intent,idEstacion:station}});
      }
      return json({ok:true,job:null});
    }
    if (action === "complete") {
      if (!isWorker) return fail("FORBIDDEN",403);
      if (!validUuid(body.id)) return fail("INVALID_ID");
      const ok = body.ok === true;
      const reply = String(body.reply_text || "").trim().slice(0,3500);
      if (!reply) return fail("REPLY_REQUIRED");
      const metadata = body.summary && typeof body.summary==="object" && !Array.isArray(body.summary) ? body.summary : {};
      const sanitized:any={};
      for (const k of ["idEstacion","tanks","hoses","dispatches","receipts","source"]) {
        if(k in metadata && (typeof metadata[k]==="string" || typeof metadata[k]==="number")) sanitized[k]=metadata[k];
      }
      const {data,error}=await db.from("doinglio_sql_question_queue")
        .update({status:ok?"completed":"failed",reply_text:reply,completed_at:new Date().toISOString(),
          result_metadata:sanitized})
        .eq("id",body.id).eq("status","processing").select("id").maybeSingle();
      if(error) throw new Error("COMPLETE_FAILED");
      if(!data) return fail("JOB_NOT_CLAIMED",409);
      return json({ok:true,id:data.id});
    }
    if (action === "result") {
      if (!isN8n) return fail("FORBIDDEN",403);
      if (!validUuid(body.id)) return fail("INVALID_ID");
      const {data,error}=await db.from("doinglio_sql_question_queue")
        .select("id,status,reply_text,result_metadata,completed_at").eq("id",body.id).maybeSingle();
      if(error) throw new Error("RESULT_FAILED");
      if(!data) return fail("NOT_FOUND",404);
      return json({ok:true,...data});
    }
    return fail("UNKNOWN_ACTION");
  } catch(e) {
    console.error("doinglio-sql-queue error:", String(e).replace(/\d{8,}/g,"[redacted]"));
    return fail("INTERNAL_ERROR",500);
  }
});
