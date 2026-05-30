// controllers/artisanController.js
const pool = require('../models/db');

const intentRules = [
  {
    category: 'plomberie',
    jobNames: ['plombier', 'plomberie', 'sanitaire'],
    phrases: [
      'pas d eau',
      'plus d eau',
      'fuite d eau',
      'eau qui coule',
      'robinet fuit',
      'wc bouche',
      'evier bouche',
      'lavabo bouche',
      'chauffe eau',
      'canalisation bouchee',
      'tuyau casse',
      'lma kayn mochkil',
    ],
    symptoms: ['fuite', 'coule', 'bouche', 'deborde', 'goutte', 'inondation', 'pression', 'humide', 'odeur'],
    objects: ['eau', 'lma', 'robinet', 'evier', 'lavabo', 'wc', 'toilette', 'douche', 'baignoire', 'tuyau', 'canalisation', 'siphon', 'chauffe eau'],
  },
  {
    category: 'electricite',
    jobNames: ['electricien', 'electricite'],
    phrases: ['pas de courant', 'plus de courant', 'prise brule', 'prise ne marche pas', 'disjoncteur saute', 'compteur saute', 'court circuit', 'lumiere clignote', 'ma kaynch do', 'ma kaynch daw'],
    symptoms: ['courant', 'saute', 'brule', 'etincelle', 'clignote', 'panne', 'eteint', 'allume', 'daw', 'do'],
    objects: ['prise', 'interrupteur', 'lampe', 'lumiere', 'cable', 'fil', 'tableau', 'disjoncteur', 'compteur'],
  },
  {
    category: 'serrurerie',
    jobNames: ['serrurier', 'serrurerie'],
    phrases: ['porte bloquee', 'cle cassee', 'cle perdue', 'porte ne ferme pas', 'porte ne s ouvre pas', 'changer serrure'],
    symptoms: ['bloque', 'casse', 'perdu', 'coince', 'ferme pas', 'ouvre pas'],
    objects: ['serrure', 'cle', 'porte', 'verrou', 'cylindre'],
  },
  {
    category: 'climatisation',
    jobNames: ['climatisation', 'climatiseur', 'technicien clim'],
    phrases: ['clim ne refroidit pas', 'clim coule', 'clim fait du bruit', 'installer clim', 'entretien clim'],
    symptoms: ['froid', 'chaud', 'bruit', 'coule', 'refroidit', 'chauffe'],
    objects: ['clim', 'climatiseur', 'air conditionne', 'split', 'ventilation'],
  },
  {
    category: 'menuiserie',
    jobNames: ['menuisier', 'menuiserie', 'bois'],
    phrases: ['porte cassee', 'fenetre cassee', 'placard casse', 'meuble casse', 'installer cuisine'],
    symptoms: ['casse', 'coince', 'grince', 'reparer', 'monter', 'installer'],
    objects: ['bois', 'porte', 'fenetre', 'placard', 'meuble', 'cuisine'],
  },
  {
    category: 'peinture',
    jobNames: ['peintre', 'peinture'],
    phrases: ['repeindre mur', 'peinture mur', 'peinture plafond'],
    symptoms: ['repeindre', 'tache', 'ecaille', 'couleur', 'peindre'],
    objects: ['mur', 'plafond', 'facade', 'chambre', 'salon'],
  },
  {
    category: 'carrelage',
    jobNames: ['carreleur', 'carrelage'],
    phrases: ['carrelage casse', 'poser carrelage', 'joint carrelage'],
    symptoms: ['casse', 'fissure', 'poser', 'joint', 'remplacer'],
    objects: ['carrelage', 'carreau', 'sol', 'faience'],
  },
  {
    category: 'maconnerie',
    jobNames: ['macon', 'maconnerie'],
    phrases: ['mur fissure', 'construire mur', 'casser mur'],
    symptoms: ['fissure', 'construire', 'casser', 'beton', 'ciment'],
    objects: ['mur', 'brique', 'beton', 'ciment', 'dalle'],
  },
  {
    category: 'nettoyage',
    jobNames: ['nettoyage', 'menage'],
    phrases: ['nettoyage maison', 'menage complet', 'apres travaux'],
    symptoms: ['sale', 'nettoyer', 'laver', 'poussiere', 'tache'],
    objects: ['maison', 'appartement', 'bureau', 'vitre', 'sol'],
  },
  {
    category: 'jardinage',
    jobNames: ['jardinier', 'jardinage'],
    phrases: ['couper herbe', 'tailler arbre', 'arroser jardin'],
    symptoms: ['couper', 'tailler', 'planter', 'arroser', 'entretenir'],
    objects: ['jardin', 'herbe', 'arbre', 'plante', 'gazon'],
  },
];

