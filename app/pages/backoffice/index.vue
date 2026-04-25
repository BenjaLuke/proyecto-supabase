<template>
  <main class="backoffice">
    <header>
      <h1>Backoffice</h1>
      <button @click="logout">Cerrar sesión</button>
    </header>

    <section class="card">
      <h2>Bienvenido</h2>
      <p>Has accedido correctamente al gestor de contenidos.</p>

      <NuxtLink class="menu-link" to="/backoffice/categories">
        Gestionar categorías
      </NuxtLink>

      <NuxtLink class="menu-link" to="/backoffice/products">
        Gestionar productos
      </NuxtLink>

    </section>
  </main>
</template>

<script setup>
import { onMounted } from 'vue'
import { createClient } from '@supabase/supabase-js'

const config = useRuntimeConfig()

const supabase = createClient(
  config.public.supabaseUrl,
  config.public.supabaseKey
)

onMounted(async () => {
  const { data } = await supabase.auth.getSession()

  if (!data.session) {
    await navigateTo('/login')
  }
})

async function logout() {
  await supabase.auth.signOut()
  await navigateTo('/login')
}
</script>

<style scoped>
.backoffice {
  min-height: 100vh;
  background: #f8fafc;
  font-family: Arial, sans-serif;
  padding: 32px;
}

header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

button {
  padding: 10px 16px;
  border: 0;
  background: #dc2626;
  color: white;
  border-radius: 8px;
  cursor: pointer;
}

.card {
  margin-top: 32px;
  background: white;
  padding: 24px;
  border-radius: 14px;
  box-shadow: 0 8px 24px rgba(0,0,0,.08);
}

.menu-link {
  display: inline-block;
  margin-top: 20px;
  margin-right: 10px;
  padding: 12px 16px;
  background: #2563eb;
  color: white;
  border-radius: 8px;
  text-decoration: none;
}
</style>