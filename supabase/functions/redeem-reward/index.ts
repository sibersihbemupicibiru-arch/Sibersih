import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight request
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Missing Authorization header' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // 1. Initialize Supabase client using Service Role Key to safely update data
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // 2. Identify the user making the request
    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabase.auth.getUser(token)
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Invalid or expired token' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // 3. Parse request body
    const body = await req.json().catch(() => ({}))
    const rewardId = body.reward_id
    if (!rewardId) {
      return new Response(JSON.stringify({ error: 'Missing reward_id' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // 4. Fetch reward details from reward_items table
    const { data: reward, error: rewardError } = await supabase
      .from('reward_items')
      .select('name, points, icon')
      .eq('id', rewardId)
      .single()

    if (rewardError || !reward) {
      return new Response(JSON.stringify({ error: 'Reward item tidak ditemukan' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const rewardPoints = reward.points
    const rewardName = reward.name
    const rewardIcon = reward.icon ?? '🎁'

    // 5. Fetch user's current points
    const { data: userData, error: userError } = await supabase
      .from('users')
      .select('total_poin, poin_keluar')
      .eq('id', user.id)
      .single()

    if (userError || !userData) {
      return new Response(JSON.stringify({ error: 'User data tidak ditemukan' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const currentPoin = userData.total_poin ?? 0
    const currentKeluar = userData.poin_keluar ?? 0

    // 6. Validate if user has enough points
    if (currentPoin < rewardPoints) {
      return new Response(JSON.stringify({ error: 'Poin tidak mencukupi' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // 7. Update user points (deduct total_poin and add to poin_keluar)
    const { error: updateError } = await supabase
      .from('users')
      .update({
        total_poin: currentPoin - rewardPoints,
        poin_keluar: currentKeluar + rewardPoints,
      })
      .eq('id', user.id)

    if (updateError) {
      throw new Error(`Gagal memotong poin: ${updateError.message}`)
    }

    // 8. Log the redemption in poin_history table
    const { error: historyError } = await supabase
      .from('poin_history')
      .insert({
        user_id: user.id,
        type: 'keluar',
        icon: rewardIcon,
        title: `Tukar: ${rewardName}`,
        poin: rewardPoints,
        tanggal: new Date().toISOString(),
      })

    if (historyError) {
      throw new Error(`Gagal mencatat riwayat poin: ${historyError.message}`)
    }

    return new Response(JSON.stringify({ 
      success: true, 
      reward_name: rewardName, 
      points_deducted: rewardPoints 
    }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
