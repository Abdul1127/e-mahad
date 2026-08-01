# E-Ma'had

E-Ma'had adalah aplikasi web terpusat untuk pengelolaan,
pemantauan, dan pelaporan perkembangan santri.

## Technology Stack

- Next.js
- TypeScript
- Tailwind CSS
- Supabase Cloud
- Supabase PostgreSQL
- Supabase Auth
- Supabase Storage
- Vercel
- npm

## Requirements

- Node.js
- npm
- Git
- Supabase Cloud project

Project tidak mewajibkan Docker atau Supabase CLI.

## Installation

Install dependency:

```bash
npm install
```

Buat file environment:

```text
.env.local
```

Isi environment:

```dotenv
NEXT_PUBLIC_APP_URL=http://localhost:3000
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=sb_publishable_your_key
```

Jalankan development server:

```bash
npm run dev
```

Buka:

```text
http://localhost:3000
```

Health check:

```text
http://localhost:3000/api/health
```

## Validation

```bash
npm run lint
npm run typecheck
npm run build
```

## Database Workflow

SQL database disimpan pada:

```text
database/sql/
```

SQL dijalankan manual melalui Supabase SQL Editor.

Database lama hanya digunakan sebagai referensi.

## Documentation

Dokumentasi project berada pada:

```text
docs/
```

Baca file berdasarkan nomor urut.

## Important Rules

- Gunakan npm.
- Supabase menggunakan project cloud.
- PostgreSQL adalah sumber data utama.
- Google Sheets bukan database transaksional.
- Jangan menyimpan secret key di browser.
- Gunakan Row Level Security.
- Periksa kode dan SQL sebelum diterapkan.