// @ts-ignore
declare const Deno: any;

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'

Deno.serve(async (req: Request) => {
  // CORS 처리
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS', //추가됨: Flutter/Web 통신 안정성 확보
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      },
    })
  }

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) throw new Error('No authorization header')
    
    // ✨ 개선됨: replace 대신 split 사용 (공백 등 예외 상황에 더 안전)
    const token = authHeader.split(' ')[1]

    const userSupabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!
    )

    const { data: { user }, error: userError } = await userSupabase.auth.getUser(token)
    if (userError || !user) {
      throw new Error(`Invalid token or user not found: ${userError?.message || 'Unknown'}`)
    }

    let payload: { reason?: string } = {}
    try {
      payload = await req.json()
    } catch {
      payload = {}
    }
    const reason = (payload?.reason && String(payload.reason).trim()) ? String(payload.reason).trim() : '기타'

    // ✨ Admin 클라이언트 생성
    const adminSupabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    const email = user.email ?? null
    const provider = (user.app_metadata?.provider as string) ?? 'unknown'

    // 탈퇴 로그 기록
    await adminSupabase.from('account_deletion_logs').insert({
      user_id: user.id,
      email,
      provider,
      reason,
    })

    // 유저 삭제 (Auth)
    const { error: deleteError } = await adminSupabase.auth.admin.deleteUser(user.id)
    if (deleteError) throw deleteError

    return new Response(JSON.stringify({ success: true, message: 'Account deleted successfully' }), {
      headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
      status: 200,
    })

  } catch (error: any) {
    return new Response(JSON.stringify({ success: false, error: error.message }), {
      headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
      status: 400,
    })
  }
})