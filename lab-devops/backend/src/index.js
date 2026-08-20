const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');

const app = express();
const PORT = process.env.PORT || 3001;

app.use(cors());
app.use(express.json());

// Configuration de la connexion PostgreSQL
const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgres://postgres:secretpassword@db:5432/lab_ghislain',
});

// Produits par défaut au cas où la BDD charge
const initialProducts = [
  { id: 1, name: 'T-Shirt DevOps Ghislain', price: 29.99, image: '👕', description: 'Cotons bio 100% automatisé' },
  { id: 2, name: 'Mug Docker Compose', price: 14.99, image: '☕', description: 'Garde votre café chaud pendant vos builds' },
  { id: 3, name: 'Sticker Kubernetes', price: 4.99, image: '🏷️', description: 'Pour orchestrer vos notebooks' },
  { id: 4, name: 'Casquette Linux WSL', price: 24.99, image: '🧢', description: 'Style Terminal garanti' }
];

// Initialisation de la table PostgreSQL
async function initDb() {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS products (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        price NUMERIC(10, 2) NOT NULL,
        image VARCHAR(10),
        description TEXT
      );
    `);

    const res = await pool.query('SELECT COUNT(*) FROM products');
    if (parseInt(res.rows[0].count, 10) === 0) {
      for (const p of initialProducts) {
        await pool.query(
          'INSERT INTO products (name, price, image, description) VALUES ($1, $2, $3, $4)',
          [p.name, p.price, p.image, p.description]
        );
      }
      console.log('✅ Base de données initialisée avec les produits de test !');
    }
  } catch (err) {
    console.error('⚠️ BDD non encore prête ou erreur :', err.message);
  }
}

// Routes de l'API
app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'E-Commerce Backend API' });
});

app.get('/products', async (req, res) => {
  try {
    const { rows } = await pool.query('SELECT * FROM products ORDER BY id ASC');
    if (rows.length > 0) {
      return res.json(rows);
    }
  } catch (err) {
    console.log('Utilisation des produits statiques en fallback...');
  }
  res.json(initialProducts);
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Backend E-Commerce à l'écoute sur http://0.0.0.0:${PORT}`);
  setTimeout(initDb, 2000); // Tente d'initialiser la BDD après le démarrage
});
