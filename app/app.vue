<template>
  <main style="font-family: Arial; padding: 40px;">
    <h1>Proyecto Supabase</h1>

    <p v-if="loading">Comprobando conexión con Supabase...</p>

    <p v-else-if="error" style="color: red;">
      Error de conexión: {{ error }}
    </p>

    <p v-else style="color: green;">
      Conexión correcta con Supabase.
    </p>
  </main>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { createClient } from '@supabase/supabase-js'

const loading = ref(true)
const error = ref(null)

onMounted(async () => {
  try {
    const config = useRuntimeConfig()

    const supabase = createClient(
      config.public.supabaseUrl,
      config.public.supabaseKey
    )

    const { error: supabaseError } = await supabase
      .from('categories')
      .select('*')
      .limit(1)

    if (supabaseError) {
      error.value = supabaseError.message
    }
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
  }
})
</script>
