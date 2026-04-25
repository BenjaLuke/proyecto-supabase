<template>
  <main class="page">
    <header>
      <div>
        <h1>Calendario de pedidos</h1>
        <p>Recordatorios de compra de productos</p>
      </div>

      <NuxtLink to="/backoffice">Volver</NuxtLink>
    </header>

    <section class="card">
      <h2>Nuevo pedido</h2>

      <form @submit.prevent="saveOrder">
        <label>Fecha del pedido</label>
        <input v-model="form.order_date" type="date" required>

        <label>Producto</label>
        <select v-model="form.product_id" required>
          <option value="">Selecciona un producto</option>
          <option
            v-for="product in products"
            :key="product.id"
            :value="product.id"
          >
            {{ product.name }}
          </option>
        </select>

        <label>Unidades</label>
        <input v-model="form.units" type="number" min="1" required>

        <div class="summary">
          <p><strong>Precio aplicado:</strong> {{ calculatedPrice }} €</p>
          <p><strong>Coste total:</strong> {{ calculatedTotal }} €</p>
        </div>

        <div class="actions">
          <button type="submit">Guardar pedido</button>
        </div>
      </form>

      <p v-if="error" class="error">{{ error }}</p>
      <p v-if="success" class="success">{{ success }}</p>
    </section>

    <section class="card">
      <h2>Pedidos guardados</h2>

      <p v-if="loading">Cargando pedidos...</p>

      <table v-else>
        <thead>
          <tr>
            <th>Fecha</th>
            <th>Producto</th>
            <th>Unidades</th>
            <th>Precio unidad</th>
            <th>Total</th>
            <th>Acciones</th>
          </tr>
        </thead>

        <tbody>
          <tr v-for="order in orders" :key="order.id">
            <td>{{ order.order_date }}</td>
            <td>{{ getProductName(order.product_id) }}</td>
            <td>{{ order.units }}</td>
            <td>{{ order.unit_price }} €</td>
            <td>{{ order.total_cost }} €</td>
            <td>
              <button class="small danger" @click="deleteOrder(order.id)">
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

const products = ref([])
const productRates = ref([])
const orders = ref([])

const loading = ref(true)
const error = ref('')
const success = ref('')

const form = ref({
  order_date: '',
  product_id: '',
  units: 1
})

onMounted(async () => {
  await checkSession()
  await loadAll()
})

const calculatedPrice = computed(() => {
  const rate = getActiveRate(form.value.product_id, form.value.order_date)
  return rate ? Number(rate.price).toFixed(2) : '0.00'
})

const calculatedTotal = computed(() => {
  const total = Number(calculatedPrice.value) * Number(form.value.units || 0)
  return total.toFixed(2)
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
      loadProductRates(),
      loadOrders()
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

async function loadOrders() {
  const { data, error: loadError } = await supabase
    .from('purchase_orders')
    .select('*')
    .order('order_date', { ascending: true })

  if (loadError) {
    error.value = loadError.message
    return
  }

  orders.value = data
}

function getActiveRate(productId, orderDate) {
  if (!productId || !orderDate) {
    return null
  }

  return productRates.value.find(rate => {
    const startsBefore = rate.start_date <= orderDate
    const endsAfter = !rate.end_date || rate.end_date >= orderDate

    return rate.product_id === productId && startsBefore && endsAfter
  })
}

async function saveOrder() {
  error.value = ''
  success.value = ''

  const rate = getActiveRate(form.value.product_id, form.value.order_date)

  if (!rate) {
    error.value = 'No existe una tarifa válida para ese producto en esa fecha.'
    return
  }

  const units = Number(form.value.units)
  const unitPrice = Number(rate.price)
  const totalCost = units * unitPrice

  const { error: insertError } = await supabase
    .from('purchase_orders')
    .insert({
      order_date: form.value.order_date,
      product_id: form.value.product_id,
      units: units,
      unit_price: unitPrice,
      total_cost: totalCost
    })

  if (insertError) {
    error.value = insertError.message
    return
  }

  success.value = 'Pedido guardado correctamente.'

  form.value = {
    order_date: '',
    product_id: '',
    units: 1
  }

  await loadOrders()
}

async function deleteOrder(id) {
  const confirmed = confirm('¿Seguro que quieres eliminar este pedido?')

  if (!confirmed) {
    return
  }

  const { error: deleteError } = await supabase
    .from('purchase_orders')
    .delete()
    .eq('id', id)

  if (deleteError) {
    error.value = deleteError.message
    return
  }

  success.value = 'Pedido eliminado correctamente.'
  await loadOrders()
}

function getProductName(productId) {
  const product = products.value.find(product => product.id === productId)
  return product ? product.name : '-'
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
select {
  width: 100%;
  padding: 10px;
  margin-top: 6px;
  box-sizing: border-box;
}

.summary {
  margin-top: 18px;
  padding: 16px;
  background: #f1f5f9;
  border-radius: 10px;
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

button.small {
  padding: 7px 10px;
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