const normalize = (value = '') =>
  value
    .toString()
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9\s]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();

const detectProblemIntent = (query) => {
  const normalizedQuery = normalize(query);
  if (normalizedQuery.length < 3) return { category: '', score: 0 };

  const scores = {};
  for (const rule of intentRules) {
    let score = 0;

    for (const jobName of rule.jobNames) {
      if (normalizedQuery.includes(jobName)) score += 7;
    }
    for (const phrase of rule.phrases) {
      if (normalizedQuery.includes(phrase)) score += 6;
    }
    for (const symptom of rule.symptoms) {
      if (normalizedQuery.includes(symptom)) score += 3;
    }
    for (const object of rule.objects) {
      if (normalizedQuery.includes(object)) score += 2;
    }

    if (score > 0) scores[rule.category] = score;
  }

  const best = Object.entries(scores).sort((a, b) => b[1] - a[1])[0];
  if (!best || best[1] < 4) return { category: '', score: 0 };
  return { category: best[0], score: best[1] };
};

const getAllArtisans = async (req, res) => {
  try {
    const query = req.query.q || '';
    const normalizedQuery = normalize(query);
    const intent = detectProblemIntent(query);

    const result = await pool.query(`
      SELECT u.id,
             u.full_name,
             u.email,
             u.phone,
             u.city,
             u.neighborhood,
             COALESCE(
               u.latitude,
               CASE
                 WHEN LOWER(u.city) IN ('rabat') THEN 34.0209
                 WHEN LOWER(u.city) IN ('casablanca', 'casa') THEN 33.5731
                 WHEN LOWER(u.city) IN ('marrakech') THEN 31.6295
                 WHEN LOWER(u.city) IN ('fes', 'fez') THEN 34.0331
                 WHEN LOWER(u.city) IN ('tanger', 'tangier') THEN 35.7595
                 WHEN LOWER(u.city) IN ('agadir') THEN 30.4278
                 ELSE NULL
               END
             ) AS latitude,
             COALESCE(
               u.longitude,
               CASE
                 WHEN LOWER(u.city) IN ('rabat') THEN -6.8416
                 WHEN LOWER(u.city) IN ('casablanca', 'casa') THEN -7.5898
                 WHEN LOWER(u.city) IN ('marrakech') THEN -7.9811
                 WHEN LOWER(u.city) IN ('fes', 'fez') THEN -5.0003
                 WHEN LOWER(u.city) IN ('tanger', 'tangier') THEN -5.8340
                 WHEN LOWER(u.city) IN ('agadir') THEN -9.5981
                 ELSE NULL
               END
             ) AS longitude,
             COALESCE(s.name, 'Artisan general') AS speciality,
             ap.description AS bio,
             ap.description,
             ap.hourly_rate,
             COALESCE(ap.is_available, true) AS is_available,
             COALESCE(ap.average_rating, 0) AS average_rating,
             COALESCE(review_stats.review_count, 0) AS review_count,
             COALESCE(ap.portfolio_images, ARRAY[]::TEXT[]) AS portfolio_images,
             ap.profile_photo_url AS profile_image
      FROM users u
      LEFT JOIN artisan_profiles ap ON ap.user_id = u.id
      LEFT JOIN specialties s ON ap.specialty_id = s.id
      LEFT JOIN (
        SELECT artisan_id, COUNT(*) AS review_count
        FROM reviews
        GROUP BY artisan_id
      ) review_stats ON review_stats.artisan_id = u.id
      WHERE u.role = 'artisan'
      ORDER BY COALESCE(ap.is_available, true) DESC,
               COALESCE(ap.average_rating, 0) DESC,
               u.full_name ASC
    `);

    const artisans = result.rows.filter((artisan) => {
      if (!normalizedQuery) return true;

      const speciality = normalize(artisan.speciality);
      const searchable = normalize([
        artisan.full_name,
        artisan.email,
        artisan.phone,
        artisan.city,
        artisan.neighborhood,
        artisan.speciality,
        artisan.description,
      ].filter(Boolean).join(' '));

      return searchable.includes(normalizedQuery) ||
        (intent.category && speciality.includes(intent.category));
    });

    return res.json(artisans);
  } catch (err) {
    console.error('[ArtisanController] Erreur getAllArtisans:', err);
    return res.status(500).json({ error: 'Erreur serveur interne.' });
  }
};

module.exports = { getAllArtisans };
