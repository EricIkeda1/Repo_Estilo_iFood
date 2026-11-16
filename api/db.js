import pg from 'pg';
if (!process.env.DATABASE_URL) throw Error('Configure DATABASE_URL no .env da API');
export const db = new pg.Pool({connectionString:process.env.DATABASE_URL,max:5});
