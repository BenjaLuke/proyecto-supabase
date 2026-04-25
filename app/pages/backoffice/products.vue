<template>
  <main class="page">
    <header>
      <div>
        <h1>Productos</h1>
        <p>Gestión de productos y categorías asociadas</p>
      </div>

      <NuxtLink to="/backoffice">Volver</NuxtLink>
    </header>

    <section class="card">
      <h2>{{ editingId ? 'Editar producto' : 'Nuevo producto' }}</h2>

      <form @submit.prevent="saveProduct">
        <label>Código</label>
        <input v-model="form.code" required>

        <label>Nombre</label>
        <input v-model="form.name" required>

        <label>Descripción</label>
        <textarea v-model="form.description"></textarea>

        <label>Categorías</label>
        <div class="checkbox-list">
          <label
            v-for="category in categories"
            :key="category.id"
            class="checkbox-item"
          >
            <input
              type="checkbox"
              :value="category.id"
              v-model="selectedCategories"
            >
            {{ category.name }}
          </label>
        </div>

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
      <h2>Listado de productos</h2>

      <p v-if="loading">Cargando productos...</p>

      <table v-else>
        <thead>
          <tr>
            <th>Código</th>
            <th>Nombre</th>
            <th>Descripción</th>
            <th>Categorías</th>
            <th>Acciones</th>
          </tr>
        </thead>

        <tbody>
          <tr v-for="product in products" :key="product.id">
            <td>{{ product.code }}</td>
            <td>{{ product.name }}</td>
            <td>{{ product.description }}</td>
            <td>{{ getProductCategories(product.id) }}</td>
            <td>
              <button class="small" @click="editProduct(product)">
                Editar
              </button>
              <button class="small danger" @click="deleteProduct(product.id)">
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
import { ref, onMounted } from 'vue'
import { createClient } from '@supabase/supabase-js'

const config = useRuntimeConfig()

const supabase = createClient(
  config.public.supabaseUrl,
  config.public.supabaseKey
)

const products = ref([])
const categories = ref([])
const productCategories = ref([])

const loading = ref(true)
const error = ref('')
const success = ref('')
const editingId = ref(null)
const selectedCategories = ref([])

const form = ref({
  code: '',
  name: '',
  description: ''
})

onMounted(async () => {
  await checkSession()
  await loadAll()
})

async function checkSession() {
  const { data } = await supabase.auth.getSession()

  if (!data.session) {
    await navigateTo('/login')
  }
}

async function loadAll() {
  loading.value = true
  error.value = ''

  await Promise.all([
    loadProducts(),
    loadCategories(),
    loadProductCategories()
  ])

  loading.value = false
}

async function loadProducts() {
  const { data, error: loadError } = await supabase
    .from('products')
    .select('*')
    .order('name', { ascending: true })

  if (loadError) {
    error.value = loadError.message
    return
  }

  products.value = data
}

async function loadCategories() {
  const { data, error: loadError } = await supabase
    .from('categories')
    .select('*')
    .order('name', { ascending: true })

  if (loadError) {
    error.value = loadError.message
    return
  }

  categories.value = data
}

async function loadProductCategories() {
  const { data, error: loadError } = await supabase
    .from('product_categories')
    .select('*')

  if (loadError) {
    error.value = loadError.message
    return
  }

  productCategories.value = data
}

async function saveProduct() {
  error.value = ''
  success.value = ''

  const payload = {
    code: form.value.code,
    name: form.value.name,
    description: form.value.description
  }

  let productId = editingId.value

  if (editingId.value) {
    const { error: updateError } = await supabase
      .from('products')
      .update(payload)
      .eq('id', editingId.value)

    if (updateError) {
      error.value = updateError.message
      return
    }
  } else {
    const { data, error: insertError } = await supabase
      .from('products')
      .insert(payload)
      .select()
      .single()

    if (insertError) {
      error.value = insertError.message
      return
    }

    productId = data.id
  }

  await saveProductCategories(productId)

  success.value = editingId.value
    ? 'Producto actualizado correctamente.'
    : 'Producto creado correctamente.'

  resetForm()
  await loadAll()
}

async function saveProductCategories(productId) {
  const { error: deleteError } = await supabase
    .from('product_categories')
    .delete()
    .eq('product_id', productId)

  if (deleteError) {
    error.value = deleteError.message
    return
  }

  if (selectedCategories.value.length === 0) {
    return
  }

  const rows = selectedCategories.value.map(categoryId => ({
    product_id: productId,
    category_id: categoryId
  }))

  const { error: insertError } = await supabase
    .from('product_categories')
    .insert(rows)

  if (insertError) {
    error.value = insertError.message
  }
}

function editProduct(product) {
  editingId.value = product.id

  form.value = {
    code: product.code,
    name: product.name,
    description: product.description
  }

  selectedCategories.value = productCategories.value
    .filter(row => row.product_id === product.id)
    .map(row => row.category_id)
}

async function deleteProduct(id) {
  const confirmed = confirm('¿Seguro que quieres eliminar este producto?')

  if (!confirmed) {
    return
  }

  error.value = ''
  success.value = ''

  const { error: deleteError } = await supabase
    .from('products')
    .delete()
    .eq('id', id)

  if (deleteError) {
    error.value = deleteError.message
    return
  }

  success.value = 'Producto eliminado correctamente.'
  await loadAll()
}

function resetForm() {
  editingId.value = null

  form.value = {
    code: '',
    name: '',
    description: ''
  }

  selectedCategories.value = []
}

function getProductCategories(productId) {
  const categoryIds = productCategories.value
    .filter(row => row.product_id === productId)
    .map(row => row.category_id)

  const names = categories.value
    .filter(category => categoryIds.includes(category.id))
    .map(category => category.name)

  return names.length ? names.join(', ') : '-'
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
textarea {
  width: 100%;
  padding: 10px;
  margin-top: 6px;
  box-sizing: border-box;
}

textarea {
  min-height: 80px;
}

.checkbox-list {
  margin-top: 8px;
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
}

.checkbox-item {
  display: flex;
  align-items: center;
  gap: 6px;
  background: #f1f5f9;
  padding: 8px 10px;
  border-radius: 8px;
  font-weight: normal;
}

.checkbox-item input {
  width: auto;
  margin: 0;
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