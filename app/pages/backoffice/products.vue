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
    <h2>Nueva tarifa</h2>

    <form @submit.prevent="saveRate">
        <label>Producto</label>
        <select v-model="rateForm.product_id" required>
        <option value="">Selecciona un producto</option>
        <option
            v-for="product in products"
            :key="product.id"
            :value="product.id"
        >
            {{ product.name }}
        </option>
        </select>

        <label>Fecha inicio</label>
        <input v-model="rateForm.start_date" type="date" required>

        <label>Fecha fin</label>
        <input v-model="rateForm.end_date" type="date">

        <label>Precio</label>
        <input v-model="rateForm.price" type="number" step="0.01" required>

        <div class="actions">
        <button type="submit">Crear tarifa</button>
        </div>
    </form>
    </section>

    <section class="card">
    <h2>Nueva imagen</h2>

    <form @submit.prevent="uploadImage">
        <label>Producto</label>
        <select v-model="imageForm.product_id" required>
        <option value="">Selecciona un producto</option>
        <option
            v-for="product in products"
            :key="product.id"
            :value="product.id"
        >
            {{ product.name }}
        </option>
        </select>

        <label>Imagen</label>
        <input type="file" accept="image/*" @change="handleImageFile" required>

        <div class="actions">
        <button type="submit">Subir imagen</button>
        </div>
    </form>
    </section>

    <section class="card">
      <h2>Listado de productos</h2>

      <button class="export-button" @click="exportProductsXls">
      Exportar XLS
      </button>

      <p v-if="loading">Cargando productos...</p>

      <table v-else>
        <thead>
          <tr>
            <th>Código</th>
            <th>Nombre</th>
            <th>Descripción</th>
            <th>Categorías</th>
            <th>Tarifas</th>
            <th>Fotos</th>
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
            <div
                v-for="rate in getProductRates(product.id)"
                :key="rate.id"
                class="rate-line"
            >
                {{ rate.start_date }} -
                {{ rate.end_date || 'Sin fin' }}:
                {{ rate.price }} €

                <button class="mini danger" @click="deleteRate(rate.id)">
                X
                </button>
            </div>

            <span v-if="getProductRates(product.id).length === 0">-</span>
            </td>

            <td>
            <div class="image-list">
                <div
                v-for="image in getProductImages(product.id)"
                :key="image.id"
                class="image-item"
                >
                <img :src="getImageUrl(image.image_path)" alt="Foto producto">
                <button class="mini danger" @click="deleteImage(image)">X</button>
                </div>

                <span v-if="getProductImages(product.id).length === 0">-</span>
            </div>
            </td>

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
const productRates = ref([])
const productImages = ref([])

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

const rateForm = ref({
  product_id: '',
  start_date: '',
  end_date: '',
  price: ''
})

