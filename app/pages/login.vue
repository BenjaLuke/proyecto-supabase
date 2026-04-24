<template>
  <main class="login-page">
    <section class="login-box">
      <h1>Acceso backoffice</h1>

      <form @submit.prevent="login">
        <label>Email</label>
        <input v-model="email" type="email" required>

        <label>Contraseña</label>
        <input v-model="password" type="password" required>

        <button type="submit">Entrar</button>
      </form>

      <p v-if="error" class="error">{{ error }}</p>
    </section>
  </main>
</template>

<script setup>
import { ref } from 'vue'
import { createClient } from '@supabase/supabase-js'

const email = ref('')
const password = ref('')
const error = ref('')

const config = useRuntimeConfig()

const supabase = createClient(
  config.public.supabaseUrl,
  config.public.supabaseKey
)

async function login() {
  error.value = ''

  const { error: loginError } = await supabase.auth.signInWithPassword({
    email: email.value,
    password: password.value
  })

  if (loginError) {
    error.value = loginError.message
    return
  }

  await navigateTo('/backoffice')
}
</script>

<style scoped>
.login-page {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #eef2f7;
  font-family: Arial, sans-serif;
}

.login-box {
  width: 360px;
  background: white;
  padding: 32px;
  border-radius: 14px;
  box-shadow: 0 10px 30px rgba(0,0,0,.12);
}

h1 {
  margin-bottom: 24px;
}

label {
  display: block;
  margin-top: 14px;
  font-weight: bold;
}

input {
  width: 100%;
  padding: 10px;
  margin-top: 6px;
  box-sizing: border-box;
}

button {
  width: 100%;
  margin-top: 22px;
  padding: 12px;
  border: 0;
  background: #2563eb;
  color: white;
  font-weight: bold;
  cursor: pointer;
  border-radius: 8px;
}

.error {
  margin-top: 16px;
  color: #dc2626;
}
</style>