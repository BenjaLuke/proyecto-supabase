<template>
  <main class="page">
    <header>
      <div>
        <h1>Categorías</h1>
        <p>Gestión de categorías de productos</p>
      </div>

      <NuxtLink to="/backoffice">Volver</NuxtLink>
    </header>

    <section class="card">
      <h2>{{ editingId ? 'Editar categoría' : 'Nueva categoría' }}</h2>

      <form @submit.prevent="saveCategory">
        <label>Código</label>
        <input v-model="form.code" required>

        <label>Nombre</label>
        <input v-model="form.name" required>

        <label>Descripción</label>
        <textarea v-model="form.description"></textarea>

        <label>Categoría padre</label>
        <select v-model="form.parent_id">
          <option :value="null">Sin categoría padre</option>
          <option
            v-for="category in parentOptions"
            :key="category.id"
            :value="category.id"
          >
            {{ category.name }}
          </option>
        </select>

        <div class="actions">
          <button type="submit">
            {{ editingId ? 'Actualizar' : 'Crear' }}
          </button>

          <button
            v-if="editingId"
            type="button"
            class="secondary"
            @click="resetForm"
          >
            Cancelar
          </button>
        </div>
      </form>

      <p v-if="error" class="error">{{ error }}</p>
      <p v-if="success" class="success">{{ success }}</p>
    </section>

    <section class="card">
      <h2>Listado de categorías</h2>

      <p v-if="loading">Cargando categorías...</p>

      <table v-else>
        <thead>
          <tr>
            <th>Código</th>
            <th>Nombre</th>
            <th>Padre</th>
            <th>Descripción</th>
            <th>Acciones</th>
          </tr>
        </thead>

        <tbody>
          <tr v-for="category in categories" :key="category.id">
            <td>{{ category.code }}</td>
            <td>{{ category.name }}</td>
            <td>{{ getParentName(category.parent_id) }}</td>
            <td>{{ category.description }}</td>
            <td>
              <button class="small" @click="editCategory(category)">
                Editar
              </button>
              <button class="small danger" @click="deleteCategory(category.id)">
                Eliminar
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </section>
  </main>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { createClient } from '@supabase/supabase-js'

const config = useRuntimeConfig()

const supabase = createClient(
  config.public.supabaseUrl,
  config.public.supabaseKey
)

const categories = ref([])
const loading = ref(true)
const error = ref('')
const success = ref('')
const editingId = ref(null)

const form = ref({
  code: '',
  name: '',
  description: '',
  parent_id: null
})

const parentOptions = computed(() => {
  return categories.value.filter(category => category.id !== editingId.value)
})

onMounted(async () => {
  await checkSession()
  await loadCategories()
})

async function checkSession() {
  const { data } = await supabase.auth.getSession()

  if (!data.session) {
    await navigateTo('/login')
  }
}

async function loadCategories() {
  loading.value = true
  error.value = ''

  const { data, error: loadError } = await supabase
    .from('categories')
    .select('*')
    .order('name', { ascending: true })

  if (loadError) {
    error.value = loadError.message
  } else {
    categories.value = data
  }

  loading.value = false
}

async function saveCategory() {
  error.value = ''
  success.value = ''

  const payload = {
    code: form.value.code,
    name: form.value.name,
    description: form.value.description,
    parent_id: form.value.parent_id || null
  }

  if (editingId.value) {
    const { error: updateError } = await supabase
      .from('categories')
      .update(payload)
      .eq('id', editingId.value)

    if (updateError) {
      error.value = updateError.message
      return
    }

    success.value = 'Categoría actualizada correctamente.'
  } else {
    const { error: insertError } = await supabase
      .from('categories')
      .insert(payload)

    if (insertError) {
      error.value = insertError.message
      return
    }

    success.value = 'Categoría creada correctamente.'
  }

  resetForm()
  await loadCategories()
}

function editCategory(category) {
  editingId.value = category.id

  form.value = {
    code: category.code,
    name: category.name,
    description: category.description,
    parent_id: category.parent_id
  }
}

async function deleteCategory(id) {
  const confirmed = confirm('¿Seguro que quieres eliminar esta categoría?')

  if (!confirmed) {
    return
  }

  error.value = ''
  success.value = ''

  const { error: deleteError } = await supabase
    .from('categories')
    .delete()
    .eq('id', id)

  if (deleteError) {
    error.value = deleteError.message
    return
  }

  success.value = 'Categoría eliminada correctamente.'
  await loadCategories()
}

function resetForm() {
  editingId.value = null

  form.value = {
    code: '',
    name: '',
    description: '',
    parent_id: null
  }
}

function getParentName(parentId) {
  if (!parentId) {
    return '-'
  }

  const parent = categories.value.find(category => category.id === parentId)

  return parent ? parent.name : '-'
}
</script>

<style scoped>
.page {
  min-height: 100vh;
  background: #f8fafc;
  font-family: Arial, sans-serif;
  padding: 32px;
}

header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
}

h1 {
  margin: 0;
}

p {
  color: #64748b;
}

a {
  background: #334155;
  color: white;
  padding: 10px 16px;
  border-radius: 8px;
  text-decoration: none;
}

.card {
  background: white;
  padding: 24px;
  border-radius: 14px;
  box-shadow: 0 8px 24px rgba(0,0,0,.08);
  margin-bottom: 24px;
}

label {
  display: block;
  margin-top: 14px;
  font-weight: bold;
}

input,
textarea,
select {
  width: 100%;
  padding: 10px;
  margin-top: 6px;
  box-sizing: border-box;
}

textarea {
  min-height: 80px;
}

.actions {
  display: flex;
  gap: 10px;
  margin-top: 18px;
}

button {
  padding: 10px 16px;
  border: 0;
  background: #2563eb;
  color: white;
  border-radius: 8px;
  cursor: pointer;
}

button.secondary {
  background: #64748b;
}

button.small {
  padding: 7px 10px;
  margin-right: 6px;
  font-size: 13px;
}

button.danger {
  background: #dc2626;
}

.error {
  color: #dc2626;
  margin-top: 16px;
}

.success {
  color: #16a34a;
  margin-top: 16px;
}

table {
  width: 100%;
  border-collapse: collapse;
}

th,
td {
  padding: 10px;
  border-bottom: 1px solid #e2e8f0;
  text-align: left;
}

th {
  background: #f1f5f9;
}
</style>