const imageForm = ref({
  product_id: '',
  file: null
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

  try {
    await Promise.all([
      loadProducts(),
      loadCategories(),
      loadProductCategories(),
      loadProductRates(),
      loadProductImages()
    ])
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
  }
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

async function loadProductRates() {
  const { data, error: loadError } = await supabase
    .from('product_rates')
    .select('*')
    .order('start_date', { ascending: true })

  if (loadError) {
    error.value = loadError.message
    return
  }

  productRates.value = data
}

async function loadProductImages() {
  const { data, error: loadError } = await supabase
    .from('product_images')
    .select('*')
    .order('sort_order', { ascending: true })

  if (loadError) {
    error.value = loadError.message
    return
  }

  productImages.value = data
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

async function saveRate() {
  error.value = ''
  success.value = ''

  const payload = {
    product_id: rateForm.value.product_id,
    start_date: rateForm.value.start_date,
    end_date: rateForm.value.end_date || null,
    price: Number(rateForm.value.price)
  }

  const { error: insertError } = await supabase
    .from('product_rates')
    .insert(payload)

  if (insertError) {
    error.value = insertError.message
    return
  }

  success.value = 'Tarifa creada correctamente.'

  rateForm.value = {
    product_id: '',
    start_date: '',
    end_date: '',
    price: ''
  }

  await loadProductRates()
}

async function deleteRate(id) {
  const confirmed = confirm('¿Seguro que quieres eliminar esta tarifa?')

  if (!confirmed) {
    return
  }

  const { error: deleteError } = await supabase
    .from('product_rates')
    .delete()
    .eq('id', id)

  if (deleteError) {
    error.value = deleteError.message
    return
  }

  success.value = 'Tarifa eliminada correctamente.'
  await loadProductRates()
}

function handleImageFile(event) {
  imageForm.value.file = event.target.files[0]
}

async function uploadImage() {
  error.value = ''
  success.value = ''

  if (!imageForm.value.product_id || !imageForm.value.file) {
    error.value = 'Selecciona un producto y una imagen.'
    return
  }

  const file = imageForm.value.file
  const fileName = `${Date.now()}-${file.name}`
  const filePath = `${imageForm.value.product_id}/${fileName}`

  const { error: uploadError } = await supabase.storage
    .from('product-images')
    .upload(filePath, file)

  if (uploadError) {
    error.value = uploadError.message
    return
  }

  const { error: insertError } = await supabase
    .from('product_images')
    .insert({
      product_id: imageForm.value.product_id,
      image_path: filePath,
      sort_order: 0
    })

  if (insertError) {
    error.value = insertError.message
    return
  }

  success.value = 'Imagen subida correctamente.'

  imageForm.value = {
    product_id: '',
    file: null
  }

  await loadProductImages()
}

async function deleteImage(image) {
  const confirmed = confirm('¿Seguro que quieres eliminar esta imagen?')

  if (!confirmed) {
    return
  }

  const { error: storageError } = await supabase.storage
    .from('product-images')
    .remove([image.image_path])

  if (storageError) {
    error.value = storageError.message
    return
  }

  const { error: deleteError } = await supabase
    .from('product_images')
    .delete()
    .eq('id', image.id)

  if (deleteError) {
    error.value = deleteError.message
    return
  }

  success.value = 'Imagen eliminada correctamente.'
  await loadProductImages()
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

function getProductRates(productId) {
  return productRates.value.filter(rate => rate.product_id === productId)
}

function getImageUrl(path) {
  const { data } = supabase.storage
    .from('product-images')
    .getPublicUrl(path)

  return data.publicUrl
}

function getProductImages(productId) {
  return productImages.value.filter(image => image.product_id === productId)
}

async function exportProductsXls() {
    const XLSX = await import('xlsx-js-style')
    const rows = products.value.map(product => {
    const rates = getProductRates(product.id)
      .map(rate => `${rate.start_date} - ${rate.end_date || 'Sin fin'}: ${rate.price} €`)
      .join('\n')

    const images = getProductImages(product.id).length

    return {
      Código: product.code,
      Nombre: product.name,
      Descripción: product.description || '',
      Categorías: getProductCategories(product.id),
      Tarifas: rates || '-',
      Fotos: images
    }
  })

  const data = [
    ['Listado de productos'],
    [`Exportado el ${new Date().toLocaleDateString('es-ES')}`],
    [],
    ['Código', 'Nombre', 'Descripción', 'Categorías', 'Tarifas', 'Fotos'],
    ...rows.map(row => [
      row.Código,
      row.Nombre,
      row.Descripción,
      row.Categorías,
      row.Tarifas,
      row.Fotos
    ])
  ]

  const worksheet = XLSX.utils.aoa_to_sheet(data)

  worksheet['!cols'] = [
    { wch: 16 },
    { wch: 28 },
    { wch: 45 },
    { wch: 30 },
    { wch: 45 },
    { wch: 10 }
  ]

  worksheet['!merges'] = [
    { s: { r: 0, c: 0 }, e: { r: 0, c: 5 } },
    { s: { r: 1, c: 0 }, e: { r: 1, c: 5 } }
  ]

  const range = XLSX.utils.decode_range(worksheet['!ref'])

  for (let row = range.s.r; row <= range.e.r; row++) {
    for (let col = range.s.c; col <= range.e.c; col++) {
      const cellAddress = XLSX.utils.encode_cell({ r: row, c: col })

      if (!worksheet[cellAddress]) {
        worksheet[cellAddress] = { t: 's', v: '' }
      }

      worksheet[cellAddress].s = {
        font: {
          name: 'Arial',
          sz: 11,
          color: { rgb: '1E293B' }
        },
        alignment: {
          vertical: 'center',
          wrapText: true
        },
        border: {
          top: { style: 'thin', color: { rgb: 'CBD5E1' } },
          bottom: { style: 'thin', color: { rgb: 'CBD5E1' } },
          left: { style: 'thin', color: { rgb: 'CBD5E1' } },
          right: { style: 'thin', color: { rgb: 'CBD5E1' } }
        }
      }
    }
  }

  worksheet['A1'].s = {
    font: {
      name: 'Arial',
      sz: 18,
      bold: true,
      color: { rgb: 'FFFFFF' }
    },
    fill: {
      fgColor: { rgb: '1D4ED8' }
    },
    alignment: {
      horizontal: 'center',
      vertical: 'center'
    }
  }

  worksheet['A2'].s = {
    font: {
      name: 'Arial',
      sz: 11,
      italic: true,
      color: { rgb: '475569' }
    },
    fill: {
      fgColor: { rgb: 'E0F2FE' }
    },
    alignment: {
      horizontal: 'center',
      vertical: 'center'
    }
  }

  const headerRow = 3

  for (let col = 0; col <= 5; col++) {
    const cellAddress = XLSX.utils.encode_cell({ r: headerRow, c: col })

    worksheet[cellAddress].s = {
      font: {
        name: 'Arial',
        sz: 12,
        bold: true,
        color: { rgb: 'FFFFFF' }
      },
      fill: {
        fgColor: { rgb: '0F172A' }
      },
      alignment: {
        horizontal: 'center',
        vertical: 'center'
      },
      border: {
        top: { style: 'thin', color: { rgb: '0F172A' } },
        bottom: { style: 'thin', color: { rgb: '0F172A' } },
        left: { style: 'thin', color: { rgb: '0F172A' } },
        right: { style: 'thin', color: { rgb: '0F172A' } }
      }
    }
  }

  for (let row = 4; row <= range.e.r; row++) {
    const fillColor = row % 2 === 0 ? 'F8FAFC' : 'FFFFFF'

    for (let col = 0; col <= 5; col++) {
      const cellAddress = XLSX.utils.encode_cell({ r: row, c: col })

      worksheet[cellAddress].s.fill = {
        fgColor: { rgb: fillColor }
      }
    }
  }

  worksheet['!rows'] = [
    { hpt: 32 },
    { hpt: 24 },
    { hpt: 8 },
    { hpt: 26 }
  ]

  worksheet['!autofilter'] = {
    ref: 'A4:F4'
  }

  const workbook = XLSX.utils.book_new()
  XLSX.utils.book_append_sheet(workbook, worksheet, 'Productos')

  XLSX.writeFile(workbook, 'productos.xlsx')
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

.rate-line {
  margin-bottom: 6px;
  font-size: 14px;
}

.export-button {
  margin-bottom: 18px;
  background: #16a34a;
}

button.mini {
  padding: 3px 7px;
  margin-left: 6px;
  font-size: 12px;
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

.image-list {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.image-item {
  position: relative;
  width: 70px;
}

.image-item img {
  width: 70px;
  height: 70px;
  object-fit: cover;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
}

.image-item button {
  margin-top: 4px;
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